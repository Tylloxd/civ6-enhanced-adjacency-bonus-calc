# Civilization VI Core Functionality Reference

## Overview
This document serves as a comprehensive reference for Civilization VI's core functionality, based on analysis of the game's .lua and .xml files. Use this as a reference before implementing new features to check if the game already provides the functionality you're looking for.

## Directory Structure

### Base Game Files
- **Base/Assets/**: Core game assets and configuration
- **DLC/**: Expansion and DLC content
- **Base/Assets/UI/**: User interface logic and display
- **Base/Assets/Maps/**: Map generation and utilities
- **Base/Assets/Scenarios/**: Scenario-specific content

## Core Game Systems

### 1. Adjacency Bonus System
**Key Files:**
- `Base/Assets/UI/AdjacencyBonusSupport.lua` - Core adjacency bonus calculations and display logic
- Various XML files contain adjacency bonus data definitions

**Core Functions Available:**
- Adjacency bonus calculation for districts
- Visual display of adjacency bonuses in UI
- Bonus validation and application

### 2. City Management System
**Key Files:**
- `Base/Assets/UI/CityPanel.lua` - Main city interface
- `Base/Assets/UI/CityPanelOverview.lua` - City overview displays
- `Base/Assets/UI/CitySupport.lua` - City utility functions
- `Base/Assets/UI/CityBannerManager.lua` - City banner displays

**Core Functions Available:**
- City production management
- Population and housing calculations
- District placement validation
- City state management
- Loyalty system (Expansion1)

### 3. District System
**Key Files:**
- `Base/Assets/UI/DistrictPlotIconManager.lua` - District placement and icons
- Various DLC files enhance district functionality

**Core Functions Available:**
- District placement validation
- District adjacency calculations
- District yield calculations
- Specialization district management

### 4. User Interface System
**Key Files:**
- `Base/Assets/UI/InGame.lua` - Main in-game UI controller
- `Base/Assets/UI/TopPanel.lua` - Top UI bar with yields and resources
- `Base/Assets/UI/LaunchBar.lua` - Bottom action bar
- `Base/Assets/UI/MinimapPanel.lua` - Minimap functionality
- `Base/Assets/UI/WorldInput.lua` - Input handling
- `Base/Assets/UI/ToolTipHelper.lua` - Tooltip system

**Core Functions Available:**
- Complete tooltip system for all game elements
- Input handling and hotkeys
- UI panel management
- Resource and yield display
- Turn management UI

### 5. Diplomacy System
**Key Files:**
- `Base/Assets/UI/DiplomacyActionView.lua` - Diplomatic actions
- `Base/Assets/UI/DiplomacyDealView.lua` - Trade deals
- `Base/Assets/UI/DiplomacyRibbon.lua` - Diplomatic status display
- `Base/Assets/UI/LeaderView.lua` - Leader interaction screens

**Core Functions Available:**
- Complete diplomatic action system
- Trade route management
- Alliance system (Expansion1)
- Diplomatic relationship tracking

### 6. Technology and Civics System
**Key Files:**
- `Base/Assets/UI/TechTree.lua` - Technology tree interface
- `Base/Assets/UI/CivicsTree.lua` - Civics tree interface
- `Base/Assets/UI/TechAndCivicSupport.lua` - Shared tech/civic functions
- `Base/Assets/UI/ResearchChooser.lua` - Research selection
- `Base/Assets/UI/CivicsChooser.lua` - Civic selection

**Core Functions Available:**
- Complete tech tree navigation
- Research progress tracking
- Boost system for techs and civics
- Eureka moment handling

### 7. Unit Management System
**Key Files:**
- `Base/Assets/UI/UnitPanel.lua` - Unit interface panel
- `Base/Assets/UI/UnitSupport.lua` - Unit utility functions
- `Base/Assets/UI/UnitFlagManager.lua` - Unit flag displays
- `Base/Assets/UI/SelectedUnit.lua` - Selected unit handling

**Core Functions Available:**
- Unit action management
- Unit promotion system
- Unit movement and combat
- Unit formation and grouping

### 8. Production System
**Key Files:**
- `Base/Assets/UI/ProductionPanel.lua` - Production queue interface
- `Base/Assets/UI/ProductionHelper.lua` - Production calculations
- `Base/Assets/UI/ProductionManager.lua` - Production queue management

**Core Functions Available:**
- Production queue management
- Build time calculations
- Resource requirement validation
- Production bonus calculations

### 9. Map and World System
**Key Files:**
- `Base/Assets/UI/WorldTracker.lua` - World state tracking
- `Base/Assets/UI/WorldInput.lua` - World interaction
- `Base/Assets/UI/PlotInfo.lua` - Plot information system
- `Base/Assets/UI/StrategicView.lua` - Strategic map view
- `Base/Assets/Maps/Utility/` - Map generation utilities

**Core Functions Available:**
- Complete map rendering system
- Plot information and tooltips
- Strategic vs. realistic view switching
- Map pin system
- Lens system for specialized views

### 10. Religion System
**Key Files:**
- `Base/Assets/UI/ReligionScreen.lua` - Religion overview
- `Base/Assets/UI/PantheonChooser.lua` - Pantheon selection

**Core Functions Available:**
- Religion founding and management
- Faith generation and spending
- Religious unit management
- Theological combat system

### 11. Espionage System
**Key Files:**
- `Base/Assets/UI/EspionageSupport.lua` - Espionage utility functions
- `Base/Assets/UI/EspionageChooser.lua` - Mission selection
- `Base/Assets/UI/EspionageOverview.lua` - Spy management
- `Base/Assets/UI/EspionagePopup.lua` - Mission results

**Core Functions Available:**
- Spy recruitment and management
- Mission selection and execution
- Counter-espionage system
- Diplomatic visibility system

## Expansion-Specific Systems

### Rise and Fall (Expansion1)
**Key Features:**
- **Governors**: `GovernorPanel.lua`, `GovernorSupport.lua`
- **Loyalty System**: `LoyaltySupport.lua`
- **Golden/Dark Ages**: Era system files
- **Emergency System**: World crisis files
- **Historic Moments**: Timeline tracking

### Gathering Storm (Expansion2)
**Key Features:**
- **Climate System**: `ClimateScreen.lua`
- **World Congress**: `WorldCongress*.lua` files
- **Power System**: `CityPanelPower.lua`
- **Natural Disasters**: `NaturalDisasterSupport.lua`
- **Diplomatic Victory**: Enhanced diplomacy files

## Utility and Support Systems

### Core Support Files
- `Base/Assets/UI/Civ6Common.lua` - Common utility functions
- `Base/Assets/UI/SupportFunctions.lua` - General support functions
- `Base/Assets/UI/InstanceManager.lua` - UI element management
- `Base/Assets/UI/Colors.lua` - Color definitions and management

### Debugging and Development
- `Base/Assets/UI/DebugHotloadCache.lua` - Development hot-reloading
- `Base/Assets/UI/Tuner/` - Development and debugging tools
- `Base/Assets/UI/Test.lua` - Testing utilities

## XML Configuration Files
The game uses numerous XML files (with hashed names) that contain:
- **Game Data**: Units, buildings, technologies, civics definitions
- **Balance Values**: Costs, yields, requirements
- **Localization**: Text strings and translations
- **Audio Cues**: Sound effect mappings
- **Visual Assets**: Art and animation references

## Modding and Extension Points

### Key Extension Files
- `Base/Assets/UI/WorldBuilder*.lua` - World builder tools
- `Base/Assets/UI/Automation/` - AI and automation systems
- `Base/Assets/UI/Civilopedia/` - In-game encyclopedia

### Scenario System
Each scenario has its own Scripts and UI folders containing:
- Custom game rules and victory conditions
- Modified UI elements
- Scenario-specific content and balance

## Usage Recommendations

### Before Creating New Features:
1. **Check if functionality exists**: Search this reference for related systems
2. **Examine existing implementations**: Look at similar features in the codebase
3. **Understand data flow**: Trace how data moves from XML → Lua → UI
4. **Consider expansion compatibility**: Ensure compatibility with Rise and Fall and Gathering Storm

### Key Integration Points:
- **UI Events**: Most game actions trigger UI events that can be hooked
- **Database Queries**: Game data is accessed through database query functions
- **Notification System**: Built-in system for informing players of events
- **Tooltip System**: Comprehensive system for displaying information

### Common Patterns:
- **Panel Management**: UI panels follow consistent creation/destruction patterns
- **Data Binding**: UI elements are bound to game data through specific patterns
- **Event Handling**: Game events are processed through established event chains
- **Localization**: All text goes through localization system

This reference should help you identify existing functionality before implementing new features. Many complex systems like adjacency bonuses, city management, and diplomatic interactions are already fully implemented and can be extended rather than recreated. 