local function xtypeof(value: any): string
	local value_type = typeof(value)

	if value_type == "table" and value.type ~= nil then
		return value.type
	end

	return value_type
end

return xtypeof
