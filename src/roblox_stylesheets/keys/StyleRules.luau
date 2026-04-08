local SpecialKey = require("../../roblox-instances/SpecialKey")

local StyleRules = SpecialKey(
	"self",
	"StyleRules",
	function(_, apply_to: StyleBase, rules: { [number]: StyleRule })
		for priority, rule in rules do
			apply_to:InsertStyleRule(rule, priority)
		end
	end
)

return StyleRules
