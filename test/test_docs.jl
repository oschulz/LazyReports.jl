# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

using Test
using LazyReports
import Documenter

Documenter.DocMeta.setdocmeta!(
    LazyReports,
    :DocTestSetup,
    :(using LazyReports);
    recursive=true,
)
Documenter.doctest(LazyReports)
