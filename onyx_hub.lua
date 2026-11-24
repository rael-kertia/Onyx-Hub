-- ONYX HUB - CORE LOADER
-- Bootstrap diagnostik: tampilkan status di layar, bukan console Delta.

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local oldDiagnostic = playerGui:FindFirstChild("OnyxLoaderDiagnostic")
if oldDiagnostic then oldDiagnostic:Destroy() end

local diagnosticGui = Instance.new("ScreenGui")
diagnosticGui.Name = "OnyxLoaderDiagnostic"
diagnosticGui.ResetOnSpawn = false
diagnosticGui.DisplayOrder = 10000
diagnosticGui.Parent = playerGui

local diagnosticLabel = Instance.new("TextLabel")
diagnosticLabel.Size = UDim2.fromOffset(310, 42)
diagnosticLabel.Position = UDim2.new(0.5, -155, 0, 18)
diagnosticLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
diagnosticLabel.TextColor3 = Color3.new(1, 1, 1)
diagnosticLabel.TextSize = 12
diagnosticLabel.Font = Enum.Font.GothamBold
diagnosticLabel.TextWrapped = true
diagnosticLabel.Text = "ONYX HUB LOADER: MEMULAI"
diagnosticLabel.Parent = diagnosticGui
Instance.new("UICorner", diagnosticLabel).CornerRadius = UDim.new(0, 8)

local function diagnosticStatus(message, failed)
    diagnosticLabel.Text = "ONYX HUB LOADER: " .. tostring(message)
    diagnosticLabel.BackgroundColor3 = failed
        and Color3.fromRGB(150, 35, 35)
        or Color3.fromRGB(30, 90, 65)
end

local function bootOnyxHub()
diagnosticStatus("MENGAMBIL CORE...", false)

