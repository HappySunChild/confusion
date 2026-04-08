local memory = require("../core_memory/types")
local state = require("../core_state/types")

export type AnimationMove<T> = (elapsed: number) -> (boolean, T, ...any)
export type MoveGenerator<T> = (goal: T, start: T, ...any) -> AnimationMove<T>

export type Motion<T> = {
	kind: "Motion",

	set_dynamic: (self: Motion<T>, index: number, value: any) -> (),
	set_dynamics: (self: Motion<T>, dynamics: { any }, at_index: number?) -> (),
	get_dynamic: (self: Motion<T>, index: number) -> any?,
	get_dynamics: (self: Motion<T>) -> { any },
} & state.StateNode<T>
export type MotionConstructor = <T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	move_generator: state.UsedAs<MoveGenerator<T>>
) -> Motion<T>

return {
	motion_invalid_goal = "A Motion was given a NaN goal. Ensure NaN isn't being passed anywhere!\nGoal: '%*'",
	motion_invalid_motion = "A Motion encountered NaN during motion. Ensure NaN/inf isn't being passed anywhere!\nCurrent: '%*'\nGoal: '%*'",
}
