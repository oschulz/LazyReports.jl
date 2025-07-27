# LazyReports.jl

LazyReports provides report generation with minimal dependencies; thus, depending on LazyReports should have minimal load-time impact for Julia packages. Reports are a mixture of text and data objects, and are lazy in the sense that they are easy to create and their contents are only rendered when the report is displayed or written to a file. This way, reports can be generated as part of algorithms and workflows with only a small runtime overhead.

The central function of the package is [`lazyreport`](@ref). It generates a report object that can be rendered (via `show` and `display`) in different MIME types. [`lazyreport`](@ref) allows for appending content to reports.

Reports are displayed automatically in the REPL (as far as supported by the report objects), in Jupyter and Pluto notebooks, and in Visual Studio Code (when using the Julia extension). Reports can also be written to files using [`write_lazyreport`](@ref).

Any objects that can render to the current Julia display (resp. the chosen output MIME-type) should work fine, including [Plots.jl](https://github.com/JuliaPlots/Plots.jl) and [Makie.jl](https://github.com/MakieOrg/Makie.jl) plots, and so on. In addition, LazyReports also has special out-of-the-box support for `StatsBase.Histogram` (one-dimensional only).

For example:

```@example rptexample
using LazyReports, StructArrays, StatsBase, Markdown, Typstry, Plots

tbl = StructArray(
    col1 = rand(5),
    col2 = [rand(3) for i in 1:5],
    col3 = [:(a[1]), :(a[2]), :(a[3]), :(a[4]), :(a[5])],
    col4 = [fit(Histogram, rand()^3 * 1000 * randn(10^4), nbins = 50) for i in 1:5],
)

rpt = lazyreport(
    "# New report",
    "Table 1:", tbl,
    "Markdown math:",
    md"$\sum_{i=1}^n x_i$",
    "Typst math (via [Typstry](https://github.com/jakobjpeters/Typstry.jl)):",
    typst"$sum_(i=1)^n x_i$"
)
lazyreport!(rpt, "Figure 1:", stephist(randn(10^3)))
lazyreport!(rpt, "Figure 2:", histogram2d(randn(10^4), randn(10^4), format = :png))
```

The lower-level function [`LazyReports.pushcontent!`](@ref) can be specialized to control how objects of specific types are added to reports (e.g. by converting them to Markdown, tables or supported content types first).

## Lazy tables

[`lazytable`](@ref) wraps/converts Tables.jl-compatible objects and allows for adding custom column labels.

```@example rptexample
using IntervalSets

tbldata = (
    a = ClosedInterval.(rand(5), rand(5).+1),
    b = rand(Bool, 5),
    c = ["a", "b", "c", "d", "e"],
)

lazyreport(
    "# Table report",
    lazytable(tbldata, headers = Dict(:a => "Intervals", :b => "Booleans", :c => "Strings"))
)
```

## Rendering Plots

When rendering reports using `MIME("text/plain")`, e.g. when showing reports on the REPL and when writing reports to ".txt" files, LazyReports will try to convert Plots.jl plots to the `Plots.UnicodePlotsBackend`. UnicodePlots will be loaded automatically, but the package UnicodePlots must be part of your Julia environment or rendering will fail. Note that converting Plots generated with a different backend (e.g. the default GR backend) to UnicodePlots will not always yield satisfactory results, depending on the type of plot.
