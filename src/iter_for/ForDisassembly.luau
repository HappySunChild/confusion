local iter = require("../iter/types")
local iter_for = require("./types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

local cleanup = require("../core_memory/cleanup")
local depend = require("../core_graph/depend")
local destructor = require("../core_memory/destructor")
local inner_scope = require("../core_memory/inner_scope")
local is_similar = require("../core_state/is_similar")
local log_error_nonfatal = require("../core_logging/log_error_nonfatal")
local mark_dirty = require("../core_graph/mark_dirty")
local peek = require("../core_use/peek")

type Self<S, IK, IV, OK, OV> = iter.Disassembly<OK, OV> & {
	_input_table: state.UsedAs<{ [IK]: IV }>,

	_active_pairs: { [IK]: iter_for.ComputedPair<IK, IV, OK, OV> },
	_pair_scope: memory.Scope<S>,

	_constructor: (memory.Scope<S>, initial_key: IK, initial_value: IV) -> iter_for.ComputedPair<IK, IV, OK, OV>,
}

local function invalidate_pair<IK, IV, OK, OV>(computedpair: iter_for.ComputedPair<IK, IV, OK, OV>, new_key: IK, new_value: IV)
	local old_key, old_value = computedpair.input_key, computedpair.input_value
	local output = computedpair._cached_value

	computedpair.input_key = new_key
	computedpair.input_value = new_value

	if computedpair.roam_keys then -- is this bad?? observers aren't being fired, but we *may* have meaningfully changed.. (doing this to avoid recomputations)
		output.key = new_key
	elseif not is_similar(old_key, new_key) then
		mark_dirty(computedpair)
	end

	if computedpair.roam_values then
		output.value = new_value
	elseif not is_similar(old_value, new_value) then
		mark_dirty(computedpair)
	end
end

local CLASS = table.freeze({
	type = "graph",
	kind = "Disassembly",
	timeliness = "lazy",

	populate = function<S, IK, IV, OK, OV>(self: Self<S, IK, IV, OK, OV>, use: state.Use, output: { [OK]: OV? })
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

		if has_holes and max_array_index > min_array_index then
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
		depend(self, self._input_table)

		local pending_pairs = table.clone(peek(self._input_table)) :: { [IK]: IV }

		local old_computedpairs = self._active_pairs
		local new_computedpairs = {}

		local unmatched_computedpairs: { iter_for.ComputedPair<IK, IV, OK, OV> } = {}

		for index, computedpair in old_computedpairs do
			old_computedpairs[index] = nil

			local old_input_key, old_input_value = computedpair.input_key, computedpair.input_value
			local roam_keys, roam_values = computedpair.roam_keys, computedpair.roam_values

			local new_input_key: IK, new_input_value: IV

			if not roam_keys and pending_pairs[old_input_key] ~= nil then
				new_input_key = old_input_key
				new_input_value = pending_pairs[old_input_key]
			else
				if roam_values then
					table.insert(unmatched_computedpairs, computedpair)
					continue
				end

				for pending_key, pending_value in pending_pairs do
					if pending_value == old_input_value then
						new_input_key = pending_key
						new_input_value = pending_value
						break
					end
				end

				if new_input_key == nil then -- failed to find any available pairs, we should probably be cleaned up
					table.insert(unmatched_computedpairs, computedpair)
					continue
				end
			end

			-- "claim" pair and invalidate with new parameters
			new_computedpairs[new_input_key] = computedpair
			pending_pairs[new_input_key] = nil

			invalidate_pair(computedpair, new_input_key, new_input_value)
		end

		for _, computedpair in unmatched_computedpairs do
			local new_input_key, new_input_value = next(pending_pairs)

			if new_input_key == nil then -- no pending pairs remaining, we should just clean up
				cleanup(computedpair.scope)

				continue
			end

			new_computedpairs[new_input_key] = computedpair
			pending_pairs[new_input_key] = nil

			invalidate_pair(computedpair, new_input_key, new_input_value)
		end

		local pair_scope = self._pair_scope
		local pair_constructor = self._constructor

		-- create new pair objects for any remaining pairs that couldn't be reused.
		for pending_key, pending_value in pending_pairs do
			new_computedpairs[pending_key] = pair_constructor(inner_scope(pair_scope), pending_key, pending_value)
		end

		self._active_pairs = new_computedpairs

		return true
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_fordiassembly<S, IK, IV, OK, OV>(fordisassembly: Self<S, IK, IV, OK, OV>)
	fordisassembly._pair_scope = nil
	fordisassembly._active_pairs = nil
end

local function ForDisassembly<S, IK, IV, OK, OV>(
	scope: memory.Scope,
	input: state.UsedAs<{ [IK]: IV }>,
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

		_input_table = input,

		_active_pairs = {},
		_pair_scope = inner_scope(scope),

		_constructor = constructor,
	}, CLASS_METATABLE) :: any

	local oldest_task = destructor(new_disassembly, destroy_fordiassembly)

	new_disassembly._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_disassembly
end

return ForDisassembly
