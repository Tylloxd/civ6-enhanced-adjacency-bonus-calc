-- Detailed Adjacency Preview - Native UI Integration
-- This mod hooks into the native adjacency visualization system to display reverse bonuses

print("DetailedAdjacencyPreview: Mod loaded successfully");

-- ===========================================================================
-- GLOBAL VARIABLES
-- ===========================================================================

local g_isInDistrictPlacement = false;
local g_currentDistrictHash = nil;
local g_selectedCity = nil;
local g_compatibleTileSet = {}; -- Track which tiles are actually compatible for placement
local g_originalRealizePlotArt = nil; -- Store reference to original function

-- ===========================================================================
-- DISTRICT PLACEMENT VALIDATION
-- ===========================================================================

-- Check if a plot is valid for placing a specific district type
function IsPlotValidForDistrict(plot, districtInfo, city)
    -- Basic checks that eliminate most invalid tiles
    if (not plot or not districtInfo or not city) then
        return false;
    end
    
    -- Check if plot is already occupied by a district or city center
    if (plot:IsCity() or CityManager.GetDistrictAt(plot) ~= nil) then
        return false;
    end
    
    -- Check if plot is water vs land requirements
    if (plot:IsWater()) then
        -- Only certain districts can be built on water (Harbor, etc.)
        if (districtInfo.DistrictType ~= "DISTRICT_HARBOR" and 
            districtInfo.DistrictType ~= "DISTRICT_ROYAL_NAVY_DOCKYARD") then -- Unique British Harbor
            return false;
        end
        -- Water districts need to be coastal
        if (not plot:IsCoastalLand() and not plot:IsWater()) then
            return false;
        end
    else
        -- Land districts cannot be built on water
        if (districtInfo.DistrictType == "DISTRICT_HARBOR" or 
            districtInfo.DistrictType == "DISTRICT_ROYAL_NAVY_DOCKYARD") then
            return false;
        end
    end
    
    -- Check terrain restrictions for specific districts
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    
    -- Mountains cannot have districts (except Machu Picchu wonder, but that's not a district)
    if (terrainType == GameInfo.Terrains["TERRAIN_SNOW_MOUNTAIN"] or 
        terrainType == GameInfo.Terrains["TERRAIN_GRASS_MOUNTAIN"] or
        terrainType == GameInfo.Terrains["TERRAIN_PLAINS_MOUNTAIN"] or
        terrainType == GameInfo.Terrains["TERRAIN_DESERT_MOUNTAIN"] or
        terrainType == GameInfo.Terrains["TERRAIN_TUNDRA_MOUNTAIN"]) then
        return false;
    end
    
    -- Aqueducts need fresh water access (this is complex to check properly)
    if (districtInfo.DistrictType == "DISTRICT_AQUEDUCT") then
        -- Simplified check: needs to be near river, lake, or mountain
        if (not plot:IsRiver() and not plot:IsLake() and 
            not IsAdjacentToFreshWater(plot) and not IsAdjacentToMountain(plot)) then
            return false;
        end
    end
    
    -- Most other placement rules are complex and depend on game state
    -- For now, if it passes these basic checks, consider it potentially valid
    return true;
end

-- Helper function to check if plot is adjacent to fresh water
function IsAdjacentToFreshWater(plot)
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
        if (adjacentPlot) then
            if (adjacentPlot:IsRiver() or adjacentPlot:IsLake()) then
                return true;
            end
        end
    end
    return false;
end

-- Helper function to check if plot is adjacent to mountain
function IsAdjacentToMountain(plot)
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
        if (adjacentPlot) then
            local terrainType = adjacentPlot:GetTerrainType();
            if (terrainType == GameInfo.Terrains["TERRAIN_SNOW_MOUNTAIN"] or 
                terrainType == GameInfo.Terrains["TERRAIN_GRASS_MOUNTAIN"] or
                terrainType == GameInfo.Terrains["TERRAIN_PLAINS_MOUNTAIN"] or
                terrainType == GameInfo.Terrains["TERRAIN_DESERT_MOUNTAIN"] or
                terrainType == GameInfo.Terrains["TERRAIN_TUNDRA_MOUNTAIN"]) then
                return true;
            end
        end
    end
    return false;
end

-- ===========================================================================
-- NATIVE SYSTEM INTEGRATION
-- ===========================================================================

-- Hook into the native RealizePlotArtForDistrictPlacement function
function HookNativeDistrictPlacement()
    -- The native function is not accessible from mod context
    -- Use interface mode tracking as our primary approach
    print("DetailedAdjacencyPreview: Using interface mode tracking for district placement detection");
    return false; -- Indicate hooking was not successful
end

-- Enhanced version that adds reverse bonuses to native visualization (unused for now)
function RealizePlotArtForDistrictPlacement_Enhanced()
    -- This function is not currently used since we can't hook the native system
    -- Add our reverse bonus enhancements
    AddReverseBonusesToNativeVisualization();
end

-- Track interface mode changes as fallback
function OnInterfaceModeChanged(oldMode, newMode)
    if (newMode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
        print("DetailedAdjacencyPreview: Entered district placement mode");
        OnDistrictPlacementEntered();
    elseif (oldMode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
        print("DetailedAdjacencyPreview: Exited district placement mode");
        OnDistrictPlacementExited();
    end
end

-- Add reverse bonuses to the native visualization system
function AddReverseBonusesToNativeVisualization()
    local pSelectedCity = UI.GetHeadSelectedCity();
    if (not pSelectedCity) then
        return;
    end
    
    local districtHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE);
    if (not districtHash) then
        return;
    end
    
    local districtInfo = GameInfo.Districts[districtHash];
    if (not districtInfo) then
        return;
    end
    
    print("DetailedAdjacencyPreview: Adding reverse bonuses to native visualization for " .. districtInfo.DistrictType);
    
    -- Get compatible plots using same method as native system
    local tParameters = {};
    tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtHash;
    
    local tResults = CityManager.GetOperationTargets(pSelectedCity, CityOperationTypes.BUILD, tParameters);
    if (not tResults or not tResults[CityOperationResults.PLOTS]) then
        return;
    end
    
    -- Process each compatible plot for reverse bonuses
    for i, plotId in ipairs(tResults[CityOperationResults.PLOTS]) do
        local plot = Map.GetPlotByIndex(plotId);
        if (plot) then
            AddReverseBonusesToPlot(plot, districtInfo, pSelectedCity);
        end
    end
end

-- Called when district placement mode is entered
function OnDistrictPlacementEntered()
    g_isInDistrictPlacement = true;
    
    -- Get the district type being placed
    g_currentDistrictHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE);
    
    if (g_currentDistrictHash) then
        local districtInfo = GameInfo.Districts[g_currentDistrictHash];
        if (districtInfo) then
            print("DetailedAdjacencyPreview: Calculating reverse adjacency for " .. districtInfo.DistrictType);
            
            -- Calculate reverse adjacency for ALL compatible tiles (console output)
            CalculateReverseAdjacencyForAllTiles(districtInfo);
            
            -- Also try our visualization approach
            AddReverseBonusesToNativeVisualization();
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
    -- Get the selected city (use same method as native game)
    local selectedCity = UI.GetHeadSelectedCity();
    if (not selectedCity) then
        print("DetailedAdjacencyPreview: Error - No selected city found");
        return;
    end
    
    g_selectedCity = selectedCity;
    
    -- Use the NATIVE system to get compatible plots (same as StrategicView_MapPlacement.lua)
    local tParameters = {};
    tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = g_currentDistrictHash;
    tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_EXCLUSIVE;
    
    -- Check if CityManager functions exist
    if (not CityManager or not CityManager.GetOperationTargets) then
        print("DetailedAdjacencyPreview: Error - CityManager.GetOperationTargets not available");
        return;
    end
    
    -- Get immediately placeable tiles
    local tResults = CityManager.GetOperationTargets(selectedCity, CityOperationTypes.BUILD, tParameters);
    if (not tResults or not tResults[CityOperationResults.PLOTS]) then
        print("DetailedAdjacencyPreview: No compatible plots found");
        return;
    end
    
    local compatiblePlots = tResults[CityOperationResults.PLOTS];
    
    -- Get purchasable tiles that are also valid for this specific district type
    local purchasableParameters = {};
    purchasableParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);
    
    local purchasableResults = CityManager.GetCommandTargets(selectedCity, CityCommandTypes.PURCHASE, purchasableParameters);
    if (purchasableResults and purchasableResults[CityCommandResults.PLOTS] and table.count(purchasableResults[CityCommandResults.PLOTS]) > 0) then
        print("DetailedAdjacencyPreview: Found " .. #purchasableResults[CityCommandResults.PLOTS] .. " total purchasable plots");
        
        -- Filter purchasable plots to only include those suitable for this district type
        local validPurchasablePlots = {};
        for i, plotID in ipairs(purchasableResults[CityCommandResults.PLOTS]) do
            local plot = Map.GetPlotByIndex(plotID);
            if (plot and IsPlotValidForDistrict(plot, districtInfo, selectedCity)) then
                table.insert(validPurchasablePlots, plotID);
            end
        end
        
        print("DetailedAdjacencyPreview: Filtered to " .. #validPurchasablePlots .. " purchasable plots suitable for " .. districtInfo.DistrictType);
        
        -- Add valid purchasable plots to our list
        for i, plotID in ipairs(validPurchasablePlots) do
            -- Only add if not already in the list
            local alreadyExists = false;
            for j, existingPlotID in ipairs(compatiblePlots) do
                if (plotID == existingPlotID) then
                    alreadyExists = true;
                    break;
                end
            end
            if (not alreadyExists) then
                table.insert(compatiblePlots, plotID);
                print("DetailedAdjacencyPreview: Added valid purchasable tile to compatible list: " .. plotID);
            end
        end
    else
        print("DetailedAdjacencyPreview: No purchasable plots found");
    end
    
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
    local totalBonuses = 0;
    local availableTiles = 0;
    local purchasableTiles = 0;
    local bonusesOnAvailable = 0;
    local bonusesOnPurchasable = 0;
    
    -- Process each compatible tile for reverse adjacency
    for i, plotID in ipairs(compatiblePlots) do
        local plot = Map.GetPlotByIndex(plotID);
        if (plot) then
            -- Determine tile ownership for display purposes
            local plotOwner = plot:GetOwner();
            local cityOwner = selectedCity:GetOwner();
            local isOwned = (plotOwner == cityOwner);
            
            local reverseBonuses = CalculateReverseBonusesForTile(plot, districtInfo);
            
            if (#reverseBonuses > 0) then
                tilesWithBonuses = tilesWithBonuses + 1;
                totalBonuses = totalBonuses + #reverseBonuses;
                
                -- Use previously determined ownership status
                
                if (isOwned) then
                    availableTiles = availableTiles + 1;
                    bonusesOnAvailable = bonusesOnAvailable + #reverseBonuses;
                else
                    purchasableTiles = purchasableTiles + 1;
                    bonusesOnPurchasable = bonusesOnPurchasable + #reverseBonuses;
                end
                
                -- Display reverse bonuses for this tile with simple status
                local statusIcon = isOwned and "🟢" or "🟡";
                local statusText = isOwned and "(owned)" or "(purchasable)";
                for j, bonus in ipairs(reverseBonuses) do
                    print("DetailedAdjacencyPreview: " .. statusIcon .. " Tile (" .. plot:GetX() .. "," .. plot:GetY() .. ") -> +" .. bonus.Amount .. " " .. bonus.YieldType .. " to " .. bonus.DistrictType .. " " .. statusText);
                end
                
                -- TODO: Display visual overlay for this tile (differentiate by availability!)
            else
                -- Count tiles without bonuses for completeness
                local plotOwner = plot:GetOwner();
                local cityOwner = selectedCity:GetOwner();
                if (plotOwner == cityOwner) then
                    availableTiles = availableTiles + 1;
                else
                    purchasableTiles = purchasableTiles + 1;
                end
            end
        end
    end
    
    -- Enhanced summary with tile availability breakdown
    if (totalBonuses > 0) then
        print("DetailedAdjacencyPreview: Found " .. totalBonuses .. " reverse bonuses across " .. tilesWithBonuses .. " tiles (out of " .. #compatiblePlots .. " compatible)");
        if (bonusesOnAvailable > 0) then
            print("DetailedAdjacencyPreview: 🟢 " .. bonusesOnAvailable .. " bonuses on " .. availableTiles .. " available tiles (immediate placement)");
        end
        if (bonusesOnPurchasable > 0) then
            print("DetailedAdjacencyPreview: 🟡 " .. bonusesOnPurchasable .. " bonuses on " .. purchasableTiles .. " purchasable tiles (gold required)");
        end
    else
        print("DetailedAdjacencyPreview: No reverse adjacency bonuses found for any compatible tiles");
        if (availableTiles > 0 or purchasableTiles > 0) then
            print("DetailedAdjacencyPreview: 🟢 " .. availableTiles .. " available tiles, 🟡 " .. purchasableTiles .. " purchasable tiles");
        end
    end
end

-- Simplified tile availability - leverage game's existing logic
function GetTileAvailabilityStatus(plot, city)
    local plotOwner = plot:GetOwner();
    local cityOwner = city:GetOwner();
    
    -- Simple check: if same owner, assume available (game handles the complexity)
    if (plotOwner == cityOwner) then
        return "available";  -- 🟢 Owned by player (game determines if immediately placeable)
    end
    
    -- If unowned, assume potentially purchasable (game will show if actually purchasable)
    if (plotOwner == -1) then
        return "purchasable";  -- 🟡 Unowned (game determines if purchasable)
    end
    
    return "unavailable";  -- 🔴 Owned by someone else
end

-- Calculate reverse bonuses for a specific tile
function CalculateReverseBonusesForTile(targetPlot, newDistrictInfo)
    local reverseBonuses = {};
    local adjacentDistricts = 0;
    
    -- Get all adjacent plots
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(targetPlot:GetX(), targetPlot:GetY(), direction);
        if (adjacentPlot) then
            -- Check if this adjacent plot has an existing district (use native method)
            local pDistrict = CityManager.GetDistrictAt(adjacentPlot);
            
            if (pDistrict ~= nil and pDistrict:IsComplete()) then
                adjacentDistricts = adjacentDistricts + 1;
                local existingDistrictInfo = GameInfo.Districts[pDistrict:GetType()];
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
    
    -- Note: Some tiles may have adjacent districts but provide no bonuses due to specific adjacency rules
    
    return reverseBonuses;
end

-- Calculate adjacency bonus between two districts
function CalculateAdjacencyBonus(receivingDistrictInfo, givingDistrictInfo)
    local totalBonus = {
        Amount = 0,
        YieldType = nil
    };
    
    -- Query the adjacency rules for the receiving district using the correct database structure
    for row in GameInfo.District_Adjacencies() do
        if (row.DistrictType == receivingDistrictInfo.DistrictType) then
            -- Access the yield change data from the reference table
            local yieldChangeRef = row.YieldChangeReference;
            if (yieldChangeRef) then
                local yieldChangeId = row.YieldChangeId or "";
                local yieldType = yieldChangeRef.YieldType;
                local yieldChange = yieldChangeRef.YieldChange;
                
                if (yieldType and yieldChange) then
                    local bonusApplies = false;
                    
                    -- Extract the district name without "DISTRICT_" prefix for flexible matching
                    local districtName = string.gsub(givingDistrictInfo.DistrictType, "DISTRICT_", "");
                    
                    -- Check for specific district-to-district adjacency rules first
                    -- Look for rules that specifically mention the giving district type
                    if (string.find(yieldChangeId, givingDistrictInfo.DistrictType) or  -- Full name match
                        string.find(yieldChangeId, districtName) or                    -- Name without prefix
                        (districtName == "COMMERCIAL_HUB" and string.find(yieldChangeId, "Commerical_Hub"))) then  -- Handle typo
                        bonusApplies = true;
                    
                    -- Check for generic district adjacency rules
                    elseif (string.find(yieldChangeId, "District") or string.find(yieldChangeId, "DISTRICT")) then
                        bonusApplies = true;
                    end
                    
                    -- Add this bonus to the total
                    if (bonusApplies) then
                        totalBonus.Amount = totalBonus.Amount + yieldChange;
                        totalBonus.YieldType = yieldType; -- Most districts have single yield type per rule
                    end
                end
            end
        end
    end
    
    -- Return the total bonus if any was found
    if (totalBonus.Amount > 0) then
        return totalBonus;
    end
    
    return nil;
end

-- ===========================================================================
-- NATIVE UI INTEGRATION FUNCTIONS
-- ===========================================================================

-- Add reverse bonuses to a specific plot using native visualization
function AddReverseBonusesToPlot(plot, newDistrictInfo, pSelectedCity)
    local reverseBonuses = CalculateReverseBonusesForTile(plot, newDistrictInfo);
    
    if (#reverseBonuses == 0) then
        return; -- No reverse bonuses for this plot
    end
    
    -- Create central bonus display text
    local centralBonusText = CreateCentralBonusText(reverseBonuses);
    local tooltipText = CreateReverseBonusTooltip(reverseBonuses);
    
    -- Try to enhance existing plotInfo if it exists in native system
    -- Since we don't have direct access to m_hexesDistrictPlacement from native code,
    -- we'll use a different approach - create our own overlay
    
    print("DetailedAdjacencyPreview: Adding visual bonuses to plot (" .. plot:GetX() .. "," .. plot:GetY() .. ") - " .. centralBonusText);
    
    -- For now, create custom overlay (will integrate better once we can access native data structures)
    CreateCustomReverseBonusOverlay(plot, centralBonusText, tooltipText, reverseBonuses);
end

-- Create formatted text for central bonus display
function CreateCentralBonusText(reverseBonuses)
    local bonusByYield = {};
    
    -- Aggregate bonuses by yield type
    for _, bonus in ipairs(reverseBonuses) do
        local yieldType = bonus.YieldType;
        if (not bonusByYield[yieldType]) then
            bonusByYield[yieldType] = 0;
        end
        bonusByYield[yieldType] = bonusByYield[yieldType] + bonus.Amount;
    end
    
    -- Format as yield strings
    local bonusTexts = {};
    for yieldType, amount in pairs(bonusByYield) do
        if (amount > 0) then
            -- Convert yield type to icon name (remove YIELD_ prefix)
            local iconName = string.gsub(yieldType, "YIELD_", "");
            local yieldString = "[ICON_" .. iconName .. "]+" .. amount;
            table.insert(bonusTexts, yieldString);
        end
    end
    
    return table.concat(bonusTexts, " ");
end

-- Create detailed tooltip for reverse bonuses
function CreateReverseBonusTooltip(reverseBonuses)
    local tooltipLines = {};
    
    for _, bonus in ipairs(reverseBonuses) do
        -- Use simple district and yield names for now
        local districtName = bonus.DistrictType;
        local yieldName = bonus.YieldType;
        local line = "+" .. bonus.Amount .. " " .. yieldName .. " to " .. districtName;
        table.insert(tooltipLines, line);
    end
    
    return table.concat(tooltipLines, " | ");
end

-- Create custom overlay for reverse bonuses (temporary solution)
function CreateCustomReverseBonusOverlay(plot, bonusText, tooltipText, reverseBonuses)
    -- This is a simplified approach - in a full implementation we would:
    -- 1. Access the native m_hexesDistrictPlacement table
    -- 2. Modify the plotInfo.adjacent array to add our edge icons
    -- 3. Add our bonus text to the central display
    -- 4. Let UILens.SetAdjacencyBonusDistict() handle the rendering
    
    -- For testing, we'll just log the visual information
    print("DetailedAdjacencyPreview: VISUAL - Plot (" .. plot:GetX() .. "," .. plot:GetY() .. ") would show:");
    print("DetailedAdjacencyPreview: VISUAL - Central: " .. bonusText);
    print("DetailedAdjacencyPreview: VISUAL - Tooltip: " .. tooltipText);
    
    -- Show edge connections to existing districts
    for _, bonus in ipairs(reverseBonuses) do
        local direction = GetDirectionToTarget(plot, bonus.TargetX, bonus.TargetY);
        print("DetailedAdjacencyPreview: VISUAL - Edge icon: " .. bonus.YieldType .. " flowing to district at (" .. bonus.TargetX .. "," .. bonus.TargetY .. ")");
    end
end

-- Get direction from source plot to target plot
function GetDirectionToTarget(sourcePlot, targetX, targetY)
    local sourceX = sourcePlot:GetX();
    local sourceY = sourcePlot:GetY();
    
    -- Calculate relative position
    local deltaX = targetX - sourceX;
    local deltaY = targetY - sourceY;
    
    -- Convert to direction (simplified - real implementation would be more precise)
    if (deltaX > 0 and deltaY == 0) then return DirectionTypes.DIRECTION_EAST;
    elseif (deltaX < 0 and deltaY == 0) then return DirectionTypes.DIRECTION_WEST;
    elseif (deltaX == 0 and deltaY > 0) then return DirectionTypes.DIRECTION_SOUTHEAST;
    elseif (deltaX == 0 and deltaY < 0) then return DirectionTypes.DIRECTION_NORTHWEST;
    elseif (deltaX > 0 and deltaY > 0) then return DirectionTypes.DIRECTION_NORTHEAST;
    elseif (deltaX < 0 and deltaY < 0) then return DirectionTypes.DIRECTION_SOUTHWEST;
    else return DirectionTypes.DIRECTION_EAST; -- Default
    end
end

-- ===========================================================================
-- INITIALIZATION
-- ===========================================================================

-- Initialize the mod with interface mode tracking
function Initialize()
    local hookSuccess = HookNativeDistrictPlacement();
    
    -- Register interface mode changes (our primary method)
    Events.InterfaceModeChanged.Add(OnInterfaceModeChanged);
    
    print("DetailedAdjacencyPreview: Initialization complete - ready for district placement");
end

-- Initialize the mod
Initialize(); 