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
    stunned = false,
		stun_timer = 0,
    dead=false,

    -- knight
    state="idle",
    timer=0,
    dir=1,
    speed=1.2,
    attack_range=40,
    land_timer=0,

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
    pulse_frame=0,
    range_dot_count=16,
		range_angle=0,
		range_rot_speed=0.001
	}

	add(enemies,enemy)
	return enemy
end

function update_enemies()

	for e in all(enemies) do

    if e.dead then
      update_dead_enemy(e)

    elseif e.stunned then
      update_stunned(e)

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
	if e.y > cam_y + 128 then
		del(enemies,e)
	end

end

function update_stunned(e)
  e.stun_timer -= 1
  if e.stun_timer <= 0 then
    e.stunned = false
  end

  e.spr = stun_spr_sets[e.type]
end

function draw_enemies()
  for e in all(enemies) do
    if e.type == "knight" then
      local e_spr = e.dead and 187 or e.spr
      local flip_y = e.dead
      spr(e_spr,e.x,e.y,e.w / 8,e.h / 8, e.flp, flip_y)
    elseif e.type == "wizard" then
      local e_spr = e.dead and 144 or e.spr
      local flip_y = e.dead
      spr(e_spr,e.x,e.y,e.w / 8,e.h / 8, e.flp, flip_y)
    elseif e.type == "cowboy" then
      local e_spr = e.dead and 160 or e.spr
      local flip_y = e.dead
      spr(e_spr,e.x,e.y,e.w / 8,e.h / 8, e.flp, flip_y)

      if not e.dead then
        draw_cowboy_range(e)
      end

      if player.trapped_by and player.trapped_by.c_state == "pulling" then

        local e = player.trapped_by
    
        -- progress bar
        local bar_w = 16
        local fill = flr(bar_w * player.struggle_progress / e.struggle_needed)
        rect(player.x-4, player.y-8, player.x-4+bar_w, player.y-5, 7)
        rectfill(player.x-4, player.y-8, player.x-4+fill, player.y-5,1)
    
        -- next button
        local next_btn = player.struggle_last_btn == "l" and "r" or "l"
    
        -- pulsing, faster with less remaining time
        local urgency = 1 - (e.c_timer / e.pull_duration)  -- 0 -> 1
        local pulse_speed = 4 + urgency
        local pulse = sin(e.pulse_frame/30 * pulse_speed)
    
        -- pulsing color
        local hl_col = pulse > 0 and 1 or 1
        local dim_col = 5  
    
        -- small bounce for next button
        local bounce = pulse > 0 and -1 or 0
    
        if next_btn == "l" then
            print("⬅️", player.x-6, player.y-16+bounce, hl_col)
            print("➡️", player.x+4, player.y-16, dim_col)
        else
            print("⬅️", player.x-6, player.y-16, dim_col)
            print("➡️", player.x+4, player.y-16+bounce, hl_col)
        end
      end
    end
  end
end


function check_enemy_collision()
	if (player.dashing or player.slamming) return 

	for e in all(enemies) do
		if not e.dead then
			if enemy_collide(e) then
				local can_kill = phase.beats[player.spr_set] == e.type
				if can_kill then
					enemy_hit(e)
					player.dy = -3
					player.slam_ready = true
				else
					player_dead()
				end
			elseif player_enemy_overlap(e) then
				player_dead()
			end
		end
	end
end

function enemy_collide(e)
	local overlap_x =
		player.x < e.x + e.w
		and player.x + player.w > e.x

	if not overlap_x or player.dy <= 0 then
		return false
	end

	local prev_bottom = player.prev_y + player.h
	local next_bottom = player.y + player.h

	local crossed_top = prev_bottom <= e.y and next_bottom >= e.y
	local not_past_bottom = prev_bottom <= e.y + e.h/2

	return crossed_top and not_past_bottom
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

function enemy_hit(e)
  e.dead = true
end

function player_dead()
  player.dead = true
end

function cleanup_distant_enemies()
	local despawn_distance = 300 

	for e in all(enemies) do
		if not e.dead and (e.y - player.y) > despawn_distance then
			del(enemies, e)
		end
	end
end