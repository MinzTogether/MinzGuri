--[[ 
  🌱 Grow a Garden Hub (OrionLib) - UI Skeleton
  Tabs: Settings / Home / Pet / Shop
  - WalkSpeed keeper + Infinite Jump + Noclip hoạt động ngay
  - Các mục khác là placeholder (để nối Remote sau)
]]

-- ========== LIB ==========
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- ========== SERVICES & HELPERS ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local function Humanoid()
    local ch = LP.Character
    if not ch then return nil end
    return ch:FindFirstChildOfClass("Humanoid")
end

local function HRP()
    local ch = LP.Character
    if not ch then return nil end
    return ch:FindFirstChild("HumanoidRootPart")
end

local function clamp(n, a, b)
    if n < a then return a end
    if n > b then return b end
    return n
end

-- ========== GLOBAL STATE ==========
getgenv().GG = {
    -- Settings
    DesiredSpeed = 16,
    ApplySpeed = false,
    InfJump = false,
    Noclip = false,

    -- Home
    PlantMode = "Random", -- "Random" | "At Player"
    AutoPlant = false,

    AutoCollect = false,
    FruitSearch = "",
    MutationSearch = "",

    -- Events
    Beanstalk = {
        AutoHarvestRequired = false,
        AutoSubmitAll = false,
        AutoCollectEventItems = false,
    },
    Cooking = {
        Slots = {"","","","",""},
        AutoCook = false,
        AutoTakeFood = false,
    },

    -- Mutation
    MutationActivateMachine = false, -- via button
    MutationSubmitHeldPet = false,   -- via button

    -- Craft
    Craft = {
        GearSelected = "",
        SeedSelected = "",
        AutoCraftGearSelected = false,
        AutoCraftSeedSelected = false
    },

    -- Pet
    Pet = {
        EggSelected = "",
        AutoPlaceEgg = false,
        AutoHatch = false,
        BoostPetSelected = "",
        BoostItemSelected = "",
        AutoApplyBoost = false,
    },

    -- Shop
    Shop = {
        SeedSelected = "",
        AutoBuySeedSelected = false,
        AutoBuyAllSeed = false,

        GearSelected = "",
        AutoBuyGearSelected = false,
        AutoBuyAllGear = false,

        EggSelected = "",
        AutoBuyEggSelected = false,
        AutoBuyAllEgg = false,

        TravelingSelected = "",
        AutoBuyTravelingSelected = false,

        EventOpenBeanShop = false,
        EventSelected = "",
        AutoBuyEventSelected = false,
        AutoBuyEventAll = false
    }
}

-- ========== BACKGROUND LOOPS ==========
-- WalkSpeed keeper (chỉ khi ApplySpeed = true)
RunService.Heartbeat:Connect(function()
    if getgenv().GG.ApplySpeed then
        local h = Humanoid()
        if h and typeof(getgenv().GG.DesiredSpeed) == "number" then
            h.WalkSpeed = clamp(getgenv().GG.DesiredSpeed, 16, 1000)
        end
    end
end)

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if getgenv().GG.InfJump then
        local h = Humanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if getgenv().GG.Noclip then
        local ch = LP.Character
        if ch then
            for _,v in ipairs(ch:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

-- ========== ORION WINDOW ==========
local Window = OrionLib:MakeWindow({
    Name = "🌱 Grow a Garden Hub",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "GrowGardenHub"
})

-- ===================== TAB SETTINGS =====================
local SettingsTab = Window:MakeTab({
    Name = "⚙️ Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddParagraph("WalkSpeed","Chọn và áp dụng tốc độ mong muốn (tối đa 1000).")

SettingsTab:AddSlider({
    Name = "WalkSpeed (Slider)",
    Min = 16, Max = 1000, Default = 16, Increment = 1,
    Callback = function(v)
        getgenv().GG.DesiredSpeed = v
        print("[Settings] DesiredSpeed (slider) =", v)
    end
})

SettingsTab:AddTextbox({
    Name = "WalkSpeed (Nhập số)",
    Default = tostring(getgenv().GG.DesiredSpeed),
    TextDisappear = false,
    Callback = function(txt)
        local n = tonumber(txt) or 16
        getgenv().GG.DesiredSpeed = clamp(n,16,1000)
        print("[Settings] DesiredSpeed (input) =", getgenv().GG.DesiredSpeed)
    end
})

SettingsTab:AddToggle({
    Name = "Áp dụng WalkSpeed",
    Default = false,
    Callback = function(v)
        getgenv().GG.ApplySpeed = v
        print("[Settings] ApplySpeed =", v)
    end
})

SettingsTab:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Callback = function(v)
        getgenv().GG.InfJump = v
        print("[Settings] InfiniteJump =", v)
    end
})

SettingsTab:AddToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(v)
        getgenv().GG.Noclip = v
        print("[Settings] Noclip =", v)
    end
})

