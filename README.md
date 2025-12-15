# IMT3603 - Rock Paper Scissors Roguelike

# [gameprog.md submission file](gameprog.md)

A deck-building roguelike card game inspired by Balatro, where you battle enemies using an expanded rock-paper-scissors system with over 100 unique hands.

## Game Overview

Navigate through procedurally generated maps, battle enemies with strategic hand selection, collect new cards, purchase items, and discover the secrets of a world where rock-paper-scissors determines fate.


## Key Features

### Core Gameplay
- **Expanded RPS System**: 100+ unique hands beyond rock, paper, and scissors
- **Generalized Win/Loss Algorithm**: Mathematically elegant system that works with any odd number of hands
- **Deck Building**: Collect and manage your hand inventory
- **Enemy Roster**: Battle unique enemies with distinct movesets and behaviors
- **Progressive Difficulty**: Multiple biomes with increasing challenge

### Map System
- **Procedural Generation**: Radial map generation with organic positioning
- **Multi-threaded Terrain Generation**: Beautiful, performance-optimized backgrounds
- **Fog of War**: Shader-based visibility system that reveals as you progress
- **Bezier Curve Paths**: Smooth, natural-looking connections between nodes
- **Dynamic Encounters**: Combat, events, shops, and boss battles

### Visual Polish
- **Hand Explosion Animation**: Physics-based particle effects when hands are defeated
- **Outcome Graph Visualization**: Interactive circular display showing win/loss relationships
- **Viewport Scaling**: Responsive UI that adapts to any screen size
- **AI-Generated Art**: Over 100 unique card images and atmospheric backgrounds

### Progression System
- **Auto-Save**: Progress automatically saved on key events
- **Discovery System**: Unlock and track enemies, cards, and biomes
- **Resource Management**: Balance health, funds, and inventory
- **Event Chains**: Complex narrative encounters with multiple outcomes

## Technical Architecture

### Built With
- **Engine**: Godot 4.4
- **Language**: GDScript
- **Art**: ChatGPT-generated images

### Core Systems

#### Autoload Singletons
- `AudioPlayer` - Music and sound effects management
- `EnemyDatabase` - Enemy data registry
- `HandDatabase` - Card/hand data registry  
- `ItemDatabase` - Item data registry
- `BiomeDatabase` - Biome/world data registry
- `EventDatabase` - Event data registry
- `Globals` - Game state management
- `SaveSystem` - Automatic save/load functionality
- `EncounterHandler` - Manages encounter flow and scene transitions
- `AlmanacOverlay` - Global almanac UI
- `DeckCreator` - Global deck builder UI

## Getting Started

### Prerequisites
- Godot 4.4 or later

### Running the Game
1. Clone the repository
2. Open the project in Godot
3. Press F5 or click the play button

### Controls
- **Mouse**: Navigate menus, click nodes, select cards
    - **Middle mouse button**: Pan the map
- **G**: Toggle outcome graph

## Project Structure

```
imt3603/
├── audio/               # Music and sound effects
├── autoload/            # Global singleton scripts
│   ├── *Database.gd     # Data loading systems
│   ├── Globals.gd       # Game state management
│   ├── SaveSystem.gd    # Persistence system
│   └── encounter_handler.gd
├── data/                # Game data resources (.tres files)
│   ├── biomes/          # Biome definitions
│   ├── cards/           # Hand/card data
│   ├── enemies/         # Enemy data and AI scripts
│   ├── events/          # Event scenarios
│   └── items/           # Item definitions
├── scenes/              # Scene files and scripts
│   ├── almanac/         # Collection/encyclopedia UI
│   ├── battleUI/        # Combat interface
│   ├── DeckCreator/     # Deck building UI
│   ├── eventScene/      # Event encounter UI
│   ├── FightScene/      # Battle animation
│   ├── mainMenu/        # Main menu
│   ├── map/             # Procedural map generation
│   ├── shopScene/       # Shop interface
│   └── VictoryScene/    # Post-battle rewards
└── ui/                  # Reusable UI components
    ├── components/      # Custom UI widgets
    ├── encounter_icons/ # Map node icons
    ├── fonts/           # Typography
    └── paneltextures/   # UI theming

```

## Save System

The game features an automatic save system that persists:
- Player progress (health, funds, inventory, deck)
- Discovery states (enemies, hands, biomes encountered)
- Level and biome completion counters

### Balancing Randomness
To counter being completely random:
- Enemies have **fixed decks** that deplete during battle
- Players can learn enemy patterns through repeated encounters
- Strategic deck building provides long-term advantage

### Enemy AI Patterns
Each enemy has a unique deck composition rather than pure randomness, allowing skilled players to gain an edge through pattern recognition.

### Scalability
The win/loss algorithm supports any odd number of hands, allowing the game to expand indefinitely with new card types.

## Known Issues

- Items can be purchased but don't have implemented effects yet
- Some TODOs remain for polish features (see code comments)

## Development Team

This project was developed as part of the IMT3603 course at NTNU.

**Team Members:**
- Aksel Wiersdalen
- Nikolai Olav Stubø
- Katharina Kivle

## License

This project was created for educational purposes as part of the IMT3603 course.

## Acknowledgments

- Hands setup from [RPS-101](https://www.umop.com/rps101.htm)

