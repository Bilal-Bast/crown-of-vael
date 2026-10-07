# Crown of Vael

**A portrait fantasy auto-battler RPG made with Godot 4.7.1.** Build a hero and party, prepare their gear and skills, then send them into an ever-expanding campaign of haunted forests, volcanic highlands, frozen peaks, and demon-haunted ruins.

Crown of Vael puts the focus on party building and long-term progression. Battles play automatically while you choose where to fight, improve your heroes, and tune the team that will take on the next challenge.

## The game

Start as the Squire and fight through campaign stages with a growing party. Your hero attacks and casts equipped skills automatically; companions join the fight. Battles reward Gold, Hero EXP, equipment, and upgrade materials. Spend those rewards to strengthen your hero and push into more dangerous regions.

The main progression loop is:

1. Choose a campaign stage or an Adventure mode.
2. Let your hero and companions fight through the encounter.
3. Collect rewards and improve stats, gear, skills, companions, and artifacts.
4. Return with a stronger party and take on the next stage, difficulty, or challenge.

### Campaign

The campaign has **10 regions**, with **20 stages per region** across six difficulties: Easy, Normal, Hard, Nightmare, Hell, and Infernal. That makes 1,200 difficulty-stage combinations to work through. Regular stages have three waves; enemies enter the battlefield over time. Stages 5, 10, and 15 feature elite enemies, and each region ends with its own named boss at Stage 20. A rare treasure enemy can appear and award extra resources.

Regions include Greenvale Outskirts, Whispering Forest, Ashen Highlands, Frostfang Mountains, Sunken Marshes, Crimson Desert, Ruined Kingdom, Shadowlands, Dragon Peaks, and Demon Realm. Defeating bosses opens new regions and, eventually, the next difficulty.

### Build your party

- **Heroes:** Begin as the Squire and develop the Knight. Mage, Ranger, Assassin, and Necromancer can be unlocked with Hero Pieces; each has a distinct combat role and party bonus.
- **Skills:** Equip up to four active skills. They trigger automatically during battle and can be improved with duplicates.
- **Equipment:** Fill seven gear slots, compare stat bonuses, upgrade items, and merge duplicates into higher rarities.
- **Companions:** Collect and improve allies who fight alongside your hero. Up to four companions can be active at once.
- **Artifacts:** Collect relics for account-wide bonuses and equip artifacts for stronger combat effects.

The Heroes, Equipment, Skills, Summon, and Settings screens are part of the production game. Some evolution paths and hero-summon features are still future-facing or locked.

### Adventure modes

Beyond the campaign, Adventure includes six reward dungeons, a scaling Permanent Tower, a five-boss Boss Rush, and Endless Survival. These modes offer different challenges and materials for developing your team.

## Project status

Crown of Vael is a local, single-player game project. It has no online services or purchases. Rewarded-ad pulls are simulated for development, and the hero summon banner is locked. The project has audio routing and organized audio folders, but no production music or sound files are included yet.

Progress is saved locally at `user://crown_of_vael.save`.

## Run the game

1. Open `project.godot` in **Godot 4.7.1**.
2. Press **F5** (Run Project).

The game is designed for a 1080 x 1920 portrait viewport and scales to a 360 x 640 window.

## Browse assets and screens

For an editor preview, open the scene in Godot and press **F6** (Run Current Scene):

- [`dev/asset_gallery/asset_gallery.tscn`](dev/asset_gallery/asset_gallery.tscn) browses hero, enemy, boss, background, UI icon, and effect artwork by category and region. It includes idle previews where sprite sheets allow them.
- [`dev/screen_gallery/screen_gallery.tscn`](dev/screen_gallery/screen_gallery.tscn) switches between live Battle, Heroes, Equipment, Skills, Summon, and Settings previews. It uses a separate gallery save.

The galleries are development tools; the production startup scene remains `scenes/main.tscn`.

## Project map

- `scenes/` — production entry scene plus editor-visible maps for runtime-built screens and UI.
- `scripts/` — combat, campaign, adventure, UI, character, data, and shared system code.
- `assets/characters/` — standard and pixel hero, enemy, and companion art.
- `assets/environments/regions/` — regional painted and pixel backgrounds grouped together.
- `assets/ui/`, `assets/effects/`, `assets/audio/`, `assets/fonts/` — interface art and organized visual/audio content.
- `resources/` — reserved for designer-authored Godot resources; much current game data is code-backed.
- `tests/` — smoke checks and visual capture tools. Local captures and test saves go under the ignored `.godot/` folder.

See [`docs/project_structure.md`](docs/project_structure.md) for the editor-oriented map and [`docs/asset_inventory.md`](docs/asset_inventory.md) for the asset catalog.