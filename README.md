# Profession Levels

A profession tracking addon for Turtle WoW.

## Description

Profession Levels is a World of Warcraft addon designed specifically for Turtle WoW that helps you track and manage your character's profession levels efficiently.

## Features

- Track profession levels across your characters
- Monitor profession progress in real-time
- Per-character settings (position, display preferences, minimap button)
- **Individual profession toggles** - enable/disable each profession separately via checkboxes
- Compact and Normal display modes
- Minimap button for quick access
- Hover highlights on rows
- Enhanced progress bar styling with vibrant colors
- Movable and lockable frame
- Preferences menu for easy configuration
- Lockpicking support for Rogues

## Commands

| Command | Description |
|---------|-------------|
| `/pl config` | Open preferences menu |
| `/pl compact` | Switch to compact mode |
| `/pl normal` | Switch to normal mode |
| `/pl lock` | Lock frame position |
| `/pl unlock` | Unlock frame position |
| `/pl reset` | Reset all settings |

## Minimap Button

- **Click** - Toggle main frame visibility
- **Shift+Click** - Open settings
- **Drag** - Reposition button

## Installation

1. Clone or download this repository
2. Place the `ProfessionLevels` folder in your World of Warcraft `Addons` directory:
   - `World of Warcraft\_classic_\Interface\AddOns\`
3. Restart World of Warcraft or reload the UI (`/reload`)

## Usage

Once installed and enabled:
1. The addon will automatically load when you start the game
2. Use the minimap button or `/pl config` to access settings
3. Drag the frame to reposition it
4. Monitor your profession levels as you level them up
5. Use the checkboxes in preferences to show/hide specific professions

## Files

- `ProfessionLevels.lua` - Main addon code
- `ProfessionLevels.toc` - Addon table of contents configuration file

## Requirements

- Turtle WoW private server
- World of Warcraft client (1.12.x - compatible with Turtle WoW)

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is open source and available under the MIT License.

---

**Author:** [gregdeichler](https://github.com/gregdeichler)
