# 🚀 Quick Deployment Guide

## For Users: Installing the Mod

### Option 1: Direct Copy (Recommended)
1. **Download** the repository
2. **Copy** the `DetailedAdjacencyPreview/` folder to your Civ VI mods directory:
   - **Windows**: `Documents\My Games\Sid Meier's Civilization VI\Mods\`
   - **Mac**: `~/Documents/Sid Meier's Civilization VI/Mods/`
   - **Linux**: `~/.local/share/aspyr-media/Sid Meier's Civilization VI/Mods/`
3. **Launch** Civilization VI
4. Go to **Additional Content** → **Mods** 
5. **Enable** "Detailed Adjacency Preview"
6. **Restart** when prompted

### ⚠️ **CRITICAL**: Verify Mod Installation

**Step 1: Check Mod Appears in Game**
- In Civilization VI, go to **Additional Content** → **Mods**
- Look for "Detailed Adjacency Preview" in the list
- If it's NOT there, the mod folder is in the wrong location

**Step 2: Enable the Mod**
- Click the checkbox next to "Detailed Adjacency Preview"
- Click "OK" 
- **Restart** Civilization VI when prompted

**Step 3: Verify Mod is Loading**
- Start a game (any type)
- Check the console output (if enabled) or game logs
- You should see: `=== DETAILED ADJACENCY PREVIEW MOD LOADING ===`

### 🔧 Troubleshooting Installation

**Problem: Mod doesn't appear in Additional Content**
- Check the folder path is exactly: `...\Mods\DetailedAdjacencyPreview\`
- Verify the folder contains `DetailedAdjacencyPreview.modinfo`
- Make sure folder name is exactly `DetailedAdjacencyPreview` (no spaces)

**Problem: Mod appears but won't enable**
- Make sure you have the required DLC (Rise & Fall, Gathering Storm)
- Check that all files are present in the mod folder
- Try disabling other mods temporarily

**Problem: Game crashes when loading**
- Disable all other mods first
- Try enabling just "Detailed Adjacency Preview"
- If it still crashes, report the issue with your game version

## Testing the Current Version

**This is a TEST version** that will:
1. Print messages to the console when loading
2. Show interface mode changes when you enter/exit district placement
3. **NOT yet show visual overlays** (debugging phase)

To test:
1. Start a new game
2. Found a city and build at least one district  
3. Try to place another district (Government Plaza recommended)
4. Look for console messages starting with `=== ADJACENCY PREVIEW ===`

## For Developers: Build from Source

### Option 2: Manual Build (For Developers)
If you want to build from the source files:

1. Install **ModBuddy** from Steam (Civilization VI Development Tools)
2. Create new project in ModBuddy
3. Copy files from `Scripts/` and `UI/` to your project
4. Use the `DetailedAdjacencyPreview.modinfo` as reference
5. Build and deploy through ModBuddy

## Repository Structure

```
Root/
├── DetailedAdjacencyPreview/     # 🎮 DEPLOYABLE MOD FOLDER
│   ├── *.modinfo                 # Mod definition
│   ├── Scripts/                  # Core logic
│   ├── UI/                       # User interface
│   └── README.md                 # User instructions
├── Scripts/                      # 💻 Development originals  
├── UI/                           # 🎨 Development originals
├── tasks/                        # 📋 Development process
└── *.mdc                         # 🛠️ AI workflow tools
```

**Key Point**: The `DetailedAdjacencyPreview/` folder is the **complete, ready-to-deploy mod**. Everything else is development scaffolding and workflow tools.

## Expected Console Output

When working correctly, you should see:
```
=== DETAILED ADJACENCY PREVIEW MOD LOADING ===
Mod file: DetailedAdjacencyPreview.lua
=== MOD SUCCESSFULLY LOADED ===
=== ADJACENCY PREVIEW === Initializing mod
=== ADJACENCY PREVIEW === Event handlers registered successfully
```

When entering district placement mode:
```
=== ADJACENCY PREVIEW === Interface mode: [old] -> DISTRICT_PLACEMENT
```

If you don't see these messages, the mod is not loading properly 

# Deployment Guide: Detailed Adjacency Preview Mod

## 🎯 **CRITICAL FIX APPLIED - Local Mod Loading**
**Fixed the modinfo structure** - Local mods use `<Components>` instead of `<InGameActions>` (which is for Steam Workshop mods).

## Current Status
✅ **Mod Recognition**: Shows as "Detailed Adjacency Preview" in Additional Content  
✅ **Modinfo Structure**: Fixed to use proper `<Components>` structure for local installation  
✅ **XML Context**: Uses correct `<n>` tag format (Civilization VI standard)  
🔄 **Loading Test**: Should now show console output when loading

## Expected Console Output After Fix

**For LOCAL MODS** (like ours), you should see:
```
InGame: Loading InGame UI - [Documents Path]/My Games/Sid Meier's Civilization VI/Mods/DetailedAdjacencyPreview/UI/DetailedAdjacencyPreview.xml
=== DETAILED ADJACENCY PREVIEW MOD: Starting to load ===
DETAILED ADJACENCY PREVIEW: Test message 1
DETAILED ADJACENCY PREVIEW: Test message 2
DETAILED ADJACENCY PREVIEW: Test message 3
=== DETAILED ADJACENCY PREVIEW MOD: Initialize() called ===
DETAILED ADJACENCY PREVIEW: Event handlers registered
=== DETAILED ADJACENCY PREVIEW MOD: FULLY LOADED ===
```

**Note**: This is different from Steam Workshop mods which show paths like:
```
InGame: Loading InGame UI - F:/SteamLibrary/steamapps/workshop/content/289070/...
```

## Critical Difference: Local vs Steam Workshop Mods

### **Local Mods** (what we're building):
- **Structure**: `<Components>` in modinfo file
- **Console Output**: Shows Documents path
- **Installation**: Manual copy to Mods folder

### **Steam Workshop Mods**:
- **Structure**: `<InGameActions>` in modinfo file  
- **Console Output**: Shows Steam workshop path
- **Installation**: Automatic via Steam subscription

## Installation Steps

### 1. Locate Your Civilization VI Mods Folder

**Windows:**
```
%USERPROFILE%\Documents\My Games\Sid Meier's Civilization VI\Mods\
```

