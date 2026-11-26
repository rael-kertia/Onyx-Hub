-- ONYX HUB - CORE LOADER
-- Loader diagnostics are intentionally silent; no status UI is shown.
local function diagnosticStatus(message, failed)
    if not failed then return end
    local report = "ONYX BOOT ERROR: " .. tostring(message)
    pcall(function()
        if typeof(setclipboard) == "function" then setclipboard(report) end
    end)
    pcall(function() warn(report) end)

    -- Error wajib terlihat di layar; Delta console tidak dapat diandalkan.
    pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
        if not playerGui then return end

        local old = playerGui:FindFirstChild("OnyxBootDiagnostic")
        if old then old:Destroy() end

        local screen = Instance.new("ScreenGui")
        screen.Name = "OnyxBootDiagnostic"
        screen.ResetOnSpawn = false
        screen.DisplayOrder = 100000
        screen.Parent = playerGui

        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(1, -24, 0, 118)
        panel.Position = UDim2.new(0, 12, 0, 80)
        panel.BackgroundColor3 = Color3.fromRGB(45, 17, 22)
        panel.BorderSizePixel = 0
        panel.Parent = screen
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, -20)
        label.Position = UDim2.fromOffset(10, 10)
        label.BackgroundTransparency = 1
        label.Text = report .. "\\nTekan SALIN ERROR untuk menyalin."
        label.TextColor3 = Color3.fromRGB(255, 225, 225)
        label.TextWrapped = true
        label.TextSize = 12
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Parent = panel

        local copy = Instance.new("TextButton")
        copy.Size = UDim2.fromOffset(108, 26)
        copy.Position = UDim2.new(1, -118, 1, -32)
        copy.BackgroundColor3 = Color3.fromRGB(135, 45, 55)
        copy.Text = "SALIN ERROR"
        copy.TextColor3 = Color3.new(1, 1, 1)
        copy.TextSize = 10
        copy.Font = Enum.Font.GothamBold
        copy.Parent = panel
        copy.Activated:Connect(function()
            pcall(function()
                if typeof(setclipboard) == "function" then setclipboard(report) end
            end)
            label.Text = report .. "\\nSudah dicoba disalin."
        end)
    end)
end
local diagnosticGui = nil

local function bootOnyxHub()
diagnosticStatus("MENGAMBIL CORE...", false)

