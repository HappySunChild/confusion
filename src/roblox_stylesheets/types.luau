local memory = require("../core_memory/types")
local state = require("../core_state/types")

export type StyleSheetProperties = {
	derives: { StyleSheet }?,
	rules: { [number]: StyleRule }?,
	tokens: { [string]: state.UsedAs<any> }?,

	parent: state.UsedAs<Instance>?,
}

export type StyleSheetConstructor = (scope: memory.Scope, properties: StyleSheetProperties) -> StyleSheet

-- export type StyleQueryConditions = {
-- 	AspectRatioRange: NumberRange?,
-- 	MaxSize: Vector2?,
-- 	MinSize: Vector2?,
-- 	PreferredInput: Enum.PreferredInput?,
-- 	ReducedMotionEnabled: boolean?,
-- 	ViewportDisplaySize: Enum.DisplaySize?,
-- }

-- export type StyleRuleProperties = {
-- 	requirements: {
-- 		id: string,
-- 		conditions: StyleQueryConditions,
-- 	}?,
-- 	properties: { [string]: any },
-- }

export type StyleRuleConstructor = (
	scope: memory.Scope,
	selector: string,
	properties: { [string]: any },
	subrules: { StyleRule }?
) -> StyleRule

return nil
