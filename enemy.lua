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

    -- knight
    state="idle",
    timer=0,
    dir=1,
    speed=1.2,
    attack_range=40,

    -- wizard
    origin_x=x,
    origin_y=y,
    orbit_radius=16,
    orbit_speed=0.005,
    orbit_angle=rnd(1),
    detect_range=40, 
    chase_speed=0.75,
    w_state="orbit"
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
    if e.type == "wizard" then
      local e_spr = 144
      if (e.dead) e_spr = 145
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