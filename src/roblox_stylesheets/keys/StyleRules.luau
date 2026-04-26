local memory = require("../../core_memory/types")
local rbx_instances = require("../../roblox_instances/types")
local rbx_stylesheets = require("../types")

local StyleRuleProperties = require("./StyleRuleProperties")
local apply_instance_properties = require("../../roblox_instances/apply_instance_properties")

local StyleRules = {
	type = "SpecialKey",
	kind = "StyleRules",
	stage = "self",
	apply = nil,
} :: rbx_instances.SpecialKey<"StyleRules">

local function stylerule_from_description(
	scope: memory.Scope,
	description: rbx_stylesheets.StyleRuleDescription
): StyleRule
	local rule = Instance.new("StyleRule")

	table.insert(scope, rule)

	local selector = table.remove(description, 1)

	local rule_properties: { [string]: any } = {}
	local rule_subrules: { StyleRule | rbx_stylesheets.StyleRuleDescription } = {}

	for key, value in description do
		local key_type = type(key)

		if key_type == "string" then
			rule_properties[key] = value
		elseif key_type == "number" then
			rule_subrules[key] = value
		end
	end

	apply_instance_properties(scope, rule, {
		Name = selector,
		Selector = selector,

		[StyleRuleProperties] = rule_properties,
		[StyleRules] = rule_subrules,
	})

	return rule
end

local function process_rule(
	scope: memory.Scope,
	apply_to: StyleBase,
	priority: number,
	rule: StyleRule | rbx_stylesheets.StyleRuleDescription
)
	local rule_type = typeof(rule)

	if rule_type == "Instance" then -- ROOT CASE
		apply_to:InsertStyleRule(rule, priority)
	elseif rule_type == "table" and type(rule[1]) == "string" then -- DESCRIPTION CASE
		process_rule(scope, apply_to, priority, stylerule_from_description(scope, rule))
	end
end

function StyleRules.apply(
	scope: memory.Scope,
	apply_to: StyleBase,
	rules: { StyleRule | rbx_stylesheets.StyleRuleDescription }
)
	for priority, rule in rules do
		process_rule(scope, apply_to, priority, rule)
	end
end

return StyleRules
