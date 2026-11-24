-- ONYX HUB - CORE LOADER
-- Loader diagnostics are intentionally silent; no status UI is shown.
local function diagnosticStatus(message, failed) end
local diagnosticGui = nil

local function bootOnyxHub()
diagnosticStatus("MENGAMBIL CORE...", false)

local url = "https://raw.githubusercontent.com/rael-kertia/Onyx-Hub/main/main_obfuscated.lua?v=onyx-single-gui-stopall-fix9-20261125"
local response = game:HttpGet(url)
assert(type(response) == "string" and #response > 1000, "Gagal mengambil core ONYX HUB")

local encoded = response:match("local encoded = %[%[(.-)%]%]")
assert(encoded, "Data core tidak ditemukan")
encoded = encoded:gsub("%s", "")

local decoded = {}
for i = 1, #encoded, 2 do
    local byte = tonumber(encoded:sub(i, i + 1), 16)
    assert(byte, "Data core rusak")
    decoded[#decoded + 1] = string.char((byte - 97) % 256)
end
local wrapper = table.concat(decoded)
diagnosticStatus("CORE TERUNDUH - MENYIAPKAN PATCH...", false)

-- Patch dilakukan setelah seluruh patch asli CORE RESTORE,
-- tepat sebelum core asli di-compile dan dijalankan.
local marker = "local compiled, compileError = loadstring(source)"
local at = wrapper:find(marker, 1, true)
assert(at, "Titik patch core ONYX tidak ditemukan")

local patch = [==[


-- LAYOUT PATCH - MATCH DENGAN CORE RESTORE
-- Semua marker di bawah dicocokkan dengan guiCode yang dibentuk main_obfuscated.lua.

local function onyxReplaceLineStrict(text, prefix, newLine, label)
    local a = text:find(prefix, 1, true)
    assert(a, "LAYOUT PATCH GAGAL: baris tidak ditemukan: " .. label)
    local e = text:find("\n", a, true) or (#text + 1)
    assert(not text:find(prefix, e + 1, true),
        "LAYOUT PATCH GAGAL: baris duplikat: " .. label)
    return text:sub(1, a - 1) .. newLine .. text:sub(e)
end

source = onyxReplaceLineStrict(
    source,
    'title.Text = "RAEL\'S TRICKS"',
    'title.Text = "ONYX HUB"',
    "TITLE TEXT"
)
source = onyxReplaceLineStrict(
    source,
    'title.Size = UDim2.new(1, -48, 0, 21)',
    'title.Size = UDim2.new(1, -105, 0, 21)',
    "TITLE WIDTH"
)
source = onyxReplaceLineStrict(
    source,
    'minimizeButton.Text = "\020"',
    'minimizeButton.Text = "-"',
    "MINIMIZE GLYPH"
)
source = onyxReplaceLineStrict(
    source,
    'miniButton.Text = "RT"',
    'miniButton.Text = "ONYX"',
    "MINI BRAND"
)
source = onyxReplaceLineStrict(
    source,
    'miniButton.Parent = gui',
    'miniButton.Parent = gui',
    "KEEP LEGACY MINI IN MAIN GUI"
)
source = onyxReplaceLineStrict(
    source,
    'miniButton.Text = "ONYX"',
    'miniButton.Text = "ONYX"',
    "KEEP ONYX MINI LABEL"
)
source = onyxReplaceLineStrict(
    source,
    'connect(minimizeButton.Activated, function() frame.Visible = false miniButton.Visible = true end)',
    [[miniButton.Size = UDim2.fromOffset(58, 58)
miniButton.Text = "ONYX"
miniButton.TextSize = 10
miniButton.Font = Enum.Font.GothamBlack
miniButton.BackgroundColor3 = Color3.fromRGB(13, 148, 136)
miniButton.Visible = false
connect(minimizeButton.Activated, function()
    frame.Visible = false
    miniButton.Visible = true
end)
connect(miniButton.Activated, function()
    miniButton.Visible = false
    frame.Visible = true
end)]],
    "MINIMIZE TO ONYX BUBBLE"
)

-- Core GUI memakai frame langsung; tidak ada objek Header terpisah.
assert(source:find("connect(miniButton.Activated, function()", 1, true),
    "REOPEN EVENT TIDAK DITEMUKAN")

-- AUTO JAM AJAIB: ditambahkan ke source core, bukan loader terpisah.
source = source .. [====[

-- ==========================================
-- AUTO JAM AJAIB - RAEL'S TRICKS
-- Loop scan | sekali per rumah per sesi
-- >20 menit | <=220 stud | posisi pemain tetap
-- ==========================================

local jamAutoEnabled = false
local jamBusy = false
local jamProcessed = setmetatable({}, {__mode = "k"})
local jamService

local jamButton = Instance.new("TextButton")
jamButton.Name = "AutoJamAjaibButton"
jamButton.Size = UDim2.fromOffset(180, 29)
jamButton.Position = UDim2.fromOffset(12, 300)
jamButton.ZIndex = 10
jamButton.Active = true
jamButton.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
jamButton.BorderSizePixel = 0
jamButton.Text = "AUTO JAM AJAIB: OFF"
jamButton.TextColor3 = Color3.new(1, 1, 1)
jamButton.TextSize = 10
jamButton.Font = Enum.Font.GothamBold
jamButton.Parent = frame
Instance.new("UICorner", jamButton).CornerRadius = UDim.new(0, 6)

local function paintJamButton()
    jamButton.Text = jamAutoEnabled and "AUTO JAM AJAIB: ON" or "AUTO JAM AJAIB: OFF"
    jamButton.BackgroundColor3 = jamAutoEnabled
        and Color3.fromRGB(5, 150, 105)
        or Color3.fromRGB(127, 29, 29)
end

local function getJamTool()
    local char = player.Character
    local bag = player:FindFirstChildOfClass("Backpack")
    for _, container in ipairs({char, bag}) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                if obj:IsA("Tool") and obj:GetAttribute("JamAjaib") then
                    return obj
                end
            end
        end
    end
end

local function jamRentedCount(house)
    local count = 0
    if house:GetAttribute("KosanState") == "Disewa" then
        count += 1
    end
    for _, child in ipairs(house:GetChildren()) do
        if child:IsA("Model")
        and child:GetAttribute("KosanState") == "Disewa" then
            count += 1
        end
    end
    return count
end

local function jamRemaining(house)
    local endsAt = house:GetAttribute("RentEndsAt")
    if typeof(endsAt) ~= "number" then return -1 end
    return endsAt - time()
end

local function jamDistance(house)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return math.huge end
    local ok, cf = pcall(function()
        return house:GetBoundingBox()
    end)
    if not ok then return math.huge end
    return (root.Position - cf.Position).Magnitude
end

local function getJamService()
    if jamService then return jamService end
    local rs = game:GetService("ReplicatedStorage")
    local nk = rs:WaitForChild("NKSystem", 15)
    if not nk then error("NKSystem tidak ditemukan") end
    local packages = nk:WaitForChild("Packages", 15)
    if not packages then error("Packages tidak ditemukan") end
    local knitFolder = packages:WaitForChild("Knit", 15)
    if not knitFolder then error("Knit tidak ditemukan") end
    local knitModule = knitFolder:WaitForChild("KnitClient", 15)
    if not knitModule then error("KnitClient tidak ditemukan") end
    local Knit = require(knitModule)
    jamService = Knit.GetService("JamAjaibService")
    if not jamService then error("JamAjaibService tidak ditemukan") end
    return jamService
end

local function jamFire(house)
    local completed, response, failure = false, nil, nil
    local ok, promise = pcall(function()
        return getJamService():Tembak(house)
    end)
    if not ok or not promise then
        return false, "PEMANGGILAN SERVICE GAGAL: " .. tostring(promise)
    end

    local chainOK, chainError = pcall(function()
        promise:andThen(function(result)
            response = result
            completed = true
        end):catch(function(reason)
            failure = reason
            completed = true
        end)
    end)
    if not chainOK then
        return false, "PEMANTAUAN PROMISE GAGAL: " .. tostring(chainError)
    end

    local deadline = os.clock() + 12
    repeat
        task.wait(0.1)
    until completed or os.clock() >= deadline

    if not completed then return false, "RESPONS SERVER TIMEOUT" end
    if failure then return false, tostring(failure) end
    if not response or response.ok ~= true then
        return false, "DITOLAK SERVER"
    end
    return true, response
end

local function jamWorker()
    if jamBusy then return end
    jamBusy = true

    while alive() and jamAutoEnabled do
        local folder = W:FindFirstChild("KosanSpawned")
        local tool = getJamTool()

        if not folder then
            setStatus("JAM AJAIB: KOSANSPAWNED TIDAK DITEMUKAN")
            task.wait(4)
            continue
        end

        if not tool then
            setStatus("JAM AJAIB: TOOL TIDAK DITEMUKAN")
            task.wait(4)
            continue
        end

        if tool.Parent ~= player.Character then
            setStatus("JAM AJAIB: EQUIP TOOL TERLEBIH DAHULU")
            task.wait(3)
            continue
        end

        local stock = tool:GetAttribute("Count")
        if typeof(stock) ~= "number" or stock <= 0 then
            setStatus("JAM AJAIB: STOK HABIS / TIDAK TERBACA")
            jamAutoEnabled = false
            paintJamButton()
            break
        end

        local targets = {}
        for _, house in ipairs(folder:GetChildren()) do
            if house:IsA("Model")
            and not jamProcessed[house]
            and house:GetAttribute("OwnerUserId") == player.UserId
            and jamRentedCount(house) > 0
            and jamRemaining(house) > 1200 then
                targets[#targets + 1] = house
            end
        end

        table.sort(targets, function(a, b)
            return jamRemaining(a) > jamRemaining(b)
        end)

        local firedThisPass = 0

        for _, house in ipairs(targets) do
            if not alive() or not jamAutoEnabled then break end

            tool = getJamTool()
            if not tool or tool.Parent ~= player.Character then
                setStatus("JAM AJAIB: TOOL TIDAK DIPEGANG")
                break
            end

            stock = tool:GetAttribute("Count")
            if typeof(stock) ~= "number" or stock <= 0 then
                setStatus("JAM AJAIB: STOK HABIS")
                jamAutoEnabled = false
                paintJamButton()
                break
            end

            -- Validasi ulang tepat sebelum setiap tembakan.
            if house.Parent ~= folder
            or house:GetAttribute("OwnerUserId") ~= player.UserId
            or jamRentedCount(house) <= 0 then
                setStatus("JAM AJAIB: TARGET BERUBAH - DILEWATI")
                continue
            end

            local seconds = jamRemaining(house)
            if seconds <= 1200 then
                setStatus("JAM AJAIB: SISA WAKTU <= 20 MENIT")
                continue
            end

            local distance = jamDistance(house)
            if distance > 220 then
                setStatus("JAM AJAIB: " .. house.Name .. " TERLALU JAUH")
                continue
            end

            setStatus(string.format(
                "JAM AJAIB: TEMBAK %s | %.1f MENIT",
                house.Name, seconds / 60
            ))

            local shotOK, result = jamFire(house)
            if not shotOK then
                setStatus("JAM AJAIB BERHENTI: " .. tostring(result))
                jamAutoEnabled = false
                paintJamButton()
                break
            end

            jamProcessed[house] = true
            firedThisPass += 1
            task.wait(0.15)

            local afterTool = getJamTool()
            local afterStock = afterTool and afterTool:GetAttribute("Count")
            setStatus(string.format(
                "JAM AJAIB: BERHASIL %s | STOK %s -> %s",
                house.Name, tostring(stock), tostring(afterStock)
            ))

            task.wait(2.7)
        end

        if jamAutoEnabled and alive() then
            if firedThisPass == 0 then
                setStatus("JAM AJAIB: SCAN ULANG | TUNGGU TARGET")
            else
                setStatus("JAM AJAIB: PASS SELESAI | " .. firedThisPass .. " RUMAH")
            end
            task.wait(5)
        end
    end

    jamBusy = false
    if alive() and not jamAutoEnabled then
        setStatus("AUTO JAM AJAIB NONAKTIF")
    end
end

connect(jamButton.Activated, function()
    if not alive() then return end
    jamAutoEnabled = not jamAutoEnabled
    paintJamButton()

    if jamAutoEnabled then
        setStatus("AUTO JAM AJAIB DIMULAI")
        task.spawn(jamWorker)
    else
        setStatus("AUTO JAM AJAIB DIMATIKAN")
    end
end)

paintJamButton()

]====]

-- No second exit button: keep the single core header close control.


source = source .. [====[
-- Status remains internal only; remove the visible status panel.
if statusPanel and statusPanel.Parent then statusPanel:Destroy() end
local function setStatus(msg) end
local exitButton
do
    -- Core saat ini memakai frame langsung, bukan objek Header terpisah.
    local header = frame
    minimizeButton.Position = UDim2.new(1, -94, 0, 2)
    exitButton = Instance.new("TextButton")
    exitButton.Name = "OnyxExitButton"
    -- X memakai ukuran dan posisi tombol minimize asli.
    exitButton.Size = minimizeButton.Size
    exitButton.Position = UDim2.new(1, -29, 0, 1)
    exitButton.BackgroundColor3 = Color3.fromRGB(145, 45, 55)
    exitButton.BorderSizePixel = 0
    exitButton.Text = "X"
    exitButton.TextColor3 = Color3.new(1, 1, 1)
    exitButton.TextSize = 13
    exitButton.Font = Enum.Font.GothamBlack
    exitButton.Parent = header
    Instance.new("UICorner", exitButton).CornerRadius = UDim.new(0, 7)
    connect(exitButton.Activated, function()
        -- STOP ALL: matikan seluruh worker Farm/Feed/Convert sebelum GUI ditutup.
        local env = getgenv()
        -- STOP ALL: hentikan seluruh worker dari CORE dan Farm/Feed/Convert.
        env.ONYX_STOP_ALL = true
        env.RaelV18Running = false
        env.RFC_Running = false

        for _, key in ipairs({"RaelV18Connections", "RFC_Connections"}) do
            local connections = env[key]
            if connections then
                for _, connection in ipairs(connections) do
                    pcall(function() connection:Disconnect() end)
                end
                table.clear(connections)
            end
        end

        for _, key in ipairs({"RaelV18Objects", "RFC_Objects"}) do
            local objects = env[key]
            if objects then
                for _, object in ipairs(objects) do
                    pcall(function() object:Destroy() end)
                end
                table.clear(objects)
            end
        end

        -- Hapus TP LOCATION secara eksplisit dari Backpack maupun Character.
        local Players = game:GetService("Players")
        local localPlayer = Players.LocalPlayer
        local backpack = localPlayer:FindFirstChildOfClass("Backpack")
        local character = localPlayer.Character
        for _, container in ipairs({backpack, character}) do
            if container then
                for _, object in ipairs(container:GetDescendants()) do
                    if object:IsA("Tool") and object.Name == "TP LOCATION" then
                        pcall(function() object:Destroy() end)
                    end
                end
                local directTool = container:FindFirstChild("TP LOCATION")
                if directTool then pcall(function() directTool:Destroy() end) end
            end
        end

        local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            for _, guiName in ipairs({"RaelsTricksV18", "RaelFarmFeedConvert"}) do
                local oldGui = playerGui:FindFirstChild(guiName)
                if oldGui then pcall(function() oldGui:Destroy() end) end
            end
        end
        if gui and gui.Parent then gui:Destroy() end
    end)

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(390, 800)
    local panelHeight = math.min(420, math.max(260, viewport.Y - 110))

    -- Fit the existing feature controls inside a mobile-safe scrolling viewport.
    frame.Size = UDim2.fromOffset(318, panelHeight)
    frame.Position = UDim2.new(1, -330, 0, math.max(12, math.min(95, viewport.Y - panelHeight - 12)))

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Name = "FeatureScroll"
    contentScroll.Position = UDim2.fromOffset(58, 47)
    contentScroll.Size = UDim2.new(1, -64, 1, -53)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 3
    contentScroll.ScrollBarImageColor3 = Color3.fromRGB(76, 190, 170)
    contentScroll.CanvasPosition = Vector2.new(0, 0)
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    contentScroll.ZIndex = 2
    contentScroll.Parent = frame

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingBottom = UDim.new(0, 12)
    contentPadding.Parent = contentScroll

    -- Preserve every legacy control's exact authored position and size.
    local maxBottom = 0
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("GuiObject")
        and child ~= header
        and child ~= contentScroll
        and child.Name ~= "ExitButton" then
            local y = child.Position.Y.Offset
            if y >= 45 then
                local h = child.AbsoluteSize.Y
                maxBottom = math.max(maxBottom, y - 45 + h + 12)
                child.Position = UDim2.new(
                    child.Position.X.Scale,
                    child.Position.X.Offset,
                    child.Position.Y.Scale,
                    y - 45
                )
                child.Parent = contentScroll
            end
        end
    end
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, maxBottom)


    -- ONYX DASHBOARD REDESIGN: new visual hierarchy, hero card, feature cards.
    frame.BackgroundColor3 = Color3.fromRGB(9, 14, 25)
    frame.BorderSizePixel = 0
    local oldStroke = frame:FindFirstChildOfClass("UIStroke")
    if oldStroke then
        oldStroke.Color = Color3.fromRGB(42, 65, 88)
        oldStroke.Thickness = 1.4
    end
    local frameGradient = frame:FindFirstChildOfClass("UIGradient")
    if not frameGradient then
        frameGradient = Instance.new("UIGradient")
        frameGradient.Rotation = 90
        frameGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 29, 47)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 13, 23))
        })
        frameGradient.Parent = frame
    end
    header.BackgroundColor3 = Color3.fromRGB(13, 23, 37)
    header.BackgroundTransparency = 0
    title.Text = "ONYX  /  CONTROL CENTER"
    title.TextColor3 = Color3.fromRGB(232, 242, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 13

    local hero = Instance.new("Frame")
    hero.Name = "OnyxDashboardHero"
    hero.Size = UDim2.new(1, -24, 0, 72)
    hero.Position = UDim2.fromOffset(12, 8)
    hero.BackgroundColor3 = Color3.fromRGB(17, 43, 54)
    hero.BorderSizePixel = 0
    hero.ZIndex = 4
    hero.Parent = contentScroll
    Instance.new("UICorner", hero).CornerRadius = UDim.new(0, 10)
    local heroGradient = Instance.new("UIGradient")
    heroGradient.Rotation = 0
    heroGradient.Color = ColorSequence.new(Color3.fromRGB(20, 68, 72), Color3.fromRGB(19, 35, 58))
    heroGradient.Parent = hero

    local heroAccent = Instance.new("Frame")
    heroAccent.Size = UDim2.fromOffset(3, 44)
    heroAccent.Position = UDim2.fromOffset(12, 14)
    heroAccent.BackgroundColor3 = Color3.fromRGB(73, 230, 192)
    heroAccent.BorderSizePixel = 0
    heroAccent.ZIndex = 5
    heroAccent.Parent = hero
    Instance.new("UICorner", heroAccent).CornerRadius = UDim.new(1, 0)

    local heroTitle = Instance.new("TextLabel")
    heroTitle.Size = UDim2.new(1, -36, 0, 25)
    heroTitle.Position = UDim2.fromOffset(23, 12)
    heroTitle.BackgroundTransparency = 1
    heroTitle.Text = "WELCOME TO ONYX"
    heroTitle.TextColor3 = Color3.fromRGB(240, 250, 255)
    heroTitle.TextSize = 14
    heroTitle.Font = Enum.Font.GothamBlack
    heroTitle.TextXAlignment = Enum.TextXAlignment.Left
    heroTitle.ZIndex = 5
    heroTitle.Parent = hero

    local heroSub = Instance.new("TextLabel")
    heroSub.Size = UDim2.new(1, -36, 0, 20)
    heroSub.Position = UDim2.fromOffset(23, 38)
    heroSub.BackgroundTransparency = 1
    heroSub.Text = "AUTOMATION  •  FARM  •  CONTROL"
    heroSub.TextColor3 = Color3.fromRGB(142, 190, 199)
    heroSub.TextSize = 9
    heroSub.Font = Enum.Font.GothamBold
    heroSub.TextXAlignment = Enum.TextXAlignment.Left
    heroSub.ZIndex = 5
    heroSub.Parent = hero

    local section = Instance.new("TextLabel")
    section.Name = "FeatureSectionLabel"
    section.Size = UDim2.new(1, -24, 0, 20)
    section.Position = UDim2.fromOffset(12, 88)
    section.BackgroundTransparency = 1
    section.Text = "FEATURE CONTROL"
    section.TextColor3 = Color3.fromRGB(107, 220, 196)
    section.TextSize = 9
    section.Font = Enum.Font.GothamBlack
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.ZIndex = 4
    section.Parent = contentScroll

    local redesignedBottom = 108
    for _, control in ipairs(contentScroll:GetChildren()) do
        if control:IsA("GuiObject") and control ~= hero and control ~= section then
            control.Position = UDim2.new(
                control.Position.X.Scale, control.Position.X.Offset,
                control.Position.Y.Scale, control.Position.Y.Offset + 108
            )
            if control:IsA("TextButton") then
                control.Size = UDim2.new(1, -24, 0, math.max(32, control.Size.Y.Offset))
                control.Position = UDim2.new(0, 12, 0, control.Position.Y.Offset)
                control.BackgroundColor3 = Color3.fromRGB(22, 36, 54)
                control.TextColor3 = Color3.fromRGB(225, 239, 250)
                control.Font = Enum.Font.GothamBold
                control.TextSize = 11
                control.ZIndex = 5
                local corner = control:FindFirstChildOfClass("UICorner")
                if not corner then
                    corner = Instance.new("UICorner")
                    corner.Parent = control
                end
                corner.CornerRadius = UDim.new(0, 8)
                local stroke = control:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(44, 70, 91)
                stroke.Thickness = 1
                stroke.Parent = control
            end
            redesignedBottom = math.max(redesignedBottom, control.Position.Y.Offset + control.AbsoluteSize.Y + 10)
        end
    end
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, redesignedBottom + 12)

    -- Icon rail stays available while the expandable control panel is hidden.
    local rail = Instance.new("Frame")
    rail.Name = "OnyxIconRail"
    rail.Size = UDim2.new(0, 48, 1, -55)
    rail.Position = UDim2.fromOffset(6, 47)
    rail.BackgroundColor3 = Color3.fromRGB(10, 15, 26)
    rail.BorderSizePixel = 0
    rail.ZIndex = 40
    rail.Parent = frame
    Instance.new("UICorner", rail).CornerRadius = UDim.new(0, 12)

    local railStroke = Instance.new("UIStroke")
    railStroke.Color = Color3.fromRGB(43, 57, 78)
    railStroke.Thickness = 1
    railStroke.Parent = rail

    local brand = Instance.new("TextLabel")
    brand.Name = "BrandMark"
    brand.Size = UDim2.new(1, 0, 0, 42)
    brand.Position = UDim2.fromOffset(0, 8)
    brand.BackgroundTransparency = 1
    brand.Text = "O"
    brand.TextColor3 = Color3.fromRGB(75, 220, 190)
    brand.TextSize = 22
    brand.Font = Enum.Font.GothamBlack
    brand.ZIndex = 41
    brand.Parent = rail

    local railLine = Instance.new("Frame")
    railLine.Size = UDim2.new(1, -18, 0, 1)
    railLine.Position = UDim2.fromOffset(9, 53)
    railLine.BackgroundColor3 = Color3.fromRGB(43, 57, 78)
    railLine.BorderSizePixel = 0
    railLine.ZIndex = 41
    railLine.Parent = rail

    local menuButton = Instance.new("TextButton")
    menuButton.Name = "ExpandMenu"
    menuButton.Size = UDim2.fromOffset(34, 38)
    menuButton.Position = UDim2.fromOffset(6, 65)
    menuButton.BackgroundColor3 = Color3.fromRGB(22, 42, 55)
    menuButton.BorderSizePixel = 0
    menuButton.Text = "≡"
    menuButton.TextColor3 = Color3.fromRGB(105, 235, 205)
    menuButton.TextSize = 22
    menuButton.Font = Enum.Font.GothamBold
    menuButton.ZIndex = 41
    menuButton.Parent = rail
    Instance.new("UICorner", menuButton).CornerRadius = UDim.new(0, 8)

    local railCaption = Instance.new("TextLabel")
    railCaption.Size = UDim2.new(1, -4, 0, 24)
    railCaption.Position = UDim2.new(0, 2, 1, -31)
    railCaption.BackgroundTransparency = 1
    railCaption.Text = "MENU"
    railCaption.TextColor3 = Color3.fromRGB(145, 160, 180)
    railCaption.TextSize = 8
    railCaption.Font = Enum.Font.GothamBold
    railCaption.ZIndex = 41
    railCaption.Parent = rail

    connect(menuButton.Activated, function()
        if not alive() then return end
        contentScroll.Visible = not contentScroll.Visible
        menuButton.Text = contentScroll.Visible and "≡" or "›"
    end)

    -- Hanya satu tombol X, ditempatkan di header utama.
    exitButton.ZIndex = 25
    exitButton.Visible = true

    -- Satu frame memuat sidebar + konten. Drag memindahkan seluruh jendela.
    local UserInputService = game:GetService("UserInputService")
    local dragging, dragStart, startPosition = false, nil, nil
    local function beginWindowDrag(input)
        if input.UserInputType ~= Enum.UserInputType.Touch
        and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging = true
        dragStart = input.Position
        startPosition = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
    local function updateWindowDrag(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.Touch
        and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
    header.Active = true
    rail.Active = true
    header.InputBegan:Connect(beginWindowDrag)
    rail.InputBegan:Connect(beginWindowDrag)
    UserInputService.InputChanged:Connect(updateWindowDrag)
    UserInputService.TouchMoved:Connect(updateWindowDrag)
end
]====]

]==]

