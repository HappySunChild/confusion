--- Returns whether `a` and `b` are meaningfully similar.
local function is_similar(a: unknown, b: unknown): boolean
	local type_a = typeof(a)
	local is_table = type_a == "table"
	local is_userdata = type_a == "userdata"

	return if not (is_table or is_userdata)
		then a == b or a ~= a and b ~= b
		elseif
			type_a == typeof(b)
			and (is_userdata or table.isfrozen(a :: any) or getmetatable(a :: any) ~= nil)
		then a == b
		else false
end

return is_similar
