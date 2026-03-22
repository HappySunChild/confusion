local memory = require("./types")

local ExternalDebug = require("../core_external/ExternalDebug")
local track_scope = ExternalDebug.track_scope

local merge = require("./merge")

local function scoped<S, M>(base: S?, methods: M?): memory.Scope<S & M>
	local new_scope = if base == nil and methods == nil
		then {}
		else setmetatable({}, {
			__index = if base == nil and methods ~= nil
				then methods
				elseif base ~= nil and methods == nil then base
				else merge(true, table.clone(base), methods),
		})

	track_scope(new_scope)

	return new_scope
end

return scoped
