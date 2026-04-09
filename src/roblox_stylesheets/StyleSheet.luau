local memory = require("../core_memory/types")
local style = require("./types")

local Attributes = require("../roblox_instances/keys/Attributes")
local StyleDerives = require("./keys/StyleDerives")
local StyleRules = require("./keys/StyleRules")
local apply_properties = require("../roblox_instances/apply_properties")

local function StyleSheet(scope: memory.Scope, properties: style.StyleSheetProperties): StyleSheet
	local new_sheet = Instance.new("StyleSheet")

	table.insert(scope, new_sheet)

	local actual_properties = {
		Parent = properties.parent,

		[Attributes] = properties.tokens,
		[StyleDerives] = properties.derives,
		[StyleRules] = properties.rules,
	}

	apply_properties(scope, new_sheet, actual_properties)

	return new_sheet
end

return StyleSheet
