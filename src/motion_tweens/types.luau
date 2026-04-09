local memory = require("../core_memory/types")
local motion = require("../motion/types")
local state = require("../core_state/types")

export type TweenConstructor = <T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	info: state.UsedAs<TweenInfo>
) -> motion.Motion<T>

export type EasingStyle = {
	read Out: (number) -> number,
	read In: (number) -> number,
	read InOut: (number) -> number,
}

export type EasingStyles = {
	read Constant: EasingStyle,
	read Linear: EasingStyle,
	read Exponential: EasingStyle,
	read Circular: EasingStyle,
	read Sine: EasingStyle,

	read Back: EasingStyle,
	read Elastic: EasingStyle,

	read Quad: EasingStyle,
	read Cubic: EasingStyle,
	read Quart: EasingStyle,
	read Quint: EasingStyle,

	read create: {
		read Exponent: (exponent: number) -> EasingStyle,
		read Overshoot: (amplitude: number) -> EasingStyle,
		read Elastic: (period: number) -> EasingStyle,
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
