# Snake Game

A classic snake game with a retro LCD aesthetic and multiple game modes built with LÖVE.

## Features

- **LCD-Style Graphics**: Retro monochrome display aesthetic
- **Multiple Game Modes**:
  - **Classic**: Traditional snake gameplay - eat food to grow longer
  - **Zen Mode**: Relaxed gameplay without time pressure
  - **Survival Mode**: Start with a longer snake (length 8) for an extra challenge
- **Menu System**: Navigate between game modes and view instructions
- **Sound Effects**: Audio feedback for eating food and game over (can be muted)

## Controls

### Menu Navigation
- **Arrow Keys**: Navigate menu options
- **Enter/Return**: Select menu option
- **Escape**: Return to menu from game

### Gameplay
- **Arrow Keys**: Change snake direction (Up, Down, Left, Right)
- **M**: Toggle sound mute/unmute
- **Escape**: Return to main menu

## How to Play

1. Launch the game: `love src/`
2. Select a game mode from the main menu
3. Use arrow keys to guide the snake to the food
4. Avoid hitting walls or yourself
5. Try to achieve the highest score!

## Game Modes Explained

### Classic Mode
The traditional snake experience. Eat food to grow longer and score points. The game ends if you hit the walls or collide with yourself.

### Zen Mode
A more relaxed variant where you can focus on gameplay without the pressure of dying. Perfect for practicing snake movement patterns.

### Survival Mode
Start with a snake that's already 8 segments long! This makes the game immediately more challenging as you have less room to maneuver from the start.

## Project Structure

```
snake/
├── src/
│   ├── main.lua    # Main game logic and entry point
│   └── lcd.lua     # LCD display rendering module
└── README.md
```

## Technical Details

- **Grid Size**: 30x20 cells
- **Starting Snake Length**: 3 (Classic/Zen) or 8 (Survival)
- **Framework**: LÖVE (Lua)

## Future Ideas

- Difficulty levels with varying speeds
- Obstacles and power-ups
- High score persistence
- Additional game modes

## Credits

Built as a learning project to explore game development with Lua and LÖVE.
