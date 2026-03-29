local calc = require("../core_calc/types")
local iter_for = require("./types")
local logging = require("../core_logging/types")
local memory = require("../core_memory/types")

local cleanup = require("../core_memory/cleanup")
local derive_scope = require("../core_memory/derive_scope")
local destructor = require("../core_memory/destructor")
local generic_use = require("../core_use/generic_use")
local is_similar = require("../core_calc/is_similar")
local log_error_nonfatal = require("../core_logging/log_error_nonfatal")
local mark_dirty = require("../core_graph/mark_dirty")
local parse_error = require("../core_logging/parse_error")

type ComputedPairProcessor<S, IK, IV, OK, OV> = (
	use: calc.Use,
	scope: memory.Scope<S>,
	key: IK,
	value: IV
) -> (OK?, OV?)

type Self<S, IK, IV, OK, OV> = iter_for.ComputedPair<IK, IV, OK, OV> & {
	roam_keys: boolean,
	roam_values: boolean,

	_inner_scope: memory.Scope<S>,
	_processor: ComputedPairProcessor<S, IK, IV, OK, OV>,
	_use: calc.Use,
}

local CLASS = table.freeze({
	type = "state",
	kind = "ComputedPair",

	invalidate_pair = function<S, IK, IV, OK, OV>(self: Self<S, IK, IV, OK, OV>, new_key: IK, new_value: IV)
		local old_key, old_value = self._input_key, self._input_value
		local output = self._cached_value

		self._input_key = new_key
		self._input_value = new_value

		if self.roam_keys then -- is this bad?? observers aren't being fired, but we *may* have meaningfully changed.. (doing this to avoid recomputations)
			output.key = new_key
		elseif not is_similar(old_key, new_key) then
			mark_dirty(self)
		end

		if self.roam_values then
			output.value = new_value
		elseif not is_similar(old_value, new_value) then
			mark_dirty(self)
		end
	end,

	_evaluate = function<S, IK, IV, OK, OV>(self: Self<S, IK, IV, OK, OV>)
		if self.scope == nil then
			return false
		end

		local inner_scope = derive_scope(self.scope)
		local ok, new_key, new_value = xpcall(
			self._processor,
			parse_error,
			self._use,
			inner_scope,
			self._input_key,
			self._input_value
		)

		if not ok then
			cleanup(inner_scope)

			log_error_nonfatal(calc.callback_error, new_key :: logging.Error)

			return false
		end

		cleanup(self._inner_scope)
		self._inner_scope = inner_scope

		local output = self._cached_value
		local old_key, old_value = output.key, output.value

		output.key, output.value = new_key, new_value

		return not (is_similar(old_key, new_key) and is_similar(old_value, new_value))
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_computedpair<S, IK, IV, OK, OV>(computedpair: Self<S, IK, IV, OK, OV>)
	cleanup(computedpair._inner_scope)
	computedpair._inner_scope = nil

	computedpair._input_key = nil
	computedpair._input_value = nil
	computedpair._cached_value = nil
end

local function ComputedPair<S, IK, IV, OK, OV>(
	scope: memory.Scope<S>,
	initial_key: IK,
	initial_value: IV,
	roam_keys: boolean,
	roam_values: boolean,
	processor: ComputedPairProcessor<S, IK, IV, OK, OV>
)
	local new_computedpair = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
		using = {},

		_cached_value = { key = nil, value = nil },

		_input_key = initial_key,
		_input_value = initial_value,

		roam_keys = roam_keys,
		roam_values = roam_values,

		_inner_scope = nil,
		_processor = processor,
	}, CLASS_METATABLE)

	new_computedpair._use = generic_use(new_computedpair)

	table.insert(scope, destructor(new_computedpair, destroy_computedpair))

	return new_computedpair
end

return ComputedPair
