--!strict
--!native
--!optimize 2

const springs = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_warn = ExternalLogger.log_warn

const Oklab = require("../colour/Oklab")
const srgb_to_oklab = Oklab.srgb_to_oklab

const Roblox = require("../colour/Roblox")
const Color3_to_vector = Roblox.Color3_to_vector

const function unpack_type(value: unknown): { number }
	const data_type = typeof(value)

	if data_type == "number" then
		const v = value :: number
		return { v }
	elseif data_type == "vector" then
		const v = value :: vector
		return { v.x, v.y, v.z }
	elseif data_type == "CFrame" then
		const v = value :: CFrame
		const axis, angle = v:ToAxisAngle()
		return { v.X, v.Y, v.Z, axis.X, axis.Y, axis.Z, angle }
	elseif data_type == "Color3" then
		const lab = srgb_to_oklab(Color3_to_vector(value :: Color3))
		return { lab.x, lab.y, lab.z }
	elseif data_type == "ColorSequenceKeypoint" then
		const v = value :: ColorSequenceKeypoint
		const lab = srgb_to_oklab(Color3_to_vector(v.Value))
		return { v.Time, lab.x, lab.y, lab.z }
	elseif data_type == "NumberRange" then
		const v = value :: NumberRange
		return { v.Min, v.Max }
	elseif data_type == "NumberSequenceKeypoint" then
		const v = value :: NumberSequenceKeypoint
		return { v.Time, v.Value, v.Envelope }
	elseif data_type == "Rect" then
		const v = value :: Rect
		return { v.Min.X, v.Min.Y, v.Max.X, v.Max.Y }
	elseif data_type == "UDim" then
		const v = value :: UDim
		return { v.Scale, v.Offset }
	elseif data_type == "UDim2" then
		const v = value :: UDim2
		return { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset }
	elseif data_type == "Vector2" then
		const v = value :: Vector2
		return { v.X, v.Y }
	elseif data_type == "Vector3" then
		const v = value :: Vector3
		return { v.X, v.Y, v.Z }
	end

	log_warn(springs.unknown_unpacking_datatype, { type = data_type })

	return {}
end

return unpack_type
