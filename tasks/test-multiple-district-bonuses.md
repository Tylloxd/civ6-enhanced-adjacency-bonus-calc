# Test Plan: Multiple District Reverse Bonus Detection

## Test Objective
Verify that our Detailed Adjacency Preview mod correctly detects and calculates reverse adjacency bonuses when placing a single district that would benefit multiple existing districts.

## Test Scenario Setup

### Ideal Test Configuration
1. **Start a new game** with a civilization that has good early production (e.g., Germany, Rome, or China)
2. **Rush to Classical Era** to unlock multiple district types
3. **Build a city with 2-3 existing districts** placed strategically
4. **Test district placement** where one new district would be adjacent to multiple existing districts

### Recommended District Combinations for Testing

#### Test Case 1: Commercial Hub benefiting Campus + Industrial Zone
- **Setup**: Place a Campus and Industrial Zone with one tile gap between them
- **Test**: Try placing a Commercial Hub in the gap
- **Expected Results**: 
  - Campus should receive: `+1 YIELD_SCIENCE` (from Commercial Hub)
  - Industrial Zone should receive: `+1 YIELD_PRODUCTION` (from Commercial Hub)
  - **Total**: 2 reverse bonuses from 1 placement

#### Test Case 2: Aqueduct benefiting Industrial Zone + Theater Square  
- **Setup**: Place Industrial Zone and Theater Square near water source
- **Test**: Try placing an Aqueduct adjacent to both
- **Expected Results**:
  - Industrial Zone should receive: `+2 YIELD_PRODUCTION` (Aqueduct is major adjacency)
  - Theater Square should receive: `+1 YIELD_CULTURE` (from Aqueduct) 
  - **Total**: 2 reverse bonuses with different yield types

#### Test Case 3: Industrial Zone benefiting Campus + Commercial Hub + Aqueduct
- **Setup**: Create a dense district cluster with Campus, Commercial Hub, and Aqueduct
- **Test**: Try placing Industrial Zone adjacent to all three
- **Expected Results**:
  - Campus should receive: `+1 YIELD_SCIENCE` (from Industrial Zone)
  - Commercial Hub should receive: `+1 YIELD_GOLD` (from Industrial Zone)
  - Aqueduct should receive: `+2 YIELD_PRODUCTION` (Industrial Zone is major adjacency to infrastructure)
  - **Total**: 3 reverse bonuses from 1 placement

## Expected Console Output Format

When testing multiple district bonuses, we should see output like:

```
DetailedAdjacencyPreview: Calculating reverse adjacency for DISTRICT_COMMERCIAL_HUB
DetailedAdjacencyPreview: 🟢 Tile (35,40) -> +1 YIELD_SCIENCE to DISTRICT_CAMPUS (owned)
DetailedAdjacencyPreview: 🟢 Tile (35,40) -> +1 YIELD_PRODUCTION to DISTRICT_INDUSTRIAL_ZONE (owned)
DetailedAdjacencyPreview: Found 2 reverse bonuses across 1 tiles (out of 8 compatible)
DetailedAdjacencyPreview: 🟢 2 bonuses on 1 available tiles (immediate placement)
```

## Verification Checklist

- [ ] **Multiple Bonuses Detected**: Verify that placing one district can show bonuses to multiple existing districts
- [ ] **Correct Yield Types**: Ensure each bonus shows the correct yield type (SCIENCE, PRODUCTION, CULTURE, etc.)
- [ ] **Accurate Amounts**: Verify bonus amounts match actual adjacency rules
- [ ] **Distinct Districts**: Confirm that each bonus specifies which existing district would benefit
- [ ] **Aggregation Logic**: Check that the summary correctly counts total bonuses
- [ ] **No Duplicates**: Ensure no duplicate bonuses are displayed for the same district
- [ ] **Performance**: Verify calculations complete quickly even with multiple districts

## Success Criteria

✅ **PASS**: If placing one district correctly identifies and displays reverse bonuses for 2+ existing districts  
✅ **PASS**: If each bonus shows correct yield type, amount, and target district  
✅ **PASS**: If summary statistics accurately reflect the number of bonuses found  
❌ **FAIL**: If multiple bonuses are missed, incorrectly calculated, or duplicated  

## Notes for Testing

- Use console output (`~` key) to see detailed mod messages
- Test with different district types to verify adjacency rule coverage
- Try both immediate placement tiles (🟢) and purchasable tiles (🟡)
- Pay attention to tiles that show multiple bonuses vs. single bonuses
- Verify that the mod works correctly with unique civilization districts (if available)

## Recent Fix Applied

**ISSUE IDENTIFIED**: Purchasable tile detection was including ALL purchasable tiles, not just those suitable for the specific district being previewed.

**SOLUTION IMPLEMENTED**: Added `IsPlotValidForDistrict()` function that filters purchasable tiles to only include those that can actually support the district type being placed. This includes checks for:
- Plot occupation (existing districts, city centers)
- Water vs land requirements (Harbor on water, other districts on land)
- Terrain restrictions (mountains, etc.)
- Special requirements (Aqueduct fresh water access)

**Expected Result**: Purchasable tile count should now match the actual buildable locations shown in the game's district placement preview.

---

**Status**: ✅ **FIXED** - Ready for re-testing with corrected purchasable tile filtering  
**Last Updated**: Fixed purchasable tile filtering to only include district-compatible tiles 