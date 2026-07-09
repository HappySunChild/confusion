const memory = require("../core_memory/types")
const rbx_instances = require("../rbx_instances/types")
const templates = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const Hydrate = require("../rbx_instances/Hydrate")

const function FromTemplate<InstanceT>(scope: memory.Scope, template: InstanceT, properties: rbx_instances.Properties): InstanceT
	template = template :: Instance

	const new_instance = template:Clone()

	if new_instance == nil then
		log_error(
			if template.Archivable
				then templates.cannot_clone_template
				else templates.cannot_clone_template_unarchivable,
			nil,
			template.ClassName,
			template:GetFullName()
		)
	end

	return Hydrate(scope, template, properties)
end

return FromTemplate
