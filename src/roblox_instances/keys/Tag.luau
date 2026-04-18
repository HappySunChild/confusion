local memory = require("../../core_memory/types")
local rbx_instances = require("../types")
local state = require("../../core_state/types")

local observe_immediate = require("../../core_graph/observe_immediate")
local peek = require("../../core_use/peek")

local KEY_CACHE = {}

local function Tag(tag: string): rbx_instances.SpecialKey<"Tag">
	local key = KEY_CACHE[tag]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "Tag",
			stage = "self",
			apply = function(scope: memory.Scope, apply_to: Instance, enabled: state.UsedAs<boolean>)
				observe_immediate(scope, enabled, function()
					local value = peek(enabled)

					if value == true then
						apply_to:AddTag(tag)
					elseif apply_to:HasTag(tag) then
						apply_to:RemoveTag(tag)
					end
				end)
			end,
		} :: rbx_instances.SpecialKey<"Tag">

		KEY_CACHE[tag] = key
	end

	return key
end

return Tag
