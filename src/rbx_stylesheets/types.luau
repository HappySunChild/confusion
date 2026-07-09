local memory = require("../core_memory/types")
local state = require("../core_state/types")

export type StyleRuleDescription = {
	[string | number]: any,
}

export type StyleSheetProperties = {
	derives: { StyleSheet }?,
	rules: { [number]: StyleRule | StyleRuleDescription }?,
	tokens: { [string]: state.UsedAs<any> }?,

	parent: state.UsedAs<Instance>?,
	name: state.UsedAs<string>?,
}

export type StyleSheetConstructor = (scope: memory.Scope, properties: StyleSheetProperties) -> StyleSheet

return nil
