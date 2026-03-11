local external = require("./types")
local logging = require("../core_logging/types")

local format_error = require("../core_logging/format_error")

local active_logger: external.ExternalLogger? = nil
-- local active_log_warn: (message: string) -> () = print
-- local active_log_error: (message: string) -> () = error
-- local active_log_error_nonfatal: (message: string) -> () = print

return table.freeze({
	set_logger = function(new_logger: external.ExternalLogger?)
		local old_logger = active_logger

		-- if new_logger == nil then
		-- 	active_log_warn = new_logger.log_warn
		-- 	active_log_error = new_logger.log_error
		-- 	active_log_error_nonfatal = new_logger.log_error_nonfatal
		-- end

		active_logger = new_logger

		return old_logger
	end,
	log_warn = function(message: string, ...: any)
		local formatted_message = format_error(message, debug.traceback(nil, 2), ...)

		if active_logger ~= nil then
			active_logger.log_warn(formatted_message)
			-- active_log_warn(formatted_message)
		else
			print(formatted_message)
		end
	end,
	log_error = function(message: string, err: logging.Error?, ...: any)
		local formatted_message = format_error(message, err, ...)

		if active_logger ~= nil then
			active_logger.log_error(formatted_message)
			-- active_log_error(formatted_message)
		else
			error(formatted_message, 0)
		end
	end,
	log_error_nonfatal = function(message: string, err: logging.Error?, ...: any)
		local formatted_message = format_error(message, err, ...)

		if active_logger ~= nil then
			active_logger.log_error_nonfatal(message)
			-- active_log_error_nonfatal(formatted_message)
		else
			print(formatted_message)
		end
	end,
})
