--!native
--!optimize 2

--- Converts a Roblox `Color3` into a `vector`.
const function Color3_to_vector(color: Color3): vector
	return vector.create(color.R, color.G, color.B)
end

--- Converts a `vector` into a Roblox `Color3`.
const function vector_to_Color3(color_vector: vector): Color3
	color_vector = vector.clamp(color_vector, vector.zero, vector.one)
	return Color3.new(color_vector.x, color_vector.y, color_vector.z)
end

return {
	Color3_to_vector = Color3_to_vector,
	vector_to_Color3 = vector_to_Color3,
}
