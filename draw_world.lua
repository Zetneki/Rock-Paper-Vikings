function draw_world_wrapped(cam_x, cam_y)
	local first_visible_ty = flr(cam_y/8) - 1
	local last_visible_ty = first_visible_ty + 17

	local first_visible_tx = flr(cam_x/8) - 1
	local last_visible_tx = first_visible_tx + 17   

	for world_ty=first_visible_ty, last_visible_ty do
		local map_row = world_to_map_row(world_ty)
		for tx=first_visible_tx, last_visible_tx do
			local tile = mget(tx, map_row)
			if tile ~= 0 then
				spr(tile, tx*8, world_ty*8)
			end
		end
	end
end