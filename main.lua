function _init()
	poke(0x5f2e, 1)
	poke(0x5f5c, 255)

	gravity = 0.3
	friction = 0.85

  player = {	
		spr=3,
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
		dash_timer=0,
		max_dash_dx = 6,
		dash_speed=6,
		jump_held=false,
		double_jump=true,
		on_wall_left=false,
		on_wall_right=false,
  }

	----- TEST -----

	-- x1r, x2r, y1r, y2r = 0,0,0,0

	----------------

	palettes={
  normal = {
		[0]=0, 1, 2, 3, 4, 5, 6, 7,
		8, 9, 10, 11, 12, 13, 14, 15
  },
  ice = {
		[0]=0, 1, 2, 3, 4, 5, 6, 7,
		12, 12, 13, 13, 14, 15, 15, 15
  },
	lava = {
		[0]=0, 1, 2, 3, 4, 5, 6, 7,
		8, 8, 9, 9, 10, 10, 11, 8
  },
		hidden = {
		[0]=-14,2,3,-7,4,-2,-1,15,-15,
		1,-3,-13,13,-10,5,-11
	}}

	current_palette = palettes.hidden

end

function _update()
	move()
	player_animate()
end

function _draw() 
  cls()
  map(0,0)
	change_palette(current_palette)
  spr(player.spr,player.x,player.y,player.w / 8,player.h / 8,player.flp)	
	print("⬅️➡️ to move")
	print("❎ to jump, 🅾️ to dash")
	print("double jump:" .. tostring(player.double_jump))
	print("on wall left:" .. tostring(player.on_wall_left))
	print("on wall right:" .. tostring(player.on_wall_right))
	----- TEST -----
	-- rectfill(x1r,y1r,x2r,y2r,7)
	----------------
end


