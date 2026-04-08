local instances = require("./types")
local memory = require("../core_memory/types")

local CLASS = table.freeze({
	type = "SpecialKey",
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function SpecialKey(
	stage: instances.SpecialKeyStage,
	kind: string,
	apply_callback: (
		scope: memory.Scope,
		apply_to: Instance,
		value: unknown
	) -> ()
)
	return table.freeze(setmetatable({
		stage = stage,
		kind = kind,
		apply = apply_callback,
	}, CLASS_METATABLE))
end

return SpecialKey
