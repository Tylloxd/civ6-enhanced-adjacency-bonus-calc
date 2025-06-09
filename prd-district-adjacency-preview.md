# District Adjacency Preview - Product Requirements Document

## Introduction/Overview
This mod enhances the district placement preview functionality in Civilization VI: Gathering Storm by showing the adjacency bonuses that a new district would provide to existing adjacent districts. This helps players make more informed decisions about district placement by clearly displaying the impact on existing districts' yields.

## Goals
1. Show numerical adjacency bonuses that a new district would provide to existing districts during placement preview
2. Support all district types, including civilization-specific unique districts
3. Provide clear, readable information during the district placement preview phase
4. Maintain compatibility with other district-related mods

## User Stories
- As a player, I want to see how much adjacency bonus my new district will provide to existing districts so that I can optimize my city planning
- As a player using Germany, I want to see the specific adjacency bonuses my Hansa would receive from new district placement so that I can maximize its unique bonuses
- As a player using mods that affect districts, I want the adjacency preview to work correctly with my other mods so that I can use them together

## Functional Requirements
1. The system must display numerical values showing adjacency bonuses during district placement preview
2. The system must calculate and show adjacency bonuses for all vanilla and civilization-specific districts
3. The system must show the preview on all valid placement tiles for the new district
4. The system must update the preview values in real-time as the player moves the placement cursor
5. The system must support unique district replacements (like Germany's Hansa)
6. The system must calculate correct adjacency values based on the specific district type being placed
7. The system must be compatible with the Gathering Storm expansion
8. The system must maintain compatibility with other district-related mods
9. The system must show combined total bonus values when multiple adjacency bonuses apply

## Non-Goals (Out of Scope)
1. The system will NOT show adjacency bonuses from terrain features or natural wonders
2. The system will NOT show adjacency bonuses that existing districts provide to the new district being placed
3. The system will NOT include advanced visual effects or animations
4. The system will NOT modify the existing district placement UI beyond adding the numerical indicators
5. The system will NOT provide in-game configuration options
6. The system will NOT attempt to calculate or display adjacency rules from other mods

## Design Considerations
- Display Format: Simple numerical values (+1, +2, etc.) shown on applicable tiles
- Visibility: Values should be clearly visible during the entire district placement preview
- UI Integration: Numbers should not obstruct existing UI elements or other important game information
- Bonus Display: Show single combined value for multiple adjacency bonuses

## Technical Considerations
1. Must integrate with Gathering Storm's district system
2. Must hook into the district placement preview system
3. Must access civilization-specific district data
4. Must handle mod compatibility by using proper game events and hooks
5. Must calculate adjacency bonuses using the game's existing adjacency rules system
6. Must focus on vanilla and DLC adjacency rules only to ensure reliability
7. Note: All district-to-district adjacency bonuses in the base game and DLCs are positive or zero - there are no negative adjacency bonuses to handle

## Success Metrics
1. Functional Implementation:
   - Correct numerical values are displayed
   - All district types are supported
   - Values are visible during placement preview
   - Works with civilization-specific districts
2. Technical Implementation:
   - No conflicts with other district-related mods
   - Works correctly with Gathering Storm expansion

## Open Questions
None at this time. 