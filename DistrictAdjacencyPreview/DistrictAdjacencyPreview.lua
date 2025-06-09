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
-- ADJACENCY CALCULATION CACHING SYSTEM (Task 2.7)
-- =============================================================================

-- Cache for adjacency calculations to improve performance
local g_AdjacencyCache = {}
local g_CacheHits = 0
local g_CacheMisses = 0

-- Generate cache key for adjacency calculation
function GenerateAdjacencyCacheKey(districtType, plotX, plotY, playerID)
    return string.format("%s_%d_%d_%s", districtType, plotX, plotY, tostring(playerID or ""))
end

-- Clear the adjacency cache (useful when districts change)
function ClearAdjacencyCache()
    g_AdjacencyCache = {}
    g_CacheHits = 0
    g_CacheMisses = 0
    print("Adjacency cache cleared")
end

-- Get cached adjacency data or calculate and cache new data
function GetCachedAdjacencyPreviewData(districtType, placementX, placementY, playerID)
    local cacheKey = GenerateAdjacencyCacheKey(districtType, placementX, placementY, playerID)
    
    -- Check if we have cached data
    if g_AdjacencyCache[cacheKey] then
        g_CacheHits = g_CacheHits + 1
        return g_AdjacencyCache[cacheKey]
    end
    
    -- Calculate new data and cache it
    g_CacheMisses = g_CacheMisses + 1
    local previewData = GetAdjacencyPreviewData(districtType, placementX, placementY, playerID)
    
    -- Cache the result
    g_AdjacencyCache[cacheKey] = previewData
    
    return previewData
end

-- Get cached combined bonus or calculate and cache
function GetCachedCombinedBonus(districtType, plotX, plotY, playerID)
    local previewData = GetCachedAdjacencyPreviewData(districtType, plotX, plotY, playerID)
    
    if not previewData.hasAnyBonus then
        return 0, {}
    end
    
    return CombineAdjacencyBonuses(previewData.bonuses)
end

