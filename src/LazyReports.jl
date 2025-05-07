# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

"""
    LazyReports

Lazy reports in Julia.
"""
module LazyReports

import Markdown
import Tables

using MIMEs: mime_from_extension

include("adapt_to.jl")
include("lazy_report.jl")

end # module
