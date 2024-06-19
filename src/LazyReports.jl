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

@static if !isdefined(Base, :get_extension)
    include("../ext/LazyReportsIntervalSetsExt.jl")
end

@static if !isdefined(Base, :get_extension)
    using Requires
end

function __init__()
    @static if !isdefined(Base, :get_extension)
        @require Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80" include("../ext/LazyReportsPlotsExt.jl")
    end
end

end # module
