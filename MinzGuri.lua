-- MinzyGuri Hub - Rayfield UI (Delta-friendly)
-- Full UI theo yêu cầu + core: Speed/Jump/Noclip/Fly + Auto Collect (lọc)
-- by MinzyGuri

-- ========== LIB ==========
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local function Notify(t, c, d)
    Rayfield:Notify({ Title = t or "MinzyGuri", Content = c or "", Duration = d or 2 })
end

-- ========== STATE / UTILS ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local function Humanoid()
    local ch = LocalPlayer.Character
    if not ch then return nil end
    return ch:FindFirstChildOfClass("Humanoid")
end

local function HRP()
    local ch = LocalPlayer.Character
    if not ch then return nil end
    return ch:FindFirstChild("HumanoidRootPart")
end

local function safeTP(cf)
    local p = HRP()
    if p and cf then p.CFrame = cf end
end

-- Clamp helper
local function clamp(n, a, b)
    if n < a then return a end
    if n > b then return b end
    return n
end

-- ========== GLOBAL CONFIG ==========
getgenv().MG = {
    Fly = false,
    FlySpeed = 50,
    InfJump = false,
    Noclip = false,
    WalkSpeed = 16,

    PlantMode = "Random", -- "Random" | "At Player"
    AutoPlant = false,

    AutoCollect = false,
    CollectFilter = {
        FruitSearch = "",
        MutationSearch = "",
    },

    -- Event
    Beanstalk = {
        AutoHarvestRequired = false,
        AutoSubmitAll = false,
        AutoCollectEventItems = false,
    },
    Cooking = {
        AutoCook = false,
        AutoTakeFood = false,
        Slots = {"","","","",""}, -- 5 slots
    },

    -- Mutation
    MutationActivateMachine = false, -- via Button
    MutationSubmitHeldPet = false,   -- via Button

    -- Craft
    Craft = {
        GearSelected = "",
        SeedSelected = "",
        AutoCraftGear = false,
        AutoCraftSeed = false
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

-- WalkSpeed keeper (đề phòng bị game reset)
RunService.Heartbeat:Connect(function()
    local h = Humanoid()
    if h then
        if typeof(getgenv().MG.WalkSpeed) == "number" then
            h.WalkSpeed = clamp(getgenv().MG.WalkSpeed, 16, 1000)
        end
    end
end)

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if getgenv().MG.InfJump then
        local h = Humanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if getgenv().MG.Noclip then
        local ch = LocalPlayer.Character
        if ch then
            for _,v in ipairs(ch:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

-- Fly (phím F toggle + toggle trong UI)
local flyKey = Enum.KeyCode.F
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == flyKey then
        getgenv().MG.Fly = not getgenv().MG.Fly
        Notify("MinzyGuri", "Fly: "..tostring(getgenv().MG.Fly), 1.5)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if getgenv().MG.Fly then
        local root = HRP()
        if root then
            local cam = workspace.CurrentCamera
            local move = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            if move.Magnitude > 0 then
                root.CFrame = root.CFrame + move.Unit * (getgenv().MG.FlySpeed or 50) * dt
            end
        end
    end
end)

-- Auto Collect (demo: tìm Part tên chứa từ khóa trái/mutation → chạm/TP ngắn)
task.spawn(function()
    while true do
        task.wait(0.5)
        if not getgenv().MG.AutoCollect then continue end
        local root = HRP()
        if not root then continue end

        -- tiêu chí lọc
        local nameKey = (getgenv().MG.CollectFilter.FruitSearch or ""):lower()
        local mutKey  = (getgenv().MG.CollectFilter.MutationSearch or ""):lower()

        -- tìm item gần nhất
        local nearest, ndist
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name:lower()
                local okFruit = (nameKey == "" or n:find(nameKey, 1, true))
                local okMut   = (mutKey == ""  or n:find(mutKey, 1, true))
                -- Heuristic: cố gắng nhặt các phần có tên gợi ý item/fruit/seed/coin
                local looksLikePickup = (n:find("fruit") or n:find("seed") or n:find("coin") or n:find("drop") or n:find("item"))
                if okFruit and okMut and looksLikePickup then
                    local d = (root.Position - obj.Position).Magnitude
                    if not ndist or d < ndist then
                        nearest, ndist = obj, d
                    end
                end
            end
        end

        if nearest and ndist and ndist < 1000 then
            -- TP ngắn + touch thử
            local targetCF = nearest.CFrame
            safeTP(targetCF + Vector3.new(0, 2, 0))
            task.wait(0.05)
            pcall(function()
                firetouchinterest(root, nearest, 0)
                firetouchinterest(root, nearest, 1)
            end)
        end
    end
end)

-- ========== UI WINDOW ==========
local Window = Rayfield:CreateWindow({
    Name = "MinzyGuri Hub",
    LoadingTitle = "MinzyGuri Hub",
    LoadingSubtitle = "Grow a Garden",
    ConfigurationSaving = { Enabled = true, FolderName = "MinzyGuriHub", FileName = "MinzyGuri" },
    KeySystem = false
})

-- ===================== TAB HOME =====================
local Home = Window:CreateTab("🏡 Home", 4483362458)

-- Khung Plant
Home:CreateSection("Chế độ trồng")
local PlantMode = Home:CreateDropdown({
    Name = "Chọn chế độ",
    Options = {"Random","Ở vị trí người chơi"},
    CurrentOption = "Random",
    Flag = "PlantMode",
    Callback = function(val)
        getgenv().MG.PlantMode = val
    end
})

Home:CreateToggle({
    Name = "Tự động trồng (demo placeholder)",
    CurrentValue = false,
    Flag = "AutoPlant",
    Callback = function(v)
        getgenv().MG.AutoPlant = v
        if v then
            Notify("Auto Plant", "Đang bật (đang để khung – cần nối Remote game).", 2)
        end
    end
})

-- Khung Auto Collect
Home:CreateSection("Tự động nhặt")
Home:CreateToggle({
    Name = "Auto Collect (có lọc)",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(v)
        getgenv().MG.AutoCollect = v
        Notify("Auto Collect", v and "ON" or "OFF", 1.5)
    end
})

local fruitSearch = Home:CreateInput({
    Name = "Tìm theo tên trái (search)",
    PlaceholderText = "vd: apple, coin, seed...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.CollectFilter.FruitSearch = tostring(txt or "")
    end
})

local mutSearch = Home:CreateInput({
    Name = "Tìm theo mutation (search)",
    PlaceholderText = "vd: golden, rare...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.CollectFilter.MutationSearch = tostring(txt or "")
    end
})

-- Khung Event: Beanstalk
Home:CreateSection("Event: Beanstalk")
Home:CreateToggle({
    Name = "Auto thu hoạch trái theo yêu cầu NPC",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Beanstalk.AutoHarvestRequired = v
        Notify("Beanstalk", "Auto Harvest: "..tostring(v))
    end
})
Home:CreateToggle({
    Name = "Auto nộp ALL trái cho NPC",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Beanstalk.AutoSubmitAll = v
        Notify("Beanstalk", "Auto Submit: "..tostring(v))
    end
})
Home:CreateToggle({
    Name = "Auto nhặt vật phẩm sự kiện",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Beanstalk.AutoCollectEventItems = v
        Notify("Beanstalk", "Auto Collect Event: "..tostring(v))
    end
})

-- Khung Event: Cooking
Home:CreateSection("Event: Cooking")
local cookInputs = {}
for i=1,5 do
    cookInputs[i] = Home:CreateInput({
        Name = ("Chọn trái thứ %d (search)"):format(i),
        PlaceholderText = "gõ tên... (vd: apple)",
        RemoveTextAfterFocusLost = false,
        Callback = function(txt)
            getgenv().MG.Cooking.Slots[i] = tostring(txt or "")
        end
    })
end
Home:CreateToggle({
    Name = "Auto Cook",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Cooking.AutoCook = v
        Notify("Cooking", "Auto Cook: "..tostring(v))
    end
})
Home:CreateToggle({
    Name = "Auto lấy food",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Cooking.AutoTakeFood = v
        Notify("Cooking", "Auto Take: "..tostring(v))
    end
})

-- Khung Mutation
Home:CreateSection("Mutation")
Home:CreateButton({
    Name = "Kích hoạt máy mutation (no pet)",
    Callback = function()
        -- TODO: Nối Remote kích hoạt máy mutation
        Notify("Mutation", "Kích hoạt máy (placeholder) – cần Remote chính xác.", 2)
    end
})
Home:CreateButton({
    Name = "Nộp pet đang cầm",
    Callback = function()
        -- TODO: Nối Remote nộp pet trên tay
        Notify("Mutation", "Nộp pet (placeholder) – cần Remote chính xác.", 2)
    end
})

-- Khung Craft
Home:CreateSection("Craft")
local gearSelect = Home:CreateInput({
    Name = "Chọn Gear (search)",
    PlaceholderText = "gõ tên gear...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.Craft.GearSelected = tostring(txt or "")
    end
})
local seedSelect = Home:CreateInput({
    Name = "Chọn Seed (search)",
    PlaceholderText = "gõ tên seed...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.Craft.SeedSelected = tostring(txt or "")
    end
})
Home:CreateToggle({
    Name = "Auto craft gear đã chọn",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Craft.AutoCraftGear = v
        Notify("Craft", "Auto Craft Gear: "..tostring(v))
    end
})
Home:CreateToggle({
    Name = "Auto craft seed đã chọn",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Craft.AutoCraftSeed = v
        Notify("Craft", "Auto Craft Seed: "..tostring(v))
    end
})

-- ===================== TAB PET =====================
local Pet = Window:CreateTab("🐾 Pet", 4483362458)

Pet:CreateSection("Auto Egg")
local eggSelect = Pet:CreateInput({
    Name = "Chọn Egg (search)",
    PlaceholderText = "gõ tên egg...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.Pet.EggSelected = tostring(txt or "")
    end
})
Pet:CreateToggle({
    Name = "Auto đặt egg đã chọn",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Pet.AutoPlaceEgg = v
        Notify("Pet", "Auto Place Egg: "..tostring(v))
    end
})
Pet:CreateToggle({
    Name = "Auto nở egg đã chọn",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Pet.AutoHatch = v
        Notify("Pet", "Auto Hatch: "..tostring(v))
    end
})

Pet:CreateSection("Pet Boosts")
local petDeployed = Pet:CreateInput({
    Name = "Chọn pet đã thả ở vườn (search)",
    PlaceholderText = "gõ tên/ID pet...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.Pet.BoostPetSelected = tostring(txt or "")
    end
})
local boostItem = Pet:CreateInput({
    Name = "Chọn vật phẩm boost (search)",
    PlaceholderText = "gõ tên item...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.Pet.BoostItemSelected = tostring(txt or "")
    end
})
Pet:CreateToggle({
    Name = "Auto dùng boost đã chọn",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Pet.AutoApplyBoost = v
        Notify("Pet", "Auto Boost: "..tostring(v))
    end
})
Pet:CreateButton({
    Name = "Làm mới danh sách pet (placeholder)",
    Callback = function()
        Notify("Pet", "Refresh (placeholder) – cần đọc data pet trong Workspace/ReplicatedStorage.", 2)
    end
})

-- ===================== TAB SHOP =====================
local Shop = Window:CreateTab("🛒 Shop", 4483362458)

-- Seed
Shop:CreateSection("Seed Shop")
local seedShopSelect = Shop:CreateInput({
    Name = "Chọn seed (search)",
    PlaceholderText = "gõ tên seed...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.Shop.SeedSelected = tostring(txt or "")
    end
})
Shop:CreateToggle({
    Name = "Auto mua seed đã chọn",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Shop.AutoBuySeedSelected = v
        Notify("Shop", "Auto Buy Seed Selected: "..tostring(v))
    end
})
Shop:CreateToggle({
    Name = "Auto mua ALL seed",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Shop.AutoBuyAllSeed = v
        Notify("Shop", "Auto Buy All Seed: "..tostring(v))
    end
})

-- Gear
Shop:CreateSection("Gear Shop")
local gearShopSelect = Shop:CreateInput({
    Name = "Chọn gear (search)",
    PlaceholderText = "gõ tên gear...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.Shop.GearSelected = tostring(txt or "")
    end
})
Shop:CreateToggle({
    Name = "Auto mua gear đã chọn",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Shop.AutoBuyGearSelected = v
        Notify("Shop", "Auto Buy Gear Selected: "..tostring(v))
    end
})
Shop:CreateToggle({
    Name = "Auto mua ALL gear",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Shop.AutoBuyAllGear = v
        Notify("Shop", "Auto Buy All Gear: "..tostring(v))
    end
})

-- Egg Shop
Shop:CreateSection("Egg Shop")
local eggShopSelect = Shop:CreateInput({
    Name = "Chọn egg (search)",
    PlaceholderText = "gõ tên egg...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.Shop.EggSelected = tostring(txt or "")
    end
})
Shop:CreateToggle({
    Name = "Auto mua egg đã chọn",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Shop.AutoBuyEggSelected = v
        Notify("Shop", "Auto Buy Egg Selected: "..tostring(v))
    end
})
Shop:CreateToggle({
    Name = "Auto mua ALL egg",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Shop.AutoBuyAllEgg = v
        Notify("Shop", "Auto Buy All Egg: "..tostring(v))
    end
})

-- Traveling Shop
Shop:CreateSection("Traveling Shop")
local travelingSelect = Shop:CreateInput({
    Name = "Chọn vật phẩm (search)",
    PlaceholderText = "gõ tên item...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.Shop.TravelingSelected = tostring(txt or "")
    end
})
Shop:CreateToggle({
    Name = "Auto mua vật phẩm đã chọn",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Shop.AutoBuyTravelingSelected = v
        Notify("Shop", "Auto Buy Traveling Item: "..tostring(v))
    end
})

-- Event Shop
Shop:CreateSection("Event Shop (Beanstalk)")
Shop:CreateToggle({
    Name = "Auto mở shop Beanstalk",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Shop.EventOpenBeanShop = v
        Notify("Shop", "Auto open Beanstalk Shop: "..tostring(v))
    end
})
local eventItemSelect = Shop:CreateInput({
    Name = "Chọn vật phẩm (search)",
    PlaceholderText = "gõ tên item...",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        getgenv().MG.Shop.EventSelected = tostring(txt or "")
    end
})
Shop:CreateToggle({
    Name = "Auto mua vật phẩm đã chọn",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Shop.AutoBuyEventSelected = v
        Notify("Shop", "Auto Buy Event Selected: "..tostring(v))
    end
})
Shop:CreateToggle({
    Name = "Auto mua ALL vật phẩm",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Shop.AutoBuyEventAll = v
        Notify("Shop", "Auto Buy Event All: "..tostring(v))
    end
})

-- ===================== TAB SETTINGS =====================
local Settings = Window:CreateTab("⚙️ Settings", 4483362458)

Settings:CreateSection("Di chuyển")
Settings:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 1000},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Callback = function(v)
        getgenv().MG.WalkSpeed = v
    end
})

Settings:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.InfJump = v
        Notify("Settings", "Infinite Jump: "..tostring(v), 1.2)
    end
})

Settings:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Noclip = v
        Notify("Settings", "Noclip: "..tostring(v), 1.2)
    end
})

Settings:CreateSection("Fly")
Settings:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 500},
    Increment = 5,
    Suffix = "",
    CurrentValue = 50,
    Callback = function(v)
        getgenv().MG.FlySpeed = v
    end
})
Settings:CreateToggle({
    Name = "Fly (ấn phím F để bật/tắt nhanh)",
    CurrentValue = false,
    Callback = function(v)
        getgenv().MG.Fly = v
        Notify("Settings", "Fly: "..tostring(v), 1.2)
    end
})

-- Done
Notify("MinzyGuri Hub", "Loaded! Tabs: Home / Pet / Shop / Settings", 3)
