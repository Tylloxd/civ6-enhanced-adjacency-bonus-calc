# District Adjacency Preview - Test Documentation

## Overview
This document provides comprehensive testing procedures and validation methods for the District Adjacency Preview mod. Use this guide to verify mod functionality across different scenarios.

## Test Categories

### 1. Vanilla District Testing (Task 4.1)

**Purpose**: Verify that all standard Civilization VI districts are properly supported.

**Test Procedure**:
1. Load the mod in-game
2. Open the console (if available) or check logs
3. Run: `TestVanillaDistricts()`

**Expected Results**:
- All 12 vanilla districts should be recognized
- Districts that provide adjacency bonuses should show their targets
- Display names should be properly formatted

**Vanilla Districts to Test**:
- Campus → Theater Square (+1), Government Plaza (+1)
- Theater Square → Campus (+1), Government Plaza (+1), Entertainment Complex (+1), Water Park (+1)
- Commercial Hub → Harbor (+2), Government Plaza (+1)
- Harbor → Commercial Hub (+2), Government Plaza (+1)
- Industrial Zone → Government Plaza (+1), Aqueduct (+2), Dam (+2), Canal (+2)
- Holy Site → Government Plaza (+1)
- Government Plaza → All major districts (+1 each)
- Entertainment Complex → Theater Square (+1)
- Water Park → Theater Square (+1)
- Aqueduct → Industrial Zone (+2)
- Dam → Industrial Zone (+2)
- Canal → Industrial Zone (+2), Commercial Hub (+1), Harbor (+1)

### 2. Civilization-Specific District Testing (Task 4.2)

**Purpose**: Ensure unique districts work correctly with their civilization bonuses.

**Test Procedure**:
1. Start games as Germany, England, Mali, Russia, and Kongo
2. Test district placement with unique districts
3. Run: `TestCivilizationDistricts()`

**Expected Results**:
- Unique districts should be recognized as replacements for base districts
- Civilization-specific bonuses should be calculated correctly
- Base adjacency rules should still apply

**Unique Districts to Test**:
- **Germany - Hansa**: Should replace Industrial Zone, provide additional Commercial Hub bonus
- **England - Royal Navy Dockyard**: Should replace Harbor with standard bonuses
- **Mali - Suguba**: Should replace Commercial Hub with additional Holy Site bonus
- **Russia - Lavra**: Should replace Holy Site with standard bonuses
- **Kongo - Mbanza**: Should replace Neighborhood (different mechanics)

### 3. Adjacency Calculation Verification (Task 4.3)

**Purpose**: Validate that adjacency bonus calculations are mathematically correct.

**Test Procedure**:
1. Run: `VerifyAdjacencyCalculations()`
2. Check console output for test results

**Critical Test Cases**:
- Campus → Theater Square = +1 Science
- Theater Square → Campus = +1 Culture
- Commercial Hub → Harbor = +2 Gold
- Harbor → Commercial Hub = +2 Gold
- Government Plaza → Campus = +1 Science
- Aqueduct → Industrial Zone = +2 Production
- Industrial Zone → Aqueduct = 0 (one-way bonus)

**Expected Results**:
- All test cases should pass (100% success rate)
- Calculations should be consistent and repeatable

### 4. UI Functionality Testing (Task 4.4)

**Purpose**: Verify that the user interface displays correctly and responds to user input.

**Manual Testing Procedure**:
1. Start a new game
2. Found a city and grow to size 4+
3. Open district placement menu
4. Hover over valid district placement tiles
5. Observe adjacency bonus numbers

**Automated Testing**:
- Run: `TestUIFunctionality()`

**Expected UI Behavior**:
- Bonus numbers appear on tiles adjacent to existing districts
- Numbers are clearly visible and properly positioned
- Numbers update in real-time as cursor moves
- UI elements don't overlap with existing game interface
- Proper cleanup when district placement is canceled

**Visual Verification**:
- Green numbers for positive bonuses
- Proper font size and readability
- Smooth animations for appearance/disappearance
- No visual artifacts or glitches

### 5. Compatibility Testing (Task 4.5)

**Purpose**: Ensure the mod works with other district-related mods.

**Test Procedure**:
1. Install common district-related mods
2. Test district placement with multiple mods active
3. Check for conflicts or errors

**Common Mods to Test With**:
- District expansion mods
- Civilization-specific district mods
- UI enhancement mods
- Gameplay balance mods

