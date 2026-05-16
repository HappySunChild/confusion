const memory = require("./types")

const ExternalDebug = require("../core_external/ExternalDebug")
const track_scope = ExternalDebug.track_scope

const merge = require("./merge")

const function derive_scope<S, M>(existing: memory.Scope<S>, methods: M?): memory.Scope<S & M>
	const old_metatable = getmetatable(existing) :: S?
	const new_metatable = if methods == nil
		then old_metatable -- reuse old metatable because nothing is being changed.
		else {
			__index = if old_metatable == nil or type(old_metatable.__index) ~= "table"
				then methods -- just use the methods since we don't have anything to merge with.
				else merge(table.clone(old_metatable.__index), methods), -- merge since both __index and methods are valid.
		}

	const derived_scope = setmetatable({}, new_metatable)

	track_scope(derived_scope)

	return derived_scope
end

return derive_scope
