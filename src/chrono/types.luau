local graph = require("../core_graph/types")
local memory = require("../core_memory/types")

type pause = () -> ()
export type TimerConstructor = (scope: memory.Scope) -> (graph.usegetter<number>, pause)

return nil
