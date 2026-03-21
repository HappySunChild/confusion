local external = require("../core_external/types")

local RobloxLogger: external.ExternalLogger = {
	log_error_nonfatal = function(message: string)
		task.spawn(error, message, 0)
	end,
	log_error = error,
	log_warn = warn,
}

return table.freeze(RobloxLogger)
