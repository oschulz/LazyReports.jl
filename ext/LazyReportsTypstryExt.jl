# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

module LazyReportsTypstryExt

import LazyReports
using LazyReports: LazyReport

using Typstry: TypstString

function LazyReports.pushcontent!(rpt::LazyReport, @nospecialize(obj::TypstString))
    push!(rpt._contents, obj)
    return rpt
end

end # module LazyReportsPlotsExt
