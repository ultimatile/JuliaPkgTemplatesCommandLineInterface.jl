using Test
using PkgTemplatesCommandLineInterface
import PkgTemplatesCommandLineInterface.CreateCommand

@testset "CreateCommand Tests" begin
    @testset "merge_config" begin
        @testset "CLI arguments override config defaults" begin
            config_defaults = Dict{String, Any}(
                "author" => "Default Author",
                "user" => "default_user",
                "mail" => "default@example.com"
            )
            cli_args = Dict{String, Any}(
                "author" => "CLI Author",
                "user" => nothing  # Should not override
            )

            merged = CreateCommand.merge_config(config_defaults, cli_args)

            @test merged["author"] == "CLI Author"  # CLI overrides
            @test merged["user"] == "default_user"  # Config preserved (CLI was nothing)
            @test merged["mail"] == "default@example.com"  # Config preserved (not in CLI)
        end

        @testset "nested configuration merge" begin
            config_defaults = Dict{String, Any}(
                "formatter" => Dict{String, Any}(
                    "style" => "blue",
                    "indent" => 4
                )
            )
            cli_args = Dict{String, Any}(
                "formatter" => Dict{String, Any}(
                    "style" => "yas"
                )
            )

            merged = CreateCommand.merge_config(config_defaults, cli_args)

            @test merged["formatter"]["style"] == "yas"  # CLI overrides
            @test merged["formatter"]["indent"] == 4  # Config preserved
        end

        @testset "empty CLI args preserves all config" begin
            config_defaults = Dict{String, Any}(
                "author" => "Test",
                "user" => "testuser"
            )
            cli_args = Dict{String, Any}()

            merged = CreateCommand.merge_config(config_defaults, cli_args)

            @test merged == config_defaults
        end
    end

    @testset "parse_plugin_option_value" begin
        @testset "boolean values" begin
            @test CreateCommand.parse_plugin_option_value("ssh=true") == ("ssh", true)
            @test CreateCommand.parse_plugin_option_value("ssh=false") == ("ssh", false)
        end

        @testset "integer values" begin
            @test CreateCommand.parse_plugin_option_value("indent=4") == ("indent", 4)
            @test CreateCommand.parse_plugin_option_value("count=123") == ("count", 123)
        end

        @testset "float values" begin
            @test CreateCommand.parse_plugin_option_value("version=1.5") == ("version", 1.5)
            @test CreateCommand.parse_plugin_option_value("ratio=0.75") == ("ratio", 0.75)
        end

        @testset "string values" begin
            @test CreateCommand.parse_plugin_option_value("style=blue") == ("style", "blue")
            @test CreateCommand.parse_plugin_option_value("name=MyPkg") == ("name", "MyPkg")
        end

        @testset "array values" begin
            key, val = CreateCommand.parse_plugin_option_value("items=[a,b,c]")
            @test key == "items"
            @test val == ["a", "b", "c"]
        end
    end

    @testset "parse_plugin_options" begin
        @testset "single plugin with multiple options" begin
            args = Dict{String, Any}(
                "--git" => ["ssh=true", "manifest=false"],
                "package_name" => "MyPkg"
            )

            plugin_options = CreateCommand.parse_plugin_options(args)

            @test haskey(plugin_options, "git")
            @test plugin_options["git"]["ssh"] == true
            @test plugin_options["git"]["manifest"] == false
        end

        @testset "multiple plugins" begin
            args = Dict{String, Any}(
                "--git" => ["ssh=true"],
                "--formatter" => ["style=blue", "indent=4"]
            )

            plugin_options = CreateCommand.parse_plugin_options(args)

            @test haskey(plugin_options, "git")
            @test haskey(plugin_options, "formatter")
            @test plugin_options["git"]["ssh"] == true
            @test plugin_options["formatter"]["style"] == "blue"
            @test plugin_options["formatter"]["indent"] == 4
        end

        @testset "ignores non-plugin keys" begin
            args = Dict{String, Any}(
                "--git" => ["ssh=true"],
                "package_name" => "MyPkg",
                "author" => "Test Author"
            )

            plugin_options = CreateCommand.parse_plugin_options(args)

            @test length(keys(plugin_options)) == 1
            @test haskey(plugin_options, "git")
        end
    end

    # Note: dry-run mode and error handling are tested in test_integration.jl
end
