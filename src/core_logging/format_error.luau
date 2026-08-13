const logging = require("./types")

const function format_context(message: string, context: logging.LogContext): string
	local formatted = message

	for key, value in context do
		formatted = string.gsub(formatted, `\{({key})}`, tostring(value))
	end

	return formatted
end

const function format_error(
	message: string,
	error_or_trace: logging.Error | string?,
	context: logging.LogContext?
): string
	const err = if typeof(error_or_trace) == "table" then error_or_trace else nil
	const trace = if typeof(error_or_trace) == "table" then error_or_trace.trace else error_or_trace

	local formatted_message = message

	if context ~= nil then
		formatted_message = format_context(message, context)
	end

	formatted_message =
		string.gsub(formatted_message, "ERROR_MESSAGE", if err ~= nil then err.message else "unknown or missing error")

	if trace ~= nil then
		formatted_message ..= `\n---- Stack trace ----\n{trace}`
	end

	-- return formatted_message:gsub("\n", "\n\t")
	return "[confusion] " .. string.gsub(formatted_message, "\n", "\n\t")
end

return format_error
