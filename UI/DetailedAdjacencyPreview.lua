-- DetailedAdjacencyPreview.lua
-- Main UI integration script for the Detailed Adjacency Preview mod

print("Loading Detailed Adjacency Preview UI System");

-- =========================================================================
-- IMPORTS AND DEPENDENCIES
-- =========================================================================

include("DetailedAdjacencyPreview_Core");
include("DetailedAdjacencyPreview_Utils");
include("DetailedAdjacencyPreview_Overlays");

-- =========================================================================
-- UI STATE MANAGEMENT
-- =========================================================================

local g_isDistrictPlacementActive = false;
local g_currentDistrictType = nil;
local g_currentCity = nil;
local g_activeOverlays = {};

-- UI Controls
local m_adjacencyOverlays = {};

-- =========================================================================
-- DISTRICT PLACEMENT INTEGRATION
-- =========================================================================

-- Hook into district placement preview system
function OnDistrictPlacementBegin(pCity, districtType)
    print("District placement begun for: " .. tostring(districtType));
    
    g_isDistrictPlacementActive = true;
    g_currentDistrictType = districtType;
    g_currentCity = pCity;
    
    -- Clear any existing overlays
    ClearAllOverlays();
    
    -- Preload cache for performance
    if g_DetailedAdjacencyPreviewUtils and pCity then
        g_DetailedAdjacencyPreviewUtils.PreloadCache(pCity, {districtType});
    end
end

-- Handle mouse hover over plots during district placement
function OnPlotMouseOver(plotX, plotY)
    if not g_isDistrictPlacementActive or not g_currentCity or not g_currentDistrictType then
        return;
    end
    
    -- Clear previous overlays for this plot
    ClearPlotOverlays(plotX, plotY);
    
    -- Check if this plot is valid for district placement
    local pPlot = Map.GetPlot(plotX, plotY);
    if not pPlot or not CanPlaceDistrictOnPlot(pPlot, g_currentDistrictType) then
        return;
    end
    
    -- Calculate benefits for existing districts
    local benefits = nil;
    if g_DetailedAdjacencyPreview then
        benefits = g_DetailedAdjacencyPreview.CalculateExistingDistrictBenefits(
            g_currentCity, g_currentDistrictType, plotX, plotY
        );
    end
    
    if benefits and next(benefits) then
        ShowAdjacencyOverlays(plotX, plotY, benefits);
        -- Also use the overlay system for visual display
        for plotID, districtInfo in pairs(benefits) do
            if g_DetailedAdjacencyPreviewOverlays then
                g_DetailedAdjacencyPreviewOverlays.ShowAdjacencyBenefitsOverlay(
                    districtInfo.PlotX, districtInfo.PlotY, districtInfo.Benefits
                );
            end
        end
    end
end

-- Handle district placement end
function OnDistrictPlacementEnd()
    print("District placement ended");
    
    g_isDistrictPlacementActive = false;
    g_currentDistrictType = nil;
    g_currentCity = nil;
    
    -- Clear all overlays
    ClearAllOverlays();
end

-- =========================================================================
-- OVERLAY MANAGEMENT
-- =========================================================================

-- Show adjacency benefit overlays for existing districts
function ShowAdjacencyOverlays(targetPlotX, targetPlotY, benefitsMap)
    for plotID, districtInfo in pairs(benefitsMap) do
        local districtX = districtInfo.PlotX;
        local districtY = districtInfo.PlotY;
        local benefits = districtInfo.Benefits;
        
        if benefits and next(benefits) then
            CreateOverlayForDistrict(districtX, districtY, benefits);
        end
    end
end

-- Create overlay for a specific district showing its benefits
function CreateOverlayForDistrict(plotX, plotY, benefits)
    local overlayKey = plotX .. "_" .. plotY;
    
    -- Format benefits text
    local benefitText = "";
    if g_DetailedAdjacencyPreview and g_DetailedAdjacencyPreview.FormatBenefitsForDisplay then
        benefitText = g_DetailedAdjacencyPreview.FormatBenefitsForDisplay(benefits);
    end
    
    if benefitText == "" then
        return;
    end
    
    -- Create the overlay (this will be updated when we implement the visual system)
    local overlay = {
        PlotX = plotX,
        PlotY = plotY,
        Text = benefitText,
        Benefits = benefits
    };
    
    m_adjacencyOverlays[overlayKey] = overlay;
    
    -- For now, just print to console (will be replaced with actual UI overlay)
    print(string.format("Adjacency benefit at (%d,%d): %s", plotX, plotY, benefitText));
