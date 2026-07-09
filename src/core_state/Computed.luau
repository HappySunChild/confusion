const logging = require("../core_logging/types")
const memory = require("../core_memory/types")
const state = require("./types")

const cleanup = require("../core_memory/cleanup")
const derive_scope = require("../core_memory/derive_scope")
const destructor = require("../core_memory/destructor")
const generic_use = require("../core_use/generic_use")
const is_similar = require("./is_similar")
const log_error_nonfatal = require("../core_logging/log_error_nonfatal")
const parse_error = require("../core_logging/parse_error")

type Self<T, S> = {
	_inner_scope: memory.Scope<S>?,
	_processor: state.ComputedProcessor<S, T>,
	_use: state.Use,
} & state.Computed<T>

const CLASS_META = table.freeze({
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

			const ok, new_value = xpcall(self._processor, parse_error, self._use, inner_scope)

			if ok then
				const similar = is_similar(self.cached_value, new_value)

				cleanup(self._inner_scope)

				self._inner_scope = inner_scope
				self.cached_value = new_value

				return not similar
			end

			cleanup(inner_scope)

			log_error_nonfatal(state.callback_error, new_value :: logging.Error)

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

		_inner_scope = nil,
		_processor = processor,
	}, CLASS_META) :: any

	const oldest_task = destructor(new_computed, computed_destructor)

	new_computed._oldest_task = oldest_task
	new_computed._use = generic_use(new_computed)

	table.insert(scope, oldest_task)

	return new_computed
end

return Computed
