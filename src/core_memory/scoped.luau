const memory = require("./types")

const ExternalDebug = require("../core_external/ExternalDebug")
const track_scope = ExternalDebug.track_scope

const merge = require("./merge")

const function scoped<S, M>(base: S?, methods: M?): memory.Scope<S & M>
	const new_scope = if base == nil and methods == nil
		then {}
		else setmetatable({}, {
			__index = if base == nil and methods ~= nil
				then methods
				elseif base ~= nil and methods == nil then base
				else merge(table.clone(base), methods),
		})

	track_scope(new_scope)

	return new_scope
end

return scoped
