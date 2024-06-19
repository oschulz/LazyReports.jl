# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

import Test

Test.@testset "Package LazyReports" begin
    include("test_aqua.jl")
    include("test_lazy_report.jl")
    include("test_docs.jl")
end # testset
