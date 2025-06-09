-- DetailedAdjacencyPreview_Utils.lua
-- Utility functions and caching system for the Detailed Adjacency Preview mod

print("Loading Detailed Adjacency Preview Utilities");

-- =========================================================================
-- CACHING SYSTEM
-- =========================================================================

-- Cache structure for storing calculated adjacency benefits
-- Key format: "CityID_DistrictType_PlotX_PlotY"
-- Value: { Benefits = {}, Timestamp = number, ExistingDistricts = {} }
local g_AdjacencyCache = {};

-- Cache settings
local CACHE_EXPIRY_TIME = 5; -- Cache expires after 5 seconds
local MAX_CACHE_SIZE = 100; -- Maximum number of cached entries
local g_CacheStats = {
    Hits = 0,
    Misses = 0,
    Evictions = 0
};

-- =========================================================================
-- CACHE MANAGEMENT FUNCTIONS
-- =========================================================================

-- Generate cache key for a specific calculation
function GenerateCacheKey(cityID, newDistrictType, plotX, plotY)
    return string.format("%d_%s_%d_%d", cityID, newDistrictType or "UNKNOWN", plotX or 0, plotY or 0);
end

-- Get current game time for cache expiry
function GetCurrentTime()
    return Locale.GetCurrentGameTime();
end

-- Check if a cache entry is still valid
function IsCacheEntryValid(cacheEntry)
    if not cacheEntry or not cacheEntry.Timestamp then
        return false;
    end
    
    local currentTime = GetCurrentTime();
    return (currentTime - cacheEntry.Timestamp) < CACHE_EXPIRY_TIME;
end

-- Get benefits from cache if available and valid
function GetCachedBenefits(cityID, newDistrictType, plotX, plotY)
    local cacheKey = GenerateCacheKey(cityID, newDistrictType, plotX, plotY);
    local cacheEntry = g_AdjacencyCache[cacheKey];
    
    if cacheEntry and IsCacheEntryValid(cacheEntry) then
        g_CacheStats.Hits = g_CacheStats.Hits + 1;
        return cacheEntry.Benefits;
    end
    
    g_CacheStats.Misses = g_CacheStats.Misses + 1;
    return nil;
end

-- Store calculated benefits in cache
function CacheBenefits(cityID, newDistrictType, plotX, plotY, benefits, existingDistricts)
    local cacheKey = GenerateCacheKey(cityID, newDistrictType, plotX, plotY);
    
    -- Check if we need to evict old entries to make room
    if GetCacheSize() >= MAX_CACHE_SIZE then
        EvictOldestCacheEntry();
    end
    
    g_AdjacencyCache[cacheKey] = {
        Benefits = benefits,
        Timestamp = GetCurrentTime(),
        ExistingDistricts = existingDistricts or {},
        CityID = cityID,
        DistrictType = newDistrictType,
        PlotX = plotX,
        PlotY = plotY
    };
end

-- Get current cache size
function GetCacheSize()
    local count = 0;
    for _ in pairs(g_AdjacencyCache) do
        count = count + 1;
    end
    return count;
end

-- Evict the oldest cache entry
function EvictOldestCacheEntry()
    local oldestKey = nil;
    local oldestTime = math.huge;
    
    for key, entry in pairs(g_AdjacencyCache) do
        if entry.Timestamp and entry.Timestamp < oldestTime then
            oldestTime = entry.Timestamp;
            oldestKey = key;
        end
    end
    
    if oldestKey then
        g_AdjacencyCache[oldestKey] = nil;
        g_CacheStats.Evictions = g_CacheStats.Evictions + 1;
    end
end

-- Clear expired cache entries
function ClearExpiredCache()
    local currentTime = GetCurrentTime();
    local expiredKeys = {};
    
    for key, entry in pairs(g_AdjacencyCache) do
        if not IsCacheEntryValid(entry) then
            table.insert(expiredKeys, key);
        end
    end
    
    for _, key in ipairs(expiredKeys) do
        g_AdjacencyCache[key] = nil;
    end
end

-- Clear all cache entries (useful when city state changes)
function ClearAllCache()
    g_AdjacencyCache = {};
    g_CacheStats.Hits = 0;
    g_CacheStats.Misses = 0;
    g_CacheStats.Evictions = 0;
end

-- Clear cache for a specific city (when districts are built/destroyed)
function ClearCityCache(cityID)
    local keysToRemove = {};
    
    for key, entry in pairs(g_AdjacencyCache) do
        if entry.CityID == cityID then
            table.insert(keysToRemove, key);
        end
    end
    
    for _, key in ipairs(keysToRemove) do
        g_AdjacencyCache[key] = nil;
    end
end

-- =========================================================================
-- CACHE STATISTICS AND DEBUGGING
-- =========================================================================

