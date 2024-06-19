# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

module LazyReportsPlotsExt

@static if isdefined(Base, :get_extension)
    import Plots
    using Plots: AbstractBackend, Plot, Subplot, SubplotMap

else
    import ..Plots
    using ..Plots: AbstractBackend, Plot, Subplot, SubplotMap
end

import LazyReports
using LazyReports: LazyReport

function LazyReports.lazyreport_for_show!(rpt::LazyReport, ::MIME"text/plain", @nospecialize(plt::Plot))
    pltbackend = Plots.UnicodePlotsBackend()
    new_plt = LazyReports.adapt_to(pltbackend, plt)
    LazyReports.lazyreport!(rpt, new_plt)
end

LazyReports.adapt_to(::B, plt::Plot{B}) where {B<:AbstractBackend} = plt

function LazyReports.adapt_to(pltbackend::B, plt::Plot) where  {B<:AbstractBackend}
    old_pltbackend = Plots.backend()
    try
        if pltbackend !== Plots.backend()
            Plots.backend(pltbackend)
        end

        new_plt = Plot()

        spmap = plt.spmap
        inv_spmap = Dict([v => k for (k, v) in spmap])
        new_spmap = Dict([k => LazyReports.adapt_to(new_plt, v) for (k, v) in spmap])
        new_subplots = [new_spmap[inv_spmap[s]] for s in plt.subplots]
        new_inset_subplots = [new_spmap[inv_spmap[s]] for s in plt.inset_subplots]

        new_plt.n = plt.n
        new_plt.attr = plt.attr
        new_plt.series_list = plt.series_list
        new_plt.o = plt.o
        new_plt.subplots = new_subplots
        new_plt.spmap = new_spmap
        new_plt.layout = plt.layout
        new_plt.inset_subplots = new_inset_subplots
        new_plt.init = plt.init
    
        return new_plt
    finally
        if old_pltbackend !== Plots.backend()
            Plots.backend(old_pltbackend)
        end
    end
end

LazyReports.adapt_to(::Plot{B}, subplt::Subplot{B}) where  {B<:AbstractBackend} = subplt

function LazyReports.adapt_to(parentplt::Plot{B}, subplt::Subplot) where  {B<:AbstractBackend}
    new_subplt = Subplot(parentplt.backend; parent = subplt.parent)
    new_subplt.series_list = subplt.series_list
    new_subplt.primary_series_count = subplt.primary_series_count
    new_subplt.minpad = subplt.minpad
    new_subplt.bbox = subplt.bbox
    new_subplt.plotarea = subplt.plotarea
    new_subplt.attr = subplt.attr
    new_subplt.o = nothing
    new_subplt.plt = parentplt

    return new_subplt
end

end # module LazyReportsPlotsExt