local url = "https://raw.githubusercontent.com/rael-kertia/Onyx-Hub/main/main_obfuscated.lua?v=onyx-core-refresh-20261126k"
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
    'local oldGui = playerGui:FindFirstChild("RaelsTricksV1")',
    'local oldGui = playerGui:FindFirstChild("RaelsTricksV18")',
    "GUI CLEANUP NAME"
)
source = onyxReplaceLineStrict(
    source,
    'gui.Name = "RaelsTricksV1"',
    'gui.Name = "RaelsTricksV18"',
    "GUI ROOT NAME"
)
source = onyxReplaceLineStrict(
    source,
    'title.Size = UDim2.new(1, -48, 0, 21)',
    'title.Size = UDim2.new(1, -105, 0, 21)',
    "TITLE WIDTH"
)
source = onyxReplaceLineStrict(
    source,
    "minimizeButton.Text =",
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

-- ONYX PORT: RAEL PAID GACHA
-- Metode service, Promise await, validasi hasil, klaim X10, dan timing
-- disalin dari implementasi Rael's Tricks yang sudah dipulihkan.
local function onyxReplaceBetween(text, firstMarker, nextMarker, replacement)
    local a = text:find(firstMarker, 1, true)

    -- Farm UI sudah sengaja dihapus dari core. Patch lama yang masih
    -- mencoba menghapus marker ini harus dilewati, bukan menggagalkan boot.
    if not a and firstMarker == "local farmButton = makeButton(" then
        return text
    end

    assert(a, "ONYX GACHA PATCH: marker awal tidak ditemukan: " .. firstMarker)
    local b = text:find(nextMarker, a + #firstMarker, true)
    assert(b, "ONYX GACHA PATCH: marker akhir tidak ditemukan: " .. nextMarker)
    return text:sub(1, a - 1) .. replacement .. "\n\n" .. text:sub(b)
end

local onyxGachaNative = [=[
local gachaService
local function getGachaService()
    if gachaService then return gachaService end
    local rs = game:GetService("ReplicatedStorage")
    local nk = rs:WaitForChild("NKSystem", 15)
    if not nk then error("NKSystem tidak ditemukan") end
    local packages = nk:WaitForChild("Packages", 15)
    if not packages then error("Packages tidak ditemukan") end
    local knitModule = packages:WaitForChild("Knit", 15)
    if not knitModule then error("Knit tidak ditemukan") end
    local Knit = require(knitModule)
    gachaService = Knit.GetService("GachaService")
    if not gachaService then error("GachaService tidak ditemukan") end
    return gachaService
end

-- Semua pemanggilan menunggu Promise selesai. Tidak ada retry otomatis.
local function gachaCall(methodName, ...)
    local args = table.pack(...)
    local ok, requestOK, result = pcall(function()
        local svc = getGachaService()
        local method = svc[methodName]
        if type(method) ~= "function" then
            error("METHOD TIDAK DITEMUKAN: " .. methodName)
        end
        local promise = method(svc, table.unpack(args, 1, args.n))
        if not promise or type(promise.await) ~= "function" then
            error("RESPONS PROMISE TIDAK VALID: " .. methodName)
        end
        return promise:await()
    end)

    if not ok then return false, tostring(requestOK) end
    if requestOK ~= true then
        return false, result or ("SERVER MENOLAK: " .. methodName)
    end
    return true, result
end

-- X10 = satu spin server, lalu klaim tiap indeks secara berurutan.
-- Jika satu klaim gagal, hentikan; jangan ulangi indeks yang sama.
local function gachaClaimMulti(results)
    if type(results) ~= "table" then
        setStatus("GACHA: HASIL X10 TIDAK VALID")
        return false
    end

    local count = #results
    if count ~= 10 then
        setStatus("GACHA: JUMLAH HASIL TIDAK 10 (" .. count .. ")")
        return false
    end

    for i = 1, count do
        if results[i] == nil then
            setStatus("GACHA: HASIL KE-" .. i .. " KOSONG")
            return false
        end

        setStatus("GACHA: KLAIM HADIAH " .. i .. "/10")
        local claimOK, claimResult = gachaCall("ClaimOneMultiReward", i)
        if not claimOK then
            setStatus("GACHA: KLAIM GAGAL " .. i .. "/10 - " .. tostring(claimResult))
            return false
        end

        -- Jeda presentasi tanpa animasi: mengikuti fase buka X10 di BlindBoxTampil.
        -- Durasi reveal terukur: 0.75 + 0.55 + 0.50 + 0.45 + 1.60 + 0.30 = 4.15 detik.
        -- Ini hanya pacing lokal; bukan perlindungan atau jaminan anti-detection.
        if i < count then
            task.wait(4.15)
        end
    end

    setStatus("GACHA: 10 KLAIM SELESAI")
    return true
end

local function gachaCycle()
    setStatus("GACHA: MEMBACA STATE")
    local stateOK, state = gachaCall("GetState")
    if not stateOK or type(state) ~= "table" then
        setStatus("GACHA: GAGAL MEMBACA STATE")
        return false
    end

    local free = tonumber(state.free) or 0
    if free >= 10 then
        setStatus("GACHA: FREE X10")
        local spinOK, result = gachaCall("SpinX10WithFree")
        if not spinOK or type(result) ~= "table" or result.ok ~= true then
            setStatus("GACHA: FREE X10 GAGAL")
            return false
        end
        return gachaClaimMulti(result.results)

    elseif free > 0 then
        setStatus("GACHA: FREE SPIN 1X")
        local spinOK, result = gachaCall("Spin")
        if not spinOK or type(result) ~= "table" or result.ok ~= true then
            setStatus("GACHA: FREE SPIN GAGAL")
            return false
        end

        local claimOK, claimResult = gachaCall("ClaimReward")
        if not claimOK then
            setStatus("GACHA: KLAIM FREE SPIN GAGAL - " .. tostring(claimResult))
            return false
        end
        setStatus("GACHA: FREE SPIN SELESAI")
        return true

    elseif gachaPaidEnabled then
        setStatus("GACHA: PAID X10")
        local spinOK, result = gachaCall("SpinX10WithMoney")
        if not spinOK or type(result) ~= "table" or result.ok ~= true then
            setStatus("GACHA: PAID X10 GAGAL")
            return false
        end
        return gachaClaimMulti(result.results)

    else
        setStatus("GACHA: MENUNGGU FREE SPIN (PAID OFF)")
        return nil
    end
end]=]

source = onyxReplaceBetween(
    source,
    "local function getGachaService()",
    "local function gachaWorker()",
    onyxGachaNative
)

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
            if (
                house.Parent ~= folder
                or house:GetAttribute("OwnerUserId") ~= player.UserId
                or jamRentedCount(house) <= 0
            ) then
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

    -- CLEAN button berada di Y=22 pada core lama, sehingga tertinggal
    -- di belakang header. Pindahkan ke area scroll agar tetap terlihat.
    if cleanButton then
        cleanButton.Parent = contentScroll
        cleanButton.Position = UDim2.fromOffset(12, 55)
        cleanButton.Visible = true
    end
    -- Farm memang tidak dipakai lagi; sembunyikan tombol legacy-nya.
    if farmButton then
        farmButton.Visible = false
    end

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
    heroSub.Text = "HOMEWORK  •  CLEAN  •  CONTROL"
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



-- AUTO CLEAN: cek deklarasi tanpa mengunci helper pembuat tombol.
assert(source:find("local cleanButton", 1, true),
    "AUTO CLEAN GUI BUTTON TIDAK DITEMUKAN DI CORE")


-- HOMEWORK: RESOLVE PROMPT PART, INCLUDING ATTACHMENT PARENTS.
source = onyxReplaceBetween(
    source,
    "local function hwPart(prompt)",
    "local function hwForceStand()",
    [=[
local function hwPart(prompt)
    local parent = prompt and prompt.Parent
    if not parent then return nil end

    if parent:IsA("BasePart") then
        return parent
    end

    if parent:IsA("Attachment") then
        return parent:FindFirstAncestorWhichIsA("BasePart")
    end

    return parent:FindFirstAncestorWhichIsA("BasePart")
        or parent:FindFirstChildWhichIsA("BasePart", true)
end
]=]
)

-- HOMEWORK STAND FIX: jangan nolkan velocity saat karakter sedang berjalan.
source = onyxReplaceBetween(
    source,
    "local function hwForceStand()",
    "local function hwMove(prompt)",
    [=[
local function hwForceStand()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid then return end

    local seated = humanoid.Sit
        or humanoid:GetState() == Enum.HumanoidStateType.Seated

    -- Dipanggil periodik oleh Homework. Saat tidak duduk, jangan
    -- mengubah velocity karena itu akan melawan Humanoid:MoveTo().
    if not seated then return end

    humanoid.Sit = false
    humanoid.Jump = false
    pcall(function()
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)
    task.wait(0.12)

    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    pcall(function()
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end)
end
]=]
)

-- HOMEWORK MOVEMENT: GROUND-VALIDATED PATHFINDING + REPATH.
source = onyxReplaceBetween(
    source,
    "local function hwMove(prompt)",
    "local function hwUse(prompt)",
    [=[
local function hwMove(prompt)
    if not alive() or not homeworkEnabled then return false end

    local PathfindingService = game:GetService("PathfindingService")
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = hwRoot()
    local targetPart = hwPart(prompt)

    if not prompt or not prompt.Parent or not targetPart
    or not humanoid or humanoid.Health <= 0 or not root then
        setStatus("HOMEWORK: TARGET PROMPT TIDAK VALID")
        return false
    end

    -- Lepas dari kursi, lalu tunggu karakter benar-benar menyentuh lantai.
    hwForceStand()
    local groundedDeadline = os.clock() + 3
    repeat
        if not alive() or not homeworkEnabled then return false end
        character = player.Character
        humanoid = character and character:FindFirstChildOfClass("Humanoid")
        root = hwRoot()
        if not humanoid or not root or humanoid.Health <= 0 then return false end
        if humanoid.FloorMaterial ~= Enum.Material.Air then break end
        task.wait(0.1)
    until os.clock() >= groundedDeadline

    if humanoid.FloorMaterial == Enum.Material.Air then
        setStatus("PATHFINDING: KARAKTER BELUM MENYENTUH LANTAI")
        return false
    end

    local promptParent = prompt.Parent
    local promptPosition = (
        promptParent and promptParent:IsA("Attachment")
    ) and promptParent.WorldPosition or targetPart.Position

    -- Jangan exclude targetPart: permukaan target bisa menjadi lantai navigasi.
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {character}
    rayParams.IgnoreWater = true
    rayParams.RespectCanCollide = true

    local offsets = {
        Vector3.new(0, 0, 0),
        Vector3.new(2.5, 0, 0), Vector3.new(-2.5, 0, 0),
        Vector3.new(0, 0, 2.5), Vector3.new(0, 0, -2.5),
        Vector3.new(4, 0, 4), Vector3.new(-4, 0, 4),
        Vector3.new(4, 0, -4), Vector3.new(-4, 0, -4)
    }

    local function findBestPath()
        local currentRoot = hwRoot()
        if not currentRoot then return nil end

        local bestPath, bestGoal, bestScore
        for _, offset in ipairs(offsets) do
            if not alive() or not homeworkEnabled then return nil end

            local rayOrigin = promptPosition + offset + Vector3.new(0, 12, 0)
            local hit = workspace:Raycast(rayOrigin, Vector3.new(0, -32, 0), rayParams)

            if hit and hit.Normal.Y >= 0.65
            and math.abs(hit.Position.Y - promptPosition.Y) <= 7 then
                local goal = hit.Position + Vector3.new(
                    0,
                    humanoid.HipHeight + root.Size.Y / 2 + 0.15,
                    0
                )

                local path = PathfindingService:CreatePath({
                    AgentRadius = 1.25,
                    AgentHeight = 5,
                    AgentCanJump = true,
                    AgentCanClimb = true,
                    WaypointSpacing = 2
                })

                local computed = pcall(function()
                    path:ComputeAsync(currentRoot.Position, goal)
                end)

                if computed and path.Status == Enum.PathStatus.Success then
                    local waypoints = path:GetWaypoints()
                    if #waypoints > 0 then
                        local score = (goal - currentRoot.Position).Magnitude
                            + (#waypoints * 0.35)
                        if not bestScore or score < bestScore then
                            bestPath = path
                            bestGoal = goal
                            bestScore = score
                        end
                    end
                end
            end
        end

        return bestPath, bestGoal
    end

    -- Repath maksimal tiga kali bila waypoint terhalang atau tidak tercapai.
    for attempt = 1, 3 do
        if not alive() or not homeworkEnabled then return false end

        root = hwRoot()
        if not root then return false end

        local path, goal = findBestPath()
        if not path or not goal then
            setStatus("PATHFINDING: RUTE KE LANTAI TARGET TIDAK DITEMUKAN")
            return false
        end

        local waypoints = path:GetWaypoints()
        local currentWaypoint = 1
        local blockedAhead = false
        local blockedConnection = path.Blocked:Connect(function(blockedIndex)
            if blockedIndex >= currentWaypoint then
                blockedAhead = true
            end
        end)

        local routeOK = true
        for index, waypoint in ipairs(waypoints) do
            currentWaypoint = index
            if not alive() or not homeworkEnabled or blockedAhead then
                routeOK = false
                break
            end

            character = player.Character
            humanoid = character and character:FindFirstChildOfClass("Humanoid")
            root = hwRoot()
            if not humanoid or not root or humanoid.Health <= 0 then
                routeOK = false
                break
            end

            local distance = (waypoint.Position - root.Position).Magnitude
            if distance > 2 then
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                end

                humanoid:MoveTo(waypoint.Position)
                local speed = math.max(humanoid.WalkSpeed, 8)
                local timeout = math.max(6, distance / speed * 3 + 4)
                local deadline = os.clock() + timeout
                local reached = false

                while os.clock() < deadline do
                    if not alive() or not homeworkEnabled or blockedAhead then
                        break
                    end

                    root = hwRoot()
                    if not root then break end

                    if (waypoint.Position - root.Position).Magnitude <= 2.5 then
                        reached = true
                        break
                    end
                    task.wait(0.1)
                end

                if not reached then
                    routeOK = false
                    break
                end
            end
        end

        blockedConnection:Disconnect()

        if routeOK and not blockedAhead then
            root = hwRoot()
            if root and prompt.Parent then
                local interactionRange = math.max(
                    4,
                    math.min(tonumber(prompt.MaxActivationDistance) or 10, 10) - 0.5
                )
                if (root.Position - promptPosition).Magnitude <= interactionRange then
                    return true
                end
            end
        end

        local currentHumanoid = player.Character
            and player.Character:FindFirstChildOfClass("Humanoid")
        if currentHumanoid then
            currentHumanoid:Move(Vector3.zero)
        end

        if attempt < 3 then
            setStatus("PATHFINDING: HITUNG ULANG RUTE " .. tostring(attempt + 1) .. "/3")
            task.wait(0.25)
        end
    end

    setStatus("PATHFINDING: GAGAL MENCAPAI AREA PROMPT")
    return false
end
]=]
)


-- Farm, Feed, and Convert controls remain absent; Auto Clean stays enabled in GUI.




-- AUTO CLEAN tetap menggunakan cleanButton asli dari GUI utama.
-- Tidak membuat tombol duplikat atau menimpa posisi tombol Homework.

-- No runtime replacement is needed.

]==]

wrapper = wrapper:sub(1, at - 1) .. patch .. "\n" .. wrapper:sub(at)

diagnosticStatus("MENG-COMPILE WRAPPER...", false)
local chunk, compileError = loadstring(wrapper)
assert(chunk, "Wrapper compile gagal: " .. tostring(compileError))
diagnosticStatus("MENJALANKAN CORE...", false)
chunk()
end -- bootOnyxHub

-- Farm / Feed / Convert integration intentionally removed from Onyx Hub.

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
    error("ONYX CORE BOOT FAILED: " .. tostring(bootError), 0)
end
