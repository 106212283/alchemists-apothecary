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
- M or Sound button: toggle audio. V or Replay Voice: replay the current guide narration.
- R: reset to the main menu. Escape: quit.
- Level 1 (orders 1–3): blue scenery, Witch guide, at least 2 ingredients. First-order narration suggests a valid recipe based on the selected customer.
- Level 2 (orders 4–6): green/teal castle scenery, Night Witch guide, at least 3 ingredients.
- Level 3 (orders 7–10): red scenery, Fire Wizard guide, at least 4 ingredients.
- Guides bob while voice audio is playing. They have subtitles and a replay button; starting another screen stops the previous voice. The background music is quieter during narration.
- Happy results fade in a Night Witch heart emote; satisfied results fade in a Wizard; disappointed results fade in an Electric Wizard.
- Customers are selected without repeating previously selected eligible profiles until the available pool is exhausted. Consecutive duplicates are avoided when there is another eligible customer. Princess requires reputation 3, so a repeat is still possible if reputation is too low to unlock all four final-level profiles.
- The final results screen shows gold, reputation and average match score.

## Project structure

- `alchemist.rb`: complete Ruby source (978 lines in this delivery).
- `ingredients.txt`: six ingredient records; unchanged values.
- `customers.txt`: ten customer profiles, including a sprite filename field.
- `guide.txt`: twenty-seven subtitle records keyed to the matching WAV audio file.
- `assets/backgrounds/`: four background images.
- `assets/characters/`: fourteen transparent PNG illustrations cut from the supplied reference screenshots.
- `sounds/`: six sound effects, an original 40-second loop, and `voices/` containing the synthetic narration.

## Important art and audio credits

The character artwork, emote, and scenery originate from the reference screenshots supplied by the user on 20 November 2026 and depict or adapt Clash Royale / Supercell intellectual property. The original source URLs and licenses were not supplied and could not be verified. Transparency was created by masking the supplied screenshots; small residual edge artifacts may remain. This is not an official Supercell product. This acknowledgment does not grant a license. Supercell's Fan Content Policy specifically restricts creating games based on its assets and characters: https://supercell.com/en/fan-content-policy/. Do not publish or submit this artwork without confirming your rights and your course's third-party-asset rules. Replace these PNG/JPG assets with original or properly licensed fantasy art if necessary. Use only a local review copy pending permission; a private repository does not itself confer rights.

The instructional voice clips are synthetic English text-to-speech produced with Flite (not official character voices or genuine voice acting). Music and six short sound effects were synthesized for this project. The program uses Gosu's Image, Sample, Song and Channel APIs. References: https://www.rubydoc.info/gems/gosu/Gosu/Image ; https://www.rubydoc.info/gems/gosu/Gosu/Sample ; https://www.rubydoc.info/gems/gosu/Gosu/Song ; https://www.rubydoc.info/gems/gosu/Gosu/Channel .

## Verification status

`ruby -c` reports Syntax OK. A headless Ruby test using a lightweight Gosu stand-in completed 140 assertions before a final successful Play Again reset check; the simulated ten-order run scored 99% average, with 368 gold and reputation 10. These are automated logic checks, not screenshots or proof of actual Gosu graphics/audio output. Actual Windows/Gosu rendering, sound playback, text fit, and performance must be tested locally. This prototype is based on the last full source version shared in the conversation, not an independently retrieved repository copy.

Suggested real-game test order: click How to Play; play the first order with the suggested recipe; replay narration and mute/unmute; test a locked purchase and an empty potion; verify happy/satisfied/disappointed reactions; check levels 2 and 3 backgrounds and new guide voices; serve ten orders; check Play Again and Main Menu. Capture fresh evidence only after these tests pass and keep the previous report/screenshots as the earlier development record.