local url = "https://raw.githubusercontent.com/rael-kertia/Onyx-Hub/main/main_obfuscated.lua"
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
local marker = "
-- ==========================================
-- ONYX HYBRID SHELL + SAFE EXIT CONFIRMATION
-- Visual/navigation layer only; feature workers remain untouched.
-- ==========================================
source = source .. [====[
do
    -- Disable the legacy immediate-exit X; use the confirmation dialog below.
    if exitButton then exitButton.Visible = false end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(390, 800)
    local panelHeight = math.min(420, math.max(260, viewport.Y - 110))

    -- Fit the existing feature controls inside a mobile-safe scrolling viewport.
    frame.Size = UDim2.fromOffset(252, panelHeight)
    frame.Position = UDim2.new(1, -266, 0, math.max(12, math.min(95, viewport.Y - panelHeight - 12)))

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Name = "FeatureScroll"
    contentScroll.Position = UDim2.fromOffset(0, 47)
    contentScroll.Size = UDim2.new(1, 0, 1, -53)
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


    -- Icon rail stays available while the expandable control panel is hidden.
    local rail = Instance.new("Frame")
    rail.Name = "OnyxIconRail"
    rail.Size = UDim2.fromOffset(46, panelHeight)
    rail.Position = UDim2.new(1, -(frame.AbsoluteSize.X + 54), 0, 95)
    rail.BackgroundColor3 = Color3.fromRGB(10, 15, 26)
    rail.BorderSizePixel = 0
    rail.ZIndex = 40
    rail.Parent = gui
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
        frame.Visible = not frame.Visible
        miniButton.Visible = false
        menuButton.Text = frame.Visible and "≡" or "›"
    end)

    -- Close is deliberately separate from minimize.
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseConfirmButton"
    closeButton.Size = UDim2.fromOffset(25, 25)
    closeButton.Position = UDim2.new(1, -66, 0, 9)
    closeButton.BackgroundColor3 = Color3.fromRGB(115, 38, 48)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.ZIndex = 25
    closeButton.Parent = header
    Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 7)

    local shade = Instance.new("Frame")
    shade.Name = "ExitConfirmation"
    shade.Size = UDim2.fromScale(1, 1)
    shade.BackgroundColor3 = Color3.fromRGB(5, 8, 14)
    shade.BackgroundTransparency = 0.12
    shade.BorderSizePixel = 0
    shade.Visible = false
    shade.ZIndex = 100
    shade.Parent = frame
    Instance.new("UICorner", shade).CornerRadius = UDim.new(0, 12)

    local dialog = Instance.new("Frame")
    dialog.Size = UDim2.new(1, -28, 0, 190)
    dialog.Position = UDim2.new(0, 14, 0.5, -95)
    dialog.BackgroundColor3 = Color3.fromRGB(20, 29, 44)
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 101
    dialog.Parent = shade
    Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 11)

    local dialogTitle = Instance.new("TextLabel")
    dialogTitle.Size = UDim2.new(1, -20, 0, 28)
    dialogTitle.Position = UDim2.fromOffset(10, 12)
    dialogTitle.BackgroundTransparency = 1
    dialogTitle.Text = "KELUAR DARI ONYX HUB?"
    dialogTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
    dialogTitle.TextSize = 13
    dialogTitle.Font = Enum.Font.GothamBold
    dialogTitle.ZIndex = 102
    dialogTitle.Parent = dialog

    local dialogInfo = Instance.new("TextLabel")
    dialogInfo.Size = UDim2.new(1, -24, 0, 38)
    dialogInfo.Position = UDim2.fromOffset(12, 43)
    dialogInfo.BackgroundTransparency = 1
    dialogInfo.Text = "Minimize menyembunyikan menu. Stop All menghentikan seluruh automasi."
    dialogInfo.TextColor3 = Color3.fromRGB(170, 185, 205)
    dialogInfo.TextSize = 10
    dialogInfo.TextWrapped = true
    dialogInfo.Font = Enum.Font.Gotham
    dialogInfo.ZIndex = 102
    dialogInfo.Parent = dialog

    local function dialogButton(name, textValue, y, color)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(1, -24, 0, 30)
        button.Position = UDim2.fromOffset(12, y)
        button.BackgroundColor3 = color
        button.BorderSizePixel = 0
        button.Text = textValue
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 10
        button.Font = Enum.Font.GothamBold
        button.ZIndex = 102
        button.Parent = dialog
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
        return button
    end

    local minimizeChoice = dialogButton("MinimizeChoice", "MINIMIZE - AUTOMASI TETAP BERJALAN", 88, Color3.fromRGB(37, 91, 83))
    local stopChoice = dialogButton("StopAllChoice", "STOP ALL & EXIT", 124, Color3.fromRGB(145, 43, 52))
    local cancelChoice = dialogButton("CancelExitChoice", "BATAL", 160, Color3.fromRGB(55, 68, 88))

    connect(closeButton.Activated, function()
        if alive() then shade.Visible = true end
    end)

    connect(cancelChoice.Activated, function()
        shade.Visible = false
    end)

    connect(minimizeChoice.Activated, function()
        shade.Visible = false
        frame.Visible = false
        miniButton.Visible = false
    end)

    connect(minimizeButton.Activated, function()
        frame.Visible = false
        miniButton.Visible = false
    end)

    connect(stopChoice.Activated, function()
        -- Invalidate both feature sessions first so every worker exits.
        env.RaelV18Running = false
        env.RFC_Running = false

        for _, key in ipairs({"RaelV18Connections", "RFC_Connections"}) do
            local list = env[key]
            if type(list) == "table" then
                for _, connection in ipairs(list) do
                    pcall(function() connection:Disconnect() end)
                end
            end
        end

        for _, key in ipairs({"RaelV18Objects", "RFC_Objects"}) do
            local list = env[key]
            if type(list) == "table" then
                for _, object in ipairs(list) do
                    pcall(function() object:Destroy() end)
                end
            end
        end

        pcall(function()
            local farmGui = playerGui:FindFirstChild("RaelFarmFeedConvert")
            if farmGui then farmGui:Destroy() end
        end)
        pcall(function() gui:Destroy() end)
        pcall(function() rail:Destroy() end)
    end)

    -- Keep the icon rail aligned if the viewport changes (rotation/resizing).
    if camera then
        connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
            if not rail.Parent then return end
            local size = camera.ViewportSize
            rail.Position = UDim2.new(1, -(frame.AbsoluteSize.X + 54), 0, math.max(12, math.min(95, size.Y - panelHeight - 12)))
        end)
    end
