const external = require("../core_external/types")

return {
	log_error_nonfatal = function(message: string)
		task.spawn(error, message, 0)
	end,
	log_error = error,
	log_warn = warn,
} :: external.ExternalLogger
