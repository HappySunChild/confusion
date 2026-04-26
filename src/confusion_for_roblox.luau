--[[
package: confusion_for_roblox
author: HappySunChild (Eli)
repository: https://github.com/HappySunChild/confusion
--]]

local graph = require("./core_graph/types")
local memory = require("./core_memory/types")
local state = require("./core_state/types")
local use = require("./core_use/types")

local async = require("./async/types")
local chain = require("./chain/types")
local chrono = require("./chrono/types")
local context = require("./context/types")
local keyframes = require("./keyframes/types")
local safe = require("./safe/types")

local iter = require("./iter/types")
local iter_for = require("./iter_for/types")
local iter_range = require("./iter_range/types")

local motion = require("./motion/types")
local motion_springs = require("./motion_springs/types")
local motion_tweens = require("./motion_tweens/types")

local rbx_binds = require("./roblox_binds/types")
local rbx_instances = require("./roblox_instances/types")
local rbx_stylesheets = require("./roblox_stylesheets/types")
local rbx_templates = require("./roblox_templates/types")

export type Scope<T = Confusion> = memory.Scope<T>

export type GraphNode = graph.GraphNode
export type StateNode<T> = state.StateNode<T>
export type UsedAs<T> = state.UsedAs<T>

export type Value<T> = state.Value<T>
export type Computed<T> = state.Computed<T>
export type Use = state.Use

export type Iter<K, V> = iter.Iter<K, V>

export type Motion<T> = motion.Motion<T>
export type TweenInfo = motion_tweens.TweenInfo

export type Eventual<T> = async.Eventual<T>

export type Contextual<T> = context.Contextual<T>

export type Timer = chrono.Timer

export type Chain<T, S = unknown> = chain.Chain<S, T>

export type SpecialKey<T = string> = rbx_instances.SpecialKey
export type Child = rbx_instances.Child

type Confusion = {
	version: { major: number, minor: number, patch: number },

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

	-- Iter: For
	ForPairs: iter_for.ForPairsConstructor,
	ForKeys: iter_for.ForKeysConstructor,
	ForValues: iter_for.ForValuesConstructor,

	-- Iter: Range
	ForRange: iter_range.ForRangeConstructor,

	-- Async
	Eventual: async.EventualConstructor,
	await: async.Await,

	-- Context
	Contextual: context.ContextConstructor,

	-- Chrono
	Timer: chrono.TimerConstructor,

	-- Safe
	safe: safe.Safe,

	-- Keyframes
	Keyframes: keyframes.KeyframesConstructor,

	-- Motion
	Motion: motion.MotionConstructor,

	-- Motion: Springs
	Spring: motion_springs.SpringConstructor,

	-- Motion: Tweens
	Tween: motion_tweens.TweenConstructor,
	TweenInfo: motion_tweens.TweenInfoConstructor,
	easing_styles: motion_tweens.EasingStyles,

	-- Chain
	Chain: chain.ChainConstructor,

	-- Roblox: Instances
	New: rbx_instances.NewConstructor,
	Hydrate: rbx_instances.HydrateConstructor,
	Describe: rbx_instances.DescribeConstructor,

	AttributeChange: (attribute: string) -> rbx_instances.SpecialKey<"AttributeChange">,
	AttributeOut: (attribute: string) -> rbx_instances.SpecialKey<"AttributeOut">,
	Attributes: rbx_instances.SpecialKey<"Attributes">,
	Children: rbx_instances.SpecialKey<"Children">,
	OnChange: (property: string) -> rbx_instances.SpecialKey<"OnChange">,
	OnEvent: (event: string) -> rbx_instances.SpecialKey<"OnEvent">,
	Out: (property: string) -> rbx_instances.SpecialKey<"Out">,
	Refs: rbx_instances.SpecialKey<"Refs">,
	Tags: rbx_instances.SpecialKey<"Tags">,

	-- Roblox: Templates
	FromTemplate: rbx_templates.FromTemplateConstructor,
	QueryDescendants: rbx_templates.QueryDescendants,

	-- Roblox: Binds
	PropertyOf: rbx_binds.PropertyOfConstructor,
	AttributeOf: rbx_binds.AttributeOfConstructor,

	-- Roblox: Stylesheets
	StyleSheet: rbx_stylesheets.StyleSheetConstructor,

	StyleSheetDerives: rbx_instances.SpecialKey<"StyleSheetDerives">,
	StyleRuleProperties: rbx_instances.SpecialKey<"StyleRuleProperties">,
	StyleLink: rbx_instances.SpecialKey<"StyleLink">,
	StyleRules: rbx_instances.SpecialKey<"StyleRules">,
}

