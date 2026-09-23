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

	player_name = load_last_player_name()
	if player_name == "" then
		player_name = "---"
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
  
  print("playing as:", 30, 70, 6)
	print(player_name, 32, 80, 9)
  
	print("❎: back", 30, 100, 6)
end

function save_last_player_name(name)
    for i=1,8 do
        local ch = sub(name, i, i)
        dset(8+i, ch ~= "" and ord(ch) or 0)
    end
end

function load_last_player_name()
    local n = ""
    for i=1,8 do
        local code = dget(8+i)
        if code > 0 then n = n .. chr(code) end
    end
    return n
end