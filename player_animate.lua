p_spr_sets={
	-- each sprite set has a starter number
	-- sets are 11 long, values are the starter numbers for the key's character
	viking=1,
	wizard=12,
	knight=23,
	cowboy=34
}

function player_animate(char)

	local spr_s = p_spr_sets[char]

	if player.jumping then
		player.spr=spr_s+7
	elseif player.falling then
		player.spr=spr_s+8
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