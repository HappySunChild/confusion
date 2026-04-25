local memory = require("../core_memory/types")
local motion = require("../motion/types")
local state = require("../core_state/types")

export type TweenConstructor = <T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	info: state.UsedAs<TweenInfo>
) -> motion.Motion<T>

export type EasingStyle = {
	Out: (number) -> number,
	In: (number) -> number,
	InOut: (number) -> number,
}

export type EasingStyles = {
	Constant: EasingStyle,
	Linear: EasingStyle,
	Exponential: EasingStyle,
	Circular: EasingStyle,
	Sine: EasingStyle,

	Back: EasingStyle,
	Elastic: EasingStyle,

	Quad: EasingStyle,
	Cubic: EasingStyle,
	Quart: EasingStyle,
	Quint: EasingStyle,

	create: {
		Exponent: (exponent: number) -> EasingStyle,
		Overshoot: (amplitude: number) -> EasingStyle,
		Elastic: (period: number) -> EasingStyle,
	},
}

-- not to be confused with TweenInfo, this is TweenInfo. got that?
export type TweenInfo = {
	type: "TweenInfo",

	time: number,
	easing: (number) -> number,
	repeat_count: number,
	reverses: boolean,
	delay_time: number,
}
export type TweenInfoConstructor = (
	time: number?,
	easing: ((number) -> number)?,
	repeat_count: number?,
	reverses: boolean?,
	delay_time: number?
) -> TweenInfo

return nil
