const memory = require("../core_memory/types")
const rbx_stylesheets = require("./types")

const apply_instance_properties = require("../rbx_instances/apply_instance_properties")
const StyleRules = require("./keys/StyleRules")
const StyleRuleTransitions = require("./keys/StyleRuleTransitions")
const StyleRuleProperties = require("./keys/StyleRuleProperties")

const function StyleRule(
	scope: memory.Scope,
	selector: string,
	properties: rbx_stylesheets.StyleRuleProperties
): StyleRule
	const new_rule = Instance.new("StyleRule")
	table.insert(scope, new_rule)

	const rule_subrules = {}
	const rule_properties = {}

	for key, value in properties do
		if key == "transitions" then
			continue
		end

		const key_type = type(key)

		if key_type == "number" then
			rule_subrules[key] = value
		elseif key_type == "string" then
			rule_properties[key] = value
		end
	end

	apply_instance_properties(scope, new_rule, {
		Name = selector,
		Selector = selector,

		[StyleRules] = rule_subrules,
		[StyleRuleProperties] = rule_properties,
		[StyleRuleTransitions] = properties.transitions,
	})

	return new_rule
end

return StyleRule
