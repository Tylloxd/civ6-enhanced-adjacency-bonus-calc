# Tasks for District Adjacency Preview Mod

## Relevant Files

- `DistrictAdjacencyPreview.modinfo` - Mod definition and configuration file
- `DistrictAdjacencyPreview.lua` - Main logic for district adjacency calculations and game integration
- `UI/DistrictAdjacencyPreview_UI.lua` - UI handling and display logic
- `UI/DistrictAdjacencyPreviewContext.xml` - UI layout and visual elements definition
- `Config/config.sql` - Database modifications and queries for district data

### Notes

- Files should be placed in the mod's directory: `%UserProfile%\Documents\My Games\Sid Meier's Civilization VI\Mods\DistrictAdjacencyPreview`
- Use ModBuddy for development and testing
- Test with both vanilla districts and civilization-specific districts (especially Germany's Hansa)

## Tasks

- [x] 1.0 Set up mod infrastructure and configuration
  - [x] 1.1 Create mod directory structure
  - [x] 1.2 Create and configure modinfo file with proper mod ID and dependencies
  - [x] 1.3 Set up basic Lua environment and required includes
  - [x] 1.4 Create initial SQL configuration for accessing district data
  - [x] 1.5 Set up mod loading hooks and initialization
  - [x] 1.6 Configure mod to work with Gathering Storm expansion

- [ ] 2.0 Implement district adjacency calculation system
  - [ ] 2.1 Create function to identify adjacent plots to placement location
  - [ ] 2.2 Implement detection of existing districts on adjacent plots
  - [ ] 2.3 Create lookup system for district adjacency rules
  - [ ] 2.4 Implement calculation of standard district adjacency bonuses
  - [ ] 2.5 Add support for civilization-specific district rules (e.g., Germany's Hansa)
  - [ ] 2.6 Create system to combine multiple adjacency bonuses into single value
  - [ ] 2.7 Implement caching system for adjacency calculations to improve performance

- [ ] 3.0 Create UI display system for adjacency previews
  - [ ] 3.1 Create basic UI layout XML structure
  - [ ] 3.2 Set up UI context and instance manager
  - [ ] 3.3 Implement number display system for showing adjacency values
  - [ ] 3.4 Create positioning system to show values on correct tiles
  - [ ] 3.5 Add event handlers for district placement preview
  - [ ] 3.6 Implement real-time update system for cursor movement
  - [ ] 3.7 Ensure UI elements don't overlap with existing game interface
  - [ ] 3.8 Add proper cleanup for UI elements when preview ends

- [ ] 4.0 Test and validate mod functionality
  - [ ] 4.1 Test with all vanilla district types
  - [ ] 4.2 Test with civilization-specific districts
  - [ ] 4.3 Verify correct adjacency bonus calculations
  - [ ] 4.4 Test UI visibility and clarity
  - [ ] 4.5 Test compatibility with other district-related mods
  - [ ] 4.6 Performance testing with multiple districts
  - [ ] 4.7 Test in different game scenarios (new game, loaded game, different map types)
  - [ ] 4.8 Create test documentation for future reference

## Current Issues to Address
1. All tasks need to be completed from the beginning
2. Focus on core functionality without toggle options
3. Ensure district-to-district adjacency calculations are accurate for all district combinations 