end
]====]

local compiled, compileError = loadstring(source)"
local at = wrapper:find(marker, 1, true)
assert(at, "Titik patch core ONYX tidak ditemukan")

local patch = [==[
local function onyxReplaceBetween(text, firstMarker, nextMarker, replacement)
    local a = text:find(firstMarker, 1, true)
    if not a then error("ONYX patch: marker awal tidak ditemukan: " .. firstMarker) end
    local b = text:find(nextMarker, a + #firstMarker, true)
    if not b then error("ONYX patch: marker akhir tidak ditemukan: " .. nextMarker) end
    return text:sub(1, a - 1) .. replacement .. "\n\n" .. text:sub(b)
end

-- PERBAIKAN 1:
-- Satu rumah bisa memiliki banyak TrashBag. Scan seluruh descendants,
-- bukan hanya prompt yang menjadi child langsung dari part TrashBag.
local raelHwGet = [=[
local function hwGet(house, mode)
    local result = {}
    local seen = {}
    if not house then return result end

    for _, object in ipairs(house:GetDescendants()) do
        if (mode == 1 or mode == 3)
        and object:IsA("ProximityPrompt")
        and object.ActionText == "Bersihkan"
        and (mode == 3 or object.Enabled)
        and not seen[object] then
            seen[object] = true
            table.insert(result, object)

        elseif (mode == 2 or mode == 4)
        and object.Name == "TrashBag" then
            if object:IsA("ProximityPrompt") then
                if (mode == 4 or object.Enabled) and not seen[object] then
                    seen[object] = true
                    table.insert(result, object)
                end
            end

            for _, prompt in ipairs(object:GetDescendants()) do
                if prompt:IsA("ProximityPrompt")
                and prompt.Name == "AmbilPrompt"
                and (mode == 4 or prompt.Enabled)
                and not seen[prompt] then
                    seen[prompt] = true
                    table.insert(result, prompt)
                end
            end
        end
    end
    return result
end
]=]

source = onyxReplaceBetween(
    source,
    "local function hwGet(house, mode)",
    "local function hwFindHouse()",
    raelHwGet
)

-- Rumah yang masih memiliki TrashBag aktif juga harus bisa dipilih,
-- termasuk ketika prompt Bersihkan rumah tersebut sedang cooldown.
local raelHwFindHouse = [=[
local function hwFindHouse()
    local folder = W:FindFirstChild("KosanSpawned")
    local r = hwRoot()
    if not folder or not r then return nil end

    local best, bd
    for _, house in ipairs(folder:GetChildren()) do
        if hwOwnsHouse(house) then
            local prompts = hwGet(house, 1)
            for _, p in ipairs(hwGet(house, 2)) do
                table.insert(prompts, p)
            end

            for _, p in ipairs(prompts) do
                local q = hwPart(p)
                if q then
                    local d = (r.Position - q.Position).Magnitude
                    if not bd or d < bd then
                        best, bd = house, d
                    end
                end
            end
        end
    end
    return best
end
]=]

source = onyxReplaceBetween(
    source,
    "local function hwFindHouse()",
    "local function homeworkRun()",
    raelHwFindHouse
)

-- HOMEWORK: lepaskan rumah yang menunggu cooldown agar scan bisa memilih rumah lain.
-- Rumah baru dinyatakan selesai setelah tidak ada prompt Bersihkan, prompt TrashBag,
-- atau muatan selama tiga pemeriksaan berurutan. Progress GUI global tidak menjadi kunci.
local raelHomeworkWait = [=[
                    local remainingClean = #hwGet(house, 3)
                    local remainingBags = #hwGet(house, 4)

                    -- Prompt disabled menandakan rumah masih cooldown/update.
                    -- Keluar dari rumah ini agar loop luar dapat scan rumah lain.
                    if remainingClean > 0 or remainingBags > 0 then
                        quiet = 0
                        if remainingClean > 0 then
                            setStatus("HOMEWORK: RUMAH COOLDOWN - SCAN ULANG")
                        else
                            setStatus("HOMEWORK: MENUNGGU UPDATE SAMPAH")
                        end
                        break
                    end

                    if hadTrash then
                        quiet += 1
                        if quiet >= 3 then
                            break
                        end
                        setStatus("HOMEWORK: VERIFIKASI RUMAH KOSONG")
                    else
                        quiet += 1
                        if quiet >= 5 then
                            setStatus("RUMAH BELUM MEMUNCULKAN SAMPAH - SCAN ULANG")
                            break
                        end
                        setStatus("HOMEWORK: MENUNGGU SAMPAH MUNCUL")
                    end
                    task.wait(1)
]=]

source = onyxReplaceBetween(
    source,
    "                    -- Hanya anggap selesai setelah sampah pernah muncul",
    "                end\n            end\n        end\n\n        if not alive() or not homeworkEnabled then break end",
    raelHomeworkWait
)


-- GACHA: gunakan tombol native game agar GachaController sendiri yang
-- menjalankan Spin, reveal BlindBox, dan seluruh proses klaim hadiah.
local raelGachaNative = [=[
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
    raelGachaNative
)

-- HILANGKAN HANYA STATUS AUTO ACC.
-- Ganti empat pemanggilan spesifik; jangan scan seluruh source karena
-- wrapper menambahkan patch fitur lain setelah blok Auto Acc.
local autoAccStart = source:find("-- AUTO ACC - TERINTEGRASI KE RAEL'S TRICKS", 1, true)
assert(autoAccStart, "Blok Auto Acc tidak ditemukan")

local function onyxReplaceOnce(text, oldText, newText, label)
    local a, b = text:find(oldText, 1, true)
    assert(a, "Status Auto Acc tidak ditemukan: " .. label)
    assert(not text:find(oldText, b + 1, true), "Status Auto Acc ganda: " .. label)
    return text:sub(1, a - 1) .. newText .. text:sub(b + 1)
end

local autoAccMarker = "local autoAccLast = {}"
local markerAt = source:find(autoAccMarker, autoAccStart, true)
assert(markerAt, "Titik patch Auto Acc tidak ditemukan")
source = source:sub(1, markerAt + #autoAccMarker - 1)
    .. "\nlocal function setAutoAccStatus(_) end"
    .. source:sub(markerAt + #autoAccMarker)

source = onyxReplaceOnce(source,
    'setStatus(enabled and "AUTO ACC AKTIF - MENUNGGU PERMINTAAN"\n        or "AUTO ACC NONAKTIF")',
    'setAutoAccStatus(enabled and "AUTO ACC AKTIF - MENUNGGU PERMINTAAN"\n        or "AUTO ACC NONAKTIF")',
    "toggle")
source = onyxReplaceOnce(source,
    'setStatus("AUTO ACC: " .. item.card.Name\n                        .. " | " .. #cards .. " popup")',
    'setAutoAccStatus("AUTO ACC: " .. item.card.Name\n                        .. " | " .. #cards .. " popup")',
    "popup ditemukan")
source = onyxReplaceOnce(source,
    'setStatus(gone and "AUTO ACC: popup diproses; scan ulang"\n                        or "AUTO ACC: popup belum hilang; coba ulang")',
    'setAutoAccStatus(gone and "AUTO ACC: popup diproses; scan ulang"\n                        or "AUTO ACC: popup belum hilang; coba ulang")',
    "hasil klik")
source = onyxReplaceOnce(source,
    'setStatus("AUTO ACC: menunggu permintaan")',
    'setAutoAccStatus("AUTO ACC: menunggu permintaan")',
    "menunggu")

-- ==========================================
-- ==========================================
-- LAYOUT PATCH - STRICT MATCH (WAJIB BERHASIL)
-- ==========================================

local function onyxReplaceLineStrict(text, prefix, newLine, label)
    local a = text:find(prefix, 1, true)
    assert(a, "LAYOUT PATCH GAGAL: baris tidak ditemukan: " .. label)
    local e = text:find("\n", a, true) or (#text + 1)
    assert(not text:find(prefix, e + 1, true),
        "LAYOUT PATCH GAGAL: baris duplikat: " .. label)
    return text:sub(1, a - 1) .. newLine .. text:sub(e)
end

-- Perbaiki glyph minimize yang sebelumnya berupa karakter kontrol (kotak).
source = onyxReplaceLineStrict(
    source, "minimizeButton.Text = ",
    'minimizeButton.Text = "-"',
    "MINIMIZE TEXT"
)

-- Semua posisi diatur eksplisit dan setiap perubahan wajib terkonfirmasi.
source = onyxReplaceLineStrict(
    source, "statusPanel.Position = ",
    "statusPanel.Position = UDim2.fromOffset(12, 178)",
    "STATUS PANEL"
)
source = onyxReplaceLineStrict(
    source, "autoAccButton.Position = ",
    "autoAccButton.Position = UDim2.fromOffset(12, 226)",
    "AUTO ACC"
)
source = onyxReplaceLineStrict(
    source, "gachaButton.Position = ",
    "gachaButton.Position = UDim2.fromOffset(12, 263)",
    "AUTO GACHA"
)
source = onyxReplaceLineStrict(
    source, "gachaPaidButton.Position = ",
    "gachaPaidButton.Position = UDim2.fromOffset(12, 298)",
    "PAID GACHA"
)
source = onyxReplaceLineStrict(
    source, "frame.Size = UDim2.fromOffset(252, 340)",
    "frame.Size = UDim2.fromOffset(252, 340)",
    "FRAME HEIGHT"
)

-- Urutan ZIndex eksplisit agar tombol minimize selalu berada di atas header.
source = onyxReplaceLineStrict(
    source, "header.Name = \"Header\"",
    'header.Name = "Header"\nheader.ZIndex = 5',
    "HEADER ZINDEX"
)
source = onyxReplaceLineStrict(
    source, 'title.Text = "ONYX HUB"',
    'title.Text = "ONYX HUB"\ntitle.ZIndex = 6',
    "TITLE ZINDEX"
)
source = onyxReplaceLineStrict(
    source, "minimizeButton.Name = \"MinimizeButton\"",
    'minimizeButton.Name = "MinimizeButton"\nminimizeButton.ZIndex = 20\nminimizeButton.Active = true\nminimizeButton.AutoButtonColor = true',
    "MINIMIZE ZINDEX"
)
source = onyxReplaceLineStrict(
    source, "miniButton.Name = \"RaelMiniButton\"",
    'miniButton.Name = "RaelMiniButton"\nminiButton.ZIndex = 30\nminiButton.Active = true\nminiButton.AutoButtonColor = true',
    "REOPEN ZINDEX"
)

-- Pastikan event minimize dan reopen terpasang tepat satu kali.
local minimizeEvent = 'connect(minimizeButton.Activated, function() frame.Visible = false miniButton.Visible = true end)'
local reopenEvent = 'connect(miniButton.Activated, function() miniButton.Visible = false frame.Visible = true end)'
assert(source:find(minimizeEvent, 1, true), "MINIMIZE EVENT TIDAK DITEMUKAN")
assert(source:find(reopenEvent, 1, true), "REOPEN EVENT TIDAK DITEMUKAN")

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
jamButton.Position = UDim2.fromOffset(12, 138)
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

source = source .. [=[
-- EXIT BUTTON UNTUK MAIN GUI: hentikan seluruh fitur V18 + Homework + Jam Ajaib.
local exitButton = Instance.new("TextButton")
exitButton.Name = "ExitButton"
exitButton.Size = UDim2.fromOffset(25, 19)
exitButton.Position = UDim2.new(1, -58, 0, 1)
exitButton.BackgroundColor3 = Color3.fromRGB(155, 38, 38)
exitButton.BorderSizePixel = 0
exitButton.Text = "X"
exitButton.TextColor3 = Color3.new(1, 1, 1)
exitButton.TextSize = 12
exitButton.Font = Enum.Font.GothamBold
exitButton.ZIndex = 20
exitButton.Active = true
exitButton.AutoButtonColor = true
exitButton.Parent = frame
Instance.new("UICorner", exitButton).CornerRadius = UDim.new(0, 5)

connect(exitButton.Activated, function()
    if not alive() then return end
    enabled = false
    autoFarm = false
    homeworkEnabled = false
    jamAutoEnabled = false
    env.RaelV18Running = false

    for _, connection in ipairs(env.RaelV18Connections or {}) do
        pcall(function() connection:Disconnect() end)
    end
    for _, object in ipairs(env.RaelV18Objects or {}) do
        pcall(function() object:Destroy() end)
    end
    env.RaelV18Connections = {}
    env.RaelV18Objects = {}
    gui:Destroy()
end)

]=]
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
    local farmUrl = "https://raw.githubusercontent.com/rael-kertia/Onyx-Hub/main/farm_feed_convert.lua"
    local farmSource = game:HttpGet(farmUrl)
    assert(type(farmSource) == "string" and #farmSource > 20000, "FARM CORE KOSONG / GAGAL DIUNDUH")
    farmSource = farmSource:gsub("RAEL // FARM SYSTEM", "ONYX // FARM SYSTEM")
    local farmChunk, farmCompileError = loadstring(farmSource)
    assert(type(farmChunk) == "function", "FARM COMPILE GAGAL: " .. tostring(farmCompileError))
    farmChunk()

    local farmGui = playerGui:WaitForChild("RaelFarmFeedConvert", 10)
    assert(farmGui, "GUI FARM TIDAK TERBENTUK")
    local mainGui = playerGui:FindFirstChild("RaelsTricksV1")
    assert(mainGui, "GUI UTAMA ONYX TIDAK DITEMUKAN")
    local scroll = mainGui:FindFirstChild("FeatureScroll", true)
    assert(scroll and scroll:IsA("ScrollingFrame"), "AREA SCROLL ONYX TIDAK DITEMUKAN")
    local farmPanel = farmGui:FindFirstChild("Panel")
    assert(farmPanel, "PANEL FARM TIDAK DITEMUKAN")

    local bottom = 0
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("GuiObject") then
            bottom = math.max(bottom, child.Position.Y.Offset + child.AbsoluteSize.Y)
        end
    end

    farmPanel.Position = UDim2.fromOffset(12, bottom + 14)
    farmPanel.Size = UDim2.new(1, -24, 0, 174)
    farmPanel.Parent = scroll

    local farmTitle = farmPanel:FindFirstChildWhichIsA("TextLabel")
    if farmTitle then farmTitle.Text = "ONYX // FARM SYSTEM" end

    local oldMinimize = farmPanel:FindFirstChildWhichIsA("TextButton")
    if oldMinimize then oldMinimize.Visible = false end
    local oldExit = farmPanel:FindFirstChild("ExitButton")
    if oldExit then oldExit.Visible = false end
    local oldMini = farmGui:FindFirstChild("RaelFarmMini")
    if oldMini then oldMini.Visible = false end

    -- The hidden ScreenGui keeps the original worker lifetime valid.
    farmGui.Enabled = false

    local mainFrame = mainGui:FindFirstChild("Main")
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

        local homeShortcut = makeShortcut("HomeShortcut", "⌂", 112)
        local farmShortcut = makeShortcut("FarmShortcut", "♧", 158)

        homeShortcut.Activated:Connect(function()
            mainFrame.Visible = true
            scroll.CanvasPosition = Vector2.new(0, 0)
        end)
        farmShortcut.Activated:Connect(function()
            frame.Visible = true
            scroll.CanvasPosition = Vector2.new(0, farmPanel.Position.Y.Offset)
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
