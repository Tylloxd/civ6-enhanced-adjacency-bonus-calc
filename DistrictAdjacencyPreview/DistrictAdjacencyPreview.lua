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
-- CIVILIZATION-SPECIFIC DISTRICT SUPPORT (Task 2.5)
-- =============================================================================

-- Enhanced civilization-specific district replacements with additional metadata
local CIVILIZATION_DISTRICTS = {
    ["CIVILIZATION_GERMANY"] = {
        ["DISTRICT_HANSA"] = {
            replaces = "DISTRICT_INDUSTRIAL_ZONE",
            bonusRules = {
                -- Hansa gets additional +1 Production from adjacent Commercial Hubs
                ["DISTRICT_COMMERCIAL_HUB"] = 1,
                -- Hansa gets +2 Production from adjacent Resources
                -- (handled separately as this involves terrain, not districts)
            }
        }
    },
    ["CIVILIZATION_ENGLAND"] = {
        ["DISTRICT_ROYAL_NAVY_DOCKYARD"] = {
            replaces = "DISTRICT_HARBOR",
            bonusRules = {
                -- Royal Navy Dockyard gets standard Harbor bonuses
                -- Plus movement bonuses (not adjacency related)
            }
        }
    },
    ["CIVILIZATION_MALI"] = {
        ["DISTRICT_SUGUBA"] = {
            replaces = "DISTRICT_COMMERCIAL_HUB",
            bonusRules = {
                -- Suguba gets additional Gold from adjacent Holy Sites and Rivers
                ["DISTRICT_HOLY_SITE"] = 1,
                -- River bonus handled separately
            }
        }
    },
    ["CIVILIZATION_RUSSIA"] = {
        ["DISTRICT_LAVRA"] = {
            replaces = "DISTRICT_HOLY_SITE",
            bonusRules = {
                -- Lavra gets Faith from adjacent districts (same as Holy Site)
                -- Plus territory expansion bonuses (not adjacency related)
            }
        }
    },
    ["CIVILIZATION_KONGO"] = {
        ["DISTRICT_MBANZA"] = {
            replaces = "DISTRICT_NEIGHBORHOOD",
            bonusRules = {
                -- Mbanza provides Housing and Food
                -- Different mechanics than standard adjacency
            }
        }
    }
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
-- ADJACENCY RULES LOOKUP SYSTEM (Task 2.3)
-- =============================================================================

-- Enhanced lookup function for district adjacency bonuses
function GetDistrictAdjacencyBonus(newDistrictType, existingDistrictType)
    if newDistrictType == nil or existingDistrictType == nil then
        return 0
    end
    
    local baseNewType = GetBaseDistrictType(newDistrictType)
    local baseExistingType = GetBaseDistrictType(existingDistrictType)
    
    -- Check the adjacency rules table
    if DISTRICT_ADJACENCY_RULES[baseNewType] and DISTRICT_ADJACENCY_RULES[baseNewType][baseExistingType] then
        return DISTRICT_ADJACENCY_RULES[baseNewType][baseExistingType]
    end
    
    return 0
end

-- Get all adjacency bonuses that a new district would provide
function GetAllAdjacencyBonuses(newDistrictType, adjacentDistrictTypes)
    local bonuses = {}
    
    for _, existingType in ipairs(adjacentDistrictTypes) do
        local bonus = GetDistrictAdjacencyBonus(newDistrictType, existingType)
        if bonus > 0 then
            table.insert(bonuses, {
                targetDistrict = existingType,
                bonus = bonus
            })
        end
    end
    
    return bonuses
end

-- Check if a new district type provides any adjacency bonuses
function DoesDistrictProvideAdjacency(districtType)
    local baseType = GetBaseDistrictType(districtType)
    return DISTRICT_ADJACENCY_RULES[baseType] ~= nil
end

-- Get all district types that a given district can provide bonuses to
function GetDistrictTargets(districtType)
    local baseType = GetBaseDistrictType(districtType)
    local targets = {}
    
    if DISTRICT_ADJACENCY_RULES[baseType] then
        for targetType, bonus in pairs(DISTRICT_ADJACENCY_RULES[baseType]) do
            table.insert(targets, {
                districtType = targetType,
                bonus = bonus
            })
        end
    end
    
    return targets
end

-- Get all district types that can provide bonuses to a given district
function GetDistrictSources(targetDistrictType)
    local baseTargetType = GetBaseDistrictType(targetDistrictType)
    local sources = {}
    
    for sourceType, rules in pairs(DISTRICT_ADJACENCY_RULES) do
        if rules[baseTargetType] then
            table.insert(sources, {
                districtType = sourceType,
                bonus = rules[baseTargetType]
            })
        end
    end
    
    return sources
end

-- Validate adjacency rules consistency (for debugging)
function ValidateAdjacencyRules()
    print("Validating adjacency rules...")
    local ruleCount = 0
    
    for sourceType, rules in pairs(DISTRICT_ADJACENCY_RULES) do
        for targetType, bonus in pairs(rules) do
            ruleCount = ruleCount + 1
            if bonus <= 0 then
                print("WARNING: Non-positive bonus found:", sourceType, "->", targetType, "=", bonus)
            end
        end
    end
    
    print("Validated", ruleCount, "adjacency rules")
    return ruleCount
end

-- Get readable district name for display
function GetDistrictDisplayName(districtType)
    local baseType = GetBaseDistrictType(districtType)
    
    -- Map district types to display names
    local displayNames = {
        ["DISTRICT_CAMPUS"] = "Campus",
        ["DISTRICT_THEATER"] = "Theater Square",
        ["DISTRICT_COMMERCIAL_HUB"] = "Commercial Hub",
        ["DISTRICT_HARBOR"] = "Harbor",
        ["DISTRICT_INDUSTRIAL_ZONE"] = "Industrial Zone",
        ["DISTRICT_HOLY_SITE"] = "Holy Site",
        ["DISTRICT_GOVERNMENT"] = "Government Plaza",
        ["DISTRICT_ENTERTAINMENT_COMPLEX"] = "Entertainment Complex",
        ["DISTRICT_WATER_ENTERTAINMENT_COMPLEX"] = "Water Park",
        ["DISTRICT_AQUEDUCT"] = "Aqueduct",
        ["DISTRICT_DAM"] = "Dam",
        ["DISTRICT_CANAL"] = "Canal"
    }
    
    -- Check for unique districts
    if districtType == "DISTRICT_HANSA" then
        return "Hansa"
    elseif districtType == "DISTRICT_ROYAL_NAVY_DOCKYARD" then
        return "Royal Navy Dockyard"
    elseif districtType == "DISTRICT_SUGUBA" then
        return "Suguba"
    elseif districtType == "DISTRICT_LAVRA" then
        return "Lavra"
    elseif districtType == "DISTRICT_MBANZA" then
        return "Mbanza"
    end
    
    return displayNames[baseType] or baseType
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
-- ADJACENCY BONUS CALCULATION (Task 2.4)
-- =============================================================================

-- Calculate the total adjacency bonus a new district would provide to existing districts
function CalculateDistrictAdjacencyBonuses(newDistrictType, placementX, placementY, playerID)
    local adjacencyBonuses = {}
    local totalBonus = 0
    
    -- Get all adjacent districts
    local adjacentDistricts = GetAdjacentDistricts(placementX, placementY)
    
    for _, districtData in ipairs(adjacentDistricts) do
        -- Only count completed districts
        if IsDistrictComplete(districtData.plot) then
            local bonus = GetDistrictAdjacencyBonusWithCiv(newDistrictType, districtData.districtType, playerID)
            
            if bonus > 0 then
                table.insert(adjacencyBonuses, {
                    targetDistrict = districtData.districtType,
                    targetPlot = districtData.plot,
                    x = districtData.x,
                    y = districtData.y,
                    bonus = bonus,
                    displayName = GetDistrictDisplayName(districtData.districtType)
                })
                totalBonus = totalBonus + bonus
                
                print("District", GetDistrictDisplayName(newDistrictType), "would provide +" .. bonus, "to", GetDistrictDisplayName(districtData.districtType), "at", districtData.x, districtData.y)
            end
        end
    end
    
    return adjacencyBonuses, totalBonus
end

-- Calculate adjacency for a specific plot and district type
function CalculateAdjacencyForPlacement(districtType, plotX, plotY, playerID)
    if districtType == nil or plotX == nil or plotY == nil then
        return {}, 0
    end
    
    local bonuses, total = CalculateDistrictAdjacencyBonuses(districtType, plotX, plotY, playerID)
    
    print("Placement analysis for", GetDistrictDisplayName(districtType), "at", plotX, plotY, "- Total bonus:", total)
    
    return bonuses, total
end

-- Get adjacency preview data for UI display
function GetAdjacencyPreviewData(districtType, placementX, placementY, playerID)
    local previewData = {
        districtType = districtType,
        placementX = placementX,
        placementY = placementY,
        bonuses = {},
        totalBonus = 0,
        hasAnyBonus = false
    }
    
    local bonuses, total = CalculateAdjacencyForPlacement(districtType, placementX, placementY, playerID)
    
    previewData.bonuses = bonuses
    previewData.totalBonus = total
    previewData.hasAnyBonus = total > 0
    
    -- Create simplified bonus data for each affected plot
    previewData.plotBonuses = {}
    for _, bonusData in ipairs(bonuses) do
        previewData.plotBonuses[bonusData.x .. "," .. bonusData.y] = {
            bonus = bonusData.bonus,
            districtName = bonusData.displayName
        }
    end
    
    return previewData
end

-- Validate placement and calculate all relevant bonuses
function ValidateAndCalculateAdjacency(districtType, plotX, plotY)
    -- Validate inputs
    if not districtType or not plotX or not plotY then
        print("ERROR: Invalid parameters for adjacency calculation")
        return nil
    end
    
    -- Check if plot exists
    local pPlot = Map.GetPlot(plotX, plotY)
    if not pPlot then
        print("ERROR: Invalid plot coordinates", plotX, plotY)
        return nil
    end
    
    -- Check if district type provides any adjacency
    if not DoesDistrictProvideAdjacency(districtType) then
        print("District type", districtType, "does not provide adjacency bonuses")
        return {
            districtType = districtType,
            placementX = plotX,
            placementY = plotY,
            bonuses = {},
            totalBonus = 0,
            hasAnyBonus = false,
            plotBonuses = {}
        }
    end
    
    -- Calculate and return the adjacency data
    return GetAdjacencyPreviewData(districtType, plotX, plotY)
end

-- Helper function to format bonus display text
function FormatBonusText(bonus)
    if bonus <= 0 then
        return "+0"
    end
    return "+" .. tostring(bonus)
end

-- Debug function to print all adjacency calculations
function DebugAdjacencyCalculation(districtType, plotX, plotY)
    print("=== DEBUG: Adjacency Calculation ===")
    print("District:", GetDistrictDisplayName(districtType))
    print("Placement:", plotX, plotY)
    
    local adjacentDistricts = GetAdjacentDistricts(plotX, plotY)
    print("Adjacent districts found:", #adjacentDistricts)
    
    for _, districtData in ipairs(adjacentDistricts) do
        local bonus = GetDistrictAdjacencyBonus(districtType, districtData.districtType)
        local isComplete = IsDistrictComplete(districtData.plot)
        print("  -", GetDistrictDisplayName(districtData.districtType), "at", districtData.x, districtData.y, "- Bonus:", bonus, "Complete:", isComplete)
    end
    
    local previewData = GetAdjacencyPreviewData(districtType, plotX, plotY)
    print("Total calculated bonus:", previewData.totalBonus)
    print("===================================")
    
    return previewData
end

-- =============================================================================
-- CIVILIZATION-SPECIFIC DISTRICT SUPPORT (Task 2.5)
-- =============================================================================

-- Get the current player's civilization type
function GetPlayerCivilization(playerID)
    local pPlayer = Players[playerID]
    if pPlayer == nil then
        return nil
    end
    
    local playerConfig = PlayerConfigurations[playerID]
    if playerConfig == nil then
        return nil
    end
    
    local civTypeID = playerConfig:GetCivilizationTypeID()
    if civTypeID == -1 then
        return nil
    end
    
    local civInfo = GameInfo.Civilizations[civTypeID]
    if civInfo then
        return civInfo.CivilizationType
    end
    
    return nil
end

-- Check if a district is a unique district for the current civilization
function IsUniqueDistrictForCivilization(districtType, civilizationType)
    if not civilizationType or not CIVILIZATION_DISTRICTS[civilizationType] then
        return false
    end
    
    return CIVILIZATION_DISTRICTS[civilizationType][districtType] ~= nil
end

-- Get civilization-specific adjacency bonus (if different from standard)
function GetCivilizationSpecificBonus(civType, newDistrictType, existingDistrictType)
    if not civType or not CIVILIZATION_DISTRICTS[civType] then
        return 0
    end
    
    local districtData = CIVILIZATION_DISTRICTS[civType][newDistrictType]
    if not districtData or not districtData.bonusRules then
        return 0
    end
    
    local baseExistingType = GetBaseDistrictType(existingDistrictType)
    return districtData.bonusRules[baseExistingType] or 0
end

-- Enhanced district adjacency bonus calculation with civilization support
function GetDistrictAdjacencyBonusWithCiv(newDistrictType, existingDistrictType, playerID)
    if newDistrictType == nil or existingDistrictType == nil then
        return 0
    end
    
    -- Get standard bonus first
    local standardBonus = GetDistrictAdjacencyBonus(newDistrictType, existingDistrictType)
    
    -- Check for civilization-specific bonuses
    local civType = GetPlayerCivilization(playerID or Game.GetLocalPlayer())
    if civType then
        local civBonus = GetCivilizationSpecificBonus(civType, newDistrictType, existingDistrictType)
        if civBonus > 0 then
            print("Civilization-specific bonus:", civBonus, "for", newDistrictType, "->", existingDistrictType)
            return civBonus -- Use civ-specific bonus instead of standard
        end
    end
    
    return standardBonus
end

-- Get all unique districts available to a civilization
function GetCivilizationUniqueDistricts(civilizationType)
    if not civilizationType or not CIVILIZATION_DISTRICTS[civilizationType] then
        return {}
    end
    
    local uniqueDistricts = {}
    for districtType, data in pairs(CIVILIZATION_DISTRICTS[civilizationType]) do
        table.insert(uniqueDistricts, {
            districtType = districtType,
            replaces = data.replaces,
            displayName = GetDistrictDisplayName(districtType)
        })
    end
    
    return uniqueDistricts
end

-- Check if a district type should be treated as its base type for adjacency calculations
function ShouldUseBaseTypeForAdjacency(districtType, civilizationType)
    -- Most unique districts use their base type's adjacency rules
    -- Only return false if the unique district has completely different rules
    
    if not civilizationType or not CIVILIZATION_DISTRICTS[civilizationType] then
        return true
    end
    
    local districtData = CIVILIZATION_DISTRICTS[civilizationType][districtType]
    if not districtData then
        return true
    end
    
    -- If the unique district has custom bonus rules, use those
    return not districtData.bonusRules or table.isEmpty(districtData.bonusRules)
end

-- Validate unique district configuration (for debugging)
function ValidateUniqueDistricts()
    print("Validating unique district configurations...")
    
    for civType, districts in pairs(CIVILIZATION_DISTRICTS) do
        print("Civilization:", civType)
        for districtType, data in pairs(districts) do
            print("  Unique District:", districtType, "replaces", data.replaces)
            if data.bonusRules then
                for target, bonus in pairs(data.bonusRules) do
                    print("    Custom bonus:", target, "=", bonus)
                end
            end
        end
    end
end

-- Helper function to check if table is empty
function table.isEmpty(t)
    return next(t) == nil
end

-- =============================================================================
-- ADJACENCY BONUS COMBINATION SYSTEM (Task 2.6)
-- =============================================================================

-- Combine multiple adjacency bonuses into a single total for a placement
function CombineAdjacencyBonuses(bonusList)
    local totalBonus = 0
    local bonusBreakdown = {}
    
    for _, bonusData in ipairs(bonusList) do
        totalBonus = totalBonus + bonusData.bonus
        table.insert(bonusBreakdown, {
            source = bonusData.displayName,
            bonus = bonusData.bonus,
            coordinates = bonusData.x .. "," .. bonusData.y
        })
    end
    
    return totalBonus, bonusBreakdown
end

-- Get combined bonus value for display on a specific plot
function GetCombinedBonusForPlot(districtType, plotX, plotY, playerID)
    local previewData = GetAdjacencyPreviewData(districtType, plotX, plotY, playerID)
    
    if not previewData.hasAnyBonus then
        return 0, {}
    end
    
    return CombineAdjacencyBonuses(previewData.bonuses)
end

-- Create a summary of all adjacency bonuses for a placement
function CreateAdjacencySummary(districtType, plotX, plotY, playerID)
    local summary = {
        placementLocation = {x = plotX, y = plotY},
        districtType = districtType,
        districtDisplayName = GetDistrictDisplayName(districtType),
        totalBonus = 0,
        bonusCount = 0,
        affectedDistricts = {},
        isEmpty = true
    }
    
    local previewData = GetAdjacencyPreviewData(districtType, plotX, plotY, playerID)
    
    if previewData.hasAnyBonus then
        summary.totalBonus = previewData.totalBonus
        summary.bonusCount = #previewData.bonuses
        summary.affectedDistricts = previewData.bonuses
        summary.isEmpty = false
        
        -- Create formatted text for display
        summary.displayText = FormatBonusText(summary.totalBonus)
        summary.tooltipText = string.format(
            "%s would provide %s total adjacency bonus to %d adjacent district%s",
            summary.districtDisplayName,
            FormatBonusText(summary.totalBonus),
            summary.bonusCount,
            summary.bonusCount == 1 and "" or "s"
        )
    else
        summary.displayText = FormatBonusText(0)
        summary.tooltipText = string.format(
            "%s would not provide any adjacency bonuses at this location",
            summary.districtDisplayName
        )
    end
    
    return summary
end

-- Combine bonuses by district type (for cases where multiple of same district are adjacent)
function CombineBonusesByDistrictType(bonusList)
    local combinedBonuses = {}
    local totalBonus = 0
    
    for _, bonusData in ipairs(bonusList) do
        local districtType = bonusData.targetDistrict
        
        if combinedBonuses[districtType] then
            combinedBonuses[districtType].totalBonus = combinedBonuses[districtType].totalBonus + bonusData.bonus
            combinedBonuses[districtType].count = combinedBonuses[districtType].count + 1
        else
            combinedBonuses[districtType] = {
                districtType = districtType,
                displayName = bonusData.displayName,
                totalBonus = bonusData.bonus,
                count = 1
            }
        end
        
        totalBonus = totalBonus + bonusData.bonus
    end
    
    -- Convert to array format
    local result = {}
    for _, data in pairs(combinedBonuses) do
        table.insert(result, data)
    end
    
    return result, totalBonus
end

-- Get the maximum possible adjacency bonus for a district type at any location
function GetMaximumPossibleAdjacency(districtType)
    local maxBonus = 0
    local targets = GetDistrictTargets(districtType)
    
    for _, target in ipairs(targets) do
        maxBonus = maxBonus + target.bonus
    end
    
    -- Theoretical maximum if all 6 adjacent plots had the highest-bonus districts
    local highestSingleBonus = 0
    for _, target in ipairs(targets) do
        if target.bonus > highestSingleBonus then
            highestSingleBonus = target.bonus
        end
    end
    
    return {
        practicalMaximum = maxBonus, -- If one of each target type is adjacent
        theoreticalMaximum = highestSingleBonus * 6 -- If all 6 adjacent plots have the highest bonus
    }
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Initialize the mod when loaded
Initialize() 