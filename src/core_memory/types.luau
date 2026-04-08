export type Chore = any
export type Scope<T = any> = { Chore } & T

export type Cleanup = (Chore) -> ()
export type Scoped = <T, M>(base: T, methods: M?) -> Scope<T & M>
export type Insert = <Tasks...>(scope: Scope, Tasks...) -> Tasks...

return {
	use_after_destroy = "%s is no longer valid - it was destroyed before %s.",

	destroyed_twice = "`cleanup()` was given something that it is already cleaning up. Unclear how to proceed.",
	unknown_cleanup_task = "`cleanup()` was given something it can't cleanup. Unclear how to proceed. (%*)",
}
