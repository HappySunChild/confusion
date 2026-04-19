local memory = require("../../core_memory/types")
local rbx_instances = require("../types")
local state = require("../../core_state/types")

local cast_to_state = require("../../core_state/cast_to_state")
local cleanup = require("../../core_memory/cleanup")
local log_error_nonfatal = require("../../core_logging/log_error_nonfatal")
local observe_immediate = require("../../core_graph/observe_immediate")
local peek = require("../../core_use/peek")

type ChildrenSet = { [Instance]: true }
type ChildrenScopes = { [rbx_instances.Child]: memory.Scope }

local function create_reconciler(
	scope: memory.Scope,
	parent: Instance,
	processor: (
		child: rbx_instances.Child,
		parent: Instance,
		new_children: ChildrenSet,
		new_scopes: ChildrenScopes,
		old_children: ChildrenSet,
		old_scopes: ChildrenScopes
	) -> ()
)
	local old_children: ChildrenSet, new_children: ChildrenSet = {}, {}
	local old_scopes: ChildrenScopes, new_scopes: ChildrenScopes = {}, {}

	local function reconcile(new_child: rbx_instances.Child?)
		old_children, new_children = new_children, old_children
		old_scopes, new_scopes = new_scopes, old_scopes

		if new_child ~= nil then
			processor(new_child, parent, new_children, new_scopes, old_children, old_scopes)
		end

		for old_child in old_children do
			old_child.Parent = nil
		end

		for _, scope in old_scopes do
			cleanup(scope)
		end

		-- reparenting has been deferred to fix a bug with nested state objects
		for new_child in new_children do
			if new_child.Parent == nil and old_children[new_child] == nil then
				new_child.Parent = parent
			end
		end

		table.clear(old_children)
		table.clear(old_scopes)
	end

	-- cleanup
	table.insert(scope, reconcile)

	return reconcile
end

local function process_child(
	child: rbx_instances.Child,
	parent: Instance,
	new_children: ChildrenSet,
	new_scopes: ChildrenScopes,
	old_children: ChildrenSet,
	old_scopes: ChildrenScopes
)
	local child_type = typeof(child)

	if child_type == "Instance" then -- ROOT CASE
		child = child :: Instance

		new_children[child] = true
		old_children[child] = nil
	elseif child_type == "function" then -- UNRESOLVED CASE
		child = child :: (Instance) -> rbx_instances.Child

		local actual_child = child(parent)

		if actual_child ~= nil then
			process_child(actual_child, parent, new_children, new_scopes, old_children, old_scopes)
		end
	elseif cast_to_state(child) ~= nil then -- STATE CASE
		child = child :: state.StateNode<rbx_instances.Child>

		local child_scope = old_scopes[child]

		if child_scope == nil then
			child_scope = {}

			local reconcile = create_reconciler(child_scope, parent, process_child)

			observe_immediate(child_scope, child, function()
				reconcile(peek(child))
			end)
		else
			old_scopes[child] = nil
		end

		new_scopes[child] = child_scope
	elseif child_type == "table" then -- NESTED CASE
		child = child :: { rbx_instances.Child }
		for _, descendant in child do
			process_child(descendant, parent, new_children, new_scopes, old_children, old_scopes)
		end
	else
		log_error_nonfatal(rbx_instances.invalid_child_type, debug.traceback(nil, 2), child_type)
	end
end

return {
	type = "SpecialKey",
	kind = "Children",
	stage = "descendants",
	apply = function(scope: memory.Scope, apply_to: Instance, root_child: rbx_instances.Child)
		local reconcile = create_reconciler(scope, apply_to, process_child)
		reconcile(root_child, apply_to)
	end,
} :: rbx_instances.SpecialKey<"Children">
