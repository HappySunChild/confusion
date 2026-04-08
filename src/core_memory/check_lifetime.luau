local memory = require("./types")

local log_error = require("../core_logging/log_error")

local function check_lifetime<A, B, C...>(
	a: A,
	b: B,
	scope_b: memory.Scope,
	formatter: (A, B, C...) -> (string, string),
	...: C...
)
	if scope_b == nil then
		log_error(memory.use_after_destroy, nil, formatter(a, b, ...))
	end
end

return check_lifetime
