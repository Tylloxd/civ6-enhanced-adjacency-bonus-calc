-- =============================================================================
-- District Adjacency Preview Mod
-- Author: District Adjacency Preview Team
-- Description: Shows adjacency bonuses that a new district would provide 
--              to existing adjacent districts during placement preview
-- =============================================================================

print("Loading District Adjacency Preview Mod...")

-- =============================================================================
-- INCLUDES AND CONSTANTS
-- =============================================================================

include("PlotIterators")
include("SupportFunctions")

-- =============================================================================
-- GLOBAL VARIABLES
-- =============================================================================

local g_DistrictAdjacencyPreview = {}
local g_isPreviewActive = false
local g_currentDistrictType = nil
local g_currentPlotX = -1
local g_currentPlotY = -1

-- =============================================================================
-- DISTRICT ADJACENCY RULES
-- =============================================================================

-- Define adjacency bonuses between districts
-- Format: [DistrictType] = { [AdjacentDistrictType] = bonus_value }
local DISTRICT_ADJACENCY_RULES = {
    ["DISTRICT_CAMPUS"] = {
        ["DISTRICT_THEATER"] = 1,          -- +1 Science from Theater Square
        ["DISTRICT_GOVERNMENT"] = 1,       -- +1 Science from Government Plaza
    },
    ["DISTRICT_THEATER"] = {
        ["DISTRICT_CAMPUS"] = 1,           -- +1 Culture from Campus
        ["DISTRICT_GOVERNMENT"] = 1,       -- +1 Culture from Government Plaza
        ["DISTRICT_ENTERTAINMENT_COMPLEX"] = 1, -- +1 Culture from Entertainment Complex
        ["DISTRICT_WATER_ENTERTAINMENT_COMPLEX"] = 1, -- +1 Culture from Water Park
    },
    ["DISTRICT_COMMERCIAL_HUB"] = {
        ["DISTRICT_HARBOR"] = 2,           -- +2 Gold from Harbor
        ["DISTRICT_GOVERNMENT"] = 1,       -- +1 Gold from Government Plaza
    },
    ["DISTRICT_HARBOR"] = {
        ["DISTRICT_COMMERCIAL_HUB"] = 2,   -- +2 Gold from Commercial Hub
        ["DISTRICT_GOVERNMENT"] = 1,       -- +1 Gold from Government Plaza
    },
    ["DISTRICT_INDUSTRIAL_ZONE"] = {
        ["DISTRICT_GOVERNMENT"] = 1,       -- +1 Production from Government Plaza
        ["DISTRICT_AQUEDUCT"] = 2,         -- +2 Production from Aqueduct
        ["DISTRICT_DAM"] = 2,              -- +2 Production from Dam
        ["DISTRICT_CANAL"] = 2,            -- +2 Production from Canal
    },
    ["DISTRICT_GOVERNMENT"] = {
        ["DISTRICT_CAMPUS"] = 1,           -- +1 from Campus
        ["DISTRICT_THEATER"] = 1,          -- +1 from Theater Square
        ["DISTRICT_COMMERCIAL_HUB"] = 1,   -- +1 from Commercial Hub
        ["DISTRICT_HARBOR"] = 1,           -- +1 from Harbor
        ["DISTRICT_INDUSTRIAL_ZONE"] = 1,  -- +1 from Industrial Zone
        ["DISTRICT_HOLY_SITE"] = 1,        -- +1 from Holy Site
    },
    ["DISTRICT_HOLY_SITE"] = {
        ["DISTRICT_GOVERNMENT"] = 1,       -- +1 Faith from Government Plaza
    },
    ["DISTRICT_ENTERTAINMENT_COMPLEX"] = {
        ["DISTRICT_THEATER"] = 1,          -- +1 Amenities bonus to Theater
    },
    ["DISTRICT_WATER_ENTERTAINMENT_COMPLEX"] = {
        ["DISTRICT_THEATER"] = 1,          -- +1 Amenities bonus to Theater
    },
    ["DISTRICT_AQUEDUCT"] = {
        ["DISTRICT_INDUSTRIAL_ZONE"] = 2,  -- +2 Production bonus to Industrial Zone
    },
    ["DISTRICT_DAM"] = {
        ["DISTRICT_INDUSTRIAL_ZONE"] = 2,  -- +2 Production bonus to Industrial Zone
    },
    ["DISTRICT_CANAL"] = {
        ["DISTRICT_INDUSTRIAL_ZONE"] = 2,  -- +2 Production bonus to Industrial Zone
        ["DISTRICT_COMMERCIAL_HUB"] = 1,   -- +1 Gold from Commercial Hub
        ["DISTRICT_HARBOR"] = 1,           -- +1 Gold from Harbor
    },
}

