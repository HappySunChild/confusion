const iter_for = require("./types")
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

type ComputedPairProcessor<S, IK, IV, OK, OV> = (
	use: state.Use,
	scope: memory.Scope<S>,
	key: IK,
	value: IV
) -> (OK?, OV?)

type Self<S, IK, IV, OK, OV> = iter_for.ComputedPair<IK, IV, OK, OV> & {
	roam_keys: boolean,
	roam_values: boolean,

	_active_scope: memory.Scope<S>,
	_processor: ComputedPairProcessor<S, IK, IV, OK, OV>,
	_use: state.Use,
}

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "ComputedPair",

		_evaluate = function<S, IK, IV, OK, OV>(self: Self<S, IK, IV, OK, OV>)
			if self.scope == nil then
				return false
			end

			const output = self._cached_value

			const active_scope = derive_scope(self.scope)
			const ok, new_key, new_value =
				xpcall(self._processor, parse_error, self._use, active_scope, self.input_key, self.input_value)

			cleanup(self._active_scope) -- for some reason the spec also calls for clearing the current scope as well? I guess it makes it consistent with omitting the pair. this is all weird

			if not ok then
				output.key, output.value = nil, nil -- this behavior isn't congruent with how Computeds work, but the spec says that this is how it should work...

				cleanup(active_scope)

				log_error_nonfatal(state.callback_error, new_key :: logging.Error)

				return false
			end

			self._active_scope = active_scope

			const old_key, old_value = output.key, output.value

			output.key, output.value = new_key, new_value

			return not (is_similar(old_key, new_key) and is_similar(old_value, new_value))
		end,
	}),
})

const function destroy_computedpair<S, IK, IV, OK, OV>(computedpair: Self<S, IK, IV, OK, OV>)
	cleanup(computedpair._active_scope)
	computedpair._active_scope = nil

	computedpair.input_key = nil
	computedpair.input_value = nil
	computedpair._cached_value = nil
end

const function ComputedPair<S, IK, IV, OK, OV>(
	scope: memory.Scope<S>,
	initial_key: IK,
	initial_value: IV,
	roam_keys: boolean,
	roam_values: boolean,
	processor: ComputedPairProcessor<S, IK, IV, OK, OV>
)
	const new_computedpair: Self<S, IK, IV, OK, OV> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
		using = {},

		_cached_value = { key = nil, value = nil },

		input_key = initial_key,
		input_value = initial_value,

		roam_keys = roam_keys,
		roam_values = roam_values,

		_active_scope = nil,
		_processor = processor,
	}, CLASS_MT) :: any

	const oldest_task = destructor(new_computedpair, destroy_computedpair)

	new_computedpair._oldest_task = oldest_task
	new_computedpair._use = generic_use(new_computedpair)

	table.insert(scope, oldest_task)

	return new_computedpair
end

return ComputedPair
