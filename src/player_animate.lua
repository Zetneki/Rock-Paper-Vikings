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