-- ===================== TAB HOME =====================
local HomeTab = Window:MakeTab({
    Name = "🏡 Home",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
})

HomeTab:AddSection({Name = "Chế độ trồng"})
HomeTab:AddDropdown({
    Name = "Chọn chế độ trồng",
    Default = "Random",
    Options = {"Random","At Player"},
    Callback = function(opt)
        getgenv().GG.PlantMode = opt
        print("[Home] PlantMode =", opt)
    end
})

HomeTab:AddToggle({
    Name = "Tự động trồng",
    Default = false,
    Callback = function(v)
        getgenv().GG.AutoPlant = v
        print("[Home] AutoPlant =", v, "| Mode =", getgenv().GG.PlantMode)
        -- TODO: nối Remote Plant
    end
})

HomeTab:AddSection({Name = "Tự động nhặt"})
HomeTab:AddToggle({
    Name = "Auto Collect",
    Default = false,
    Callback = function(v)
        getgenv().GG.AutoCollect = v
        print("[Home] AutoCollect =", v)
        -- TODO: logic collect theo bộ lọc
    end
})
HomeTab:AddTextbox({
    Name = "Tìm trái (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.FruitSearch = tostring(txt or "")
        print("[Home] FruitSearch =", getgenv().GG.FruitSearch)
    end
})
HomeTab:AddTextbox({
    Name = "Tìm mutation (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.MutationSearch = tostring(txt or "")
        print("[Home] MutationSearch =", getgenv().GG.MutationSearch)
    end
})

HomeTab:AddSection({Name = "Event: Beanstalk"})
HomeTab:AddToggle({
    Name = "Auto thu hoạch trái theo yêu cầu NPC",
    Default = false,
    Callback = function(v)
        getgenv().GG.Beanstalk.AutoHarvestRequired = v
        print("[Event-Beanstalk] AutoHarvestRequired =", v)
    end
})
HomeTab:AddToggle({
    Name = "Auto nộp ALL trái cho NPC",
    Default = false,
    Callback = function(v)
        getgenv().GG.Beanstalk.AutoSubmitAll = v
        print("[Event-Beanstalk] AutoSubmitAll =", v)
    end
})
HomeTab:AddToggle({
    Name = "Auto nhặt vật phẩm sự kiện",
    Default = false,
    Callback = function(v)
        getgenv().GG.Beanstalk.AutoCollectEventItems = v
        print("[Event-Beanstalk] AutoCollectEventItems =", v)
    end
})

HomeTab:AddSection({Name = "Event: Cooking"})
for i=1,5 do
    HomeTab:AddTextbox({
        Name = ("Chọn trái thứ %d (search)"):format(i),
        Default = "",
        TextDisappear = false,
        Callback = function(txt)
            getgenv().GG.Cooking.Slots[i] = tostring(txt or "")
            print(("[Event-Cooking] Slot[%d] = %s"):format(i, getgenv().GG.Cooking.Slots[i]))
        end
    })
end
HomeTab:AddToggle({
    Name = "Auto Cook",
    Default = false,
    Callback = function(v)
        getgenv().GG.Cooking.AutoCook = v
        print("[Event-Cooking] AutoCook =", v, "| Slots =", table.concat(getgenv().GG.Cooking.Slots,", "))
    end
})
HomeTab:AddToggle({
    Name = "Auto lấy food",
    Default = false,
    Callback = function(v)
        getgenv().GG.Cooking.AutoTakeFood = v
        print("[Event-Cooking] AutoTakeFood =", v)
    end
})

