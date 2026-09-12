function spawn_enemy(x,y,type)
	local enemy = {
		x=x,
		y=y,
		w=8,
		h=8,
		type=type, -- "knight", "wizard", "cowboy"
		dx=0,
		dy=0,
		flp=false,
		anim=0,
    dead=false,

    state="idle",
    timer=0,
    dir=1,
    speed=1.2,
    attack_range=40
	}

	add(enemies,enemy)
	return enemy
end

function update_enemies()

	for e in all(enemies) do

    if e.dead then
      update_dead_enemy(e)

    elseif e.type == "knight" then
			update_knight(e)

		elseif e.type == "wizard" then
			update_wizard(e)

		elseif e.type == "cowboy" then
			update_cowboy(e)

		end
	end

  check_enemy_collision()

end

function update_knight(e)

	-- gravity
	e.dy += gravity

	if e.state == "idle" then

		e.dx = 0

		if player_in_knight_range(e) then
			e.state = "prepare"
			e.timer = 10
		end


	elseif e.state == "prepare" then

		e.dx = 0

		-- turn towards player
		if player.x < e.x then
			e.dir = -1
		else
			e.dir = 1
		end

		e.flp = e.dir == -1

		e.timer -= 1

		if e.timer <= 0 then
			e.state = "jump"
			e.dy = -3.5
			e.dx = e.dir * e.speed
		end


	elseif e.state == "jump" then

    e.x += e.dx
    e.y += e.dy
  
    if e.dy > 0 and collide(e,"down",1) then
  
      -- snap to tile
      e.y = flr(e.y / 8) * 8
  
      e.dy = 0
      e.dx = 0
  
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

end

function can_knight_jump(e)

	local check_x

	if e.dir == 1 then
		check_x = e.x + e.w + 2
	else
		check_x = e.x - 2
	end

	local check_y = e.y + e.h + 1

	local tx = flr(check_x / 8)
	local ty = flr(check_y / 8)

	return fget(mget(tx,ty),1)

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

function update_wizard(e)

end

function update_cowboy(e)

end

function update_dead_enemy(e)

	e.dy += gravity
	e.y += e.dy

	-- when under screen
	if e.y > 128 then
		del(enemies,e)
	end

end

function draw_enemies()
  for e in all(enemies) do
    if e.type == "knight" then
      local e_spr = 128
      if (e.dead) e_spr = 129
      spr(e_spr,e.x,e.y,e.w / 8,e.h / 8, e.flp, false)
    end
  end
end

function check_enemy_collision()
	for e in all(enemies) do
		if not e.dead then
			if player_enemy_overlap(e) then
				if player_enemy_collision(e) then
					enemy_hit(e)
				else
					player_dead()
				end
			end
		end
	end
end

function player_enemy_overlap(e)

	local overlap_x =
		player.x < e.x + e.w
		and player.x + player.w > e.x

	local overlap_y =
		player.y < e.y + e.h
		and player.y + player.h > e.y

	return overlap_x and overlap_y
end

function player_enemy_collision(e)

	local overlap_x =
		player.x < e.x + e.w
		and player.x + player.w > e.x

	local hit_top =
		player.y + player.h >= e.y
		and player.y + player.h <= e.y + e.h / 2

	local falling = player.dy > 0

	return overlap_x and hit_top and falling
end

function enemy_hit(e)
  player.dy = -3
  e.dead = true
  e.dy = -1
end

function player_dead()
  player.dead = true
end