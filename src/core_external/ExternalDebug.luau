--!strict
--!native
--!optimize 2

const external = require("./types")
const memory = require("../core_memory/types")

local current_debugger: external.ExternalDebugger? = nil

const function set_debugger(new_debugger: external.ExternalDebugger?)
	const old_debugger = current_debugger

	if old_debugger ~= nil then
		old_debugger.stop_debugging()
	end

	if new_debugger ~= nil then
		new_debugger.start_debugging()
	end

	current_debugger = new_debugger

	return old_debugger
end

const function track_scope(scope: memory.Scope)
	if current_debugger == nil then
		return
	end

	current_debugger.track_scope(scope)
end

const function untrack_scope(scope: memory.Scope)
	if current_debugger == nil then
		return
	end

	current_debugger.untrack_scope(scope)
end

const function begin_profile(label: string)
	if current_debugger == nil then
		return
	end

	current_debugger.begin_profile(label)
end

const function end_profile()
	if current_debugger == nil then
		return
	end

	current_debugger.end_profile()
end

return {
	set_debugger = set_debugger,

	track_scope = track_scope,
	untrack_scope = untrack_scope,

	begin_profile = begin_profile,
	end_profile = end_profile,
}
