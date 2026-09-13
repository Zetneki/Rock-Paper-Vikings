function _init()
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
		shake_timer=0,

  }

	music_patterns = {
		viking=0,
		cowboy=4,
		knight=8,
		wizard=12
	}

	wall_sprites = {
		viking=66,
		cowboy=68,
		knight=66,
		wizard=70
	}

	bg_sprites = {
		viking = {71, 72, 87, 88},
		wizard = {75, 76, 91, 92},
		knight = {73, 74, 89, 90},
		cowboy = {73, 74, 89, 90}
	}

	decoration_sprites = {114, 116, 118}

	music(music_patterns[player.spr_set])


	enemies = {}

	--- TEST -----
	--spawn_enemy(24,32,"knight")
	--spawn_enemy(88, 24, "wizard")
	--spawn_enemy(24,64,"cowboy")

	-- charater type timer
	phase = {
		duration=450,     -- 600 frame = 20mp at 30fps
		current=450,
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
		[0]=0,8,3,-7,4,9,-1,15,-15,1,-5,-13,13,-10,5,-11
	}}

	current_palette = palettes.base

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
end

function _update()
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
	end
end

function _draw() 
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