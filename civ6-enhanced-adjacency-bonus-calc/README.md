# Civilization VI Enhanced Adjacency Bonus Calculator

A mod that enhances Civilization VI's district placement preview by showing the adjacency benefits that existing districts would receive from a new district placement.

## Project Structure

### `/DetailedAdjacencyPreview/`
The main mod folder containing all game files:
- `DetailedAdjacencyPreview.modinfo` - Mod definition and metadata
- `UI/` - Lua scripts for UI integration and functionality

### `/tasks/`
Project documentation and requirements:
- `tasks-prd-detailed-adjacency-preview.md` - Complete task list and development status
- `prd-detailed-adjacency-preview.md` - Product Requirements Document

### Reference Documentation
- `Civ6_Core_Functionality_Reference.md` - Comprehensive guide to Civilization VI's core systems
- `Civ6_Function_Quick_Reference.md` - Quick reference for common functions and patterns

## Current Status

✅ **Core functionality complete** - The mod successfully calculates and displays reverse adjacency bonuses
✅ **Native integration achieved** - Works seamlessly with Civilization VI's adjacency system
🚧 **Visual overlay implementation in progress** - Working on displaying bonuses directly on map tiles

## Features

- **Complete adjacency information**: Shows both incoming and outgoing benefits during district placement
- **Real-time calculations**: Updates as you move the district placement cursor
- **Native integration**: Uses Civilization VI's built-in adjacency calculation functions
- **Performance optimized**: Efficient caching and calculation systems
- **Universal compatibility**: Works with all district types, DLCs, and unique civilization districts

## Installation

1. Copy the `DetailedAdjacencyPreview` folder to your Civilization VI Mods directory
2. Enable the mod in Additional Content before starting a game

## Development

This mod is built using the Civilization VI SDK and ModBuddy, leveraging Lua for UI scripting and game integration. 