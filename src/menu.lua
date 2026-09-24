function init_menu()
  menu_selected = 1
  menu_options = {"start", "no enemy", "how to play", "high score", "change name"}
end

-- handles menu navigation and dispatches the selected option
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
      is_enemy = true
    elseif choice == "no enemy" then
      init_game()
      game_state = "playing"
      is_enemy = false
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

-- draws the menu list with the current selection highlighted
function draw_menu()
  camera(0, 0)
	pal()     
  cls(1)

  print("rock paper vikings", 30, 30, 7)

  for i, opt in ipairs(menu_options) do
    local y = 50 + (i-1)*10
    local col = (i == menu_selected) and 10 or 6
    local prefix = (i == menu_selected) and "> " or "   "
    print(prefix..opt, 30, y, col)
  end
end

function update_howto()
	if btnp(❎) then
		game_state = "menu"
	end
end

-- static how-to-play text screen
function draw_howto()
  camera(0,0)   
	pal()         
  cls(0)

  local y = 4
  local lh = 6  

  print("rock-paper-vikings", 4, y, 10) y+=lh+2
  
  print("controls:", 4, y, 9) y+=lh
  print("movement: ⬆️⬇️⬅️➡️", 4, y, 7) y+=lh
  print("(double) jump: (2x) ⬆️ // ❎", 4, y, 7) y+=lh
  print("dash: 2x tap ⬅️/➡️ // 🅾️+⬅️/➡️", 4, y, 7) y+=lh
  print("gives invulnerability", 4, y, 2) y+=lh
  print("resets on every new platform", 4, y, 3) y+=lh+1
  print("slam: 2x tap ⬇️ // 🅾️+⬇️", 4, y, 7) y+=lh
  print("kills right enemy, stuns others", 4, y, 2) y+=lh
  print("resets on normal(non-slam) kill", 4, y, 3) y+=lh+1
  print("wall-jump near walls", 4, y, 7) y+=lh+2

  print("who beats who:", 4, y, 9) y+=lh
  print("knight beats cowboy", 4, y, 7) y+=lh
  print("cowboy beats wizard", 4, y, 7) y+=lh
  print("wizard beats knight", 4, y, 7) y+=lh+2

  print("timer runs out - theme changes", 4, y, 6) y+=lh
  print("jump on the right enemy to kill", 4, y, 6) y+=lh
  print("killing gives you points", 4, y, 6) y+=lh+2

  print("❎: back to menu", 4, y, 5)
end