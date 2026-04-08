local calc = require("../../core-calc/types")
local memory = require("../../core-memory/types")

local SpecialKey = require("../../roblox-instances/SpecialKey")
local apply_properties = require("../../roblox-instances/apply_properties")

local StyleLink = SpecialKey(
	"descendants",
	"StyleLink",
	function(scope: memory.Scope, apply_to: Instance, style: calc.UsedAs<StyleSheet>)
		local link = Instance.new("StyleLink")

		apply_properties(scope, link, {
			Parent = apply_to,
			StyleSheet = style,
		})

		table.insert(scope, link)
	end
)

return StyleLink
