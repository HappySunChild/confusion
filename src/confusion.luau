local calc = require("./core_calc/types")
local external = require("./core_external/types")
local graph = require("./core_graph/types")
local memory = require("./core_memory/types")
local use = require("./core_use/types")

local External = require("./core_external/External")
local ExternalDebugger = require("./core_external/ExternalDebug")
local ExternalLogger = require("./core_external/ExternalLogger")

local merge = require("./core_memory/merge")

type Version = {
	read major: number,
	read minor: number,
}

type Configuration<Included> = {
	version: Version,
	include: Included,
	provider: external.ExternalProvider,
	debugger: external.ExternalDebugger?,
	logger: external.ExternalLogger?,
}

export type ConFusion<Included = any> = {
	version: Version,

	-- Core: Memory
	scoped: memory.Scoped,
	derive_scope: memory.Scoped,
	inner_scope: memory.Scoped,
	cleanup: memory.Cleanup,
	insert: memory.Insert,

	-- Core: State
	Computed: calc.ComputedConstructor,
	Value: calc.ValueConstructor,

	-- Core: Graph
	observe: graph.Observe,
	observe_immediate: graph.Observe,

	-- Core: Use
	peek: calc.Use,
	flatten: use.Flatten,
} & Included

local CORE_CONFUSION = table.freeze({
	derive_scope = require("./core_memory/derive_scope"),
	cleanup = require("./core_memory/cleanup"),
	inner_scope = require("./core_memory/inner_scope"),
	insert = require("./core_memory/insert"),
	scoped = require("./core_memory/scoped"),

	Computed = require("./core_calc/Computed"),
	Value = require("./core_calc/Value"),

	observe = require("./core_graph/observe"),
	observe_immediate = require("./core_graph/observe_immediate"),

	flattern = require("./core_use/flatten"),
	peek = require("./core_use/peek"),
})

local function confusion<I>(options: Configuration<I>): ConFusion<I>
	External.set_provider(options.provider)
	ExternalDebugger.set_debugger(options.debugger)
	ExternalLogger.set_logger(options.logger)

	local include = options.include

	assert(type(include) == "table", "`include` field should be a table!")

	local new_confusion = merge(
		true,
		table.clone(CORE_CONFUSION),
		include,
		{ version = options.version } -- always override version field
	)

	return new_confusion :: ConFusion<I>
end

return confusion
