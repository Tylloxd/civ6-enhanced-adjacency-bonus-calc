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