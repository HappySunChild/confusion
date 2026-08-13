const logging = require("./types")

const function parse_error(err: unknown): logging.Error
	return {
		message = tostring(err),
		trace = debug.traceback(nil, 2),
	}
end

return parse_error
