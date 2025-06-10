-- Detailed Adjacency Preview - Integrated District Placement System
-- This mod calculates reverse adjacency bonuses for all compatible tiles during district placement

print("=== DETAILED ADJACENCY PREVIEW MOD: Starting to load ===");

-- ===========================================================================
-- GLOBAL VARIABLES
-- ===========================================================================

local g_isInDistrictPlacement = false;
local g_currentDistrictHash = nil;
local g_selectedCity = nil;
local g_compatibleTileSet = {}; -- Track which tiles are actually compatible for placement

-- ===========================================================================
-- DISTRICT PLACEMENT INTEGRATION
-- ===========================================================================

-- Track interface mode changes to detect district placement
function OnInterfaceModeChanged(oldMode, newMode)
    print("DetailedAdjacencyPreview: Interface mode changed from " .. tostring(oldMode) .. " to " .. tostring(newMode));
    print("DetailedAdjacencyPreview: DISTRICT_PLACEMENT mode = " .. tostring(InterfaceModeTypes.DISTRICT_PLACEMENT));
    
    if (newMode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
        print("DetailedAdjacencyPreview: Entered district placement mode!");
        OnDistrictPlacementEntered();
    elseif (oldMode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
        print("DetailedAdjacencyPreview: Exited district placement mode!");
        OnDistrictPlacementExited();
    end
end

-- Called when district placement mode is entered
function OnDistrictPlacementEntered()
    g_isInDistrictPlacement = true;
    
    -- Get the district type being placed
    g_currentDistrictHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE);
    print("DetailedAdjacencyPreview: District hash parameter = " .. tostring(g_currentDistrictHash));
    
    if (g_currentDistrictHash) then
        local districtInfo = GameInfo.Districts[g_currentDistrictHash];
        if (districtInfo) then
            print("DetailedAdjacencyPreview: Placing district: " .. districtInfo.DistrictType);
            
            -- Calculate reverse adjacency for ALL compatible tiles
            CalculateReverseAdjacencyForAllTiles(districtInfo);
        end
    end
end

-- Called when district placement mode is exited
function OnDistrictPlacementExited()
    g_isInDistrictPlacement = false;
    g_currentDistrictHash = nil;
    g_selectedCity = nil;
    g_compatibleTileSet = {}; -- Clear the compatible tile tracking
end

-- Calculate reverse adjacency bonuses for all compatible tiles
function CalculateReverseAdjacencyForAllTiles(districtInfo)
    print("DetailedAdjacencyPreview: === CALCULATING REVERSE ADJACENCY FOR ALL TILES ===");
    
    -- Get the selected city
    local selectedCity = Cities.GetCityInOperationRange();
    if (not selectedCity) then
        print("DetailedAdjacencyPreview: No selected city found!");
        return;
    end
    
    g_selectedCity = selectedCity;
    print("DetailedAdjacencyPreview: Selected city: " .. Locale.Lookup(selectedCity:GetName()));
    
    -- Use the NATIVE system to get compatible plots (same as StrategicView_MapPlacement.lua)
    local tParameters = {};
    tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = g_currentDistrictHash;
    tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_EXCLUSIVE;
    
    local tResults = CityManager.GetOperationTargets(selectedCity, CityOperationTypes.BUILD, tParameters);
    if (not tResults or not tResults[CityOperationResults.PLOTS]) then
        print("DetailedAdjacencyPreview: No compatible plots found!");
        return;
    end
    
    local compatiblePlots = tResults[CityOperationResults.PLOTS];
    print("DetailedAdjacencyPreview: Found " .. #compatiblePlots .. " compatible plots using native system");
    
    -- Clear and populate the compatible tile set for fast lookup
    g_compatibleTileSet = {};
    for i, plotID in ipairs(compatiblePlots) do
        local plot = Map.GetPlotByIndex(plotID);
        if (plot) then
            local tileKey = plot:GetX() .. "," .. plot:GetY();
            g_compatibleTileSet[tileKey] = true;
        end
    end
    
    local tilesWithBonuses = 0;
    
    -- Process each compatible tile for reverse adjacency
    for i, plotID in ipairs(compatiblePlots) do
        local plot = Map.GetPlotByIndex(plotID);
        if (plot) then
            print("DetailedAdjacencyPreview: --- Compatible tile at (" .. plot:GetX() .. "," .. plot:GetY() .. ") ---");
            
            local reverseBonuses = CalculateReverseBonusesForTile(plot, districtInfo);
            
            if (#reverseBonuses > 0) then
                tilesWithBonuses = tilesWithBonuses + 1;
                print("DetailedAdjacencyPreview: *** TILE (" .. plot:GetX() .. "," .. plot:GetY() .. ") HAS " .. #reverseBonuses .. " REVERSE BONUSES ***");
                
                for j, bonus in ipairs(reverseBonuses) do
                    print("DetailedAdjacencyPreview: -> +" .. bonus.Amount .. " [ICON_" .. bonus.YieldType .. "] " .. bonus.YieldType .. " to " .. bonus.DistrictType .. " at (" .. bonus.TargetX .. "," .. bonus.TargetY .. ")");
                end
                
                -- TODO: Display visual overlay for this tile (only for compatible tiles!)
                
            else
                print("DetailedAdjacencyPreview: No reverse bonuses for this tile");
            end
        end
    end
    
    print("DetailedAdjacencyPreview: === SUMMARY ===");
    print("DetailedAdjacencyPreview: Compatible tiles: " .. #compatiblePlots);
    print("DetailedAdjacencyPreview: Tiles with reverse bonuses: " .. tilesWithBonuses);
    print("DetailedAdjacencyPreview: === END CALCULATION ===");
end

-- Calculate reverse bonuses for a specific tile
function CalculateReverseBonusesForTile(targetPlot, newDistrictInfo)
    local reverseBonuses = {};
    
    -- Get all adjacent plots
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(targetPlot:GetX(), targetPlot:GetY(), direction);
        if (adjacentPlot) then
            
            -- Check if this adjacent plot has an existing district
            local existingDistrictType = adjacentPlot:GetDistrictType();
            if (existingDistrictType ~= -1) then
                local existingDistrictInfo = GameInfo.Districts[existingDistrictType];
                if (existingDistrictInfo) then
                    
                    -- Calculate what bonus the existing district would get from our new district
                    local bonus = CalculateAdjacencyBonus(existingDistrictInfo, newDistrictInfo);
                    if (bonus and bonus.Amount > 0) then
                        bonus.DistrictType = existingDistrictInfo.DistrictType;
                        bonus.TargetX = adjacentPlot:GetX();
                        bonus.TargetY = adjacentPlot:GetY();
                        table.insert(reverseBonuses, bonus);
                    end
                end
            end
        end
    end
    
    return reverseBonuses;
end

-- Calculate adjacency bonus between two districts
function CalculateAdjacencyBonus(receivingDistrictInfo, givingDistrictInfo)
    -- Query the adjacency rules for the receiving district
    for row in GameInfo.District_Adjacencies() do
        if (row.DistrictType == receivingDistrictInfo.DistrictType and 
            row.AdjacentDistrict == givingDistrictInfo.DistrictType) then
            
            return {
                Amount = row.YieldChange,
                YieldType = row.YieldType
            };
        end
    end
    
    return nil;
end

-- ===========================================================================
-- INITIALIZATION
-- ===========================================================================

-- Register for interface mode change events
Events.InterfaceModeChanged.Add(OnInterfaceModeChanged);

print("=== DETAILED ADJACENCY PREVIEW MOD: Loaded successfully ==="); 
print("=== DETAILED ADJACENCY PREVIEW MOD: FULLY LOADED ==="); 