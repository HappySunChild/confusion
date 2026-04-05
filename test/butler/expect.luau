local fmt_repr = require("./fmt_repr")

type Indexable = { [any]: any }
type Callable<A... = ...any, R... = ...any> = (A...) -> R...
type LanguageType =
	"nil"
	| "string"
	| "number"
	| "boolean"
	| "table"
	| "function"
	| "thread"
	| "userdata"
	| "vector"
	| "buffer"
	| string

export type ExpectTests = {
	to_exist: (self: ExpectTests) -> ExpectTests,
	to_never_exist: (self: ExpectTests) -> ExpectTests,

	to_equal: (self: ExpectTests, x: any) -> ExpectTests,
	to_never_equal: (self: ExpectTests, x: any) -> ExpectTests,

	to_be_a: (self: ExpectTests, type: LanguageType) -> ExpectTests,
	to_never_be_a: (self: ExpectTests, type: LanguageType) -> ExpectTests,

	to_be_near: (self: ExpectTests, x: number, tolerance: number) -> ExpectTests,
	to_never_be_near: (self: ExpectTests, x: number, tolerance: number) -> ExpectTests,
	
	to_be_less_than: (self: ExpectTests, x: number) -> ExpectTests,
	to_never_be_less_than: (self: ExpectTests, x: number) -> ExpectTests,
	
	to_be_greater_than: (self: ExpectTests, x: number) -> ExpectTests,
	to_never_be_greater_than: (self: ExpectTests, x: number) -> ExpectTests,

	to_have_key: (self: ExpectTests, key: any) -> ExpectTests,
	to_never_have_key: (self: ExpectTests, key: any) -> ExpectTests,

	to_have_value: (self: ExpectTests, value: any) -> ExpectTests,
	to_never_have_value: (self: ExpectTests, value: any) -> ExpectTests,

	to_throw: (self: ExpectTests, ...unknown) -> ExpectTests,
	to_never_throw: (self: ExpectTests, ...unknown) -> ExpectTests,

	to_throw_with: (self: ExpectTests, message: string, ...unknown) -> ExpectTests,
	to_never_throw_with: (self: ExpectTests, message: string, ...unknown) -> ExpectTests,

	to_evaluate_to: (self: ExpectTests, value: unknown, ...unknown) -> ExpectTests,
	to_never_evaluate_to: (self: ExpectTests, value: unknown, ...unknown) -> ExpectTests,

	to_be_empty: (self: ExpectTests) -> ExpectTests,
	to_never_be_empty: (self: ExpectTests) -> ExpectTests,
}
type Self<T = unknown> = {
	v: T,
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

local function check_usage(condition: boolean, reason: string)
	if not condition then
		local label = debug.info(2, "n")

		error(`Bad usage of expect():{label}()\nReason: {reason}`, 0)
	end
end

local CLASS = table.freeze({
	to_exist = function(self: Self): Self
		if self.v == nil then
			fail(self.v, `is nil`)
		end

		return self
	end,
	to_never_exist = function(self: Self): Self
		if self.v ~= nil then
			fail(self.v, `isn't nil`)
		end

		return self
	end,

	to_equal = function(self: Self, x: any): Self
		if self.v ~= x then
			fail(self.v, `does not equal {fmt_repr(x)}`, fmt_repr(x))
		end

		return self
	end,
	to_never_equal = function(self: Self, x: any): Self
		if self.v == x then
			fail(self.v, `equals {fmt_repr(x)}`, fmt_repr(x))
		end

		return self
	end,

	to_be_a = function(self: Self, x_type: string): Self
		local a = self.v

		if typeof(a) ~= x_type then
			fail(a, `isn't of type '{x_type}'`, fmt_repr(x_type))
		end

		return self
	end,
	to_never_be_a = function(self: Self, x_type: string): Self
		local a = self.v

		if typeof(a) == x_type then
			fail(a, `is of type '{x_type}'`, fmt_repr(x_type))
		end

		return self
	end,

	to_be_near = function(self: Self<number>, x: number, tolerance: number): Self<number>
		local a = self.v

		check_usage(type(a) == "number", "expect() value must be a number.")
		check_usage(type(x) == "number", "to_be_near() x must be a number.")
		check_usage(type(tolerance) == "number", "to_be_near() tolerance must be a number.")

		if math.abs(a - x) > tolerance then
			fail(a, `|{fmt_repr(a)} - {x}| > {tolerance}`, x, tolerance)
		end

		return self
	end,
	to_never_be_near = function(self: Self<number>, x: number, tolerance: number): Self<number>
		local a = self.v

		check_usage(type(a) == "number", "expect() value must be a number")
		check_usage(type(x) == "number", "to_be_near() x must be a number.")
		check_usage(type(tolerance) == "number", "to_be_near() tolerance must be a number.")

		if math.abs(a - x) <= tolerance then
			fail(a, `|{fmt_repr(self.v)} - {x}| <= {tolerance}`, fmt_repr(x), fmt_repr(tolerance))
		end

		return self
	end,
	
	to_be_less_than = function(self: Self<number>, x: number): Self<number>
		local a = self.v
		
		check_usage(type(a) == "number", "expect() value must be a number.")
		check_usage(type(x) == "number", "to_be_less_than() x must be a number.")
		
		if a >= x then
			fail(a, `{fmt_repr(a)} >= {x}`, x)
		end
		
		return self
	end,
	to_never_be_less_than = function(self: Self<number>, x: number): Self<number>
		local a = self.v
		
		check_usage(type(a) == "number", "expect() value must be a number.")
		check_usage(type(x) == "number", "to_never_be_less_than() value must be a number.")
		
		if a < x then
			fail(a, `{fmt_repr(a)} < {x}`, x)
		end
		
		return self
	end,
	
	to_be_greater_than = function(self: Self<number>, x: number): Self<number>
		local a = self.v
		
		check_usage(type(a) == "number", "expect() value must be a number.")
		check_usage(type(x) == "number", "to_be_greater_than() x must be a number.")
		
		if a <= x then
			fail(a, `{fmt_repr(a)} <= {x}`, x)
		end
		
		return self
	end,
	to_never_be_greater_than = function(self: Self<number>, x: number): Self<number>
		local a = self.v
		
		check_usage(type(a) == "number", "expect() value must be a number.")
		check_usage(type(x) == "number", "to_never_be_greater_than() value must be a number.")
		
		if a > x then
			fail(a, `{fmt_repr(a)} > {x}`, x)
		end
		
		return self
	end,

	to_have_key = function(self: Self<Indexable>, key: any): Self<Indexable>
		local a = self.v

		check_usage(can_index(a), "expect() value must be indexable")

		if a[key] == nil then
			fail(a, `value at key [{fmt_repr(key)}] == nil`, fmt_repr(key))
		end

		return self
	end,
	to_never_have_key = function(self: Self<Indexable>, key: any): Self<Indexable>
		local a = self.v

		check_usage(can_index(a), "expect() value must be indexable")

		if a[key] ~= nil then
			fail(a, `value at key [{fmt_repr(key)}] ~= nil`, fmt_repr(key))
		end

		return self
	end,

	to_have_value = function(self: Self<Indexable>, value: any): Self<Indexable>
		local a = self.v

		check_usage(can_index(a), "expect() value must be indexable")

		if table.find(a, value) == nil then
			fail(a, `does not have a {fmt_repr(value)}`, fmt_repr(value))
		end

		return self
	end,
	to_never_have_value = function(self: Self<Indexable>, value: any): Self<Indexable>
		local a = self.v

		check_usage(can_index(a), "expect() value must be indexable")

		if table.find(a, value) ~= nil then
			fail(a, `does have a {fmt_repr(value)}`, fmt_repr(value))
		end

		return self
	end,

	to_throw = function<A...>(self: Self<Callable<A...>>, ...: A...): Self<Callable<A...>>
		local a = self.v

		check_usage(type(a) == "function", "expect() value must be a function")

		local ok = pcall(a, ...)

		if ok then
			fail(a, "did not fail")
		end

		return self
	end,
	to_never_throw = function<A...>(self: Self<Callable<A...>>, ...: A...): Self<Callable<A...>>
		local f = self.v

		check_usage(type(f) == "function", "expect() value must be a function")

		local ok = pcall(f, ...)

		if not ok then
			fail(f, "did fail")
		end

		return self
	end,

	to_throw_with = function<A...>(
		self: Self<Callable<A...>>,
		message: string,
		...: A...
	): Self<Callable<A...>>
		local f = self.v
		local ok, err: string = pcall(f, ...)

		if ok then
			fail(f, "did not fail", fmt_repr(message), ...)
		end

		if not err:lower():match(message:lower()) then
			fail(f, `failed with {fmt_repr(err)}`, fmt_repr(message), ...)
		end

		return self
	end,
	to_never_throw_with = function<A...>(
		self: Self<Callable<A...>>,
		message: string,
		...: A...
	): Self<Callable<A...>>
		local f = self.v
		local ok, err: string = pcall(f, ...)

		if not ok and err:lower():match(message:lower()) then
			fail(f, `failed with {fmt_repr(err)}`, fmt_repr(message), ...)
		end

		return self
	end,

	to_evaluate_to = function<A...>(
		self: Self<Callable<A...>>,
		value: unknown,
		...: A...
	): Self<Callable<A...>>
		local f = self.v
		local result = f(...)

		if result ~= value then
			fail(f, `did not evaluate to {fmt_repr(value)}`, fmt_repr(value), ...)
		end

		return self
	end,
	to_never_evaluate_to = function<A...>(
		self: Self<Callable<A...>>,
		value: unknown,
		...: A...
	): Self<Callable<A...>>
		local f = self.v
		local result = f(...)

		if result == value then
			fail(f, `evaluated to {fmt_repr(value)}`, fmt_repr(value), ...)
		end

		return self
	end,

	to_be_empty = function(self: Self<Indexable>)
		local a = self.v

		if next(a) ~= nil then
			fail(a, "is not empty")
		end

		return self
	end,
	to_never_be_empty = function(self: Self<Indexable>)
		local a = self.v

		if next(a) == nil then
			fail(a, "is empty")
		end

		return self
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function expect(value: any): ExpectTests
	return setmetatable({ v = value }, CLASS_METATABLE) :: any
end

return expect
