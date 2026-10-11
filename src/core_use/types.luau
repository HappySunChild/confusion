const state = require("../core_state/types")

export type Flatten = <T>(use: state.Use, x: state.UsedAs<T>) -> T
export type Peek = state.Use

return {
	invalid_user = "Unnable to create `use` callback for non-state user; got a value of type '{type}' ({value})",
}
