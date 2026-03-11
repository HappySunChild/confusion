local fmt_repr = require("./fmt_repr")

type Indexable = { [any]: any }
type Callable<A... = ...any, R... = ...any> = (A...) -> R...

export type ExpectTests = {
	to_exist: (ExpectTests) -> ExpectTests,
	to_never_exist: (ExpectTests) -> ExpectTests,

	to_equal: (ExpectTests, x: any) -> ExpectTests,
	to_never_equal: (ExpectTests, x: any) -> ExpectTests,

	to_be_a: (ExpectTests, x_type: string) -> ExpectTests,
	to_never_be_a: (ExpectTests, x_type: string) -> ExpectTests,

	to_be_near: (ExpectTests, x: number, tolerance: number) -> ExpectTests,
	to_never_be_near: (ExpectTests, x: number, tolerance: number) -> ExpectTests,

	to_have_key: (ExpectTests, key: any) -> ExpectTests,
	to_never_have_key: (ExpectTests, key: any) -> ExpectTests,

	to_have_value: (ExpectTests, value: any) -> ExpectTests,
	to_never_have_value: (ExpectTests, value: any) -> ExpectTests,

	to_throw: (ExpectTests, ...unknown) -> ExpectTests,
	to_never_throw: (ExpectTests, ...unknown) -> ExpectTests,

	to_throw_with: (ExpectTests, message: string, ...unknown) -> ExpectTests,
	to_never_throw_with: (ExpectTests, message: string, ...unknown) -> ExpectTests,
}
type Self<T = unknown> = {
	val: T,
} & ExpectTests

local function can_index(x: unknown): boolean
	return type(x) == "table" or type(x) == "userdata"
end

local function fail(value: any, reason: string, ...: any)
	local label = debug.info(2, "n")

	error({
		type = "failed_expectation",
		message = `Expectation not met, because:\n{reason}`,
		trace = debug.traceback(nil, 3),
		line = debug.info(3, "l"),
		code = `expect({fmt_repr(value)}):{label}({table.concat({ ... }, ", ")})`,
	}, 0)
end

local function check(condition: boolean, reason: string)
	if not condition then
		local label = debug.info(2, "n")

		error(`Bad usage of expect():{label}()\nReason: {reason}`, 0)
	end
end

local CLASS = table.freeze({
	to_exist = function(self: Self): Self
		if self.val == nil then
			fail(self.val, `is nil`)
		end

		return self
	end,
	to_never_exist = function(self: Self): Self
		if self.val ~= nil then
			fail(self.val, `isn't nil`)
		end

		return self
	end,

	to_equal = function(self: Self, x: any): Self
		if self.val ~= x then
			fail(self.val, `does not equal {fmt_repr(x)}`, fmt_repr(x))
		end

		return self
	end,
	to_never_equal = function(self: Self, x: any): Self
		if self.val == x then
			fail(self.val, `equals {fmt_repr(x)}`, fmt_repr(x))
		end

		return self
	end,

	to_be_a = function(self: Self, x_type: string): Self
		local a = self.val

		if typeof(a) ~= x_type then
			fail(a, `isn't of type '{x_type}'`, fmt_repr(x_type))
		end

		return self
	end,
	to_never_be_a = function(self: Self, x_type: string): Self
		local a = self.val

		if typeof(a) == x_type then
			fail(a, `is of type '{x_type}'`, fmt_repr(x_type))
		end

		return self
	end,

	to_be_near = function(self: Self<number>, x: number, tolerance: number): Self<number>
		local a = self.val

		check(type(a) == "number", "expect() value must be a number.")
		check(type(x) == "number", "to_be_near() x must be a number.")
		check(type(tolerance) == "number", "to_be_near() tolerance must be a number.")

		if math.abs(a - x) > tolerance then
			fail(a, `|{fmt_repr(self.val)} - {x}| > {tolerance}`, x, tolerance)
		end

		return self
	end,
	to_never_be_near = function(self: Self<number>, x: number, tolerance: number): Self<number>
		local a = self.val

		check(type(a) == "number", "expect() value must be a number")
		check(type(x) == "number", "to_be_near() x must be a number.")
		check(type(tolerance) == "number", "to_be_near() tolerance must be a number.")

		if math.abs(a - x) <= tolerance then
			fail(a, `|{fmt_repr(self.val)} - {x}| <= {tolerance}`, fmt_repr(x), fmt_repr(tolerance))
		end

		return self
	end,

	to_have_key = function(self: Self<Indexable>, key: any): Self<Indexable>
		local a = self.val

		check(can_index(a), "expect() value must be indexable")

		if a[key] == nil then
			fail(a, `value at key [{fmt_repr(key)}] == nil`, fmt_repr(key))
		end

		return self
	end,
	to_never_have_key = function(self: Self<Indexable>, key: any): Self<Indexable>
		local a = self.val

		check(can_index(a), "expect() value must be indexable")

		if a[key] ~= nil then
			fail(a, `value at key [{fmt_repr(key)}] ~= nil`, fmt_repr(key))
		end

		return self
	end,

	to_have_value = function(self: Self<Indexable>, value: any): Self<Indexable>
		local a = self.val

		check(can_index(a), "expect() value must be indexable")

		if table.find(a, value) == nil then
			fail(a, `does not have a {fmt_repr(value)}`, fmt_repr(value))
		end

		return self
	end,
	to_never_have_value = function(self: Self<Indexable>, value: any): Self<Indexable>
		local a = self.val

		check(can_index(a), "expect() value must be indexable")

		if table.find(a, value) ~= nil then
			fail(a, `does have a {fmt_repr(value)}`, fmt_repr(value))
		end

		return self
	end,

	to_throw = function<A...>(self: Self<Callable<A...>>, ...: A...): Self<Callable<A...>>
		local a = self.val

		check(type(a) == "function", "expect() value must be a function")

		local ok = pcall(a, ...)

		if ok then
			fail(a, "did not fail")
		end

		return self
	end,
	to_never_throw = function<A...>(self: Self<Callable<A...>>, ...: A...): Self<Callable<A...>>
		local f = self.val

		check(type(f) == "function", "expect() value must be a function")

		local ok = pcall(f, ...)

		if not ok then
			fail(f, "did fail")
		end

		return self
	end,

	to_throw_with = function<A...>(self: Self<Callable<A...>>, message: string, ...: A...): Self<Callable<A...>>
		local f = self.val
		local ok, err: string = pcall(f, ...)

		if ok then
			fail(f, "did not fail", fmt_repr(message), ...)
		end

		if not err:lower():match(message:lower()) then
			fail(f, `failed with {fmt_repr(err)}`, fmt_repr(message), ...)
		end

		return self
	end,
	to_never_throw_with = function<A...>(self: Self<Callable<A...>>, message: string, ...: A...): Self<Callable<A...>>
		local f = self.val
		local ok, err: string = pcall(f, ...)

		if not ok and err:lower():match(message:lower()) then
			fail(f, `failed with {fmt_repr(err)}`, fmt_repr(message), ...)
		end

		return self
	end,
})
local METATABLE = table.freeze({ __index = CLASS })

local function expect(value: any): ExpectTests
	return setmetatable({ val = value }, METATABLE) :: any
end

return expect