HomeTab:AddSection({Name = "Mutation"})
HomeTab:AddButton({
    Name = "Kích hoạt máy mutation (không có pet)",
    Callback = function()
        print("[Mutation] Activate machine (placeholder) → TODO: FireServer remote kích hoạt")
    end
})
HomeTab:AddButton({
    Name = "Nộp pet đang cầm (ưu tiên nộp ngay, không nộp khi máy đã có pet)",
    Callback = function()
        print("[Mutation] Submit held pet (placeholder) → TODO: FireServer remote nộp pet")
    end
})

HomeTab:AddSection({Name = "Craft"})
HomeTab:AddTextbox({
    Name = "Chọn Gear (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.Craft.GearSelected = tostring(txt or "")
        print("[Craft] GearSelected =", getgenv().GG.Craft.GearSelected)
    end
})
HomeTab:AddTextbox({
    Name = "Chọn Seed (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.Craft.SeedSelected = tostring(txt or "")
        print("[Craft] SeedSelected =", getgenv().GG.Craft.SeedSelected)
    end
})
HomeTab:AddToggle({
    Name = "Auto craft GEAR đã chọn",
    Default = false,
    Callback = function(v)
        getgenv().GG.Craft.AutoCraftGearSelected = v
        print("[Craft] AutoCraftGearSelected =", v, "| Gear =", getgenv().GG.Craft.GearSelected)
    end
})
HomeTab:AddToggle({
    Name = "Auto craft SEED đã chọn",
    Default = false,
    Callback = function(v)
        getgenv().GG.Craft.AutoCraftSeedSelected = v
        print("[Craft] AutoCraftSeedSelected =", v, "| Seed =", getgenv().GG.Craft.SeedSelected)
    end
})

-- ===================== TAB PET =====================
local PetTab = Window:MakeTab({
    Name = "🐾 Pet",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false
})

PetTab:AddSection({Name = "Auto Egg"})
PetTab:AddTextbox({
    Name = "Chọn Egg (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.Pet.EggSelected = tostring(txt or "")
        print("[Pet] EggSelected =", getgenv().GG.Pet.EggSelected)
    end
})
PetTab:AddToggle({
    Name = "Auto đặt egg đã chọn",
    Default = false,
    Callback = function(v)
        getgenv().GG.Pet.AutoPlaceEgg = v
        print("[Pet] AutoPlaceEgg =", v, "| Egg =", getgenv().GG.Pet.EggSelected)
    end
})
PetTab:AddToggle({
    Name = "Auto nở egg đã chọn",
    Default = false,
    Callback = function(v)
        getgenv().GG.Pet.AutoHatch = v
        print("[Pet] AutoHatch =", v, "| Egg =", getgenv().GG.Pet.EggSelected)
    end
})

PetTab:AddSection({Name = "Pet Boosts"})
PetTab:AddTextbox({
    Name = "Chọn pet đã thả ở vườn (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.Pet.BoostPetSelected = tostring(txt or "")
        print("[Pet] BoostPetSelected =", getgenv().GG.Pet.BoostPetSelected)
    end
})
PetTab:AddButton({
    Name = "Làm mới danh sách pet (placeholder)",
    Callback = function()
        print("[Pet] Refresh deployed pets → TODO: đọc data pet")
    end
})
PetTab:AddTextbox({
    Name = "Chọn vật phẩm boost (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.Pet.BoostItemSelected = tostring(txt or "")
        print("[Pet] BoostItemSelected =", getgenv().GG.Pet.BoostItemSelected)
    end
})
PetTab:AddToggle({
    Name = "Auto dùng boost đã chọn",
    Default = false,
    Callback = function(v)
        getgenv().GG.Pet.AutoApplyBoost = v
        print("[Pet] AutoApplyBoost =", v, "| Pet =", getgenv().GG.Pet.BoostPetSelected, "| Item =", getgenv().GG.Pet.BoostItemSelected)
    end
})

