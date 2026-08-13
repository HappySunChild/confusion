--!strict
--!native
--!optimize 2
const memory = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const function check_lifetime<A, B, C...>(
	a: A,
	b: B,
	scope_b: memory.Scope?,
	describer: (A, B, C...) -> { subject_description: string, case_description: string },
	...: C...
)
	if scope_b == nil then
		const format_context = describer(a, b, ...) :: { [string]: any }
		format_context.case_subject = a
		format_context.subject_subject = b

		log_error(memory.use_after_destroy, debug.traceback(nil, 2), format_context)
	end
end

return check_lifetime
