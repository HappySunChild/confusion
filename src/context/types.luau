export type Contextual<T> = {
	type: "Contextual",

	now: (Contextual<T>) -> T,
	execute_with: <R, A...>(Contextual<T>, value: T, callback: (A...) -> R, A...) -> R,
}
export type ContextConstructor = <T>(default: T) -> Contextual<T>

return {
	callback_error = "Error in contextual callback with value {value}:\nERROR_MESSAGE",
}
