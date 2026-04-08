local memory = require("../core_memory/types")
local state = require("../core_state/types")

export type ExternalTime = state.StateNode<number> & {
	kind: "ExternalTime",

	enable: (ExternalTime) -> (),
	disable: (ExternalTime) -> (),
	is_enabled: (ExternalTime) -> boolean,
}

export type Timer = state.StateNode<number> & {
	kind: "Timer",
	is_paused: boolean,
	reference_point: number,

	pause: (Timer) -> (),
	unpause: (Timer) -> (),
	zero: (Timer) -> (),
}
export type TimerConstructor = (scope: memory.Scope) -> Timer

return nil
