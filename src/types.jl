"""
Common data structures for PkgTemplatesCommandLineInterface.

This module defines reusable data types used throughout the application
for representing command results and plugin metadata.
"""

"""
    CommandResult

Unified representation of command execution results.

# Fields
- `success::Bool`: Indicates whether the command executed successfully
- `message::Union{String, Nothing}`: Optional message describing the result
- `data::Union{Dict{String, Any}, Nothing}`: Optional additional data from command execution

# Examples
```julia
# Success result with message
result = CommandResult(success=true, message="Package created successfully")

# Failure result with error data
result = CommandResult(
    success=false,
    message="Plugin not found",
    data=Dict("plugin" => "XYZ")
)

# Minimal result
result = CommandResult(success=true)
```
"""
struct CommandResult
    success::Bool
    message::Union{String,Nothing}
    data::Union{Dict{String,Any},Nothing}

    function CommandResult(;
        success::Bool,
        message::Union{String,Nothing}=nothing,
        data::Union{Dict,Nothing}=nothing
    )
        # Convert any Dict type to Dict{String, Any} for type consistency
        converted_data = if data === nothing
            nothing
        elseif data isa Dict{String,Any}
            data
        else
            Dict{String,Any}(data)
        end
        new(success, message, converted_data)
    end
end

"""
    PluginDetails

Metadata information about a PkgTemplates.jl plugin.

# Fields
- `name::String`: Name of the plugin
- `fields::Vector{Symbol}`: Field names of the plugin struct
- `types::Vector{Type}`: Types of each field
- `defaults::Vector{Any}`: Default values for each field (can include `nothing`)

# Examples
```julia
# Plugin with multiple fields
details = PluginDetails(
    name="Git",
    fields=[:manifest, :ssh],
    types=[Bool, Bool],
    defaults=[false, false]
)

# Plugin with no fields
details = PluginDetails(
    name="Readme",
    fields=Symbol[],
    types=Type[],
    defaults=Any[]
)
```
"""
struct PluginDetails
    name::String
    fields::Vector{Symbol}
    types::Vector{Type}
    defaults::Vector{Any}

    # Keyword argument constructor for better usability
    # Accepts Vector{<:Type} (including Vector{DataType}) and converts to Vector{Type}
    function PluginDetails(;
        name::String,
        fields::Vector{Symbol},
        types::Vector{<:Type},
        defaults::Vector
    )
        # Convert to Vector{Type} for type consistency
        converted_types = Type[t for t in types]
        # Convert to Vector{Any} for type consistency
        converted_defaults = Any[d for d in defaults]
        new(name, fields, converted_types, converted_defaults)
    end

    # Positional argument constructor (primary)
    # Accepts Vector{<:Type} (including Vector{DataType}) and converts to Vector{Type}
    function PluginDetails(
        name::String,
        fields::Vector{Symbol},
        types::Vector{<:Type},
        defaults::Vector
    )
        # Convert to Vector{Type} for type consistency
        converted_types = Type[t for t in types]
        # Convert to Vector{Any} for type consistency
        converted_defaults = Any[d for d in defaults]
        new(name, fields, converted_types, converted_defaults)
    end
end
