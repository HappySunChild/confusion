local function parse_error(message: string)
	return {
		type = "Error",
		raw = message,
		message = message:gsub("^.+:%d+:%s*", ""),
		trace = debug.traceback(nil, 2),
	}
end

return parse_error
