# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

"""
    LazyReports

Lazy reports in Julia.
"""
module LazyReports

import Markdown
import Tables

using MIMEs: mime_from_extension
using Printf: @sprintf

include("lazy_table.jl")
include("lazy_report.jl")
include("opaque_content.jl")

end # module
