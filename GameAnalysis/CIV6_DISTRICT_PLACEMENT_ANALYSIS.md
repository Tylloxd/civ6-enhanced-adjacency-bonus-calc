# Civilization VI District Placement System Analysis

## Overview

Analysis of the official Civilization VI district placement system based on game files from:
- `AdjacencyBonusSupport.lua` - Core adjacency calculation functions
- `StrategicView_MapPlacement.lua` - District placement UI and interaction system

## Key System Components

### 1. Interface Mode Integration

**Entry Point**: `OnInterfaceModeEnter_DistrictPlacement()`
- Triggered when entering `InterfaceModeTypes.DISTRICT_PLACEMENT` mode
- Calls `RealizePlotArtForDistrictPlacement()` to calculate and display all compatible tiles
- Sets UI cursor and fixed tilt mode

**Exit Point**: `OnInterfaceModeLeave_DistrictPlacement()`  
- Cleans up lens layers and resets UI state
- Opens production panel (if not going to modal lens)

### 2. Core Plot Detection System

**Function**: `RealizePlotArtForDistrictPlacement()`

This is the main function that calculates ALL compatible tiles when district placement mode is entered:

```lua
local districtHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE);
local district = GameInfo.Districts[districtHash];
local tParameters = {};
tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtHash;

local tResults = CityManager.GetOperationTargets(pSelectedCity, CityOperationTypes.BUILD, tParameters);
```

**Key Insight**: The game uses `CityManager.GetOperationTargets()` with `CityOperationTypes.BUILD` to get ALL valid plots for district placement at once.

### 3. Adjacency Bonus System

**Function**: `AddAdjacentPlotBonuses()`

For each compatible tile, the game calculates adjacency bonuses the NEW district would receive:

```lua
local kAdjacentPlotBonuses = AddAdjacentPlotBonuses(kPlot, district.DistrictType, pSelectedCity, m_hexesDistrictPlacement);
```

**Core Adjacency Function**: `GetAdjacentYieldBonusString()`

This function calculates yield bonuses using the engine's native adjacency system:

```lua
local iBonus = plot:GetAdjacencyYield(Game.GetLocalPlayer(), pkCity:GetID(), eDistrict, iBonusYield);
```

### 4. Native Engine Functions Available

#### Plot Functions:
- `plot:GetAdjacencyYield(playerID, cityID, districtType, yieldType)` - Get adjacency bonus amount
- `plot:GetAdjacencyBonusTooltip(playerID, cityID, districtType, yieldType)` - Get detailed tooltip
- `plot:GetAdjacencyBonusType(playerID, cityID, districtType, direction)` - Get bonus type/source
- `plot:CanHaveDistrict(districtIndex, playerID, cityID)` - Check if district can be placed

#### City Manager Functions:
- `CityManager.GetOperationTargets(city, operation, parameters)` - Get valid plots for operation
- `CityManager.CanStartOperation(city, operation, parameters, showFailure)` - Check if operation can start

#### UI Parameters:
- `UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE)` - Get current district type
- `UI.GetHeadSelectedCity()` - Get currently selected city

### 5. Visual System

The game uses `UILens` system for visualization:

```lua
UILens.SetActive("DistrictPlacement");
UILens.SetAdjacencyBonusDistict(plotInfo.index, plotInfo.hexArtdef, plotInfo.adjacent);
```

Each plot gets a `plotInfo` object with:
- `hexArtdef` - Visual style ("Placement_Valid", "Placement_Purchase")
- `adjacent` - Array of adjacency bonus icons on hex edges
- `selectable` - Whether the plot can be selected

## Integration Strategy for Our Mod

### Perfect Alignment with Our Approach

Our current mod implementation already perfectly aligns with the game's native system:

1. **✅ Same Entry Point**: We hook `InterfaceModeTypes.DISTRICT_PLACEMENT`
2. **✅ Same Parameter System**: We use `UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE)`
3. **✅ Same Plot Detection**: We use `plot:CanHaveDistrict()` for compatibility checking
4. **✅ Same Calculation Timing**: We calculate all tiles when placement mode is entered

### Key Native Functions We Should Leverage

#### For Adjacency Calculations:
```lua
-- Get adjacency bonuses the NEW district would receive (existing functionality)
local bonus = plot:GetAdjacencyYield(playerID, cityID, districtType, yieldType);

-- Get detailed tooltip information
local tooltip, required = plot:GetAdjacencyBonusTooltip(playerID, cityID, districtType, yieldType);
```

#### For Plot Compatibility:
```lua
-- Use the same system the game uses for plot detection
local tResults = CityManager.GetOperationTargets(pSelectedCity, CityOperationTypes.BUILD, tParameters);
```

### Reverse Adjacency Implementation Strategy

We need to create a complementary system that:

1. **Uses same plot detection**: Leverage `CityManager.GetOperationTargets()` 
2. **Calculates reverse bonuses**: For each compatible plot, check what benefits existing districts would receive
3. **Integrates with visualization**: Add our bonus information to the existing `plotInfo.adjacent` system

### Native Adjacency Data Structures

From `AdjacencyBonusSupport.lua`, the game tracks adjacency-enabled districts:

```lua
local m_DistrictsWithAdjacencyBonuses = {};
for row in GameInfo.District_Adjacencies() do
    local districtIndex = GameInfo.Districts[row.DistrictType].Index;
    if (districtIndex ~= nil) then
        m_DistrictsWithAdjacencyBonuses[districtIndex] = true;
    end
end
```

This suggests we should query `GameInfo.District_Adjacencies()` to understand which districts can benefit from adjacency.

## Next Steps

1. **Replace our manual adjacency rules** with queries to `GameInfo.District_Adjacencies()`
2. **Leverage native plot detection** using `CityManager.GetOperationTargets()`
3. **Use native adjacency calculations** where possible with `plot:GetAdjacencyYield()`
4. **Integrate with existing visualization** by adding to `plotInfo.adjacent` arrays

This analysis confirms our approach is perfectly aligned with Civilization VI's native district placement system. 