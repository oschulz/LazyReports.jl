# LazyReports.jl

LazyReports provides report generation with minimal dependencies, depending on LazyReports should have minimal load-time impact for Julia packages. Reports are a mixture and data objects, and are lazy in the sense that they are both easy to create and that contents are only rendered when the reports is displayed to written to a file. This way, reports can be generated as part of algorithms and workflows with only a small runtime overhead.

The central function of the package is [`lazyreport`](@ref), it generates a report object that can be rendered (via `show` and `display`) with different MIME types. [`lazyreport`](@ref) allows for appending content to reports.

Reports should be displayed automatically on the REPL (as far as supported by the objects in the reports), in Jupyter and Pluto notebooks and in Visual Studio Code (when using the Julia extension). Reports can also be written to files using [`write_lazyreport`](@ref).

In addition to types that can be shown in the MIME type of the current Julia display anyway, LazyReports (so far) has special support for `StatsBase.Histogram` (one-dimensional).

For example:

```@example rptexample
using LazyReports, StructArrays, StatsBase, Plots

tbl = StructArray(
    col1 = rand(5),
    col2 = [rand(3) for i in 1:5],
    col3 = [:(a[1]), :(a[2]), :(a[3]), :(a[4]), :(a[5])],
    col4 = [fit(Histogram, rand()^3 * 1000 * randn(10^4), nbins = 50) for i in 1:5],
)

rpt = lazyreport(
    "# New report",
    "Table 1:", tbl
)
lazyreport!(rpt, "Figure 1:", stephist(randn(10^3)))
lazyreport!(rpt, "Figure 2:", histogram2d(randn(10^4), randn(10^4), format = :png))
```

## Lazy tables

[`lazytable`](@ref) allows to wrap [Tables](https://github.com/JuliaData/Tables.jl)-compatible object and add custom column labels.


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
