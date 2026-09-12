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
    x=140,
    y=500,
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
  }

	palettes={
		base = {
		[0]=-14,2,3,-7,4,-2,-1,15,-15,
		1,-3,-13,13,-10,5,-11
	}}

	current_palette = palettes.base

	-- cam_x=0
	cam_y=0

	map_start=128
	map_end=256
	map_ceiling=1024
	map_floor=1
	camera_min_y = map_floor
	camera_locked = false

	score=0
	last_height=1000



	generate_platforms(
		map_start, map_end,   -- x tartomány pixelben (vagy tile*8)
		0, 511,          -- y tartomány: kezdő magasság -> plafon
		66,                        -- wall_spr — állítsd a saját fal sprite indexedre
		18, 24,                    -- min/max függőleges rés (a 26.7px max ugrás alatt marad)
		3, 6,                       -- platform hossza 3-6 tile között
		0.4
	)
end

function _update()
	move()
	player_animate(player.spr_set)

	if last_height-player.y > 50 then
		last_height = player.y
		score+=10
	end

  update_camera()
end

function _draw() 
  cls()
  map(0,0)
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


