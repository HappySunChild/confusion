--!strict

const memory = require("../core_memory/types")
const motion = require("../motion/types")
const state = require("../core_state/types")

export type SpringConstructor = <T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	speed: state.UsedAs<number>?,
	damping: state.UsedAs<number>?
) -> motion.OldMotion<T>

export type SpringMover = (damping: number, speed: number) -> motion.Transition

return nil
