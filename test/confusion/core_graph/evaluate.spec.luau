local butler = require("@butler/butler")
local graph = require("@fusion/core_graph/types")

local evaluate = require("@fusion/core_graph/evaluate")

local check_graph = require("@utility/graph/check_graph")
local generate_tests = require("@utility/graph/generate_tests")
local graph_filters = require("@utility/graph/graph_filters")
local graph_selectors = require("@utility/graph/graph_selectors")
local graph_tests = require("@utility/graph/graph_tests")

return function(configured: butler.Configured)
	local unit = configured.unit

	return unit("evaluate", function(test: butler.Test)
		generate_tests("validity", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for index, node in graph.all_nodes do
					local using_copy = table.clone(node.using)
					node.validity = if index % 2 == 0 then "valid" else "invalid"
					node._evaluate = function()
						node.using = table.clone(using_copy)

						for dependency in node.using do
							evaluate(dependency)
						end

						return index // 2 % 2 == 0
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					evaluate(node)
				end

				return check_graph(graph.all_nodes, graph_tests.validity("valid"))
			end,
		})
		generate_tests("last_change exists", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for index, node in graph.all_nodes do
					local using_copy = table.clone(node.using)
					node.validity = if index % 2 == 0 then "valid" else "invalid"
					node._evaluate = function()
						node.using = table.clone(using_copy)

						for dependency in node.using do
							evaluate(dependency)
						end

						return index // 2 % 2 == 0
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				for _, nodes in graph.all_nodes do
					evaluate(nodes, false)
				end

				return check_graph(graph.all_nodes, graph_tests.change_time_exists)
			end,
		})
		generate_tests("does not evaluate prior dependencies", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for index, node in graph.all_nodes do
					local using_copy = table.clear(node.using)
					node._evaluate(function()
						node.using = table.clone(using_copy)

						for dependency in node.using do
							evaluate(node)
						end

						return true
					end)
				end

				local targets = graph_selectors.no_connections(graph.all_nodes, "users")

				for _, node in graph_selectors.distance(graph.all_nodes, targets, "users", 1) do
					node.validity = "invalid"
				end
			end,
			perform = function(graph: generate_tests.Graph)
				local targets = graph_selectors.no_connections(graph.all_nodes, "users")

				for _, target in targets do
					evaluate(target, false)
				end

				return check_graph(
					graph_selectors.distance(graph.all_nodes, targets, "using", 1),
					graph_tests.validity("valid")
				) or check_graph(
					graph_selectors.distance(graph.all_nodes, targets, "using", 2),
					graph_tests.validity("valid")
				)
			end,
		})
		generate_tests("evaluate during evaluation", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for index, node in graph.all_nodes do
					local using_copy = table.clone(node.using)
					node.validity = "invalid"
					node._evaluate = function()
						node.using = table.clone(using_copy)

						for dependency in node.using do
							evaluate(dependency)
						end

						return true
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				local targets = graph_selectors.no_connections(graph.all_nodes, "users")

				for _, target in targets do
					local dependencies =
						graph_selectors.distance(graph.all_nodes, { target }, "dependency", 1)
					evaluate(target)

					local ok, diagnosis = check_graph(dependencies, graph_tests.validity("valid"))

					if not ok then
						return false, diagnosis
					end
				end

				return true, nil
			end,
		})
		generate_tests("clears dependencies", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					node.validity = "invalid"
					node._old_deps = table.clone(node.using)
					node._evaluate = function()
						return false
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					evaluate(node)

					if next(node.using) ~= nil then
						return false, "Node had dependencies after evaluation"
					end

					for dependency: graph.GraphNode in node._old_deps do
						if dependency.users[node] ~= nil then
							return "Node wasn't cleared from the users set of an old dependency"
						end
					end
				end

				return true, nil
			end,
		})
		generate_tests("preserve user connections", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for index, node in graph.all_nodes do
					local using_copy = table.clone(node.using)
					node.validity = "invalid"
					node._evaluate = function()
						node.using = table.clone(using_copy)

						for dependency in node.using do
							evaluate(dependency)
						end

						return true
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					if next(node.users) == nil then
						continue
					end

					evaluate(node)

					if next(node.users) == nil then
						return false, `{node.id} did not have any users after evaluation`
					end
				end

				return true, nil
			end,
		})
		generate_tests("don't evaluate users", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for index, node in graph.all_nodes do
					local using_clone = table.clone(node.using)
					node.validity = "invalid"
					node._evaluate = function()
						node.using = table.clone(using_clone)

						for dependency in node.using do
							evaluate(dependency)
						end

						return true
					end
				end

				local targets = graph_selectors.no_connections(graph.all_nodes, "using")
				local users = graph_selectors.distance(graph.all_nodes, targets, "users", 1)

				for _, user in users do
					user._evaluate = function()
						error(`{user.id} was evaluated`, 0)
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				local targets = graph_selectors.no_connections(graph.all_nodes, "using")

				for _, target in targets do
					evaluate(target)
				end

				return true, nil
			end,
		})
		generate_tests("valid nodes", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					node.validity = "valid"
					node.last_change = math.huge
					node.last_compute = math.huge -- gotta add this since it wasn't accounted for in base fusion :3
					node._evaluate = function()
						error(`{node.id} was evaluated when it should not have been`, 0)
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					evaluate(node)
				end

				return true, nil
			end,
		})
		generate_tests("force computation", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					node._evaluate = function()
						node.TEST_MARKER = true
						return false
					end
					node.validity = "valid"
					node.last_change = math.huge
					node.last_compute = math.huge
				end
			end,
			perform = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					evaluate(node, true)

					if node.TEST_MARKER == nil then
						return false, `{node.id} was not evaluated.`
					end
				end

				return true, nil
			end,
		})
		generate_tests("invalid nodes", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					node.validity = "invalid"
					node.last_change = 0
					node.last_compute = 0
					node._evaluate = function()
						node.TEST_MARKER = true
						return false
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					if node.validity ~= "invalid" or node.last_change ~= nil then
						continue
					end

					evaluate(node)

					if node.TEST_MARKER == nil then
						return false, `{node.id} did not compute despite being invalid`
					end
				end

				return true, nil
			end,
		})
		generate_tests("dirty nodes", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					node.validity = "dirty"
					node.last_change = 0
					node.last_compute = 0
					node._evaluate = function()
						node.TEST_MARKER = true
						return false
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					if node.validity ~= "dirty" or node.last_change ~= nil then
						continue
					end

					evaluate(node)

					if node.TEST_MARKER == nil then
						return false, `{node.id} did not compute despite being dirty`
					end
				end

				return true, nil
			end,
		})
		generate_tests("busy nodes", {
			filters = { graph_filters.well_formed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					node.validity = "busy"
				end
			end,
			perform = function(graph: generate_tests.Graph)
				local ok = pcall(function()
					for _, node in graph.all_nodes do
						evaluate(node)
					end
				end)

				if ok then
					return false, "Should not have completed without errors"
				end

				return true, nil
			end,
		})
		generate_tests("cyclical graphs", {
			filters = { graph_filters.malformed },
			test = test,
			setup = function(graph: generate_tests.Graph)
				for _, node in graph.all_nodes do
					local using_copy = table.clone(node.using)
					node._evaluate = function()
						node.using = table.clone(using_copy)

						for dependency in node.using do
							evaluate(dependency)
						end

						return true
					end
				end
			end,
			perform = function(graph: generate_tests.Graph)
				local ok = pcall(function()
					for _, node in graph.all_nodes do
						for _, other_node in graph.all_nodes do
							other_node.validity = "invalid"
							other_node.last_change = nil
							other_node.last_compute = nil
						end

						evaluate(node)
					end
				end)

				if ok then
					return false, "Should not have completed without errors"
				end

				return true, nil
			end,
		})
	end)
end
