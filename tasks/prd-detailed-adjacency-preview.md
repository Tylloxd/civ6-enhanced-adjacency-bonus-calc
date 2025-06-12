# Product Requirements Document: Detailed Adjacency Preview Mod for Civilization VI

## Introduction/Overview

The Detailed Adjacency Preview mod addresses a significant UI limitation in Civilization VI's district placement system. Currently, when players preview district placement, they can see the adjacency benefits the new district would receive from existing districts and terrain features. However, the game does not display the benefits that existing districts would gain from the new district placement.

This mod enhances the district placement preview by displaying the adjacency bonuses that existing districts would receive when a new district is placed adjacent to them. This provides players with complete information about the mutual benefits of district placement, enabling more strategic city planning decisions.

## Goals

1. **Complete Information Display**: Show both incoming and outgoing adjacency benefits during district placement preview
2. **Enhanced Strategic Planning**: Enable players to make more informed decisions about district placement by seeing all adjacency relationships
3. **Seamless Integration**: Integrate the feature naturally with existing game UI without disrupting gameplay flow
4. **Universal Compatibility**: Work across all district types, game modes (single-player and multiplayer), and DLC content
5. **Performance Optimization**: Maintain game performance while calculating and displaying additional adjacency information

## User Stories

1. **As a strategic city planner**, I want to see how placing an Aqueduct will benefit my existing Industrial Zone so that I can optimize my city's production output.

2. **As a new player**, I want to understand all the benefits of district placement so that I can learn the game's adjacency mechanics more effectively.

3. **As an experienced player**, I want complete adjacency information during district placement so that I can make optimal decisions without mental calculations.

4. **As a multiplayer participant**, I want the mod to work in online games so that I can use it in competitive scenarios.

5. **As a city builder**, I want to see cumulative benefits when multiple existing districts would benefit from a new placement so that I can identify high-value locations.

## Functional Requirements

1. **Adjacency Calculation**: The mod must calculate adjacency benefits that existing districts would receive from a new district placement on each compatible tile.

2. **Visual Overlay System**: The mod must display benefit information as overlays on compatible tiles during district placement preview.

3. **Benefit Visualization**: For each existing district that would benefit:
   - Display the numerical benefit value (e.g., "+2")
   - Show the benefit type symbol (Production, Science, Culture, Faith, etc.)
   - Support multiple benefit types per district if applicable

4. **Benefit Aggregation**: When multiple existing districts would benefit from a single placement, the mod must summarize and display the total benefits by type.

5. **Compatible Tile Detection**: The mod must only process and display information for tiles that are highlighted as compatible by the game's existing district placement system.

6. **District Type Coverage**: The mod must work for all district types including:
   - Base game districts (Campus, Commercial Hub, Industrial Zone, etc.)
   - DLC districts (Government Plaza, Diplomatic Quarter, etc.)
   - Unique civilization districts

7. **Game Mode Compatibility**: The mod must function in both single-player and multiplayer game modes.

8. **UI Integration**: The visual display must integrate with the existing game UI style and not interfere with other UI elements.

9. **Performance Optimization**: The mod must calculate and display information without causing noticeable performance degradation.

10. **Dynamic Updates**: The overlay information must update in real-time as the player moves the district placement cursor.

## Non-Goals (Out of Scope)

1. **Future Adjacency Predictions**: The mod will not show potential benefits from districts that could be built in the future.

2. **Terrain Modification**: The mod will not alter existing terrain features or adjacency rules.

3. **AI Behavior Changes**: The mod will not modify AI district placement behavior or decision-making.

4. **Alternative UI Modes**: The mod will not provide alternative display modes (tooltips, separate panels) - only tile overlays.

5. **Adjacency Rule Modifications**: The mod will not change existing adjacency bonus values or rules.

6. **Save Game Compatibility**: The mod will not alter save game files or require specific save game versions.

## Design Considerations

**Visual Design:**
- Use the same visual styling as existing adjacency bonus displays in the game
- Maintain consistency with the game's color scheme and iconography
- Ensure overlays are clearly visible but not intrusive
- Use appropriate contrast for readability against various terrain types

**Information Architecture:**
- Display benefits in a clear, scannable format
- Group multiple benefits logically (e.g., "+2 Production, +1 Science")
- Use standardized symbols for benefit types consistent with the base game

**User Experience:**
- Ensure the feature feels like a natural extension of existing gameplay
- Maintain the game's responsiveness during district placement
- Provide immediate visual feedback as players hover over different tiles

## Technical Considerations

**Development Framework:**
- Utilize the [Civilization VI SDK and ModBuddy](https://civilization.fandom.com/wiki/Modding_(Civ6)/Basics_of_Mod_Creation) for mod development
- Leverage XML for game data modifications and Lua for UI scripting
- Ensure compatibility with the game's existing modding architecture

**Core Systems Integration:**
- Hook into the existing district placement preview system
- Access adjacency calculation functions from the game engine
- Integrate with the UI rendering pipeline for overlay display

**Performance Considerations:**
- Optimize adjacency calculations to run efficiently during tile hover events
- Cache calculations when possible to avoid redundant processing
- Ensure the mod doesn't impact game frame rate during district placement

**Compatibility Requirements:**
- Test with base game and all DLC content
- Ensure compatibility with popular gameplay mods
- Follow Civilization VI modding best practices for cross-platform support

**Data Access:**
- Access district type definitions and adjacency rules from game databases
- Read existing district placements and their adjacency relationships
- Interface with the game's tile compatibility system

## Success Metrics

1. **Functionality**: 100% of district types show correct adjacency benefits in the preview
2. **Performance**: No measurable impact on game frame rate during district placement
3. **User Adoption**: Positive feedback from both casual and experienced players
4. **Compatibility**: Works across all game modes and DLC content without conflicts
5. **Accuracy**: Displayed benefits match actual in-game adjacency bonuses after placement

## Open Questions

1. **Mod Distribution**: Should the mod be distributed via Steam Workshop, or are alternative distribution methods preferred?

2. **Localization**: Does the mod need to support multiple languages, or is English sufficient for the initial release?

3. **Visual Styling Details**: Are there specific preferences for overlay positioning, size, or animation effects?

4. **Testing Scope**: What is the priority order for testing across different DLC combinations and game scenarios?

5. **Update Maintenance**: How should the mod handle future Civilization VI updates that might change adjacency systems?

---

**Target Audience**: This PRD is designed for developers familiar with Civilization VI modding tools and game mechanics. The mod should be approachable for both novice and experienced Civilization VI players.

**Technical Resources**: 
- [Civilization VI Modding Guide](https://civilization.fandom.com/wiki/Modding_(Civ6))
- [Mod Creation Basics](https://civilization.fandom.com/wiki/Modding_(Civ6)/Basics_of_Mod_Creation)
- [Altering Base Game Content](https://civilization.fandom.com/wiki/Modding_(Civ6)/How_to_Alter_Base_Game_Content) 