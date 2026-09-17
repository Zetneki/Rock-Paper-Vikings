function init_menu()
  menu_selected = 1
  menu_options = {"start", "how to play", "high score", "change name"}
end

function update_menu()
	if btnp(⬆️) then
		menu_selected -= 1
		if menu_selected < 1 then menu_selected = #menu_options end
	end
	if btnp(⬇️) then
		menu_selected += 1
		if menu_selected > #menu_options then menu_selected = 1 end
	end

	if btnp(❎) then
		local choice = menu_options[menu_selected]
		if choice == "start" then
			init_game()
			game_state = "playing"
		elseif choice == "how to play" then
			game_state = "howto"
		elseif choice == "high score" then
			game_state = "scoreboard"
		elseif choice == "change name" then
			init_name_entry()
			game_state = "enter_name"
		end
	end
end

function draw_menu()
  camera(0, 0)
	pal()     
  cls(1)

  print("rock paper wizards", 40, 30, 7)

  for i, opt in ipairs(menu_options) do
    local y = 60 + (i-1)*10
    local col = (i == menu_selected) and 10 or 6
    local prefix = (i == menu_selected) and "> " or "  "
    print(prefix..opt, 40, y, col)
  end
end

function update_howto()
	if btnp(❎) then
		game_state = "menu"
	end
end

function draw_howto()
  camera(0,0)   
	pal()         
  cls(0)

  local y = 4
  local lh = 6  

  print("rock-paper-wizards", 4, y, 10) y+=lh+2
  print("the ultimate climbing game", 4, y, 6) y+=lh+2

  print("controls:", 4, y, 9) y+=lh
  print("arrows: move", 4, y, 7) y+=lh
  print("2x tap up: jump", 4, y, 7) y+=lh
  print("2x tap l/r: dash", 4, y, 7) y+=lh
  print("dash gives invulnerability", 4, y, 2) y+=lh
  print("2x tap down: slam", 4, y, 7) y+=lh
  print("wall-jump near walls", 4, y, 7) y+=lh+3

  print("type cycle:", 4, y, 9) y+=lh
  print("knight beats cowboy", 4, y, 7) y+=lh
  print("cowboy beats wizard", 4, y, 7) y+=lh
  print("wizard beats knight", 4, y, 7) y+=lh+3

  print("your type switches", 4, y, 6) y+=lh
  print("when the music switches", 4, y, 6) y+=lh
  print("match it to survive enemies", 4, y, 6) y+=lh+3

  print("❎: back to menu", 4, y, 5)
end