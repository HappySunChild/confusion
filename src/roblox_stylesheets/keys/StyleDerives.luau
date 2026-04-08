local SpecialKey = require("../../roblox-instances/SpecialKey")

local StyleDerives = SpecialKey(
	"self",
	"StyleDerives",
	function(_, apply_to: StyleSheet, derives: { StyleSheet })
		apply_to:SetDerives(derives)
	end
)

return StyleDerives
