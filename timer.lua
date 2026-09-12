function update_phase()
	phase.current -= 1

	if phase.current <= 0 then
		phase.char_index = phase.char_index % 4 + 1
		phase.current = phase.duration

		player.spr_set = phase.beats[phase.char_index]
		player.spr = p_spr_sets[player.spr_set]
		player.anim = time()         
	end
end

function draw_phase_bar()

	local dot_size=5
	local gap=3
	local origin_x=64 - flr(phase.dot_count*(dot_size+gap)/2)
	local origin_y=2

	local col
	if phase.char_index==1 then col=8
	elseif phase.char_index==2 then col=12
	elseif phase.char_index==3 then col=11
	else col=9 end

	local progress = 1 - (phase.current / phase.duration)
	local exact_pos = progress * phase.dot_count

	for i=0,phase.dot_count-1 do
		local visual_i = phase.dot_count-1-i
		local dx = origin_x + visual_i*(dot_size+gap)
		local dy = origin_y
		local cx = dx + flr(dot_size/2)
		local cy = dy + flr(dot_size/2)
		local arm = flr(dot_size/2)

		if i < flr(exact_pos) then
			pset(cx, cy, col)

		elseif i == flr(exact_pos) then
			local local_t = exact_pos - i

			if local_t < 0.33 then
				rectfill(dx, dy, dx+dot_size-1, dy+dot_size-1, col)
			elseif local_t < 0.66 then
				draw_cross(cx, cy, max(1, flr(arm/2)), col)
			else
				pset(cx, cy, col)
			end

		else
			rectfill(dx, dy, dx+dot_size-1, dy+dot_size-1, col)
		end
	end

end

function draw_cross(cx, cy, arm, col)
	line(cx-arm, cy, cx+arm, cy, col)
	line(cx, cy-arm, cx, cy+arm, col)
end