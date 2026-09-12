function move()
	player.dy += gravity
	player.dx *= friction

	-- if currently dashing, limits another dash for dash_timer frames
	if player.dash_timer > 0 then
		player.dash_timer -= 1
	end

	-- sets running left state
	if btn(⬅️) then
		player.dx -= player.acc
		player.running = true
		player.flp = true

		-- dashing left
		if btnp(🅾️) then
			player.dx -= player.dash_speed
			player.dash_timer = 6
		end
	end

	-- sets running right state
	if btn(➡️) then
		player.dx += player.acc
		player.running = true
		player.flp = false

		-- dashing right
		if btnp(🅾️) then
			player.dx += player.dash_speed
			player.dash_timer = 6
		end
	end

	-- sets sliding state
	if player.running
	and not btn(⬅️)
	and not btn(➡️)
	and not player.falling
	and not player.jumping then
		player.running=false
    player.sliding=true
	end

	-- jumping
	if btnp(❎)
	and player.landed then
		player.dy -= player.boost
		player.landed = false 

	-- double jump
	elseif btnp(❎)
	and player.double_jump
	and not (player.on_wall_left or player.on_wall_right) then
		-- making sure to not take double jump when on wall
		player.dy = 0
		player.dy -= player.boost
		player.double_jump = false
	end

	-- gravity (falling)
	if player.dy > 0 then
		player.falling = true
		player.landed = false
		player.jumping = false

		player.dy = limit_speed(player.dy, player.max_dy)

		local hit, tile_x, tile_y = collide(player, "down", 0)

		if hit then
			player.dy = 0
			player.landed = true
			player.double_jump = true  -- mikor coin-hoz kotjuk, akkor tesszuk majd igazza ha van
			player.falling = false
			player.y = (tile_y)*8 - player.h
		end

	--gravity (jumping)
	elseif player.dy < 0 then
		player.jumping = true

		local hit, tile_x, tile_y = collide(player, "up", 0)

		if hit then
			player.dy = 0
			player.y = (tile_y+1)*8
		end
		-- jump smaller if not held on full duration
		if player.jump_held and not btn(❎) then
			player.dy /= 2
		end
	end

	local dashing = player.dash_timer > 0 -- szerintem majd ide kell tenni a coin-t hogy van-e coin and ...


	-- moving left
	if player.dx < 0 then 
		if not dashing then
			player.dx = limit_speed(player.dx, player.max_dx)
		else
			player.dx = limit_speed(player.dx, player.max_dash_dx)
		end

		local hit, tile_x = collide(player, "left", 0)

		if hit then
			player.dx = 0
			player.x = (tile_x+1)*8
		end
	elseif player.dx > 0 then

		-- max speed changes on dash value
		if not dashing then
			player.dx = limit_speed(player.dx, player.max_dx)
		else
			player.dx = limit_speed(player.dx, player.max_dash_dx)
		end

		local hit, tile_x = collide(player, "right", 0)

		if hit then
			player.dx = 0
			player.x = tile_x*8 - player.w
		end
	end

	-- setting state for wall collision
	if player.dx == 0
	and btn(⬅️)
	and player.falling then
		player.on_wall_left = true
	elseif player.dx == 0
	and btn(➡️)
	and player.falling then
		player.on_wall_right = true
	else
		player.on_wall_left = false
		player.on_wall_right = false
	end

	-- hitting left wall
	if player.on_wall_left then
		player.dy /= 2

		if btnp(❎) then
			player.dy = 0
			player.dy -= player.boost
			player.dx += player.boost/2
		end

	-- hitting right wall
	elseif player.on_wall_right then
		player.dy /= 2

		if btnp(❎) then
			player.dy = 0
			player.dy -= player.boost
			player.dx -= player.boost/2
		end
	end

	-- calculating sliding
	if player.sliding then
		if abs(player.dx) < 0.2 then
			player.dx = 0
			player.sliding = false
		end
	end

	player.jump_held = btn(❎)

	player.x += player.dx
	player.y += player.dy

end


function limit_speed(num, maximum)
	return mid(-maximum, num, maximum)
end




