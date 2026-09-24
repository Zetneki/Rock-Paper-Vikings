# Rock Paper Vikings

A vertical platformer for [PICO-8](https://www.lexaloffle.com/pico-8.php). Climb as high as you can, dodge or defeat enemies, and survive as your character class keeps changing on you. The game was created for the [2026 PICO-8 Jam](https://picojam.hu/) and was completed afterwards.

## Concept

Every run, your character cycles between four classes on a timer: **viking**, **knight**, **wizard**, and **cowboy**. Each class beats exactly one enemy type (and loses to another) except for the viking, who beats noone. Rock-paper-scissors style:

- Knight beats Cowboy
- Cowboy beats Wizard
- Wizard beats Knight
- Viking beats nobody, but everybody beats Viking

Land on an enemy while you're the class that beats them to kill it and bounce upward. Land on the wrong one and it's game over. The class you're playing as changes automatically over time, so you constantly have to reassess who's safe to fight.

The level itself scrolls upward and is generated procedurally as you climb, and past a certain score the camera starts auto-scrolling, forcing you to keep moving.

## Controls

| Action             | Input                                        |
| ------------------ | -------------------------------------------- |
| Move               | Arrow keys                                   |
| Jump / double jump | Up (double-tap) or X                         |
| Dash               | Double-tap left/right, or hold O + direction |
| Slam               | Double-tap down, or hold O + down            |
| Wall-jump          | Up/X while sliding against a wall            |

Dash grants brief invulnerability and resets whenever you land on a new platform. Slam lets you crash downward: it kills the enemy type you beat and stuns the others in a small area, and resets on a normal (non-slam) kill.

## Enemy types

- **Knight** — waits for you to get close, then telegraphs and leaps at you.
- **Wizard** — orbits its spawn point, then breaks off to chase you if you get close.
- **Cowboy** — pulls you toward it from range once you're in its reach; break free with alternating left/right taps before time runs out.

## Game modes

- **Start** — the normal run, with enemies. Scores here count toward the high score.
- **No enemy** — a pure platforming run with no combat. Not ranked; scores from this mode are never saved.

## Scoring

Points come from climbing height and from enemy kills. Kills award a bonus that's shown as a temporary "+N" next to your score before merging into the total.

## Running it

Open `rock_paper_vikings.p8` in PICO-8:

```
load rock_paper_vikings.p8
run
```

Or run the exported version directly:

- **Native**: run the exported `.bin` for your platform.
- **Web**: open the exported `game.html` in a browser (or host it, e.g. via GitHub Pages).

## Building / exporting

From the PICO-8 console, with the cart loaded:

```
press F7         -- captures the current screen as the cart's thumbnail
export game.html -- web build (game.html + game.js)
export game.bin  -- native build
```

## Project structure

```
src/     -- individual .lua source files, split by system
build/   -- the merged, single-file .p8 used for running/exporting and the exported files
```

## Credits

Built solo in PICO-8 Lua.

## License

MIT
