--!strict

const composition = require("../composition/types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

--- A function that generates a `Curve` based off the initial parameters given to it.
export type Mover = (initial_values: { { number } }) -> Curve
--- A function that calculates the displacement, velocity, acceleration, etc. of a curve at a specific time.
export type Curve = (time_elapsed: number) -> { { number } }
--- A function that creates a `Mover` that converges to a specified goal.
export type Transition = (goal: { number }, space: composition.Space) -> Mover

export type Motion<T> = {
	set_displacement: (Motion<T>, T) -> (),
	set_velocity: (Motion<T>, T) -> (),

	impulse_velocity: (Motion<T>, T) -> (),

	get_displacement: (Motion<T>) -> T,
	get_velocity: (Motion<T>) -> T,

	is_settled: (Motion<T>) -> boolean,
} & state.StateNode<T>
export type MotionConstructor = <T>(
	scope: memory.Scope,
	mover: state.UsedAs<Mover>,
	compositor: composition.Compositor<T>,
	initial_values: { T }?
) -> Motion<T>

-- old

export type AnimationCurve<T> = (elapsed: number) -> (boolean, T, ...any)
export type CurveGenerator<T> = (goal: T, start: T, ...any) -> AnimationCurve<T>

export type OldMotion<T> = {
	set_dynamic: (self: OldMotion<T>, index: number, value: any) -> (),
	set_dynamics: (self: OldMotion<T>, dynamics: { any }, at_index: number?) -> (),
	get_dynamic: (self: OldMotion<T>, index: number) -> any?,
	get_dynamics: (self: OldMotion<T>) -> { any },
} & state.StateNode<T>
export type OldMotionConstructor = <T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	curve_generator: state.UsedAs<CurveGenerator<T>>
) -> OldMotion<T>

return {
	motion_nan_goal = "A Motion was given a NaN goal. Ensure NaN isn't being passed anywhere!\nGoal: '{goal}'",
	motion_nan_motion = "A Motion encountered NaN during motion. Ensure NaN/inf isn't being passed anywhere!\nCurrent: '{current}'\nGoal: '{goal}'",
}
