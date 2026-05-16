const iter_range = require("./types")
const logging = require("../core_logging/types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

const cleanup = require("../core_memory/cleanup")
const derive_scope = require("../core_memory/derive_scope")
const destructor = require("../core_memory/destructor")
const generic_use = require("../core_use/generic_use")
const is_similar = require("../core_state/is_similar")
const log_error_nonfatal = require("../core_logging/log_error_nonfatal")
const parse_error = require("../core_logging/parse_error")

type Self<T, S> = {
	_active_scope: memory.Scope<S>,
	_processor: iter_range.RangeDisassemblyProcessor<T, S>,
	_use: state.Use,
} & iter_range.RangePair<T>

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "RangePair",
		timeliness = "lazy",

		_evaluate = function<T, S>(self: Self<T, S>)
			if self.scope == nil then
				return false
			end

			const inner_scope = derive_scope(self.scope)
			const ok, output_value = xpcall(self._processor, parse_error, self._use, inner_scope, self.input_index)

			cleanup(self._active_scope)

			if not ok then
				self._cached_value = nil

				cleanup(inner_scope)

				log_error_nonfatal(state.callback_error, output_value :: logging.Error)

				return false
			end

			self._active_scope = inner_scope

			const old_value = self._cached_value

			self._cached_value = output_value

			return not is_similar(old_value, output_value)
		end,
	}),
})

const function destroy_rangepair<T, S>(rangepair: Self<T, S>)
	cleanup(rangepair._active_scope)
	rangepair._active_scope = nil
end

const function RangePair<S, T>(
	scope: memory.Scope<S>,
	initial_index: number,
	processor: iter_range.RangeDisassemblyProcessor<S, T>
): iter_range.RangePair<T>
	const new_rangepair: Self<T, S> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},

		_cached_value = nil,

		input_index = initial_index,

		_active_scope = nil,
		_processor = processor,
	}, CLASS_MT) :: any

	const oldest_task = destructor(new_rangepair, destroy_rangepair)

	new_rangepair._oldest_task = oldest_task
	new_rangepair._use = generic_use(new_rangepair)

	table.insert(scope, oldest_task)

	return new_rangepair
end

return RangePair
