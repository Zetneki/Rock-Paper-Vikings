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
    x=140, y=500,
		w=8, h=8,
    dy=0, dx=0,
		max_dx=4, max_dy=6,
		acc=0.4, boost=4,
		anim=0,
		running=false, jumping=false, falling=false, sliding=false, landed=false,
		dash_act_time=0, dash_ready_l=false, dash_ready_r=false, 
		dashing=false, dash_timer=0, max_dash_dx = 6, dash_speed=6,
		slam_act_time=0, slam_ready=false, slamming=false, slam_max_dy=14,
		jump_held=false, double_jump=true,
		on_wall_left=false, on_wall_right=false,
  }

	palettes={
		base = {
		[0]=-14,2,3,-7,4,-2,-1,15,-15,
		1,-3,-13,13,-10,5,-11
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

	generate_chunk(64, 0, map_start, map_end, 65, 18, 24, 3, 6, 0.4)
	world_generated_up_to = 0

	ensure_spawn_platform(player.x, player.y, 65, 66)
end

function _update()
	move()
	player_animate(player.spr_set)

	if last_height-player.y > 50 then
		last_height = player.y
		score+=10
	end

  update_camera()

	local player_ty = flr(player.y/8)

	if player_ty < world_generated_up_to + trigger_buffer then
		local new_top = world_generated_up_to - chunk_height
		generate_chunk(world_generated_up_to, new_top, map_start, map_end, 65, 18, 24, 3, 6, 0.4)
		world_generated_up_to = new_top
	end
end

function _draw() 
  cls()
  draw_world_wrapped(cam_x, cam_y) 
	change_palette(current_palette)
  spr(player.spr,player.x,player.y,player.w / 8,player.h / 8,player.flp)	

	----- TEST -----
	if test then
		print("⬅️➡️ to move")
		print("❎ to jump, 🅾️ to dash")
		print("double jump:" .. tostring(player.double_jump))
		print("on wall left:" .. tostring(player.on_wall_left))
		print("on wall right:" .. tostring(player.on_wall_right))
	end

	print("score: " .. score, cam_x, cam_y)
end


