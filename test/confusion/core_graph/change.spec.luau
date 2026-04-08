local butler = require("@butler/butler")

local change = require("@fusion/core_graph/change")

local check_graph = require("@utility/graph/check_graph")
local generate_tests = require("@utility/graph/generate_tests")
local graph_filters = require("@utility/graph/graph_filters")
local graph_selectors = require("@utility/graph/graph_selectors")
local graph_tests = require("@utility/graph/graph_tests")

return function(configured: butler.Configured)
	local unit = configured.unit

	return unit("change", function(test: butler.Test)
		generate_tests("validity", {
			filters = { graph_filters.well_formed },
			test = test,
			perform = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					change(node)
				end

				return check_graph(graph.all_nodes, graph_tests.validity("valid"))
			end,
		})
		generate_tests("last_compute, last_change", {
			filters = { graph_filters.well_formed },
			test = test,
			perform = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					local before_change = node.last_change
					local before_compute = node.last_compute

					change(node)

					if node.last_change == before_change then
						return false, `{node.id} didn't change it's last_change time`
					elseif node.last_compute == before_compute then
						return false, `{node.id} didn't change it's last_compute time`
					end
				end

				return true, nil
			end,
		})
		generate_tests("last_compute, no last_change", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					-- set these to 0 so it doesn't count as a first time computation
					node.last_change = 0
					node.last_compute = 0
					node._evaluate = function()
						return false
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					local before_change = node.last_change
					local before_compute = node.last_compute

					change(node)

					if node.last_change ~= before_change then
						return false, `{node.id} changed it's last_change time`
					elseif node.last_compute == before_compute then
						return false, `{node.id} didn't change it's last_compute time`
					end
				end

				return true, nil
			end,
		})
		generate_tests("invalidates valid users", {
			filters = { graph_filters.well_formed },
			test = test,
			perform = function(graph: generate_tests.Graph)
				local targets = graph_selectors.no_connections(graph.all_nodes, "using")

				for _, node in targets do
					change(node)
				end

				return check_graph(
					graph_selectors.distance(graph.all_nodes, targets, "users", 1),
					graph_tests.validity("invalid")
				)
			end,
		})
		generate_tests("invalidates up to invalid users", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				local targets = graph_selectors.no_connections(graph.all_nodes, "users")
				for _, node in graph_selectors.distance(graph.all_nodes, targets, "users", 1) do
					node.validity = "invalid"
				end
			end,
			perform = function(graph: generate_tests.Graph)
				local targets = graph_selectors.no_connections(graph.all_nodes, "using")

				for _, node in targets do
					change(node)
				end

				return check_graph(
					graph_selectors.distance(graph.all_nodes, targets, "users", 2),
					graph_tests.validity("valid")
				)
			end,
		})
		generate_tests("invalidates valid transitive users", {
			filters = { graph_filters.well_formed },
			test = test,
			perform = function(graph: generate_tests.Graph)
				local roots = graph_selectors.no_connections(graph.all_nodes, "using")

				for _, node in roots do
					change(node)
				end

				return check_graph(
					graph_selectors.distance(graph.all_nodes, roots, "users", 2),
					graph_tests.validity("invalid")
				)
			end,
		})
		generate_tests("stops at already-invalid transitive users", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				local roots = graph_selectors.no_connections(graph.all_nodes, "using")

				for _, node in graph_selectors.distance(graph.all_nodes, roots, "using", 2) do
					node.validity = "invalid"
				end
			end,
			perform = function(graph: generate_tests.Graph)
				local roots = graph_selectors.no_connections(graph.all_nodes, "using")

				for _, node in roots do
					change(node)
				end

				return check_graph(
					graph_selectors.distance(graph.all_nodes, roots, "using", 3),
					graph_tests.validity("valid")
				)
			end,
		})
		generate_tests("does not invalidate any dependencies (using), direct or transitive", {
			filters = { graph_filters.well_formed },
			test = test,
			perform = function(graph: generate_tests.Graph)
				local tips = graph_selectors.no_connections(graph.all_nodes, "users")

				for _, node in tips do
					change(node)
				end

				return check_graph(
					graph_selectors.distance(graph.all_nodes, tips, "using", 2),
					graph_tests.validity("valid")
				) or check_graph(
					graph_selectors.distance(graph.all_nodes, tips, "using", 3),
					graph_tests.validity("valid")
				)
			end,
		})
		generate_tests("revalidates eager objects after all invalidation is complete", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				local tips = graph_selectors.no_connections(graph.all_nodes, "using")
				local do_not_invalidate

				for _, node in tips do
					node.timeliness = "eager"
					node._evaluate = function()
						if do_not_invalidate == nil then
							do_not_invalidate = {}

							for _, node in graph.all_nodes do
								if node.validity ~= "invalid" then
									table.insert(do_not_invalidate, node)
								end
							end

							return
						end

						for _, node in do_not_invalidate do
							if node.validity == "invalid" then
								error("Node became invalid between revalidations", 0)
							end
						end
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				local roots = graph_selectors.no_connections(graph.all_nodes, "users")
				local tips = graph_selectors.no_connections(graph.all_nodes, "using")

				for _, node in roots do
					change(node)
				end

				return check_graph(tips, graph_tests.validity("valid"))
			end,
		})
		generate_tests("revalidates eager objects in order of creation", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph & {
				proper_order: { generate_tests.GraphNode },
				execution_order: { generate_tests.GraphNode },
			})
				graph.proper_order = {}
				graph.execution_order = {}

				local tips = graph_selectors.no_connections(graph.all_nodes, "users")
				local create_at_time = 0
				for _, node in tips do
					create_at_time += 1
					node.timeliness = "eager"
					node.created_at = create_at_time

					table.insert(graph.proper_order, node)

					node._evaluate = function()
						table.insert(graph.execution_order, node)
						return true
					end
				end
			end,
			perform = function(graph: generate_tests.Graph & {
				proper_order: { generate_tests.GraphNode },
				execution_order: { generate_tests.GraphNode },
			})
				local roots = graph_selectors.no_connections(graph.all_nodes, "using")

				for _, node in roots do
					change(node)
				end

				for index, proper_node in graph.proper_order do
					if proper_node ~= graph.execution_order[index] then
						return false, `Object {index} was evaluated out of order. {proper_node.id}`
					end
				end

				return true
			end,
		})
		generate_tests("throws when encountering a busy node", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				local tips = graph_selectors.no_connections(graph.all_nodes, "users")

				for _, node in tips do
					node.validity = "busy"
				end
			end,
			perform = function(graph: generate_tests.Graph)
				local ok = pcall(function()
					for _, node in graph.all_nodes do
						change(node)
					end
				end)

				if ok then
					return false, "Should not have completed without errors"
				end

				return true
			end,
		})
	end)
end
