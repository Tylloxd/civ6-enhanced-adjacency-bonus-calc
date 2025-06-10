-- DetailedAdjacencyPreview.lua
-- Test version to verify mod loading

print("=== DETAILED ADJACENCY PREVIEW MOD LOADING ===");
print("Mod file: DetailedAdjacencyPreview.lua");
print("=== MOD SUCCESSFULLY LOADED ===");

-- Simple test to confirm event system works
function OnTestInterfaceModeChanged(oldMode, newMode)
    print(string.format("=== ADJACENCY PREVIEW === Interface mode: %s -> %s", 
        tostring(oldMode), tostring(newMode)));
end

-- Initialize with minimal setup
function Initialize()
    print("=== ADJACENCY PREVIEW === Initializing mod");
    
    -- Register for interface mode changes
    Events.InterfaceModeChanged.Add(OnTestInterfaceModeChanged);
    
    print("=== ADJACENCY PREVIEW === Event handlers registered successfully");
end

-- Initialize when script loads
Initialize(); 