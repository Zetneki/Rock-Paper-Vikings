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
    w_state="orbit",

    -- cowboy
    c_state="idle",       
    pull_range=40,         
    pull_strength=0.3,
    pull_duration=60,
    pause_duration=60,
    c_timer=0,
    struggle_needed=5,
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
    elseif e.type == "wizard" then
      local e_spr = 144
      if (e.dead) e_spr = 145
      spr(e_spr,e.x,e.y,e.w / 8,e.h / 8, e.flp, false)
    elseif e.type == "cowboy" then
      local e_spr = 160
      if (e.dead) e_spr = 161
      spr(e_spr,e.x,e.y,e.w / 8,e.h / 8, e.flp, false)

      -- progress bar
      if player.trapped_by and player.trapped_by.c_state == "pulling" then
        local bar_w = 16
        local fill = flr(bar_w * player.struggle_progress / player.trapped_by.struggle_needed)
        rect(player.x-4, player.y-8, player.x-4+bar_w, player.y-5, 7)
        rectfill(player.x-4, player.y-8, player.x-4+fill, player.y-5, 8)
    end
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