const logging = require("../core_logging/types")
const memory = require("../core_memory/types")
const state = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error_nonfatal = ExternalLogger.log_error_nonfatal

const cleanup = require("../core_memory/cleanup")
const derive_scope = require("../core_memory/derive_scope")
const destructor = require("../core_memory/destructor")
const generic_use = require("../core_use/generic_use")
const is_similar = require("./is_similar")
const parse_error = require("../core_logging/parse_error")

type Self<T, S> = {
	inner_scope: memory.Scope<S>?,
	processor: state.ComputedProcessor<S, T>,
	use: state.Use,
} & state.Computed<T>

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Computed",
		timeliness = "lazy",

		evaluate = function<T, S>(self: Self<T, S>): boolean
			if self.scope == nil then
				return false
			end

			const outer_scope = self.scope
			const inner_scope = derive_scope(outer_scope)

			const ok, new_value_or_err = xpcall(self.processor, parse_error, self.use, inner_scope)

			if ok then
				const similar = is_similar(self.cached_value, new_value_or_err)

				cleanup(self.inner_scope)

				self.inner_scope = inner_scope
				self.cached_value = new_value_or_err

				return not similar
			end

			cleanup(inner_scope)

			log_error_nonfatal(state.callback_error, new_value_or_err :: logging.Error)

			return false
		end,
	}),
})

const function computed_destructor<T, S>(computed: Self<T, S>)
	cleanup(computed._inner_scope)
	computed._inner_scope = nil
end

const function Computed<T, S>(scope: memory.Scope<S>, processor: state.ComputedProcessor<S, T>): state.Computed<T>
	const new_computed: Self<T, S> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},
		cached_value = nil,

		inner_scope = nil,
		processor = processor,
	}, CLASS_MT) :: any

	const oldest_task = destructor(new_computed, computed_destructor)

	new_computed._oldest_task = oldest_task
	new_computed.use = generic_use(new_computed)

	table.insert(scope, oldest_task)

	return new_computed
end

return Computed
