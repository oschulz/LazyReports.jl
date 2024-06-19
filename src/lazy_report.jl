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

function Base.show(@nospecialize(io::IO), rpt::LazyReport)
    show(io, MIME("text/plain"), rpt)

    #for x in rpt._contents
    #    show(io, x)
    #    println(io)
    #end
end


function Base.show(@nospecialize(io::IO), mime::MIME"text/plain", rpt::LazyReport)
    r_conv = lazyreport_for_show!(lazyreport(), mime, rpt)
    for x in r_conv._contents
        _show_report_element_plain(io, x)
        println(io)
    end
end

function _show_report_element_plain(@nospecialize(io::IO), @nospecialize(x))
    show(io, MIME("text/plain"), x)
end


function Base.show(@nospecialize(io::IO), mime::MIME"text/html", rpt::LazyReport)
    r_conv = lazyreport_for_show!(lazyreport(), mime, rpt)
    for x in r_conv._contents
        _show_report_element_html(io, x)
        println(io)
    end
end

function _show_report_element_html(@nospecialize(io::IO), @nospecialize(x))
    if showable(MIME("text/html"), x)
        show(io, MIME("text/html"), x)
    else
        _show_report_element_plain(io, x)
    end
end


function Base.show(@nospecialize(io::IO), mime::MIME"text/markdown", rpt::LazyReport)
    r_conv = lazyreport_for_show!(lazyreport(), mime, rpt)
    for x in r_conv._contents
        _show_report_element_markdown(io, x)
        #println(io)
    end
end

function _show_report_element_markdown(@nospecialize(io::IO), @nospecialize(x))
    if showable(MIME("text/markdown"), x)
        show(io, MIME("text/markdown"), x)
    else
        _show_report_element_html(io, x)
    end
end


function Base.show(@nospecialize(io::IO), ::MIME"juliavscode/html", rpt::LazyReport)
    show(io, MIME("text/html"), rpt)
end



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

See [`LazyReports.lazyreport_for_show!`](@ref) for how to specialize the
behavior of `show` for specific report content types.
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
"""
function lazyreport! end
export lazyreport!


function lazyreport!(rpt::LazyReport, @nospecialize(content))
    push!(rpt._contents, content)
    return rpt
end

function lazyreport!(rpt::LazyReport, @nospecialize(contents...))
    for content in contents
        lazyreport!(rpt, content)
    end
    return rpt
end


function lazyreport!(rpt::LazyReport, content::Markdown.MD)
    # Need to make a copy here to prevent recursive self-modification during
    # show-transformation:
    content_content_copy = copy(content.content)

    if isempty(rpt._contents) || !(rpt._contents[end] isa Markdown.MD)
        push!(rpt._contents, Markdown.MD(content_content_copy))
    else
        append!(rpt._contents[end].content, content_content_copy)
    end
    return rpt
end

function lazyreport!(rpt::LazyReport, @nospecialize(markdown_str::AbstractString))
    lazyreport!(rpt, Markdown.parse(markdown_str))
end

#lazyreport!(rpt::LazyReport, @nospecialize(number::AbstractFloat)) = lazyreport!(rpt, string(round(number, digits=3)))
#lazyreport!(rpt::LazyReport, @nospecialize(number::Unitful.Quantity{<:Real})) = lazyreport!(rpt, string(round(unit(number), number, digits=3)))


"""
    LazyReports.lazyreport_for_show!(rpt::LazyReport, mime::MIME, content)

Add the contents of `content` to `rpt` in a way that is optimized for being
displayed (e.g. via `show`) with the given `mime` type.

`show(output, mime, rpt)` first transforms `rpt` by converting all contents of
`rpt` using `lazyreport_for_show!(rpt::LazyReport, mime, content)`.

Defaults to `lazyreport!(rpt, content)`, except for tables
(`Tables.istable(content) == true`), which are converted to Markdown tables
by default for uniform appearance.

`lazyreport_for_show!` is not inteded to be called by users, but to be
specialized for specific types of content `content`. Content types not already
supported will primarily require specialization of

```julia
lazyreport_for_show!(rpt::LazyReport, ::MIME"text/markdown", content::SomeType)
```

In some cases it may be desireable to specialize `lazyreport_for_show!` for
MIME types like `MIME"text/html"` and `MIME"text/plain"` as well.
"""
function lazyreport_for_show! end

function lazyreport_for_show!(rpt::LazyReport, mime::MIME, content::LazyReport)
    for c in content._contents
        lazyreport_for_show!(rpt, mime, c)
    end
    return rpt
end

function lazyreport_for_show!(rpt::LazyReport, ::MIME, @nospecialize(content))
    if Tables.istable(content)
        lazyreport!(rpt, Markdown.MD(_markdown_table(content)))
    else
        lazyreport!(rpt, content)
    end
end

_table_columnnames(tbl) = keys(Tables.columns(tbl))
_default_table_headermap(tbl) = Dict(k => string(k) for k in _table_columnnames(tbl))

_markdown_cell_content(@nospecialize(content)) = content
_markdown_cell_content(@nospecialize(content::AbstractString)) = String(content)
_markdown_cell_content(@nospecialize(content::Symbol)) = string(content)
_markdown_cell_content(@nospecialize(content::Expr)) = string(content)
_markdown_cell_content(@nospecialize(content::Number)) = _show_plain_compact(content)
_markdown_cell_content(@nospecialize(content::Array)) = _show_plain_compact(content)


_show_plain_compact(@nospecialize(content)) = sprint(show, content; context = :compact=>true)

function _markdown_table(
    tbl;
    headermap::Dict{Symbol,<:AbstractString} = _default_table_headermap(tbl),
    align::AbstractVector{Symbol} = fill(:l, length(Tables.columns(tbl)))
)
    content = Vector{Any}[Any[headermap[k] for k in keys(Tables.columns(tbl))]]
    for rpt in Tables.rows(tbl)
        push!(content, [_markdown_cell_content(content) for content in values(rpt)])
    end
    Markdown.Table(content, align)
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
