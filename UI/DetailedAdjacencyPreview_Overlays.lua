-- DetailedAdjacencyPreview_Overlays.lua
-- Visual overlay system for displaying adjacency benefits on the map

print("Loading Detailed Adjacency Preview Visual Overlay System");

-- =========================================================================
-- OVERLAY RENDERING SYSTEM
-- =========================================================================

local g_OverlayInstances = {};
local g_OverlayContainer = nil;

-- Initialize the overlay system
function InitializeOverlays()
    -- We'll use the game's existing plotting overlay system
    print("Initializing adjacency benefit overlays");
end

-- Create a visual overlay for adjacency benefits
function CreateAdjacencyOverlay(plotX, plotY, benefitText)
    local overlayKey = plotX .. "_" .. plotY;
    
    -- Remove existing overlay for this plot
    RemoveOverlay(overlayKey);
    
    -- Create new overlay instance
    local overlayData = {
        PlotX = plotX,
        PlotY = plotY,
        Text = benefitText,
        Timestamp = Locale.GetCurrentGameTime()
    };
    
    g_OverlayInstances[overlayKey] = overlayData;
    
    -- For now, use console output (will be enhanced with actual UI rendering)
    print(string.format("[OVERLAY] Plot (%d,%d): %s", plotX, plotY, benefitText));
    
    -- TODO: Add actual 3D world overlay rendering
    -- This would typically involve:
    -- 1. Getting world position from plot coordinates
    -- 2. Creating UI element positioned in 3D space
    -- 3. Styling the overlay to match game aesthetics
    
    return overlayKey;
end

-- Remove a specific overlay
function RemoveOverlay(overlayKey)
    if g_OverlayInstances[overlayKey] then
        print(string.format("[OVERLAY] Removing overlay: %s", overlayKey));
        g_OverlayInstances[overlayKey] = nil;
    end
end

-- Clear all overlays
function ClearAllOverlays()
    for key, _ in pairs(g_OverlayInstances) do
        g_OverlayInstances[key] = nil;
    end
    print("[OVERLAY] All overlays cleared");
end

-- Update overlay positions (called when camera moves)
function UpdateOverlayPositions()
    -- Update 3D positions of overlays based on current camera
    for key, overlay in pairs(g_OverlayInstances) do
        -- TODO: Update world-to-screen position calculation
    end
end

-- =========================================================================
-- INTEGRATION WITH MAIN UI SYSTEM
-- =========================================================================

-- Enhanced overlay creation that integrates with our main UI
function ShowAdjacencyBenefitsOverlay(plotX, plotY, benefits)
    if not benefits or not next(benefits) then
        return;
    end
    
    -- Format the benefits for display
    local benefitText = "";
    if g_DetailedAdjacencyPreview and g_DetailedAdjacencyPreview.FormatBenefitsForDisplay then
        benefitText = g_DetailedAdjacencyPreview.FormatBenefitsForDisplay(benefits);
    end
    
    if benefitText ~= "" then
        CreateAdjacencyOverlay(plotX, plotY, benefitText);
    end
end

-- =========================================================================
-- EXPORT FUNCTIONS
-- =========================================================================

g_DetailedAdjacencyPreviewOverlays = {
    InitializeOverlays = InitializeOverlays,
    CreateAdjacencyOverlay = CreateAdjacencyOverlay,
    ShowAdjacencyBenefitsOverlay = ShowAdjacencyBenefitsOverlay,
    RemoveOverlay = RemoveOverlay,
    ClearAllOverlays = ClearAllOverlays,
    UpdateOverlayPositions = UpdateOverlayPositions
};

print("Detailed Adjacency Preview Visual Overlay System Loaded"); 