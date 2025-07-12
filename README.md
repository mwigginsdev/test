# Sci-Fi Bullet Hell Game

A fast-paced bullet hell game built with LÖVE2D (Lua) featuring sci-fi themes, multiple enemy types, and intense combat.

## Features

- **Player Ship**: Triangle-shaped sci-fi fighter with thrust particles
- **Enemy Types**:
  - **Scout**: Fast, agile, erratic movement
  - **Fighter**: Medium speed, strafing behavior, spread shots
  - **Bomber**: Slow, heavy, powerful shots
- **Weapon System**: Mouse-aimed shooting with visual effects
- **Audio System**: Procedural music and sound effects
  - **Background Music**: Ambient sci-fi soundtrack with looping
  - **Sound Effects**: Laser shots, explosions, and impact sounds
- **Particle Effects**: Explosions, thrust trails, and bullet glows
- **Progressive Difficulty**: Faster spawning and stronger enemies over time
- **Sci-Fi Aesthetics**: Starfield background, glowing effects, geometric ships

## Controls

- **WASD / Arrow Keys**: Move ship (relative to ship's facing direction)
- **Mouse / Spacebar**: Shoot towards mouse cursor (manual mode)
- **Q / E**: Rotate ship and camera left/right
- **G**: Toggle auto-shooting mode on/off
- **M**: Toggle background music on/off
- **N**: Toggle sound effects on/off
- **P**: Pause game (pauses music)
- **R**: Reset ship rotation / Restart (when game over)
- **Escape**: Quit

## Installation

1. Install LÖVE2D from https://love2d.org/
2. Run the game:
   ```bash
   love sci-fi-bullet-hell/
   ```

## Game Mechanics

- **Health System**: Player starts with 100 health, enemies deal varying damage
- **Scoring**: Points awarded for destroying enemies (scouts: 10, fighters: 25, bombers: 50)
- **Wave System**: Enemies get stronger and spawn faster as waves progress
- **Collision Detection**: Pixel-perfect collision between bullets, enemies, and player
- **Visual Feedback**: Health bars, particle explosions, glowing effects

## Technical Features

- Modular Lua architecture
- Entity-component-like design
- Efficient particle system
- Smooth movement and animations
- Real-time collision detection

Enjoy the intense sci-fi bullet hell action!