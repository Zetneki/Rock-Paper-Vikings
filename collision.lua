function collide(obj, aim, flag)
	local x = obj.x
	local y = obj.y
	local w = obj.w
	local h = obj.h

	-- extra tiles based on speed
	local extra_x = max(0, ceil(abs(obj.dx)) - 1)
	local extra_y = max(0, ceil(abs(obj.dy)) - 1)

	if aim=="left" then
		local ty1, ty2 = flr((y)/8), flr((y+h-1)/8)
		local tx_near, tx_far = flr((x-1)/8), flr((x-1-extra_x)/8)

		-- check exta tiles for collision
		for tx = tx_near, tx_far, -1 do
			for ty = ty1, ty2 do
				local map_row = world_to_map_row(ty)
				if fget(mget(tx, map_row), flag) then return true, tx, ty end 
			end
		end

	elseif aim=="right" then
		local ty1, ty2 = flr((y)/8), flr((y+h-1)/8)
		local tx_near, tx_far = flr((x+w)/8), flr((x+w+extra_x)/8)

		-- check exta tiles for collision
		for tx = tx_near, tx_far do
			for ty = ty1, ty2 do
				local map_row = world_to_map_row(ty)
				if fget(mget(tx, map_row), flag) then return true, tx, ty end 
			end
		end
		
	elseif aim=="up" then
		local tx1, tx2 = flr((x)/8), flr((x+w-1)/8)
		local ty_near, ty_far = flr((y-1)/8), flr((y-1-extra_y)/8)

		-- check exta tiles for collision
		for ty = ty_near, ty_far, -1 do
			local map_row = world_to_map_row(ty)
			for tx = tx1, tx2 do
				if fget(mget(tx, map_row), flag) then return true, tx, ty end
			end
		end
		
	elseif aim=="down" then
		local tx1, tx2 = flr((x)/8), flr((x+w-1)/8)
		local ty_near, ty_far = flr((y+h)/8), flr((y+h+extra_y)/8)

		-- check exta tiles for collision
		for ty = ty_near, ty_far do
			local map_row = world_to_map_row(ty)
			for tx = tx1, tx2 do
				if fget(mget(tx, map_row), flag) then return true, tx, ty end
			end
		end
	end
end

function world_to_map_row(world_ty)
	local r = world_ty % 64
	if r < 0 then r += 64 end
	return r
end