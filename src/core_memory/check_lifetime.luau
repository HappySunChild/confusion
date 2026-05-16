const memory = require("./types")

const log_error = require("../core_logging/log_error")

const function check_lifetime<A, B, C...>(
	a: A,
	b: B,
	scope_b: memory.Scope?,
	formatter: (A, B, C...) -> (string, string),
	...: C...
)
	if scope_b == nil then
		log_error(memory.use_after_destroy, nil, formatter(a, b, ...))
	end
end

return check_lifetime