-- Get cache performance statistics
function GetCacheStats()
    local totalRequests = g_CacheStats.Hits + g_CacheStats.Misses;
    local hitRate = totalRequests > 0 and (g_CacheStats.Hits / totalRequests * 100) or 0;
    
    return {
        Hits = g_CacheStats.Hits,
        Misses = g_CacheStats.Misses,
        Evictions = g_CacheStats.Evictions,
        HitRate = hitRate,
        CacheSize = GetCacheSize(),
        MaxSize = MAX_CACHE_SIZE
    };
end

-- Print cache statistics (for debugging)
function PrintCacheStats()
    local stats = GetCacheStats();
    print(string.format("Adjacency Cache Stats: Hits=%d, Misses=%d, Hit Rate=%.1f%%, Size=%d/%d, Evictions=%d", 
        stats.Hits, stats.Misses, stats.HitRate, stats.CacheSize, stats.MaxSize, stats.Evictions));
end

-- =========================================================================
-- PERFORMANCE OPTIMIZATION UTILITIES
-- =========================================================================

-- Batch calculate benefits for multiple plots (more efficient)
function BatchCalculateBenefits(pCity, newDistrictType, plotList)
    if not pCity or not newDistrictType or not plotList then
        return {};
    end
    
    local results = {};
    local cityID = pCity:GetID();
    
    -- First, check cache for all plots
    for i, plotData in ipairs(plotList) do
        local plotX, plotY = plotData.X, plotData.Y;
        local cachedBenefits = GetCachedBenefits(cityID, newDistrictType, plotX, plotY);
        
        if cachedBenefits then
            results[i] = {
                PlotX = plotX,
                PlotY = plotY,
                Benefits = cachedBenefits,
                FromCache = true
            };
        else
            results[i] = {
                PlotX = plotX,
                PlotY = plotY,
                Benefits = nil,
                FromCache = false
            };
        end
    end
    
    -- Calculate missing benefits and cache them
    for i, result in ipairs(results) do
        if not result.FromCache then
            -- Import the calculation function from Core
            if g_DetailedAdjacencyPreview and g_DetailedAdjacencyPreview.CalculateExistingDistrictBenefits then
                local benefits = g_DetailedAdjacencyPreview.CalculateExistingDistrictBenefits(
                    pCity, newDistrictType, result.PlotX, result.PlotY
                );
                
                result.Benefits = benefits;
                CacheBenefits(cityID, newDistrictType, result.PlotX, result.PlotY, benefits);
            end
        end
    end
    
    return results;
end

-- Preload cache for common district placements
function PreloadCache(pCity, districtTypes)
    if not pCity or not districtTypes then
        return;
    end
    
    -- Get all valid plots around the city for district placement
    local cityPlots = Map.GetCityPlots():GetPurchasedPlots(pCity);
    local validPlots = {};
    
    for _, plotID in ipairs(cityPlots) do
        local pPlot = Map.GetPlotByIndex(plotID);
        if pPlot and pPlot:CanHaveDistrict() then
            table.insert(validPlots, {
                X = pPlot:GetX(),
                Y = pPlot:GetY()
            });
        end
    end
    
    -- Preload cache for each district type
    for _, districtType in ipairs(districtTypes) do
        BatchCalculateBenefits(pCity, districtType, validPlots);
    end
end

-- =========================================================================
-- EVENT HANDLERS FOR CACHE MANAGEMENT
-- =========================================================================

-- Clear cache when city state changes (districts built/destroyed)
function OnCityDistrictChanged(cityID)
    ClearCityCache(cityID);
end

-- Periodic cache cleanup
function OnTurnBegin()
    ClearExpiredCache();
    
    -- Print stats every 10 turns for debugging (can be removed in release)
    local currentTurn = Game.GetCurrentGameTurn();
    if currentTurn % 10 == 0 then
        PrintCacheStats();
    end
end

-- =========================================================================
-- EXPORT FUNCTIONS
-- =========================================================================

-- Make functions available to other parts of the mod
g_DetailedAdjacencyPreviewUtils = {
    -- Cache functions
    GetCachedBenefits = GetCachedBenefits,
    CacheBenefits = CacheBenefits,
    ClearAllCache = ClearAllCache,
    ClearCityCache = ClearCityCache,
    
    -- Performance functions
    BatchCalculateBenefits = BatchCalculateBenefits,
    PreloadCache = PreloadCache,
    
    -- Statistics
    GetCacheStats = GetCacheStats,
    PrintCacheStats = PrintCacheStats,
    
    -- Event handlers
    OnCityDistrictChanged = OnCityDistrictChanged,
    OnTurnBegin = OnTurnBegin
};

print("Detailed Adjacency Preview Utilities Loaded Successfully"); 