# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).


"""
    struct LazyReport

Represents a lazy report.

Don't instantiate directly, use [`lazyreport()`](@ref)
"""
struct LazyReport
    _contents::AbstractVector
end


LazyReport() = LazyReport(Any[])


function _show(@nospecialize(io::IO), mime, rpt::LazyReport)
    for obj in rpt._contents
        render_element(io, mime, obj)
        println(io)
    end
end

function Base.show(@nospecialize(io::IO), rpt::LazyReport)
    _show(io, MIME("text/plain"), rpt)
end

Base.showable(::MIME"text/plain", ::LazyReport) = true
Base.show(@nospecialize(io::IO), mime::MIME"text/plain", rpt::LazyReport) = _show(io, mime, rpt)

Base.showable(::MIME"text/markdown", ::LazyReport) = true
Base.show(@nospecialize(io::IO), mime::MIME"text/markdown", rpt::LazyReport) = _show(io, mime, rpt)

Base.showable(::MIME"text/html", ::LazyReport) = true
Base.show(@nospecialize(io::IO), mime::MIME"text/html", rpt::LazyReport) = _show(io, mime, rpt)

Base.showable(::MIME"juliavscode/html", ::LazyReport) = true
function Base.show(@nospecialize(io::IO), ::MIME"juliavscode/html", rpt::LazyReport)
    show(io, MIME("text/html"), rpt)
end


"""
    LazyTable.render_element(io::IO, mime::MIME, obj::Any)

Render `obj` for the given `mime` type to `io`.

Defaults to `show(io, mime, obj)`, with `show(io, MIME("text/plain"), obj)`
as a fallback if `showable(mime, obj) == false`.

Should be specialized for specific combinations of MIME and object types if
specialization of `Base.show` would be too broad.
"""
function render_element end

function render_element(@nospecialize(io::IO), @nospecialize(mime::MIME), @nospecialize(obj))
    if Tables.istable(obj)
        render_element(io, mime, lazytable(obj))
    else
        _render_element_impl(io, mime, obj)
    end
end

function _render_element_impl(@nospecialize(io::IO), @nospecialize(mime::MIME), @nospecialize(obj))
    if showable(mime, obj)
        show(io, mime, obj)
    else
        render_element(io, MIME("text/plain"), obj)
    end
end

function _render_element_impl(@nospecialize(io::IO), ::MIME"text/plain", @nospecialize(obj))
    show(io, MIME("text/plain"), obj)
end


"""
    LazyTable.render_inline(io::IO, mime::MIME, obj::Any)

Render `obj` as inline content for the given `mime` type to `io`.

Defaults to [`render_element(io, mime, obj)`](@ref) and may be specialized for
specific combinations of MIME and object types.
"""
function render_inline end

function render_inline(@nospecialize(io::IO), @nospecialize(mime::MIME), @nospecialize(obj))
    if showable(mime, obj)
        ioctx = IOContext(io, :compact => true)
        show(ioctx, mime, obj)
    else
        render_inline(io, MIME("text/plain"), obj)
    end
end

render_inline(@nospecialize(io::IO), ::MIME"text/plain", @nospecialize(obj::AbstractString)) = print(io, obj)

function render_inline(@nospecialize(io::IO), ::MIME"text/plain", @nospecialize(A::AbstractArray))
    ioctx = IOContext(io, :compact => true)
    # show(ioctx, MIME("text/plain"), A::AbstractArray) produces multi-line
    # output, so use
    show(ioctx, A)
end

render_inline(@nospecialize(io::IO), ::MIME"text/plain", @nospecialize(obj::Symbol)) = print(io, obj)
render_inline(@nospecialize(io::IO), ::MIME"text/plain", @nospecialize(obj::Expr)) = print(io, obj)

render_inline(@nospecialize(io::IO), ::MIME"text/html", @nospecialize(obj::Symbol)) = _render_inline_code_to_html(io, obj)
render_inline(@nospecialize(io::IO), ::MIME"text/html", @nospecialize(obj::Expr)) = _render_inline_code_to_html(io, obj)

function _render_inline_code_to_html(@nospecialize(io::IO), @nospecialize(obj))
    print(io, "<code>")
    print(io, obj)
    print(io, "</code>")
end


"""
    LazyTable.render_intable(io::IO, mime::MIME, obj::Any)

Render `obj` as table cell content for the given `mime` type to `io`.

Defaults to [`render_inline(io, mime, obj)`](@ref) and may be specialized for
specific combinations of MIME and object types.
"""
function render_intable end

