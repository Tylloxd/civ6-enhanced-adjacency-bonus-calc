-- DetailedAdjacencyPreview_Overlays.lua
-- Enhanced visual overlay system for displaying adjacency benefits on the map

print("Loading Detailed Adjacency Preview Visual Overlay System");

-- =========================================================================
-- UI CONTROLS AND INSTANCES
-- =========================================================================

local g_OverlayInstances = {};
local g_OverlayContainer = nil;
local g_InstanceManager = nil;

-- Reference to the UI context controls
local Controls = {};

-- =========================================================================
-- INITIALIZATION
-- =========================================================================

-- Initialize the overlay system with proper UI context
function InitializeOverlays()
    print("Initializing adjacency benefit overlays with UI context");
    
    -- Get reference to the overlay container from XML
    g_OverlayContainer = ContextPtr:LookUpControl("AdjacencyOverlayContainer");
    if g_OverlayContainer then
        -- Create instance manager for benefit overlays
        g_InstanceManager = InstanceManager:new("AdjacencyBenefitOverlay", "BenefitContainer", g_OverlayContainer);
        print("Overlay instance manager created successfully");
    else
        print("ERROR: Could not find AdjacencyOverlayContainer in UI context");
    end
end

-- =========================================================================
-- WORLD-TO-SCREEN COORDINATE CONVERSION
-- =========================================================================

-- Convert plot coordinates to screen position for UI overlay
function GetScreenPositionFromPlot(plotX, plotY)
    local pPlot = Map.GetPlot(plotX, plotY);
    if not pPlot then
        return nil;
    end
    
    -- Get 3D world position from plot
    local worldX, worldY, worldZ = UI.GridToWorld(plotX, plotY);
    
    -- Convert world position to screen coordinates
    local screenX, screenY = UI.WorldToScreen(worldX, worldY, worldZ);
    
    -- Adjust for UI scaling and offset to center on tile
    local uiScale = UI.GetWorldRenderView():GetZoom();
    screenX = screenX * uiScale;
    screenY = screenY * uiScale;
    
    return {
        X = screenX,
        Y = screenY,
        IsOnScreen = screenX >= 0 and screenX <= UI.GetScreenSizeX() and 
                     screenY >= 0 and screenY <= UI.GetScreenSizeY()
    };
end

-- =========================================================================
-- ENHANCED OVERLAY CREATION AND MANAGEMENT
-- =========================================================================

-- Create a visual overlay for adjacency benefits with proper UI integration
function CreateAdjacencyOverlay(plotX, plotY, benefitText, benefits)
    if not g_InstanceManager then
        print("ERROR: Instance manager not initialized");
        return nil;
    end
    
    local overlayKey = plotX .. "_" .. plotY;
    
    -- Remove existing overlay for this plot
    RemoveOverlay(overlayKey);
    
    -- Get screen position for the plot
    local screenPos = GetScreenPositionFromPlot(plotX, plotY);
    if not screenPos or not screenPos.IsOnScreen then
        return nil;
    end
    
    -- Create new overlay instance
    local overlayInstance = g_InstanceManager:GetInstance();
    if not overlayInstance then
        print("ERROR: Failed to create overlay instance");
        return nil;
    end
    
    -- Configure the overlay appearance
    ConfigureOverlayAppearance(overlayInstance, benefitText, benefits);
    
    -- Position the overlay on screen
    overlayInstance.BenefitContainer:SetOffsetVal(screenPos.X - 60, screenPos.Y - 20);
    overlayInstance.BenefitContainer:SetHide(false);
    
    -- Store overlay data
    local overlayData = {
        PlotX = plotX,
        PlotY = plotY,
        Instance = overlayInstance,
        Text = benefitText,
        Benefits = benefits,
        Timestamp = Locale.GetCurrentGameTime()
    };
    
    g_OverlayInstances[overlayKey] = overlayData;
    
    print(string.format("[OVERLAY] Created benefit overlay at (%d,%d): %s", plotX, plotY, benefitText));
    
    return overlayKey;
end

-- Configure the visual appearance of an overlay to match game styling
function ConfigureOverlayAppearance(overlayInstance, benefitText, benefits)
    if not overlayInstance or not overlayInstance.BenefitText then
        return;
    end
    
    -- Set benefit text with proper formatting
    overlayInstance.BenefitText:SetText(benefitText);
    
    -- Configure background styling to match game UI
    if overlayInstance.BenefitBackground then
        overlayInstance.BenefitBackground:SetAlpha(0.8);
        overlayInstance.BenefitBackground:SetColor(0x2D004225); -- Dark semi-transparent background
    end
    
    -- Add subtle animation effect
    overlayInstance.BenefitContainer:SetAlpha(0);
    overlayInstance.BenefitContainer:RegisterAnimationCallback(
        function()
            overlayInstance.BenefitContainer:SetAlpha(1);
        end
    );
    
    -- Configure icon if single benefit type
    if benefits and overlayInstance.BenefitIcon then
        local singleYieldType = GetSingleYieldType(benefits);
        if singleYieldType then
            SetYieldIcon(overlayInstance.BenefitIcon, singleYieldType);
            overlayInstance.BenefitIcon:SetHide(false);
        else
            overlayInstance.BenefitIcon:SetHide(true);
        end
    end