**Expected Results**:
- No crashes or errors
- Adjacency calculations remain accurate
- UI elements don't conflict with other mod UIs

### 6. Performance Testing (Task 4.6)

**Purpose**: Verify that the mod doesn't negatively impact game performance.

**Test Procedure**:
1. Run: `TestPerformance()`
2. Monitor frame rates during district placement
3. Test with large cities and many districts

**Performance Benchmarks**:
- Adjacency calculations: < 1ms per calculation
- Cache hit rate: > 80% after initial calculations
- No noticeable frame rate drops during district placement
- Memory usage remains stable

**Stress Testing**:
- Place districts in cities with 10+ existing districts
- Rapidly move cursor over multiple valid placement tiles
- Test on large maps with many cities

### 7. Game Scenario Testing (Task 4.7)

**Purpose**: Verify functionality across different game scenarios and conditions.

**Test Scenarios**:

#### New Game Testing
1. Start fresh game
2. Test district placement from early game
3. Verify mod loads correctly

#### Loaded Game Testing
1. Load existing save file
2. Verify mod functionality persists
3. Test district placement in established cities

#### Map Type Testing
- **Pangaea**: Standard land-based testing
- **Archipelago**: Test harbor/water district interactions
- **Continents**: Mixed land/water scenarios
- **Island Plates**: Limited space scenarios

#### Game Speed Testing
- Test on different game speeds (Quick, Standard, Epic, Marathon)
- Verify calculations remain consistent

#### Multiplayer Testing
- Test in multiplayer games
- Verify synchronization between players
- Check for desync issues

### 8. Error Handling Testing

**Purpose**: Verify the mod handles edge cases and errors gracefully.

**Edge Cases to Test**:
- Invalid plot coordinates
- Missing district data
- Corrupted save files
- Mod conflicts
- Memory limitations

**Expected Behavior**:
- Graceful error handling with informative messages
- No crashes or game-breaking bugs
- Fallback to safe defaults when data is missing

## Test Execution

### Running Automated Tests

```lua
-- Run all tests
local results = RunComprehensiveTests()

-- Run individual test categories
TestVanillaDistricts()
TestCivilizationDistricts()
VerifyAdjacencyCalculations()
TestUIFunctionality()
TestPerformance()
```

### Manual Testing Checklist

- [ ] Mod loads without errors
- [ ] District placement UI appears correctly
- [ ] Adjacency numbers display on correct tiles
- [ ] Numbers update in real-time
- [ ] All vanilla districts work correctly
- [ ] Unique districts function properly
- [ ] Performance is acceptable
- [ ] No conflicts with other mods
- [ ] Works in different game scenarios

### Test Results Documentation

Record test results in the following format:

```
Test Date: [Date]
Game Version: [Civ VI Version]
Mod Version: [Mod Version]
Test Environment: [New Game/Loaded Game/Multiplayer]

Results:
- Vanilla Districts: [PASS/FAIL] - [Details]
- Unique Districts: [PASS/FAIL] - [Details]
- Calculations: [PASS/FAIL] - [X/Y tests passed]
- UI Functionality: [PASS/FAIL] - [Details]
- Performance: [GOOD/ACCEPTABLE/POOR] - [Metrics]
- Compatibility: [PASS/FAIL] - [Mods tested]

Issues Found:
- [List any bugs or issues discovered]

Overall Assessment: [PASS/FAIL]
```

## Troubleshooting

### Common Issues

1. **Numbers not appearing**
   - Check if district placement mode is active
   - Verify adjacent districts exist and are completed
   - Check console for error messages

2. **Incorrect calculations**
   - Run `VerifyAdjacencyCalculations()` to check rules
   - Verify district types are correctly identified
   - Check for mod conflicts

3. **Performance issues**
   - Run `PrintCacheStatistics()` to check cache efficiency
   - Clear cache with `ClearAdjacencyCache()` if needed
   - Check for memory leaks

4. **UI positioning problems**
   - Verify screen resolution compatibility
   - Check for UI scaling issues
   - Test with different camera angles

### Debug Commands

```lua
-- Enable debug output
DebugAdjacencyCalculation("DISTRICT_CAMPUS", 10, 10)

-- Check cache performance
PrintCacheStatistics()

-- Validate rules
ValidateAdjacencyRules()

-- Get UI state
GetUIState()
```

## Conclusion

This test documentation provides a comprehensive framework for validating the District Adjacency Preview mod. Regular testing using these procedures will ensure the mod maintains high quality and compatibility across different game scenarios and updates. 