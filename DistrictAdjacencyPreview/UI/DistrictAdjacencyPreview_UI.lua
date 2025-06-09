-- =============================================================================
-- District Adjacency Preview UI
-- Author: District Adjacency Preview Team
-- Description: UI handling and display logic for showing adjacency bonuses
--              during district placement preview
-- =============================================================================

print("Loading District Adjacency Preview UI...")

-- =============================================================================
-- INCLUDES AND DEPENDENCIES
-- =============================================================================

include("InstanceManager")
include("SupportFunctions")

-- =============================================================================
-- UI GLOBAL VARIABLES
-- =============================================================================

local g_UIContext = nil
local g_BonusNumberManager = nil
local g_TooltipManager = nil
local g_ActiveBonusInstances = {}
local g_IsUIInitialized = false
local g_CurrentPreviewData = nil

-- UI state tracking
local g_UIState = {
    isPreviewActive = false,
    currentDistrictType = nil,
    currentPlotX = -1,
    currentPlotY = -1,
    playerID = -1
}

-- =============================================================================
-- UI INITIALIZATION (Task 3.2)
-- =============================================================================

-- Initialize the UI context and instance managers
function InitializeUI()
    if g_IsUIInitialized then
        return true
    end
    
    print("Initializing District Adjacency Preview UI...")
    
    -- Load the UI context
    g_UIContext = ContextPtr:LoadNewContext("DistrictAdjacencyPreviewContext")
    if g_UIContext == nil then
        print("ERROR: Failed to load DistrictAdjacencyPreviewContext")
        return false
    end
    
    -- Initialize instance managers
    g_BonusNumberManager = InstanceManager:new("AdjacencyBonusNumber", "BonusNumberContainer", g_UIContext)
    if g_BonusNumberManager == nil then
        print("ERROR: Failed to create BonusNumberManager")
        return false
    end
    
    g_TooltipManager = InstanceManager:new("AdjacencyTooltip", "TooltipContainer", g_UIContext)
    if g_TooltipManager == nil then
        print("ERROR: Failed to create TooltipManager")
        return false
    end
    
    -- Set up event handlers
    SetupUIEventHandlers()
    
    g_IsUIInitialized = true
    print("District Adjacency Preview UI initialized successfully!")
    return true
end

-- Set up UI event handlers
function SetupUIEventHandlers()
    -- Connect to district placement events
    Events.DistrictPicker_FilterShown.Add(OnDistrictPickerShown)
    Events.DistrictPicker_FilterHidden.Add(OnDistrictPickerHidden)
    
    -- Connect to plot selection events
    Events.CityBannerManager_Updated.Add(OnCityBannerUpdate)
    Events.PlotSelected.Add(OnPlotSelected)
    
    -- Connect to input events for real-time updates
    Events.InputActionTriggered.Add(OnInputAction)
    
    -- Enhanced event handlers for district placement preview (Task 3.5)
    Events.DistrictPlacementShow.Add(OnDistrictPlacementShow)
    Events.DistrictPlacementHide.Add(OnDistrictPlacementHide)
    Events.DistrictPlacementUpdate.Add(OnDistrictPlacementUpdate)
    
    -- Real-time cursor movement handlers (Task 3.6)
    Events.PlotHover.Add(OnPlotHover)
    Events.CursorMove.Add(OnCursorMove)
    Events.PlotMouseEnter.Add(OnPlotMouseEnter)
    Events.PlotMouseExit.Add(OnPlotMouseExit)
    
    print("UI event handlers configured")
end

-- Clean up UI resources
function CleanupUI()
    if g_BonusNumberManager then
        g_BonusNumberManager:ResetInstances()
    end
    
    if g_TooltipManager then
        g_TooltipManager:ResetInstances()
    end
    
    g_ActiveBonusInstances = {}
    g_CurrentPreviewData = nil
    
    -- Reset UI state
    g_UIState.isPreviewActive = false
    g_UIState.currentDistrictType = nil
    g_UIState.currentPlotX = -1
    g_UIState.currentPlotY = -1
    g_UIState.playerID = -1
    
    print("UI cleaned up")
end

-- =============================================================================
-- UI STATE MANAGEMENT
-- =============================================================================

