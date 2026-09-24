pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function update_camera()

  -- horizontal camera follows player, clamped to map bounds
  cam_x = player.x - 64 + (player.w/2)
  if cam_x < map_start then cam_x = map_start end
  if cam_x > map_end - 128 then cam_x = map_end - 128 end

    -- vertical camera only moves up (with player), never back down
    local desired_cam_y = player.y - 64 + (player.h/2)

    if camera_min_y == nil then
      camera_min_y = desired_cam_y   
    end

    if desired_cam_y > camera_min_y then
      cam_y = camera_min_y           
    else
      camera_min_y = desired_cam_y  
      cam_y = desired_cam_y
    end

  -- auto-scroll kicks in past score thresholds, speeding up over time
  if score > 200 then
    auto_scroll_active = true
  end

  if score > 300 and auto_scroll_active then
    auto_scroll_speed = 0.2
  end

  if score > 400 and auto_scroll_active then
    auto_scroll_speed = 0.3
  end

  if score > 500 and auto_scroll_active then
    auto_scroll_speed = 0.4
  end

  -- forces camera upward regardless of player position once active
  if auto_scroll_active then
    camera_min_y -= auto_scroll_speed   
    if camera_min_y < cam_y then
        cam_y = camera_min_y
    end
  end

  camera(cam_x, cam_y)
end

-- tile collision check in one direction, extended by speed to avoid tunneling
function collide(obj, aim, flag)
	local x = obj.x
	local y = obj.y
	local w = obj.w
	local h = obj.h

	-- extra tiles based on speed
	local extra_x = max(0, ceil(abs(obj.dx)) - 1)
	local extra_y = max(0, ceil(abs(obj.dy)) - 1)

	if aim=="left" then
		local ty1, ty2 = flr((y)/8), flr((y+h-1)/8)
		local tx_near, tx_far = flr((x-1)/8), flr((x-1-extra_x)/8)

		-- check exta tiles for collision
		for tx = tx_near, tx_far, -1 do
			for ty = ty1, ty2 do
				local map_row = world_to_map_row(ty)
				if fget(mget(tx, map_row), flag) then return true, tx, ty end 
			end
		end

	elseif aim=="right" then
		local ty1, ty2 = flr((y)/8), flr((y+h-1)/8)
		local tx_near, tx_far = flr((x+w)/8), flr((x+w+extra_x)/8)

		-- check exta tiles for collision
		for tx = tx_near, tx_far do
			for ty = ty1, ty2 do
				local map_row = world_to_map_row(ty)
				if fget(mget(tx, map_row), flag) then return true, tx, ty end 
			end
		end
		
	elseif aim=="up" then
		local tx1, tx2 = flr((x)/8), flr((x+w-1)/8)
		local ty_near, ty_far = flr((y-1)/8), flr((y-1-extra_y)/8)

		-- check exta tiles for collision
		for ty = ty_near, ty_far, -1 do
			local map_row = world_to_map_row(ty)
			for tx = tx1, tx2 do
				if fget(mget(tx, map_row), flag) then return true, tx, ty end
			end
		end
		
	elseif aim=="down" then
		local tx1, tx2 = flr((x)/8), flr((x+w-1)/8)
		local ty_near, ty_far = flr((y+h)/8), flr((y+h+extra_y)/8)

		-- check exta tiles for collision
		for ty = ty_near, ty_far do
			local map_row = world_to_map_row(ty)
			for tx = tx1, tx2 do
				if fget(mget(tx, map_row), flag) then return true, tx, ty end
			end
		end
	end
end

-- wraps a world-space tile row into the map's fixed-height wraparound range
function world_to_map_row(world_ty)
	local r = world_ty % 64
	if r < 0 then r += 64 end
	return r
end

-- applies palette with secondary/display mapping (for background layer)
function change_palette(palette)
  poke(0x5f2e, 1)
  pal(palette, 1)
end

-- cowboy enemy state machine: idle -> pulling (traps player) -> release -> pause
function update_cowboy(e)

	local center_x = e.x + e.w/2
	local center_y = e.y + e.h/2

	local dx = player.x - center_x
	local dy = player.y - center_y
	local dist = sqrt(dx*dx + dy*dy)

	local margin = 16
	local on_screen = e.y > cam_y - margin and e.y < cam_y + 128 + margin and e.x > cam_x - margin and e.x < cam_x + 128 + margin

	if e.c_state == "idle" then
		-- starts pulling once player is in range and visible
		if dist < e.pull_range and on_screen then
			e.c_state = "pulling"
			e.c_state = "pulling"
			e.c_timer = e.pull_duration
      e.pulse_frame = 0

			player.pre_trap_x = player.x
			player.pre_trap_y = player.y
		end

	elseif e.c_state == "pulling" then

		-- drags player toward the enemy each frame
		if dist > 1 then
			player.x -= (dx/dist) * e.pull_strength
			player.y -= (dy/dist) * e.pull_strength
		end

		player.trapped_by = e
    e.pulse_frame += 1

		-- struggle input check
		if btnp(⬅️) and player.struggle_last_btn ~= "l" then
			player.struggle_progress += 1
			player.struggle_last_btn = "l"
      player.shake_timer = 4
		elseif btnp(➡️) and player.struggle_last_btn ~= "r" then
			player.struggle_progress += 1
			player.struggle_last_btn = "r"
      player.shake_timer = 4
		end

		player.struggle_progress -= 0.05
		player.struggle_progress = mid(0, player.struggle_progress, e.struggle_needed)

		e.c_timer -= 1

		-- struggle progress decays over time, caps between 0 and needed
		if player.struggle_progress >= e.struggle_needed
		or e.c_timer <= 0 then
			player.struggle_progress = 0
			player.struggle_last_btn = nil

			player.release_start_x = player.x
			player.release_start_y = player.y
			player.release_timer = player.release_duration

			e.c_state = "release"
		end

	elseif e.c_state == "release" then

		-- lerps player back to their pre-trap position
		player.release_timer -= 1

		local t = 1 - (player.release_timer / player.release_duration)
		t = mid(0, t, 1)

		player.x = lerp(player.release_start_x, player.pre_trap_x, t)
		player.y = lerp(player.release_start_y, player.pre_trap_y, t)

		if player.release_timer <= 0 then
			player.x = player.pre_trap_x
			player.y = player.pre_trap_y
			player.dx = 0
			player.dy = 0
			player.trapped_by = nil

			e.c_state = "pause"
			e.c_timer = e.pause_duration
		end

	elseif e.c_state == "pause" then

		-- cooldown before the enemy can pull again
		e.c_timer -= 1

		if e.c_timer <= 0 then
			if dist < e.pull_range and on_screen then
				e.c_state = "pulling"
				e.c_timer = e.pull_duration
        e.pulse_frame = 0

				player.pre_trap_x = player.x
				player.pre_trap_y = player.y
			else
				e.c_state = "idle"
			end
		end

	end

	e.flp = player.x < e.x

	-- slowly rotates the pull-range dot ring
	e.range_angle -= e.range_rot_speed
	if e.range_angle < 0 then
		e.range_angle += 1
	end

	animate_cowboy(e)

end

-- draws a rotating dotted ring showing the cowboy's pull range
function draw_cowboy_range(e)

	if e.c_state == "pulling" then return end

	local center_x = e.x + e.w/2
	local center_y = e.y + e.h/2

	for i=0,e.range_dot_count-1 do
		local angle = e.range_angle + i/e.range_dot_count
		local dot_x = center_x + cos(angle) * e.pull_range
		local dot_y = center_y + sin(angle) * e.pull_range

		pset(dot_x, dot_y, 1)
	end

end

-- toggles cowboy walk-cycle sprite
function animate_cowboy(e)

	local cowboy_spr_base=160

	if time()-e.anim > 0.3 then
		e.anim = time()
		e.spr = (e.spr == cowboy_spr_base) and cowboy_spr_base+1 or cowboy_spr_base
	end

end

-- linear interpolation between a and b at t (0-1)
function lerp(a, b, t)
	return a + (b-a) * t
end

-- draws visible map tiles, mapping wrapped world-y back to screen position
function draw_world_wrapped(cam_x, cam_y)
	local first_visible_ty = flr(cam_y/8) - 1
	local last_visible_ty = first_visible_ty + 17

	local first_visible_tx = flr(cam_x/8) - 1
	local last_visible_tx = first_visible_tx + 17   

	for world_ty=first_visible_ty, last_visible_ty do
		local map_row = world_to_map_row(world_ty)
		for tx=first_visible_tx, last_visible_tx do
			local tile = mget(tx, map_row)
			if tile ~= 0 then
				spr(tile, tx*8, world_ty*8)
			end
		end
	end
end

-- creates an enemy of the given type at x,y with all per-type state fields
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

-- routes each enemy to its state update based on dead/stunned/type
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

-- lets a dead enemy fall off-screen, then removes it
function update_dead_enemy(e)

	e.dy += gravity
	e.y += e.dy

	-- when under screen
	if e.y > cam_y + 128 then
		del(enemies,e)
	end

end

-- counts down stun duration and shows the stunned sprite
function update_stunned(e)
  e.stun_timer -= 1
  if e.stun_timer <= 0 then
    e.stunned = false
  end

  e.spr = stun_spr_sets[e.type]
end

-- draws every enemy plus the cowboy struggle qte overlay when trapped
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

-- normal stomp/overlap check, skipped while dashing or slamming
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

-- swept stomp check: was above enemy last frame, now inside it, falling
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

-- simple aabb overlap between player and enemy
function player_enemy_overlap(e)

	local overlap_x =
		player.x < e.x + e.w
		and player.x + player.w > e.x

	local overlap_y =
		player.y < e.y + e.h
		and player.y + player.h > e.y

	return overlap_x and overlap_y
end

-- kills enemy and awards the current popup score amount
function enemy_hit(e)
  e.dead = true
  score += score_popup
  score_popup_timer = 30
end

function player_dead()
  player.dead = true
end

