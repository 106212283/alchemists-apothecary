# Gameplay Screenshot Evidence

These **9 screenshots** were provided from a Windows playthrough of *Alchemist's Apothecary* on 22 November 2026. They illustrate features of the finished game, but do not replace automated tests or complete manual testing.

## Screenshot index

| No. | Filename | Feature demonstrated |
|---|---|---|
| 01 | `01_main_menu.png` | Main menu, Clash Bold font, character artwork and navigation buttons. |
| 02 | `02_level1_workbench.png` | Level 1 Apprentice workbench, Purple Witch, Goblin request, starting gold and no timer. |
| 03 | `03_ingredient_shop.png` | Separate shop showing ingredient prices, quantities, unlock requirement and return button. |
| 04 | `04_perfect_potion_result.png` | 100% potion result with happy reaction, three stars and 15-gold perfect-potion bonus. |
| 05 | `05_potion_score_breakdown.png` | Heat, Calm, Energy and Bitterness compared against target values and differences. |
| 06 | `06_level2_workbench.png` | Level 2 Skilled workbench with Night Witch, three-ingredient minimum and 60-second allowance. |
| 07 | `07_level3_workbench.png` | Level 3 Master workbench with Fire Wizard, four-ingredient minimum and 30-second allowance. |
| 08 | `08_customer_order_history.png` | Order history showing customer names, match scores, stars, rewards, moods and average. |
| 09 | `09_timer_expired_result.png` | Timer-expired result with 0% match, no payment, reputation loss and disappointed reaction. |

## Gameplay and assessment evidence

**Interface and shop (01–03).** The menu, Apprentice workbench and separate ingredient shop show the interface, character sprites, custom typography, inventory, purchasing costs, locked stock and navigation.

**Scoring (04–05).** A perfect potion earns 100%, three stars and a 15-gold bonus. The score breakdown displays the potion's four properties alongside targets and absolute differences.

**Difficulty progression (02, 06–07).** Levels increase both ingredient requirements and time pressure:

| Level | Guide | Minimum ingredients | Timer |
|---|---|---:|---|
| 1 — Apprentice | Purple Witch | 2 | No timer |
| 2 — Skilled | Night Witch | 3 | 60 seconds |
| 3 — Master | Fire Wizard | 4 | 30 seconds |

**History and timeouts (08–09).** The history screen records completed orders and running average. The timed-out order screen shows a zero score, no payment, lost reputation and disappointed feedback.

The game also has ticking sounds that become more urgent during the final 15 seconds, custom guide voices, external customer and ingredient files, and persistent high scores. These nonvisual features should be verified using code, audio files, tests or a live demonstration, not the screenshots alone.

## Suggested use in the final submission

Include relevant screenshots with captions alongside descriptions of the interface, game flow, scoring, levels, history and timeout handling. Supplement the images with code explanations, test outputs and reflection.
