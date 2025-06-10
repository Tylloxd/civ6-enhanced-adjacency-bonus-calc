-- DetailedAdjacencyPreview_Core.lua
-- Core adjacency calculation system for the Detailed Adjacency Preview mod

print("Loading Detailed Adjacency Preview Core System");

-- =========================================================================
-- ADJACENCY BENEFIT DATA STRUCTURES
-- =========================================================================

-- Maps district types to the benefits they PROVIDE to adjacent districts
-- Structure: [DistrictType] = { [TargetDistrictType] = { YieldType = Amount } }
local g_DistrictAdjacencyProviders = {
    -- Aqueduct provides benefits to other districts
    ["DISTRICT_AQUEDUCT"] = {
        ["DISTRICT_INDUSTRIAL_ZONE"] = { ["YIELD_PRODUCTION"] = 2 },
        ["DISTRICT_HOLY_SITE"] = { ["YIELD_FAITH"] = 1 }
    },
    
    -- Dam provides benefits to other districts
    ["DISTRICT_DAM"] = {
        ["DISTRICT_INDUSTRIAL_ZONE"] = { ["YIELD_PRODUCTION"] = 1 }
    },
    
    -- Harbor provides benefits to other districts
    ["DISTRICT_HARBOR"] = {
        ["DISTRICT_COMMERCIAL_HUB"] = { ["YIELD_GOLD"] = 1 }
    },
    
    -- Government Plaza provides benefits to other districts
    ["DISTRICT_GOVERNMENT"] = {
        ["DISTRICT_INDUSTRIAL_ZONE"] = { ["YIELD_PRODUCTION"] = 2 },
        ["DISTRICT_CAMPUS"] = { ["YIELD_SCIENCE"] = 2 },
        ["DISTRICT_COMMERCIAL_HUB"] = { ["YIELD_GOLD"] = 2 },
        ["DISTRICT_HOLY_SITE"] = { ["YIELD_FAITH"] = 2 },
        ["DISTRICT_THEATER"] = { ["YIELD_CULTURE"] = 2 },
        ["DISTRICT_ENTERTAINMENT_COMPLEX"] = { ["YIELD_AMENITY"] = 2 },
        ["DISTRICT_WATER_ENTERTAINMENT_COMPLEX"] = { ["YIELD_AMENITY"] = 2 }
    },
    
    -- Generic district adjacency (most districts provide +0.5 to each other)
    ["GENERIC_DISTRICT_ADJACENCY"] = {
        ["DISTRICT_CAMPUS"] = { ["YIELD_SCIENCE"] = 0.5 },
        ["DISTRICT_COMMERCIAL_HUB"] = { ["YIELD_GOLD"] = 0.5 },
        ["DISTRICT_INDUSTRIAL_ZONE"] = { ["YIELD_PRODUCTION"] = 0.5 },
        ["DISTRICT_HOLY_SITE"] = { ["YIELD_FAITH"] = 0.5 },
        ["DISTRICT_THEATER"] = { ["YIELD_CULTURE"] = 0.5 },
        ["DISTRICT_ENTERTAINMENT_COMPLEX"] = { ["YIELD_AMENITY"] = 0.5 },
        ["DISTRICT_WATER_ENTERTAINMENT_COMPLEX"] = { ["YIELD_AMENITY"] = 0.5 }
    }
};

