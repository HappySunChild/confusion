local SpecialKey = require("../SpecialKey")

return SpecialKey("last", "OnStartup", function(_, apply_to: Instance, callback: (Instance) -> ())
	callback(apply_to)
end)
