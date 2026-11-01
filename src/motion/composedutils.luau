--!strict

const function add(a: { number }, b: { number }): { number }
	const result = table.create(#a, 0)

	for index, v_a in a do
		result[index] = v_a + b[index]
	end

	return result
end

const function sub(a: { number }, b: { number }): { number }
	const result = table.create(#a, 0)

	for index, v_a in a do
		result[index] = v_a - b[index]
	end

	return result
end

const function mul(a: { number }, b: { number }): { number }
	const result = table.create(#a, 0)

	for index, v_a in a do
		result[index] = v_a * b[index]
	end

	return result
end

const function div(a: { number }, b: { number }): { number }
	const result = table.create(#a, 0)

	for index, v_a in a do
		result[index] = v_a / b[index]
	end

	return result
end

const function scale(a: { number }, factor: number) end

return {
	add = add,
	sub = sub,
	mul = mul,
	div = div,
	scale = scale,
}
