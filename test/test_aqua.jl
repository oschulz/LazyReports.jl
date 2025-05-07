# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

import Test
import Aqua
import LazyReports

Test.@testset "Package ambiguities" begin
    Test.@test isempty(Test.detect_ambiguities(LazyReports))
end # testset

Test.@testset "Aqua tests" begin
    Aqua.test_all(
        LazyReports,
        ambiguities = true,
    )
end # testset
