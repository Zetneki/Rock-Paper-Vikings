score-alapú spawn esély (spawn_chance = min(0.6, 0.3 + score/2000) jellegű módosítás a meglévő sorban) — kb. 15-20 token, szinte semmi, mert csak egy kifejezést cserélsz ki.

kill bónusz score, ami külön kiírva "összeadódik" majd egyesül — ez a drágább rész, mert kell hozzá state: pl. score_popup=0, score_popup_timer=0, és a print logikának két ágra kell bomlania (popup aktív / nincs). Realisztikusan 50-80 token, a pontos megvalósítástól függően (animáció bonyolultsága számít).

alternatív gombok (❎ ugrás már megvan, 🅾️+irány dash, 🅾️+le slam) — a dash() és slam() feltételeit kell kiegészíteni btn(🅾️)-vel vagy-kapcsolattal. Kb. 25-40 token, mert csak plusz feltételeket kell hozzáfűzni a meglévő elágazásokhoz.

howto szövegbővítés — minden új print() sor kb. 5-6 token (a print, a string, két koordináta, egy szín). Ha 4-6 új sort tervezel, az 20-35 token.

ha marad hely enemy mentes mod
