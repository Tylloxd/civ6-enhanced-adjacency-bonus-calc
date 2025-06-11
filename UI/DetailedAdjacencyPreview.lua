-- Detailed Adjacency Preview - Native System Integration
-- This mod enhances the native adjacency bonus display by adding reverse bonuses
-- to the central tile bonus text during district placement

print("DetailedAdjacencyPreview: Native Integration Mod loaded successfully");

-- ===========================================================================
-- GLOBAL VARIABLES
-- ===========================================================================

local g_originalGetAdjacentYieldBonusString = nil;
local g_isModEnabled = true;
local g_currentDistrictHash = nil;
local g_functionCallCount = 0; -- Track how many times our function is called

-- ===========================================================================
-- UTILITY FUNCTIONS
-- ===========================================================================

-- Get yield string in the format used by the game (e.g. "[ICON_GOLD]+2")
function GetYieldString_Enhanced(yieldType, amount)
    if (amount <= 0) then
        return "";
    end
    
    -- Convert yield type to icon format
    local iconName = "[ICON_" .. string.gsub(yieldType, "YIELD_", "") .. "]";
    return iconName .. "+" .. tostring(amount);
end

-- Check if two plots are adjacent
function ArePlotsAdjacent(plot1, plot2)
    if (not plot1 or not plot2) then
        return false;
    end
    
    local x1, y1 = plot1:GetX(), plot1:GetY();
    local x2, y2 = plot2:GetX(), plot2:GetY();
    
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
        local adjacentPlot = Map.GetAdjacentPlot(x1, y1, direction);
        if (adjacentPlot and adjacentPlot:GetX() == x2 and adjacentPlot:GetY() == y2) then
            return true;
        end
    end
    
    return false;
end

-- Get the primary yield type for a district
function GetDistrictYieldType(districtInfo)
    -- Map district types to their primary yields
    local districtYields = {
        ["DISTRICT_CAMPUS"] = "YIELD_SCIENCE",
        ["DISTRICT_THEATER"] = "YIELD_CULTURE", 
        ["DISTRICT_HOLY_SITE"] = "YIELD_FAITH",
        ["DISTRICT_COMMERCIAL_HUB"] = "YIELD_GOLD",
        ["DISTRICT_HARBOR"] = "YIELD_GOLD",
        ["DISTRICT_INDUSTRIAL_ZONE"] = "YIELD_PRODUCTION",
        ["DISTRICT_HANSA"] = "YIELD_PRODUCTION", -- German unique
        ["DISTRICT_OPPIDUM"] = "YIELD_PRODUCTION", -- Gallic unique
        ["DISTRICT_ROYAL_NAVY_DOCKYARD"] = "YIELD_GOLD", -- English unique
        ["DISTRICT_ACROPOLIS"] = "YIELD_CULTURE", -- Greek unique
        ["DISTRICT_LAVRA"] = "YIELD_FAITH", -- Russian unique
        ["DISTRICT_COTHON"] = "YIELD_GOLD", -- Phoenician unique
        ["DISTRICT_SUGUBA"] = "YIELD_GOLD", -- Mali unique
    };
    
    return districtYields[districtInfo.DistrictType] or "YIELD_PRODUCTION";
end

-- ===========================================================================
-- REVERSE BONUS CALCULATION
-- ===========================================================================

-- Calculate the bonus an existing district would get from a new adjacent district
function CalculateAdjacentBonusFromNewDistrict(existingDistrictInfo, newDistrictInfo)
    local totalBonus = 0;
    
    print("DetailedAdjacencyPreview: DEBUG - Checking adjacency rules for " .. existingDistrictInfo.DistrictType .. " from new " .. newDistrictInfo.DistrictType);
    
    -- Query all adjacency rules for the existing district type
    for row in GameInfo.District_Adjacencies() do
        if (row.DistrictType == existingDistrictInfo.DistrictType) then
            -- Check if this rule applies to the new district type
            if (row.AdjacentDistrict == newDistrictInfo.DistrictType) then
                totalBonus = totalBonus + (row.YieldChange or 0);
                print("DetailedAdjacencyPreview: FOUND - Specific adjacency rule: " .. existingDistrictInfo.DistrictType .. 
                      " gets +" .. (row.YieldChange or 0) .. " from adjacent " .. newDistrictInfo.DistrictType);
            elseif (row.AdjacentDistrict == "DISTRICT_GENERIC" and newDistrictInfo.DistrictType ~= "DISTRICT_CITY_CENTER") then
                totalBonus = totalBonus + (row.YieldChange or 0);
                print("DetailedAdjacencyPreview: FOUND - Generic adjacency rule: " .. existingDistrictInfo.DistrictType .. 
                      " gets +" .. (row.YieldChange or 0) .. " from adjacent district " .. newDistrictInfo.DistrictType);
            end
        end
    end
    
    print("DetailedAdjacencyPreview: DEBUG - Total bonus calculated: " .. totalBonus);
    return totalBonus;
