"""
Tests for PackageGenerator module.

This module tests the core package generation functionality using PkgTemplates.jl,
including plugin instantiation and error handling.
"""

using Test
using JuliaPkgTemplatesCommandLineInterface
using PkgTemplates
using TOML

# Import PackageGenerator module
include("../src/package_generator.jl")

@testset "PackageGenerator" begin
    @testset "create_package - basic functionality" begin
        # Test basic package generation with minimal options
        mktempdir() do tmpdir
            name = "TestPackage"
            options = Dict{String,Any}(
                "user" => "testuser",
                "authors" => ["Test Author <test@example.com>"],
                "julia_version" => "1.10"
            )
            plugin_options = Dict{String,Dict{String,Any}}()

            # Execute package generation
            PackageGenerator.create_package(name, options, plugin_options, tmpdir)

            # Verify package directory was created
            pkg_path = joinpath(tmpdir, name)
            @test isdir(pkg_path)

            # Verify Project.toml exists and contains expected data
            project_toml = joinpath(pkg_path, "Project.toml")
            @test isfile(project_toml)

            # Parse and verify contents
            project_data = TOML.parsefile(project_toml)
            @test project_data["name"] == name
            @test haskey(project_data, "uuid")
        end
    end

    @testset "create_package - with plugin options" begin
        # Test package generation with plugin instantiation
        mktempdir() do tmpdir
            name = "TestPackageWithPlugins"
            options = Dict{String,Any}(
                "user" => "testuser",
                "authors" => ["Test Author <test@example.com>"]
            )
            plugin_options = Dict{String,Dict{String,Any}}(
                "Git" => Dict{String,Any}(
                    "manifest" => true,
                    "ssh" => false
                ),
                "Readme" => Dict{String,Any}()
            )

            # Execute package generation with plugins
            PackageGenerator.create_package(name, options, plugin_options, tmpdir)

            # Verify package was created
            pkg_path = joinpath(tmpdir, name)
            @test isdir(pkg_path)

            # Verify Git plugin was applied (should have .git directory)
            @test isdir(joinpath(pkg_path, ".git"))

            # Verify Readme plugin was applied
            @test isfile(joinpath(pkg_path, "README.md"))
        end
    end

    @testset "instantiate_plugins - basic plugins" begin
        # Test plugin instantiation with no options
        plugin_options = Dict{String,Dict{String,Any}}(
            "Readme" => Dict{String,Any}()
        )

        plugins = PackageGenerator.instantiate_plugins(plugin_options)

        @test length(plugins) == 1
        @test plugins[1] isa PkgTemplates.Readme
    end

    @testset "instantiate_plugins - with options" begin
        # Test plugin instantiation with keyword arguments
        plugin_options = Dict{String,Dict{String,Any}}(
            "Git" => Dict{String,Any}(
                "manifest" => true,
                "ssh" => false
            )
        )

        plugins = PackageGenerator.instantiate_plugins(plugin_options)

        @test length(plugins) == 1
        @test plugins[1] isa PkgTemplates.Git
        @test plugins[1].manifest == true
        @test plugins[1].ssh == false
    end

    @testset "instantiate_plugins - multiple plugins" begin
        # Test multiple plugin instantiation
        plugin_options = Dict{String,Dict{String,Any}}(
            "Git" => Dict{String,Any}("manifest" => true),
            "Readme" => Dict{String,Any}(),
            "License" => Dict{String,Any}("name" => "MIT")
        )

        plugins = PackageGenerator.instantiate_plugins(plugin_options)

        @test length(plugins) == 3

        # Check plugin types (order may vary)
        plugin_types = Set(typeof(p) for p in plugins)
        @test PkgTemplates.Git in plugin_types
        @test PkgTemplates.Readme in plugin_types
        @test PkgTemplates.License in plugin_types
    end

    @testset "error handling - PkgTemplates.jl errors" begin
        # Test that PkgTemplates.jl errors are converted to PackageGenerationError
        mktempdir() do tmpdir
            name = "Invalid-Package-Name!"  # Invalid Julia identifier
            options = Dict{String,Any}("user" => "test")
            plugin_options = Dict{String,Dict{String,Any}}()

            # Should throw PackageGenerationError (not raw PkgTemplates error)
            @test_throws PackageGenerationError PackageGenerator.create_package(
                name, options, plugin_options, tmpdir
            )
        end
    end

    @testset "error handling - invalid plugin name" begin
        # Test error when plugin type doesn't exist
        plugin_options = Dict{String,Dict{String,Any}}(
            "NonExistentPlugin" => Dict{String,Any}()
        )

        # Should throw an error (either PluginNotFoundError or caught by instantiate_plugins)
        @test_throws Exception PackageGenerator.instantiate_plugins(plugin_options)
    end
end
