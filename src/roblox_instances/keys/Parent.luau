local graph = require("../../core_graph/types")
local memory = require("../../core_memory/types")
local rbx_instances = require("../types")

local Observer = require("../../core_graph/Observer")
local log_warn = require("../../core_logging/log_warn")
local peek = require("../../core_use/peek")

local function set_parent(instance: Instance, parent: Instance?)
	local success, err = pcall(function()
		instance.Parent = parent
	end)

	if not success then
		log_warn(err)
	end
end

return {
	type = "SpecialKey",
	kind = "Parent",
	stage = "ancestor",
	apply = function(scope: memory.Scope, apply_to: Instance, parent: graph.UsedAs<Instance?>)
		if type(parent) == "function" then
			Observer(scope, function(use: graph.use)
				set_parent(apply_to, use(parent))
			end)
		else
			set_parent(apply_to, peek(parent))
		end
	end,
} :: rbx_instances.SpecialKey<"Parent">
