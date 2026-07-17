const memory = require("../core_memory/types")
const instances = require("../rbx_instances/types")
const audio = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error_nonfatal = ExternalLogger.log_error_nonfatal

const apply_instance_properties = require("../rbx_instances/apply_instance_properties")

type Wireable = Instance | { Wireable }

const function process_wire_target(scope: memory.Scope, apply_to: Instance, output_name: string, wireable: Wireable)
	const wireable_type = typeof(wireable)

	if wireable_type == "Instance" then
		const wire = Instance.new("Wire")

		-- probably bad
		if wireable.Parent == nil then
			wireable.Parent = apply_to
		end

		apply_instance_properties(scope, wire, {
			Parent = apply_to,
			SourceInstance = apply_to,
			TargetInstance = wireable,
			TargetName = output_name,
		})

		table.insert(scope, wire)
	elseif wireable_type == "table" then
		for _, sub_wireable in wireable do
			process_wire_target(scope, apply_to, output_name, sub_wireable)
		end
	else
		log_error_nonfatal(audio.invalid_wireable_type, debug.traceback(nil, 2), wireable_type)
	end
end

return {
	type = "SpecialKey",
	kind = "Connections",
	stage = "descendants",
	apply = function(scope: memory.Scope, apply_to: Instance, wireable_targets: { [string]: Wireable })
		for output_name, wireable in wireable_targets do
			process_wire_target(scope, apply_to, output_name, wireable)
		end
	end,
} :: instances.SpecialKey<"Connections">
