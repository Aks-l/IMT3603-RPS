# Save System Documentation

## Overview
The game now has an automatic save/load system that preserves all important game progress and discovery states.

## What Gets Saved

### Player Progress
- Health and funds
- Inventory (cards and items)
- Current deck composition
- Progress counters (levels completed, biomes completed)
- Current biome

### Discovery States
- **Enemies**: Which enemies have been discovered
- **Hands/Cards**: Which cards have been discovered  
- **Biomes**: Which biomes have been discovered and encountered

## Auto-Save
The game automatically saves when:
- Health changes
- Funds change
- An encounter finishes

You can disable auto-save by setting `AUTO_SAVE_ENABLED = false` in [SaveSystem.gd](autoload/SaveSystem.gd).

## Manual Save/Load
- **F5**: Quick Save (saves current progress)
- **F9**: Quick Load (loads last save and returns to map)

## Main Menu
- **Continue**: Loads the last saved game (only visible if save exists)
- **New Game**: Starts fresh game
  - If a save exists, you'll be asked to confirm deletion
  - Clears all discovered states for a clean start

## Save File Location
The save file is stored at: `user://savegame.save`

On Windows, this typically resolves to:
`C:\Users\[YourUsername]\AppData\Roaming\Godot\app_userdata\IMT3603\savegame.save`

## API Usage

### From Code
```gdscript
# Manual save
SaveSystem.save_game()

# Manual load
SaveSystem.load_game()

# Delete save
SaveSystem.delete_save()

# Check if save exists
if SaveSystem.has_save():
	print("Save file exists!")

# Listen for save events
SaveSystem.save_completed.connect(_on_save_done)
SaveSystem.load_completed.connect(_on_load_done)
```

## Implementation Details

### Autoload Order
SaveSystem is loaded after all databases (EnemyDatabase, HandDatabase, BiomeDatabase) and Globals, ensuring all data is available when loading.

### Data Serialization
- **HandData**: Stored by ID, deserialized from HandDatabase
- **ItemData**: Stored by ID, deserialized from ItemDatabase
- **BiomeData**: Current biome stored by ID, deserialized from BiomeDatabase

### Resource Persistence
Discovery states are stored directly on the Resource objects (EnemyData, HandData, BiomeData), so they persist across scenes automatically once loaded.

## Testing Notes

When testing new game vs continue:
1. Start a new game
2. Discover some enemies/cards
3. Gain some funds/items
4. Return to main menu
5. "Continue" should restore all progress
6. "New Game" should ask for confirmation and reset everything
