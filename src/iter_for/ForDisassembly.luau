local calc = require("../core_calc/types")
local iter = require("../iter/types")
local iter_for = require("./types")
local memory = require("../core_memory/types")

local cleanup = require("../core_memory/cleanup")
local depend = require("../core_graph/depend")
local derive_scope = require("../core_memory/derive_scope")
local destructor = require("../core_memory/destructor")
local log_error_nonfatal = require("../core_logging/log_error_nonfatal")
local peek = require("../core_use/peek")

type Self<S, IK, IV, OK, OV> = iter.Disassembly<OK, OV> & {
	_input: calc.UsedAs<{ [IK]: IV }>,

	_active_pairs: { [IK]: iter_for.ComputedPair<IK, IV, OK, OV> },
	_pair_scope: memory.Scope<S>,

	_constructor: (
		memory.Scope<S>,
		initial_key: IK,
		initial_value: IV
	) -> iter_for.ComputedPair<IK, IV, OK, OV>,
}

local CLASS = table.freeze({
	type = "graph",
	kind = "Disassembly",
	timeliness = "lazy",

	populate = function<S, IK, IV, OK, OV>(self: Self<S, IK, IV, OK, OV>, use: calc.Use, output: { [OK]: OV? })
		local min_array_index = math.huge
		local max_array_index = -math.huge
		local has_holes = false

		for _, pair in self._active_pairs do
			local pair_output = use(pair)
			local output_key, output_value = pair_output.key, pair_output.value

			if output_key == nil or output_value == nil then
				has_holes = true
				continue
			elseif output[output_key] ~= nil then
				log_error_nonfatal(
					iter_for.for_key_collision,
					nil,
					output_key,
					pair.input_key,
					pair.input_value,
					output_key,
					output_value
				)

				continue
			end

			output[output_key] = output_value

			if type(output_key) == "number" then
				min_array_index = math.min(min_array_index, output_key :: number)
				max_array_index = math.max(max_array_index, output_key :: number)
			end
		end

		if has_holes and max_array_index < min_array_index then
			local move_to_index = min_array_index

			for move_from_index = min_array_index, max_array_index do
				local output_value = output[move_from_index] :: any

				if output_value == nil then
					continue
				end

				output[move_from_index] = nil
				output[move_to_index] = output_value
				move_to_index += 1
			end
		end
	end,
	_evaluate = function<S, IK, IV, OK, OV>(self: Self<S, IK, IV, OK, OV>)
		depend(self, self._input)

		local pending_pairs = table.clone(peek(self._input)) :: { [IK]: IV }

		local old_pairs = self._active_pairs
		local new_pairs = {}

		for index, pair in old_pairs do
			old_pairs[index] = nil

			local roam_keys, roam_values = pair.roam_keys, pair.roam_values

			local can_reuse = false

			local old_input_key = pair._input_key
			local old_input_value = pair._input_value

			local new_input_key: IK

			if not roam_keys and pending_pairs[old_input_key] ~= nil then
				can_reuse = true
				new_input_key = old_input_key
			else
				local claimed_values = {}

				if not roam_values then
					for _, other_pair in old_pairs do
						claimed_values[other_pair._input_value] = true
					end
				end

				for pending_key, pending_value in pending_pairs do
					if
						-- "predict" that this key is going to be reused by another existing object that is
						-- expecting it to be available. if it is going to be reused, then don't.
						not roam_keys and old_pairs[pending_key] ~= nil
					then
						continue
					end

					if
						-- "selfless" check
						-- don't use values that are "claimed" by other objects.
						not roam_values
						and old_input_value ~= pending_value
						and claimed_values[pending_value] == true
					then
						continue
					end

					can_reuse = true
					new_input_key = pending_key

					if roam_values then
						break
					end

					if pending_value == old_input_value then
						break
					end
				end
			end

			-- cleanup pairs that can't be reused
			if not can_reuse then
				pair:destroy()

				continue
			end

			local new_input_value: IV = pending_pairs[new_input_key]

			pending_pairs[new_input_key] = nil

			-- "claim" pair and invalidate with new parameters
			new_pairs[new_input_key] = pair
			pair:invalidate_pair(new_input_key, new_input_value)
		end

		local pair_scope = self._pair_scope
		local pair_constructor = self._constructor

		-- create new pair objects for any remaining pairs that couldn't be reused.
		for pending_key, pending_value in pending_pairs do
			new_pairs[pending_key] = pair_constructor(pair_scope, pending_key, pending_value)
		end

		self._active_pairs = new_pairs

		return true
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_fordiassembly<S, IK, IV, OK, OV>(fordisassembly: Self<S, IK, IV, OK, OV>)
	cleanup(fordisassembly._pair_scope)
	fordisassembly._pair_scope = nil
	fordisassembly._active_pairs = nil
end

local function ForDisassembly<S, IK, IV, OK, OV>(
	scope: memory.Scope,
	input: calc.UsedAs<{ [IK]: IV }>,
	constructor: (
		memory.Scope<S>,
		initial_key: IK,
		initial_value: IV
	) -> iter_for.ComputedPair<IK, IV, OK, OV>
): iter.Disassembly<OK, OV>
	local new_disassembly: Self<S, IK, IV, OK, OV> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
		using = {},

		_input = input,

		_active_pairs = {},
		_pair_scope = derive_scope(scope),

		_constructor = constructor,
	}, CLASS_METATABLE) :: any

	local oldest_task = destructor(new_disassembly, destroy_fordiassembly)

	new_disassembly._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_disassembly
end

return ForDisassembly
