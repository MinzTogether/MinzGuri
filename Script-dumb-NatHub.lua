-- NatHub Auto Dump All Scripts
repeat wait() until game:IsLoaded()

-- Ghi đè loadstring để bắt script thật
local old_loadstring = loadstring or load
loadstring = function(src)
    local gameid = tostring(game.GameId)
    local filename = "NatHub_Dump_"..gameid..".lua"

    print("==== [NATHUB SCRIPT THẬT - "..gameid.."] ====")
    print(src:sub(1,500).." ...") -- chỉ in 500 ký tự đầu cho gọn
    if writefile then
        writefile(filename, src)
        print("[+] Script đã lưu: "..filename)
    end
    return old_loadstring(src)
end

-- Danh sách GameID + ScriptID (copy từ NatHub Premium)
local game_list = {
    [7436755782] = "483d639ad74a7814ff1057d68cec56c2", -- Grow a Garden
    [7018190066] = "d3a76114c1ea182127b88170b6043d11", -- Dead Rails
    [5750914919] = "bfd8ac56165c2caf1eebc5a14ccdb134", -- Fisch
    [6325068386] = "a0ad31cf58a8bd98dd82fa1fb648290f", -- Blue Lock Rivals
    [4777817887] = "d53370331c9ca16ce3479c3ac6ae5a78", -- Blade Ball
    [994732206]  = "446a745866c1abf8459657502b7818fc", -- Blox Fruit
    [4658598196] = "27394fa4dc9c7268a839f2c98b6a35f7", -- Attack On Titan Revolution
    [6331902150] = "0771107275ffabca9221c264306214f9", -- Forsaken
    [7709344486] = "4039bc61ee76ab6f5247b15a0ebf5f60", -- Steal a Brainrot
    [7326934954] = "936bc2bb715727ee86ba41e64a851f3d", -- 99 Night In The Forest
}

-- Script Key (chỉ cần nhập 1 lần)
script_key = "KEY"

-- Auto dump tất cả script NatHub
for gid, sid in pairs(game_list) do
    print("[*] Dumping game ID: "..gid.." (script: "..sid..")")
    local url = "https://api.luarmor.net/files/v4/loaders/"..sid..".lua"
    local ok, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)
    if not ok then
        warn("[!] Lỗi dump game "..gid..": "..err)
    end
    wait(2)
end

print("=== [AUTO DUMP HOÀN TẤT] ===")
