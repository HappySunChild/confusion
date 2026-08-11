--!native
--!optimize 2

--- Converts a Roblox `Color3` into a `vector`.
const function to_vector(color: Color3): vector
	return vector.create(color.R, color.G, color.B)
end

--- Converts a `vector` into a Roblox `Color3`.
const function from_vector(color_vector: vector): Color3
	return Color3.new(color_vector.x, color_vector.y, color_vector.z)
end

return {
	to_vector = to_vector,
	from_vector = from_vector,
}
