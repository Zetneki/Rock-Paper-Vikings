-- knight enemy state machine: idle -> prepare -> jump -> land -> cooldown
function update_knight(e)

	e.dy += gravity

	if e.state == "idle" then

		e.dx = 0

		-- starts winding up once player enters attack range
		if player_in_knight_range(e) then
			e.state = "prepare"
			e.timer = 10
		end

	elseif e.state == "prepare" then

    e.dx = 0

		-- faces the player before jumping
    if player.x < e.x then
        e.dir = -1
    else
        e.dir = 1
    end

    e.flp = e.dir == -1

    e.timer -= 1

    if e.timer <= 0 then
        if can_knight_jump(e) then
            e.state = "jump"
            e.dy = -2
            e.dx = e.dir * e.speed * 1.25
        else
            e.state = "cooldown"
            e.timer = 20
        end
    end

	elseif e.state == "jump" then

		move_knight(e)

	elseif e.state == "land" then

		-- brief pause after landing before it can act again
    e.dx = 0
    e.land_timer -= 1

    if e.land_timer <= 0 then
        e.state = "cooldown"
        e.timer = 20
    end

	elseif e.state == "cooldown" then

		e.dx = 0

		e.timer -= 1

		if e.timer <= 0 then
			e.state = "idle"
		end
	end

	animate_knight(e)

end

-- checks whether there's solid ground ahead in the knight's facing direction
function can_knight_jump(e)

	local check_x

	if e.dir == 1 then
		check_x = e.x + e.w + 5
	else
		check_x = e.x - 5
	end

	local check_y = e.y + e.h + 4

	local tx = flr(check_x / 8)
	local ty = flr(check_y / 8)
	local map_row = world_to_map_row(ty)

	return fget(mget(tx, map_row), 0)
end

-- true if the player is close enough horizontally and vertically to attack
function player_in_knight_range(e)

	local dx = player.x - e.x

	if abs(dx) > e.attack_range then
		return false
	end

	if abs(player.y - e.y) > 16 then
		return false
	end

	return true
end

-- applies knight movement and tile collision, switches to "land" on touchdown
function move_knight(e)
  
  limit_speed(e.dy, e.max_dy)
  limit_speed(e.dx, e.max_dx)

	-- horizontal collision
	if e.dx < 0 then
		local hit, tx = collide(e,"left",0)
		if hit then
			e.x = (tx+1)*8
			e.dx = 0
		else
			e.x += e.dx
		end

	elseif e.dx > 0 then
		local hit, tx = collide(e,"right",0)
		if hit then
			e.x = tx*8 - e.w
			e.dx = 0
		else
			e.x += e.dx
		end
	end


	-- vertical collision
	if e.dy < 0 then
		local hit, tx, ty = collide(e,"up",0)
		if hit then
			e.y = (ty+1)*8
			e.dy = 0
		else
			e.y += e.dy
		end

	elseif e.dy > 0 then
		local hit, tx, ty = collide(e,"down",0)

    if hit then
        e.y = ty*8 - e.h
        e.dy = 0

        if e.state == "jump" then
            e.state = "land"
            e.land_timer = 6 
        end
    else
        e.y += e.dy
    end
	end

end

-- sets the knight's sprite based on its current state
function animate_knight(e)

	local knight_spr_base=187

	if e.state == "idle" then

		if time()-e.anim > 0.3 then
			e.anim = time()
			e.spr = (e.spr == knight_spr_base) and knight_spr_base+1 or knight_spr_base
		end

	elseif e.state == "land" then
		e.spr = knight_spr_base+4

	elseif e.state == "prepare" then
		e.spr = knight_spr_base+2

	elseif e.state == "jump"
	or e.state == "cooldown" then
		e.spr = knight_spr_base+3

	end

end