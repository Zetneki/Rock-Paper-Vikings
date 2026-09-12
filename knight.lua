function update_knight(e)

	e.dy += gravity

	if e.state == "idle" then

		e.dx = 0

		if player_in_knight_range(e) then
			e.state = "prepare"
			e.timer = 10
		end

	elseif e.state == "prepare" then

    e.dx = 0

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
            e.dx = e.dir * e.speed * 1,25
        else
            e.state = "cooldown"
            e.timer = 20
        end
    end

	elseif e.state == "jump" then

		move_enemy(e)

	elseif e.state == "cooldown" then

		e.dx = 0

		e.timer -= 1

		if e.timer <= 0 then
			e.state = "idle"
		end
	end

end


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

	return fget(mget(tx,ty),0)

end

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
