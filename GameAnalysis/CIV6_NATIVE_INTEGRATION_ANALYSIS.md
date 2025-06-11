# Civilization VI Native System Integration Analysis

## Overview

This document analyzes our approach to integrating reverse adjacency bonuses directly into Civilization VI's native district placement system by enhancing the existing central tile bonus displays.

## Native System Architecture

### Key Components

1. **DistrictPlotIconManager.lua** - Manages the visual display of adjacency bonuses on tiles
2. **AdjacencyBonusSupport.lua** - Contains `GetAdjacentYieldBonusString()` function that calculates bonus text
3. **StrategicView_MapPlacement.lua** - Handles district placement mode and tile detection

### Central Tile Bonus Display

The game displays adjacency bonuses in the center of compatible tiles using:
- **UI Element**: `BonusText` label in `PlotYieldBonusInstance`
- **Content**: String like "[ICON_GOLD]+2" showing yield icons and amounts
- **Calculation**: `GetAdjacentYieldBonusString()` function in `AdjacencyBonusSupport.lua`

## Our Enhancement Strategy

### Function Hooking Approach

Instead of creating separate overlays, we **hook into the native `GetAdjacentYieldBonusString()` function** to enhance it with reverse bonuses.

#### Key Benefits:
1. **Seamless Integration**: Uses exact same UI elements, positioning, and styling as native system
2. **Enhanced Display**: Where native shows "[ICON_GOLD]+2", we show "[ICON_GOLD]+2, [ICON_PRODUCTION]+1, [ICON_SCIENCE]+1"
3. **Enhanced Tooltips**: Adds explanations for reverse bonuses to existing tooltips
4. **Zero Visual Changes**: No new UI elements, perfect consistency with game aesthetic

### Implementation Details

```lua
-- Store reference to original function
g_originalGetAdjacentYieldBonusString = GetAdjacentYieldBonusString;

-- Replace with enhanced version
GetAdjacentYieldBonusString = GetAdjacentYieldBonusString_Enhanced;

function GetAdjacentYieldBonusString_Enhanced(eDistrict, pkCity, plot)
    -- Call original function
    local originalBonus, originalTooltip, originalRequired = 
        g_originalGetAdjacentYieldBonusString(eDistrict, pkCity, plot);
    
    -- Calculate reverse bonuses
    local reverseBonuses = CalculateReverseBonuses(plot, districtInfo, pkCity);
    
    -- Enhance the display text
    local enhancedBonus = originalBonus;
    for _, reverseBonus in ipairs(reverseBonuses) do
        local yieldString = GetYieldString_Enhanced(reverseBonus.yieldType, reverseBonus.amount);
        enhancedBonus = enhancedBonus .. ", " .. yieldString;
    end
    
    return enhancedBonus, enhancedTooltip, originalRequired;
end
```

### Reverse Bonus Calculation

Our enhanced function:

1. **Calls Original Function**: Gets base adjacency bonuses the new district would receive
2. **Calculates Reverse Bonuses**: Determines what existing districts would gain
3. **Enhances Display Text**: Combines original + reverse bonuses in comma-separated format
4. **Enhances Tooltips**: Adds explanations for each reverse bonus

### Example Result

**Before Enhancement:**
- Tile shows: "[ICON_GOLD]+2"
- Tooltip: "+2 Gold from adjacent Commercial Hub"

**After Enhancement:**
- Tile shows: "[ICON_GOLD]+2, [ICON_PRODUCTION]+1, [ICON_SCIENCE]+1"  
- Tooltip: "+2 Gold from adjacent Commercial Hub
            +1 Production to Industrial Zone
            +1 Science to Campus"

## Technical Advantages

### 1. Perfect Native Integration
- Uses game's existing UI components
- Respects game's text formatting and iconography
- Automatically inherits positioning, sizing, and styling

### 2. Minimal Code Complexity
- Single function hook instead of complex overlay system
- Leverages existing adjacency calculation infrastructure
- No new UI elements to maintain

### 3. Maximum Compatibility
- Works with all district types and unique districts
- Compatible with DLCs and expansions
- No conflicts with other mods that modify UI

### 4. Optimal Performance
- Only calculates when adjacency display is already being calculated
- Reuses native caching and optimization systems
- No additional rendering overhead

## Integration with Game Database

### Adjacency Rule Queries

We query `GameInfo.District_Adjacencies()` to find applicable rules:

```lua
for row in GameInfo.District_Adjacencies() do
    if (row.DistrictType == existingDistrictInfo.DistrictType) then
        if (row.AdjacentDistrict == newDistrictInfo.DistrictType) then
            totalBonus = totalBonus + (row.YieldChange or 0);
        end
    end
end
```

### District Yield Mapping

We map districts to their primary yields:
- Campus → Science
- Industrial Zone → Production  
- Commercial Hub → Gold
- Theater Square → Culture
- Holy Site → Faith
- Harbor → Gold

## Expected User Experience

### Seamless Enhancement
Users will see enhanced adjacency information exactly where they expect it - in the native tile displays. The experience feels like a natural extension of the game's existing system.

### Clear Information Hierarchy
- **Original Bonus**: Shows what the new district gets (as before)
- **Reverse Bonuses**: Shows what existing districts would gain (new information)
- **Combined Display**: Everything in one place, clearly formatted

### Comprehensive Tooltips
Enhanced tooltips explain exactly which districts would benefit and by how much, providing complete information for strategic decision-making.

## Conclusion

This native integration approach provides the ideal user experience by enhancing existing systems rather than creating new ones. It delivers maximum functionality with minimal complexity and perfect visual consistency. 