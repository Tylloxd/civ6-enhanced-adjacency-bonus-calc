# Testing Guide: Native Integration Approach

## What We're Testing

Our mod now hooks into the native `GetAdjacentYieldBonusString()` function to enhance the central tile bonus displays with reverse adjacency bonuses.

## Expected Behavior

Instead of creating separate overlays, **the existing central tile displays should now show enhanced information**:

**Before**: "[ICON_GOLD]+2"  
**After**: "[ICON_GOLD]+2, [ICON_PRODUCTION]+1, [ICON_SCIENCE]+1"

## Testing Steps

### 1. Enable the Mod
1. Launch Civilization VI
2. Go to Additional Content → Mods
3. Make sure "Detailed Adjacency Preview" is enabled
4. Start a new game or load a save

### 2. Set Up Test Scenario
1. Find or settle a city
2. Build at least 2 different districts (e.g., Campus and Industrial Zone)
3. Position them so they could be adjacent to a new district

### 3. Test District Placement
1. Go into district placement mode (try to build a Commercial Hub)
2. **Look at the central tile displays** on compatible tiles
3. **Check Console Output**: If you can access the console, you should see:
   ```
   DetailedAdjacencyPreview: Native Integration Mod loaded successfully
   DetailedAdjacencyPreview: Successfully hooked GetAdjacentYieldBonusString
   DetailedAdjacencyPreview: Found reverse bonus: +1 YIELD_PRODUCTION to DISTRICT_INDUSTRIAL_ZONE
   DetailedAdjacencyPreview: Enhanced bonus: [ICON_GOLD]+2, [ICON_PRODUCTION]+1
   ```

### 4. What to Look For

#### Central Tile Displays
- **Enhanced Text**: Tiles should show multiple yield bonuses separated by commas
- **Reverse Bonuses**: Additional yields beyond what the new district would get
- **Native Styling**: Should look exactly like normal game displays, just with more information

#### Tooltips
- **Enhanced Information**: Tooltips should explain what each bonus is for
- **Clear Format**: Should show both original bonuses and reverse bonuses

### 5. Console Access (If Available)
If you can access the in-game console:
1. Press `~` or `F1` (depending on game version)
2. Look for our mod's debug messages
3. Messages should show the hooking was successful and reverse bonuses were found

## Troubleshooting

### If No Enhanced Displays Appear:
1. **Check Mod is Loaded**: Look for console messages starting with "DetailedAdjacencyPreview:"
2. **Verify Scenarios**: Make sure you have existing districts that could benefit from adjacency
3. **Check Function Hooking**: Look for "Successfully hooked GetAdjacentYieldBonusString" message

### If Game Crashes or Errors:
1. Our function hooking might have compatibility issues
2. Check the game's error logs
3. We may need to adjust our hooking approach

## Success Criteria

✅ **Full Success**: Central tile displays show enhanced yield information with reverse bonuses  
✅ **Partial Success**: Console shows our mod is loading and calculating reverse bonuses  
❌ **Failure**: No evidence of mod functionality or game errors

## Expected Scenarios

**Commercial Hub Placement near Campus + Industrial Zone:**
- Original: "[ICON_GOLD]+2" (from adjacency to other districts)
- Enhanced: "[ICON_GOLD]+2, [ICON_SCIENCE]+1, [ICON_PRODUCTION]+1" (includes what Campus and Industrial Zone would gain)

**Industrial Zone Placement near Campus + Commercial Hub:**
- Original: "[ICON_PRODUCTION]+2" 
- Enhanced: "[ICON_PRODUCTION]+2, [ICON_SCIENCE]+1, [ICON_GOLD]+1"

This testing will verify whether our native function hooking approach successfully integrates reverse adjacency bonuses into the existing game UI without requiring separate overlays. 