-- Civilization-specific district replacements
local UNIQUE_DISTRICT_REPLACEMENTS = {
    ["DISTRICT_HANSA"] = "DISTRICT_INDUSTRIAL_ZONE",  -- Germany
    ["DISTRICT_ROYAL_NAVY_DOCKYARD"] = "DISTRICT_HARBOR", -- England
    ["DISTRICT_SUGUBA"] = "DISTRICT_COMMERCIAL_HUB",  -- Mali
    ["DISTRICT_LAVRA"] = "DISTRICT_HOLY_SITE",        -- Russia
    ["DISTRICT_MBANZA"] = "DISTRICT_NEIGHBORHOOD",    -- Kongo
}

-- =============================================================================
-- CORE FUNCTIONS
-- =============================================================================

-- Initialize the mod
function Initialize()
    print("Initializing District Adjacency Preview...")
    
    -- Register event handlers
    Events.DistrictPicker_FilterShown.Add(OnDistrictPickerShown)
    Events.DistrictPicker_FilterHidden.Add(OnDistrictPickerHidden)
    Events.CityBannerManager_Updated.Add(OnCityBannerUpdate)
    
    print("District Adjacency Preview initialized successfully!")
end

-- Get the base district type for unique districts
function GetBaseDistrictType(districtType)
    if UNIQUE_DISTRICT_REPLACEMENTS[districtType] then
        return UNIQUE_DISTRICT_REPLACEMENTS[districtType]
    end
    return districtType
end

-- Calculate adjacency bonus from a new district to an existing district
function CalculateAdjacencyBonus(newDistrictType, existingDistrictType)
    local baseNewType = GetBaseDistrictType(newDistrictType)
    local baseExistingType = GetBaseDistrictType(existingDistrictType)
    
    if DISTRICT_ADJACENCY_RULES[baseNewType] and DISTRICT_ADJACENCY_RULES[baseNewType][baseExistingType] then
        return DISTRICT_ADJACENCY_RULES[baseNewType][baseExistingType]
    end
    
    return 0
end

-- =============================================================================
-- PLOT ADJACENCY FUNCTIONS (Task 2.1)
-- =============================================================================