wrapper = wrapper:sub(1, at - 1) .. patch .. "\n" .. wrapper:sub(at)

diagnosticStatus("MENG-COMPILE WRAPPER...", false)
local chunk, compileError = loadstring(wrapper)
assert(chunk, "Wrapper compile gagal: " .. tostring(compileError))
diagnosticStatus("MENJALANKAN CORE...", false)
chunk()

-- Load the existing Farm/Feed/Convert engine without rewriting its working logic.
diagnosticStatus("MENGINTEGRASIKAN FARM / FEED / CONVERT...", false)
local farmOK, farmError = pcall(function()
    local farmUrl = "https://raw.githubusercontent.com/rael-kertia/Onyx-Hub/main/farm_feed_convert.lua?v=onyx-single-gui-stopall-fix9-20261125"
    local farmSource = game:HttpGet(farmUrl)
    assert(type(farmSource) == "string" and #farmSource > 20000, "FARM CORE KOSONG / GAGAL DIUNDUH")
    farmSource = farmSource:gsub("RAEL // FARM SYSTEM", "ONYX // FARM SYSTEM")

    -- Bangun kontrol Farm langsung di FeatureScroll ONYX.
    -- Tidak membuat ScreenGui, panel, minimize, atau tombol X kedua.
    local uiStart = "-- NEW GUI: three feature toggles only";
    local uiEnd = "-- DROPPING SCANNER";
    local first = farmSource:find(uiStart, 1, true)
    local last = farmSource:find(uiEnd, first or 1, true)
    assert(first and last and last > first, "FARM UI PATCH: BLOK UI TIDAK DITEMUKAN")
    local integratedUI = [=[
-- ONYX EMBEDDED FARM UI
local gui = playerGui:WaitForChild("RaelsTricksV18")
local panel = gui:FindFirstChild("FeatureScroll", true)
assert(panel and panel:IsA("ScrollingFrame"), "ONYX FEATURESCROLL TIDAK DITEMUKAN")

local function setStatus(message) end

-- Letakkan Farm di bagian atas agar AUTO FARM langsung terlihat,
-- bukan terselip jauh di bawah daftar fitur.
local fixedTop = 116
for _, child in ipairs(panel:GetChildren()) do
    if child:IsA("GuiObject")
    and child.Name ~= "OnyxDashboardHero"
    and child.Name ~= "FeatureSectionLabel"
    and child.Name ~= "FarmSectionHeader"
    and child.Name ~= "AutoFarm"
    and child.Name ~= "AutoFeed"
    and child.Name ~= "AutoConvert"
    and child.Position.Y.Offset >= fixedTop then
        child.Position = UDim2.new(
            child.Position.X.Scale, child.Position.X.Offset,
            child.Position.Y.Scale, child.Position.Y.Offset + 160
        )
    end
end

local function makeToggle(name, label, y, color)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(1, -24, 0, 36)
    b.Position = UDim2.fromOffset(12, y)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = label .. "  [OFF]"
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 12
    b.Visible = true
    b.Active = true
    b.AutoButtonColor = true
    b.Parent = panel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(47, 88, 105)
    stroke.Thickness = 1
    stroke.Parent = b
    return b
end

local sectionY = 116
local section = Instance.new("TextLabel")
section.Name = "FarmSectionHeader"
section.Size = UDim2.new(1, -24, 0, 20)
section.Position = UDim2.fromOffset(12, sectionY)
section.BackgroundTransparency = 1
section.Text = "FARM AUTOMATION"
section.TextColor3 = Color3.fromRGB(104, 220, 195)
section.Font = Enum.Font.GothamBlack
section.TextSize = 10
section.TextXAlignment = Enum.TextXAlignment.Left
section.ZIndex = 12
section.Visible = true
section.Parent = panel

local farmButton = makeToggle("AutoFarm", "AUTO FARM", sectionY + 24, Color3.fromRGB(34, 94, 75))
local feedButton = makeToggle("AutoFeed", "AUTO FEED", sectionY + 66, Color3.fromRGB(44, 83, 128))
local convertButton = makeToggle("AutoConvert", "AUTO CONVERT", sectionY + 108, Color3.fromRGB(113, 77, 39))

-- Hitung ulang canvas secara eksplisit; jangan bergantung pada AutomaticCanvasSize.
panel.AutomaticCanvasSize = Enum.AutomaticSize.None
panel.ScrollingEnabled = true
panel.ScrollBarThickness = 4
local contentBottom = 0
for _, child in ipairs(panel:GetChildren()) do
    if child:IsA("GuiObject") and child.Visible then
        contentBottom = math.max(contentBottom,
            child.Position.Y.Offset + child.AbsoluteSize.Y + 14)
    end
end
panel.CanvasSize = UDim2.new(0, 0, 0, contentBottom)

local function paint(button, label, enabled, onColor, offColor)
    button.Text = label .. (enabled and "  [ON]" or "  [OFF]")
    button.BackgroundColor3 = enabled and onColor or offColor
end
local function updateUI()
    paint(farmButton, "AUTO FARM", autoFarm, Color3.fromRGB(32,145,94), Color3.fromRGB(34,94,75))
    paint(feedButton, "AUTO FEED", autoFeed, Color3.fromRGB(43,126,190), Color3.fromRGB(44,83,128))
    paint(convertButton, "AUTO CONVERT", autoConvert, Color3.fromRGB(184,123,48), Color3.fromRGB(113,77,39))
end
]=]
    farmSource = farmSource:sub(1, first - 1) .. integratedUI .. "\n" .. farmSource:sub(last)
    -- gui now points to ONYX itself, so workers end with ONYX and no second GUI exists.
    local farmChunk, farmCompileError = loadstring(farmSource)
    assert(type(farmChunk) == "function", "FARM COMPILE GAGAL: " .. tostring(farmCompileError))
    farmChunk()

    local Players = game:GetService("Players")
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local mainGui = playerGui:FindFirstChild("RaelsTricksV18")
    assert(mainGui, "GUI UTAMA ONYX TIDAK DITEMUKAN")
    local scroll = mainGui:FindFirstChild("FeatureScroll", true)
    assert(scroll and scroll:IsA("ScrollingFrame"), "AREA SCROLL ONYX TIDAK DITEMUKAN")
    for _, controlName in ipairs({"AutoFarm", "AutoFeed", "AutoConvert"}) do
        local control = scroll:FindFirstChild(controlName)
        assert(control and control:IsA("TextButton"), "KONTROL FARM TIDAK TERTANAM: " .. controlName)
    end
    assert(not playerGui:FindFirstChild("RaelFarmFeedConvert"), "GUI FARM TERPISAH MASIH ADA")

    local mainFrame = mainGui:FindFirstChildWhichIsA("Frame")
    assert(mainFrame, "PANEL UTAMA ONYX TIDAK DITEMUKAN")
    local rail = mainGui:FindFirstChild("OnyxIconRail")
    if rail then
        local function makeShortcut(name, glyph, y)
            local button = Instance.new("TextButton")
            button.Name = name
            button.Size = UDim2.fromOffset(34, 38)
            button.Position = UDim2.fromOffset(6, y)
            button.BackgroundColor3 = Color3.fromRGB(22, 42, 55)
            button.BorderSizePixel = 0
            button.Text = glyph
            button.TextColor3 = Color3.fromRGB(105, 235, 205)
            button.TextSize = 17
            button.Font = Enum.Font.GothamBold
            button.ZIndex = 41
            button.Parent = rail
            Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
            return button
        end

        local homeShortcut = makeShortcut("HomeShortcut", "⌂", 145)
        local farmShortcut = makeShortcut("FarmShortcut", "♧", 191)
        homeShortcut.Activated:Connect(function()
            mainFrame.Visible = true
            scroll.CanvasPosition = Vector2.new(0, 0)
        end)
        farmShortcut.Activated:Connect(function()
            mainFrame.Visible = true
            local farmHeader = scroll:FindFirstChild("FarmSectionHeader")
            if farmHeader then
                scroll.CanvasPosition = Vector2.new(0, farmHeader.Position.Y.Offset)
            end
        end)
    end
end)

if not farmOK then
    diagnosticStatus("FARM INTEGRASI GAGAL: " .. tostring(farmError):sub(1, 140), true)
else
    diagnosticStatus("ONYX + FARM TERINTEGRASI", false)
end
end

local bootOK, bootError = pcall(bootOnyxHub)
if bootOK then
    diagnosticStatus("CORE BERHASIL DIEKSEKUSI", false)
    task.delay(2, function()
        if diagnosticGui and diagnosticGui.Parent then
            diagnosticGui:Destroy()
        end
    end)
else
    diagnosticStatus("GAGAL: " .. tostring(bootError):sub(1, 180), true)
end
