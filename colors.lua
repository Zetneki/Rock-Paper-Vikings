function change_ingame(palette)
  pal(palette)
end

function change_palette(palette)
  poke(0x5f2e, 1)
  pal(palette, 1)
end