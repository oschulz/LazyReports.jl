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

function Base.show(@nospecialize(io::IO), ::MIME{MT}, @nospecialize(content::OpaqueContent{MT})) where MT
    write(io, content.data)
    return nothing
end


Base.showable(::MIME"text/plain", ::OpaqueContent) = true

function Base.show(@nospecialize(io::IO), ::MIME"text/plain", @nospecialize(content::OpaqueContent))
    print(io, "[$(content.mime)]")
end

function Base.show(@nospecialize(io::IO), ::MIME"text/plain", @nospecialize(content::OpaqueContent{Symbol("text/plain")}))
    write(io, content.data)
    return nothing
end

function Base.show(@nospecialize(io::IO), mime::MIME"text/plain", @nospecialize(content::OpaqueContent{Symbol("text/markdown")}))
    _convert_from_markdown(io, mime, content.data)
end


Base.showable(::MIME"text/html", ::OpaqueContent{Symbol("text/markdown")}) = true

function Base.show(@nospecialize(io::IO), mime::MIME"text/html", @nospecialize(content::OpaqueContent{Symbol("text/markdown")}))
    _convert_from_markdown(io, mime, content.data)
end


function _convert_from_markdown(@nospecialize(io::IO), @nospecialize(mime::MIME), @nospecialize(data::AbstractVector{UInt8}))
    _convert_from_markdown(io, mime, String(deepcopy(data)))
end

function _convert_from_markdown(@nospecialize(io::IO), @nospecialize(mime::MIME), @nospecialize(md_str::AbstractString))
    md = Markdown.parse(md_str)
    show(io, mime, md)
end
