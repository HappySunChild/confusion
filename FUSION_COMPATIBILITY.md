# API Compatibility with Fusion 0.3
This list is written assuming you're using the `confusion_for_roblox` package.

Most API differences between functions are only in name, they still behave the same/take the same parameters.

## Changed/Renamed
```diff
- scoped: <Methods...>(...: (Methods & {})...) -> Scope<merge(Methods...)>
+ scoped: <S, M>(base: S?, methods: M?) -> memory.Scope<S & M>

- deriveScope: <Existing, AddMethods...>(existing: Scope<Existing>, ...: (AddMethods & {})...) -> Scope<merge(Existing, AddMethods...)>
+ derive_scope: <S, M>(existing: memory.Scope<S>, methods: M?) -> memory.Scope<S & M>

- doCleanup: (task: Fusion.Task) -> ()
+ cleanup: (chore: any?) -> ()

- New: (scope: Scope<unknown>, className: string) -> (props: PropertyTable) -> Instance
+ New: (scope: memory.Scope, class_name: string, properties: instances.Properties) -> Instance

- Hydrate: (scope: Scope<unknown>, target: Instance) -> (props: PropertyTable) -> Instance
+ Hydrate: <InstanceT>(scope: memory.Scope, instance: InstanceT, properties: instances.Properties) -> InstanceT

- Tween: <T>(
- 	scope: Scope<unknown>,
- 	goal: UsedAs<T>,
- 	tweenInfo: UsedAs<TweenInfo>?
- ) -> Tween<T>
+ Tween: <T>(
+ 	scope: memory.Scope,
+ 	goal: state.UsedAs<T>,
+ 	info: state.UsedAs<tweens.TweenInfo
+ ) -> motion.Motion<T>

- Spring: <T>(
- 	scope: Scope<unknown>,
- 	goal: UsedAs<T>,
- 	speed: UsedAs<number>?,
- 	damping: UsedAs<number>?
- ) -> Spring<T>
+ Spring: <T>(
+ 	scope: memory.Scope,
+ 	goal: state.UsedAs<T>,
+ 	speed: state.UsedAs<number>?,
+ 	damping: state.UsedAs<number>?
+ ) -> motion.Motion<T>

- Safe: <Success, Fail>(callbacks: { try: () -> Success, fallback: (err: unknown) -> Fail }) -> Success | Fail
+ safe: <Ok, Err>(callbacks: { try: () -> Ok, fallback: (err: unknown) -> Err }) -> Ok | Err
```

## Removed
```luau
-- Core: Graph
Observer: (scope: Scope<unknown>, watching: unknown) -> Observer
```

## Added
```luau
-- Core: Memory
inner_scope: <S, M>(existing: memory.Scope<S>, methods: M?) -> memory.Scope<S & M>
insert: <Tasks...>(scope: memory.Scope, Tasks...) -> Tasks...

-- Core: Use
flatten: <T>(use: state.Use, x: state.UsedAs<T>) -> T

-- Core: Graph
observe: (scope: memory.Scope, subject: any?, callback: () -> ()) -> (() -> ())?
observe_immediate: (scope: memory.Scope, subject: any?, callback: () -> ()) -> (() -> ())?

-- Iter: Range
ForRange: <S, T>(
	scope: memory.Scope<S>,
	start: state.UsedAs<number>,
	finish: state.UsedAs<number>,
	processor: (use: state.Use, scope: memory.Scope<S>, index: number) -> T
) -> iter.Iter<number, T>

-- Async
Eventual: <S, T>(
	scope: memory.Scope<S>,
	processor: (use: state.Use, scope: memory.Scope<S>, become: (T) -> ()) -> (),
	pending_value: T
) -> async.Eventual<T>
await: (scope: memory.Scope, subject: graph.GraphNode) -> ()

-- Chrono
Timer: (scope: memory.Scope) -> chrono.Timer

-- Keyframes
Keyframes: <T>(
	scope: memory.Scope,
	alpha: state.UsedAs<number>,
	keyframes: { [number]: T }
) -> keyframes.Keyframes<T>

-- Motion
Motion: (
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	curve_generator: state.UsedAs<(goal: T, start: T, ...any) -> (elapsed: number) -> (boolean, T, ...any)>
)

-- Motion: Tweens
TweenInfo: (
	time: number?,
	easing: ((number) -> number)?,
	repeat_count: number?,
	reverses: boolean?,
	delay_time: number?
) -> tweens.TweenInfo
easing_styles: {
	Constant: tweens.EasingStyle,
	Linear: tweens.EasingStyle,
	Exponential: tweens.EasingStyle,
	Circular: tweens.EasingStyle,
	Sine: tweens.EasingStyle,
	Back: tweens.EasingStyle,
	Elastic: tweens.EasingStyle,
	Quad: tweens.EasingStyle,
	Cubic: tweens.EasingStyle,
	Quart: tweens.EasingStyle,
	Quint: tweens.EasingStyle,
	
	create: {
		Exponent: (exponent: number) -> tweens.EasingStyle,
		Overshoot: (amplitude: number) -> tweens.EasingStyle,
		Elastic: (period: number) -> tweens.EasingStyle,
	},
}

-- Chain
Chain: <S, T>(
	scope: memory.Scope<S>,
	initial_value: T
) -> chain.Chain<S, T>

-- Roblox: Instances
Describe: (
	scope: memory.Scope,
	description: { [number | string]: any }
) -> Instance

Refs: instances.SpecialKey<"Refs">,
Tags: instances.SpecialKey<"Tags">,

-- Roblox: Templates
FromTemplate: <InstanceT>(
	scope: memory.Scope,
	template: InstanceT,
	properties: instances.Properties
) -> InstanceT
QueryDescendants: (
	scope: memory.Scope,
	selector: string,
	properties: instances.Properties
) -> (parent: Instance) -> Instance?

-- Roblox: Binds
PropertyOf: (
	scope: memory.Scope,
	instance: Instance,
	property: string
) -> binds.PropertyOf<unknown>
AttributeOf: (
	scope: memory.Scope,
	instance: Instance,
	attribute: string
) -> binds.AttributeOf<unknown>

-- Roblox: Stylesheets
StyleSheet: (
	scope: memory.Scope,
	properties: {
		derives: { StyleSheet }?,
		rules: { [number]: StyleRule | { [string | number]: any } }?,
		tokens: { [string]: state.UsedAs<any> }?,
		
		parent: state.UsedAs<Instance>?,
		name: state.UsedAs<string>?,
	}
) -> StyleSheet
StyleSheetDerives: instances.SpecialKey<"StyleSheetDerives">,
StyleRuleProperties: instances.SpecialKey<"StyleRuleProperties">,
StyleLink: instances.SpecialKey<"StyleLink">,
StyleRules: instances.SpecialKey<"StyleRules">,
```