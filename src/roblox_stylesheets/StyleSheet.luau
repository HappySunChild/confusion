local memory = require("../core_memory/types")
local rbx_stylesheets = require("./types")

local Attributes = require("../roblox_instances/keys/Attributes")
local StyleDerives = require("./keys/StyleDerives")
local StyleRules = require("./keys/StyleRules")
local apply_instance_properties = require("../roblox_instances/apply_instance_properties")

local function StyleSheet(scope: memory.Scope, properties: rbx_stylesheets.StyleSheetProperties): StyleSheet
	local new_sheet = Instance.new("StyleSheet")

	table.insert(scope, new_sheet)

	apply_instance_properties(scope, new_sheet, {
		Parent = properties.parent,

		[Attributes] = properties.tokens,
		[StyleDerives] = properties.derives,
		[StyleRules] = properties.rules,
	})

	return new_sheet
end

return StyleSheet
