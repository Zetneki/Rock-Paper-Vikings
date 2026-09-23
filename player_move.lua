function move()
	if player.trapped_by then
		-- cant move while trapped
		player.dx = 0
		player.dy = 0
		return
	end

	player.prev_y = player.y 

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
	end

	-- sets running right state
	if btn(➡️) then
		player.dx += player.acc
		player.running = true
		player.flp = false
	end

	dash()

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
	if btnp(⬆️)
	and player.landed then
		player.dy -= player.boost
		player.landed = false 

	-- double jump
	elseif btnp(⬆️)
	and player.double_jump
	and not (player.on_wall_left or player.on_wall_right) then
		-- making sure to not take double jump when on wall
		player.dy = 0
		player.dy -= player.boost
		player.double_jump = false
	end

	slam()

	-- gravity (falling)
	if player.dy > 0 then
		player.falling = true
		player.jumping = false

		if not player.slamming then
			player.dy = limit_speed(player.dy, player.max_dy)
		else 
			player.dy = limit_speed(player.dy, player.slam_max_dy) 
		end

		local hit, tile_x, tile_y = collide(player, "down", 0)

		if hit then
			player.dy = 0

			if tile_y ~= player.last_platform_ty then
        player.dash_used_on_platform = false
        player.last_platform_ty = tile_y
			end

			if (player.slamming) slam_impact()

			player.landed = true
			player.double_jump = true 
			player.falling = false
			player.slamming=false
			player.y = (tile_y)*8 - player.h
		else
        player.landed = false   
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
		if player.jump_held and not btn(⬆️) then
			player.dy /= 2
		end
	end

	
	player.dashing = player.dash_timer > 0 -- szerintem majd ide kell tenni a coin-t hogy van-e coin and ...

	-- moving left
	if player.dx < 0 then 
		if not player.dashing then
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
		if not player.dashing then
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

		if btnp(⬆️) then
			player.dy = 0
			player.dy -= player.boost/2
			player.dx += player.boost/2
		end

	-- hitting right wall
	elseif player.on_wall_right then
		player.dy /= 2

		if btnp(⬆️) then
			player.dy = 0
			player.dy -= player.boost/2
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

	player.jump_held = btn(⬆️)

	player.x += player.dx
	player.y += player.dy

	local min_x = map_start
	local max_x = map_end - player.w

	if player.x < min_x or player.x > max_x then
		player.x = mid(min_x, player.x, max_x)
		player.dx = 0
	end

end


function limit_speed(num, maximum)
	return mid(-maximum, num, maximum)
end

function dash() 

	-- if dash is ready and right or left button is pressed then dash
	if btnp(➡️)
	and player.dash_ready_r
	and not player.dash_ready_l
	and time()-player.dash_act_time<0.25
	and not player.dash_used_on_platform then
		player.dx += player.dash_speed
		player.dash_timer = 6
		player.dash_used_on_platform = true
	elseif btnp(⬅️)
	and player.dash_ready_l
	and not player.dash_ready_r
	and time()-player.dash_act_time<0.25 
	and not player.dash_used_on_platform then
		player.dx -= player.dash_speed
		player.dash_timer = 6
		player.dash_used_on_platform = true

	-- if right or left button is pressed, sets dash_ready to true
	elseif btnp(➡️) then
		player.dash_ready_l = false
		player.dash_ready_r = true
		player.dash_act_time = time()
	elseif btnp(⬅️) then
		player.dash_ready_r = false
		player.dash_ready_l = true
		player.dash_act_time = time()
	end
end

-- if slam double jump off
function slam()

	if player.slam_ready
	and not player.landed
	and btnp(⬇️)
	and time()-player.slam_act_time<0.25 then
		player.double_jump = false
		player.dy += 14
		player.slamming = true
		player.slam_ready = false
	elseif btnp(⬇️) then
		player.slam_act_time = time()
	end
end

function slam_impact()
	player.slam_flash_timer = 5
	local player_cx = player.x + player.w/2
	local player_cy = player.y + player.h/2
	for e in all(enemies) do
		if not e.dead then
			local e_cx = e.x + e.w/2
			local e_cy = e.y + e.h/2

			local dx = e_cx - player_cx
			local dy = e_cy - player_cy
			if abs(dx) < 24 and abs(dy) < 12 then
				if phase.beats[player.spr_set] == e.type then
					enemy_hit(e)
				else
					e.stunned = true
					e.stun_timer = 30
				end
			end
		end
	end
end

function draw_slam()
	local sprs = {
		192, 208
	}

	local px = player.x
	local py = player.y

	if player.slam_flash_timer and player.slam_flash_timer > 0 then
		player.slam_flash_timer -= 1

		local stage
		if player.slam_flash_timer >= 3 then
			stage = sprs[1]
		elseif player.slam_flash_timer >= 2 then
			stage = sprs[2]
		else 
			return
		end

		spr(stage, px + player.w + 0, py, 1, 1, false)
		spr(stage, px - 8, py, 1, 1, true)
	end
end