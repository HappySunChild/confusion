--!strict

const memory = require("../core_memory/types")
const state = require("../core_state/types")

--- A function that generates a `Curve` based off the initial parameters given to it.
export type Mover = (initial_values: { { number } }) -> Curve
--- A function that calculates the displacement, velocity, acceleration, etc. of a curve at a specific time.
export type Curve = (time_elapsed: number) -> { { number } }

export type Space = {
	to_displacement: (position: { number }, relative_to: { number }) -> { number },
	to_position: (displacement: { number }, relative_to: { number }) -> { number },
}
export type Compositor<T> = {
	compose: ({ number }) -> T,
	decompose: (T) -> { number },
	space: Space,
}

export type Spaces = {
	linear: Space,
	linear_wrapped: (minimum: number, maximum: number) -> Space,

	degrees_unsigned: Space,
	degrees_signed: Space,
	radians_unsigned: Space,
	radians_signed: Space,
}

export type Composition = {
	number: {
		linear: Compositor<number>,
	},
	vector: {
		linear: Compositor<vector>,
	},
}

export type Motion<T> = {
	set_displacement: (Motion<T>, { number }) -> (),
	set_velocity: (Motion<T>, { number }) -> (),

	get_displacement: (Motion<T>) -> T,
	get_velocity: (Motion<T>) -> T,
} & state.StateNode<T>
export type MotionConstructor = <T>(
	scope: memory.Scope,
	mover: state.UsedAs<Mover>,
	compositor: Compositor<T>,
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