end

-- Clear overlays for a specific plot
function ClearPlotOverlays(plotX, plotY)
    local overlayKey = plotX .. "_" .. plotY;
    if m_adjacencyOverlays[overlayKey] then
        m_adjacencyOverlays[overlayKey] = nil;
    end
end

-- Clear all adjacency overlays
function ClearAllOverlays()
    for key, overlay in pairs(m_adjacencyOverlays) do
        m_adjacencyOverlays[key] = nil;
    end
end

-- =========================================================================
-- HELPER FUNCTIONS
-- =========================================================================

-- Check if a district can be placed on a plot
function CanPlaceDistrictOnPlot(pPlot, districtType)
    if not pPlot then
        return false;
    end
    
    -- Basic checks
    if pPlot:IsWater() and not IsWaterDistrict(districtType) then
        return false;
    end
    
    if not pPlot:IsWater() and IsWaterDistrict(districtType) then
        return false;
    end
    
    -- Check if plot already has a district
    if pPlot:GetDistrictType() ~= -1 then
        return false;
    end
    
    -- Check if plot has improvement that prevents district placement
    if pPlot:GetImprovementType() ~= -1 then
        local improvementInfo = GameInfo.Improvements[pPlot:GetImprovementType()];
        if improvementInfo and not improvementInfo.CanBeBuiltOnResource then
            return false;
        end
    end
    
    return true;
end

-- Check if district type is a water district
function IsWaterDistrict(districtType)
    local waterDistricts = {
        "DISTRICT_HARBOR",
        "DISTRICT_WATER_ENTERTAINMENT_COMPLEX"
    };
    
    for _, waterDistrict in ipairs(waterDistricts) do
        if districtType == waterDistrict then
            return true;
        end
    end
    
    return false;
end

-- =========================================================================
-- EVENT HANDLERS
-- =========================================================================

-- Listen for district placement events
function OnCityBannerClick(cityID, eMouseButton)
    -- This will be enhanced to detect district placement mode
end

-- Handle plot selection during district placement
function OnInterfaceModeChanged(eOldMode, eNewMode)
    -- INTERFACE_MODE_DISTRICT_PLACEMENT or similar
    if eNewMode == InterfaceModeTypes.DISTRICT_PLACEMENT then
        -- District placement started
        local pSelectedCity = UI.GetHeadSelectedCity();
        if pSelectedCity then
            OnDistrictPlacementBegin(pSelectedCity, "UNKNOWN"); -- We'll detect the actual type
        end
    else
        -- District placement ended
        if g_isDistrictPlacementActive then
            OnDistrictPlacementEnd();
        end
    end
end

-- Handle mouse events
function OnMouseOverHex(hexX, hexY)
    if g_isDistrictPlacementActive then
        OnPlotMouseOver(hexX, hexY);
    end
end

-- =========================================================================
-- INITIALIZATION
-- =========================================================================

function Initialize()
    print("Initializing Detailed Adjacency Preview UI");
    
    -- Register event handlers
    Events.InterfaceModeChanged.Add(OnInterfaceModeChanged);
    Events.MouseOverHex.Add(OnMouseOverHex);
    
    -- Initialize state
    g_isDistrictPlacementActive = false;
    g_currentDistrictType = nil;
    g_currentCity = nil;
    m_adjacencyOverlays = {};
    
    print("Detailed Adjacency Preview UI Initialized Successfully");
end

-- =========================================================================
-- EXPORT FUNCTIONS
-- =========================================================================

-- Make functions available for testing
g_DetailedAdjacencyPreviewUI = {
    OnDistrictPlacementBegin = OnDistrictPlacementBegin,
    OnDistrictPlacementEnd = OnDistrictPlacementEnd,
    OnPlotMouseOver = OnPlotMouseOver,
    ClearAllOverlays = ClearAllOverlays,
    IsActive = function() return g_isDistrictPlacementActive; end
};

-- Initialize when script loads
Initialize(); 