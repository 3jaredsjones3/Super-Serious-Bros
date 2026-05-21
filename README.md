# Super Serious Bros

A small 2D platformer built in **Godot 4.6.2** as a team practice project.

The main goal is to learn how to collaborate on a Godot game: scene organization, reusable components, feature branches, pull requests, level design workflow, player feel, enemies, hazards, UI, audio, shaders, and general polish.

This is a learning project first. Keep changes small, readable, and easy to review.

## Project Status

Early prototype.

Current/planned prototype features:

- Player movement
- Jump, double jump, wall slide, and wall jump
- Level loading through a persistent main scene
- Fruit collectibles
- Basic enemies
- Hazards and traps
- Checkpoints and respawning
- Simple UI
- Basic audio management
- Pixel-art visual polish

## Engine Version

Use:

```txt
Godot 4.6.2 stable mono
```

Please use the same Godot version unless the team agrees to upgrade.

## Getting Started

Clone the repository:

```bash
git clone https://github.com/3jaredsjones3/Super-Serious-Bros.git
```

Open Godot 4.6.2, choose **Import**, and select:

```txt
project.godot
```

Run the main scene:

```txt
res://scenes/main/main.tscn
```

## Controls

Current planned/default controls:

```txt
Move Left:      A / Left Arrow
Move Right:     D / Right Arrow
Jump:           Space
Double Jump:    Space while airborne
Wall Slide:     Hold toward a wall while falling
Wall Jump:      Press Space while sliding on a wall
Pause:          Escape
```

Double jump and wall jump are not separate input actions. They are different behaviors triggered by the jump input depending on the player state.

## Project Structure

Recommended structure:

```txt
res://
├── assets/
│   ├── art/
│   │   ├── backgrounds/
│   │   ├── pixel_adventure_packs/
│   │   │   ├── pixel_adventure_1/
│   │   │   └── pixel_adventure_2/
│   │   ├── sprites/
│   │   ├── tilesets/
│   │   └── ui/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
│
├── components/
│   ├── collectible/
│   ├── damage/
│   ├── hitbox/
│   ├── hurtbox/
│   └── movement/
│
├── scenes/
│   ├── blocks/
│   ├── enemies/
│   │   ├── angry_pig/
│   │   ├── bat/
│   │   ├── bee/
│   │   ├── mushroom/
│   │   ├── snail/
│   │   └── turtle/
│   ├── items/
│   │   ├── box/
│   │   ├── checkpoint/
│   │   └── fruit/
│   ├── levels/
│   │   ├── level_1_1/
│   │   └── test_levels/
│   ├── main/
│   ├── player/
│   ├── traps/
│   │   ├── falling_platform/
│   │   ├── rock_head/
│   │   ├── saw/
│   │   ├── spikes/
│   │   └── trampoline/
│   └── ui/
│
└── scripts/
    ├── autoload/
    ├── data/
    └── util/
```

## Folder Guidelines

Gameplay objects should usually live in their own feature folder.

Example:

```txt
scenes/enemies/mushroom/
├── mushroom.tscn
├── mushroom.gd
└── mushroom_sprite_frames.tres
```

Scripts that belong to one scene should usually stay next to that scene.

Good:

```txt
scenes/player/player.tscn
scenes/player/player.gd
scenes/enemies/mushroom/mushroom.tscn
scenes/enemies/mushroom/mushroom.gd
```

Shared scripts should go in one of these locations:

```txt
components/
scripts/autoload/
scripts/data/
scripts/util/
```

Use `components/` for reusable gameplay pieces like hitboxes, hurtboxes, damage receivers, collectible behavior, and movement helpers.

Use `scripts/autoload/` for project-wide singleton systems:

```txt
scripts/autoload/audio_manager.gd
scripts/autoload/game_state.gd
scripts/autoload/save_manager.gd
```

Use `scripts/data/` for reusable data resources:

```txt
scripts/data/level_data.gd
scripts/data/player_movement_stats.gd
scripts/data/enemy_stats.gd
```

Use `scripts/util/` for general helpers:

```txt
scripts/util/debug_draw.gd
scripts/util/math_util.gd
```

## Main Scene and Levels

The main scene should act as the stable game shell.

```txt
Main
├── CurrentLevel
├── HUD
├── PauseMenu
└── ScreenTransition
```

Individual levels are separate scenes loaded into `CurrentLevel`.

```txt
scenes/levels/level_1_1/level_1_1.tscn
```

Level scenes should contain local world content:

```txt
Level1_1
├── World
├── Enemies
├── Items
├── Traps
├── SpawnPoints
├── CameraBounds
└── Goal
```

