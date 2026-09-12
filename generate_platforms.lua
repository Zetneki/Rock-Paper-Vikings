-- x_min, x_max, y_top, y_bottom: PIXEL koordináták, amiken belül generál
-- wall_spr: a fal sprite indexe a spritesheeten
-- min_gap, max_gap: két platform KÖZÖTTI szabad levegő (pixelben, platform ALJA -> köv. platform TETEJE)
-- min_len, max_len: egy platform hossza (tile-ban)
function generate_platforms(x_min, x_max, y_top, y_bottom, wall_spr, min_gap, max_gap, min_len, max_len, split_chance)

	local tx_min = flr(x_min/8)
	local tx_max = flr(x_max/8)
	local ty_top = flr(y_top/8)
	local ty_bottom = flr(y_bottom/8)

	-- ugrásköltségvetés a player fizikájából (durva becslés, dash/fal-ugrás nélkül)
	local max_jump_height_tiles = (player.boost^2 / (2*gravity)) / 8
	local air_time_frames = (2*player.boost) / gravity
	local max_jump_dist_tiles = (air_time_frames * player.max_dx) / 8

	-- shape most (tx, ty, len, h) alapján rajzol -- a magasságot a hívó adja át
	local shapes = {
		function(tx, ty, len, h)
			local cx, cy = len/2, h/2
			for row=0,h-1 do
				for col=0,len-1 do
					local dx = (col-cx)/(len/2)
					local dy = (row-cy)/(h/2)
					local dist = dx*dx + dy*dy
					if dist <= 1 or (dist <= 1.4 and rnd(1) < 0.4) then
						mset(tx+col, ty+row, wall_spr)
					end
				end
			end
		end,
	}

	local y = y_top
	local prev_bottom_y = nil     -- előző platform ALJA, pixelben
	local prev_tx_center = nil
	local forced_direction = nil 

	while y < y_bottom do

		local gap = min_gap + rnd(max_gap - min_gap)

		if prev_bottom_y then
			y = prev_bottom_y + gap
		else
			y += gap
		end

		if y >= y_bottom then break end

			local ty = flr(y/8)
			local len = min_len + flr(rnd(max_len - min_len + 1))
			local h = 2 + flr(rnd(2))

			local gap_tiles = gap/8
			local budget_left = max(1, max_jump_dist_tiles * (1 - gap_tiles/max_jump_height_tiles))
			local max_h_shift = mid(1, flr(budget_left), 8)

			-- ELŐSZÖR eldöntjük, split lesz-e, hogy tudjuk a tényleges szélességet a tx clamp-hez
			local is_split = rnd(1) < split_chance
			local len1, len2, gap_between, effective_width

			if is_split then
				len1 = min_len + flr(rnd(max_len - min_len + 1))
				len2 = min_len + flr(rnd(max_len - min_len + 1))
				gap_between = 3 + flr(rnd(3))
				effective_width = len1 + gap_between + len2
			else
				effective_width = len
			end

			-- MOST már effective_width-et használjuk a tx kiszámításánál és a clamp-nél
			local tx
			if prev_tx_center then
				local shift = min_h_shift_val(max_h_shift, forced_direction)
				local desired_tx = prev_tx_center + shift - flr(effective_width/2)
				tx = mid(tx_min, desired_tx, tx_max-effective_width)

				if tx ~= desired_tx then
					forced_direction = (desired_tx > tx) and -1 or 1
				else
					forced_direction = nil
				end
			else
				tx = tx_min + flr(rnd(max(1, tx_max - tx_min - effective_width + 1)))
			end

			local actual_bottom_y, actual_center

			if is_split then
				local h1 = 2 + flr(rnd(2))
				local h2 = 2 + flr(rnd(2))

				shapes[1](tx, ty, len1, h1)
				shapes[1](tx+len1+gap_between, ty, len2, h2)

				actual_bottom_y = (ty + max(h1, h2)) * 8
				actual_center = tx + flr(effective_width/2)
			else
				shapes[1](tx, ty, len, h)
				actual_bottom_y = (ty + h) * 8
				actual_center = tx + flr(len/2)
			end

		prev_bottom_y = actual_bottom_y
		prev_tx_center = actual_center
	end
end

-- segédfüggvény: min_shift-től max_h_shift-ig random táv, opcionális kényszerített iránnyal
function min_h_shift_val(max_h_shift, forced_direction)
	local min_shift = 6
	if max_h_shift < min_shift then max_h_shift = min_shift end
	local shift = min_shift + flr(rnd(max_h_shift - min_shift + 1))

	if forced_direction then
		shift = shift * forced_direction
	elseif rnd(1) < 0.5 then
		shift = -shift
	end
	return shift
end