local memory = require("../core_memory/types")
local state = require("../core_state/types")

export type SpecialKeyStage = | "self" | "descendants" | "properties" | "ancestor" | "observer" | "last"

export type SpecialKey<T = string> = {
	type: "SpecialKey",
	kind: T,
	stage: SpecialKeyStage,
	apply: (scope: memory.Scope, instance: Instance, value: unknown) -> (),
}

export type ChildState = state.StateNode<Child>
export type ChildUnresolved = (parent: Instance) -> Child?
export type ChildMany = { Child }
export type Child = Instance | ChildState | ChildUnresolved | ChildMany

export type Properties = { [string | number | SpecialKey]: any }
export type Tag = string | { Tag } | state.StateNode<Tag>

-- straight outa fluid because i can't be bothered to type this out manually
type _Instances = {
	PyramidHandleAdornment: PyramidHandleAdornment,
	AudioChannelSplitter: AudioChannelSplitter,
	AudioPitchShifter: AudioPitchShifter,
	AudioDeviceOutput: AudioDeviceOutput,
	AudioChannelMixer: AudioChannelMixer,
	AudioTextToSpeech: AudioTextToSpeech,
	AudioDeviceInput: AudioDeviceInput,
	AudioDistortion: AudioDistortion,
	AudioCompressor: AudioCompressor,
	AudioEqualizer: AudioEqualizer,
	AudioAnalyzer: AudioAnalyzer,
	AudioListener: AudioListener,
	AudioRecorder: AudioRecorder,
	AudioLimiter: AudioLimiter,
	AudioFlanger: AudioFlanger,
	AudioEmitter: AudioEmitter,
	AudioPlayer: AudioPlayer,
	AudioReverb: AudioReverb,
	AudioFilter: AudioFilter,
	ArcHandles: ArcHandles,
	AudioFader: AudioFader,
	AudioEcho: AudioEcho,
	AdGui: AdGui,
	BoxHandleAdornment: BoxHandleAdornment,
	BillboardGui: BillboardGui,
	BlurEffect: BlurEffect,
	CylinderHandleAdornment: CylinderHandleAdornment,
	ConeHandleAdornment: ConeHandleAdornment,
	CanvasGroup: CanvasGroup,
	Camera: Camera,
	DialogChoice: DialogChoice,
	DragDetector: DragDetector,
	Dialog: Dialog,
	Folder: Folder,
	Frame: Frame,
	Highlight: Highlight,
	Handles: Handles,
	ImageHandLeAdornment: ImageHandleAdornment,
	ImageButton: ImageButton,
	ImageLabel: ImageLabel,
	LineHandleAdornment: LineHandleAdornment,
	ProximityPrompt: ProximityPrompt,
	Path2D: Path2D,
	Part: Part,
	SphereHandLeAdornment: SphereHandleAdornment,
	SelectionSphere: SelectionSphere,
	ScrollingFrame: ScrollingFrame,
	SelectionBox: SelectionBox,
	StyleDerive: StyleDerive,
	StyleQuery: StyleQuery,
	SurfaceGui: SurfaceGui,
	StyleSheet: StyleSheet,
	SoundGroup: SoundGroup,
	StyleLink: StyleLink,
	ScreenGui: ScreenGui,
	StyleBase: StyleBase,
	StyleRule: StyleRule,
	Sound: Sound,
	TextButton: TextButton,
	TextLabel: TextLabel,
	TextBox: TextBox,
	UIAspectRatioConstraint: UIAspectRatioConstraint,
	UITextSizeConstraint: UITextSizeConstraint,
	UISizeConstraint: UISizeConstraint,
	UIDragDetector: UIDragDetector,
	UITableLayout: UITableLayout,
	UIPageLayout: UIPageLayout,
	UIGridLayout: UIGridLayout,
	UIListLayout: UIListLayout,
	UIGradient: UIGradient,
	UIFlexItem: UIFlexItem,
	UIPadding: UIPadding,
	UIStroke: UIStroke,
	UICorner: UICorner,
	UIShadow: UIShadow,
	UIScale: UIScale,
	ViewportFrame: ViewportFrame,
	VideoDisplay: VideoDisplay,
	VideoFrame: VideoFrame,
	WireframeHandleAdornment: WireframeHandleAdornment,
	WorldModel: WorldModel,
	Wire: Wire,
}
type _Instance = Instance

type function get_instance_type(class_name: type): type
	if not class_name:is("singleton") then
		return _Instance
	end

	return _Instances:readproperty(class_name) or _Instance
end

type function get_properties_for(class_name: type): type
	const object = get_instance_type(class_name) :: type
	local current = object

	const properties = types.newtable()

	while current ~= nil do
		for property, value in current:properties() do
			const value_read, value_write = value.read, value.write

			if value_read then
				if
					value_read.tag == "function"
					or value_read.tag == "intersection"
					or (value_read.tag == "table" and value_read:readproperty(types.singleton("Connect")))
				then
					continue
				end
			end

			if value_write then
				properties:setproperty(property, types.optional(value_write))
			end
		end

		current = current:readparent()
	end

	return properties
end

export type NewConstructor = <ClassName>(
	scope: memory.Scope,
	class_name: ClassName | keyof<_Instances>,
	properties: get_properties_for<ClassName>
) -> get_instance_type<ClassName>
export type HydrateConstructor = <InstanceT>(
	scope: memory.Scope,
	instance: InstanceT,
	properties: Properties
) -> InstanceT

return {
	cannot_create_class = "Unable to create instance of type '{class}'.",
	cannot_connect_change = "The {class} class doesn't have a property called '{property}'.",
	cannot_connect_event = "The {class} class doesn't have a event called '{event}'.",

	property_cannot_assign = "The {class} class has no assignable property '{property}'.",
	property_assign_error = "An error occured while setting property '{class}.{property}' to {value}:\nERROR_MESSAGE",

	invalid_key_type = "Invalid key type: expected a 'string | SpecialKey' type, but got a '{given_type}' type.",
	invalid_child_type = "Invalid child type: expected a 'Instance | (Instance) -> [RECURSE] | { [RECURSE] } | StateNode<[RECURSE]>' type, but got a '{given_type}' type.",
	invalid_tag_type = "Invalid tag type: expected a 'string | { [RECURSE] } | StateNode<[RECURSE]>' type, but got a '{given_type}' type.",
	invalid_ref_type = "Invalid ref type: expected a 'Value' type, but got a '{given_type}' type.",
	invalid_out_type = "Invalid out type: expected a 'Value' type, but got a '{given_type}' type.",
	invalid_property_type = "'{class}.{property}' expected a '{expected_type}' type, but got a '{given_type}' type.",

	missing_specialkey_stage = "The SpecialKey '{kind}' is missing a stage property.",
	invalid_specialkey_stage = "The SpecialKey '{kind}' has an invalid stage '{stage}'.",
	specialkey_apply_error = "The SpecialKey '{kind}' errored while being applied to {instance_class} '{instance_name}' with value {value} at stage '{stage}':\nERROR_MESSAGE",
}
