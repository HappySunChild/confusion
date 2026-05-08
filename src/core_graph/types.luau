local memory = require("../core_memory/types")

export type Set<T> = { [T]: true }

export type Validity = "valid" | "invalid" | "busy"

export type observer = (disconnect_source: source?) -> ()
export type source = (target: observer?, remove: boolean?) -> number
export type capture = (using: source) -> observer

export type disconnect = () -> ()

export type usegetter<T> = { type: "getter", raw: rawgetter<T> }
export type rawgetter<T> = (capture: capture?) -> T
export type setter<T> = (T) -> ()

export type UsedAs<T> = T | usegetter<T>
export type use = <T>(UsedAs<T>) -> T

export type ObserverCallback = (use) -> ()
export type ObserverConstructor = (memory.Scope, ObserverCallback) -> disconnect

return {
	infinite_loop = "Detected an infinite loop. Consider adding an explicit breakpoint to your code to prevent a cyclic dependency.",
}