-- Get all adjacent plots to a given plot coordinate
function GetAdjacentPlots(plotX, plotY)
    local adjacentPlots = {}
    local pPlot = Map.GetPlot(plotX, plotY)
    
    if pPlot == nil then
        print("ERROR: Invalid plot coordinates:", plotX, plotY)
        return adjacentPlots
    end
    
    -- Get all plots within range 1 (adjacent plots only)
    local plotIterator = Map.GetAdjacentPlots(plotX, plotY)
    
    for adjPlot in plotIterator do
        if adjPlot ~= nil then
            table.insert(adjacentPlots, {
                plot = adjPlot,
                x = adjPlot:GetX(),
                y = adjPlot:GetY()
            })
        end
    end
    
    print("Found", #adjacentPlots, "adjacent plots to", plotX, plotY)
    return adjacentPlots
end

-- Alternative method using direction-based adjacency for validation
function GetAdjacentPlotsDirectional(plotX, plotY)
    local adjacentPlots = {}
    local mapWidth = Map.GetGridWidth()
    local mapHeight = Map.GetGridHeight()
    
    -- Define the 6 hexagonal directions (Civ VI uses hex grid)
    local directions = {
        {0, 1},   -- North
        {1, 0},   -- Northeast  
        {1, -1},  -- Southeast
        {0, -1},  -- South
        {-1, 0},  -- Southwest
        {-1, 1}   -- Northwest
    }
    
    for _, direction in ipairs(directions) do
        local adjX = plotX + direction[1]
        local adjY = plotY + direction[2]
        
        -- Handle map wrapping and bounds checking
        if adjX >= 0 and adjX < mapWidth and adjY >= 0 and adjY < mapHeight then
            local adjPlot = Map.GetPlot(adjX, adjY)
            if adjPlot ~= nil then
                table.insert(adjacentPlots, {
                    plot = adjPlot,
                    x = adjX,
                    y = adjY
                })
            end
        end
    end
    
    return adjacentPlots
end

-- Validate that a plot is actually adjacent to the placement location
function IsPlotAdjacent(placementX, placementY, testX, testY)
    -- Simple distance check - adjacent plots are exactly 1 tile away
    local distance = Map.GetPlotDistance(placementX, placementY, testX, testY)
    return distance == 1
end

-- =============================================================================
-- DISTRICT DETECTION FUNCTIONS (Task 2.2)
-- =============================================================================

-- Get the district type on a specific plot (if any)
function GetDistrictOnPlot(pPlot)
    if pPlot == nil then
        return nil
    end
    
    -- Check if plot has a district
    local districtID = pPlot:GetDistrictID()
    if districtID == -1 then
        return nil -- No district on this plot
    end
    
    -- Get the district object
    local pDistrict = CityManager.GetDistrict(districtID)
    if pDistrict == nil then
        return nil
    end
    
    -- Get district type
    local districtType = pDistrict:GetType()
    if districtType == -1 then
        return nil
    end
    
    -- Convert district type ID to string
    local districtInfo = GameInfo.Districts[districtType]
    if districtInfo then
        return districtInfo.DistrictType
    end
    
    return nil
end

-- Get all districts on adjacent plots to a placement location
function GetAdjacentDistricts(plotX, plotY)
    local adjacentDistricts = {}
    local adjacentPlots = GetAdjacentPlots(plotX, plotY)
    
    for _, plotData in ipairs(adjacentPlots) do
        local districtType = GetDistrictOnPlot(plotData.plot)
        if districtType ~= nil then
            table.insert(adjacentDistricts, {
                districtType = districtType,
                plot = plotData.plot,
                x = plotData.x,
                y = plotData.y
            })
            print("Found district", districtType, "at", plotData.x, plotData.y)
        end
    end
    
    print("Found", #adjacentDistricts, "adjacent districts to", plotX, plotY)
    return adjacentDistricts
end

-- Check if a specific district type exists adjacent to a plot
function HasAdjacentDistrict(plotX, plotY, targetDistrictType)
    local adjacentDistricts = GetAdjacentDistricts(plotX, plotY)
    
    for _, districtData in ipairs(adjacentDistricts) do
        local baseType = GetBaseDistrictType(districtData.districtType)
        local targetBaseType = GetBaseDistrictType(targetDistrictType)
        
        if baseType == targetBaseType then
            return true
        end
    end
    
    return false
end

-- Get all unique district types adjacent to a plot
function GetAdjacentDistrictTypes(plotX, plotY)
    local adjacentDistricts = GetAdjacentDistricts(plotX, plotY)
    local uniqueTypes = {}
    local typesSeen = {}
    
    for _, districtData in ipairs(adjacentDistricts) do
        local baseType = GetBaseDistrictType(districtData.districtType)
        if not typesSeen[baseType] then
            typesSeen[baseType] = true
            table.insert(uniqueTypes, baseType)
        end
    end
    
    return uniqueTypes
end

-- Validate that a district is properly constructed (not just planned)
function IsDistrictComplete(pPlot)
    if pPlot == nil then
        return false
    end
    
    local districtID = pPlot:GetDistrictID()
    if districtID == -1 then
        return false
    end
    
    local pDistrict = CityManager.GetDistrict(districtID)
    if pDistrict == nil then
        return false
    end
    
    -- Check if district is complete (not under construction)
    return pDistrict:IsComplete()
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

-- Called when district picker is shown
function OnDistrictPickerShown()
    print("District picker shown - activating preview")
    g_isPreviewActive = true
end

-- Called when district picker is hidden
function OnDistrictPickerHidden()
    print("District picker hidden - deactivating preview")
    g_isPreviewActive = false
    g_currentDistrictType = nil
    g_currentPlotX = -1
    g_currentPlotY = -1
end

-- Called when city banner is updated (placeholder for now)
function OnCityBannerUpdate()
    if not g_isPreviewActive then
        return
    end
    -- This will be expanded in later tasks
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Initialize the mod when loaded
Initialize() 