-- test.lua trong GitHub của bạn
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

local Window = OrionLib:MakeWindow({Name = "🌱 Garden Hub Test", HidePremium = false, SaveConfig = true, ConfigFolder = "GardenHub"})

local Tab = Window:MakeTab({
    Name = "Test Tab",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

Tab:AddButton({
    Name = "Hello World",
    Callback = function()
        print("Nút Hello đã bấm!")
    end    
})

OrionLib:Init()
