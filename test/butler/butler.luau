local butler_hooks = require("./butler_hooks")
local expect = require("./expect")

export type Error = {
	type: string,
	message: string,

	trace: string,
	line: number?,
	code: string?,
}

export type TestRunResult = {
	label: string,
	status: "pass" | "fail",
	remarks: { string },
	error: Error?,
	[string]: any,
}
export type UnitRunResult = {
	label: string,
	individual: { TestRunResult },
	tally: { pass: number, fail: number },
	[string]: any,
}
export type UnitsRunResult = {
	total_tally: { pass: number, fail: number },
	individual_units: { UnitRunResult },
	[string]: any,
}

export type Options = {
	hooks: { butler_hooks.Hook }?,
}

export type Configured = {
	unit: (label: string, body: UnitBody) -> UnitRunner,
	expect: (any) -> expect.ExpectTests,

	run_units: (units: { UnitRunner }) -> UnitsRunResult,
}

type TestBody = (remark: (string) -> ()) -> ()
export type Test = (label: string, run: TestBody) -> ()

type UnitBody = (test: Test) -> ()
export type TestRunner = (butler_hooks.ButlerHooks) -> TestRunResult
export type UnitRunner = (butler_hooks.ButlerHooks) -> UnitRunResult

local function test_error_handler(err: Error | string): Error
	if typeof(err) == "string" then
		return {
			type = "generic_error",
			message = err,
			trace = debug.traceback(nil, 3),
		}
	end

	return err
end

local function unit(label: string, body: UnitBody): UnitRunner
	local tests = {}

	local function test(label: string, run: TestBody)
		local function run_test(test_hooks: butler_hooks.ButlerHooks)
			test_hooks.notify("before_test", label)

			local remarks = {}

			local function remark(text: string)
				table.insert(remarks, text)
			end

			local ok, err: Error? =
				xpcall(run :: ((string) -> ()) -> any?, test_error_handler, remark)

			local test_run_result: TestRunResult = {
				label = label,
				status = if ok then "pass" else "fail",
				remarks = remarks,
				error = err,
			}

			test_hooks.notify("after_test", label, test_run_result)

			return test_run_result
		end

		table.insert(tests, run_test)
	end

	body(test)

	local function run_unit(unit_hooks: butler_hooks.ButlerHooks)
		unit_hooks.notify("before_unit", label)

		local tally = {
			pass = 0,
			fail = 0,
		}

		local individual: { TestRunResult } = {}

		for index, test in tests do
			local test_result = test(unit_hooks)

			individual[index] = test_result

			if test_result.status == "pass" then
				tally.pass += 1
			else
				tally.fail += 1
			end
		end

		local unit_result: UnitRunResult = {
			label = label,
			individual = individual,
			tally = tally,
		}

		unit_hooks.notify("after_unit", unit_result)

		return unit_result
	end

	return run_unit
end

local function units_runner(units_hooks: butler_hooks.ButlerHooks)
	local function run_units(units: { UnitRunner }): UnitsRunResult
		units_hooks.notify("before_units", units)

		local total_tally = {
			fail = 0,
			pass = 0,
		}
		local individual_units = {}

		for _, unit in units do
			local result = unit(units_hooks)

			total_tally.fail += result.tally.fail
			total_tally.pass += result.tally.pass

			table.insert(individual_units, result)
		end

		local units_result: UnitsRunResult = {
			total_tally = total_tally,
			individual_units = individual_units,
		}

		units_hooks.notify("after_units", units, units_result)

		return units_result
	end

	return run_units
end

local function butler(options: Options): Configured
	local new_butler = {
		unit = unit,
		expect = expect,

		run_units = units_runner(butler_hooks(options.hooks)),
	}

	return new_butler
end

return butler
