-- Detailed Adjacency Preview - Integrated District Placement System
-- This mod calculates reverse adjacency bonuses for all compatible tiles during district placement

print("=== DETAILED ADJACENCY PREVIEW MOD: Starting to load ===");

-- ===========================================================================
-- GLOBAL VARIABLES
-- ===========================================================================

local g_isInDistrictPlacement = false;
local g_currentDistrictHash = nil;
local g_selectedCity = nil;

-- ===========================================================================
-- DISTRICT PLACEMENT INTEGRATION
-- ===========================================================================

-- Track interface mode changes and calculate reverse adjacency for all tiles
function OnInterfaceModeChanged(oldMode, newMode)
    print("DetailedAdjacencyPreview: Interface mode changed from " .. tostring(oldMode) .. " to " .. tostring(newMode));
    print("DetailedAdjacencyPreview: DISTRICT_PLACEMENT mode = " .. tostring(InterfaceModeTypes.DISTRICT_PLACEMENT));
    
    if newMode == InterfaceModeTypes.DISTRICT_PLACEMENT then
        print("DetailedAdjacencyPreview: Entered district placement mode!");
        g_isInDistrictPlacement = true;
        
        -- Check if we can get district type parameter
        local districtHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE);
        print("DetailedAdjacencyPreview: District hash parameter = " .. tostring(districtHash));
        
        if districtHash then
            g_currentDistrictHash = districtHash;
            local district = GameInfo.Districts[districtHash];
            if district then
                print("DetailedAdjacencyPreview: Placing district: " .. district.DistrictType);
                
                -- Calculate reverse adjacency bonuses for all compatible tiles
                CalculateReverseAdjacencyForAllTiles(district, districtHash);
            end
        end
        
    elseif oldMode == InterfaceModeTypes.DISTRICT_PLACEMENT then
        print("DetailedAdjacencyPreview: Exited district placement mode!");
        g_isInDistrictPlacement = false;
        g_currentDistrictHash = nil;
        g_selectedCity = nil;
    end
end