local ExternalLogger = require("./core_external/ExternalLogger")
ExternalLogger.set_logger(require("./roblox_external/RobloxLogger"))

local ExternalScheduler = require("./core_external/ExternalScheduler")
ExternalScheduler.set_scheduler(require("./roblox_external/RobloxScheduler"))

local confusion_for_roblox = {
	version = { major = 0, minor = 0, patch = 0 },

	-- Core: Memory
	scoped = require("./core_memory/scoped"),
	derive_scope = require("./core_memory/derive_scope"),
	inner_scope = require("./core_memory/inner_scope"),
	cleanup = require("./core_memory/cleanup"),
	insert = require("./core_memory/insert"),

	-- Core: State
	Computed = require("./core_state/Computed"),
	Value = require("./core_state/Value"),

	-- Core: Graph
	observe = require("./core_graph/observe"),
	observe_immediate = require("./core_graph/observe_immediate"),

	-- Core: Use
	peek = require("./core_use/peek"),
	flatten = require("./core_use/flatten"),

	-- Iter: For
	ForPairs = require("./iter_for/ForPairs"),
	ForKeys = require("./iter_for/ForKeys"),
	ForValues = require("./iter_for/ForValues"),

	-- Iter: Range
	ForRange = require("./iter_range/ForRange"),

	-- Async
	Eventual = require("./async/Eventual"),
	await = require("./async/await"),

	-- Context
	Contextual = require("./context/Contextual"),

	-- Chrono
	Timer = require("./chrono/Timer"),

	-- Safe
	safe = require("./safe/safe"),

	-- Keyframes
	Keyframes = require("./keyframes/Keyframes"),

	-- Motion
	Motion = require("./motion/Motion"),

	-- Motion: Springs
	Spring = require("./motion_springs/Spring"),

	-- Motion: Tweens
	Tween = require("./motion_tweens/Tween"),
	TweenInfo = require("./motion_tweens/TweenInfo"),
	easing_styles = require("./motion_tweens/easing_styles"),

	-- Chain
	Chain = require("./chain/Chain"),

	-- Roblox: Instances
	New = require("./roblox_instances/New"),
	Hydrate = require("./roblox_instances/Hydrate"),
	Describe = require("./roblox_instances/Describe"),

	AttributeChange = require("./roblox_instances/keys/AttributeChange"),
	AttributeOut = require("./roblox_instances/keys/AttributeOut"),
	Attributes = require("./roblox_instances/keys/Attributes"),
	Children = require("./roblox_instances/keys/Children"),
	OnChange = require("./roblox_instances/keys/OnChange"),
	OnEvent = require("./roblox_instances/keys/OnEvent"),
	Out = require("./roblox_instances/keys/Out"),
	Refs = require("./roblox_instances/keys/Refs"),
	Tags = require("./roblox_instances/keys/Tags"),

	-- Roblox: Templates
	FromTemplate = require("./roblox_templates/FromTemplate"),
	QueryDescendants = require("./roblox_templates/QueryDescendants"),

	-- Roblox: Binds
	PropertyOf = require("./roblox_binds/PropertyOf"),
	AttributeOf = require("./roblox_binds/AttributeOf"),

	-- Roblox: Stylesheets
	StyleSheet = require("./roblox_stylesheets/StyleSheet"),

	StyleSheetDerives = require("./roblox_stylesheets/keys/StyleSheetDerives"),
	StyleRuleProperties = require("./roblox_stylesheets/keys/StyleRuleProperties"),
	StyleLink = require("./roblox_stylesheets/keys/StyleLink"),
	StyleRules = require("./roblox_stylesheets/keys/StyleRules"),
}

return confusion_for_roblox :: Confusion
