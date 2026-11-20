# Alchemist's Apothecary – themed local prototype

A local presentation prototype of the COS10009 Ruby and Gosu potion-brewing project. The original three-level gameplay, ingredient values, scoring formula, gold, reputation and ten-order ending are preserved. An extra royal customer profile allows four separate Level 3 orders when the player's reputation is at least three.

## Run on Windows

1. Extract the entire ZIP into a separate folder, rather than overwriting the previous working version.
2. In VS Code, select File > Open Folder and select the extracted folder containing `alchemist.rb`.
3. Open Terminal > New Terminal and run:

```powershell
ruby -c alchemist.rb
(Get-Content alchemist.rb).Count
ruby alchemist.rb
```

Ruby and Gosu are the only runtime requirements. If Gosu is absent, use `gem install gosu`. Keep the `assets` and `sounds` directories, and all three text files, next to the Ruby file.

## Controls and new features

- Left mouse button: select shop items, brewing ingredients and navigation buttons.
- F11: toggle fullscreen (Gosu's built-in shortcut).
- M or Sound button: toggle audio. V: replay the current guide narration (when available).
- R: reset to the main menu. Escape: quit.
- Level 1 (orders 1–3): blue scenery, Witch guide, at least 2 ingredients. First-order narration suggests a valid recipe based on the selected customer.
- Level 2 (orders 4–6): green/teal castle scenery, Night Witch guide, at least 3 ingredients.
- Level 3 (orders 7–10): red scenery, Fire Wizard guide, at least 4 ingredients.
- Guides speak automatically only in the shop and brewing screen of the first order, and in the shop at the start of Levels 2 and 3. Otherwise they stand silently unless the player requests help. The optional How to Play screen retains its narration. Guides bob while speaking; background music is quieter during narration.
- Help costs 100 gold per customer order, reveals quantities for that customer, and can be replayed at no further cost until serving. Ingredient purchases remain separate. Nine recipes score 100%; Princess has a verified 98% recipe (the existing target is difficult to match exactly). Insufficient gold rejects help without charging.
- Happy results fade in a Night Witch heart emote; satisfied results fade in a Wizard; disappointed results fade in an Electric Wizard.
- Customers are selected without repeating previously selected eligible profiles until the available pool is exhausted. Consecutive duplicates are avoided when there is another eligible customer. Princess requires reputation 3, so a repeat is still possible if reputation is too low to unlock all four final-level profiles.
- The final results screen shows gold, reputation and average match score.

## Project structure

- `alchemist.rb`: complete Ruby source (990 lines in this delivery).
- `ingredients.txt`: six ingredient records; unchanged values.
- `customers.txt`: ten customer profiles, including a sprite filename field.
- `guide.txt`: nineteen subtitle records keyed to the matching WAV audio file.
- `assets/backgrounds/`: four background images.
- `assets/characters/`: fourteen transparent PNG illustrations cut from the supplied reference screenshots.
- `sounds/`: six sound effects, an original 40-second loop, and `voices/` containing the synthetic narration.

## Important art and audio credits

The character artwork, emote, and scenery originate from the reference screenshots supplied by the user on 20 November 2026 and depict or adapt Clash Royale / Supercell intellectual property. The original source URLs and licenses were not supplied and could not be verified. Transparency was created by masking the supplied screenshots; small residual edge artifacts may remain. This is not an official Supercell product. This acknowledgment does not grant a license. Supercell's Fan Content Policy specifically restricts creating games based on its assets and characters: https://supercell.com/en/fan-content-policy/. Do not publish or submit this artwork without confirming your rights and your course's third-party-asset rules. Replace these PNG/JPG assets with original or properly licensed fantasy art if necessary. Use only a local review copy pending permission; a private repository does not itself confer rights.

The instructional voice clips are synthetic English text-to-speech produced with Flite (female-style Witch voices and male-style Wizard voice), with slower pacing, filtering and compression (not official character voices or genuine voice acting). Music and six short sound effects were synthesized for this project. The program uses Gosu's Image, Sample, Song and Channel APIs. References: https://www.rubydoc.info/gems/gosu/Gosu/Image ; https://www.rubydoc.info/gems/gosu/Gosu/Sample ; https://www.rubydoc.info/gems/gosu/Gosu/Song ; https://www.rubydoc.info/gems/gosu/Gosu/Channel .

## Verification status

`ruby -c` reports Syntax OK. A headless Ruby test using a Gosu stand-in passed 160 checks, including all ten recipe scores, first-order narration, silent rounds and results, level introductions, help rejection and one-time charging, help persistence across screens, and completion. These checks do not prove actual Windows/Gosu rendering or audio playback; test locally. This version modifies the previously supplied ZIP, not an independently retrieved repository copy.

Suggested real-game tests: play the first order, check silent narration on order two, try Help with less than 100 gold, buy a recipe with sufficient gold, replay it without a second charge, return to the shop, and check the new-level introductions and silent results. Keep the old version as a backup.
