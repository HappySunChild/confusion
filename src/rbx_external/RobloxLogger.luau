const LogService = game:GetService("LogService")

const external = require("../core_external/types")
const logging = require("../core_logging/types")

const format_error = require("../core_logging/format_error")

return {
	log_warn = function(message: string, context: logging.LogContext?)
		LogService:Warn(format_error(message, debug.traceback("WARN TRACEBACK", 3)), context)
	end,
	log_error = function(message: string, err: logging.Error | string?, context: logging.LogContext?)
		LogService:Error(format_error(message, err), context)
	end,
	log_error_nonfatal = function(message: string, err: logging.Error | string?, context: logging.LogContext?)
		LogService:Info(format_error(message, err), context)
	end,
} :: external.ExternalLogger
