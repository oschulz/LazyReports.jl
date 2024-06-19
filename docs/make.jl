# Use
#
#     DOCUMENTER_DEBUG=true julia --color=yes make.jl local [nonstrict] [fixdoctests]
#
# for local builds.

using Documenter
using LazyReports

# Doctest setup
DocMeta.setdocmeta!(
    LazyReports,
    :DocTestSetup,
    :(using LazyReports);
    recursive=true,
)

makedocs(
    sitename = "LazyReports",
    modules = [LazyReports],
    format = Documenter.HTML(
        prettyurls = !("local" in ARGS),
        canonical = "https://oschulz.github.io/LazyReports.jl/stable/"
    ),
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
        "LICENSE" => "LICENSE.md",
    ],
    doctest = ("fixdoctests" in ARGS) ? :fix : true,
    linkcheck = !("nonstrict" in ARGS),
    warnonly = ("nonstrict" in ARGS),
)

deploydocs(
    repo = "github.com/oschulz/LazyReports.jl.git",
    forcepush = true,
    push_preview = true,
)
