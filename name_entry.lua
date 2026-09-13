function init_name_entry()
	name_chars = "abcdefghijklmnopqrstuvwxyz"
	name_input = {1,1,1}   
	name_cursor = 1
end

function update_name_entry()
	if btnp(⬅️) then
		name_cursor = max(1, name_cursor - 1)
	end
	if btnp(➡️) then
		name_cursor = min(3, name_cursor + 1)
	end
	if btnp(⬆️) then
		name_input[name_cursor] -= 1
		if name_input[name_cursor] < 1 then name_input[name_cursor] = #name_chars end
	end
	if btnp(⬇️) then
		name_input[name_cursor] += 1
		if name_input[name_cursor] > #name_chars then name_input[name_cursor] = 1 end
	end

	if btnp(❎) then
		local final_name = ""
		for i=1,3 do
			final_name = final_name .. sub(name_chars, name_input[i], name_input[i])
		end
		player_name = final_name
		init_menu()
		game_state = "menu"
	end

	if btnp(🅾️) then   
		init_menu()
		game_state = "menu"
	end
end

function draw_name_entry()
	camera(0,0)
	pal()
	cls(0)
	print("enter your name", 30, 30, 7)

	for i=1,3 do
		local ch = sub(name_chars, name_input[i], name_input[i])
		local col = (i == name_cursor) and 10 or 7
		print(ch, 55 + (i-1)*10, 60, col)
	end

	print("arrows: select/change", 8, 90, 6)
	print("❎: confirm   🅾️: cancel", 8, 100, 6)
end