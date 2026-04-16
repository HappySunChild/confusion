local external = require("./types")
local logging = require("../core_logging/types")

local format_error = require("../core_logging/format_error")

local default_log_warn = print
local default_log_error = error
local default_log_error_nonfatal = print

local active_logger: external.ExternalLogger? = nil
local active_log_warn: (message: string) -> () = default_log_warn
local active_log_error: (message: string, level: number?) -> never = default_log_error
local active_log_error_nonfatal: (message: string) -> () = default_log_error_nonfatal

return table.freeze({
	set_logger = function(new_logger: external.ExternalLogger?)
		local old_logger = active_logger

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
	log_warn = function(message: string, ...: any)
		local formatted_message = format_error(message, debug.traceback(nil, 2), ...)

		active_log_warn(formatted_message)
	end,
	log_error = function(message: string, err: logging.Error?, ...: any): never
		local formatted_message = format_error(message, err, ...)

		active_log_error(formatted_message, 0)
	end,
	log_error_nonfatal = function(message: string, err: logging.Error?, ...: any)
		local formatted_message = format_error(message, err, ...)

		active_log_error_nonfatal(formatted_message)
	end,
})
