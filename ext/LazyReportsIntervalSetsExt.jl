# This file is a part of LazyReports.jl, licensed under the MIT License (MIT).

module LazyReportsIntervalSetsExt

import LazyReports
using LazyReports: _show_plain_compact

using IntervalSets: AbstractInterval

LazyReports._markdown_cell_content(@nospecialize(content::AbstractInterval)) = _show_plain_compact(content)

end # module IntervalSetsExt
