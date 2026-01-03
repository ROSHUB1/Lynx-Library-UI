-- Example that demonstrates returned handles and two-column usage
local url = "https://raw.githubusercontent.com/ROSHUB1/Lynx-Library-UI/main/src/ui_library.lua"
local ok, res = pcall(function() return game:HttpGet(url) end)
if not ok or not res then warn("Failed to fetch library") return end
local Library = loadstring(res)()

-- require adapter locally (save src/adapter.lua as ModuleScript named "adapter" in ReplicatedStorage)
local Adapter = nil
pcall(function() Adapter = require(game:GetService("ReplicatedStorage"):WaitForChild("adapter")) end)

local Window
if Adapter then
    Window = Adapter.CreateWindow(Library, "Baseplate", "http://www.roblox.com/asset/?id=7803241868")
else
    local Tabs, win = Library:Window("Baseplate", "http://www.roblox.com/asset/?id=7803241868")
    Window = { Tab = function(_,t) return Tabs:Tab(t) end }
end

-- Create tabs
local Tab = Window:Tab("Aiming")
local Tab2 = Window:Tab("Visual")

-- Create sections (left and right)
local Aimbot = Tab:Section({Text="Aimbot", Side="Left"})
local FOV = Tab:Section({Text="FOV", Side="Right"})

-- Add toggles and capture handles
local noRecoil = Aimbot:Toggle("No Recoil", true, function(v) print("NoRecoil toggled",v) end)
print("Toggle initial state:", noRecoil:Get())
noRecoil:Set(false)

local lbl = Aimbot:Label("Status: Ready")
wait(0.5)
lbl:Set("Status: Running")

local dd = FOV:Dropdown("Aim Bone", {"Head","Torso","Random"}, function(v) print("Dropdown selected",v) end)
print("Dropdown selected initially:", dd:GetSelected())

print("Example ready")
