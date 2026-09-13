function load_scoreboard()
	high_score = dget(0)   

	high_score_name = ""
	for i=1,8 do
		local code = dget(i)  
		if code > 0 then
			high_score_name = high_score_name .. chr(code)
		end
	end

	if high_score_name == "" then
		high_score_name = "---"
	end
end

function save_scoreboard(name, sc)
	dset(0, sc)
	for i=1,8 do
		local ch = sub(name, i, i)
		if ch ~= "" then
			dset(i, ord(ch))
		else
			dset(i, 0)
		end
	end
end

function update_scoreboard()
	if btnp(❎) then
		game_state = "menu"
	end
end

function draw_scoreboard()
	camera(0,0)
	pal()
	cls(0)
	print("high score", 40, 40, 10)
	print(high_score_name .. ": " .. high_score, 30, 55, 7) 
  
  print("playing as:", 25, 70, 6)
	print(player_name, 25, 80, 9)
  
	print("❎: back", 45, 100, 6)
end