-- ===================== TAB SHOP =====================
local ShopTab = Window:MakeTab({
    Name = "🛒 Shop",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ShopTab:AddSection({Name = "Seed Shop"})
ShopTab:AddTextbox({
    Name = "Chọn seed (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.Shop.SeedSelected = tostring(txt or "")
        print("[Shop-Seed] Selected =", getgenv().GG.Shop.SeedSelected)
    end
})
ShopTab:AddToggle({
    Name = "Auto mua seed đã chọn",
    Default = false,
    Callback = function(v)
        getgenv().GG.Shop.AutoBuySeedSelected = v
        print("[Shop-Seed] AutoBuySelected =", v)
    end
})
ShopTab:AddToggle({
    Name = "Auto mua ALL seed",
    Default = false,
    Callback = function(v)
        getgenv().GG.Shop.AutoBuyAllSeed = v
        print("[Shop-Seed] AutoBuyAll =", v)
    end
})

ShopTab:AddSection({Name = "Gear Shop"})
ShopTab:AddTextbox({
    Name = "Chọn gear (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.Shop.GearSelected = tostring(txt or "")
        print("[Shop-Gear] Selected =", getgenv().GG.Shop.GearSelected)
    end
})
ShopTab:AddToggle({
    Name = "Auto mua gear đã chọn",
    Default = false,
    Callback = function(v)
        getgenv().GG.Shop.AutoBuyGearSelected = v
        print("[Shop-Gear] AutoBuySelected =", v)
    end
})
ShopTab:AddToggle({
    Name = "Auto mua ALL gear",
    Default = false,
    Callback = function(v)
        getgenv().GG.Shop.AutoBuyAllGear = v
        print("[Shop-Gear] AutoBuyAll =", v)
    end
})

ShopTab:AddSection({Name = "Egg Shop"})
ShopTab:AddTextbox({
    Name = "Chọn egg (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.Shop.EggSelected = tostring(txt or "")
        print("[Shop-Egg] Selected =", getgenv().GG.Shop.EggSelected)
    end
})
ShopTab:AddToggle({
    Name = "Auto mua egg đã chọn",
    Default = false,
    Callback = function(v)
        getgenv().GG.Shop.AutoBuyEggSelected = v
        print("[Shop-Egg] AutoBuySelected =", v)
    end
})
ShopTab:AddToggle({
    Name = "Auto mua ALL egg",
    Default = false,
    Callback = function(v)
        getgenv().GG.Shop.AutoBuyAllEgg = v
        print("[Shop-Egg] AutoBuyAll =", v)
    end
})

ShopTab:AddSection({Name = "Traveling Shop"})
ShopTab:AddTextbox({
    Name = "Chọn vật phẩm (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.Shop.TravelingSelected = tostring(txt or "")
        print("[Shop-Traveling] Selected =", getgenv().GG.Shop.TravelingSelected)
    end
})
ShopTab:AddToggle({
    Name = "Auto mua vật phẩm đã chọn",
    Default = false,
    Callback = function(v)
        getgenv().GG.Shop.AutoBuyTravelingSelected = v
        print("[Shop-Traveling] AutoBuySelected =", v)
    end
})

ShopTab:AddSection({Name = "Event Shop (Beanstalk)"})
ShopTab:AddToggle({
    Name = "Auto hiện shop Beanstalk",
    Default = false,
    Callback = function(v)
        getgenv().GG.Shop.EventOpenBeanShop = v
        print("[Shop-Event] AutoOpenBeanShop =", v)
    end
})
ShopTab:AddTextbox({
    Name = "Chọn vật phẩm (search)",
    Default = "",
    TextDisappear = false,
    Callback = function(txt)
        getgenv().GG.Shop.EventSelected = tostring(txt or "")
        print("[Shop-Event] Selected =", getgenv().GG.Shop.EventSelected)
    end
})
ShopTab:AddToggle({
    Name = "Auto mua vật phẩm đã chọn",
    Default = false,
    Callback = function(v)
        getgenv().GG.Shop.AutoBuyEventSelected = v
        print("[Shop-Event] AutoBuySelected =", v)
    end
})
ShopTab:AddToggle({
    Name = "Auto mua ALL vật phẩm",
    Default = false,
    Callback = function(v)
        getgenv().GG.Shop.AutoBuyEventAll = v
        print("[Shop-Event] AutoBuyAll =", v)
    end
})

-- Show UI
OrionLib:Init()

-- Thông báo nhỏ
OrionLib:MakeNotification({
    Name = "Grow a Garden Hub",
    Content = "Loaded! Tabs: Settings / Home / Pet / Shop",
    Image = "rbxassetid://4483345998",
    Time = 3
})
