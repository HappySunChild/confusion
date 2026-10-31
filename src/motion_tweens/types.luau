--!strict

const memory = require("../core_memory/types")
const motion = require("../motion/types")
const state = require("../core_state/types")

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
	linear: (number) -> number,

	constant: EasingStyle,
	exponential: EasingStyle,
	circular: EasingStyle,
	sine: EasingStyle,

	back: EasingStyle,
	elastic: EasingStyle,

	quad: EasingStyle,
	cubic: EasingStyle,
	quart: EasingStyle,
	quint: EasingStyle,

	create: {
		exponent: (exponent: number) -> EasingStyle,
		overshoot: (amplitude: number) -> EasingStyle,
		elastic: (period: number) -> EasingStyle,
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
