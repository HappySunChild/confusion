local calc = require("../core-calc/types")
local memory = require("../core-memory/types")

export type StyleSheetProperties = {
	derives: { StyleSheet }?,
	rules: { [number]: StyleRule }?,
	tokens: { [string]: calc.UsedAs<any> }?,

	parent: calc.UsedAs<Instance>?,
}

export type StyleRuleConstructor = (
	scope: memory.Scope,
	selector: string,
	properties: { [string]: any },
	subrules: { StyleRule }?
) -> StyleRule
export type StyleSheetConstructor = (
	scope: memory.Scope,
	properties: StyleSheetProperties
) -> StyleSheet

return nil