-- Calculate reverse adjacency bonuses for all compatible tiles in the selected city
function CalculateReverseAdjacencyForAllTiles(district, districtHash)
    print("DetailedAdjacencyPreview: === CALCULATING REVERSE ADJACENCY FOR ALL TILES ===");
    
    -- Get the selected city
    local localPlayer = Players[Game.GetLocalPlayer()];
    if not localPlayer then 
        print("DetailedAdjacencyPreview: No local player found");
        return;
    end
    
    -- Find the selected city (the one that's building the district)
    local selectedCity = UI.GetHeadSelectedCity();
    if not selectedCity then
        print("DetailedAdjacencyPreview: No selected city found");
        return;
    end
    
    g_selectedCity = selectedCity;
    local cityName = selectedCity:GetName();
    print("DetailedAdjacencyPreview: Selected city: " .. cityName);
    
    -- Get all plots that this city can potentially build on
    local cityPlots = GetCityPlots(selectedCity);
    print("DetailedAdjacencyPreview: Found " .. #cityPlots .. " total city plots");
    
    local compatibleTileCount = 0;
    local tilesWithBenefits = 0;
    
    -- Check each plot to see if it's compatible for this district
    for _, plot in ipairs(cityPlots) do
        local plotX, plotY = plot:GetX(), plot:GetY();
        
        -- Check if this plot can have the district we're trying to place
        if plot:CanHaveDistrict(district.Index, localPlayer:GetID(), selectedCity:GetID()) then
            compatibleTileCount = compatibleTileCount + 1;
            print("DetailedAdjacencyPreview: --- Compatible tile at (" .. plotX .. "," .. plotY .. ") ---");
            
            -- Calculate what reverse adjacency bonuses this placement would provide
            local reverseBonuses = GetReverseAdjacencyBonuses(plotX, plotY, selectedCity, districtHash);
            
            if #reverseBonuses > 0 then
                tilesWithBenefits = tilesWithBenefits + 1;
                print("DetailedAdjacencyPreview: *** TILE (" .. plotX .. "," .. plotY .. ") HAS " .. #reverseBonuses .. " REVERSE BONUSES ***");
                
                for _, bonus in ipairs(reverseBonuses) do
                    print("DetailedAdjacencyPreview: -> " .. bonus.bonus .. " to " .. bonus.districtName .. " at (" .. bonus.districtX .. "," .. bonus.districtY .. ")");
                end
            else
                print("DetailedAdjacencyPreview: No reverse bonuses for this tile");
            end
        end
    end
    
    print("DetailedAdjacencyPreview: === SUMMARY ===");
    print("DetailedAdjacencyPreview: Compatible tiles: " .. compatibleTileCount);
    print("DetailedAdjacencyPreview: Tiles with reverse bonuses: " .. tilesWithBenefits);
    print("DetailedAdjacencyPreview: === END CALCULATION ===");
end

-- Get all plots owned by or available to a city
function GetCityPlots(city)
    local plots = {};
    local cityPlots = city:GetOwnedPlots();
    
    -- Add owned plots
    for i, plotIndex in ipairs(cityPlots) do
        local plot = Map.GetPlotByIndex(plotIndex);
        if plot then
            table.insert(plots, plot);
        end
    end
    
    -- Add purchaseable plots
    local cityX, cityY = city:GetX(), city:GetY();
    for dx = -3, 3 do
        for dy = -3, 3 do
            local plotX = cityX + dx;
            local plotY = cityY + dy;
            local plot = Map.GetPlot(plotX, plotY);
            
            if plot and Cities.GetPlotPurchaseCity(plot) == city then
                -- Check if it's not already in our list
                local alreadyAdded = false;
                for _, existingPlot in ipairs(plots) do
                    if existingPlot:GetX() == plotX and existingPlot:GetY() == plotY then
                        alreadyAdded = true;
                        break;
                    end
                end
                
                if not alreadyAdded then
                    table.insert(plots, plot);
                end
            end
        end
    end
    
    return plots;
end

-- ===========================================================================
-- ADJACENCY CALCULATION FUNCTIONS  
-- ===========================================================================

-- Check if two plots are adjacent (including diagonally)
function IsAdjacentPlot(x1, y1, x2, y2)
    local dx = math.abs(x1 - x2);
    local dy = math.abs(y1 - y2);
    return (dx <= 1 and dy <= 1) and not (dx == 0 and dy == 0);
end

-- Calculate what benefits an existing district would get from a new district
function CalculateDistrictBenefitsFromNewDistrict(existingDistrictType, newDistrictType, existingDistrict, pCity)
    local benefits = {};
    
    -- Campus adjacency rules
    if existingDistrictType == GameInfo.Districts["DISTRICT_CAMPUS"].Index then
        local currentAdjacent = CountAdjacentDistricts(existingDistrict, pCity);
        local newAdjacent = currentAdjacent + 1; -- Adding one more district
        
        local currentBonus = math.floor(currentAdjacent / 2);
        local newBonus = math.floor(newAdjacent / 2);
        local additionalBonus = newBonus - currentBonus;
        
        if additionalBonus > 0 then
            table.insert(benefits, {
                text = "+" .. additionalBonus .. " [ICON_Science] Science",
                yieldType = "YIELD_SCIENCE",
                amount = additionalBonus
            });
        end
    end
    
    -- Commercial Hub adjacency rules  
    if existingDistrictType == GameInfo.Districts["DISTRICT_COMMERCIAL_HUB"].Index then
        table.insert(benefits, {
            text = "+0.5 [ICON_Gold] Gold",
            yieldType = "YIELD_GOLD", 
            amount = 0.5
        });
    end
    
    -- Industrial Zone adjacency rules
    if existingDistrictType == GameInfo.Districts["DISTRICT_INDUSTRIAL_ZONE"].Index then
        table.insert(benefits, {
            text = "+0.5 [ICON_Production] Production",
            yieldType = "YIELD_PRODUCTION",
            amount = 0.5
        });
    end
    
    -- Theater Square adjacency rules
    if existingDistrictType == GameInfo.Districts["DISTRICT_THEATER"].Index then
        table.insert(benefits, {
            text = "+0.5 [ICON_Culture] Culture",
            yieldType = "YIELD_CULTURE",
            amount = 0.5
        });
    end
    
    -- Holy Site adjacency rules
    if existingDistrictType == GameInfo.Districts["DISTRICT_HOLY_SITE"].Index then
        table.insert(benefits, {
            text = "+0.5 [ICON_Faith] Faith", 
            yieldType = "YIELD_FAITH",
            amount = 0.5
        });
    end
    
    return benefits;
end

-- Count how many districts are adjacent to the given district
function CountAdjacentDistricts(district, pCity)
    local count = 0;
    local districtX, districtY = district:GetX(), district:GetY();
    
    local cityDistricts = pCity:GetDistricts();
    for i, otherDistrict in cityDistricts:Members() do
        if otherDistrict:GetID() ~= district:GetID() then -- Don't count itself
            local otherX, otherY = otherDistrict:GetX(), otherDistrict:GetY();
            if IsAdjacentPlot(districtX, districtY, otherX, otherY) then
                count = count + 1;
            end
        end
    end
    
    return count;
end

-- Calculate reverse adjacency bonuses for a specific plot
function GetReverseAdjacencyBonuses(plotX, plotY, pCity, districtHash)
    local reverseBonuses = {};
    
    if not pCity or not districtHash then
        return reverseBonuses;
    end
    
    -- Get all existing districts in this city
    local cityDistricts = pCity:GetDistricts();
    for i, existingDistrict in cityDistricts:Members() do
        local districtType = existingDistrict:GetType();
        local districtX, districtY = existingDistrict:GetX(), existingDistrict:GetY();
        
        -- Check if the new district would be adjacent to this existing district
        if IsAdjacentPlot(plotX, plotY, districtX, districtY) then
            local benefits = CalculateDistrictBenefitsFromNewDistrict(districtType, districtHash, existingDistrict, pCity);
            
            if benefits and #benefits > 0 then
                for _, benefit in ipairs(benefits) do
                    table.insert(reverseBonuses, {
                        districtType = districtType,
                        districtX = districtX,
                        districtY = districtY,
                        bonus = benefit.text,
                        districtName = Locale.Lookup(GameInfo.Districts[districtType].Name)
                    });
                end
            end
        end
    end
    
    return reverseBonuses;
end

-- ===========================================================================
-- EVENT REGISTRATION
-- ===========================================================================

function Initialize()
    print("DetailedAdjacencyPreview: Registering event handlers");
    
    -- Register for interface mode changes
    Events.InterfaceModeChanged.Add(OnInterfaceModeChanged);
    print("DetailedAdjacencyPreview: Registered InterfaceModeChanged");
end

-- Initialize the mod
Initialize();

print("=== DETAILED ADJACENCY PREVIEW MOD: FULLY LOADED ==="); 