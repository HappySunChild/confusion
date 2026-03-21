local calc = require("../core_calc/types")
local iter_for = require("../iter_for/types")
local memory = require("../core_memory/types")

local cast_to_state = require("../core_calc/cast_to_state")
local cleanup = require("../core_memory/cleanup")
local dissolving_use = require("../core_use/dissolving_use")
local inner_scope = require("../core_memory/inner_scope")
local log_error_nonfatal = require("../core_logging/log_error_nonfatal")

local function check_dissolvable<S, IK, IV, OK, OV>(
	scope: memory.Scope<S>,
	input: calc.UsedAs<{ [IK]: IV }>,
	processor: (
		calc.Use,
		memory.Scope<S>,
		IK,
		IV
	) -> (OK?, OV?)
): (boolean, { [OK]: OV }?)
	if cast_to_state(input) ~= nil then
		return false, nil
	end

	local dissolving_scope = inner_scope(scope)
	local output = {}

	for key, value in input do
		local ok, output_key, output_value =
			pcall(processor, dissolving_use, dissolving_scope, key, value)

		if not ok then
			cleanup(dissolving_scope)

			return false, nil
		end

		if output_key == nil or output_value == nil then
			continue
		elseif output[output_key] ~= nil then
			log_error_nonfatal(iter_for.for_key_collision, nil, tostring(output_key))

			continue
		end

		output[output_key] = output_value
	end

	return true, output
end

return check_dissolvable
