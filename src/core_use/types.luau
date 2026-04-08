local state = require("../core_state/types")

export type Flatten = <T>(use: state.Use, x: state.UsedAs<T>) -> T

return {
	invalid_user = "Unnable to create `use` callback for non-state user; got a value of type '%*' (%*)",
}
