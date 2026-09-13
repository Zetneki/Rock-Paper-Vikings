function update_gameover()
  if btnp(❎) then
		game_state = "menu"
	end
end

function draw_gameover()
  camera(0, 0)
  cls(0)
	print("game over", 45, 50, 8)
	print("score: "..score, 45, 60, 7)
	print("press ❎ to continue", 25, 80, 6)
end