-- removes enemies that have fallen far behind the player
function cleanup_distant_enemies()
	local despawn_distance = 300 

	for e in all(enemies) do
		if not e.dead and (e.y - player.y) > despawn_distance then
			del(enemies, e)
		end
	end
end

-- resets all game state and generates the starting chunk for a new run
function init_game()
  poke(0x5f2e, 1) -- allows hidden colors
	poke(0x5f5c, 255) -- button press only activates once

	gravity = 0.3
	friction = 0.85

  player = {	
		spr_set='viking',
		spr=p_spr_sets['viking'],
		flp=false,
    x = 140,
    y = 490,
		w=8,
		h=8,
    dy=0,
		dx=0,
		max_dx=4,
		max_dy=6,
		prev_y=490,
		acc=0.4,
		boost=4,
		anim=0,
		running=false,
		jumping=false,
		falling=false,
		sliding=false,
		landed=false,
    dash_used_on_platform=false,
		last_platform_ty=nil,
		dash_act_time=0,
		dash_ready_l=false,
		dash_ready_r=false,
		dashing=false,
		dash_timer=0,
		max_dash_dx = 6,
		dash_speed=6,
		slam_flash_timer=0,
		slam_act_time=0,
		slam_ready=true,
		slamming=false,
		slam_max_dy=14,
		jump_held=false,
		double_jump=true,
		on_wall_left=false,
		on_wall_right=false,
		dead=false,

		-- cowboy quick time event
		struggle_progress=0,
		struggle_last_btn=nil, 
		trapped_by=nil,
		pre_trap_x=0,
		pre_trap_y=0,
		release_timer=0,
		release_duration=10,
		release_start_x=0,
		release_start_y=0,
		shake_timer=0
  }

	music_patterns = {
		viking=0,
		cowboy=4,
		knight=8,
		wizard=12
	}

	wall_sprites = {
		viking=65,
		cowboy=67,
		knight=65,
		wizard=69
	}

	bg_sprites = {
		viking = {71, 72, 87, 88},
		wizard = {75, 76, 91, 92},
		knight = {73, 74, 89, 90},
		cowboy = {73, 74, 89, 90}
	}

	decoration_sprites = {
		viking = 114,
		cowboy = 116,
		knight = 114,
		wizard = 118,
	}

	stun_spr_sets = {
		knight = 186,   
		wizard = 146,
		cowboy = 162
	}

	display = {
		anim=0,
		spr=0,
		state="s_1",
	}

	outline_x = {
		{-1,-1, 2,-1}, {2,0, 5,0}, {4,1, 4,1}, {5,-1, 8,-1},
		{8,0, 8,2}, {7,2, 7,5}, {6,3, 6,3}, {8,5, 8,8},
		{6,8, 8,8}, {6,7, 5,7}, {2,6, 5,6}, {3,5, 4,5},
		{4,4, 4,4}, {2,7, 2,8}, {-1,8, 1,8}, {-1,7, -1,5},
		{0,4, 0,5}, {1,2, 1,4}, {2,3, 2,3}, {-1,2, 0,2},
		{-1,0, -1,1}
	}

	outline_wizard = {
		s_1 = {
			{0,0, 0,1}, {1,-1, 1,0}, {2,-1, 6,-1}, {6,0, 7,0}, 
			{7,1, 8,1}, {8,2, 8,8}, {-1,8, 7,8}, {-1,1, -1,7}, 
			{0,3, 0,3}, {0,6, 0,6}, {7,3, 7,3}, {7,6, 7,6}, 
			{3,7, 4,7}
		},
		s_2 = {
			{1,0, 1,1}, {2,-1, 2,0}, {3,-1, 5,-1}, {5,0, 6,0}, 
			{6,1, 7,1}, {7,2, 7,8}, {0,8, 6,8}, {0,1, 0,7}, 
			{1,6, 1,6}, {6,6, 6,6}
		}
	}

	outline_knight = {
		s_1 = {
			{0,1, 0,3}, {1,0, 1,1}, {2,0, 6,0}, {6,1, 7,1}, 
			{7,2, 7,3}, {8,3, 8,8}, {7,6, 7,6}, {-1,8, 7,8}, 
			{-1,3, -1,7}, {0,6, 0,6}, {3,7, 4,7}
		},
		s_2 = {
			{0,1, 0,8}, {1,0, 1,1}, {2,0, 2,-1}, {3,-1, 5,-1}, 
			{5,0, 6,0}, {6,1, 7,1}, {7,2, 7,8}, {1,6, 1,6}, 
			{6,6, 6,6}, {1,8, 6,8}
		}
	}

	outline_cowboy = {
		s_1 = {
			{0,0, 8,0}, {8,1, 8,8}, {-1,8, 7,8}, {-1,0, -1,7},
			{0,3, 0,3}, {0,6, 0,6}, {7,3, 7,3}, {7,6, 7,6}, 
			{3,7, 4,7}, {1,1, 1,1}, {6,1, 6,1}
		},
		s_2 = {
			{0,0, 0,1}, {1,0, 2,0}, {2,-1, 5,-1}, {5,0, 7,0}, 
			{7,1, 8,1}, {8,2, 8,3}, {7,3, 7,8}, {0,8, 6,8}, 
			{0,3, 0,7}, {-1,1, -1,3}, {1,6, 1,6}, {6,6, 6,6}
		}
	}

	music(music_patterns[player.spr_set])

	enemies = {}

	-- charater type timer
	phase = {
		duration=445,     -- 600 frame = 20mp at 30fps
		current=445,
		char_index=1,    
		dot_count=8, 
	
		-- char_index
		chars = {
			[1]="viking",
			[2]="wizard",
			[3]="knight",
			[4]="cowboy"
		},

		-- what class beats another (rock, paper scissors)
		beats = {
			viking=nil,
			knight="cowboy",
			cowboy="wizard",
			wizard="knight"
		},
		-- depletion queue for timer rectangles
		-- center always stays
		cell_order = {
			{-1,-1},{0,-1},{1,-1},
			{1,0},{1,1},{0,1},
			{-1,1},{-1,0}
		}
	}

	palettes={
		base = {
			[0]=-14,2,3,-7,4,-2,-1,15,-15,
			1,-3,-13,13,-10,5,-11
		},
		new = {[0]=0,8,3,-7,4,9,-1,15,-15,
		1,-5,-13,13,-10,5,-11
	}}

	current_palette = palettes.new

	cam_x, cam_y = 0, 0
	map_start = 0
	map_end = 128 

	map_start=128
	map_end=256

	camera_min_y = nil

	score=0
	last_height=player.y

	auto_scroll_active = false
	auto_scroll_speed = 0.1 

	chunk_height = 30     
	trigger_buffer = 20    

	-- tracks platforms passed since last enemy spawn, for the min-gap gate
	platforms_since_spawn = 0

	generate_chunk(64, 0, map_start, map_end, wall_sprites[player.spr_set], 18, 24, 3, 6, 0.4, true)
	world_generated_up_to = 0

  death_timer = nil

	-- score awarded per kill, shown as a temporary popup next to the total
	score_popup = 50
	score_popup_timer = 0
end

-- main per-frame update: movement, camera, enemies, world streaming, death
function update_game()
	if not player.dead then
		update_phase()
		move()
		update_camera()
		player_animate(player.spr_set)
		update_enemies()

		cleanup_distant_enemies()

		-- awards climbing score every 50px of new height gained
		if last_height-player.y > 50 then
			last_height = player.y
			score+=10
		end

		local player_ty = flr(player.y/8)

		-- streams in a new chunk once player nears the generated edge
		if player_ty < world_generated_up_to + trigger_buffer then
			local new_top = world_generated_up_to - chunk_height
			generate_chunk(world_generated_up_to, new_top, map_start, map_end, wall_sprites[player.spr_set], 18, 24, 3, 6, 0.4)
			world_generated_up_to = new_top
		end

		check_offscreen_death()
	else
		-- death sequence: small upward pop, then fall, then game over after a delay
    if death_timer == nil then
			death_timer = 30
			player.dy = -3  
    end

    player.dy += gravity     
    player.y += player.dy     

    death_timer -= 1

    if death_timer <= 0 then
			-- only enemy mode runs are eligible for the high score
			if is_enemy and score > high_score then
				high_score = score
				high_score_name = player_name
				save_scoreboard(player_name, score)
			end

			game_state = "gameover"
			death_timer = nil
    end
		music(-1, 100)
	end
end

-- draws the full playing screen: world, player, enemies, hud
function draw_game()
	cls()
	change_palette(current_palette)
	draw_background()
  draw_world_wrapped(cam_x, cam_y) 

	--shakes player when struggling
	local shake_x = 0
	if player.shake_timer and player.shake_timer > 0 then
			shake_x = (rnd(2)-1)
			player.shake_timer -= 1
	end
	spr(player.spr, player.x+shake_x, player.y, player.w/8, player.h/8, player.flp)

	draw_slam()

	draw_enemies()

	draw_phase_bar()

	-- shows the score, plus a temporary "+bonus" while the kill popup is active
	if score_popup_timer > 0 then
		print("\^o0ffscore: " .. score .. " (+" .. score_popup .. ")", cam_x+2, cam_y+10)
		score_popup_timer -= 1
	else
		print("\^o0ffscore: " .. score, cam_x+2, cam_y+10)
	end
	
	if (is_enemy) draw_nemesis()

	if (is_enemy) draw_skills()
end

-- kills the player once they've fully left the camera view
function check_offscreen_death()
	local completely_offscreen =
			player.x + player.w < cam_x or
			player.x > cam_x + 128 or
			player.y + player.h < cam_y or
			player.y > cam_y + 128

	if completely_offscreen then
			player.dead = true
	end
end

function update_gameover()
  if btnp(❎) then
		game_state = "menu"
	end
end

