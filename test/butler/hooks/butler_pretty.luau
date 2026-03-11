local butler = require("../butler")
local butler_hooks = require("../butler_hooks")

export type HookMethod = | "add_annotations" | "add_line_items" | butler_hooks.HookMethod

type FormattedResult = {
	test_results: butler.TestRunResult,
	icon: string,

	full_label: string,
	annotations: string,
}

export type Options = {
	hooks: { butler_hooks.Hook }?,
	disable_unicode: boolean?,
	disable_emoji: boolean?,
	disable_color: boolean?,
	line_width: number?,
}

local function butler_pretty(options: Options)
	local hooks = butler_hooks(options.hooks)

	local ANSI_RESET = "\x1b[0m"

	local DISABLE_UNICODE = options.disable_unicode
	local DISABLE_EMOJI = options.disable_emoji
	local DISABLE_COLOR = options.disable_color

	local function bind_tint(...: string)
		local ansi_code = `\x1b[{table.concat({ ... }, ";")}m`

		return function(text: any): string
			return if DISABLE_COLOR
				then tostring(text)
				else ansi_code .. tostring(text) .. ANSI_RESET
		end
	end

	-- COLORS
	local dim = bind_tint("2", "90")
	local pass_bright = bind_tint("92")
	local pass = bind_tint("32")
	local fail_bright = bind_tint("91")
	local fail = bind_tint("31")
	local trace = bind_tint("95")
	local trace_dim = bind_tint("2", "35")

	local tint_number = bind_tint("1", "36")
	local tint_string = bind_tint("33")
	local tint_keyword = bind_tint("1", "35")
	local tint_bool = bind_tint("1", "94")

	local function syntax(snippet: string): string
		local formatted = snippet
			:gsub("0?[xXbB]?%d*%.?%d*[eE]?%-?%d+", tint_number)
			:gsub('".-"', tint_string)
			:gsub("'.-'", tint_string)
			:gsub("function", tint_keyword)
			:gsub("end", tint_keyword)
			:gsub("true", tint_bool)
			:gsub("false", tint_bool)
			:gsub("nil", tint_keyword)
			:gsub("%-%-.-\n", dim)

		return formatted
	end

	local LINE_WIDTH = options.line_width or 80

	local DIVIDER = if DISABLE_UNICODE then "=" else "═"
	local MARGIN_LINE = if DISABLE_UNICODE then "|" else "│"
	local ARROW = if DISABLE_UNICODE then " > " else " ▸ "
	local BULLET = if DISABLE_UNICODE then "-" else "•"

	local PASS_ICON = if DISABLE_EMOJI
		then pass_bright(if DISABLE_UNICODE then "[PASS]" else "✔")
		else "✅"
	local FAIL_ICON = if DISABLE_EMOJI
		then fail_bright(if DISABLE_UNICODE then "[FAIL]" else "✖")
		else "❌"

	local function title(text: string)
		local no_ansi = text:gsub("\x1b.-m", "")
		local divider_count = (LINE_WIDTH - string.len(no_ansi) - 2) / 2
		local divider_lhs = dim(string.rep(DIVIDER, math.floor(divider_count)))
		local divider_rhs = dim(string.rep(DIVIDER, math.ceil(divider_count)))

		return `{divider_lhs} {text} {divider_rhs}`
	end

	local FULL_DIVIDER = dim(string.rep(DIVIDER, LINE_WIDTH))

	local function run_fmt(units_results: butler.UnitsRunResult): string
		local lines = {}

		local pretty_results: { FormattedResult } = {}
		local remarkable_pretty_results: { FormattedResult } = {}

		for _, unit_results in units_results.individual_units do
			local individual = unit_results.individual

			for _, test_result in individual do
				-- local test_result = individual[test]
				local status_emojis = if test_result.status == "pass" then PASS_ICON else FAIL_ICON
				local annotations = ""

				local function add_annotation(annotation: string)
					annotations ..= ` - {annotation}`
				end

				hooks.notify("add_annotations", test_result, options, add_annotation)

				local pretty = {
					-- test = test,
					test_results = test_result,
					icon = status_emojis,

					full_label = `{unit_results.label}{ARROW}{test_result.label}`,
					annotations = dim(annotations),
				}

				if #test_result.remarks > 0 then
					table.insert(remarkable_pretty_results, pretty)
				end

				table.insert(pretty_results, pretty)
			end
		end

		-- REMARKS SECTION
		if #remarkable_pretty_results > 0 then
			table.insert(lines, title(`Remarks from {#remarkable_pretty_results} test(s)`) .. "\n")

			for _, pretty in remarkable_pretty_results do
				local results = pretty.test_results

				table.insert(lines, `{pretty.icon} {pretty.full_label}`)
				for _, remark in results.remarks do
					table.insert(lines, `    {BULLET} {remark}`)
				end
				table.insert(lines, "")
			end
		end

		-- ERRORS SECTION
		if units_results.total_tally.fail > 0 then
			table.insert(lines, title(`Errors from {units_results.total_tally.fail} test(s)`))
			table.insert(lines, "")

			for _, pretty in pretty_results do
				local err = pretty.test_results.error

				if err == nil then
					continue
				end

				table.insert(lines, `{pretty.icon} {pretty.full_label}`)
				table.insert(lines, trace(err.message))

				local snippet = err.code

				if snippet ~= nil then
					local line = tostring(err.line or "??")
					local empty_margin = string.rep(" ", #line + 1) .. dim(MARGIN_LINE)

					local formatted_snippet = syntax(snippet):gsub(
						"[^\n\r]+[\n\r]",
						function(line: string)
							return `{line}{empty_margin} `
						end
					)

					table.insert(lines, empty_margin)
					table.insert(lines, `{trace(line)} {dim(MARGIN_LINE)} {formatted_snippet}`)
					table.insert(lines, empty_margin)
				end

				table.insert(lines, trace_dim(err.trace))
				table.insert(lines, "")
			end
		end

		-- STATUS SECTION
		table.insert(lines, title(`Status of {#pretty_results} test(s)`) .. "\n")
		for _, pretty in pretty_results do
			table.insert(lines, `{pretty.icon} {pretty.full_label}{pretty.annotations}`)
		end
		table.insert(lines, "")

		-- TOTAL TALLY SECTION
		local total_tally = units_results.total_tally

		table.insert(
			lines,
			title(`{pass(total_tally.pass)} passed, {fail(total_tally.fail)} failed`)
		)

		-- BONUS ITEMS SECTION
		local line_items = {}

		local function add_line_item(key: string, value: string)
			table.insert(line_items, `{dim(key .. ":")} {value}`)
		end

		hooks.notify("add_line_items", units_results, options, add_line_item)

		if #line_items > 0 then
			table.insert(lines, "")
			for _, item in line_items do
				table.insert(lines, item)
			end
			table.insert(lines, "")
			table.insert(lines, FULL_DIVIDER)
		end

		return table.concat(lines, "\n")
	end

	local pretty_hook: butler_hooks.Hook = {
		after_units = function(_, results: butler.UnitsRunResult)
			print(run_fmt(results))
		end,
	}

	return pretty_hook
end

return butler_pretty
