--!strict
--!native
--!optimize 2

const Oklab = require("../colour/Oklab")
const oklab_lerp_srgb = Oklab.lerp_srgb

const Roblox = require("../colour/Roblox")
const Color3_to_vector, vector_to_Color3 = Roblox.Color3_to_vector, Roblox.vector_to_Color3

const function lerp_type(a: unknown, b: unknown, alpha: number): unknown
	const data_type = typeof(a)

	if typeof(b) == data_type then
		if data_type == "number" then
			return math.lerp(a :: number, b :: number, alpha)
		elseif data_type == "vector" then
			return vector.lerp(a :: vector, b :: vector, alpha)
		elseif data_type == "CFrame" then
			return (a :: CFrame):Lerp(b :: CFrame, alpha)
		elseif data_type == "Color3" then
			return vector_to_Color3(
				oklab_lerp_srgb(Color3_to_vector(a :: Color3), Color3_to_vector(b :: Color3), alpha, true)
			)
		elseif data_type == "ColorSequence" then
			const from, to = a :: ColorSequence, b :: ColorSequence
			const from_keypoints, to_keypoints = from.Keypoints, to.Keypoints

			if #from_keypoints == #to_keypoints then -- could lead to some confusing behavior
				const interpolated_keypoints = table.create(#from_keypoints) :: { ColorSequenceKeypoint }

				for index = 1, #from_keypoints do
					const from_keypoint, to_keypoint = from_keypoints[index], to_keypoints[index]

					interpolated_keypoints[index] = ColorSequenceKeypoint.new(
						math.lerp(from_keypoint.Time, to_keypoint.Time, alpha),
						vector_to_Color3(
							oklab_lerp_srgb(
								Color3_to_vector(from_keypoint.Value),
								Color3_to_vector(to_keypoint.Value),
								alpha,
								true
							)
						)
					)
				end

				return ColorSequence.new(interpolated_keypoints)
			end
		elseif data_type == "ColorSequenceKeypoint" then
			const from, to = a :: ColorSequenceKeypoint, b :: ColorSequenceKeypoint

			return ColorSequenceKeypoint.new(
				math.lerp(from.Time, to.Time, alpha),
				vector_to_Color3(oklab_lerp_srgb(Color3_to_vector(from.Value), Color3_to_vector(to.Value), alpha, true))
			)
		elseif data_type == "NumberRange" then
			const from, to = a :: NumberRange, b :: NumberRange

			return NumberRange.new(math.lerp(from.Min, to.Min, alpha), math.lerp(from.Max, to.Max, alpha))
		elseif data_type == "NumberSequence" then
			const from, to = a :: NumberSequence, b :: NumberSequence
			const from_keypoints, to_keypoints = from.Keypoints, to.Keypoints

			if #from_keypoints == #to_keypoints then
				const interpolated_keypoints = table.create(#from_keypoints) :: { NumberSequenceKeypoint }

				for index = 1, #from_keypoints do
					const from_keypoint, to_keypoint = from_keypoints[index], to_keypoints[index]

					interpolated_keypoints[index] = NumberSequenceKeypoint.new(
						math.lerp(from_keypoint.Time, to_keypoint.Time, alpha),
						math.lerp(from_keypoint.Value, to_keypoint.Value, alpha),
						math.lerp(from_keypoint.Envelope, to_keypoint.Envelope, alpha)
					)
				end

				return NumberSequence.new(interpolated_keypoints)
			end
		elseif data_type == "NumberSequenceKeypoint" then
			const from, to = a :: NumberSequenceKeypoint, b :: NumberSequenceKeypoint

			return NumberSequenceKeypoint.new(
				math.lerp(from.Time, to.Time, alpha),
				math.lerp(from.Value, to.Value, alpha),
				math.lerp(from.Envelope, to.Envelope, alpha)
			)
		elseif data_type == "Rect" then
			const from, to = a :: Rect, b :: Rect

			return Rect.new(from.Min:Lerp(to.Min, alpha), from.Max:Lerp(to.Max, alpha))
		elseif data_type == "UDim" then
			return UDim.new(
				math.lerp((a :: UDim).Scale, (b :: UDim).Scale, alpha),
				math.lerp((a :: UDim).Offset, (b :: UDim).Offset, alpha)
			)
		elseif data_type == "UDim2" then
			return (a :: UDim2):Lerp(b :: UDim2, alpha)
		elseif data_type == "Vector2" then
			return (a :: Vector2):Lerp(b :: Vector2, alpha)
		elseif data_type == "Vector3" then
			return (a :: Vector3):Lerp(b :: Vector3, alpha)
		end
	end

	return if alpha < 0.5 then a else b
end

return lerp_type
