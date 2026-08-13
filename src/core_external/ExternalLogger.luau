const external = require("./types")
const logging = require("../core_logging/types")

const format_error = require("../core_logging/format_error")

const function default_log_warn(message: string, context: logging.LogContext?)
	print(format_error(message, debug.traceback(nil, 3), context))
end
const function default_log_error(message: string, err: logging.Error | string?, context: logging.LogContext?)
	error(format_error(message, err, context))
end
const function default_log_error_nonfatal(message: string, err: logging.Error | string?, context: logging.LogContext?)
	print(format_error(message, err, context))
end

local active_logger: external.ExternalLogger? = nil
local active_log_warn: (message: string, context: logging.LogContext?) -> () = default_log_warn
local active_log_error: (message: string, context: logging.LogContext?) -> never = default_log_error
local active_log_error_nonfatal: (message: string, context: logging.LogContext?) -> () = default_log_error_nonfatal

return {
	set_logger = function(new_logger: external.ExternalLogger?)
		const old_logger = active_logger

		if new_logger ~= nil then
			active_log_warn = new_logger.log_warn
			active_log_error = new_logger.log_error
			active_log_error_nonfatal = new_logger.log_error_nonfatal
		else
			active_log_warn = default_log_warn
			active_log_error = default_log_error
			active_log_error_nonfatal = default_log_error_nonfatal
		end

		active_logger = new_logger

		return old_logger
	end,
	log_warn = function(message: string, context: logging.LogContext?)
		active_log_warn(message, context)
	end,
	log_error = function(message: string, err: logging.Error | string?, context: logging.LogContext?): never
		active_log_error(message, err, context)

		error(external.fallback_error) -- fallback error incase the external log_error did not throw like it should've
	end,
	log_error_nonfatal = function(message: string, err: logging.Error | string?, context: logging.LogContext?)
		active_log_error_nonfatal(message, err, context)
	end,
}
