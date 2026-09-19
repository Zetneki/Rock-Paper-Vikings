function init_game()
  poke(0x5f2e, 1) -- allows hidden colors
	poke(0x5f5c, 255) -- button press only activates once

  test = false

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
		acc=0.4,
		boost=4,
		anim=0,
		running=false,
		jumping=false,
		falling=false,
		sliding=false,
		landed=false,
    dash_used_on_platform=false,
		dash_act_time=0,
		dash_ready_l=false,
		dash_ready_r=false,
		dashing=false,
		dash_timer=0,
		max_dash_dx = 6,
		dash_speed=6,
		slam_act_time=0,
		slam_ready=false,
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

	--- TEST -----
	--spawn_enemy(24,32,"knight")
	--spawn_enemy(88, 24, "wizard")
	--spawn_enemy(24,64,"cowboy")

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

	-- cam_x=0
	cam_x, cam_y = 0, 0
	map_start = 0
	map_end = 128 

	map_start=128
	map_end=256

	camera_min_y = nil

	score=0
	last_height=1000

	auto_scroll_active = false
	auto_scroll_speed = 0.1 

	chunk_height = 30     
	trigger_buffer = 20    

	generate_chunk(64, 0, map_start, map_end, wall_sprites[player.spr_set], 18, 24, 3, 6, 0.4, true)
	world_generated_up_to = 0

  death_timer = nil
end

function update_game()
	if not player.dead then
		update_phase()
		move()
		update_camera()
		player_animate(player.spr_set)
		update_enemies()

		cleanup_distant_enemies()

		if last_height-player.y > 50 then
			last_height = player.y
			score+=10
		end

		local player_ty = flr(player.y/8)

		if player_ty < world_generated_up_to + trigger_buffer then
			local new_top = world_generated_up_to - chunk_height
			generate_chunk(world_generated_up_to, new_top, map_start, map_end, wall_sprites[player.spr_set], 18, 24, 3, 6, 0.4)
			world_generated_up_to = new_top
		end

		check_offscreen_death()
	else
    if death_timer == nil then
        death_timer = 30
        player.dy = -3   -- egyszeri felfele lokes (allitsd izles szerint, pl -3 vagy -4)
    end

    player.dy += gravity      -- ez MINDEN frame-ben fusson, hogy folyamatosan gyorsuljon
    player.y += player.dy     -- ez is minden frame-ben

    death_timer -= 1

    if death_timer <= 0 then
        if score > high_score then
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
	draw_enemies()

	draw_phase_bar()

	print("\^o0ffscore: " .. score, cam_x+2, cam_y+10)

	draw_nemesis()

	----- TEST -----
	if test then
		print("⬅️➡️ to move")
		print("❎ to jump, 🅾️ to dash")
		print("double jump:" .. tostring(player.double_jump))
		print("on wall left:" .. tostring(player.on_wall_left))
		print("on wall right:" .. tostring(player.on_wall_right))
	end
end

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