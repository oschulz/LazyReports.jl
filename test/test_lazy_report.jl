# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

using LazyReports
using Test

using StructArrays, StatsBase, IntervalSets, Plots


@testset "lazy_report" begin
    @test lazyreport() isa LazyReports.LazyReport

    @test lazyreport("Hello", nothing, missing, "World!") == lazyreport("Hello", "World!")

    tbl = StructArray(
        col1 = rand(5), col2 = ClosedInterval.(rand(5), rand(5).+1),
        col3 = [rand(3) for i in 1:5], col4 = rand(Bool, 5),
        col5 = [:a, :b, :c, :d, :e], col6 = ["a", "b", "c", "d", "e"],
        col7 = [:(a[1]), :(a[2]), :(a[3]), :(a[4]), :(a[5])],
        col9 = [fit(Histogram, rand()^3 * 1000 * randn(10^4), nbins = 50) for i in 1:5],
    )

    hist = fit(Histogram, randn(10^4), range(-4, 4, length = 100))

    rpt = lazyreport(
        "# New report",
        "Table 1:", tbl,
        "Histogram 1", hist,
    )
    lazyreport!(rpt, "Figure 1:", stephist(randn(10^3)))
    new_rpt = lazyreport!(rpt, "Figure 2:", histogram2d(randn(10^4), randn(10^4), format = :png))

    @test new_rpt === rpt

    # For some reason need to run this once before UnicodePlots rendering will get active:
    show(IOBuffer(), MIME("text/plain"), rpt)

    buf = IOBuffer()
    show(buf, MIME("text/plain"), rpt)
    bufstr = String(take!(buf))
    @test contains(bufstr, "Figure 1")
    @test !contains(bufstr, "Plot{")

    buf = IOBuffer()
    show(buf, MIME"text/html"(), rpt)
    bufstr = String(take!(buf))
    @test contains(bufstr, "<table>")

    buf = IOBuffer()
    show(buf, MIME"text/markdown"(), rpt)
    bufstr = String(take!(buf))
    @test contains(bufstr, "# New report")

    mktempdir() do dir
        write_lazyreport(joinpath(dir, "report.txt"), rpt)
        content = read(joinpath(dir, "report.txt"), String)
        @test contains(content, "Figure 1")
        @test !contains(content, "Plot{")

        write_lazyreport(joinpath(dir, "report.html"), rpt)
        @test contains(read(joinpath(dir, "report.html"), String), "<table>")

        write_lazyreport(joinpath(dir, "report.md"), rpt)
        @test contains(read(joinpath(dir, "report.md"), String), "# New report")
    end
end
