function ensure_spawn_platform(px, py, wall_spr_top, wall_spr_fill)
	local spawn_tx = flr(px/8)
	local spawn_ty = flr((py + 8)/8)  

  while fget(mget(spawn_tx, world_to_map_row(spawn_ty)), 0) do
		spawn_ty -= 1
		player.y -= 8
	end

	local ground_ty = spawn_ty + 1
	for dx=-2,2 do
		mset(spawn_tx+dx, world_to_map_row(ground_ty), wall_spr_top)
	end
end