end

-- Get single yield type if benefits contain only one type
function GetSingleYieldType(benefits)
    local yieldCount = 0;
    local singleYield = nil;
    
    for yieldType, _ in pairs(benefits) do
        yieldCount = yieldCount + 1;
        singleYield = yieldType;
        if yieldCount > 1 then
            return nil; -- Multiple yield types
        end
    end
    
    return singleYield;
end

-- Set appropriate yield icon for the benefit type
function SetYieldIcon(iconControl, yieldType)
    local yieldIcons = {
        ["YIELD_SCIENCE"] = "ICON_YIELD_SCIENCE",
        ["YIELD_GOLD"] = "ICON_YIELD_GOLD", 
        ["YIELD_PRODUCTION"] = "ICON_YIELD_PRODUCTION",
        ["YIELD_FAITH"] = "ICON_YIELD_FAITH",
        ["YIELD_CULTURE"] = "ICON_YIELD_CULTURE",
        ["YIELD_FOOD"] = "ICON_YIELD_FOOD"
    };
    
    local iconName = yieldIcons[yieldType];
    if iconName then
        iconControl:SetIcon(iconName);
    end
end

-- =========================================================================
-- DYNAMIC OVERLAY UPDATES
-- =========================================================================

-- Update all overlay positions (called when camera moves or zoom changes)
function UpdateOverlayPositions()
    for key, overlay in pairs(g_OverlayInstances) do
        if overlay.Instance then
            local screenPos = GetScreenPositionFromPlot(overlay.PlotX, overlay.PlotY);
            
            if screenPos and screenPos.IsOnScreen then
                -- Update position
                overlay.Instance.BenefitContainer:SetOffsetVal(screenPos.X - 60, screenPos.Y - 20);
                overlay.Instance.BenefitContainer:SetHide(false);
            else
                -- Hide if off-screen
                overlay.Instance.BenefitContainer:SetHide(true);
            end
        end
    end
end

-- Enhanced overlay creation that integrates with our main UI
function ShowAdjacencyBenefitsOverlay(plotX, plotY, benefits)
    if not benefits or not next(benefits) then
        return;
    end
    
    -- Format the benefits for display using core system
    local benefitText = "";
    if g_DetailedAdjacencyPreview and g_DetailedAdjacencyPreview.FormatBenefitsForDisplay then
        benefitText = g_DetailedAdjacencyPreview.FormatBenefitsForDisplay(benefits);
    end
    
    if benefitText ~= "" then
        CreateAdjacencyOverlay(plotX, plotY, benefitText, benefits);
    end
end

-- =========================================================================
-- OVERLAY CLEANUP AND MANAGEMENT
-- =========================================================================

-- Remove a specific overlay
function RemoveOverlay(overlayKey)
    if g_OverlayInstances[overlayKey] then
        local overlay = g_OverlayInstances[overlayKey];
        
        if overlay.Instance and g_InstanceManager then
            g_InstanceManager:ReleaseInstance(overlay.Instance);
        end
        
        g_OverlayInstances[overlayKey] = nil;
        print(string.format("[OVERLAY] Removed overlay: %s", overlayKey));
    end
end

-- Clear all overlays with proper cleanup
function ClearAllOverlays()
    for key, overlay in pairs(g_OverlayInstances) do
        if overlay.Instance and g_InstanceManager then
            g_InstanceManager:ReleaseInstance(overlay.Instance);
        end
    end
    
    g_OverlayInstances = {};
    print("[OVERLAY] All overlays cleared with proper cleanup");
end

-- Hide all overlays without destroying them (for temporary hiding)
function HideAllOverlays()
    for key, overlay in pairs(g_OverlayInstances) do
        if overlay.Instance and overlay.Instance.BenefitContainer then
            overlay.Instance.BenefitContainer:SetHide(true);
        end
    end
end

-- Show all previously hidden overlays
function ShowAllOverlays()
    for key, overlay in pairs(g_OverlayInstances) do
        if overlay.Instance and overlay.Instance.BenefitContainer then
            overlay.Instance.BenefitContainer:SetHide(false);
        end
    end
    UpdateOverlayPositions(); -- Ensure positions are current
end

-- =========================================================================
-- EVENT INTEGRATION
-- =========================================================================

-- Initialize overlay system when UI context loads
function OnUIContextLoad()
    InitializeOverlays();
end

-- Update positions when camera changes
function OnCameraUpdate()
    UpdateOverlayPositions();
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
    HideAllOverlays = HideAllOverlays,
    ShowAllOverlays = ShowAllOverlays,
    UpdateOverlayPositions = UpdateOverlayPositions,
    OnUIContextLoad = OnUIContextLoad,
    OnCameraUpdate = OnCameraUpdate
};

-- Event registration
Events.LoadGameViewStateDone.Add(OnUIContextLoad);
Events.CameraGameplayView.Add(OnCameraUpdate);

print("Enhanced Detailed Adjacency Preview Visual Overlay System Loaded"); 