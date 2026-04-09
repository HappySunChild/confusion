local instances = require("../types")

local apply_properties = require("../apply_properties")

return {
	type = "SpecialKey",
	kind = "Passthrough",
	stage = "properties",
	apply = apply_properties,
} :: instances.SpecialKey<"Passthrough">
