function move()
	player.dy += gravity
	player.dx *= friction

	if player.dash_timer > 0 then
		player.dash_timer -= 1
	end

	if btn(⬅️) then
		player.dx -= player.acc
		player.running = true
		player.flp = true

		if btnp(🅾️) then
			player.dx -= player.dash_speed
			player.dash_timer = 6 -- ennyi kepkockaig ne limitaljon
		end
	end
	if btn(➡️) then
		player.dx += player.acc
		player.running = true
		player.flp = false

		if btnp(🅾️) then
			player.dx += player.dash_speed
			player.dash_timer = 6
		end
	end

	if player.running
	and not btn(⬅️)
	and not btn(➡️)
	and not player.falling
	and not player.jumping then
		player.running=false
    player.sliding=true
	end

	if btnp(❎)
	and player.landed then
		player.dy -= player.boost
		player.landed = false 
	elseif btnp(❎)
	and player.double_jump
	and not (player.on_wall_left or player.on_wall_right) then
		player.dy = 0
		player.dy -= player.boost
		player.double_jump = false
	end

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
	elseif player.dy < 0 then
		player.jumping = true

		local hit, tile_x, tile_y = collide(player, "up", 0)

		if hit then
			player.dy = 0
			player.y = (tile_y+1)*8
		end
		if player.jump_held and not btn(❎) then
			player.dy /= 2
		end
	end

	local dashing = player.dash_timer > 0 -- szerintem majd ide kell tenni a coin-t hogy van-e coin and ...

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

	if player.on_wall_left then
		player.dy /= 2

		if btnp(❎) then
			player.dy = 0
			player.dy -= player.boost
			player.dx += player.boost/2
		end
	elseif player.on_wall_right then
		player.dy /= 2

		if btnp(❎) then
			player.dy = 0
			player.dy -= player.boost
			player.dx -= player.boost/2
		end
	end

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


function player_animate()
	if player.jumping then
		player.spr=7
	elseif player.falling then
		player.spr=8
	elseif player.sliding then
		player.spr=9
	elseif player.running then
		if time()-player.anim>0.1 then
			player.anim=time()
			player.spr+=1
			if player.spr>6 then
				player.spr=5
			end
		end
	else --player idle
		if time()-player.anim>0.3 then
			player.anim=time()
			player.spr+=1
			if player.spr>4 then
				player.spr=3
			end
		end
	end
end

