--!strict
const function xtypeof(value: any): string
	const value_type = typeof(value)

	if value_type == "table" and value.type ~= nil then
		return value.type :: string
	end

	return value_type
end

return xtypeof
