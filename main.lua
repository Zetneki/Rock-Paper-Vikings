function _init()
	cartdata("rock_paper_wizards_v1")

	game_state = "menu"
	load_scoreboard()

	if high_score_name == "---" then
		init_name_entry()
		game_state = "enter_name"
	else
		player_name = high_score_name
		init_menu()
		game_state = "menu"
	end
end

function _update()
	if game_state == "menu" then
		update_menu()
	elseif game_state == "playing" then
		update_game()
	elseif game_state == "howto" then
		update_howto()
	elseif game_state == "gameover" then
		update_gameover()
	elseif game_state == "enter_name" then
		update_name_entry()
	elseif game_state == "scoreboard" then
		update_scoreboard()
	end
end

function _draw()
	if game_state == "menu" then
		draw_menu()
	elseif game_state == "playing" then
		draw_game()
	elseif game_state == "howto" then
		draw_howto()
	elseif game_state == "gameover" then
		draw_gameover()
	elseif game_state == "enter_name" then
		draw_name_entry()
	elseif game_state == "scoreboard" then
		draw_scoreboard()
	end
end


