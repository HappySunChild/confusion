local graph = require("../core_graph/types")
local state = require("../core_state/types")

export type Disassembly<OK, OV> = {
	populate: (Disassembly<OK, OV>, use: state.Use, output: { [OK]: OV }) -> (),
} & graph.GraphNode

export type Iter<K, V> = {
	kind: "Iter",
	timeliness: "lazy",
} & state.StateNode<{ [K]: V }>

return nil
