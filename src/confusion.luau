local external = require("./core_external/types")
local graph = require("./core_graph/types")
local memory = require("./core_memory/types")
local state = require("./core_state/types")
local use = require("./core_use/types")

local ExternalDebugger = require("./core_external/ExternalDebug")
local ExternalLogger = require("./core_external/ExternalLogger")
local ExternalScheduler = require("./core_external/ExternalScheduler")

local merge = require("./core_memory/merge")

type Version = {
	read major: number,
	read minor: number,
}

type Configuration<Included> = {
	version: Version,
	include: Included,
	scheduler: external.ExternalScheduler,
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
	Computed: state.ComputedConstructor,
	Value: state.ValueConstructor,

	-- Core: Graph
	observe: graph.Observe,
	observe_immediate: graph.Observe,

	-- Core: Use
	peek: state.Use,
	flatten: use.Flatten,
} & Included

local CORE_CONFUSION = table.freeze({
	scoped = require("./core_memory/scoped"),
	derive_scope = require("./core_memory/derive_scope"),
	inner_scope = require("./core_memory/inner_scope"),
	cleanup = require("./core_memory/cleanup"),
	insert = require("./core_memory/insert"),

	Computed = require("./core_state/Computed"),
	Value = require("./core_state/Value"),

	observe = require("./core_graph/observe"),
	observe_immediate = require("./core_graph/observe_immediate"),

	peek = require("./core_use/peek"),
	flatten = require("./core_use/flatten"),
})

local function confusion<I>(options: Configuration<I>): ConFusion<I>
	ExternalScheduler.set_scheduler(options.scheduler)
	ExternalDebugger.set_debugger(options.debugger)
	ExternalLogger.set_logger(options.logger)

	local include = options.include

	assert(type(include) == "table", "`include` field should be a table!")

	local new_confusion = merge(
		table.clone(CORE_CONFUSION :: any),
		include,
		{ version = options.version } -- always override version field
	)

	return new_confusion :: ConFusion<I>
end

return confusion