-- Update UI state when district picker is shown
function OnDistrictPickerShown()
    print("District picker shown - activating UI preview")
    g_UIState.isPreviewActive = true
    g_UIState.playerID = Game.GetLocalPlayer()
    
    -- Initialize UI if not already done
    if not g_IsUIInitialized then
        InitializeUI()
    end
end

-- Update UI state when district picker is hidden
function OnDistrictPickerHidden()
    print("District picker hidden - deactivating UI preview")
    g_UIState.isPreviewActive = false
    CleanupUI()
end

-- Handle plot selection for preview updates
function OnPlotSelected(plotX, plotY)
    if not g_UIState.isPreviewActive or not g_IsUIInitialized then
        return
    end
    
    -- Update current plot coordinates
    g_UIState.currentPlotX = plotX
    g_UIState.currentPlotY = plotY
    
    -- Update preview if we have a district type selected
    if g_UIState.currentDistrictType then
        UpdateAdjacencyPreview(g_UIState.currentDistrictType, plotX, plotY)
    end
end

-- Handle city banner updates (placeholder for district type detection)
function OnCityBannerUpdate()
    if not g_UIState.isPreviewActive then
        return
    end
    
    -- This will be expanded in later tasks to detect the current district type
    -- For now, we just ensure the UI is ready
    if not g_IsUIInitialized then
        InitializeUI()
    end
end

-- Handle input actions for cursor movement
function OnInputAction(actionType, plotX, plotY)
    if not g_UIState.isPreviewActive or not g_IsUIInitialized then
        return
    end
    
    -- Update preview on cursor movement during district placement
    if actionType == "CURSOR_MOVE" and g_UIState.currentDistrictType then
        UpdateAdjacencyPreview(g_UIState.currentDistrictType, plotX, plotY)
    end
end

-- =============================================================================
-- UI DISPLAY FUNCTIONS (Tasks 3.3-3.4)
-- =============================================================================

-- Update the adjacency preview display
function UpdateAdjacencyPreview(districtType, plotX, plotY)
    if not g_IsUIInitialized or not g_UIState.isPreviewActive then
        return
    end
    
    -- Clear existing preview
    ClearAdjacencyPreview()
    
    -- Get adjacency data (this will connect to the calculation system)
    local previewData = GetAdjacencyPreviewData(districtType, plotX, plotY, g_UIState.playerID)
    
    if previewData and previewData.hasAnyBonus then
        g_CurrentPreviewData = previewData
        DisplayBonusNumbers(previewData)
        print("Updated adjacency preview for", districtType, "at", plotX, plotY)
    else
        print("No adjacency bonuses to display for", districtType, "at", plotX, plotY)
    end
end

-- Clear all active bonus number displays
function ClearAdjacencyPreview()
    if g_BonusNumberManager then
        g_BonusNumberManager:ResetInstances()
    end
    
    if g_TooltipManager then
        g_TooltipManager:ResetInstances()
    end
    
    g_ActiveBonusInstances = {}
    g_CurrentPreviewData = nil
end

-- Display bonus numbers on the appropriate tiles
function DisplayBonusNumbers(previewData)
    if not previewData or not previewData.bonuses then
        return
    end
    
    for _, bonusData in ipairs(previewData.bonuses) do
        CreateBonusNumberInstance(bonusData)
    end
end

-- Create a bonus number instance for a specific plot
function CreateBonusNumberInstance(bonusData)
    local instance = g_BonusNumberManager:GetInstance()
    if not instance then
        print("ERROR: Failed to create bonus number instance")
        return
    end
    
    -- Configure the bonus text
    local bonusText = FormatBonusText(bonusData.bonus)
    instance.BonusText:SetText(bonusText)
    
    -- Set text color based on bonus value
    if bonusData.bonus > 0 then
        instance.BonusText:SetColorByName("COLOR_GREEN")
    else
        instance.BonusText:SetColorByName("COLOR_GREY")
    end
    
    -- Position the instance on the correct plot
    PositionInstanceOnPlot(instance, bonusData.x, bonusData.y)
    
    -- Store reference for cleanup
    table.insert(g_ActiveBonusInstances, {
        instance = instance,
        plotX = bonusData.x,
        plotY = bonusData.y,
        bonus = bonusData.bonus
    })
    
    -- Animate the appearance
    AnimateInstanceFadeIn(instance)
    
    print("Created bonus number instance:", bonusText, "at", bonusData.x, bonusData.y)