This keeps menus, UI, transitions, game state, and level loading outside the individual level scenes.

## Naming Conventions

Use `snake_case` for files and folders.

Good:

```txt
player_controller.gd
level_1_1.tscn
rock_head.tscn
pixel_adventure_packs/
```

Avoid:

```txt
PlayerController.gd
Level 1-1.tscn
Rock Head.tscn
Pixel Adventure Packs/
```

Use descriptive names. Avoid vague names like `thing.gd`, `stuff.tscn`, or `new_script.gd`.

## Input Actions

Recommended Godot input actions:

```txt
move_left
move_right
jump
pause
```

Optional future actions:

```txt
dash
interact
restart
```

The player controller should decide whether `jump` means normal jump, double jump, or wall jump depending on the current movement state.

## Collision Layers

Initial suggested collision layers:

```txt
1  world
2  player
3  enemy
4  player_hitbox
5  enemy_hitbox
6  item
7  trigger
8  hazard
9  camera_bounds
10 one_way_platform
```

Keep this list updated whenever collision layers change.

## Prototype Milestones

### Milestone 1: Playable Test Room

- Main scene loads a test level
- Player can run, jump, double jump, wall slide, and wall jump
- Camera follows the player
- Fruit can be collected
- Mushroom enemy patrols
- Spikes damage the player
- Checkpoint can be activated
- Player respawns at the active checkpoint
- Goal loads the next level
- Pause menu works

### Milestone 2: Core Platformer Loop

- Multiple test levels
- Level restart after death
- Falling platforms
- Moving platforms
- Trampolines
- Enemy stomp behavior
- Player damage and invulnerability frames
- Basic HUD
- Basic audio effects

### Milestone 3: Juice Pass

- Player hurt flash shader
- Enemy dissolve shader
- Fruit sparkle particles
- Landing dust particles
- Camera shake on damage
- Fade transition between levels
- Music and SFX audio buses
- Volume settings

### Milestone 4: Team Workflow

- Protected `main` branch
- Feature branches
- Pull requests
- Issue tracking
- Scene ownership rules
- Collision layer documentation
- Coding conventions documentation

## Shader and FX Ideas

Good starter shader tasks:

```txt
assets/art/shaders/hurt_flash.gdshader
assets/art/shaders/dissolve.gdshader
assets/art/shaders/outline.gdshader
assets/art/shaders/water_distortion.gdshader
assets/art/shaders/screen_wipe.gdshader
```

Good starter particle/FX scenes:

```txt
scenes/fx/landing_dust/
scenes/fx/enemy_poof/
scenes/fx/fruit_sparkle/
scenes/fx/screen_transition/
```

Suggested first visual effects:

- Player hurt flash
- Enemy dissolve on defeat
- Fruit sparkle on pickup
- Dust puff on landing
- Checkpoint glow
- Simple screen fade or wipe

## Collaboration Workflow

Please avoid pushing directly to `main`.

Recommended workflow:

1. Create a feature branch.

```bash
git checkout -b feature/player-movement
```

2. Make your changes.

3. Commit with a clear message.

```bash
git commit -m "Add basic player movement"
```

4. Push your branch.

```bash
git push origin feature/player-movement
```

5. Open a pull request.

6. Wait for review before merging.

## Branch Naming

Use short descriptive branch names:

```txt
feature/player-movement
feature/mushroom-enemy
feature/checkpoints
feature/level-1-1-blockout
feature/hurt-flash-shader
fix/player-jump-buffer
fix/spike-damage
cleanup/folder-structure
```

## Commit Message Style

Use clear, practical commit messages.

Good:

```txt
Add player jump buffering
Create mushroom enemy scene
Fix spike damage collision
Move Pixel Adventure assets into art folder
```

Avoid:

```txt
stuff
changes
fix
asdf
```

## Assets

This project currently uses Pixel Adventure asset packs as prototype art.

Recommended asset location:

```txt
assets/art/pixel_adventure_packs/
```

Before publishing or distributing the game, verify that all third-party assets are used according to their license.

Do not assume third-party assets are covered by this repository's eventual code license.

## Git Ignore

Recommended `.gitignore` entries:

```gitignore
.godot/
.import/
export.cfg
export_presets.cfg
*.tmp
.DS_Store
Thumbs.db
```

## License

Code license is not finalized yet.

Asset licenses may differ from the code license. Keep asset license information documented before release or public distribution.

## Contributors

Team members:

```txt
Jared Jones
```

Add more contributors here as the team joins.

## Notes

This is a team learning project. Prefer simple working systems over clever architecture. Build small pieces, review often, and keep the game playable as it grows.
