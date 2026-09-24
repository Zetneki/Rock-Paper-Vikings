-- cowboy enemy state machine: idle -> pulling (traps player) -> release -> pause
function update_cowboy(e)

	local center_x = e.x + e.w/2
	local center_y = e.y + e.h/2

	local dx = player.x - center_x
	local dy = player.y - center_y
	local dist = sqrt(dx*dx + dy*dy)

	local margin = 16
	local on_screen = e.y > cam_y - margin and e.y < cam_y + 128 + margin and e.x > cam_x - margin and e.x < cam_x + 128 + margin

	if e.c_state == "idle" then
		-- starts pulling once player is in range and visible
		if dist < e.pull_range and on_screen then
			e.c_state = "pulling"
			e.c_state = "pulling"
			e.c_timer = e.pull_duration
      e.pulse_frame = 0

			player.pre_trap_x = player.x
			player.pre_trap_y = player.y
		end

	elseif e.c_state == "pulling" then

		-- drags player toward the enemy each frame
		if dist > 1 then
			player.x -= (dx/dist) * e.pull_strength
			player.y -= (dy/dist) * e.pull_strength
		end

		player.trapped_by = e
    e.pulse_frame += 1

		-- struggle input check
		if btnp(⬅️) and player.struggle_last_btn ~= "l" then
			player.struggle_progress += 1
			player.struggle_last_btn = "l"
      player.shake_timer = 4
		elseif btnp(➡️) and player.struggle_last_btn ~= "r" then
			player.struggle_progress += 1
			player.struggle_last_btn = "r"
      player.shake_timer = 4
		end

		player.struggle_progress -= 0.05
		player.struggle_progress = mid(0, player.struggle_progress, e.struggle_needed)

		e.c_timer -= 1

		-- struggle progress decays over time, caps between 0 and needed
		if player.struggle_progress >= e.struggle_needed
		or e.c_timer <= 0 then
			player.struggle_progress = 0
			player.struggle_last_btn = nil

			player.release_start_x = player.x
			player.release_start_y = player.y
			player.release_timer = player.release_duration

			e.c_state = "release"
		end

	elseif e.c_state == "release" then

		-- lerps player back to their pre-trap position
		player.release_timer -= 1

		local t = 1 - (player.release_timer / player.release_duration)
		t = mid(0, t, 1)

		player.x = lerp(player.release_start_x, player.pre_trap_x, t)
		player.y = lerp(player.release_start_y, player.pre_trap_y, t)

		if player.release_timer <= 0 then
			player.x = player.pre_trap_x
			player.y = player.pre_trap_y
			player.dx = 0
			player.dy = 0
			player.trapped_by = nil

			e.c_state = "pause"
			e.c_timer = e.pause_duration
		end

	elseif e.c_state == "pause" then

		-- cooldown before the enemy can pull again
		e.c_timer -= 1

		if e.c_timer <= 0 then
			if dist < e.pull_range and on_screen then
				e.c_state = "pulling"
				e.c_timer = e.pull_duration
        e.pulse_frame = 0

				player.pre_trap_x = player.x
				player.pre_trap_y = player.y
			else
				e.c_state = "idle"
			end
		end

	end

	e.flp = player.x < e.x

	-- slowly rotates the pull-range dot ring
	e.range_angle -= e.range_rot_speed
	if e.range_angle < 0 then
		e.range_angle += 1
	end

	animate_cowboy(e)

end

-- draws a rotating dotted ring showing the cowboy's pull range
function draw_cowboy_range(e)

	if e.c_state == "pulling" then return end

	local center_x = e.x + e.w/2
	local center_y = e.y + e.h/2

	for i=0,e.range_dot_count-1 do
		local angle = e.range_angle + i/e.range_dot_count
		local dot_x = center_x + cos(angle) * e.pull_range
		local dot_y = center_y + sin(angle) * e.pull_range

		pset(dot_x, dot_y, 1)
	end

end

-- toggles cowboy walk-cycle sprite
function animate_cowboy(e)

	local cowboy_spr_base=160

	if time()-e.anim > 0.3 then
		e.anim = time()
		e.spr = (e.spr == cowboy_spr_base) and cowboy_spr_base+1 or cowboy_spr_base
	end

end

-- linear interpolation between a and b at t (0-1)
function lerp(a, b, t)
	return a + (b-a) * t
end