-- Maps district types to the benefits they RECEIVE from adjacent districts/features
-- This helps us understand what existing districts might benefit from new placements
local g_DistrictAdjacencyReceivers = {
    ["DISTRICT_CAMPUS"] = {
        -- Campus receives from terrain features
        ["FEATURE_MOUNTAINS"] = { ["YIELD_SCIENCE"] = 1 },
        ["FEATURE_JUNGLE"] = { ["YIELD_SCIENCE"] = 1 },
        ["FEATURE_REEF"] = { ["YIELD_SCIENCE"] = 1 },
        -- Campus receives from districts
        ["GENERIC_DISTRICT"] = { ["YIELD_SCIENCE"] = 0.5 }
    },
    
    ["DISTRICT_COMMERCIAL_HUB"] = {
        -- Commercial Hub receives from features
        ["FEATURE_RIVER"] = { ["YIELD_GOLD"] = 2 },
        ["DISTRICT_HARBOR"] = { ["YIELD_GOLD"] = 1 },
        -- Commercial Hub receives from districts
        ["GENERIC_DISTRICT"] = { ["YIELD_GOLD"] = 0.5 }
    },
    
    ["DISTRICT_INDUSTRIAL_ZONE"] = {
        -- Industrial Zone receives from improvements and districts
        ["IMPROVEMENT_MINE"] = { ["YIELD_PRODUCTION"] = 1 },
        ["IMPROVEMENT_QUARRY"] = { ["YIELD_PRODUCTION"] = 1 },
        ["DISTRICT_AQUEDUCT"] = { ["YIELD_PRODUCTION"] = 2 },
        ["DISTRICT_DAM"] = { ["YIELD_PRODUCTION"] = 1 },
        ["DISTRICT_CANAL"] = { ["YIELD_PRODUCTION"] = 1 },
        -- Industrial Zone receives from districts
        ["GENERIC_DISTRICT"] = { ["YIELD_PRODUCTION"] = 0.5 }
    },
    
    ["DISTRICT_HOLY_SITE"] = {
        -- Holy Site receives from natural features
        ["FEATURE_NATURAL_WONDER"] = { ["YIELD_FAITH"] = 1 },
        ["FEATURE_MOUNTAINS"] = { ["YIELD_FAITH"] = 1 },
        ["FEATURE_FOREST"] = { ["YIELD_FAITH"] = 1 },
        ["DISTRICT_AQUEDUCT"] = { ["YIELD_FAITH"] = 1 },
        -- Holy Site receives from districts
        ["GENERIC_DISTRICT"] = { ["YIELD_FAITH"] = 0.5 }
    },
    
    ["DISTRICT_THEATER"] = {
        -- Theater Square receives from wonders and districts
        ["BUILDING_WONDER"] = { ["YIELD_CULTURE"] = 1 },
        ["GENERIC_DISTRICT"] = { ["YIELD_CULTURE"] = 0.5 }
    },
    
    ["DISTRICT_ENTERTAINMENT_COMPLEX"] = {
        ["GENERIC_DISTRICT"] = { ["YIELD_AMENITY"] = 0.5 }
    },
    
    ["DISTRICT_WATER_ENTERTAINMENT_COMPLEX"] = {
        ["GENERIC_DISTRICT"] = { ["YIELD_AMENITY"] = 0.5 }
    }
};

-- Yield type to display icon mapping
local g_YieldDisplayInfo = {
    ["YIELD_SCIENCE"] = { Icon = "[ICON_Science]", Color = "[COLOR:ScienceIcon]" },
    ["YIELD_GOLD"] = { Icon = "[ICON_Gold]", Color = "[COLOR:GoldIcon]" },
    ["YIELD_PRODUCTION"] = { Icon = "[ICON_Production]", Color = "[COLOR:ProductionIcon]" },
    ["YIELD_FAITH"] = { Icon = "[ICON_Faith]", Color = "[COLOR:FaithIcon]" },
    ["YIELD_CULTURE"] = { Icon = "[ICON_Culture]", Color = "[COLOR:CultureIcon]" },
    ["YIELD_AMENITY"] = { Icon = "[ICON_Amenities]", Color = "[COLOR:White]" }
};

-- =========================================================================
-- CORE CALCULATION FUNCTIONS
-- =========================================================================

