# Civilization VI Quick Function Reference

## Key Search Terms and Functions

### Adjacency System Functions (likely in AdjacencyBonusSupport.lua)
```lua
-- Common adjacency-related functions to look for:
GetAdjacencyBonus()
CalculateDistrictAdjacency()
GetDistrictAdjacencyYield()
ValidateDistrictPlacement()
GetAdjacentDistricts()
GetPlotAdjacencyBonus()
```

### City Management Functions (CitySupport.lua, CityPanel.lua)
```lua
-- City information and management:
GetCityData()
UpdateCityData()
GetCityYields()
GetCityProduction()
GetCityPopulation()
GetCityGrowth()
GetCityHousing()
ValidateCityPlacement()
GetWorkablePlots()
```

### District Functions (DistrictPlotIconManager.lua)
```lua
-- District-related functions:
GetDistrictType()
GetDistrictYields()
GetDistrictAdjacency()
CanPlaceDistrict()
GetValidDistrictPlots()
GetDistrictProduction()
GetSpecialtyDistrictLimit()
```

### UI Helper Functions (ToolTipHelper.lua, SupportFunctions.lua)
```lua
-- UI and tooltip systems:
GetToolTipString()
AddToolTip()
CreateTooltip()
GetColoredText()
GetIconString()
FormatYieldText()
GetYieldIcon()
```

### Plot and Map Functions (PlotInfo.lua, WorldInput.lua)
```lua
-- Map and plot information:
GetPlotInfo()
GetPlotYields()
GetPlotOwner()
GetPlotImprovement()
GetPlotResource()
GetPlotTerrain()
GetPlotFeature()
IsPlotWorkable()
```

### Production Functions (ProductionHelper.lua)
```lua
-- Production calculations:
GetProductionCost()
GetProductionProgress()
GetTurnsToComplete()
CanProduce()
GetProductionModifier()
GetYieldModifier()
```

### Unit Functions (UnitSupport.lua)
```lua
-- Unit management:
GetUnitData()
GetUnitStrength()
GetUnitMovement()
CanUnitMove()
GetUnitActions()
GetUnitPromotions()
```

## Common Data Structures

### Plot Data Structure
```lua
plot = {
    X = number,
    Y = number,
    ResourceType = string,
    TerrainType = string,
    FeatureType = string,
    ImprovementType = string,
    DistrictType = string,
    Owner = playerID,
    Yields = { Food, Production, Gold, Science, Culture, Faith }
}
```

### City Data Structure
```lua
city = {
    Name = string,
    Population = number,
    Housing = number,
    Amenities = number,
    Growth = number,
    Production = productionTable,
    Districts = districtArray,
    Yields = yieldTable,
    Owner = playerID
}
```

### District Data Structure
```lua
district = {
    Type = string,
    Plot = plotReference,
    AdjacencyBonus = number,
    Yields = yieldTable,
    Buildings = buildingArray,
    Completed = boolean
}
```

## Common Event Handlers

### UI Events
```lua
-- Common UI event patterns:
Events.CitySelectionChanged.Add(OnCitySelectionChanged)
Events.DistrictPlacementChanged.Add(OnDistrictPlacement)
Events.PlotYieldsChanged.Add(OnPlotYieldsChanged)
Events.CityProductionChanged.Add(OnProductionChanged)
```

### Input Events
```lua
-- Input handling patterns:
Events.InputActionTriggered.Add(OnInputAction)
Events.KeyEvent.Add(OnKeyEvent)
Events.MouseEvent.Add(OnMouseEvent)
```

## Database Query Patterns

### Common Database Queries
```lua
-- Typical database query patterns:
for row in GameInfo.Districts() do
    -- Process district data
end

for row in GameInfo.Buildings() do
    -- Process building data
end

local districtInfo = GameInfo.Districts[districtType]
local buildingInfo = GameInfo.Buildings[buildingType]
```

## Utility Functions to Look For

### Math and Calculation Helpers
```lua
Round()
Clamp()
Lerp()
GetDistance()
GetDirectionToward()
```

### String and Localization Helpers
```lua
Locale.Lookup()
Locale.ToUpper()
GetLocalizedText()
FormatText()
```

### Color and Visual Helpers
```lua
GetPlayerColor()
GetColorFromType()
SetColorByName()
GetUIColor()
```

## File Organization Patterns

### Replacement Files (DLC/Expansion patterns)
- Base game: `Base/Assets/UI/FileName.lua`
- Expansion 1: `DLC/Expansion1/UI/Replacements/FileName_Expansion1.lua`
- Expansion 2: `DLC/Expansion2/UI/Replacements/FileName_Expansion2.lua`

### Addition Files (New functionality)
- DLC additions: `DLC/[DLCName]/UI/Additions/NewFile.lua`

### Common Include Patterns
```lua
include("InstanceManager")
include("SupportFunctions")
include("Colors")
include("Civ6Common")
```

## Performance Considerations

### Expensive Operations to Avoid
- Frequent database queries in loops
- Complex calculations every frame
- Large table recreations
- Unnecessary UI updates

### Optimization Patterns
- Cache database results
- Use dirty flags for updates
- Batch UI updates
- Pre-calculate static values

## Integration Points

### Hooking into Existing Systems
1. **Event System**: Subscribe to relevant game events
2. **UI Framework**: Extend existing panels and controls
3. **Database System**: Add data through XML modifications
4. **Notification System**: Use existing notification framework

### Extension Patterns
- Override functions by redefining them after include
- Add new event handlers to existing events
- Extend data structures with additional fields
- Hook into update cycles of existing systems

This quick reference should help you identify specific functions and patterns when examining the actual .lua files in the Civilization VI codebase. 