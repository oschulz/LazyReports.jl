# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).


"""
    struct LazyReports.LazyTable

Represents a lazy table.

Supports `convert(::Type{Markdown.Table}, lt::LazyTable)`.

Don't instantiate directly, use [`lazytable`](@ref).
"""
struct LazyTable
    _headers::AbstractVector
    _columns::AbstractVector
    _nrows::Int
end


function Base.convert(::Type{Markdown.Table}, lt::LazyTable)
    align = fill(:l, length(lt._headers))
    content = Vector{Any}[Any[_markdown_cell_content(obj) for obj in lt._headers]]
    colvals = lt._columns
    colidxs = eachindex(colvals)
    for rel_i in 0:(lt._nrows-1)
        push!(content,
            [
                _markdown_cell_content(colvals[j][firstindex(colvals[j]) + rel_i])
                for j in colidxs
            ]
        )
    end
    return Markdown.Table(content, align)
end

function _markdown_cell_content(obj)
    # Doesn't seem to render properly as part of Markdown table (yet):
    #
    # OpaqueContent(MIME("text/markdown")) do io
    #     render_intable(io, MIME("text/markdown"), obj)
    # end
    #
    # So fall back to MIME("text/plain") for Markdown table cell contents:

    io = IOBuffer()
    render_intable(io, MIME("text/plain"), obj)
    content = String(take!(io))
    return content
end


Base.showable(mime::MIME"text/plain", ::LazyTable) = true
Base.showable(mime::MIME"text/markdown", ::LazyTable) = true

Base.show(io::IO, mime::MIME"text/plain", lt::LazyTable) = show(io, mime, _markdown_table(lt))
Base.show(io::IO, mime::MIME"text/markdown", lt::LazyTable) = show(io, mime, _markdown_table(lt))

_markdown_table(lt::LazyTable) = Markdown.MD(convert(Markdown.Table, lt))


Base.showable(mime::MIME"text/html", ::LazyTable) = true

function Base.show(io::IO, mime::MIME"text/html", lt::LazyTable)
    open_table, close_table = "<div>  <table>", "</table> </div>"
    open_tr, close_tr = "    <tr>", " </tr>"
    open_th, close_th = " <th align=\"left\">", "</th>"
    open_td, close_td = " <td align=\"left\">", "</td>"

    println(io, open_table)

    print(io, open_tr)
    for obj in lt._headers
        print(io, open_th)
        render_intable(io, mime, obj)
        print(io, close_th)
    end
    println(io, close_tr)

    colvals = lt._columns
    colidxs = eachindex(colvals)
    for rel_i in 0:(lt._nrows-1)
        print(io, open_tr) 
        for j in colidxs
            print(io, open_td)
            i = firstindex(lt._columns[1]) + rel_i
            render_intable(io, mime, colvals[j][i])
            print(io, close_td)
        end
        println(io, close_tr)
    end
    println(io, close_table)
end


"""
    lazytable(tbl; headers = missing)

Wrap `tbl` as a `LazyTable` to be used with [`lazyreport`](@ref).

If `headers` is `missing`, default headers are generated from the column
names of `tbl`. If `headers` is an `AbstractDict`, the default column
names are overridden according to the keys and values in it. If `headers` is
an `AbstractVector`, it explicitly defines all headers of the table and
must have the same length as the number of columns in `tbl`.
"""
function lazytable end
export lazytable

function lazytable(@nospecialize(tbl); @nospecialize(headers = missing))
    if Tables.istable(tbl)
        colnames = convert.(String, string.(collect(Tables.columnnames(tbl))))
        cols = Tables.columns(tbl)
        colvals = [Tables.getcolumn(cols, i) for i in eachindex(colnames)]
        nrows = Tables.rowcount(tbl)
        new_headers = _table_headers(colnames, headers)
        return LazyTable(new_headers, colvals, nrows)
    else
        throw(ArgumentError("tbl must be a Tables.jl compatible table"))
    end
end


_table_headers(@nospecialize(colnames), ::Missing) = colnames

function _table_headers(@nospecialize(colnames), @nospecialize(headermap::AbstractDict))
    conv_headermap = IdDict(convert(String, string(k)) => v for (k, v) in headermap)
    headers = [get(conv_headermap, cn, cn) for cn in colnames]
    return headers
end

function _table_headers(@nospecialize(colnames), @nospecialize(headers::AbstractVector))
    n, m = length(colnames), length(headers)
    if n == m 
        return headers
    else
        throw(ArgumentError("Can't use $m headers for $n columns in lazytable"))        
    end
end
