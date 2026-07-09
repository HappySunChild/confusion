const rbx_instances = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_warn = ExternalLogger.log_warn

const STAGE_ORDER = table.freeze({
	self = 1,
	descendants = 2,
	properties = 4,
	ancestor = 8,
	observer = 16,
	last = math.huge,
})

const function sort_keys(a: rbx_instances.SpecialKey, b: rbx_instances.SpecialKey)
	const a_order = STAGE_ORDER[a.stage]
	const b_order = STAGE_ORDER[b.stage]

	if a_order == nil then
		log_warn(
			if a.stage == nil then rbx_instances.missing_specialkey_stage else rbx_instances.invalid_specialkey_stage,
			a.type,
			a.stage
		)

		return true
	elseif b_order == nil then
		log_warn(
			if b.stage == nil then rbx_instances.missing_specialkey_stage else rbx_instances.invalid_specialkey_stage,
			b.type,
			b.stage
		)

		return false
	end

	return a_order < b_order
end

return sort_keys
