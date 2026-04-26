local memory = require("../core_memory/types")

local StyleProperties = require("./keys/StyleProperties")
local StyleRules = require("./keys/StyleRules")
local apply_instance_properties = require("../roblox_instances/apply_instance_properties")

local function StyleRule(scope: memory.Scope, selector: string, properties: { [string | number]: any })
	local new_rule = Instance.new("StyleRule")

	table.insert(scope, new_rule)

	local style_properties: { [string]: any } = {}
	local style_subrules: { StyleRule } = {}

	for key, value in properties do
		local key_type = type(key)

		if key_type == "string" then
			style_properties[key] = value
		elseif key_type == "number" then
			style_subrules[key] = value
		end
	end

	-- implicit stylerule description handling
	-- TODO: do something like this for Children/Describe, description syntax should be a Describe only thing i feel. also cleans up hacks i did
	for key, subrule in style_subrules do
		if type(subrule) == "table" and type(subrule[1]) == "string" then
			style_subrules[key] = StyleRule(scope, subrule[1], subrule)
		end
	end

	apply_instance_properties(scope, new_rule, {
		Selector = selector,
		Name = selector,

		[StyleRules] = style_subrules,
		[StyleProperties] = style_properties,
	})

	return new_rule
end

return StyleRule
