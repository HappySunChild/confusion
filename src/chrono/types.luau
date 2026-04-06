local calc = require("../core_calc/types")
local memory = require("../core_memory/types")

export type ExternalTime = calc.StateNode<number> & {
	kind: "ExternalTime",

	enable: (ExternalTime) -> (),
	disable: (ExternalTime) -> (),
	is_enabled: (ExternalTime) -> boolean,
}

export type Timer = calc.StateNode<number> & {
	kind: "Timer",
	is_paused: boolean,
	reference_point: number,

	pause: (Timer) -> (),
	unpause: (Timer) -> (),
	zero: (Timer) -> (),
}
export type TimerConstructor = (scope: memory.Scope) -> Timer

return nil
