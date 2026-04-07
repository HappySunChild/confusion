local memory = require("../core_memory/types")
local motion = require("../motion/types")
local state = require("../core_state/types")

export type SpringConstructor = <T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	speed: state.UsedAs<number>?,
	damping: state.UsedAs<number>?
) -> motion.Motion<T>

return nil
