--!strict
--!native
--!optimize 2

const external = require("./types")
const logging = require("../core_logging/types")

const format_error = require("../core_logging/format_error")

const function default_log_warn(message: string, context: logging.LogContext?)
	print(format_error(message, debug.traceback(nil, 3), context))
end
const function default_log_error(message: string, err: (logging.Error | string)?, context: logging.LogContext?): never
	error(format_error(message, err, context))
end
const function default_log_error_nonfatal(message: string, err: (logging.Error | string)?, context: logging.LogContext?)
	print(format_error(message, err, context))
end

local current_logger: external.ExternalLogger? = nil
local current_log_warn: (message: string, context: logging.LogContext?) -> () = default_log_warn
local current_log_error: (message: string, err: (logging.Error | string)?, context: logging.LogContext?) -> never =
	default_log_error
local current_log_error_nonfatal: (message: string, err: (logging.Error | string)?, context: logging.LogContext?) -> () =
	default_log_error_nonfatal

const function set_logger(new_logger: external.ExternalLogger?)
	const old_logger = current_logger

	if new_logger ~= nil then
		current_log_warn = new_logger.log_warn
		current_log_error = new_logger.log_error
		current_log_error_nonfatal = new_logger.log_error_nonfatal
	else
		current_log_warn = default_log_warn
		current_log_error = default_log_error
		current_log_error_nonfatal = default_log_error_nonfatal
	end

	current_logger = new_logger

	return old_logger
end

const function log_warn(message: string, context: logging.LogContext?)
	current_log_warn(message, context)
end

const function log_error(message: string, err: logging.Error | string?, context: logging.LogContext?): never
	current_log_error(message, err, context)
	error(external.fallback_error) -- fallback error incase the external log_error did not throw like it should've
end

const function log_error_nonfatal(message: string, err: logging.Error | string?, context: logging.LogContext?)
	current_log_error_nonfatal(message, err, context)
end

return {
	set_logger = set_logger,
	log_warn = log_warn,
	log_error = log_error,
	log_error_nonfatal = log_error_nonfatal,
}
