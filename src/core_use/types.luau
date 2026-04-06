local calc = require("../core_calc/types")

export type Flatten = <T>(use: calc.Use, x: calc.UsedAs<T>) -> T

return {
	invalid_user = "Unnable to create `use` callback for non-state user; got a value of type '%*' (%*)",
}
