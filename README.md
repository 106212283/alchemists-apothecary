# Alchemist's Apothecary – themed local prototype

A local presentation prototype of the COS10009 Ruby and Gosu potion-brewing project. The original three-level gameplay, ingredient values, match-scoring formula, reputation and ten-order ending are preserved, with a perfect-potion gold bonus and new challenge rules. An extra royal customer profile allows four separate Level 3 orders when the player's reputation is at least three.

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
- M: toggle all audio. The Music and SFX buttons independently control background music and sound effects (including narration). V: replay the current guide narration (when available).
- R: reset to the main menu. Escape: quit.
- Level 1 (orders 1–3): blue scenery, Witch guide, at least 2 ingredients. First-order narration suggests a valid recipe based on the selected customer.
- Level 2 (orders 4–6): green/teal castle scenery, Night Witch guide, at least 3 ingredients.
- Level 3 (orders 7–10): red scenery, Fire Wizard guide, at least 4 ingredients.
- Automatic instructional narration starts at the workbench for the first order and at the beginning of Levels 2 and 3, with an extra brewing instruction on the first order. Level 2 explains the 60-second timer and Level 3 explains the 30-second timer. Otherwise the guide does not give unsolicited instructions; the player can request help. The guide also gives a short spoken reaction on perfect, happy and disappointed results, while satisfied results have no spoken reaction. Each reaction plays once when the results screen is entered. The optional How to Play screen has narration. Guides bob while speaking; background music is quieter during narration.
- Help costs 100 gold per customer order, reveals quantities for that customer, and can be replayed at no further cost until serving. Ingredient purchases remain separate. Nine recipes score 100%; Princess has a verified 98% recipe (the existing target is difficult to match exactly). Insufficient gold rejects help without charging.
- Happy results fade in a Night Witch heart emote; satisfied results fade in a Wizard; disappointed results fade in an Electric Wizard.
- Customers are selected without repeating previously selected eligible profiles until the available pool is exhausted. Consecutive duplicates are avoided when there is another eligible customer. Princess requires reputation 3, so a repeat is still possible if reputation is too low to unlock all four final-level profiles.
- Customer patience: Level 1 is untimed; Level 2 gives 60 seconds and Level 3 gives 30 seconds per order. The clock starts on the first click of Start Brewing for each timed order and continues if the player visits the shop. At zero, the customer leaves, the order earns 0% and no gold, reputation falls by one (minimum zero), and ingredients still in the cauldron are consumed. Continue to the next customer from the results screen.
- Star ratings: happy (80–100%) = 3 small gold star images, satisfied (50–79%) = 2, and disappointed (0–49%) = 1. The gold stars are rendered using the supplied star artwork on a transparent background, rather than relying on text glyphs. A timed-out order receives one star and a 0% match.
- A perfect 100% potion earns 15 bonus gold in addition to the customer's base payment. Lower scores use the original payment formula.
- Win by completing ten orders with a rounded average match score of at least 80%; otherwise the final screen shows a loss. A timeout counts as an order. Restart or play again if needed.
- High score: the best rounded average over completed games is shown on the menu and final results. It persists in `high_score.txt`, created/updated when a new positive record is set. Keep the game in a writable folder.

## Project structure

- `alchemist.rb`: complete Ruby source (990 lines in this delivery).
- `ingredients.txt`: six ingredient records; unchanged values.
- `customers.txt`: ten customer profiles, including a sprite filename field.
- `guide.txt`: twenty-eight subtitle records keyed to the matching WAV audio file.
- `high_score.txt`: generated locally on a new positive record; not required before running.
- `assets/backgrounds/`: four background images.
- `assets/characters/`: fourteen character PNG illustrations from the supplied screenshots, plus the new transparent gold star sprite.
- `sounds/`: six general sound effects, two generated countdown ticks (`tick.wav` and `tick_urgent.wav`), an original background loop, and `voices/` with the 28 supplied narration and reaction clips.

## Important art and audio credits

The character artwork, emote, and scenery originate from the reference screenshots supplied by the user on 20 November 2026 and depict or adapt Clash Royale / Supercell intellectual property. The original source URLs and licenses were not supplied and could not be verified. Transparency was created by masking the supplied screenshots; small residual edge artifacts may remain. This is not an official Supercell product. This acknowledgment does not grant a license. Supercell's Fan Content Policy specifically restricts creating games based on its assets and characters: https://supercell.com/en/fan-content-policy/. Do not publish or submit this artwork without confirming your rights and your course's third-party-asset rules. Replace these PNG/JPG assets with original or properly licensed fantasy art if necessary. Use only a local review copy pending permission; a private repository does not itself confer rights.

The `sounds/voices/` WAV files were provided by the user, with the Level 2 and Level 3 introduction clips replaced on this update. The voice recordings are not official character voices. The countdown ticks are locally synthesised sound effects (no additional runtime dependencies). The gold star sprite is extracted from the additional reference supplied by the user; its original source and license are unverified. Music and six short sound effects were synthesized for this project. The program uses Gosu's Image, Sample, Song and Channel APIs. References: https://www.rubydoc.info/gems/gosu/Gosu/Image ; https://www.rubydoc.info/gems/gosu/Gosu/Sample ; https://www.rubydoc.info/gems/gosu/Gosu/Song ; https://www.rubydoc.info/gems/gosu/Gosu/Channel .

## Verification status