end

-- Position a UI instance on a specific plot
function PositionInstanceOnPlot(instance, plotX, plotY)
    -- Convert plot coordinates to screen coordinates
    local worldPos = UI.GetPlotWorldPosition(plotX, plotY)
    if worldPos then
        local screenX, screenY = UI.GetWorldToScreenPosition(worldPos.x, worldPos.y, worldPos.z)
        
        -- Center the instance on the plot
        instance.BonusNumberContainer:SetOffsetX(screenX - 20)
        instance.BonusNumberContainer:SetOffsetY(screenY - 20)
        
        -- Make sure it's visible
        instance.BonusNumberContainer:SetHide(false)
    else
        print("ERROR: Could not get world position for plot", plotX, plotY)
    end
end

-- Animate instance fade in
function AnimateInstanceFadeIn(instance)
    if instance and instance.BonusNumberContainer then
        instance.BonusNumberContainer:SetAlpha(0)
        instance.BonusNumberContainer:SetHide(false)
        
        -- Simple fade in animation
        local fadeInAnim = instance.BonusNumberContainer:GetAlphaAnimation()
        fadeInAnim:SetToAlpha(1.0)
        fadeInAnim:SetSpeed(2.0)
        fadeInAnim:Play()
    end
end

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Format bonus value for display
function FormatBonusText(bonus)
    if bonus > 0 then
        return "+" .. tostring(bonus)
    else
        return "+0"
    end
end

-- Check if UI is ready for operations
function IsUIReady()
    return g_IsUIInitialized and g_UIState.isPreviewActive
end

-- Get current UI state (for debugging)
function GetUIState()
    return {
        initialized = g_IsUIInitialized,
        previewActive = g_UIState.isPreviewActive,
        districtType = g_UIState.currentDistrictType,
        plotX = g_UIState.currentPlotX,
        plotY = g_UIState.currentPlotY,
        playerID = g_UIState.playerID,
        activeInstances = #g_ActiveBonusInstances
    }
end

-- =============================================================================
-- ENHANCED DISTRICT PLACEMENT EVENT HANDLERS (Task 3.5)
-- =============================================================================

-- Handle district placement preview showing
function OnDistrictPlacementShow(districtType, cityID)
    print("District placement preview shown for", districtType)
    g_UIState.currentDistrictType = districtType
    g_UIState.isPreviewActive = true
    
    -- Initialize UI if needed
    if not g_IsUIInitialized then
        InitializeUI()
    end
    
    -- Update preview if we have plot coordinates
    if g_UIState.currentPlotX >= 0 and g_UIState.currentPlotY >= 0 then
        UpdateAdjacencyPreview(districtType, g_UIState.currentPlotX, g_UIState.currentPlotY)
    end
end

-- Handle district placement preview hiding
function OnDistrictPlacementHide()
    print("District placement preview hidden")
    g_UIState.currentDistrictType = nil
    ClearAdjacencyPreview()
end

-- Handle district placement updates (when district type changes)
function OnDistrictPlacementUpdate(districtType, cityID)
    print("District placement updated to", districtType)
    g_UIState.currentDistrictType = districtType
    
    -- Update preview with new district type
    if g_UIState.currentPlotX >= 0 and g_UIState.currentPlotY >= 0 then
        UpdateAdjacencyPreview(districtType, g_UIState.currentPlotX, g_UIState.currentPlotY)
    end
end

-- =============================================================================
-- REAL-TIME CURSOR MOVEMENT HANDLERS (Task 3.6)
-- =============================================================================

-- Handle plot hover events for real-time updates
function OnPlotHover(plotX, plotY)
    if not g_UIState.isPreviewActive or not g_IsUIInitialized or not g_UIState.currentDistrictType then
        return
    end
    
    -- Update coordinates
    g_UIState.currentPlotX = plotX
    g_UIState.currentPlotY = plotY
    
    -- Real-time preview update
    UpdateAdjacencyPreviewRealTime(g_UIState.currentDistrictType, plotX, plotY)
end

