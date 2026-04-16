local rbx_instances = require("../types")

return {
	type = "SpecialKey",
	kind = "OnStartup",
	stage = "last",
	apply = function(_, apply_to: Instance, callback: (Instance) -> ())
		callback(apply_to)
	end,
} :: rbx_instances.SpecialKey<"OnStartup">