`ruby -c` reports Syntax OK. The updated Ruby source remains under 1,000 physical lines, including descriptive section comments. Repeated setup, drawing and click-handling code was consolidated. Headless tests using a Gosu stand-in passed 160 regression checks and 46 additional checks covering star thresholds, the bonus, timed levels, timeout behavior, visiting the shop, audio settings, win/loss screens, persistent high score and restart. A further 81 headless checks verified mentor feedback for the score categories at each level, correct star sprite counts, no repeated frame-triggered reactions, timer narration and muted playback. All 28 WAV files and the transparent star sprite were inspected for valid file structure. These checks do not verify actual Windows/Gosu rendering, audible voice quality or playback. This version modifies the previously supplied ZIP rather than an independently retrieved repository copy. The previous customer and ingredient data, character art, backgrounds, background music and sound effects are preserved; the new introductory voice recordings and timer narration are replaced, while all prior characters and gameplay remain.

Suggested real-game tests: check independent audio buttons and first-order narration; serve a perfect potion; test the Level 2 and 3 timers, including visiting the shop and letting time run out; check all star ratings; complete a winning and a losing run; restart the program and verify that the best average remains. Keep the old version as a backup. Listen to the revised guides, check the result reactions at each level and verify that the right number of gold star images appears.

## New room navigation and voice differences

- **Workbench** is the home screen for each customer. Select **Visit Shop** to open the separate royal ingredient shop, then **Return to Workbench** to prepare the potion. Click **Start Brewing** at the workbench to begin mixing.
- The brewing screen has a **Visit Shop** button for restocking. **Return to Brewing** preserves ingredients already mixed; any active 60-second or 30-second timer continues running while shopping.
- The shop has its own `assets/backgrounds/shop.jpg` illustration and on-screen room title. The inventory cards are reused to avoid duplicating shopping logic.
- The 28 guide audio files are supplied recordings, not word-by-word synthetic clips. The new Level 2 and Level 3 welcome recordings announce 60 and 30 seconds respectively.
- The original gameplay, stars, paid recipe help, reactions, high scores and sound controls remain. Audio quality should be checked on the player's Windows machine.

**Copyright note:** The character images are third-party game fan art. Check the rights and your institution's rules before publicly sharing the artwork, voice associations or source repository.

## Source code organisation (refactored version)

The main `alchemist.rb` file is shorter and uses section comments to explain its components: constants and data records; reading the external ingredient/customer/guide files; the game rules and scoring; window setup and voice/music loading; drawing each scene; mouse/keyboard handling. Ingredient/customer parsing now shares one `load_records` helper, potion values use one attribute loop, and repeated list-building code uses Ruby collections. Existing file formats, screen navigation, voice files and scoring rules have not been changed. The main file has 990 lines.


## Custom in-game font

The game's headings, buttons, subtitles, customer dialogue, and score labels use the supplied **Clash Bold** font, stored at `assets/fonts/Clash_Bold.otf`. Font sizes were adjusted slightly to improve fit. The font is loaded from a relative path, so it travels with the game; no Windows font installation is needed. The image artwork itself is unchanged.


## Custom character narration (28 recordings)
The 28 files in `sounds/voices/` have been replaced with the supplied final WAV recordings: indices 0–12 for Purple Witch, 13–19 for Night Witch, and 20–27 for Wizard. See `VOICE_FILE_MAPPING.txt`. No game code or other assets were changed.

## Final programming enhancement — history, scoring explanation and evidence

- Press **H** or click **History (H)** in the top bar while on the workbench or a result screen to review completed customer orders. The history lists customer name, score, stars, gold earned, customer mood and cumulative average. History resets for each new game.
- On a results screen, click **Score Details (D)** or press **D** for a breakdown of the four potion properties, customer targets and absolute differences. The exact original scoring formula is shown. A timeout correctly reports that no potion was served.
- Press the on-screen **Return to Game** button to close either review screen. These read-only screens do not change your gold, inventory, customer progression or timer.
- Run `ruby tests/test_game.rb` for headless automated checks, and `ruby tests/scoring_experiment.rb` to recreate `docs/scoring_experiment.csv` from the real ingredients and customers.
- See `docs/HD_TESTING_AND_REFLECTION.md` for the test results, manual verification checklist, explanation of the data structures and suggestions for genuine submission evidence.
- **Code length:** the main `alchemist.rb` contains 990 physical lines with section comments. The external test scripts are not loaded by the game.
- **Evidence limitation:** automated tests passed on the included sample data, but actual Gosu window rendering, font fit, narration playback, and a complete ten-order Windows playthrough must still be verified on the student's own machine. HD cannot be guaranteed.

## Final countdown update (22 November 2026)

- **Level 1:** no countdown. **Level 2:** 60 seconds. **Level 3:** 30 seconds.
- Timer begins on **Start Brewing** and keeps counting if you visit the shop.
- A quiet wooden-clock tick plays once per displayed second. At **15 seconds remaining** it changes to a louder, sharp double-tick until the countdown ends.
- Ticks respect the **SFX OFF** button and M mute shortcut; they do not play during untimed Level 1 or after an order ends.
- `sounds/voices/welcome_2.wav` and `welcome_3.wav` are replaced by the two updated recordings supplied by the user; `guide.txt` subtitles use the same durations. All 26 other voice clips are retained.
- Run `ruby tests/test_game.rb`, `ruby tests/test_timer_sound.rb`, and `ruby tests/scoring_experiment.rb` for reproducible headless verification. Actual sound quality and screen behaviour need testing on a PC with Gosu installed.
- The main Ruby file is **990 physical lines**, with section comments preserved and an unused constants block removed.
