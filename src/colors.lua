-- applies palette with secondary/display mapping (for background layer)
function change_palette(palette)
  poke(0x5f2e, 1)
  pal(palette, 1)
end