-- Calculate what benefits existing districts would receive from placing a new district
function CalculateExistingDistrictBenefits(pCity, newDistrictType, targetPlotX, targetPlotY)
    if not pCity or not newDistrictType then
        print("ERROR: Missing city or district type");
        return {};
    end
    
    print(string.format("Calculating benefits for %s at (%d,%d) in city %s", 
        newDistrictType, targetPlotX, targetPlotY, pCity:GetName()));
    
    local benefitsMap = {};
    local cityPlots = Map.GetCityPlots():GetPurchasedPlots(pCity);
    
    print(string.format("Found %d plots in city", #cityPlots));
    
    -- Iterate through all plots in the city
    for i, plotID in ipairs(cityPlots) do
        local pPlot = Map.GetPlotByIndex(plotID);
        if pPlot then
            local pDistrict = pPlot:GetDistrict();
            if pDistrict and pDistrict:IsComplete() then
                local existingDistrictType = GameInfo.Districts[pDistrict:GetType()].DistrictType;
                local districtX, districtY = pPlot:GetX(), pPlot:GetY();
                
                print(string.format("Found district %s at (%d,%d)", existingDistrictType, districtX, districtY));
                
                -- Check if this existing district is adjacent to the proposed new district location
                if IsAdjacentPlot(districtX, districtY, targetPlotX, targetPlotY) then
                    print(string.format("District %s is adjacent to target location", existingDistrictType));
                    
                    local benefits = GetBenefitsFromNewDistrict(existingDistrictType, newDistrictType);
                    if benefits and next(benefits) then
                        print("Found benefits!");
                        benefitsMap[plotID] = {
                            DistrictType = existingDistrictType,
                            Benefits = benefits,
                            PlotX = districtX,
                            PlotY = districtY
                        };
                    else
                        print("No benefits calculated");
                    end
                else
                    print(string.format("District %s is NOT adjacent", existingDistrictType));
                end
            end
        end
    end
    
    print(string.format("Total benefits found: %d", GetTableSize(benefitsMap)));
    return benefitsMap;
end

-- Helper function to count table entries
function GetTableSize(t)
    local count = 0;
    for _ in pairs(t) do
        count = count + 1;
    end
    return count;
end

-- Get benefits that an existing district would receive from a new district
function GetBenefitsFromNewDistrict(existingDistrictType, newDistrictType)
    local benefits = {};
    
    print(string.format("Calculating benefits: %s -> %s", newDistrictType, existingDistrictType));
    
    -- Check if the new district type provides specific benefits to the existing district
    if g_DistrictAdjacencyProviders[newDistrictType] then
        print(string.format("Found provider data for %s", newDistrictType));
        local providerBenefits = g_DistrictAdjacencyProviders[newDistrictType][existingDistrictType];
        if providerBenefits then
            print(string.format("Found specific benefits for %s", existingDistrictType));
            for yieldType, amount in pairs(providerBenefits) do
                benefits[yieldType] = (benefits[yieldType] or 0) + amount;
                print(string.format("  Added %s: +%s", yieldType, tostring(amount)));
            end
        else
            print(string.format("No specific benefits for %s", existingDistrictType));
        end
    else
        print(string.format("No provider data for %s", newDistrictType));
    end
    
    -- Check generic district adjacency bonuses
    if g_DistrictAdjacencyProviders["GENERIC_DISTRICT_ADJACENCY"][existingDistrictType] then
        print(string.format("Found generic benefits for %s", existingDistrictType));
        local genericBenefits = g_DistrictAdjacencyProviders["GENERIC_DISTRICT_ADJACENCY"][existingDistrictType];
        for yieldType, amount in pairs(genericBenefits) do
            benefits[yieldType] = (benefits[yieldType] or 0) + amount;
            print(string.format("  Added generic %s: +%s", yieldType, tostring(amount)));
        end
    else
        print(string.format("No generic benefits for %s", existingDistrictType));
    end
    
    local benefitCount = GetTableSize(benefits);
    print(string.format("Total benefit types calculated: %d", benefitCount));
    
    return benefits;
end

-- Check if two plots are adjacent (including diagonally)
function IsAdjacentPlot(x1, y1, x2, y2)
    local dx = math.abs(x1 - x2);
    local dy = math.abs(y1 - y2);
    return (dx <= 1 and dy <= 1) and not (dx == 0 and dy == 0);
end

-- Format benefits for display
function FormatBenefitsForDisplay(benefits)
    local displayText = "";
    local benefitCount = 0;
    
    for yieldType, amount in pairs(benefits) do
        if benefitCount > 0 then
            displayText = displayText .. " ";
        end
        
        local displayInfo = g_YieldDisplayInfo[yieldType];
        if displayInfo then
            local formattedAmount = (amount == math.floor(amount)) and string.format("%.0f", amount) or string.format("%.1f", amount);
            displayText = displayText .. displayInfo.Color .. "+" .. formattedAmount .. displayInfo.Icon .. "[ENDCOLOR]";
        end
        
        benefitCount = benefitCount + 1;
    end
    
    return displayText;
end

-- =========================================================================
-- EXPORT FUNCTIONS
-- =========================================================================

-- Make functions available to other parts of the mod
g_DetailedAdjacencyPreview = {
    CalculateExistingDistrictBenefits = CalculateExistingDistrictBenefits,
    GetBenefitsFromNewDistrict = GetBenefitsFromNewDistrict,
    FormatBenefitsForDisplay = FormatBenefitsForDisplay,
    IsAdjacentPlot = IsAdjacentPlot
};

print("Detailed Adjacency Preview Core System Loaded Successfully"); 