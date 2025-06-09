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
        -- Government Plaza provides +1.5 to all districts (we'll handle this specially)
        ["GENERIC_DISTRICT"] = { ["YIELD_GENERIC"] = 1.5 }
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
        return {};
    end
    
    local benefitsMap = {};
    local cityPlots = Map.GetCityPlots():GetPurchasedPlots(pCity);
    
    -- Iterate through all plots in the city
    for i, plotID in ipairs(cityPlots) do
        local pPlot = Map.GetPlotByIndex(plotID);
        if pPlot then
            local pDistrict = pPlot:GetDistrict();
            if pDistrict and not pDistrict:IsComplete() == false then
                local existingDistrictType = pDistrict:GetType();
                local districtX, districtY = pPlot:GetX(), pPlot:GetY();
                
                -- Check if this existing district is adjacent to the proposed new district location
                if IsAdjacentPlot(districtX, districtY, targetPlotX, targetPlotY) then
                    local benefits = GetBenefitsFromNewDistrict(existingDistrictType, newDistrictType);
                    if benefits and next(benefits) then
                        benefitsMap[plotID] = {
                            DistrictType = existingDistrictType,
                            Benefits = benefits,
                            PlotX = districtX,
                            PlotY = districtY
                        };
                    end
                end
            end
        end
    end
    
    return benefitsMap;
end

-- Get benefits that an existing district would receive from a new district
function GetBenefitsFromNewDistrict(existingDistrictType, newDistrictType)
    local benefits = {};
    
    -- Check if the new district type provides specific benefits to the existing district
    if g_DistrictAdjacencyProviders[newDistrictType] then
        local providerBenefits = g_DistrictAdjacencyProviders[newDistrictType][existingDistrictType];
        if providerBenefits then
            for yieldType, amount in pairs(providerBenefits) do
                benefits[yieldType] = (benefits[yieldType] or 0) + amount;
            end
        end
    end
    
    -- Check generic district adjacency bonuses
    if g_DistrictAdjacencyProviders["GENERIC_DISTRICT_ADJACENCY"][existingDistrictType] then
        local genericBenefits = g_DistrictAdjacencyProviders["GENERIC_DISTRICT_ADJACENCY"][existingDistrictType];
        for yieldType, amount in pairs(genericBenefits) do
            benefits[yieldType] = (benefits[yieldType] or 0) + amount;
        end
    end
    
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