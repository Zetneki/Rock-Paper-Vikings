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

	enemies = {}

	--- TEST -----
	--spawn_enemy(24,32,"knight")
	--spawn_enemy(88, 24, "wizard")
	--spawn_enemy(24,64,"cowboy")

	-- charater type timer
	phase = {
		duration=400,     -- 600 frame = 20mp at 30fps
		current=400,
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

	generate_chunk(64, 0, map_start, map_end, 65, 18, 24, 3, 6, 0.4, true)
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
			generate_chunk(world_generated_up_to, new_top, map_start, map_end, 65, 18, 24, 3, 6, 0.4)
			world_generated_up_to = new_top
		end

		check_offscreen_death()
	else
		if death_timer == nil then
			death_timer = 30
		end

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
	end
end

function draw_game()
  cls()
  draw_world_wrapped(cam_x, cam_y) 
	change_palette(current_palette)

	--shakes player when struggling
	local shake_x = 0
	if player.shake_timer and player.shake_timer > 0 then
			shake_x = (rnd(2)-1)
			player.shake_timer -= 1
	end
	spr(player.spr, player.x+shake_x, player.y, player.w/8, player.h/8, player.flp)
	draw_enemies()

	draw_phase_bar()

	----- TEST -----
	if test then
		print("⬅️➡️ to move")
		print("❎ to jump, 🅾️ to dash")
		print("double jump:" .. tostring(player.double_jump))
		print("on wall left:" .. tostring(player.on_wall_left))
		print("on wall right:" .. tostring(player.on_wall_right))
	end

	print("score: " .. score, cam_x+1, cam_y+9)
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