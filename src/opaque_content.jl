# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).


"""
    struct OpaqueContent

Represents opaque content of a specific MIME type.

Constructors:

```julia
OpaqueContent(data::AbstractVector{UInt8}, mime::MIME)

OpaqueContent(mime::MIME) do io
    # add something to io::IO
end
```

Example:

content = OpaqueContent(MIME("text/html")) do io
    println(io, "<p>Hello, World!</p>")
end
lazyreport(content)
"""
struct OpaqueContent{MT}
    mime::MIME{MT}
    data::Vector{UInt8}
end
export OpaqueContent

function OpaqueContent(f, mime::MIME)
    io = IOBuffer()
    f(io)
    OpaqueContent(mime, take!(io))
end

Base.showable(::MIME{MT}, ::OpaqueContent{MT}) where MT = true

function _write_opaque(io::IO, @nospecialize(content::OpaqueContent))
    write(io, content.data)
    return nothing
end

Base.show(io::IO, ::MIME{MT}, content::OpaqueContent{MT}) where MT = _write_opaque(io, content)

# Disambiguation:
Base.show(io::IO, ::MIME{Symbol("text/plain")}, content::OpaqueContent{Symbol("text/plain")}) = _write_opaque(io, content)
