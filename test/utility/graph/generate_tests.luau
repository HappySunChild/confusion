--!strict
local butler = require("@butler/butler")

local assemble_graph = require("./assemble_graph")
local format_graph = require("./format_graph")
local standard_graph_shapes = require("./standard_graph_shapes")

export type Graph = assemble_graph.Graph
export type GraphNode = assemble_graph.GraphNode

type Options = {
	filters: { (standard_graph_shapes.GraphShape) -> boolean },
	setup: (assemble_graph.Graph) -> ()?,
	perform: (assemble_graph.Graph) -> (boolean, string?),
	test: butler.Test,
}

local function check_filtered<T>(value: T, filters: { (T) -> boolean }): boolean
	for _, filter in filters do
		if not filter(value) then
			return true
		end
	end

	return false
end

local function generate_tests(label: string, options: Options)
	local test, perform = options.test, options.perform

	for _, shape in standard_graph_shapes do
		if check_filtered(shape, options.filters) then
			continue
		end

		local test_graph = assemble_graph(shape)

		if options.setup then
			options.setup(test_graph)
		end

		test(`{label} / ({shape.label})`, function()
			local pre_state_formatted = format_graph(test_graph)

			local ran_ok, test_ok, diagnosis = pcall(perform, test_graph)

			if not ran_ok then
				error(`An error occured while performing a test: {test_ok}`)
			end

			if not test_ok then
				local output =
					`Shape failed while performing a test.\nDiagnosis: {diagnosis}\n\n  Initial state of graph before test:\n{pre_state_formatted}\n\n  Final state of graph after error:\n{format_graph(
						test_graph
					)}\n`

				error(output, 0)
			end
		end)
	end
end

return generate_tests
