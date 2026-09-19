function update_phase()
	phase.current -= 1

	if phase.current <= 0 then
		local new_index
		repeat
			new_index = flr(rnd(4)) + 1
		until new_index != phase.char_index

		local old_char = player.spr_set

		phase.char_index = new_index
		phase.current = phase.duration

		player.spr_set = phase.chars[phase.char_index]
		player.spr = p_spr_sets[player.spr_set]
		player.anim = time()

		music(music_patterns[player.spr_set])

		retile_floor(wall_sprites[old_char], wall_sprites[player.spr_set])
		retile_decoration(decoration_sprites[old_char], decoration_sprites[player.spr_set])
	end
end

function retile_floor(old_spr, new_spr)

	local tx_min_clear = flr(map_start/8)
	local tx_max_clear = flr(map_end/8)

	for ty = world_generated_up_to, 64 do
		local map_row = world_to_map_row(ty)
		for tx = tx_min_clear, tx_max_clear do
			local s = mget(tx, map_row)
			if s == old_spr then
				mset(tx, map_row, new_spr)
			elseif s == old_spr+1 then
				mset(tx, map_row, new_spr+1)
			end
		end
	end
end

function retile_decoration(old_spr, new_spr)
	local tx_min_clear = flr(map_start/8)
	local tx_max_clear = flr(map_end/8)

	for ty = world_generated_up_to, 64 do
		local map_row = world_to_map_row(ty)
		for tx = tx_min_clear, tx_max_clear do
			local s = mget(tx, map_row)
			if s == old_spr then
				mset(tx, map_row, new_spr)
			end
		end
	end
end

function draw_background()

	local tile_size = 16
	local parallax_factor = 0.2

	local scroll_x = (cam_x * parallax_factor) % tile_size
	local scroll_y = (cam_y * parallax_factor) % tile_size

	local b = bg_sprites[player.spr_set]

	camera(0,0)

	for y = -tile_size, 128+tile_size, tile_size do
		for x = -tile_size, 128+tile_size, tile_size do
			local screen_x = x - scroll_x
			local screen_y = y - scroll_y

			spr(b[1], screen_x,   screen_y,   1, 1)
			spr(b[2], screen_x+8, screen_y,   1, 1)
			spr(b[3], screen_x,   screen_y+8, 1, 1)
			spr(b[4], screen_x+8, screen_y+8, 1, 1)
		end
	end

	camera(cam_x, cam_y)
end

function draw_phase_bar()

	local dot_size=5
	local gap=3
	local origin_x=cam_x + (phase.dot_count*8/2)
	local origin_y=cam_y + 2

	local col = 1
	local outline_col = 0

	local progress = 1 - (phase.current / phase.duration)
	local exact_pos = progress * phase.dot_count

	for i=0,phase.dot_count-1 do
		local visual_i = phase.dot_count-1-i
		local dx = origin_x + visual_i*(dot_size+gap)
		local dy = origin_y
		local cx = dx + flr(dot_size/2)
		local cy = dy + flr(dot_size/2)
		local arm = flr(dot_size/2)

		if i < flr(exact_pos) then
			rect(cx-1, cy-1, cx+1, cy+1, outline_col)
			pset(cx, cy, col)

		elseif i == flr(exact_pos) then
			local local_t = exact_pos - i

			if local_t < 0.33 then
				rect(dx-1, dy-1, dx+dot_size, dy+dot_size, outline_col)
				rectfill(dx, dy, dx+dot_size-1, dy+dot_size-1, col)
			elseif local_t < 0.66 then
				draw_cross(cx, cy, max(1, flr(arm/2)), outline_col, true)
				draw_cross(cx, cy, max(1, flr(arm/2)), col, false)
			else
				rect(cx-1, cy-1, cx+1, cy+1, outline_col)
				pset(cx, cy, col)
			end

		else
			rect(dx-1, dy-1, dx+dot_size, dy+dot_size, outline_col)
			rectfill(dx, dy, dx+dot_size-1, dy+dot_size-1, col)
		end
	end

end

function draw_cross(cx, cy, arm, col, thick)
	if thick then
		line(cx-arm-1, cy, cx+arm+1, cy, col)
		line(cx-arm-1, cy-1, cx+arm+1, cy-1, col)
		line(cx-arm-1, cy+1, cx+arm+1, cy+1, col)
		line(cx, cy-arm-1, cx, cy+arm+1, col)
		line(cx-1, cy-arm-1, cx-1, cy+arm+1, col)
		line(cx+1, cy-arm-1, cx+1, cy+arm+1, col)
	else
		line(cx-arm, cy, cx+arm, cy, col)
		line(cx, cy-arm, cx, cy+arm, col)
	end
end

function draw_nemesis()
	if (player.spr_set == "viking") return
	local x_x = map_end-9*2-3
	local x_y = cam_y+9

	spr(143, x_x, x_y, 1, 1)
	enemy_outl(x_x, x_y, outline_x, 0)

	local ex, ey = map_end-9-1, cam_y+9

	if player.spr_set == "wizard" then
		anim_disp(187)
		spr(display.spr, ex, ey, 1, 1)
		enemy_outl(ex, ey, outline_knight[display.state], 0)
	elseif player.spr_set == "knight" then
		anim_disp(160)
		spr(display.spr, ex, ey, 1, 1)
		enemy_outl(ex, ey, outline_cowboy[display.state], 0)
	elseif player.spr_set == "cowboy" then
		anim_disp(144)
		spr(display.spr, ex, ey, 1, 1)
		enemy_outl(ex, ey, outline_wizard[display.state], 0)
	end
end

function enemy_outl(x, y, segments, col)
	for _, s in ipairs(segments) do
		line(x+s[1], y+s[2], x+s[3], y+s[4], col)
	end
end

function anim_disp(spr_val)
	if time() - display.anim > 0.3 then
			display.anim = time()
			if display.spr == spr_val then
				display.spr = spr_val+1
				display.state = "s_2"
			else
				display.spr = spr_val
				display.state = "s_1"
			end
		end
end