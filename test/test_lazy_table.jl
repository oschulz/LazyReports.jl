# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

using LazyReports
using Test


@testset "lazy_table" begin
    tbl = Dict("z" => rand(5), "b" => rand(5), "a" => rand(5))
    @test lazytable(tbl) isa LazyReports.LazyTable
    lt = lazytable(tbl)
    @test sort(lt._headers) == sort(["z", "b", "a"])
    @test lt._nrows == 5

    tbl = (z = rand(5), b = rand(5), a = rand(5))
    @test lazytable(tbl) isa LazyReports.LazyTable
    lt = lazytable(tbl)
    @test lt._headers == ["z", "b", "a"]
    @test lt._columns == [tbl.z, tbl.b, tbl.a]
    @test lt._nrows == 5
    @test lazytable(tbl, headers = Dict("b" => "g", "h" => "k"))._headers == ["z", "g", "a"]
    @test lazytable(tbl, headers = [6, 2, 4])._headers == [6, 2, 4]
    @test_throws ArgumentError lazytable(tbl, headers = [6, 2])
end
