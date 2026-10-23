--!strict

const graph = require("../core_graph/types")
const state = require("../core_state/types")

export type Disassembly<OK, OV> = {
	populate: (Disassembly<OK, OV>, use: state.Use, output: { [OK]: OV }) -> (),
} & graph.GraphNode

export type Iter<K, V> = state.StateNode<{ [K]: V }>

return nil
