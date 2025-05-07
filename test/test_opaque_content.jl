# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

using LazyReports
using Test


@testset "opaque_content" begin
    op = OpaqueContent(MIME("text/plain")) do io
        println(io, "Hello, World!")
    end
    @test op isa OpaqueContent{Symbol("text/plain")} 
    @test showable(MIME("text/plain"), op)
    @test let io = IOBuffer()
        show(io, MIME("text/plain"), op)
        take!(io) == op.data
    end

    op = OpaqueContent(MIME("text/html")) do io
        println(io, "<p>Hello, World!</p>")
    end
    @test op isa OpaqueContent{Symbol("text/html")} 
    @test showable(MIME("text/html"), op)
    @test let io = IOBuffer()
        show(io, MIME("text/html"), op)
        take!(io) == op.data
    end
end