-- shows final score; no-enemy runs get an extra "not ranked" notice
function draw_gameover()
  camera(0, 0)
  cls(0)

	if not is_enemy then
		print("game over", 45, 40, 8)
		print("score: "..score, 45, 50, 7)

		print("no enemy mode - not ranked", 15, 70, 7) 
		print("score is not saved", 30, 80, 7)

		print("press ❎ to continue", 25, 100, 6)
		return
	end

	print("game over", 45, 50, 8)
	print("score: "..score, 45, 60, 7)

	print("press ❎ to continue", 25, 80, 6)
end

-- procedurally carves a vertical strip of the map between two world-y rows,
-- laying down platforms (occasionally split in two) that stay jumpable
function generate_chunk(world_ty_top, world_ty_bottom, x_min, x_max, wall_spr, min_gap, max_gap, min_len, max_len, split_chance, is_initial_spawn)

	-- clears the strip before regenerating it
	local tx_min_clear = flr(x_min/8)
	local tx_max_clear = flr(x_max/8)

	for ty = world_ty_bottom, world_ty_top do
		local map_row = world_to_map_row(ty)
		for tx = tx_min_clear, tx_max_clear do
			mset(tx, map_row, 0)   
		end
	end

	local tx_min = flr(x_min/8)
	local tx_max = flr(x_max/8)
	
	-- caps how far a platform can shift sideways, based on max jump range
	local max_jump_height_tiles = (player.boost^2 / (2*gravity)) / 8
	local air_time_frames = (2*player.boost) / gravity
	local max_jump_dist_tiles = (air_time_frames * player.max_dx) / 8

	local ty = world_ty_top
	local prev_bottom_y = nil
	local prev_tx_center = nil
	local forced_direction = nil

	local generated_platforms = {}

	while ty > world_ty_bottom do

		-- picks a random vertical gap to the next platform
		local gap = min_gap + rnd(max_gap - min_gap)
		local gap_tiles = flr(gap/8)

		if prev_bottom_y then
			ty = prev_bottom_y - gap_tiles   
		else
			ty -= gap_tiles
		end

		if ty <= world_ty_bottom then break end

		local len = min_len + flr(rnd(max_len - min_len + 1))
		local h = 2 + flr(rnd(2))

		-- remaining horizontal shift budget, shrinking as the gap grows
		local budget_left = max(1, max_jump_dist_tiles * (1 - gap_tiles/max_jump_height_tiles))
		local max_h_shift = mid(1, flr(budget_left), 8)

		-- occasionally splits this platform into two separate pieces
		local is_split = rnd(1) < split_chance
		local len1, len2, gap_between, effective_width

		if is_split then
			len1 = min_len + flr(rnd(max_len - min_len + 1))
			len2 = min_len + flr(rnd(max_len - min_len + 1))
			gap_between = 3 + flr(rnd(3))
			effective_width = len1 + gap_between + len2
		else
			effective_width = len
		end

		-- picks the platform's x position, shifted from the previous one
		local tx
		if prev_tx_center then
			local shift = min_h_shift_val(max_h_shift, forced_direction)
			local desired_tx = prev_tx_center + shift - flr(effective_width/2)
			tx = mid(tx_min, desired_tx, tx_max-effective_width)

			if tx ~= desired_tx then
				forced_direction = (desired_tx > tx) and -1 or 1
			else
				forced_direction = nil
			end
		else
			tx = tx_min + flr(rnd(max(1, tx_max - tx_min - effective_width + 1)))
		end

		local map_row = world_to_map_row(ty)
		local actual_top_y, actual_center

		if is_split then
			local h1 = 2 + flr(rnd(2))
			local h2 = 2 + flr(rnd(2))

			draw_shape_wrapped(tx, ty, len1, h1, wall_spr, wall_spr+1)
			draw_shape_wrapped(tx+len1+gap_between, ty, len2, h2, wall_spr, wall_spr+1)

			add(generated_platforms, {tx=tx, ty=ty-h1+1, len=len1})
			add(generated_platforms, {tx=tx+len1+gap_between, ty=ty-h2+1, len=len2})

			actual_top_y = ty - max(h1, h2) + 1
			actual_center = tx + flr(effective_width/2)
		else
			draw_shape_wrapped(tx, ty, len, h, wall_spr, wall_spr+1)
			actual_top_y = ty - h + 1
			actual_center = tx + flr(len/2)
		end

		prev_bottom_y = actual_top_y 
		prev_tx_center = actual_center
	end

	-- first call also places the player; enemy spawns are enemy-mode only
	if is_initial_spawn then
		spawn_player(generated_platforms)
		if (is_enemy) spawn_enemies_on_platforms(generated_platforms, 3)   
	else
		if (is_enemy) spawn_enemies_on_platforms(generated_platforms, 0)   
	end

	spawn_decorations_on_platforms(generated_platforms)
end

-- stamps a rounded platform shape into the map, picking top vs fill sprite per tile
function draw_shape_wrapped(tx, world_ty, len, h, top_spr, fill_spr)
	local cx, cy = len/2, h/2
	local mask = {}
	for row=0,h-1 do
		mask[row] = {}
		for col=0,len-1 do
			local dx = (col-cx)/(len/2)
			local dy = (row-cy)/(h/2)
			local dist = dx*dx + dy*dy
			mask[row][col] = (dist <= 1 or (dist <= 1.4 and rnd(1) < 0.4))
		end
	end

	for row=0,h-1 do
		for col=0,len-1 do
			if mask[row][col] then
				local above_filled = (row < h-1) and mask[row+1][col]
				local spr_to_use = above_filled and fill_spr or top_spr
				local this_world_ty = world_ty - row
				mset(tx+col, world_to_map_row(this_world_ty), spr_to_use)
			end
		end
	end
end

-- random sideways shift for the next platform, respecting the jump budget
function min_h_shift_val(max_h_shift, forced_direction)
	local min_shift = 6
	if max_h_shift < min_shift then max_h_shift = min_shift end
	local shift = min_shift + flr(rnd(max_h_shift - min_shift + 1))

	if forced_direction then
		shift = shift * forced_direction
	elseif rnd(1) < 0.5 then
		shift = -shift
	end
	return shift
end

enemy_types = {"knight", "wizard", "cowboy"}

