local Oklab = require("../colour/Oklab")

local function pack_type(data_type: string, numbers: { number }): unknown
	if data_type == "number" then
		return numbers[1]
	elseif data_type == "vector" then
		return vector.create(numbers[1], numbers[2], numbers[3])
	elseif data_type == "Color3" then
		local ok_result = Oklab.from_oklab_to_srgb(
			vector.create(numbers[1], numbers[2], numbers[3]),
			false
		)

		return Color3.new(ok_result.x, ok_result.y, ok_result.z)
	elseif data_type == "Vector3" then
		return Vector3.new(numbers[1], numbers[2], numbers[3])
	elseif data_type == "Vector2" then
		return Vector3.new(numbers[1], numbers[2])
	elseif data_type == "UDim2" then
		return UDim2.new(
			numbers[1],
			math.round(numbers[2]),
			numbers[3],
			math.round(numbers[4])
		)
	elseif data_type == "UDim" then
		return UDim.new(numbers[1], math.round(numbers[2]))
	elseif data_type == "CFrame" then
		return CFrame.new(numbers[1], numbers[2], numbers[3])
			* CFrame.fromAxisAngle(
				Vector3.new(numbers[4], numbers[5], numbers[6]),
				numbers[7]
			)
	end

	return nil
end

return pack_type
