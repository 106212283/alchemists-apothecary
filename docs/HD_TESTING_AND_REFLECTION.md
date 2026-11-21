# Alchemist's Apothecary — HD Evidence and Test Notes

## Scope of the final enhancement

The game retains its existing three levels, customer queue, ingredient shop, mixing, scoring, reputation, stars, challenge timers, Clash Bold font and the 28 user-supplied voice recordings. The final enhancement concentrates on **programming and explainability** rather than adding decorative assets:

1. **Order history:** After every served or timed-out order, the program appends a compact record to an array. The history displays customer, score, stars, payment, mood, running average and number of orders completed. Choose **History (H)** in the header while at the workbench or results screen, or press **H**. Use **Return to Game** to close. The record is intentionally session-only; a new game starts with empty history while the best-average high score remains persistent.
2. **Score details:** After serving, choose **Score Details (D)** or press **D**. The screen compares the four averaged potion properties with the customer target, shows the absolute difference for each property and explains the formula. Timeouts correctly display that no potion was served.
3. **Automated tests:** `ruby tests/test_game.rb` checks loading of external data, starting resources, level thresholds, potion score and bonus, insufficient stock, inventory restoration, history capture, snapshot preservation, timeout entries, and review navigation.
4. **Reproducible algorithm experiment:** `ruby tests/scoring_experiment.rb` enumerates combinations at the *minimum* ingredient count for three selected customers. Results are exported to `docs/scoring_experiment.csv` rather than inventing test results. The experiment deliberately ignores affordability/unlock state to isolate the matching function. These rankings are not a claim that the recipes are the best affordable recipes or the best with an unrestricted number of ingredients.

## Algorithm explanation

A mixed potion's heat, calm, energy, and bitterness are independently averaged across selected ingredients and rounded. The sum of absolute differences from the customer targets is multiplied by 2.5, subtracted from 100, rounded, and floored at 0. Happy is a score of 80–100, satisfied is 50–79, and disappointed is below 50. The star rating uses 3, 2 or 1 respectively. Exactly 100% awards an additional 15 gold.

The properties recorded for the details screen are a `.dup` snapshot when serving. Without the snapshot, resetting the cauldron for the next order would destroy the values required to explain the result. The history stores *data* rather than rendered text, so the UI can independently format its rows.

## Executed automated checks

Run from the project directory:

```powershell
ruby -c alchemist.rb
ruby tests/test_game.rb
ruby tests/scoring_experiment.rb
ruby alchemist.rb
```

The headless tests use a minimal substitute for Gosu graphics objects, so they validate **game logic and review navigation only**. They do not prove that images and fonts render correctly in the actual window or that every audio cue sounds right. Capture **your own** real screenshots for visual assessment and listen to the character recordings. The project does not include fabricated screenshots or play-test observations.

## Manual acceptance checklist — mark after running on Windows

| Scenario | Expected outcome | Evidence to capture |
|---|---|---|
| Launch from extracted folder | Menu appears with Clash Bold text and images | Menu screenshot |
| Visit shop, buy ingredient, return | Gold and stock update; back button returns to workbench | Shop screenshot |
| Brew a perfect customer potion | Result score 100%, three stars, +15 bonus gold | Results screenshot |
| Select Score Details or D | Four properties, targets, differences and formula appear | Details screenshot |
| Select History (H) after serving | One recorded order with score, stars, gold and mood | History screenshot |
| Serve a second customer | History shows two rows and updated average | History screenshot |
| Clear cauldron | Removed ingredients return to inventory | Before/after observation |
| Level 2 customer | 60-second timer starts only when brewing begins | Timer screenshot |
| Level 3 customer | 30-second timer starts only when brewing begins | Timer screenshot |
| Return to shop during brewing | Active countdown continues; recipe ingredients remain | Before/after observation |
| Run out of time | Score 0; time-out recorded in history; details says no potion served | Results screenshot |
| Finish 10 customers | >=80% rounded average wins; otherwise loses | Final result screenshot |
| Restart program after high score | Best saved average remains visible | Restart screenshot |
| Sound controls | Music and narration/SFX can be muted separately | Listening test |
| All character voice lines | Narration plays with the correct level, no missing WAV errors | Listening test |

## Suggested final report evidence structure

Describe the task goals and changes from the original design; provide a game state diagram (menu → workbench → shop → brewing → results); describe data structures (`Ingredient`, `Customer`, `Potion`, `Player`, `Result`, `GameData`) and how external text files are loaded; explain the scoring algorithm and the experiment; show genuine screenshots from running the program; include the test table and what failed or was improved; finish with a reflection in your own words on challenges, debugging and what you would change next. Do not state that you completed a test or a research step that you have not personally performed.

## Academic and intellectual-property note

This game includes user-supplied artwork inspired by existing commercial game characters and a supplied font. Review the source licensing and your course rules before distribution or submission. A personal/private use copy does not establish redistribution permission. The game has not been graded; the HD band cannot be guaranteed by feature count alone.

### Countdown update and testing
Level 2 now permits 60 seconds and Level 3 permits 30 seconds after Start Brewing.
The final 15 seconds use a sharper double-tick. Music and speech remain independent of ticking,
which obeys the SFX mute preference. `ruby tests/test_timer_sound.rb` tests the changeover,
muting, zero-time silence, and the untimed level without needing speakers.
The two supplied new welcome recordings replace the earlier 90- and 60-second audio.
Run a real Windows/Gosu test to verify the display, alignment of the voice clips and perceived tick volume.
