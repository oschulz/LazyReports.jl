# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

using LazyReports
using Test

using LazyReports: LazyReport
using Typstry: typst, @typst_str
import Markdown


@testset "test_typstry" begin
    t = typst"$ sum_(i=1)^n x_i$"

    @test showable(MIME("image/svg+xml"), t)

    @test lazyreport("#Report", t, "Some text.") isa LazyReport

    r = lazyreport("#Report", t, "Some text.")
    @test r._contents == [Markdown.parse("#Report"), t, Markdown.parse("Some text.")]
end
