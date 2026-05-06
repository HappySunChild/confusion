local memory = require("../core_memory/types")

export type Set<T> = { [T]: true }

export type Validity = "valid" | "invalid" | "busy"

export type observer = (source?) -> ()
export type source = (observer?, boolean?) -> number
export type capture = (source) -> observer

export type disconnect = () -> ()

export type getter<T> = (capture?) -> T
export type setter<T> = (T) -> ()

export type UsedAs<T> = T | getter<T>
export type use = <T>(UsedAs<T>) -> T

export type ObserverCallback = (use) -> ()
export type ObserverConstructor = (memory.Scope, ObserverCallback) -> disconnect

return {
	infinite_loop = "Detected an infinite loop. Consider adding an explicit breakpoint to your code to prevent a cyclic dependency.",
}
