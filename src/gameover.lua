function update_gameover()
  if btnp(❎) then
		game_state = "menu"
	end
end

-- shows final score; no-enemy runs get an extra "not ranked" notice
function draw_gameover()
  camera(0, 0)
  cls(0)

	if not is_enemy then
		print("game over", 45, 40, 8)
		print("score: "..score, 45, 50, 7)

		print("no enemy mode - not ranked", 15, 70, 7) 
		print("score is not saved", 30, 80, 7)

		print("press ❎ to continue", 25, 100, 6)
		return
	end

	print("game over", 45, 50, 8)
	print("score: "..score, 45, 60, 7)

	print("press ❎ to continue", 25, 80, 6)
end