const memory = require("../core_memory/types")
const rbx_stylesheets = require("./types")

const Attributes = require("../roblox_instances/keys/Attributes")
const StyleRules = require("./keys/StyleRules")
const StyleSheetDerives = require("./keys/StyleSheetDerives")
const apply_instance_properties = require("../roblox_instances/apply_instance_properties")

const function StyleSheet(scope: memory.Scope, properties: rbx_stylesheets.StyleSheetProperties): StyleSheet
	const new_sheet = Instance.new("StyleSheet")

	table.insert(scope, new_sheet)

	apply_instance_properties(scope, new_sheet, {
		Parent = properties.parent,
		Name = properties.name,

		[Attributes] = properties.tokens,
		[StyleRules] = properties.rules,
		[StyleSheetDerives] = properties.derives,
	})

	return new_sheet
end

return StyleSheet
