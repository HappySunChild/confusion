local memory = require("../core_memory/types")
local rbx_instances = require("../roblox_instances/types")
local templates = require("./types")

local Hydrate = require("../roblox_instances/Hydrate")
local log_error = require("../core_logging/log_error")

local function FromTemplate<InstanceT>(
	scope: memory.Scope,
	template: InstanceT,
	properties: rbx_instances.Properties
): InstanceT
	template = template :: Instance

	local new_instance = template:Clone()

	if new_instance == nil then
		log_error(
			if template.Archivable
				then templates.cannot_clone_template
				else templates.cannot_clone_template_unarchivable,
			nil,
			template.ClassName,
			template:GetFullName()
		)
	end

	return Hydrate(scope, template, properties)
end

return FromTemplate
