function spawn_enemy(x,y,type)
	local enemy = {
		x=x,
		y=y,
		w=8,
		h=8,
		type=type, -- "knight", "wizard", "cowboy"
		dx=0,
		dy=0,
    max_dx = 4,
    max_dy = 6,
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

function move_enemy(e)
  
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
				e.state = "cooldown"
				e.timer = 20
			end
		else
			e.y += e.dy
		end
	end

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