-- Onyx-Hub | Homework Map Diagnosis
-- Standalone diagnostic. Does not move the character or activate prompts.
-- Run in Delta; report is copied automatically when clipboard API is available.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local function getRoot()
    local char = player and player.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function posOf(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Model") then
        local ok, cf = pcall(function() return inst:GetPivot() end)
        if ok then return cf.Position end
    end
    local part = inst:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function pathOf(inst)
    local names = {}
    local node = inst
    for _ = 1, 7 do
        if not node then break end
        table.insert(names, 1, node.Name)
        node = node.Parent
    end
    return table.concat(names, "/")
end

local function v3(v)
    if not v then return "n/a" end
    return string.format("%.1f, %.1f, %.1f", v.X, v.Y, v.Z)
end

local function round(n)
    return math.floor(n * 10 + 0.5) / 10
end

local root = getRoot()
local origin = root and root.Position or Vector3.zero
local lines = {}
local function add(s) table.insert(lines, tostring(s)) end

add("ONYX-HUB HOMEWORK DIAGNOSIS")
add("Version: 1.0 | Read-only scan; no movement/prompt activation")
add("Character position: " .. v3(origin))
add("PlaceId: " .. tostring(game.PlaceId))
add("JobId: " .. tostring(game.JobId))
add("")

local kosan = Workspace:FindFirstChild("KosanSpawned")
local ownedHouses = {}
if kosan then
    for _, house in ipairs(kosan:GetChildren()) do
        local owner = house:FindFirstChild("OwnerUserId", true)
        if owner and tostring(owner.Value) == tostring(player.UserId) then
            table.insert(ownedHouses, house)
        end
    end
end

add("=== OWN HOUSE ===")
add("KosanSpawned found: " .. tostring(kosan ~= nil))
add("Owned houses found: " .. #ownedHouses)
local ownParts = {}
local ownPrompts = {}
for _, house in ipairs(ownedHouses) do
    add("HOUSE: " .. pathOf(house) .. " | class=" .. house.ClassName .. " | pivot=" .. v3(posOf(house)))
    for _, d in ipairs(house:GetDescendants()) do
        if d:IsA("BasePart") then
            table.insert(ownParts, d)
        elseif d:IsA("ProximityPrompt") then
            table.insert(ownPrompts, d)
        end
    end
end

add("")
add("=== HOME PROMPTS (DIRT / TRASH) ===")
add("Prompt count in owned house: " .. #ownPrompts)
for i, p in ipairs(ownPrompts) do
    if i > 100 then add("... prompt list capped at 100"); break end
    local pp = posOf(p.Parent)
    add(string.format(
        "%02d | %s | action=%s | object=%s | enabled=%s | pos=%s | dist=%s",
        i, pathOf(p), tostring(p.ActionText), tostring(p.ObjectText),
        tostring(p.Enabled), v3(pp),
        pp and tostring(round((pp - origin).Magnitude)) or "n/a"
    ))
end

add("")
add("=== HOUSE COLLIDABLE PARTS / GEOMETRY ===")
add("BaseParts in owned house: " .. #ownParts)
local selectedParts = {}
for _, part in ipairs(ownParts) do
    if part.CanCollide and part.Transparency < 1 then
        table.insert(selectedParts, part)
    end
end
table.sort(selectedParts, function(a, b)
    local pa, pb = posOf(a), posOf(b)
    return ((pa - origin).Magnitude) < ((pb - origin).Magnitude)
end)
add("Visible collidable parts: " .. #selectedParts)
for i, part in ipairs(selectedParts) do
    if i > 140 then add("... geometry list capped at 140"); break end
    add(string.format(
        "%03d | %s | pos=%s | size=%s | anchored=%s | material=%s",
        i, pathOf(part), v3(part.Position), v3(part.Size),
        tostring(part.Anchored), tostring(part.Material)
    ))
end

add("")
add("=== TRASH BAGS AND DISPOSAL PROMPTS ===")
local bags, bins = {}, {}
for _, d in ipairs(Workspace:GetDescendants()) do
    if d.Name == "TrashBag" then
        local p = posOf(d)
        if p and (p - origin).Magnitude <= 250 then
            table.insert(bags, d)
        end
    elseif d:IsA("ProximityPrompt") and d.Name == "BuangPrompt" then
        local p = posOf(d.Parent)
        if p and (p - origin).Magnitude <= 350 then
            table.insert(bins, d)
        end
    end
end
add("TrashBag within 250 studs: " .. #bags)
for i, bag in ipairs(bags) do
    if i > 60 then add("... bag list capped at 60"); break end
    local p = posOf(bag)
    local prompt = bag:FindFirstChild("AmbilPrompt", true)
    add(string.format("%02d | %s | pos=%s | dist=%s | AmbilPrompt=%s",
        i, pathOf(bag), v3(p), tostring(round((p-origin).Magnitude)),
        tostring(prompt ~= nil)))
end
add("BuangPrompt within 350 studs: " .. #bins)
for i, prompt in ipairs(bins) do
    if i > 60 then add("... bin list capped at 60"); break end
    local p = posOf(prompt.Parent)
    add(string.format("%02d | %s | action=%s | enabled=%s | pos=%s | dist=%s",
        i, pathOf(prompt), tostring(prompt.ActionText), tostring(prompt.Enabled),
        v3(p), tostring(round((p-origin).Magnitude))))
end

add("")
add("=== NEARBY NAMED STRUCTURE / ENTRY CANDIDATES ===")
local keywords = {"door", "pintu", "gate", "gerbang", "wall", "tembok", "fence", "pagar", "road", "jalan", "spawn", "zona"}
local found = {}
for _, d in ipairs(Workspace:GetDescendants()) do
    if d:IsA("BasePart") or d:IsA("Model") then
        local n = string.lower(d.Name)
        local match = false
        for _, key in ipairs(keywords) do
            if string.find(n, key, 1, true) then match = true break end
        end
        if match then
            local p = posOf(d)
            if p and (p-origin).Magnitude <= 300 then
                table.insert(found, {inst=d, pos=p, dist=(p-origin).Magnitude})
            end
        end
    end
end
table.sort(found, function(a,b) return a.dist < b.dist end)
add("Named candidates within 300 studs: " .. #found)
for i, item in ipairs(found) do
    if i > 100 then add("... candidate list capped at 100"); break end
    local d = item.inst
    local extra = ""
    if d:IsA("BasePart") then
        extra = " | size=" .. v3(d.Size) .. " | collide=" .. tostring(d.CanCollide)
    end
    add(string.format("%03d | %s | class=%s | pos=%s | dist=%s%s",
        i, pathOf(d), d.ClassName, v3(item.pos), tostring(round(item.dist)), extra))
end

add("")
add("=== SCAN SUMMARY ===")
add("Owned houses: " .. #ownedHouses)
add("House prompts: " .. #ownPrompts)
add("House BaseParts: " .. #ownParts)
add("Nearby TrashBags: " .. #bags)
add("Nearby disposal prompts: " .. #bins)
add("If any section says 0 unexpectedly, send this complete report anyway.")
add("END OF DIAGNOSIS")

local report = table.concat(lines, "\n")
local copied = false
if typeof(setclipboard) == "function" then
    copied = pcall(setclipboard, report)
elseif typeof(toclipboard) == "function" then
    copied = pcall(toclipboard, report)
end

local gui = Instance.new("ScreenGui")
gui.Name = "HomeworkDiagnosisGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(340, 190)
frame.Position = UDim2.new(0.5, -170, 0.5, -95)
frame.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 32)
title.Position = UDim2.fromOffset(10, 6)
title.BackgroundTransparency = 1
title.Text = "HOMEWORK DIAGNOSIS"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 54)
status.Position = UDim2.fromOffset(12, 43)
status.BackgroundTransparency = 1
status.TextWrapped = true
status.Text = copied and "Diagnosis berhasil disalin ke clipboard. Tinggal paste ke chat." or "Clipboard tidak tersedia. Tekan tombol Salin; jika tetap gagal, kirim screenshot laporan."
status.TextColor3 = Color3.fromRGB(210,220,235)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.Parent = frame

local function makeButton(text, x, width)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(width, 38)
    b.Position = UDim2.fromOffset(x, 112)
    b.BackgroundColor3 = Color3.fromRGB(55, 105, 180)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

local copyButton = makeButton("SALIN ULANG", 12, 190)
copyButton.MouseButton1Click:Connect(function()
    local ok = false
    if typeof(setclipboard) == "function" then ok = pcall(setclipboard, report)
    elseif typeof(toclipboard) == "function" then ok = pcall(toclipboard, report) end
    status.Text = ok and "Berhasil disalin. Paste hasilnya ke chat ini." or "Clipboard API tidak didukung executor ini."
end)

local closeButton = makeButton("TUTUP", 210, 118)
closeButton.BackgroundColor3 = Color3.fromRGB(85, 90, 100)
closeButton.MouseButton1Click:Connect(function() gui:Destroy() end)

local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print("Homework diagnosis generated. Clipboard copied: " .. tostring(copied))
