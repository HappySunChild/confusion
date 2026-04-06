local calc = require("../../core_calc/types")
local instances = require("../types")
local memory = require("../../core_memory/types")

local SpecialKey = require("../SpecialKey")
local cast_to_state = require("../../core_calc/cast_to_state")
local cleanup = require("../../core_memory/cleanup")
local log_error_nonfatal = require("../../core_logging/log_error_nonfatal")
local observe_immediate = require("../../core_graph/observe_immediate")
local peek = require("../../core_use/peek")

type TagsSet = { [string]: true }
type TagsScopes = { [string]: memory.Scope }

local function create_reconciler(
	scope: memory.Scope,
	processor: (
		child: instances.Tag,
		parent: Instance?,
		new_tags: TagsSet,
		new_scopes: TagsScopes,
		old_tags: TagsSet,
		old_scopes: TagsScopes
	) -> ()
)
	local old_tags: TagsSet, new_tags: TagsSet = {}, {}
	local old_scopes: TagsScopes, new_scopes: TagsScopes = {}, {}

	local function reconcile(new_tag: instances.Tag?, apply_to: Instance)
		old_tags, new_tags = new_tags, old_tags
		old_scopes, new_scopes = new_scopes, old_scopes

		if new_tag ~= nil then
			processor(new_tag, apply_to, new_tags, new_scopes, old_tags, old_scopes)
		end

		for old_tag in old_tags do
			apply_to:RemoveTag(old_tag)
		end

		for _, scope in old_scopes do
			cleanup(scope)
		end

		for new_tag in new_tags do
			if old_tags[new_tag] == nil then
				apply_to:AddTag(new_tag)
			end
		end

		table.clear(old_tags)
		table.clear(old_scopes)
	end

	-- cleanup
	table.insert(scope, reconcile)

	return reconcile
end

local function process_tag(
	tag: instances.Tag,
	apply_to: Instance,
	new_tags: TagsSet,
	new_scopes: TagsScopes,
	old_tags: TagsSet,
	old_scopes: TagsScopes
)
	local tag_type = typeof(tag)

	if tag_type == "string" then -- ROOT CASE
		tag = tag :: string

		new_tags[tag] = true
		old_tags[tag] = nil
	elseif cast_to_state(tag) ~= nil then -- STATE CASE
		tag = tag :: calc.StateNode<instances.Tag>

		local tag_scope = old_scopes[tag]

		if tag_scope == nil then
			tag_scope = {}

			local reconcile = create_reconciler(tag_scope, process_tag)

			observe_immediate(tag_scope, tag, function()
				reconcile(peek(tag), apply_to)
			end)
		else
			old_scopes[tag] = nil
		end

		new_scopes[tag] = tag_scope
	elseif tag_type == "table" then -- NESTED CASE
		tag = tag :: { instances.Tag }
		for _, sub_tag in tag do
			process_tag(sub_tag, apply_to, new_tags, new_scopes, old_tags, old_scopes)
		end
	else
		log_error_nonfatal(instances.invalid_tag_type, debug.traceback(nil, 2), tag_type)
	end
end

local Tags = SpecialKey(
	"self",
	"Tags",
	function(scope: memory.Scope, apply_to: Instance, root_tag: instances.Tag?)
		local reconcile = create_reconciler(scope, process_tag)
		reconcile(root_tag, apply_to)
	end
)

return Tags
