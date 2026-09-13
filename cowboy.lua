function update_cowboy(e)

	local center_x = e.x + e.w/2
	local center_y = e.y + e.h/2

	local dx = player.x - center_x
	local dy = player.y - center_y
	local dist = sqrt(dx*dx + dy*dy)

	local margin = 16
	local on_screen = e.y > cam_y - margin and e.y < cam_y + 128 + margin and e.x > cam_x - margin and e.x < cam_x + 128 + margin

	if e.c_state == "idle" then
		if dist < e.pull_range and on_screen then
			e.c_state = "pulling"
			e.c_state = "pulling"
			e.c_timer = e.pull_duration
      e.pulse_frame = 0

			player.pre_trap_x = player.x
			player.pre_trap_y = player.y
		end

	elseif e.c_state == "pulling" then

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

end

function lerp(a, b, t)
	return a + (b-a) * t
end