end

-- Calculate what bonuses existing districts would receive from a new district at this plot
function CalculateReverseBonuses(plot, newDistrictInfo, city)
    local reverseBonuses = {};
    
    print("DetailedAdjacencyPreview: DEBUG - CalculateReverseBonuses called for plot (" .. plot:GetX() .. "," .. plot:GetY() .. ") with district " .. newDistrictInfo.DistrictType);
    
    if (not plot or not newDistrictInfo or not city) then
        print("DetailedAdjacencyPreview: DEBUG - Invalid parameters passed to CalculateReverseBonuses");
        return reverseBonuses;
    end
    
    -- Get all existing districts in the city
    local cityDistricts = city:GetDistricts();
    local districtCount = 0;
    
    for i, existingDistrict in cityDistricts:Members() do
        districtCount = districtCount + 1;
        local existingDistrictInfo = GameInfo.Districts[existingDistrict:GetType()];
        print("DetailedAdjacencyPreview: DEBUG - Found existing district: " .. (existingDistrictInfo and existingDistrictInfo.DistrictType or "UNKNOWN"));
        
        if (existingDistrictInfo and existingDistrictInfo.DistrictType ~= "DISTRICT_CITY_CENTER") then
            local existingPlot = Map.GetPlot(existingDistrict:GetX(), existingDistrict:GetY());
            
            -- Check if the new district would be adjacent to this existing district
            if (existingPlot and ArePlotsAdjacent(plot, existingPlot)) then
                print("DetailedAdjacencyPreview: DEBUG - District " .. existingDistrictInfo.DistrictType .. " at (" .. 
                      existingPlot:GetX() .. "," .. existingPlot:GetY() .. ") is adjacent to new placement");
                
                -- Calculate what bonus the existing district would get
                local bonus = CalculateAdjacentBonusFromNewDistrict(existingDistrictInfo, newDistrictInfo);
                if (bonus > 0) then
                    local bonusInfo = {
                        amount = bonus,
                        yieldType = GetDistrictYieldType(existingDistrictInfo),
                        districtName = existingDistrictInfo.Name,
                        districtType = existingDistrictInfo.DistrictType,
                        location = {x = existingPlot:GetX(), y = existingPlot:GetY()}
                    };
                    table.insert(reverseBonuses, bonusInfo);
                    
                    print("DetailedAdjacencyPreview: SUCCESS - Found reverse bonus: +" .. bonus .. " " .. 
                          bonusInfo.yieldType .. " to " .. existingDistrictInfo.DistrictType .. 
                          " at (" .. existingPlot:GetX() .. "," .. existingPlot:GetY() .. ")");
                else
                    print("DetailedAdjacencyPreview: DEBUG - No bonus calculated for adjacent district " .. existingDistrictInfo.DistrictType);
                end
            else
                print("DetailedAdjacencyPreview: DEBUG - District " .. existingDistrictInfo.DistrictType .. " is not adjacent to new placement");
            end
        end
    end
    
    print("DetailedAdjacencyPreview: DEBUG - Total districts in city: " .. districtCount);
    print("DetailedAdjacencyPreview: DEBUG - Total reverse bonuses found: " .. #reverseBonuses);
    
    return reverseBonuses;
end

-- ===========================================================================
-- NATIVE FUNCTION INTEGRATION
-- ===========================================================================

-- Enhanced version of GetAdjacentYieldBonusString that includes reverse bonuses
function GetAdjacentYieldBonusString_Enhanced(eDistrict, pkCity, plot)
    g_functionCallCount = g_functionCallCount + 1;
    print("DetailedAdjacencyPreview: FUNCTION CALLED #" .. g_functionCallCount .. " - GetAdjacentYieldBonusString_Enhanced for plot (" .. 
          (plot and plot:GetX() or "nil") .. "," .. (plot and plot:GetY() or "nil") .. ")");
    
    -- Call the original function first to get the base bonuses
    local originalBonus, originalTooltip, originalRequired = g_originalGetAdjacentYieldBonusString(eDistrict, pkCity, plot);
    
    print("DetailedAdjacencyPreview: DEBUG - Original function returned: '" .. (originalBonus or "nil") .. "'");
    
    if (not g_isModEnabled or not plot or not pkCity) then
        print("DetailedAdjacencyPreview: DEBUG - Mod disabled or invalid parameters, returning original result");
        return originalBonus, originalTooltip, originalRequired;
    end
    
    -- Get reverse bonuses that existing districts would receive if this plot had a district
    local reverseBonuses = {};
    local districtInfo = GameInfo.Districts[eDistrict];
    if (districtInfo) then
        print("DetailedAdjacencyPreview: DEBUG - Calculating reverse bonuses for district: " .. districtInfo.DistrictType);
        reverseBonuses = CalculateReverseBonuses(plot, districtInfo, pkCity);
    else
        print("DetailedAdjacencyPreview: DEBUG - Could not find district info for eDistrict: " .. tostring(eDistrict));
    end
    
    -- Enhance the bonus text if we have reverse bonuses
    local enhancedBonus = originalBonus or "";
    local enhancedTooltip = originalTooltip or "";
    
    if (reverseBonuses and #reverseBonuses > 0) then
        print("DetailedAdjacencyPreview: ENHANCING - Adding " .. #reverseBonuses .. " reverse bonuses to plot (" .. plot:GetX() .. "," .. plot:GetY() .. ")");
        
        -- Add reverse bonuses to the display text
        for _, reverseBonus in ipairs(reverseBonuses) do
            local yieldString = GetYieldString_Enhanced(reverseBonus.yieldType, reverseBonus.amount);
            if (yieldString ~= "") then
                if (enhancedBonus == "") then
                    enhancedBonus = yieldString;
                else
                    enhancedBonus = enhancedBonus .. ", " .. yieldString;
                end
                
                -- Add to tooltip
                if (enhancedTooltip ~= "") then
                    enhancedTooltip = enhancedTooltip .. "[NEWLINE]";
                end
                enhancedTooltip = enhancedTooltip .. "+" .. reverseBonus.amount .. " " .. 
                                 Locale.Lookup("LOC_" .. reverseBonus.yieldType .. "_NAME") .. 
                                 " to " .. Locale.Lookup(reverseBonus.districtName);
            end
        end
        
        print("DetailedAdjacencyPreview: FINAL RESULT - Enhanced bonus: '" .. enhancedBonus .. "'");
    else
        print("DetailedAdjacencyPreview: DEBUG - No reverse bonuses found, returning original result");
    end
    
    return enhancedBonus, enhancedTooltip, originalRequired;
end

-- ===========================================================================
-- INTERFACE MODE TRACKING
-- ===========================================================================

function OnInterfaceModeChanged(oldMode, newMode)
    if (newMode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
        g_currentDistrictHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE);
        g_functionCallCount = 0; -- Reset counter for new placement session
        print("DetailedAdjacencyPreview: Entered district placement mode for district hash: " .. 
              tostring(g_currentDistrictHash));
    elseif (oldMode == InterfaceModeTypes.DISTRICT_PLACEMENT) then
        g_currentDistrictHash = nil;
        print("DetailedAdjacencyPreview: Exited district placement mode. Function was called " .. g_functionCallCount .. " times.");
    end
end

-- ===========================================================================
-- INITIALIZATION AND HOOKING
-- ===========================================================================

function Initialize()
    print("DetailedAdjacencyPreview: Initializing native integration...");
    
    -- Store reference to original function
    g_originalGetAdjacentYieldBonusString = GetAdjacentYieldBonusString;
    
    -- Replace the native function with our enhanced version
    GetAdjacentYieldBonusString = GetAdjacentYieldBonusString_Enhanced;
    
    print("DetailedAdjacencyPreview: Successfully hooked GetAdjacentYieldBonusString");
    
    -- Set up interface mode tracking
    Events.InterfaceModeChanged.Add(OnInterfaceModeChanged);
    
    print("DetailedAdjacencyPreview: Initialization complete!");
end

-- ===========================================================================
-- INITIALIZATION
-- ===========================================================================

Initialize(); 