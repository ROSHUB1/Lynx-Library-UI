-- Test example for the improved UI library.
local url = "https://raw.githubusercontent.com/ROSHUB1/Lynx-Library-UI/main/src/ui_library.lua"
local ok, res = pcall(function() return game:HttpGet(url) end)
local Library
if ok and res and #res > 10 then
    local fn, err = loadstring(res)
    if fn then
        local success, module = pcall(fn)
        if success and type(module) == "table" then
            Library = module
        else
            warn("Loaded but module not returned:", module or err)
        end
    else
        warn("loadstring error:", err)
    end
else
    warn("Failed to fetch library from URL. Falling back to local require (if available).")
    -- Library = require(game:GetService("ReplicatedStorage"):WaitForChild("ui_library"))
end

if not Library then
    warn("Library not loaded. Check URL or local require path.")
    return
end

-- require adapter locally (if saved as ModuleScript in ReplicatedStorage)
local Adapter = nil
pcall(function()
    Adapter = require(game:GetService("ReplicatedStorage"):WaitForChild("adapter"))
end)

local Window
if Adapter then
    Window = Adapter.CreateWindow(Library, "Baseplate", "http://www.roblox.com/asset/?id=7803241868")
else
    -- fallback: use library directly
    local Tabs, win = Library:Window("Baseplate", "http://www.roblox.com/asset/?id=7803241868")
    Window = { Tab = function(_,t) return Tabs:Tab(t) end }
end

local Tab = Window:Tab("Aiming")
local Tab2 = Window:Tab("Visual")

local ChamsSection = Tab2:Section({ Text = "Chams" })
ChamsSection:Toggle("Enabled", false, function(v) print("Chams Enabled:", v) end)
ChamsSection:Toggle("Color", false, function(v) print("Chams Color:", v) end)

local AimbotSection = Tab:Section({ Text = "Aimbot" })
AimbotSection:Toggle("Enabled", false, function(v) print("Aimbot Enabled:", v) end)
AimbotSection:Toggle("Smooth Aimbot", false, function(v) print("Smooth:", v) end)

print("Test UI created")
