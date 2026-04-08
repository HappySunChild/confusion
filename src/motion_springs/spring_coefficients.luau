local function spring_coefficients(
	time: number,
	damping: number,
	speed: number
): (number, number, number, number)
	-- if time or speed is 0, then the spring won't move
	if time == 0 or speed == 0 then
		return 1, 0, 0, 1
	end
	local pos_pos, pos_vel, vel_pos, vel_vel

	if damping > 1 then
		-- overdamped spring

		local alpha = math.sqrt(damping ^ 2 - 1)
		local neg_half_over_alpha_speed = -0.5 / (alpha * speed)
		local z1 = speed * (alpha + damping) * -1
		local z2 = speed * (alpha - damping)
		local exp1 = math.exp(time * z1)
		local exp2 = math.exp(time * z2)

		pos_pos = (exp2 * z1 - exp1 * z2) * neg_half_over_alpha_speed
		pos_vel = (exp1 - exp2) * neg_half_over_alpha_speed / speed
		vel_pos = (exp2 - exp1) * neg_half_over_alpha_speed * speed
		vel_vel = (exp1 * z1 - exp2 * z2) * neg_half_over_alpha_speed
	elseif damping == 1 then
		-- critically damped spring

		local time_speed = time * speed
		local time_speed_neg1 = time_speed * -1
		local exp = math.exp(time_speed_neg1)

		pos_pos = exp * (time_speed + 1)
		pos_vel = exp * time
		vel_pos = exp * (time_speed_neg1 * speed)
		vel_vel = exp * (time_speed_neg1 + 1)
	else
		-- underdamped spring

		local alpha = speed * math.sqrt(1 - damping ^ 2)
		local over_alpha = 1 / alpha
		local exp = math.exp(-1 * time * speed * damping)
		local sin = math.sin(alpha * time)
		local cos = math.cos(alpha * time)
		local exp_sin = exp * sin
		local exp_cos = exp * cos
		local exp_sin_speed_damping_overAlpha = exp_sin * speed * damping * over_alpha

		pos_pos = exp_sin_speed_damping_overAlpha + exp_cos
		pos_vel = exp_sin * over_alpha
		vel_pos = -1
			* (exp_sin * alpha + speed * damping * exp_sin_speed_damping_overAlpha)
		vel_vel = exp_cos - exp_sin_speed_damping_overAlpha
	end

	return pos_pos, pos_vel, vel_pos, vel_vel
end

return spring_coefficients
