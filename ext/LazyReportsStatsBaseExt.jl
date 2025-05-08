# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

module LazyReportsStatsBaseExt

import StatsBase
import LazyReports

using StatsBase: Histogram, Weights, mean, median

using Printf: @sprintf


function LazyReports.render_inline(@nospecialize(io::IO), ::MIME"text/plain", @nospecialize(obj::Histogram{<:Real,1}))
    showhist_unicode(io, obj)
end

function LazyReports.render_element(@nospecialize(io::IO), ::MIME"text/plain", @nospecialize(obj::Histogram{<:Real,1}))
    showhist_unicode(io, obj)
end

const unicode_vbar_chars = ['\u2800', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█']

function showhist_unicode(io::IO, h::Histogram{<:Real,1})
    edge = only(h.edges)

    if !(edge isa AbstractRange)
        print(io, "[non-uniform histogram]")
        return
    end

    W = h.weights
    bins_left = edge[begin:end-1]
    bins_right = edge[begin+1:end]
    bincenters = (bins_left + bins_right) / 2

    symidxs = eachindex(unicode_vbar_chars)
    norm_factor = length(symidxs) / maximum(W)
    get_sym_idx(x) = isnan(x) ? 1 : clamp(first(symidxs) + floor(Int, norm_factor * x), first(symidxs), last(symidxs))

    mean_idx = StatsBase.binindex(h, mean(bincenters, Weights(W)))
    median_idx = StatsBase.binindex(h, median(bincenters, Weights(W)))
    
    print(io, replace(lpad(@sprintf("%8.3g", minimum(edge)), 8, '\u2800'), " " => "\u2800"))
    print(io, h.closed == :left ? "[" : "]")
    for (i) in eachindex(W)
        color = if i == mean_idx == median_idx
            :cyan
        elseif i == mean_idx
            :green
        elseif i == median_idx
            :blue
        else
            :default
        end
        sym = unicode_vbar_chars[get_sym_idx(W[i])]
        printstyled(io, sym; color=color)
    end
    print(io, h.closed == :right ? "]" : "[")
    print(io, replace(lpad(@sprintf("%-8.3g", maximum(edge)), 8, '\u2800'), " " => "\u2800"))
end


function LazyReports.render_element(@nospecialize(io::IO), ::MIME"text/html", @nospecialize(obj::Histogram{<:Real,1}))
    showhist_html(io, obj)
end

function showhist_html(io::IO, h::Histogram{<:Real,1}; height::AbstractString = "8em")
    edge = only(h.edges)

    label_left = @sprintf("%8.3g", edge[begin])
    label_right = @sprintf("%-8.3g", edge[end])

    print(io, "<div style=\"white-space:nowrap; margin-bottom:0em;\">")
    (;mean_value, median_value) = show_barhist1d_svg(io, h; width="100%", height=height)
    print(io, "</div>")

    mean_str = @sprintf("%8.3g", mean_value)
    median_str = @sprintf("%8.3g", median_value)

    print(io, "<div style=\"white-space:nowrap; margin-top:0em;\">")
    print(io, "<span style=\"display: inline-block; width: 20%; text-align: left;\">", h.closed == :left ? "[" : "]", label_left, "</span>")
    print(io, "<span style=\"display: inline-block; width: 30%; text-align: center; color:green;\">", "mean: ", mean_str, "</span>")
    print(io, "<span style=\"display: inline-block; width: 30%; text-align: center; color:steelblue;\">", "median: ", median_str, "</span>")
    print(io, "<span style=\"display: inline-block; width: 20%; text-align: right;\">", label_right, h.closed == :right ? "]" : "[", "</span>")
    print(io, "</div>")
end


function LazyReports.render_inline(@nospecialize(io::IO), ::MIME"text/html", @nospecialize(obj::Histogram{<:Real,1}))
    showhist_html_inline(io, obj)
end

function showhist_html_inline( io::IO, h::Histogram{<:Real,1}; graph_relwidth::Real = 0.70)
    edge = only(h.edges)

    graphwidth = "$(round(Int, 100 * graph_relwidth))%"
    labelwidth = "$(round(Int, 100 * (1-graph_relwidth)/2))%"

    label_left = @sprintf("%8.3g", edge[begin])
    label_right = @sprintf("%-8.3g", edge[end])

    print(io, "<div style=\"white-space:nowrap;\">")
    print(io, "<span style=\"display: inline-block; width: ", labelwidth, "; text-align: right; font-size: 70%;\">", label_left, h.closed == :left ? "[" : "]", "</span>")
 
    show_barhist1d_svg(io, h; width=graphwidth, height="1em")

    print(io, "<span style=\"display: inline-block; width: ", labelwidth, "; text-align: left; font-size: 70%;\">", h.closed == :right ? "]" : "[", label_right, "</span>")
    print(io, "</div>")
end


function print_svg_rect(@nospecialize(io::IO), x::Real, y::Real, width::Real, height::Real, color::AbstractString)
    print(io, "<rect x=\"", x, "\" y=\"", y, "\" width=\"", width, "\" height=\"", height, "\" fill=\"", color, "\"/>")
end

function show_barhist1d_svg(
    io::IO, h::Histogram{<:Real,1};
    avg_barwidth::Real = 1, bargap::Real = 0, width::AbstractString = "100%", height::AbstractString = "1em",
)
    edge, weights = only(h.edges), h.weights

    Y = weights / maximum(weights)
    nbins = length(Y)
    bins_left = edge[begin:end-1]
    bins_right = edge[begin+1:end]
    bincenters = (bins_left + bins_right) / 2
    binwidths = bins_right - bins_left
    mean_binwidth = (edge[end] - edge[begin]) / nbins
    X = (bins_left .- bins_left[begin]) ./ mean_binwidth
    W = binwidths ./ mean_binwidth

    mean_value = mean(bincenters, Weights(Y))
    median_value = median(bincenters, Weights(Y))
    mean_idx = StatsBase.binindex(h, mean_value)
    median_idx = StatsBase.binindex(h, median_value)
 
    nbins = length(Y)
    total_width = nbins * avg_barwidth + max(0, nbins-1) * bargap
    print(io, "<svg height=\"", height, "\" width=\"", width, "\" viewBox=\"0 0 ", total_width, " ", 1, "\" preserveAspectRatio=\"none\" shape-rendering=\"crispEdges\" style=\"vertical-align:bottom;\">")
    for i in eachindex(Y)
        color = i == mean_idx == median_idx ? "teal" : (i == mean_idx ? "green" : (i == median_idx ? "steelblue" : "currentColor"))
        barheight = Y[i]
        xpos = X[i] * (avg_barwidth + bargap)
        print_svg_rect(io, xpos, 1 - barheight, W[i] * avg_barwidth, barheight, color)
    end
    print(io, "</svg>")
    return (mean_value = mean_value, median_value = median_value)
end


end # module LazyReportsStatsBaseExt