-- Handle cursor movement for continuous updates
function OnCursorMove(plotX, plotY)
    if not g_UIState.isPreviewActive or not g_IsUIInitialized or not g_UIState.currentDistrictType then
        return
    end
    
    -- Only update if the plot actually changed
    if plotX ~= g_UIState.currentPlotX or plotY ~= g_UIState.currentPlotY then
        g_UIState.currentPlotX = plotX
        g_UIState.currentPlotY = plotY
        
        -- Real-time preview update with throttling
        UpdateAdjacencyPreviewRealTime(g_UIState.currentDistrictType, plotX, plotY)
    end
end

-- Handle mouse entering a plot
function OnPlotMouseEnter(plotX, plotY)
    if not g_UIState.isPreviewActive or not g_IsUIInitialized then
        return
    end
    
    -- Show enhanced preview on mouse enter
    if g_UIState.currentDistrictType then
        HighlightAdjacencyPreview(plotX, plotY)
    end
end

-- Handle mouse exiting a plot
function OnPlotMouseExit(plotX, plotY)
    if not g_UIState.isPreviewActive or not g_IsUIInitialized then
        return
    end
    
    -- Remove highlight effects
    RemoveAdjacencyHighlight()
end

-- Real-time adjacency preview update with performance optimization
function UpdateAdjacencyPreviewRealTime(districtType, plotX, plotY)
    if not g_IsUIInitialized or not g_UIState.isPreviewActive then
        return
    end
    
    -- Use cached calculation for performance
    local previewData = GetCachedAdjacencyPreviewData(districtType, plotX, plotY, g_UIState.playerID)
    
    if previewData and previewData.hasAnyBonus then
        -- Update display without full clear/rebuild for performance
        UpdateBonusNumbersRealTime(previewData)
    else
        -- Clear if no bonuses
        ClearAdjacencyPreview()
    end
end

-- Update bonus numbers for real-time performance
function UpdateBonusNumbersRealTime(previewData)
    -- Clear existing instances
    ClearAdjacencyPreview()
    
    -- Display new numbers
    DisplayBonusNumbers(previewData)
    
    g_CurrentPreviewData = previewData
end

-- Highlight adjacency preview for enhanced visual feedback
function HighlightAdjacencyPreview(plotX, plotY)
    -- Add glow effects to active bonus numbers
    for _, instanceData in ipairs(g_ActiveBonusInstances) do
        if instanceData.instance and instanceData.instance.NumberGlow then
            instanceData.instance.NumberGlow:SetHide(false)
            
            -- Pulse animation for highlight
            local pulseAnim = instanceData.instance.NumberGlow:GetScaleAnimation()
            pulseAnim:SetToScale(1.2, 1.2)
            pulseAnim:SetSpeed(1.5)
            pulseAnim:SetCycle("Bounce")
            pulseAnim:Play()
        end
    end
end

-- Remove adjacency highlight effects
function RemoveAdjacencyHighlight()
    -- Remove glow effects
    for _, instanceData in ipairs(g_ActiveBonusInstances) do
        if instanceData.instance and instanceData.instance.NumberGlow then
            instanceData.instance.NumberGlow:SetHide(true)
            instanceData.instance.NumberGlow:StopAnimation()
        end
    end
end

-- =============================================================================
-- PERFORMANCE OPTIMIZATION FOR REAL-TIME UPDATES
-- =============================================================================

-- Throttling variables for performance
local g_LastUpdateTime = 0
local g_UpdateThrottleInterval = 0.1 -- Update at most every 100ms

-- Throttled update function to prevent performance issues
function ThrottledAdjacencyUpdate(districtType, plotX, plotY)
    local currentTime = os.clock()
    
    if currentTime - g_LastUpdateTime >= g_UpdateThrottleInterval then
        UpdateAdjacencyPreviewRealTime(districtType, plotX, plotY)
        g_LastUpdateTime = currentTime
    end
end

-- Enhanced cursor movement with throttling
function OnCursorMoveThrottled(plotX, plotY)
    if not g_UIState.isPreviewActive or not g_IsUIInitialized or not g_UIState.currentDistrictType then
        return
    end
    
    -- Only update if the plot actually changed
    if plotX ~= g_UIState.currentPlotX or plotY ~= g_UIState.currentPlotY then
        g_UIState.currentPlotX = plotX
        g_UIState.currentPlotY = plotY
        
        -- Use throttled update
        ThrottledAdjacencyUpdate(g_UIState.currentDistrictType, plotX, plotY)
    end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Initialize UI on load
print("District Adjacency Preview UI script loaded") 