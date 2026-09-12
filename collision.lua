function collide(obj, aim, flag)
	local x = obj.x
	local y = obj.y
	local w = obj.w
	local h = obj.h

	local x1,y1,x2,y2 = 0,0,0,0

	local extra_x = ceil(abs(obj.dx)) - 1
	local extra_y = ceil(abs(obj.dy)) - 1

	if aim=="left" then
		x1=x-1  y1=y
		x2=x-1  y2=y+h-1

		if extra_x > 0 then
        x1 -= extra_x
        x2 -= extra_x
    end

	elseif aim=="right" then
		x1=x+w    y1=y
		x2=x+w    y2=y+h-1

		if extra_y > 0 then
        x1 += extra_y
        x2 += extra_y
    end
		
	elseif aim=="up" then
		x1=x    y1=y-1
		x2=x+w-1  y2=y-1

		if extra_y > 0 then
        y1 -= extra_y
        y2 -= extra_y
    end
		
	elseif aim=="down" then
		x1=x      y1=y+h
		x2=x+w-1  y2=y+h

		if extra_y > 0 then
				y1 += extra_y
				y2 += extra_y
		end

	end

	------ TEST ------
	-- x1r=x1
	-- y1r=y1
	-- x2r=x2
	-- y2r=y2
	------------------

	local tx1=flr(x1/8)
	local ty1=flr(y1/8)
	local tx2=flr(x2/8)
	local ty2=flr(y2/8)

	if fget(mget(tx1,ty1),flag)
	or fget(mget(tx2,ty2),flag)
	or fget(mget(tx1,ty2),flag)
	or fget(mget(tx2,ty1),flag) then
		return true, tx1, ty1
	else
		return false
	end

end