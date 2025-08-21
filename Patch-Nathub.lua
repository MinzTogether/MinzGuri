-- NatHub Premium Bypass Loader
repeat wait() until game:IsLoaded() and game:FindFirstChild("CoreGui") and pcall(function() return game.CoreGui end)

-- Ép buộc premium
premium = true
is_premium = true
script_key = "bypass"

-- Các hàm chính
local _function = {
    ["getid"] = function()
        local g = game.GameId
        -- Luôn trả về ID premium
        if g == 7436755782 then return "483d639ad74a7814ff1057d68cec56c2" -- Grow a Garden
        elseif g == 7018190066 then return "d3a76114c1ea182127b88170b6043d11" -- Dead Rails
        elseif g == 5750914919 then return "bfd8ac56165c2caf1eebc5a14ccdb134" -- Fisch
        elseif g == 6325068386 then return "a0ad31cf58a8bd98dd82fa1fb648290f" -- Blue Lock Rivals
        elseif g == 4777817887 then return "d53370331c9ca16ce3479c3ac6ae5a78" -- Blade Ball
        elseif g == 994732206 then return "446a745866c1abf8459657502b7818fc" -- Blox Fruit
        elseif g == 4658598196 then return "27394fa4dc9c7268a839f2c98b6a35f7" -- Attack On Titan Revolution
        elseif g == 6331902150 then return "0771107275ffabca9221c264306214f9" -- Forsaken
        elseif g == 7709344486 then return "4039bc61ee76ab6f5247b15a0ebf5f60" -- Steal a Brainrot
        elseif g == 7326934954 then return "936bc2bb715727ee86ba41e64a851f3d" end -- 99 Night In The Forest
    end,

    ["gamename"] = function()
        local g = game.GameId
        if g == 5750914919 then return "Fisch"
        elseif g == 7018190066 then return "Dead Rails"
        elseif g == 6325068386 then return "Blue Lock Rivals"
        elseif g == 4777817887 then return "Blade Ball"
        elseif g == 7436755782 then return "Grow a Garden"
        elseif g == 994732206 then return "Blox Fruit"
        elseif g == 4658598196 then return "Attack On Titan Revolution"
        elseif g == 6331902150 then return "Forsaken"
        elseif g == 7709344486 then return "Steal a Brainrot"
        elseif g == 7326934954 then return "99 Night in The Forest" end
    end,

    ["load"] = function(url)
        local game_url = game:HttpGet(url)
        return (load or loadstring)(game_url)()
    end
}

-- Chạy script chính
local script_id, game_name = _function.getid(), _function.gamename()
if script_id then
    game.StarterGui:SetCore("SendNotification", {
        Title = "NatHub Premium",
        Text = game_name .. " Premium Script Loaded!",
        Icon = "rbxassetid://99764942615873",
        Duration = 5
    })
    _function.load("https://api.luarmor.net/files/v4/loaders/" .. script_id .. ".lua")
end
