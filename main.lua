function _init()
	poke(0x5f2e, 1) -- allows hidden colors
	poke(0x5f5c, 255) -- button press only activates once

	test = false

	gravity = 0.3
	friction = 0.85

  player = {	
		spr_set='viking',
		flp=false,
    x=1,
    y=1,
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

	extra_x = 0
	extra_y = 0


end

function _update()
	move()
	player_animate(player.spr_set)

	extra_x = max(0, ceil(abs(player.dx)) - 1)
	extra_y = max(0, ceil(abs(player.dy)) - 1)

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


	print(player.slamming)

	print(flr((player.y+player.h)/8))
	--print(player.dy-1)
	print(flr((player.y+player.h+extra_y)/8))
	--print(extra_y)

end


