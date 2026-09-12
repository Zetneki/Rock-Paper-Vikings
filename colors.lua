-- change_palette_onpress()
--   if(btnp(⬆️)) then
--     current_palette = palettes.hidden
--   elseif(btnp(⬇️)) then
--     current_palette = palettes.normal
--   end
-- end

function change_ingame(palette)
  pal(palette)
end

function change_palette(palette)
  poke(0x5f2e, 1)
  pal(palette, 1)
end