**Example path:**
```
C:\Users\[YourUsername]\Documents\My Games\Sid Meier's Civilization VI\Mods\
```

### 2. Copy the Mod Folder

1. Copy the entire `DetailedAdjacencyPreview` folder from this repository
2. Paste it into your Civilization VI Mods directory
3. The final path should look like:
   ```
   Documents\My Games\Sid Meier's Civilization VI\Mods\DetailedAdjacencyPreview\
   ```

### 3. Verify Folder Structure

Ensure your mod folder contains:
```
DetailedAdjacencyPreview/
├── DetailedAdjacencyPreview.modinfo
├── UI/
│   ├── DetailedAdjacencyPreview.lua
│   ├── DetailedAdjacencyPreview.xml
│   └── DetailedAdjacencyPreview_Overlays.lua
└── Scripts/
    ├── DetailedAdjacencyPreview_Core.lua
    └── DetailedAdjacencyPreview_Utils.lua
```

### 4. Enable the Mod

1. Launch Civilization VI
2. Go to **Main Menu** → **Additional Content**
3. Find "Detailed Adjacency Preview" in the list
4. Enable the mod
5. **MUST RESTART** the game completely (exit to desktop, relaunch)

### 5. Test and Verify

1. Load a save game with at least one city and district
2. Open the console (if available) or watch for UI behavior
3. Try placing a new district and look for adjacency information

## Troubleshooting

### If the mod doesn't appear in Additional Content:
- Check file path is correct
- Verify `DetailedAdjacencyPreview.modinfo` exists in the mod folder
- Restart Civilization VI completely

### If the mod appears but doesn't load:
- Look for console messages starting with "DETAILED ADJACENCY PREVIEW"
- Check that the game was restarted after enabling the mod
- Verify all files are present in the correct folders

### If you see errors:
- Check the game's log files in `Documents\My Games\Sid Meier's Civilization VI\Logs\`
- Compare console output with the expected output above

## Next Steps

Once loading is confirmed, we'll implement the full adjacency preview functionality with visual overlays and real-time district placement integration.

## Support

If you continue to see "Unknown Mod" or the mod doesn't load:
1. Check the exact folder structure matches the above
2. Verify the modinfo file isn't corrupted
3. Try copying the files again
4. Restart Civilization VI completely 