render_intable(@nospecialize(io::IO), @nospecialize(mime::MIME), @nospecialize(obj)) = render_inline(io, mime, obj)


"""
    lazyreport()
    lazyreport(contents...)
    lazyreport(contents...)

Generate a lazy report, e.g. a data processing report.

Use [`lazyreport!(rpt, contents...)`](@ref) to add more content to a report.

Example:

```julia
using LazyReports, StructArrays, IntervalSets, Plots

tbl = StructArray(
    col1 = rand(5), col2 = ClosedInterval.(rand(5), rand(5).+1),
    col3 = [rand(3) for i in 1:5], col4 = rand(Bool, 5),
    col5 = [:a, :b, :c, :d, :e], col6 = ["a", "b", "c", "d", "e"],
    col7 = [:(a[1]), :(a[2]), :(a[3]), :(a[4]), :(a[5])]
)

rpt = lazyreport(
    "# New report",
    "Table 1:", tbl
)
lazyreport!(rpt, "Figure 1:", stephist(randn(10^3)))
lazyreport!(rpt, "Figure 2:", histogram2d(randn(10^4), randn(10^4), format = :png))

show(stdout, MIME"text/plain"(), rpt)
show(stdout, MIME"text/html"(), rpt)
show(stdout, MIME"text/markdown"(), rpt)

write_lazyreport("report.txt", rpt)
write_lazyreport("report.html", rpt)
write_lazyreport("report.md", rpt)
```

# Implementation

Do not specilialize `lazyreport` directly, specialize the lower-level function
[`LazyReports.pushcontent!`](@ref) instead.
"""
function lazyreport end
export lazyreport


lazyreport() = LazyReport(Any[])
function lazyreport(contents...)
    rpt = lazyreport()
    for content in contents
        lazyreport!(rpt, content)
    end
    return rpt
end


"""
    lazyreport!(rpt::LazyReport, contents...)

Add more content to report `rpt`. See [`lazyreport`](@ref) for an example.

# Implementation

Do not specialize `lazyreport!(rpt::LazyReport, obj::MyType)` directly,
specialize the lower-level function [`LazyReports.pushcontent!`](@ref)
instead.
"""
function lazyreport!(rpt::LazyReport, @nospecialize(contents...))
    for content in contents
        pushcontent!(rpt, content)
    end
    return rpt
end
export lazyreport!


"""
    LazyReports.pushcontent!(rpt::LazyReport, obj)

Lower-level function to add a single object to report `rpt`.

Users should call [`lazyreport!(rpt, obj)`](@ref) instead, but should
specialize `LazyReports.pushcontent!(rpt::LazyReport, obj::MyType)`
to control how objects of specific types are added to reports (e.g. by
converting them to Markdown, tables or other content types first.

The return value of `pushcontent!` is undefined and should be ignored.

# Implementation

Specialized methods of `pushcontent!` that convert `obj` to types already
supported by `LazyReport` should preferably call `lazyreport!` internally
instead of call `pushcontent!` again directly.
"""
function pushcontent! end

function pushcontent!(rpt::LazyReport, @nospecialize(obj))
    push!(rpt._contents, obj)
    return rpt
end



function pushcontent!(rpt::LazyReport, content::Markdown.MD)
    # Need to make a copy here to prevent recursive self-modification during
    # show-transformation:
    content_content_copy = copy(content.content)

    if isempty(rpt._contents) || !(rpt._contents[end] isa Markdown.MD)
        push!(rpt._contents, Markdown.MD(content_content_copy))
    else
        append!(rpt._contents[end].content, content_content_copy)
    end
    return nothing
end

function pushcontent!(rpt::LazyReport, @nospecialize(markdown_str::AbstractString))
    pushcontent!(rpt, Markdown.parse(markdown_str))
end


"""
    write_lazyreport(filename::AbstractString, rpt::LazyReport)
    write_lazyreport(filename::AbstractString, mime::MIME, rpt::LazyReport)

Write lazyreport `rpt` to file `filename`.
"""
function write_lazyreport end
export write_lazyreport

function write_lazyreport(@nospecialize(filename::AbstractString), @nospecialize(mime::MIME), rpt::LazyReport)
    open(filename, "w") do io
        show(io, mime, rpt)
    end
end

function write_lazyreport(@nospecialize(filename::AbstractString), rpt::LazyReport)
    _, ext = splitext(filename)
    mime = mime_from_extension(ext)
    write_lazyreport(filename, mime, rpt)
end
