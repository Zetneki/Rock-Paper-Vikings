-- wizard enemy state machine: orbit around spawn -> follow player -> return to orbit
function update_wizard(e)

	local dx = player.x - e.x
	local dy = player.y - e.y
	local dist = sqrt(dx*dx + dy*dy)

	if e.w_state == "orbit" then

		-- circles its spawn point until the player gets close
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

		-- chases the player directly
		if dist > 0 then
			e.x += (dx/dist) * e.chase_speed
			e.y += (dy/dist) * e.chase_speed
		end

		if dist > e.detect_range then
			e.w_state = "return"
		end

	elseif e.w_state == "return" then

		-- heads back to the nearest point on its orbit ring
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

	animate_wizard(e)

end

-- toggles wizard sprite between its two animation frames
function animate_wizard(e)

	local wizard_spr_base=144

	if time()-e.anim > 0.3 then
		e.anim = time()
		e.spr = (e.spr == wizard_spr_base) and wizard_spr_base+1 or wizard_spr_base
	end

end