-- rolls an enemy spawn per eligible platform, gated by a min-gap and score-scaled chance
function spawn_enemies_on_platforms(platforms, skip_first_n)
	skip_first_n = skip_first_n or 0

	local min_gap = max(1, 3 - flr(score/400))
	local spawn_chance = min(0.7, 0.45 + score/1500)

	for i, p in ipairs(platforms) do
		if i > skip_first_n then   

			platforms_since_spawn += 1
			
			if p.len >= 3 
			and platforms_since_spawn >= min_gap
			and rnd(1) < spawn_chance then
				local margin = 1
				local safe_len = max(1, p.len - margin*2)
				local offset = margin + flr(rnd(safe_len))

				local enemy_tx = p.tx + offset
				local enemy_x = enemy_tx * 8
				local enemy_y = p.ty * 8 - 8

				spawn_enemy(enemy_x, enemy_y, enemy_types[1 + flr(rnd(#enemy_types))])
				platforms_since_spawn = 0
			end
		end
	end
end

-- places the player on the first generated platform of the initial chunk
function spawn_player(platforms)
	if #platforms > 0 then
		local spawn_platform = platforms[1]
		local spawn_tx = spawn_platform.tx + flr(spawn_platform.len/2)  
		player.x = spawn_tx * 8
		player.y = spawn_platform.ty * 8 - player.h   
		last_height = player.y
	end
end

-- scatters decoration sprites just above some platforms
function spawn_decorations_on_platforms(platforms)
	for i, p in ipairs(platforms) do

		local deco_chance = 0.5
		if p.len >= 2 and rnd(1) < deco_chance then

			local deco_tx = p.tx + flr(rnd(p.len))
			local map_row = world_to_map_row(p.ty)

			local found = false

			for check_row = map_row, map_row + 3 do
				if fget(mget(deco_tx, check_row), 0) then
					mset(deco_tx, check_row - 1, decoration_sprites[player.spr_set])
					found = true
					break
				end
			end
		end
	end
end

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

-- entry point: loads saved data, prompts for a name if none is set yet
function _init()
	cartdata("rock_paper_wizards_v1")

	is_enemy = false
	-- reset high score
 -- dset(0,0) for i=1,16 do dset(i,0) end

	game_state = "menu"
	load_scoreboard()

	if player_name == "---" then
		init_name_entry()
		game_state = "enter_name"
	else
		init_menu()
		game_state = "menu"
	end
end

-- routes the frame update to whichever screen is active
function _update()
	if game_state == "menu" then
		update_menu()
	elseif game_state == "playing" then
		update_game()
	elseif game_state == "howto" then
		update_howto()
	elseif game_state == "gameover" then
		update_gameover()
	elseif game_state == "enter_name" then
		update_name_entry()
	elseif game_state == "scoreboard" then
		update_scoreboard()
	end
end

-- routes the frame draw to whichever screen is active
function _draw()
	if game_state == "menu" then
		draw_menu()
	elseif game_state == "playing" then
		draw_game()
	elseif game_state == "howto" then
		draw_howto()
	elseif game_state == "gameover" then
		draw_gameover()
	elseif game_state == "enter_name" then
		draw_name_entry()
	elseif game_state == "scoreboard" then
		draw_scoreboard()
	end
end

function init_menu()
  menu_selected = 1
  menu_options = {"start", "no enemy", "how to play", "high score", "change name"}
end

-- handles menu navigation and dispatches the selected option
function update_menu()
	if btnp(⬆️) then
		menu_selected -= 1
		if menu_selected < 1 then menu_selected = #menu_options end
	end
	if btnp(⬇️) then
		menu_selected += 1
		if menu_selected > #menu_options then menu_selected = 1 end
	end

	if btnp(❎) then
		local choice = menu_options[menu_selected]
		if choice == "start" then
			init_game()
			game_state = "playing"
      is_enemy = true
    elseif choice == "no enemy" then
      init_game()
      game_state = "playing"
      is_enemy = false
		elseif choice == "how to play" then
			game_state = "howto"
		elseif choice == "high score" then
			game_state = "scoreboard"
		elseif choice == "change name" then
			init_name_entry()
			game_state = "enter_name"
		end
	end
end

-- draws the menu list with the current selection highlighted
function draw_menu()
  camera(0, 0)
	pal()     
  cls(1)

  print("rock paper vikings", 30, 30, 7)

  for i, opt in ipairs(menu_options) do
    local y = 50 + (i-1)*10
    local col = (i == menu_selected) and 10 or 6
    local prefix = (i == menu_selected) and "> " or "   "
    print(prefix..opt, 30, y, col)
  end
end

function update_howto()
	if btnp(❎) then
		game_state = "menu"
	end
end

-- static how-to-play text screen
function draw_howto()
  camera(0,0)   
	pal()         
  cls(0)

  local y = 4
  local lh = 6  

  print("rock-paper-vikings", 4, y, 10) y+=lh+2
  
  print("controls:", 4, y, 9) y+=lh
  print("movement: ⬆️⬇️⬅️➡️", 4, y, 7) y+=lh
  print("(double) jump: (2x) ⬆️ // ❎", 4, y, 7) y+=lh
  print("dash: 2x tap ⬅️/➡️ // 🅾️+⬅️/➡️", 4, y, 7) y+=lh
  print("gives invulnerability", 4, y, 2) y+=lh
  print("resets on every new platform", 4, y, 3) y+=lh+1
  print("slam: 2x tap ⬇️ // 🅾️+⬇️", 4, y, 7) y+=lh
  print("kills right enemy, stuns others", 4, y, 2) y+=lh
  print("resets on normal(non-slam) kill", 4, y, 3) y+=lh+1
  print("wall-jump near walls", 4, y, 7) y+=lh+2

  print("who beats who:", 4, y, 9) y+=lh
  print("knight beats cowboy", 4, y, 7) y+=lh
  print("cowboy beats wizard", 4, y, 7) y+=lh
  print("wizard beats knight", 4, y, 7) y+=lh+2

  print("timer runs out - theme changes", 4, y, 6) y+=lh
  print("jump on the right enemy to kill", 4, y, 6) y+=lh
  print("killing gives you points", 4, y, 6) y+=lh+2

  print("❎: back to menu", 4, y, 5)
end

function init_name_entry()
	name_chars = "abcdefghijklmnopqrstuvwxyz"
	name_input = {1,1,1}   
	name_cursor = 1
end

-- 3-letter name picker; cancel is blocked until a real name has been set once
function update_name_entry()
	if btnp(⬅️) then
		name_cursor = max(1, name_cursor - 1)
	end
	if btnp(➡️) then
		name_cursor = min(3, name_cursor + 1)
	end
	if btnp(⬆️) then
		name_input[name_cursor] -= 1
		if name_input[name_cursor] < 1 then name_input[name_cursor] = #name_chars end
	end
	if btnp(⬇️) then
		name_input[name_cursor] += 1
		if name_input[name_cursor] > #name_chars then name_input[name_cursor] = 1 end
	end

	if btnp(❎) then
		local final_name = ""
		for i=1,3 do
			final_name = final_name .. sub(name_chars, name_input[i], name_input[i])
		end
		player_name = final_name
		save_last_player_name(final_name)
		init_menu()
		game_state = "menu"
	end

	if btnp(🅾️) and player_name ~= "---" then   
		init_menu()
		game_state = "menu"
	end
end

-- shows the 3-letter cursor grid for name entry
function draw_name_entry()
	camera(0,0)
	pal()
	cls(0)
	print("enter your name", 30, 30, 7)

	for i=1,3 do
		local ch = sub(name_chars, name_input[i], name_input[i])
		local col = (i == name_cursor) and 10 or 7
		print(ch, 55 + (i-1)*10, 60, col)
	end

	print("⬅️➡️⬆️⬇️: select/change", 8, 90, 6)
	print("❎: confirm   🅾️: cancel", 8, 100, 6)
end

p_spr_sets={
	-- each sprite set has a starter number
	-- sets are 12 long, values are the starter numbers for the key's character
	viking=1,
	wizard=13,
	knight=25,
	cowboy=37
}

-- picks the player sprite frame based on current movement state, in priority order
function player_animate(char)

	local spr_s = p_spr_sets[char]

	if player.dashing then
		player.spr=spr_s+9
	elseif player.slamming then
		player.spr=spr_s+11
	elseif player.jumping and player.running then
		player.spr=spr_s+7
	elseif player.on_wall_left or player.on_wall_right then
		player.spr=spr_s+10
	elseif player.falling and player.running then
		player.spr=spr_s+8
	elseif player.jumping then
		player.spr=spr_s+5
	elseif player.falling then
		player.spr=spr_s+6
	elseif player.sliding then
		player.spr=spr_s+4
	elseif player.running then
		if time()-player.anim>0.1 then
			player.anim=time()
			player.spr+=1
			if player.spr>spr_s+3 then
				player.spr=spr_s+2
			end
		end
	else --player idle
		if time()-player.anim>0.3 then
			player.anim=time()
			player.spr+=1
			if player.spr>spr_s+1 then
				player.spr=spr_s
			end
		end
	end
end

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

	if (is_enemy) dash()

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
	if (btnp(⬆️) or btnp(❎))
	and player.landed then
		player.dy -= player.boost
		player.landed = false 

	-- double jump
	elseif (btnp(⬆️) or btnp(❎))
	and player.double_jump
	and not (player.on_wall_left or player.on_wall_right) then
		-- making sure to not take double jump when on wall
		player.dy = 0
		player.dy -= player.boost
		player.double_jump = false
	end

	if (is_enemy) slam()

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
		if player.jump_held and not (btn(⬆️) or btn(❎)) then
			player.dy /= 2
		end
	end

	
	player.dashing = player.dash_timer > 0 

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

		if btnp(⬆️) or btnp(❎) then
			player.dy = 0
			player.dy -= player.boost/2
			player.dx += player.boost/2
		end

	-- hitting right wall
	elseif player.on_wall_right then
		player.dy /= 2

		if btnp(⬆️) or btnp(❎) then
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

	player.jump_held = btn(⬆️) or btn(❎)

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

	-- 🅾️ + direction triggers dash immediately, no double-tap timing needed
	local hold_dash_r = btnp(🅾️) and btn(➡️)
	local hold_dash_l = btnp(🅾️) and btn(⬅️)

	-- if dash is ready and right or left button is pressed then dash
	if (btnp(➡️)
	and player.dash_ready_r
	and not player.dash_ready_l
	and time()-player.dash_act_time<0.25
	and not player.dash_used_on_platform)
	or (hold_dash_r and not player.dash_used_on_platform) then
		player.dx += player.dash_speed
		player.dash_timer = 6
		player.dash_used_on_platform = true
	elseif (btnp(⬅️)
	and player.dash_ready_l
	and not player.dash_ready_r
	and time()-player.dash_act_time<0.25 
	and not player.dash_used_on_platform)
	or (hold_dash_l and not player.dash_used_on_platform) then
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

	-- 🅾️ + down triggers slam immediately, no double-tap timing needed
	local hold_slam = btnp(🅾️) and btn(⬇️)

	-- double-tap down or 🅾️+down triggers slam, only while airborne and ready
	if player.slam_ready
	and not player.landed
	and ((btnp(⬇️) and time()-player.slam_act_time<0.25) or hold_slam) then
		player.double_jump = false
		player.dy += 14
		player.slamming = true
		player.slam_ready = false
	elseif btnp(⬇️) then
		player.slam_act_time = time()
	end
end

-- aoe check on landing after a slam: right type dies, others get stunned
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

-- draws the slam impact flash sprites on both sides of the player
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

-- loads the ranked high score plus the separately-stored last-used player name
function load_scoreboard()
	high_score = dget(0)   

	high_score_name = ""
	for i=1,8 do
		local code = dget(i)  
		if code > 0 then
			high_score_name = high_score_name .. chr(code)
		end
	end

	if high_score_name == "" then
		high_score_name = "---"
	end

	player_name = load_last_player_name()
	if player_name == "" then
		player_name = "---"
	end
end

-- persists a new high score and its owner's name
function save_scoreboard(name, sc)
	dset(0, sc)
	for i=1,8 do
		local ch = sub(name, i, i)
		if ch ~= "" then
			dset(i, ord(ch))
		else
			dset(i, 0)
		end
	end
end

function update_scoreboard()
	if btnp(❎) then
		game_state = "menu"
	end
end

-- shows the saved high score and the currently active player name
function draw_scoreboard()
	camera(0,0)
	pal()
	cls(0)
	print("high score", 40, 40, 10)
	print(high_score_name .. ": " .. high_score, 30, 55, 7) 
  
  print("playing as:", 30, 70, 6)
	if player_name == "---" then
		print("???", 32, 80, 9)
	else
		print(player_name, 32, 80, 9)
	end
  
	print("❎: back", 30, 100, 6)
end

-- stores the last name entered, independent of the high score's owner
function save_last_player_name(name)
    for i=1,8 do
        local ch = sub(name, i, i)
        dset(8+i, ch ~= "" and ord(ch) or 0)
    end
end

-- reads back the last name entered, used to prefill player_name on boot
function load_last_player_name()
    local n = ""
    for i=1,8 do
        local code = dget(8+i)
        if code > 0 then n = n .. chr(code) end
    end
    return n
end

-- pushes the spawn point up out of solid tiles, then carves a safe ground strip
function ensure_spawn_platform(px, py, wall_spr_top, wall_spr_fill)
	local spawn_tx = flr(px/8)
	local spawn_ty = flr(py/8)

	local safety_counter = 0
	while fget(mget(spawn_tx, world_to_map_row(spawn_ty)), 0) and safety_counter < 20 do
		spawn_ty -= 1
		player.y -= 8
		safety_counter += 1
	end

	local ground_ty = spawn_ty + 1
	for dx=-2,2 do
		mset(spawn_tx+dx, world_to_map_row(ground_ty), wall_spr_top)
	end
end

-- counts down the phase timer, then randomly swaps to a new character class
function update_phase()
	phase.current -= 1

	if phase.current <= 0 then
		local new_index
		repeat
			new_index = flr(rnd(4)) + 1
		until new_index != phase.char_index

		local old_char = player.spr_set

		phase.char_index = new_index
		phase.current = phase.duration

		player.spr_set = phase.chars[phase.char_index]
		player.spr = p_spr_sets[player.spr_set]
		player.anim = time()

		music(music_patterns[player.spr_set])

		retile_floor(wall_sprites[old_char], wall_sprites[player.spr_set])
		retile_decoration(decoration_sprites[old_char], decoration_sprites[player.spr_set])
	end
end

-- swaps every generated-so-far floor tile from the old character's wall sprite to the new one
function retile_floor(old_spr, new_spr)

	local tx_min_clear = flr(map_start/8)
	local tx_max_clear = flr(map_end/8)

	for ty = world_generated_up_to, 64 do
		local map_row = world_to_map_row(ty)
		for tx = tx_min_clear, tx_max_clear do
			local s = mget(tx, map_row)
			if s == old_spr then
				mset(tx, map_row, new_spr)
			elseif s == old_spr+1 then
				mset(tx, map_row, new_spr+1)
			end
		end
	end
end

-- swaps every generated-so-far decoration sprite from the old character's set to the new one
function retile_decoration(old_spr, new_spr)
	local tx_min_clear = flr(map_start/8)
	local tx_max_clear = flr(map_end/8)

	for ty = world_generated_up_to, 64 do
		local map_row = world_to_map_row(ty)
		for tx = tx_min_clear, tx_max_clear do
			local s = mget(tx, map_row)
			if s == old_spr then
				mset(tx, map_row, new_spr)
			end
		end
	end
end

-- draws the repeating, parallax-scrolling background for the current character theme
function draw_background()

	local tile_size = 16
	local parallax_factor = 0.2

	local scroll_x = (cam_x * parallax_factor) % tile_size
	local scroll_y = (cam_y * parallax_factor) % tile_size

	local b = bg_sprites[player.spr_set]

	camera(0,0)

	for y = -tile_size, 128+tile_size, tile_size do
		for x = -tile_size, 128+tile_size, tile_size do
			local screen_x = x - scroll_x
			local screen_y = y - scroll_y

			spr(b[1], screen_x,   screen_y,   1, 1)
			spr(b[2], screen_x+8, screen_y,   1, 1)
			spr(b[3], screen_x,   screen_y+8, 1, 1)
			spr(b[4], screen_x+8, screen_y+8, 1, 1)
		end
	end

	camera(cam_x, cam_y)
end

-- draws the phase-timer dot bar, with the current dot animating as it depletes
function draw_phase_bar()

	local dot_size=5
	local gap=3
	local origin_x=cam_x + (phase.dot_count*8/2)
	local origin_y=cam_y + 2

	local col = 1
	local outline_col = 0

	local progress = 1 - (phase.current / phase.duration)
	local exact_pos = progress * phase.dot_count

	for i=0,phase.dot_count-1 do
		local visual_i = phase.dot_count-1-i
		local dx = origin_x + visual_i*(dot_size+gap)
		local dy = origin_y
		local cx = dx + flr(dot_size/2)
		local cy = dy + flr(dot_size/2)
		local arm = flr(dot_size/2)

		if i < flr(exact_pos) then
			rect(cx-1, cy-1, cx+1, cy+1, outline_col)
			pset(cx, cy, col)

		elseif i == flr(exact_pos) then
			local local_t = exact_pos - i

			if local_t < 0.33 then
				rect(dx-1, dy-1, dx+dot_size, dy+dot_size, outline_col)
				rectfill(dx, dy, dx+dot_size-1, dy+dot_size-1, col)
			elseif local_t < 0.66 then
				draw_cross(cx, cy, max(1, flr(arm/2)), outline_col, true)
				draw_cross(cx, cy, max(1, flr(arm/2)), col, false)
			else
				rect(cx-1, cy-1, cx+1, cy+1, outline_col)
				pset(cx, cy, col)
			end

		else
			rect(dx-1, dy-1, dx+dot_size, dy+dot_size, outline_col)
			rectfill(dx, dy, dx+dot_size-1, dy+dot_size-1, col)
		end
	end

end

-- draws a plus-shaped cross, optionally thickened, used by the phase bar
function draw_cross(cx, cy, arm, col, thick)
	if thick then
		line(cx-arm-1, cy, cx+arm+1, cy, col)
		line(cx-arm-1, cy-1, cx+arm+1, cy-1, col)
		line(cx-arm-1, cy+1, cx+arm+1, cy+1, col)
		line(cx, cy-arm-1, cx, cy+arm+1, col)
		line(cx-1, cy-arm-1, cx-1, cy+arm+1, col)
		line(cx+1, cy-arm-1, cx+1, cy+arm+1, col)
	else
		line(cx-arm, cy, cx+arm, cy, col)
		line(cx, cy-arm, cx, cy+arm, col)
	end
end

-- draws the corner hud showing who the player beats
function draw_nemesis()
	if (player.spr_set == "viking") return
	local x_x = map_end-9*2-3
	local x_y = cam_y+9

	spr(143, x_x, x_y, 1, 1)
	enemy_outl(x_x, x_y, outline_x, 0)

	local ex, ey = map_end-9-1, cam_y+9

	if player.spr_set == "wizard" then
		anim_disp(187)
		spr(display.spr, ex, ey, 1, 1)
		enemy_outl(ex, ey, outline_knight[display.state], 0)
	elseif player.spr_set == "knight" then
		anim_disp(160)
		spr(display.spr, ex, ey, 1, 1)
		enemy_outl(ex, ey, outline_cowboy[display.state], 0)
	elseif player.spr_set == "cowboy" then
		anim_disp(144)
		spr(display.spr, ex, ey, 1, 1)
		enemy_outl(ex, ey, outline_wizard[display.state], 0)
	end
end

-- draws a sprite's line-art outline from a list of segments
function enemy_outl(x, y, segments, col)
	for _, s in ipairs(segments) do
		line(x+s[1], y+s[2], x+s[3], y+s[4], col)
	end
end

-- toggles the nemesis display sprite between its two animation frames
function anim_disp(spr_val)
	if time() - display.anim > 0.3 then
			display.anim = time()
			if display.spr == spr_val then
				display.spr = spr_val+1
				display.state = "s_2"
			else
				display.spr = spr_val
				display.state = "s_1"
			end
		end
end

-- draws icons showing which of dash/slam are currently available
function draw_skills() 
	local s_x = map_end-8
	local d_x = map_end-8*2-1
	local y = cam_y+9*2+2

	if (not player.dash_used_on_platform) spr(158, d_x, y, 1, 1)
	if (player.slam_ready) spr(159, s_x, y, 1, 1)
end

-- wizard enemy state machine: orbit around spawn -> follow player -> return to orbit
function update_wizard(e)

	local dx = player.x - e.x
	local dy = player.y - e.y
	local dist = sqrt(dx*dx + dy*dy)

	if e.w_state == "orbit" then

		-- circles its spawn point until the player gets close
		e.orbit_angle += e.orbit_speed
		if e.orbit_angle >= 1 then
			e.orbit_angle -= 1
		end

		e.x = e.origin_x + cos(e.orbit_angle) * e.orbit_radius
		e.y = e.origin_y + sin(e.orbit_angle) * e.orbit_radius

		if dist < e.detect_range then
			e.w_state = "follow"
		end

	elseif e.w_state == "follow" then

		-- chases the player directly
		if dist > 0 then
			e.x += (dx/dist) * e.chase_speed
			e.y += (dy/dist) * e.chase_speed
		end

		if dist > e.detect_range then
			e.w_state = "return"
		end

	elseif e.w_state == "return" then

		-- heads back to the nearest point on its orbit ring
		local ox = e.x - e.origin_x
		local oy = e.y - e.origin_y
		local angle_to_e = atan2(ox, oy)

		local target_x = e.origin_x + cos(angle_to_e) * e.orbit_radius
		local target_y = e.origin_y + sin(angle_to_e) * e.orbit_radius

		local rdx = target_x - e.x
		local rdy = target_y - e.y
		local rdist = sqrt(rdx*rdx + rdy*rdy)

		if rdist < 1 then
			e.orbit_angle = angle_to_e
			e.w_state = "orbit"
		else
			e.x += (rdx/rdist) * e.chase_speed
			e.y += (rdy/rdist) * e.chase_speed
		end

		if dist < e.detect_range then
			e.w_state = "follow"
		end

	end

	e.flp = player.x < e.x

	animate_wizard(e)

end

-- toggles wizard sprite between its two animation frames
function animate_wizard(e)

	local wizard_spr_base=144

	if time()-e.anim > 0.3 then
		e.anim = time()
		e.spr = (e.spr == wizard_spr_base) and wizard_spr_base+1 or wizard_spr_base
	end

end
__gfx__
00000000700000070708807000000007000000700000000000088000070880700089987730000007000000007088807006844860004334000004400000444000
00000000778998770789987000899877008998707000000770899807078998700899998700899877707788777799987009433490043333400043340004333400
00700700089999800836638008999980089999807788998774366347683663860433366038999980008999870433664608433480444444440476674043333340
000770000436634004333340043333600433366008999998943333469333333943334330346636640899999899333339073333700d7667d00d7777d044777760
000770009333333909333390433994303399433404336664643333494333338443349934339943344333366366333334043663404777777404777740d7744d70
007007006433334606433460049664404466943469333339043338400843389804999834048894306636993404333348074334706d7777d606d77d600d466dd0
0000000008444480008448000008800000899840684333860084898089844400006689400008980006469946084334890784497004dddd40004dd40000044000
00000000898008980898898000899800088889988984489808984000000000003008900000008990898444988984400800089000434004340434434000433400
0000000000000000000440000004400000433400704440000000000040444000064dd46000000000000880000000000000000000000000000008800000088000
004334000000000000433400004334000433334000433400404444000433340003d77d3000899800008cc800008998000089980000000000009cc900c099990c
43333340004433400d7667d0647667464d77766074333340000333400d7766d604d77d40089cc98009988990089ccc90089ccc900089cc8009888890c9c88c9c
04777660443333344d7777d647777774d777d7707d66766d0433333444777774047777400c8888c00cc88cc00cccc8800ccc8880089ccc98c9c88c9c9cccccc9
0d44d77d0d77666d6d7777d4d777774dd77d337d7733d77dd77776676677777d0d7667d09cc88cc909cccc900cc99c800c99c8990ccc88889cccccc909999980
0d663d7d637777740d7774d004d774340d33347d0d443d706676447d0d7777d404377340c999999c0c9999c0009cc90009cc9c9cc98cc88909ccc890089cc898
004334d064d77746004d4340434ddd00006643d00004340006d644d604d77d430043340008cccc80008cc8000008800000889800c89ccc9c0089898089899000
04444334434dd4340434d000000000007004300000004330434ddd34434dd0040004400089800898089889800089980008998880898998880898000000000000
008998000000000000000000008880000c8008c000000000000ff000000000000000000000000000000ff000f0ffff0f00ffff00000fff0f000000f0f0ffff0f
089ccc9000899800c0cc8800099cc98009cccc90f0ffff0f0ffeeff0f0ffff0ff0ffff0f00000000ffeeeeffffeeeeffffeeeefff0ffeefff000ff0fffeeeef0
89ccc880089ccc9c00899c8008cc888c08888880ffeeeefffe3663efffeeeeffffeeeefff00ffffff436634f64366346f433366fffeee66000ffffff04336646
9ccccc8c8cccc889089cccc899ccc8c908cccc80043663400f4334f00433336004433660fffeeeef64333346f433334f4333433003663664ffeeee6fff44333f
09cc99998c99cc8989989889cc99999008c88c80ff4334ff0fe44ef004eff4300eff433f04436664fe4334ef0e4444f04334ee3f04ee43344333366366feeef0
0899988009889c90cccc998c09cccc98098888906eeeeee606eeee6000f66e400f66eee66ef4333e0feeefe00feeefef0feeefef00ffe43066e6ff340eeeeeef
00cc8980009898000c8c99cc089cc989008cc9000feffef000feef00000ff00000feeff06feeeef600f0fff0fef000000066fef0000fef0006e6ff460feffefe
9008900000008990898c0c988980000800089000fef00fef0feffef000feef000ffffeeffef00fef0fff000000000000300fe0000000fee0fef0e0effef0000f
06f44f60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e4334e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f4334f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e3333e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f436634f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffe33eff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ffeeff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0111111022222222efffffff55555555efffffff22a2222a9c9899cccccccccccccccccc6666666666666666cccccccccccccccc000000000000000000000000
114444402b22bb92dfffedfe53553365dfffedfeab22899299989999cc77cccccccccccc6677666666666666cc66cccccccccccc000000000000000000000000
144848402b9bb8bbefeffeff53633433efeffeffb99b8bbbb998bb99c7777ccccccccccc6777766666666666c6666ccccccccccc000000000000000000000000
04444440bb2b8ff87fffffff335344f47fffffff8882888288888888cccccccccccccccc6666666666666666cccccccccccccccc000000000000000000000000
00a4a00088bfffffffffffff443fffffffffffffb9cbcccb99c9ccc8ccccccccccc77ccc6666666666677666ccccccccccc66ccc000000000000000000000000
044a4400ef8fefefefffefefef4fefefefffefef2999999899999998cccccccc777777cc6666666677777766cccccccc666666cc000000000000000000000000
00444000fdfefffffdfefff7fdfefffffdfefff7bbb9b998bbb9b998ccccccc77777777c6666666777777776ccccccc66666666c000000000000000000000000
04000400fefffedffefffedffefffedffefffedf8888888888888888cccccccccccccccc6666666666666666cccccccccccccccc000000000000000000000000
70000007000000000000000000000000000000000000000000000000cccccccccccccccc6666666666666666cccccccccccccccc000000000000000000000000
77566577000000000000000000000000000000000000000000000000cccccc77cccccccc6666667766666666cccccc66cccccccc000000000000000000000000
05666650000000000000000000000000000000000000000000000000cccc77777ccccccc6666777776666666cccc66666ccccccc000000000000000000000000
049ff9400000000000000000000000000000000000000000000000007cccccccccccc77776666666666667776cccccccccccc666000000000000000000000000
5999999500000000000000000000000000000000000000000000000077cccccccccc7777776666666666777766cccccccccc6666000000000000000000000000
f499994f000000000000000000000000000000000000000000000000cccccccccccccccc6666666666666666cccccccccccccccc000000000000000000000000
05444450000000000000000000000000000000000000000000000000cccccccccccccccc6666666666666666cccccccccccccccc000000000000000000000000
56500565000000000000000000000000000000000000000000000000cccccccccccccccc6666666666666666cccccccccccccccc000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000002a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000070000000000000002202000000000000ff000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000075700000000000020b22a00000000000f43d00000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000002070000000000000b22a0000000000000ffef00000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000a2a00000000000000220000000000000f44e00000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000b2000000000000000ba0000000000000ffff00000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033110113
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000311330
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000130110
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001300310
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013000031
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013000003
00f11f00000ff00000feef0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008880008888800
0f1111f000f11f000feeeef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008888188008111800
ffffffff0f3553f0ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000008111138808113800
04355340043333400ed77de000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008111313888113880
1333333101333310edddddde00000000000000000000000000000000000000000000000000000000000000000000000000000000000000008333138883111380
54333345054334507edddde700000000000000000000000000000000000000000000000000000000000000000000000000000000000000008888388088313880
0f4444f000f44f000feeeef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008880008838800
f1f00f1f0f1ff1f0fef00fef00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888000
00000000000ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0ffff0f0ff11ff0f0ffff0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff1111fff135531fffeeeeff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
043553400f4334f007d77d7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ff4334ff0f1441f0ff7dd7ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51111115051111507eeeeee700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f1ff1f000f11f000feffef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f1f00f1f0f1ff1f0fef00fef00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff000005500500000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000feef0000f11f0000f33f005033ff0000f11f0000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000feddef00f1331f0011ff11000f113f50f13331300f11f00
000000000000000000000000000000000000000000000000000000000000000000000000000000000d7777d003ffff30033ff3300f13333ff3333ff10f1331f0
00000000000000000000000000000000000000000000000000000000000000000000000000000000edd77dde133ff33101333310f11f1ff1f31133f103ffff30
00000000000000000000000000000000000000000000000000000000000000000000000000000000deeeeeed3111111303111130333311f301ff1310133ff331
000000000000000000000000000000000000000000000000000000000000000000000000000000000fddddf00f3333f000f33f0003f31133001f1f0031111113
00000000000000000000000000000000000000000000000000000000000000000000000000000000fef00feff1f00f1f0f1ff1f0f1f3031f0000f110f1f00f1f
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000de000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dddde000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddeede0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ded0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dd0ed000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000ed000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddddde000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddeede0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddd0000000d0000000d0000000d0000000d0000000d0000000dddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddd0888880d0888880d0888880d0888880d0888880d0888880ddd000dddddddddddddddddddddddddddddddddddddddddddd
ddddddddffddddddddddddddffddddd0888880d0888880d0888880d0888880d0888880d0888880dd00800dddf000ddddddddddddffddddddddddddddffdddddd
dddddddffffddddddddddddffffdddd0888880d0888880d0888880d0888880d0888880d0888880330888033330803333333333333333333333333333fffddddd
ddddddddddddddddddddddddddddddd0888880d0888880d0888880d0888880d0888880d08888801300800j133000jj133j33jj133j33jj133j33jj13dddddddd
dffddddddddddddddffdddddddddddd0888880d0888880d0888880d0888880d0888880d0888880jj3000jhjj3j1jjhjj3j1jjhjj3j1jjhjj3j1jjhjjdddddddd
ffffddddddddddffffffddddddddddf0000000d0000000f0000000d0000000f0000000d0000000lhjj3jhllhjj3jhllhjj3jhllhjj3jhllhjj3jhllhddddddff
fffffddddddddffffffffddddddddffffffffddddddddffffffffddddddddffffffffdddhhjlllllhhjlllllhhjlllllhhjlllllhhjlllllhhjllllldddddfff
dd00000000000000000000ddddddd00000dddddddddddddddddddddddddddddddddddddd5lhl5l5l5lhl5l5l5lhl5l5l5lhl5l5l5lhl5l5l5lhl5l5ldddddddd
d008800880088088808880000dddd08880ddddddddddddddddddddddddddddddddddddddlml5lllllml5lllllml5lllllml5lllllml5lllllml5lllldddddddd
d080008000808080808000080dddf08080ddddddddddffddddddddddddddffddddddddddl5lll5mll5lll5mll5lll5mll5lll5mll5lll5mll5lll5mlddddffdd
d0888080d080808800880d000dfff08080ddddddddfffffdddddddddddfffffddddddddd5lllllll5lllllll5lllllll5lllllll5lllllll5lllllllddfffffd
d000808000808080808000080dddd08080dffffddddddddddddffffddddddddddddffffdmlll5ml5mlll5ml5mlll5ml5mlll5ml5mlll5ml5mlll5ml5dddddddd
d088000880880080808880000dddd08880ffffffddddddddddffffffddddddddddffffff5l5ll5ll5l5ll5ll5l5ll5ll5l5ll5ll5l5ll5ll5l5ll5lldddddddd
d0000d0000000000000000ddddddd00000ddddddddddddddddddddddddddddddddddddddflllllllflllllllflllllllflllllllflllllllfllllllldddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlllllllllllllllllllllllllllllllllllllllllllllllldddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd5lll5l5l5lll5l5l5lll5l5l5lll5l5l5lll5l5l5lll5l5ldddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlml5lllflml5lllflml5lllflml5lllflml5lllflml5lllfdddddddd
ddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddl5lll5mll5lll5mll5lll5mll5lll5mll5lll5mll5lll5mlffdddddd
dddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddd5lllllll5lllllllddhhhddffhhhhhdd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmlll5ml5mlll5mlhhhh8hhdddh888hdd
dffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddd5l5ll5ll5l5ll5lh8888phhddh88phdd
ffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffflllllllfllllllh888p8phdhh88phhf
fffffddddddddffffffffddddddddffffffffddddddddffffffffddddddddffffffffddddddddffffffffddddddddffflllllllllllllllhppp8phhdhp888phf
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd5lll5l5l5lll5l5hhhhphhddhhp8phhd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlml5lllflml5lllfddhhhddddhhphhdd
ddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddl5lll5mll5lll5mlddddddddddhhhfdd
ddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffd
dddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddd
ddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffdddddddd
dddddddddddddddddddddddddddfdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddfdddddddddddddddddddddddddddd
ddddddddddddddddddddddddddf9fdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddf9fddddddddddddddddddddddddddd
ddddddddddddddddddddddddd3dfddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd3dfdddddddddddddddddddddddddddd
ddddddddddddddddddddddddddr3rdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddr3rddddddddddddddddddddddddddd
ddddddddffddddddddddddddffj3ddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddj3ddddffddddddddddddddffdddddd
33333333333333333333333333333333dddddddffffddddddddddddffffddddddddddddf33333333333333333333333333333333fffddddddddddddffffddddd
3j33jj133j33jj133j33jj133j33jj13dddddddddddddddddddddddddddddddddddddddd3j33jj133j33jj133j33jj133j33jj13dddddddddddddddddddddddd
3j1jjhjj3j1jjhjj3j1jjhjj3j1jjhjjdffddddddddddddddffddddddddddddddffddddd3j1jjhjj3j1jjhjj3j1jjhjj3j1jjhjjdddddddddffddddddddddddd
jj3jhllhjj3jhllhjj3jhllhjj3jhllhffffddddddddddffffffddddddddddffffffddddjj3jhllhjj3jhllhjj3jhllhjj3jhllhddddddffffffddddddddddff
hhjlllllhhjlllllhhjlllllhhjlllllfffffddddddddffffffffddddddddffffffffdddhhjlllllhhjlllllhhjlllllhhjllllldddddffffffffddddddddfff
5lhl5l5l5lhl5l5l5lhl5l5l5lhl5l5ldddddddddddddddddddddddddddddddddddddddd5lhl5l5l5lhl5l5l5lhl5l5l5lhl5l5ldddddddddddddddddddddddd
lml5lllllml5lllllml5lllllml5llllddddddddddddddddddddddddddddddddddddddddlml5lllllml5lllllml5lllllml5lllldddddddddddddddddddddddd
l5lll5mll5lll5mll5lll5mll5lll5mlddddddddddddffddddddddddddddffddddddddddl5lll5mll5lll5mll5lll5mll5lll5mlddddffddddddddddddddffdd
dddddddd5lllllll5lllllll5lllllllddddddddddfffffdddddddddddfffffd333333335lllllll5lllllll5lllllll5lllllllddfffffdddddddddddfffffd
dddffffdmlll5ml5mlll5ml5mlll5ml5dddffffddddddddddddffffddddddddd3j33jj13mlll5ml5mlll5ml5mlll5ml5mlll5ml5dddddddddddffffddddddddd
ddffffff5l5ll5ll5l5ll5ll5l5ll5llddffffffddddddddddffffffdddddddd3j1jjhjj5l5ll5ll5l5ll5ll5l5ll5ll5l5ll5llddddddddddffffffdddddddd
ddddddddflllllllflllllllflllllllddddddddddddddddddddddddddddddddjj3jhllhflllllllflllllllflllllllfllllllldddddddddddddddddddddddd
ddddddddllllllllllllllllllllllllddddddddddddddddddddddddddddddddhhjllllllllllllllllllllllllllllllllllllldddddddddddddddddddddddd
dddddddd5lll5l5l5lll5l5l5lll5l5ldddddddddddddddddddddddddddddddd5lhl5l5l5lll5l5l5lll5l5l5lll5l5l5lll5l5ldddddddddddddddddddddddd
ddddddddlml5lllflml5lllflml5lllfddddddddddddddddddddddddddddddddlml5lllllml5lllflml5lllflml5lllflml5lllfdddddddddddddddddddddddd
ddddddddl5lll5mll5lll5mll5lll5mlddddddddffddddddddddddddffddddddl5lll5mll5lll5mll5lll5mll5lll5mll5lll5mlffddddddddddddddffdddddd
dddddddf5lllllll5lllllll5llllllldddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddd5lllllllfffddddddddddddffffddddd
ddddddddmlll5ml5mlll5ml5mlll5ml5ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddmlll5ml5dddddddddddddddddddddddd
dffddddd5l5ll5ll5l5ll5ll5l5ll5lldffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddd5l5ll5lldddddddddffddddddddddddd
ffffddddflllllllflllllllflllllllffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffflllllllddddddffffffddddddddddff
fffffdddllllllllllllllllllllllllfffffddddddddffffffffddddddddffffffffddddddddffffffffddddddddffflllllllldddddffffffffddddddddfff
dddddddd5lll5l5l5lll5l5l5lll5l5ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd5lll5l5ldddddddddddddddddddddddd
ddddddddlml5lllflml5lllflml5lllfddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddlml5lllfdddddddddddddddddddddddd
ddddddddl5lll5mll5lll5mll5lll5mlddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddl5lll5mlddddffddddddddddddddffdd
ddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddfdffffffddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffd
dddffffddddddddddddffffddddddddddddffffddddddddddddffffdffh11hffdddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddd
ddffffffddddddddddffffffddddddddddffffffddddddddddffffffdh1111hdddffffffddddddddddffffffddddddddddffffffddddddddddffffffdddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd4pvvp4ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddd1pppppp1dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddv4pppp4vdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddh4444hddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddffddddddddddddddffddddddddddddddffddddddddddddddh1hddh1hddddddddffddddddddddddddffddddddddddddddffddddddddddddddffdddddd
dddddddffffddddddddddddffffddddddddddddffffddddd333333333333333333333333fffddddddddddddffffddddddddddddffffddddddddddddffffddddd
dddddddddddddddddddddddddddddddddddddddddddddddd3j33jj133j33jj133j33jj13dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dffddddddddddddddffddddddddddddddffddddddddddddd3j1jjhjj3j1jjhjj3j1jjhjjdddddddddffddddddddddddddffddddddddddddddffddddddddddddd
ffffddddddddddffffffddddddddddffffffddddddddddffjj3jhllhjj3jhllhjj3jhllhddddddffffffddddddddddffffffdddddddfddffffffddddddddddff
fffffddddddddffffffffddddddddffffffffddddddddfffhhjlllllhhjlllllhhjllllldddddffffffffddddddddffffffffdddddf9fffffffffddddddddfff
dddddddddddddddddddddddddddddddddddddddddddddddd5lhl5l5l5lhl5l5l5lhl5l5lddddddddddddddddddddddddddddddddd3dfdddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddlml5lllllml5lllllml5llllddddddddddddddddddddddddddddddddddr3rddddddddddddddddddd
ddddddddddddffddddddddddddddffddddddddddddddffddl5lll5mll5lll5mll5lll5mlddddffddddddddddddddffddddddddddddj3ffddddddddddddddffdd
ddddddddddfffffdddddddddddfffffdddddddddddfffffd5lllllll5lllllll5lllllllddfffffdddddddddddfffffddddddddd333333333333333333333333
dddffffddddddddddddffffddddddddddddffffdddddddddmlll5ml5mlll5ml5mlll5ml5dddddddddddffffddddddddddddffffd3j33jj133j33jj133j33jj13
ddffffffddddddddddffffffddddddddddffffffdddddddd5l5ll5ll5l5ll5ll5l5ll5llddddddddddffffffddddddddddffffff3j1jjhjj3j1jjhjj3j1jjhjj
ddddddddddddddddddddddddddddddddddddddddddddddddflllllllflllllllflllllllddddddddddddddddddddddddddddddddjj3jhllhjj3jhllhjj3jhllh
ddddddddddddddddddddddddddddddddddddddddddddddddllllllllllllllllllllllllddddddddddddddddddddddddddddddddhhjlllllhhjlllllhhjlllll
dddddddddddddddddddddddddddddddddddddddddddddddd5lll5l5l5lll5l5l5lll5l5ldddddddddddddddddddddddddddddddd5lhl5l5l5lhl5l5l5lhl5l5l
ddddddddddddddddddddddddddddddddddddddddddddddddlml5lllflml5lllflml5lllfddddddddddddddddddddddddddddddddlml5lllllml5lllllml5llll
ddddddddffddddddddddddddffddddddddddddddffddddddl5lll5mll5lll5mll5lll5mlffddddddddddddddffddddddddddddddl5lll5mll5lll5mll5lll5ml
dddddddffffddddddddddddffffddddddddddddffffddddd5lllllll5llllllldddddddffffddddddddddddffffddddddddddddffffddddddddddddf5lllllll
ddddddddddddddddddddddddddddddddddddddddddddddddmlll5ml5mlll5ml5ddddddddddddddddddddddddddddddddddddddddddddddddddddddddmlll5ml5
dffddddddddddddddffddddddddddddddffddddddddddddd5l5ll5ll5l5ll5lldffddddddddddddddffddddddddddddddffddddddddddddddffddddd5l5ll5ll
ffffddddddddddffffffddddddddddffffffddddddddddffflllllllflllllllffffddddddddddffffffddddddddddffffffddddddddddffffffddddflllllll
fffffddddddddffffffffddddddddffffffffddddddddfffllllllllllllllllfffffddddddddffffffffddddddddffffffffddddddddffffffffdddllllllll
dddddddddddddddddddddddddddddddddddddddddddddddd5lll5l5l5lll5l5ldddddddddddddddddddddddddddddddddddddddddddddddddddddddd5lll5l5l
ddddddddddddddddddddddddddddddddddddddddddddddddlml5lllflml5lllfddddddddddddddddddddddddddddddddddddddddddddddddddddddddlml5lllf
ddddddddddddffddddddddddddddffddddddddddddddffddl5lll5mll5lll5mlddddddddddddffddddddddddddddffddddddddddddddffddddddddddl5lll5ml
ddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffd
dddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddd
ddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffdddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffdddddd
dddddddffffddddddddddddffffddddd3333333333333333333333333333333333333333fffddddddddddddffffddddddddddddffffddddddddddddffffddddd
dddddddddddddddddddddddddddddddd3j33jj133j33jj133j33jj133j33jj133j33jj13dddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dffddddddddddddddffddddddddddddd3j1jjhjj3j1jjhjj3j1jjhjj3j1jjhjj3j1jjhjjdddddddddffddddddddddddddffddddddddddddddffddddddddddddd
ffffddddddddddffffffddddddddddffjj3jhllhjj3jhllhjj3jhllhjj3jhllhjj3jhllhddddddffffffddddddddddffffffddddddddddffffffddddddddddff
fffffddddddddffffffffddddddddfffhhjlllllhhjlllllhhjlllllhhjlllllhhjllllldddddffffffffddddddddffffffffddddddddffffffffddddddddfff
dddddddddddddddddddddddddddddddd5lhl5l5l5lhl5l5l5lhl5l5l5lhl5l5l5lhl5l5ldddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddlml5lllllml5lllllml5lllllml5lllllml5lllldddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddffddddddddddddddffddl5lll5mll5lll5mll5lll5mll5lll5mll5lll5mlddddffddddddddddddddffddddddddddddddffddddddddddddddffdd
ddddddddddfffffdddddddddddfffffdddddddddddfffffd5lllllllddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffd
dddffffddddddddddddffffddddddddddddffffdddddddddmlll5ml5dddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddd
ddffffffddddddddddffffffddddddddddffffffdddddddd5l5ll5llddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffdddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddfllllllldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddlllllllldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddd5lll5l5ldddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddddddlml5lllfdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddffddddddddddddddffddddddddddddddffddddddl5lll5mlffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffdddddd
dddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddd
ffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddff
fffffddddddddffffffffddddddddffffffffddddddddffffffffddddddddffffffffddddddddffffffffddddddddffffffffddddddddffffffffddddddddfff
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffdd
ddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffdddddddddddfffffd
dddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddddddffffddddddddd
ddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffddddddddddffffffdddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000004242000000000000420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000042000046000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000004200004545460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000420000000000000000420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000042424242000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4242424241414141424242424242424242424242424242424242424242424242424242000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000004242424242424242424242004200420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000e00000f0501b1000f0500f0300f0501b1000f0500f0300d050191000d0500d0300d050191000d0500d0300b050191000b0500b0300b0500a0000b0500b0300b0500b0000b0500b0300b0500b0000b0500b030
000e00000f0501b1000f0500f0300f0501b1000f0500f0300d050191000d0500d0300d050191000d0500d03006050191000605006030060500a0000605006030080500b0000805008030080500b0000805008030
000e00000f0501b1000f0500f0300f0501b1000f0500f0300d050191000d0500d0300e050191000e0500e0300f0500f0000f0500f0300f0500a0000f0500f0300b0500b0000b0500b0300d0500b0000d0500d030
000e00000f0501b1000f0500f0300f0501b1000f0500f0300d050191000d0500d0300a050191000d0500d030080500f0000805008030080500a0000805008030080500b0000805008030080500b0000805008030
000e00000f0501b1000f0500f0300f0501b1000f0500f0300d050191000d0500d0300e050191000e0500e03008050060000805008030080500800008050080300b0500b0000b0500b0300d0500b0000d0500d030
000e00000f0501b1000f0500f0300f0501b1000f0500f0300d050191000d0500d0300a050191000d0500d03006050070000605006030060500a0000605006030080500b0000805008030080500b0000805008030
000e00000f0501b1000f0500f0300f0501b1000f0500f030100501910010050100300d050191000d0500d0300f050191000f0500f0300f0500f0000f0500f0300a0500a0500b0500b0500c0500c0500d0500d050
000e00000f0501b1000f0500f0300f0501b1000f0500f030110501910011050110301105019100110501103012050140001205012030120500f00012050120300b0500b0500b0500b0500d0500d0500d0500d050
000e00000f0501b1000f0500f0300f0501b1000f0500f0300d050191000d0500d0300d050191000d0500d0300b050191000b0500b0300b0500a0000b0500b0300a0500b0000a0500a0300a0500b0000a0500a030
000e0000080501b1000805008030080501b10008050080300a050090000a0500a0300a050191000a0500a0300b050191000b0500b0300b0500a0000b0500b0300d0500c0000d0500d0300d0500b0000d0500d030
0010000022030220302203022030220302203022030200302003020030200302003020030200301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e030
00100000200302003020030200302003020030200301d0301d0301d0301d0301d0301d0301d0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e0301e030
000e0000220302703022030270302203022030220302203022030220302203022030220302203022030220301e0301e0301e0301e030200302003020030200301b0301b0301b0301b0301b0301b0301b0301b030
000e0000220302703022030270302203022030220302203022030220302203022030220302203022030220301e0301e0301e0301e030200302003020030200302503025030250302503025030250302503025030
000e0000220302703022030270302203022030220302203022030220302203022030220302203022030220301e0301e0301e0301e0301d0301d0301b0301b0301903019030190301903019030190301903019030
000e0000220302703022030270302203022030220302203022030220302203022030220302203022030220301e0301e0301e0301e030200302003020030200301b0301b0301b0301b0301b0301b0301b0301b030
000e000022030220302203022030220302203022030220302003022030230302303022030220301b0301b03022030220302203022030220302203022030220302205022000220202203022040220302203022030
000e00001e0301e0301e0301e0301e0301e0301e0301e0301d0301d0301d0301d0301d0301d0301d0301d0301e0301e0301e0301e0301e0301e0301e0301e0302003020030200302003020030200302003020030
000e00001b0301b0301e0302203020030200301e0301e030200300300020030200201b0301b03019030190301b0301b0301e0302203020030200301e0301e0302203022030220302203022030220302203022030
000e000019030190301d0301e0301d0301d0301b0301b0301e03020030220302203020030200301e0301e03017030170301903019030140301403016030170301903019030190301903019030190301903019030
000e00001b550175001b5501b55012550125501455014550195500000019560195501956018500195401955017550000001756017550175601750017540175501955019500195501955019560000001954019550
000e00001d5500f5001d5501d5401d5600000012530125501d5500c5001b5501b5301b550000001b5301b55016550165001654016540165601150016540165601755000000175401755017560175001755017560
000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000016550165501655016550115501155011550115500b5500b5500b5500b5500b5500b5500b5500b550
000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5500d5500d5500d550115501155011550115501455014550145501455014550145501455014550
000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000016550165501655016550145501455012550125501155011550115501155011550115501155011550
000e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5500d5500d5500d550115501155011550115501b5401b5401b5401b5401b5401b5401b5401b540
000e00001e5301e5301e5301e5301e5301e5301e5301e5301b5301d5301e5301e5301d5301d53016530165301e5301e5301e5301e5301e5301e5301e5301e530205302050020520205301e5301e5301e5301e530
000e00001653016530165301653016530165301653016530195301953019530195301953019530195301953017530175301753017530175301753017530175301b5301b5301b5301b5301b5301b5301b5301b530
000e0000165301653016530165301b5301b5301b5301b5301d5301d5301d5301d5301e5301e5301d5301d530165301653016530165301b5301b5301b5301b5301953019530195301953019530195301953019530
000e000016530165301653016530195301953019530195301b5301b5301b5301b5301e5301e5301d5301d5301b5301b5301e530225301b5301b5301d5301e5302053020530205302053020530205302053020530
000e00000f5300f5300f5300f530125301253012530125301653016530165301653014530145301253012530165301653016530165301b5301b5301b5301b5301d5301d5301d5301d5301d5301d5301d5301d530
000e000016530165301653016530195301953019530195301b5301b5301b5301b5301e5301e5301d5301d5301b5301b5301e530225301b5301b5301d5301e5302053020530205302053020530205302053020530
000e0000287002870027700277002770027700277000000000000000000000000000000000000000000000000000000000000000000000000000000000000000277402770029740297402a740000000000000000
000e00002870028700277002770027700277002770000000000000000000000000000000000000000000000000000000000000000000000000000000000000002774027700257402574027740277400000000000
000e00002870028700277002770027700277002770000000000000000000000000000000000000000000000000000000000000000000000000000000000000002374024740257402674027740277402774027740
000e00002870028700277002770027700277002770000000000000000000000000000000000000000000000000000000000000000000000000000000000000002770027700257002570027740277002774027740
000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000277302773027730277302a7302a73029730297302573025730257302573022730227302273022730
000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000022700227002270022700227302273025730277302973029730297302973029730297302973029730
000e000027730277302773027730277302773027730277302a7302a7302a7302a7302e7302e7302e7302e7303373033730337303373033730337303373033730317303173031730317302e7302c7302a7302a730
000e00002773027730277302773027730277302773027730297302973029730297302a7302c7302e7302e7302a7302a7302a7302a7302a7302a7302a7302a7302e7302e7302c7302973031730317303173031730
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001d6201a600006000b63000000000001d6500000000000056100c600016001060000600000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 000a1420
00 010b1521
00 000a1420
00 010b1521
00 020c1622
00 030d1723
00 040e1862
00 050f1923
00 06101a60
00 07111b21
00 06101a60
00 07111b21
00 08121c24
00 09131d25
00 08121e26
00 09131f27
00 49424344

