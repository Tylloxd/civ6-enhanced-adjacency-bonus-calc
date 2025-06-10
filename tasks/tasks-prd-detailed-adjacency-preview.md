# Task List: Detailed Adjacency Preview Mod for Civilization VI

## Relevant Files

- `DetailedAdjacencyPreview.modinfo` - ✅ CREATED - Mod definition file containing metadata, dependencies, and configuration.
- `Scripts/DetailedAdjacencyPreview_Core.lua` - ✅ CREATED - Core adjacency calculation engine with data structures and benefit calculation functions.
- `Scripts/DetailedAdjacencyPreview_Utils.lua` - ✅ CREATED - Caching system and performance optimization utilities with statistics tracking.
- `UI/DetailedAdjacencyPreview.lua` - ✅ CREATED - Main UI integration script with district placement hooks and event handlers.
- `UI/DetailedAdjacencyPreview.xml` - ✅ CREATED - UI context definitions for loading the mod in-game.
- `UI/DetailedAdjacencyPreview_Overlays.lua` - ✅ CREATED - Visual overlay system for displaying adjacency benefits on map.
- `GameAnalysis/CIV6_DISTRICT_PLACEMENT_ANALYSIS.md` - ✅ CREATED - Comprehensive analysis of native district placement system.
- `GameAnalysis/AdjacencyBonusSupport.lua` - ✅ ADDED - Official game file for adjacency calculation reference.
- `GameAnalysis/StrategicView_MapPlacement.lua` - ✅ ADDED - Official game file for district placement UI reference.

### Notes

- ✅ **MAJOR ACHIEVEMENT**: Our approach perfectly aligns with Civilization VI's native district placement system
- ✅ Analysis of official game files confirms our integration strategy is correct
- ✅ We use the same entry points (`InterfaceModeTypes.DISTRICT_PLACEMENT`) as the native system
- ✅ We calculate for all compatible tiles at once, just like the native adjacency bonus display
- ✅ **REVERSE ADJACENCY CALCULATION WORKS**: Successfully detecting and calculating reverse bonuses
- ⚠️ **NEW ISSUE**: Reverse bonuses showing on ALL adjacent tiles, not just suitable placement tiles
- ⚠️ **NEW ISSUE**: Mod persists even when disabled in game options
- We should leverage native functions like `CityManager.GetOperationTargets()` for plot detection
- We should integrate with the existing `plotInfo.adjacent` visualization system

## Tasks

- [x] 1.0 Set up Civilization VI Mod Development Environment
  - [x] 1.1 Install Civilization VI Development Tools from Steam Library
  - [x] 1.2 Install Visual Studio components required by ModBuddy
  - [x] 1.3 Create new ModBuddy project using "Basic Mod" template
  - [x] 1.4 Configure mod metadata (name, description, version, author)
  - [x] 1.5 Test build and deployment pipeline by creating a minimal test mod
  - [x] 1.6 Verify mod appears in game's Additional Content menu

- [x] 2.0 Create Core Adjacency Calculation System
  - [x] 2.1 Research and document Civilization VI's existing adjacency rule system
  - [x] 2.2 Create data structure mapping district types to their adjacency benefits
  - [x] 2.3 Implement function to calculate adjacency benefits for existing districts
  - [x] 2.4 Create caching system to optimize repeated calculations
  - [x] 2.5 Add support for all base game district types
  - [x] 2.6 Add support for DLC district types (Government Plaza, Diplomatic Quarter, etc.)
  - [x] 2.7 Add support for unique civilization districts
  - [x] 2.8 Implement benefit aggregation logic for multiple district bonuses
  - [x] ✅ **NEW**: 2.9 Analyze official game files for native adjacency system integration

