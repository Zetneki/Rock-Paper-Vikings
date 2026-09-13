function generate_chunk(world_ty_top, world_ty_bottom, x_min, x_max, wall_spr, min_gap, max_gap, min_len, max_len, split_chance)

	local tx_min_clear = flr(x_min/8)
	local tx_max_clear = flr(x_max/8)

	for ty = world_ty_bottom, world_ty_top do
		local map_row = world_to_map_row(ty)
		for tx = tx_min_clear, tx_max_clear do
			mset(tx, map_row, 0)   
		end
	end

	local tx_min = flr(x_min/8)
	local tx_max = flr(x_max/8)
	
	local max_jump_height_tiles = (player.boost^2 / (2*gravity)) / 8
	local air_time_frames = (2*player.boost) / gravity
	local max_jump_dist_tiles = (air_time_frames * player.max_dx) / 8

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

	local ty = world_ty_top
	local prev_bottom_y = nil
	local prev_tx_center = nil
	local forced_direction = nil

	while ty > world_ty_bottom do

		local gap = min_gap + rnd(max_gap - min_gap)
		local gap_tiles = flr(gap/8)

		if prev_bottom_y then
			ty = prev_bottom_y - gap_tiles   
		else
			ty -= gap_tiles
		end

		if ty <= world_ty_bottom then break end

		local len = min_len + flr(rnd(max_len - min_len + 1))
		local h = 2 + flr(rnd(2))

		local budget_left = max(1, max_jump_dist_tiles * (1 - gap_tiles/max_jump_height_tiles))
		local max_h_shift = mid(1, flr(budget_left), 8)

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

		local map_row = world_to_map_row(ty)
		local actual_top_y, actual_center

		if is_split then
			local h1 = 2 + flr(rnd(2))
			local h2 = 2 + flr(rnd(2))

			draw_shape_wrapped(tx, ty, len1, h1, wall_spr, wall_spr+1)
			draw_shape_wrapped(tx+len1+gap_between, ty, len2, h2, wall_spr, wall_spr+1)

			actual_top_y = ty - max(h1, h2) + 1
			actual_center = tx + flr(effective_width/2)
		else
			draw_shape_wrapped(tx, ty, len, h, wall_spr, wall_spr+1)
			actual_top_y = ty - h + 1
			actual_center = tx + flr(len/2)
		end

		prev_bottom_y = actual_top_y 
		prev_tx_center = actual_center
		
	end
end

function draw_shape_wrapped(tx, world_ty, len, h, top_spr, fill_spr)
	local cx, cy = len/2, h/2
	local mask = {}
	for row=0,h-1 do
		mask[row] = {}
		for col=0,len-1 do
			local dx = (col-cx)/(len/2)
			local dy = (row-cy)/(h/2)
			local dist = dx*dx + dy*dy
			mask[row][col] = (dist <= 1 or (dist <= 1.4 and rnd(1) < 0.4))
		end
	end

	for row=0,h-1 do
		for col=0,len-1 do
			if mask[row][col] then
				local above_filled = (row < h-1) and mask[row+1][col]
				local spr_to_use = above_filled and fill_spr or top_spr
				local this_world_ty = world_ty - row
				mset(tx+col, world_to_map_row(this_world_ty), spr_to_use)
			end
		end
	end
end

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