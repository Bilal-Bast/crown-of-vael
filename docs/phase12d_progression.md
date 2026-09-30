# Phase 12D progression notes

## Early progression review

Fresh profiles keep the existing starter roster, starter equipment, Shield Bash, and campaign rewards. The first account ATK upgrade costs 25 Gold; no campaign, combat, reward, or balance values were changed. The smoke check simulates a fresh campaign through Easy 1-1 to Easy 2-20, checks that the existing starter gear and skill are present, confirms a tier 1 Gold Dungeon remains accessible, and verifies ordinary early Gold can pay for the initial ATK upgrade.

## Offline reward formula

Offline rewards grant Gold and hero EXP only. Each hourly rate is calculated as:

- Gold/hour = 120 + 25 × (region − 1) + 8 × (stage − 1) + 3 × (hero level − 1)
- Hero EXP/hour = 18 + 4 × (region − 1) + (stage − 1) + (hero level − 1)

Elapsed time is capped at 12 hours, or 16 hours for a valid active subscription. The reward is floored to whole amounts; time under 15 minutes is checkpointed without a popup. No premium currency is awarded.

Pending rewards and their source timestamp are stored in the local save before display; claiming clears the pending reward in the same save update that grants Gold and EXP. A failed rewarded ad leaves the base claim available. The current development provider simulates successful ads; an unavailable provider can reject the 2× claim. Production provider integration remains separate.

## Local clock boundary

The game clamps long absences to the cap, ignores negative elapsed time, and advances the saved timestamp on pause, close, and claim. This reduces accidental or simple local clock abuse. Because save data and the clock live on the device, this is not server-grade anti-cheat: a player with local file or system-clock control can still manipulate them. No cloud or social trust assumptions were changed.