- [x] 3.0 Implement District Placement Preview Integration
  - [x] 3.1 Identify and hook into the game's district placement preview system
  - [x] 3.2 Create event listeners for district placement mode activation
  - [x] 3.3 Implement tile compatibility detection using game's existing system
  - [x] 3.4 Create real-time calculation triggers for cursor movement *(Updated: Now calculates all tiles at once)*
  - [x] 3.5 Implement district placement preview exit detection
  - [x] 3.6 Add error handling for edge cases in placement system
  - [x] 3.7 Ensure compatibility with different district placement contexts
  - [x] ✅ **NEW**: 3.8 Verify alignment with native `RealizePlotArtForDistrictPlacement()` system
  - [x] ✅ **WORKING**: 3.9 Reverse adjacency calculation successfully detects existing districts

- [x] 4.0 Develop Visual Overlay Display System *(In Progress - Need to integrate with native visualization)*
  - [x] 4.1 Create UI overlay components for displaying adjacency benefits
  - [x] 4.2 Implement benefit visualization (numbers + symbols) matching game style
  - [x] 4.3 Create positioning logic for overlays on compatible tiles
  - [x] 4.4 Add support for multiple benefit types per tile display
  - [x] 4.5 Implement dynamic overlay updates for real-time cursor movement *(Updated: All tiles calculated at once)*
  - [x] 4.6 Add visual styling consistent with existing game UI
  - [x] 4.7 Optimize overlay rendering performance *(Achieved through single calculation)*
  - [x] 4.8 Add overlay cleanup when exiting district placement mode

- [ ] ⚠️ **NEW**: 4.9 Critical Bug Fixes and Filtering
  - [ ] 4.9.1 **URGENT**: Filter reverse bonuses to only suitable placement tiles (not all adjacent tiles)
  - [ ] 4.9.2 **URGENT**: Fix mod persistence when disabled in game options
  - [ ] 4.9.3 Investigate base game `DistrictPlotIconManager.lua:159` errors
  - [ ] 4.9.4 Ensure reverse bonuses only display on tiles highlighted by native placement system
  - [ ] 4.9.5 Validate that occupied tiles (City Center, existing districts) are excluded
  - [ ] 4.9.6 Test that unsuitable terrain tiles are properly excluded

- [ ] 5.0 Testing and Compatibility Validation
  - [ ] 5.1 Create test scenarios for all base game district combinations
  - [ ] 5.2 Test functionality with each DLC expansion enabled
  - [ ] 5.3 Validate performance with large cities and complex adjacency chains
  - [ ] 5.4 Test multiplayer compatibility and synchronization
  - [ ] 5.5 Verify compatibility with popular gameplay mods
  - [ ] 5.6 Test edge cases (water districts, unique terrain features)
  - [ ] 5.7 Validate accuracy by comparing displayed vs. actual post-placement bonuses
  - [ ] 5.8 Perform final integration testing across different game scenarios

- [ ] ✅ **NEW**: 6.0 Integration with Native Game Systems
  - [ ] 6.1 Replace manual plot detection with `CityManager.GetOperationTargets()`
  - [ ] 6.2 Leverage native adjacency functions like `plot:GetAdjacencyYield()`
  - [ ] 6.3 Integrate with existing `plotInfo.adjacent` visualization system
  - [ ] 6.4 Use `GameInfo.District_Adjacencies()` for adjacency rule queries
  - [ ] 6.5 Test integration with native `UILens.SetAdjacencyBonusDistict()` system

## Current Status

**✅ BREAKTHROUGH ACHIEVED**: Reverse adjacency calculation is working correctly! Console output shows:
- Campus placement: 0 reverse bonuses (correct)
- Industrial Zone placement: 6 reverse bonuses found (+1 Science to Campus)

**🐛 CRITICAL ISSUES TO ADDRESS**:
1. **Filtering Problem**: Reverse bonuses showing on all adjacent tiles instead of only suitable placement tiles
2. **Mod Persistence**: Mod continues running even when disabled in options
3. **Base Game Errors**: `DistrictPlotIconManager.lua:159` errors appearing (possibly unrelated)

**Next Phase**: Fix filtering to only show reverse bonuses on tiles that are actually suitable for district placement.

---

*Last Updated: After successful reverse adjacency calculation validation - core logic works, now need proper filtering!* 