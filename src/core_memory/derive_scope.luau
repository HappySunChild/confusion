local memory = require("./types")

local ExternalDebug = require("../core_external/ExternalDebug")
local track_scope = ExternalDebug.track_scope

local merge = require("./merge")

local function derive_scope<S, M>(existing: memory.Scope<S>, methods: M?): memory.Scope<S & M>
	local old_metatable = getmetatable(existing) :: S?
	local new_metatable = if methods == nil
		then old_metatable -- reuse old metatable because nothing is being changed.
		else {
			__index = if old_metatable == nil or type(old_metatable.__index) ~= "table"
				then methods -- just use the methods since we don't have anything to merge with.
				else merge(true, table.clone(old_metatable.__index), methods), -- merge since both __index and methods are valid.
		}

	local derived_scope = setmetatable({}, new_metatable)

	track_scope(derived_scope)

	return derived_scope
end

return derive_scope
