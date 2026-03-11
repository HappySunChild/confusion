type Pair = { key: string, value: string }

local function render_table_pairs(ordered_pairs: { Pair }, depth: number)
	if #ordered_pairs == 0 then
		return "{}"
	end

	local outer_indent = string.rep("\t", depth)
	local inner_indent = string.rep("\t", depth + 1)

	local lines = { "{" }

	for _, pair in ordered_pairs do
		table.insert(lines, `{inner_indent}[{pair.key}] = {pair.value};`)
	end

	table.insert(lines, outer_indent .. "}")

	return table.concat(lines, "\n")
end

local function fmt_repr(value: unknown): string
	local value_type = type(value)

	if value_type == "string" then
		local str: string = value :: any

		return `"{str}"`
	elseif value_type == "function" then
		local func: () -> () = value :: any
		local arg_count: number, variadic: boolean, name: string? = debug.info(func, "an")

		local display_args = {}

		for i = 1, arg_count do
			table.insert(display_args, `a{i - 1}`)
		end

		if variadic then
			table.insert(display_args, "...")
		end

		return `function {name or ""}({table.concat(display_args, ", ")})`
	elseif value_type == "table" then
		local active: { [any]: number } = {}

		local function recursive(target: any, depth: number): string
			if type(target) ~= "table" then
				return fmt_repr(target)
			end

			if active[target] ~= nil then
				return `[ RECURSIVE +{depth - active[target] - 1} ]`
			end

			active[target] = depth

			local ordered_pairs: { Pair } = {}

			for k, v in target do
				table.insert(ordered_pairs, {
					key = recursive(k, depth + 1),
					value = recursive(v, depth + 1),
				})
			end

			table.sort(ordered_pairs, function(a: Pair, b: Pair)
				return a.key < b.key
			end)

			local isfrozen = table.isfrozen(target)
			local metatable = getmetatable(target) :: any

			local output = render_table_pairs(ordered_pairs, depth)

			if metatable then
				output = `setmetatable({output}, {recursive(metatable, depth)})`
			end

			if isfrozen then
				output = `table.freeze({output})`
			end

			active[target] = nil

			return output
		end

		return recursive(value, 0)
	end

	return tostring(value)
end

return fmt_repr :: (value: unknown) -> string
