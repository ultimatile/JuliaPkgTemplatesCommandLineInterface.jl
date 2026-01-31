using Test
using PkgTemplatesCommandLineInterface

@testset "Common Data Structures" begin
    @testset "CommandResult" begin
        @testset "Basic construction" begin
            # Success result with message
            result = CommandResult(success=true, message="Operation completed")
            @test result.success === true
            @test result.message == "Operation completed"
            @test result.data === nothing

            # Failure result without message
            result = CommandResult(success=false)
            @test result.success === false
            @test result.message === nothing
            @test result.data === nothing

            # Result with data
            data = Dict("key" => "value", "count" => 42)
            result = CommandResult(success=true, message="Done", data=data)
            @test result.success === true
            @test result.message == "Done"
            @test result.data == data
        end

        @testset "Type constraints" begin
            # message field accepts String or Nothing
            @test CommandResult(success=true, message="test").message isa Union{String,Nothing}
            @test CommandResult(success=true, message=nothing).message isa Union{String,Nothing}

            # data field accepts Dict or Nothing
            @test CommandResult(success=true, data=Dict("a" => 1)).data isa Union{Dict{String,Any},Nothing}
            @test CommandResult(success=true, data=nothing).data isa Union{Dict{String,Any},Nothing}
        end

        @testset "Keyword argument construction" begin
            # Only success required
            result = CommandResult(success=true)
            @test result.success === true
            @test result.message === nothing
            @test result.data === nothing

            # All arguments provided
            result = CommandResult(
                success=false,
                message="Error occurred",
                data=Dict("error_code" => 500)
            )
            @test result.success === false
            @test result.message == "Error occurred"
            @test result.data == Dict("error_code" => 500)
        end
    end

    @testset "PluginDetails" begin
        @testset "Basic construction" begin
            details = PluginDetails(
                name="TestPlugin",
                fields=[:field1, :field2],
                types=[String, Int],
                defaults=["default", 42]
            )

            @test details.name == "TestPlugin"
            @test details.fields == [:field1, :field2]
            @test details.types == [String, Int]
            @test details.defaults == ["default", 42]
        end

        @testset "Type constraints" begin
            details = PluginDetails(
                name="Plugin",
                fields=Symbol[],
                types=Type[],
                defaults=Any[]
            )

            @test details.name isa String
            @test details.fields isa Vector{Symbol}
            @test details.types isa Vector{Type}
            @test details.defaults isa Vector{Any}
        end

        @testset "Empty fields" begin
            # Plugin with no fields
            details = PluginDetails(
                name="EmptyPlugin",
                fields=Symbol[],
                types=Type[],
                defaults=Any[]
            )

            @test isempty(details.fields)
            @test isempty(details.types)
            @test isempty(details.defaults)
        end

        @testset "Multiple field types" begin
            # Plugin with various field types
            details = PluginDetails(
                name="ComplexPlugin",
                fields=[:str_field, :int_field, :bool_field, :vec_field],
                types=[String, Int, Bool, Vector{String}],
                defaults=["text", 0, false, String[]]
            )

            @test length(details.fields) == 4
            @test length(details.types) == 4
            @test length(details.defaults) == 4

            @test details.types[1] == String
            @test details.types[2] == Int
            @test details.types[3] == Bool
            @test details.types[4] == Vector{String}
        end

        @testset "Default values can be nothing" begin
            # Some fields might not have default values
            details = PluginDetails(
                name="PartialDefaults",
                fields=[:required, :optional],
                types=[String, Union{String,Nothing}],
                defaults=[nothing, "default"]
            )

            @test details.defaults[1] === nothing
            @test details.defaults[2] == "default"
        end
    end

    @testset "Type safety" begin
        @testset "CommandResult type safety" begin
            result = CommandResult(success=true)
            @test isa(result, CommandResult)
            @test fieldnames(CommandResult) == (:success, :message, :data)
        end

        @testset "PluginDetails type safety" begin
            details = PluginDetails(
                name="Test",
                fields=Symbol[],
                types=Type[],
                defaults=Any[]
            )
            @test isa(details, PluginDetails)
            @test fieldnames(PluginDetails) == (:name, :fields, :types, :defaults)
        end
    end
end