-- Invalidate cache entries for a specific plot (when districts change)
function InvalidateCacheForPlot(plotX, plotY)
    local keysToRemove = {}
    
    for cacheKey, _ in pairs(g_AdjacencyCache) do
        -- Check if cache key contains this plot's coordinates
        if string.find(cacheKey, "_" .. plotX .. "_" .. plotY .. "_") then
            table.insert(keysToRemove, cacheKey)
        end
    end
    
    -- Remove invalidated entries
    for _, key in ipairs(keysToRemove) do
        g_AdjacencyCache[key] = nil
    end
    
    if #keysToRemove > 0 then
        print("Invalidated", #keysToRemove, "cache entries for plot", plotX, plotY)
    end
end

-- Invalidate cache entries that might be affected by a district being built
function InvalidateCacheForDistrictPlacement(plotX, plotY)
    -- Invalidate cache for the placement plot and all adjacent plots
    InvalidateCacheForPlot(plotX, plotY)
    
    local adjacentPlots = GetAdjacentPlots(plotX, plotY)
    for _, plotData in ipairs(adjacentPlots) do
        InvalidateCacheForPlot(plotData.x, plotData.y)
    end
end

-- Get cache statistics (for debugging and performance monitoring)
function GetCacheStatistics()
    local totalRequests = g_CacheHits + g_CacheMisses
    local hitRate = totalRequests > 0 and (g_CacheHits / totalRequests * 100) or 0
    
    return {
        hits = g_CacheHits,
        misses = g_CacheMisses,
        totalRequests = totalRequests,
        hitRate = hitRate,
        cacheSize = table.size(g_AdjacencyCache)
    }
end

-- Print cache statistics (for debugging)
function PrintCacheStatistics()
    local stats = GetCacheStatistics()
    print("=== Adjacency Cache Statistics ===")
    print("Cache hits:", stats.hits)
    print("Cache misses:", stats.misses)
    print("Total requests:", stats.totalRequests)
    print("Hit rate:", string.format("%.1f%%", stats.hitRate))
    print("Cache size:", stats.cacheSize, "entries")
    print("==================================")
end

-- Limit cache size to prevent memory issues
local MAX_CACHE_SIZE = 1000

function LimitCacheSize()
    local cacheSize = table.size(g_AdjacencyCache)
    
    if cacheSize > MAX_CACHE_SIZE then
        -- Simple approach: clear half the cache when limit is reached
        local keysToRemove = {}
        local count = 0
        local targetRemove = math.floor(cacheSize / 2)
        
        for key, _ in pairs(g_AdjacencyCache) do
            table.insert(keysToRemove, key)
            count = count + 1
            if count >= targetRemove then
                break
            end
        end
        
        for _, key in ipairs(keysToRemove) do
            g_AdjacencyCache[key] = nil
        end
        
        print("Cache size limit reached. Removed", #keysToRemove, "entries")
    end
end

-- Helper function to get table size
function table.size(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Enhanced main calculation function with caching
function CalculateDistrictAdjacencyBonusesCached(newDistrictType, placementX, placementY, playerID)
    local previewData = GetCachedAdjacencyPreviewData(newDistrictType, placementX, placementY, playerID)
    return previewData.bonuses, previewData.totalBonus
end

-- =============================================================================
-- TESTING AND VALIDATION FUNCTIONS (Task 4.0)
-- =============================================================================

-- Test all vanilla district types (Task 4.1)
function TestVanillaDistricts()
    print("=== Testing Vanilla District Types ===")
    
    local vanillaDistricts = {
        "DISTRICT_CAMPUS",
        "DISTRICT_THEATER",
        "DISTRICT_COMMERCIAL_HUB", 
        "DISTRICT_HARBOR",
        "DISTRICT_INDUSTRIAL_ZONE",
        "DISTRICT_HOLY_SITE",
        "DISTRICT_GOVERNMENT",
        "DISTRICT_ENTERTAINMENT_COMPLEX",
        "DISTRICT_WATER_ENTERTAINMENT_COMPLEX",
        "DISTRICT_AQUEDUCT",
        "DISTRICT_DAM",
        "DISTRICT_CANAL"
    }
    
    local testResults = {}
    
    for _, districtType in ipairs(vanillaDistricts) do
        local providesAdjacency = DoesDistrictProvideAdjacency(districtType)
        local targets = GetDistrictTargets(districtType)
        local displayName = GetDistrictDisplayName(districtType)
        
        testResults[districtType] = {
            providesAdjacency = providesAdjacency,
            targetCount = #targets,
            displayName = displayName,
            targets = targets
        }
        
        print(string.format("  %s (%s): Provides adjacency: %s, Targets: %d", 
            displayName, districtType, tostring(providesAdjacency), #targets))
        
        if #targets > 0 then
            for _, target in ipairs(targets) do
                print(string.format("    -> %s: +%d", GetDistrictDisplayName(target.districtType), target.bonus))
            end
        end
    end
    
    print("=== Vanilla District Test Complete ===")
    return testResults
end

-- Test civilization-specific districts (Task 4.2)
function TestCivilizationDistricts()
    print("=== Testing Civilization-Specific Districts ===")
    
    local uniqueDistricts = {
        {type = "DISTRICT_HANSA", civ = "CIVILIZATION_GERMANY", replaces = "DISTRICT_INDUSTRIAL_ZONE"},
        {type = "DISTRICT_ROYAL_NAVY_DOCKYARD", civ = "CIVILIZATION_ENGLAND", replaces = "DISTRICT_HARBOR"},
        {type = "DISTRICT_SUGUBA", civ = "CIVILIZATION_MALI", replaces = "DISTRICT_COMMERCIAL_HUB"},
        {type = "DISTRICT_LAVRA", civ = "CIVILIZATION_RUSSIA", replaces = "DISTRICT_HOLY_SITE"},
        {type = "DISTRICT_MBANZA", civ = "CIVILIZATION_KONGO", replaces = "DISTRICT_NEIGHBORHOOD"}
    }
    
    local testResults = {}
    
    for _, district in ipairs(uniqueDistricts) do
        local baseType = GetBaseDistrictType(district.type)
        local isUnique = IsUniqueDistrictForCivilization(district.type, district.civ)
        local displayName = GetDistrictDisplayName(district.type)
        local targets = GetDistrictTargets(district.type)
        
        testResults[district.type] = {
            baseType = baseType,
            isUnique = isUnique,
            displayName = displayName,
            civilization = district.civ,
            replaces = district.replaces,
            targetCount = #targets
        }
        
        print(string.format("  %s (%s):", displayName, district.type))
        print(string.format("    Base Type: %s", baseType))
        print(string.format("    Is Unique: %s", tostring(isUnique)))
        print(string.format("    Replaces: %s", district.replaces))
        print(string.format("    Targets: %d", #targets))
        
        -- Test adjacency calculation with civilization context
        if district.civ then
            local testBonus = GetCivilizationSpecificBonus(district.civ, district.type, "DISTRICT_CAMPUS")
            print(string.format("    Civ-specific bonus to Campus: %d", testBonus))
        end
    end
    
    print("=== Civilization District Test Complete ===")
    return testResults
end

-- Verify adjacency bonus calculations (Task 4.3)
function VerifyAdjacencyCalculations()
    print("=== Verifying Adjacency Bonus Calculations ===")
    
    local testCases = {
        {source = "DISTRICT_CAMPUS", target = "DISTRICT_THEATER", expected = 1},
        {source = "DISTRICT_THEATER", target = "DISTRICT_CAMPUS", expected = 1},
        {source = "DISTRICT_COMMERCIAL_HUB", target = "DISTRICT_HARBOR", expected = 2},
        {source = "DISTRICT_HARBOR", target = "DISTRICT_COMMERCIAL_HUB", expected = 2},
        {source = "DISTRICT_INDUSTRIAL_ZONE", target = "DISTRICT_AQUEDUCT", expected = 0}, -- Aqueduct provides TO Industrial Zone
        {source = "DISTRICT_AQUEDUCT", target = "DISTRICT_INDUSTRIAL_ZONE", expected = 2},
        {source = "DISTRICT_GOVERNMENT", target = "DISTRICT_CAMPUS", expected = 1},
        {source = "DISTRICT_CAMPUS", target = "DISTRICT_GOVERNMENT", expected = 1}
    }
    
    local passedTests = 0
    local totalTests = #testCases
    
    for i, testCase in ipairs(testCases) do
        local actualBonus = GetDistrictAdjacencyBonus(testCase.source, testCase.target)
        local passed = actualBonus == testCase.expected
        
        if passed then
            passedTests = passedTests + 1
        end
        
        print(string.format("  Test %d: %s -> %s", i, 
            GetDistrictDisplayName(testCase.source), 
            GetDistrictDisplayName(testCase.target)))
        print(string.format("    Expected: +%d, Actual: +%d, Result: %s", 
            testCase.expected, actualBonus, passed and "PASS" or "FAIL"))
    end
    
    local successRate = (passedTests / totalTests) * 100
    print(string.format("=== Calculation Verification Complete: %d/%d tests passed (%.1f%%) ===", 
        passedTests, totalTests, successRate))
    
    return {
        passed = passedTests,
        total = totalTests,
        successRate = successRate,
        allPassed = passedTests == totalTests
    }
end

-- Test UI visibility and functionality (Task 4.4)
function TestUIFunctionality()
    print("=== Testing UI Functionality ===")
    
    local uiTests = {
        {name = "UI Initialization", test = function() return g_IsUIInitialized end},
        {name = "Bonus Number Manager", test = function() return g_BonusNumberManager ~= nil end},
        {name = "Tooltip Manager", test = function() return g_TooltipManager ~= nil end},
        {name = "Format Bonus Text", test = function() 
            return FormatBonusText(3) == "+3" and FormatBonusText(0) == "+0" 
        end},
        {name = "Cache System", test = function() 
            ClearAdjacencyCache()
            local stats = GetCacheStatistics()
            return stats.cacheSize == 0
        end}
    }
    
    local passedTests = 0
    local totalTests = #uiTests
    
    for i, uiTest in ipairs(uiTests) do
        local success, result = pcall(uiTest.test)
        local passed = success and result
        
        if passed then
            passedTests = passedTests + 1
        end
        
        print(string.format("  UI Test %d: %s - %s", i, uiTest.name, passed and "PASS" or "FAIL"))
        if not success then
            print(string.format("    Error: %s", tostring(result)))
        end
    end
    
    local successRate = (passedTests / totalTests) * 100
    print(string.format("=== UI Test Complete: %d/%d tests passed (%.1f%%) ===", 
        passedTests, totalTests, successRate))
    
    return {
        passed = passedTests,
        total = totalTests,
        successRate = successRate,
        allPassed = passedTests == totalTests
    }
end

-- Performance testing (Task 4.6)
function TestPerformance()
    print("=== Performance Testing ===")
    
    local startTime = os.clock()
    
    -- Test adjacency calculations
    local calculationTests = 0
    for i = 1, 100 do
        local previewData = GetAdjacencyPreviewData("DISTRICT_CAMPUS", i % 50, i % 50, 0)
        calculationTests = calculationTests + 1
    end
    
    local calculationTime = os.clock() - startTime
    
    -- Test cache performance
    startTime = os.clock()
    local cacheTests = 0
    for i = 1, 100 do
        local previewData = GetCachedAdjacencyPreviewData("DISTRICT_CAMPUS", i % 10, i % 10, 0)
        cacheTests = cacheTests + 1
    end
    
    local cacheTime = os.clock() - startTime
    local cacheStats = GetCacheStatistics()
    
    print(string.format("  Calculation Performance: %d tests in %.3f seconds (%.3f ms per test)", 
        calculationTests, calculationTime, (calculationTime / calculationTests) * 1000))
    print(string.format("  Cache Performance: %d tests in %.3f seconds (%.3f ms per test)", 
        cacheTests, cacheTime, (cacheTime / cacheTests) * 1000))
    print(string.format("  Cache Hit Rate: %.1f%% (%d hits, %d misses)", 
        cacheStats.hitRate, cacheStats.hits, cacheStats.misses))
    
    return {
        calculationTime = calculationTime,
        cacheTime = cacheTime,
        cacheHitRate = cacheStats.hitRate,
        performanceGood = calculationTime < 1.0 and cacheTime < 0.5
    }
end

-- Comprehensive test suite (Task 4.8)
function RunComprehensiveTests()
    print("========================================")
    print("DISTRICT ADJACENCY PREVIEW - TEST SUITE")
    print("========================================")
    
    local testResults = {}
    
    -- Run all test categories
    testResults.vanilla = TestVanillaDistricts()
    testResults.civilization = TestCivilizationDistricts()
    testResults.calculations = VerifyAdjacencyCalculations()
    testResults.ui = TestUIFunctionality()
    testResults.performance = TestPerformance()
    
    -- Validate adjacency rules
    local ruleCount = ValidateAdjacencyRules()
    testResults.ruleValidation = {ruleCount = ruleCount, valid = ruleCount > 0}
    
    -- Print cache statistics
    PrintCacheStatistics()
    
    -- Overall summary
    print("========================================")
    print("TEST SUMMARY")
    print("========================================")
    print(string.format("Adjacency Calculations: %s (%d/%d passed)", 
        testResults.calculations.allPassed and "PASS" or "FAIL",
        testResults.calculations.passed, testResults.calculations.total))
    print(string.format("UI Functionality: %s (%d/%d passed)", 
        testResults.ui.allPassed and "PASS" or "FAIL",
        testResults.ui.passed, testResults.ui.total))
    print(string.format("Performance: %s", 
        testResults.performance.performanceGood and "GOOD" or "NEEDS IMPROVEMENT"))
    print(string.format("Rule Validation: %s (%d rules)", 
        testResults.ruleValidation.valid and "PASS" or "FAIL",
        testResults.ruleValidation.ruleCount))
    
    local overallSuccess = testResults.calculations.allPassed and 
                          testResults.ui.allPassed and 
                          testResults.performance.performanceGood and 
                          testResults.ruleValidation.valid
    
    print(string.format("OVERALL RESULT: %s", overallSuccess and "ALL TESTS PASSED" or "SOME TESTS FAILED"))
    print("========================================")
    
    return testResults
end

-- Initialize the mod when loaded
Initialize() 