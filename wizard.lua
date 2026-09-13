function update_wizard(e)

	local dx = player.x - e.x
	local dy = player.y - e.y
	local dist = sqrt(dx*dx + dy*dy)

	if e.w_state == "orbit" then

		e.orbit_angle += e.orbit_speed
		if e.orbit_angle >= 1 then
			e.orbit_angle -= 1
		end

		e.x = e.origin_x + cos(e.orbit_angle) * e.orbit_radius
		e.y = e.origin_y + sin(e.orbit_angle) * e.orbit_radius

		if dist < e.detect_range then
			e.w_state = "follow"
		end

	elseif e.w_state == "follow" then

		if dist > 0 then
			e.x += (dx/dist) * e.chase_speed
			e.y += (dy/dist) * e.chase_speed
		end

		if dist > e.detect_range then
			e.w_state = "return"
		end

	elseif e.w_state == "return" then
		local ox = e.x - e.origin_x
		local oy = e.y - e.origin_y
		local angle_to_e = atan2(ox, oy)

		local target_x = e.origin_x + cos(angle_to_e) * e.orbit_radius
		local target_y = e.origin_y + sin(angle_to_e) * e.orbit_radius

		local rdx = target_x - e.x
		local rdy = target_y - e.y
		local rdist = sqrt(rdx*rdx + rdy*rdy)

		if rdist < 1 then
			e.orbit_angle = angle_to_e
			e.w_state = "orbit"
		else
			e.x += (rdx/rdist) * e.chase_speed
			e.y += (rdy/rdist) * e.chase_speed
		end

		if dist < e.detect_range then
			e.w_state = "follow"
		end

	end

	e.flp = player.x < e.x

end