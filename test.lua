-- ONYX HUB | MAIN LOADER
-- Silent bootstrap: tidak membuat GUI status atau overlay tambahan.

pcall(function() getgenv().ONYX_HW_PATH_DIAG = "TEST LOADER V7 START" end)

local url = "https://raw.githubusercontent.com/rael-kertia/Onyx-Hub/main/onyx_hub.lua?v=homework-ground-recovery-20261126-1"
local response = game:HttpGet(url)
assert(type(response) == "string" and #response > 10000, "ONYX HUB: core gagal diunduh")

local onyxHomeworkPathfindingMarker = "wrapper = wrapper:sub(1, at - 1) .. patch .. \"\\n\" .. wrapper:sub(at)"
local onyxHomeworkPathfindingPatch = [==[

patch = patch .. [====[
-- AUTO ACC: sisipkan ke source GUI pada anchor yang benar.
-- Core asli tidak memiliki blok Auto ACC lama untuk diganti.
local autoAccInsertMarker = "local function updateButtons()"
local autoAccInsertAt = source:find(autoAccInsertMarker, 1, true)
assert(autoAccInsertAt, "AUTO ACC: anchor GUI updateButtons tidak ditemukan")
-- HAPUS JALUR AUTO ACC LEGACY.
-- Versi lama selalu menekan AccBtn dengan VirtualInputManager tanpa filter nominal.
-- Blok legacy berada sebelum blok Auto Gacha di source hasil decode.
local legacyAutoAccStart = source:find("-- AUTO ACC - TERINTEGRASI KE RAEL'S TRICKS", 1, true)
if legacyAutoAccStart then
    local nextSourceBlock = source:find("-- AUTO GACHA - TERINTEGRASI KE GUI UTAMA", legacyAutoAccStart, true)
    assert(nextSourceBlock, "AUTO ACC: batas akhir blok legacy tidak ditemukan")
    source = source:sub(1, legacyAutoAccStart - 1) .. source:sub(nextSourceBlock)
end

local autoAccAlreadyInjected = source:find("AutoAccButton", 1, true) ~= nil
assert(not autoAccAlreadyInjected, "AUTO ACC: instance legacy masih tertinggal setelah pembersihan")

local autoAccInsert = [=[
-- AUTO ACC - FILTER NOMINAL SEWA
frame.Size = UDim2.fromOffset(205, 150)
status.Position = UDim2.fromOffset(5, 123)

local autoAccEnabled = false
local autoAccBusy = false
local autoAccDone = setmetatable({}, {__mode = "k"})
local autoAccAttempt = setmetatable({}, {__mode = "k"})

local autoAccButton = Instance.new("TextButton")
autoAccButton.Name = "AutoAccButton"
autoAccButton.Size = UDim2.fromOffset(195, 27)
autoAccButton.Position = UDim2.fromOffset(5, 86)
autoAccButton.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
autoAccButton.BorderSizePixel = 0
autoAccButton.Text = "AUTO ACC: OFF"
autoAccButton.TextColor3 = Color3.fromRGB(248, 250, 252)
autoAccButton.TextSize = 10
autoAccButton.Font = Enum.Font.GothamBold
autoAccButton.Parent = frame
Instance.new("UICorner", autoAccButton).CornerRadius = UDim.new(0, 6)

local function setAutoAcc(enabled)
    autoAccEnabled = enabled
    autoAccButton.Text = enabled and "AUTO ACC: ON" or "AUTO ACC: OFF"
    autoAccButton.BackgroundColor3 = enabled
        and Color3.fromRGB(5, 150, 105)
        or Color3.fromRGB(127, 29, 29)
    setStatus(enabled and "AUTO ACC AKTIF | BATAS RP20 JUTA"
        or "AUTO ACC NONAKTIF")
end

connect(autoAccButton.Activated, function()
    if alive() then setAutoAcc(not autoAccEnabled) end
end)

local function autoAccParseAmount(value)
    local raw = tostring(value or "")
    local amount = raw:match("[Rr][Pp]%s*%.?%s*([%d][%d%.,]*)")
    if not amount then return nil end
    local digits = amount:gsub("[^%d]", "")
    if digits == "" then return nil end
    return tonumber(digits)
end

local function autoAccGetCards()
    local result = {}
    local requestUI = playerGui:FindFirstChild("PermintaanSewaUI")
    if not requestUI then return result end
    if requestUI:IsA("ScreenGui") and not requestUI.Enabled then
        return result
    end

    local stack = requestUI:FindFirstChild("Tumpukan", true)
    if not stack then return result end

    for _, card in ipairs(stack:GetChildren()) do
        if card.Name:match("^Kartu_%d+$") and card.Visible then
            local body = card:FindFirstChild("Isi")
            local tag = body and body:FindFirstChild("Tag")
            local tagLabel = tag and tag:FindFirstChild("Label")
            local info = body and body:FindFirstChild("Info")
            local accept = body and body:FindFirstChild("AccBtn")
            local reject = body and body:FindFirstChild("TolakBtn")

            if tagLabel and info
            and tostring(tagLabel.Text):upper():find("PERMINTAAN SEWA", 1, true) then
                local amount = autoAccParseAmount(info.Text)
                -- Semua nominal valid harus masuk antrean:
                -- > Rp20 juta = ACC, <= Rp20 juta = TOLAK.
                if amount then
                    local decision = amount > 20000000 and "TERIMA" or "TOLAK"
                    local target = decision == "TERIMA" and accept or reject
                    if target and target:IsA("GuiButton")
                    and target.Visible and target.Active then
                        local pos = target.AbsolutePosition
                        local size = target.AbsoluteSize
                        result[#result + 1] = {
                            card = card,
                            button = target,
                            amount = amount,
                            info = tostring(info.Text),
                            decision = decision,
                            x = pos.X + size.X / 2,
                            y = pos.Y + size.Y / 2
                        }
                    end
                end
            end
        end
    end

    table.sort(result, function(a, b) return a.y < b.y end)
    return result
end

local function autoAccClick(item)
    -- Jangan pernah memakai referensi tombol atau nominal dari hasil scan lama.
    -- Baca ulang isi kartu dan cari tombol langsung dari kartu yang masih aktif.
    local card = item and item.card
    if not card or not card.Parent or not card.Visible then
        return false
    end

    local body = card:FindFirstChild("Isi")
    local tag = body and body:FindFirstChild("Tag")
    local tagLabel = tag and tag:FindFirstChild("Label")
    local info = body and body:FindFirstChild("Info")
    if not body or not tagLabel or not info
    or not tostring(tagLabel.Text):upper():find("PERMINTAAN SEWA", 1, true) then
        return false
    end

    -- Parse teks live, bukan cache. Tidak ada nominal = tidak ada aksi.
    local liveText = tostring(info.Text or "")
    local liveAmount = autoAccParseAmount(liveText)
    if not liveAmount or liveAmount ~= item.amount
    or liveText ~= item.info then
        return false
    end

    local shouldAccept = liveAmount > 20000000
    local expectedName = shouldAccept and "AccBtn" or "TolakBtn"
    local forbiddenName = shouldAccept and "TolakBtn" or "AccBtn"

    local accept = body:FindFirstChild("AccBtn")
    local reject = body:FindFirstChild("TolakBtn")
    local button = shouldAccept and accept or reject

    -- Fail closed: tombol target wajib tepat, tombol lawan wajib berbeda.
    if not button or button == (shouldAccept and reject or accept)
    or button.Name ~= expectedName
    or not button:IsA("GuiButton")
    or not button.Parent or button.Parent ~= body
    or not button.Visible or not button.Active
    or (button.Name == forbiddenName) then
        return false
    end

    -- Pemeriksaan terakhir tepat sebelum Activate untuk mencegah kartu berubah.
    local finalText = tostring(info.Text or "")
    local finalAmount = autoAccParseAmount(finalText)
    if finalText ~= liveText or finalAmount ~= liveAmount
    or ((finalAmount > 20000000) ~= (button.Name == "AccBtn")) then
        return false
    end

    -- Kirim input sentuh ke TOMBOL YANG SUDAH DIPILIH.
    -- Hindari metode Activate yang bukan bagian dari API GuiButton terdokumentasi.
    local input = game:GetService("VirtualInputManager")
    local pos = button.AbsolutePosition
    local size = button.AbsoluteSize
    local x = pos.X + size.X / 2
    local y = pos.Y + size.Y / 2
    local point = Vector2.new(x, y)

    local touchOK = pcall(function()
        input:SendTouchEvent(0, Enum.UserInputState.Begin, point)
        task.wait(0.10)
        input:SendTouchEvent(0, Enum.UserInputState.End, point)
    end)

    task.wait(0.45)
    if not card.Parent or not card.Visible then
        return true
    end

    -- Jika sentuh tidak memproses kartu, coba klik mouse pada koordinat
    -- tombol yang SAMA. Validasi nominal dan nama tombol sekali lagi dahulu.
    local retryText = tostring(info.Text or "")
    local retryAmount = autoAccParseAmount(retryText)
    if retryText ~= finalText or retryAmount ~= finalAmount
    or not button.Parent or button.Name ~= expectedName
    or not button.Visible or not button.Active then
        return false
    end

    local mouseOK = pcall(function()
        input:SendMouseMoveEvent(x, y, game)
        task.wait(0.05)
        input:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.08)
        input:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)

    if not touchOK and not mouseOK then return false end
    task.wait(0.65)
    return not card.Parent or not card.Visible
end

task.spawn(function()
    while alive() and gui.Parent do
        if autoAccEnabled and not autoAccBusy then
            local cards = autoAccGetCards()
            for _, item in ipairs(cards) do
                local fingerprint = item.info .. "|" .. tostring(item.amount)
                    .. "|" .. item.decision
                local now = os.clock()
                if autoAccDone[item.card] ~= fingerprint
                and (not autoAccAttempt[item.card]
                    or now - autoAccAttempt[item.card] >= 3) then
                    autoAccBusy = true
                    autoAccAttempt[item.card] = now

                    -- Verifikasi ulang kartu dan nominal tepat sebelum klik.
                    local valid
                    for _, current in ipairs(autoAccGetCards()) do
                        if current.card == item.card
                        and current.amount == item.amount
                        and current.decision == item.decision
                        and current.info == item.info then
                            valid = current
                            break
                        end
                    end

                    if valid then
                        local clicked = autoAccClick(valid)
                        if clicked then
                            autoAccDone[item.card] = fingerprint
                            setStatus("AUTO ACC " .. valid.decision
                                .. " | RP " .. tostring(valid.amount))
                        else
                            setStatus("AUTO ACC: KLIK BELUM TERKONFIRMASI")
                        end
                    end

                    autoAccBusy = false
                    task.wait(0.5)
                    break
                end
            end
        end
        task.wait(0.2)
    end
end)
]=]

if not autoAccAlreadyInjected then
    source = source:sub(1, autoAccInsertAt - 1)
        .. autoAccInsert .. "\n"
        .. source:sub(autoAccInsertAt)
end

-- HOMEWORK PATHFINDING: hanya untuk prompt Bersihkan.
-- Aksi TrashBag (Ambil/Buang) tetap memakai TP lama.
local function onyxHomeworkReplaceBetween(text, firstMarker, nextMarker, replacement)
    local a = text:find(firstMarker, 1, true)
    assert(a, "HOMEWORK PATHFINDING: fungsi awal tidak ditemukan")
    local b = text:find(nextMarker, a + #firstMarker, true)
    assert(b, "HOMEWORK PATHFINDING: batas fungsi tidak ditemukan")
    return text:sub(1, a - 1) .. replacement .. "\n\n" .. text:sub(b)
end

source = onyxHomeworkReplaceBetween(
    source,
    "local function hwMove(prompt)",
    "local function hwUse(prompt)",
    [=[
local function hwMove(prompt)
    local function pathDiag(value)
        pcall(function() getgenv().ONYX_HW_PATH_DIAG = tostring(value) end)
    end

    if not alive() or not homeworkEnabled then
        pathDiag("TWEEN DIBATALKAN: HOMEWORK OFF / KARAKTER TIDAK AKTIF")
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = hwRoot()
    local targetPart = hwPart(prompt)
    if not humanoid or not root or not targetPart then
        pathDiag("TWEEN GAGAL: ROOT / HUMANOID / PROMPT TIDAK DITEMUKAN")
        return false
    end

    -- Kecepatan lari standar Roblox adalah 16 studs/detik.
    -- Jika game mengubah WalkSpeed, ikuti nilai aktual karakter.
    local runSpeed = tonumber(humanoid.WalkSpeed) or 16
    if runSpeed <= 0 then runSpeed = 16 end

    -- Bergerak langsung ke posisi prompt. Tween lurus sengaja mengabaikan
    -- collision pintu, dinding, tangga, dan objek di sepanjang jalur.
    -- Offset kecil menjaga root tidak tepat berada di titik attachment prompt.
    local targetPosition = targetPart.Position + Vector3.new(0, 1.5, 0)
    local distance = (targetPosition - root.Position).Magnitude
    local duration = math.max(distance / runSpeed, 0.05)
    local targetCFrame = root.CFrame + (targetPosition - root.Position)

    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local wasAnchored = root.Anchored
    local oldAutoRotate = humanoid.AutoRotate
    local tween = tweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    local completedState = nil
    local completedConnection = tween.Completed:Connect(function(state)
        completedState = state
    end)

    pathDiag("TWEEN HOMEWORK: JARAK=" .. string.format("%.1f", distance)
        .. " SPEED=" .. string.format("%.1f", runSpeed)
        .. " DURASI=" .. string.format("%.2f", duration))

    -- Anchor sementara agar physics tidak mendorong karakter keluar dari
    -- lintasan Tween saat menembus geometri. Selalu pulihkan state setelahnya.
    root.Anchored = true
    humanoid.AutoRotate = false
    tween:Play()

    while not completedState do
        if not alive() or not homeworkEnabled
        or player.Character ~= character
        or not root.Parent then
            tween:Cancel()
            break
        end
        task.wait(0.05)
    end

    completedConnection:Disconnect()
    pcall(function() tween:Cancel() end)
    if root and root.Parent then
        root.Anchored = wasAnchored
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    if humanoid and humanoid.Parent then
        humanoid.AutoRotate = oldAutoRotate
    end

    if completedState == Enum.PlaybackState.Completed
    and alive() and homeworkEnabled then
        pathDiag("TWEEN HOMEWORK SELESAI")
        return true
    end

    pathDiag("TWEEN HOMEWORK DIBATALKAN")
    return false
end
]=],

    "HOMEWORK PATHFINDING MOVE"
)

-- DIAGNOSTIK HOMEWORK: hanya mencatat, tidak mengubah alur kerja.
local diagInsert = [=[
local onyxHwDiag = {
    lastStage = "MENUNGGU HOMEWORK",
    findCalls = 0,
    moveCalls = 0,
    lastMove = "BELUM ADA",
    lastMoveResult = "BELUM ADA"
}

-- Rumah yang gagal tidak dikunci. Beri cooldown sementara agar
-- hwFindHouse memilih rumah kotor lain; setelah 20 detik boleh dicoba lagi.
local onyxHwFailedHouseUntil = setmetatable({}, {__mode = "k"})
local hwGetOriginal = hwGet
hwGet = function(house, mode)
    local items = hwGetOriginal(house, mode)
    if mode ~= 1 or not house then return items end
    local untilTime = onyxHwFailedHouseUntil[house]
    if untilTime and os.clock() < untilTime then
        return {}
    end
    if untilTime then onyxHwFailedHouseUntil[house] = nil end
    return items
end

local hwFindHouseOriginal = hwFindHouse
hwFindHouse = function(...)
    onyxHwDiag.findCalls = onyxHwDiag.findCalls + 1
    onyxHwDiag.lastStage = "MENCARI RUMAH"
    local result = hwFindHouseOriginal(...)
    onyxHwDiag.lastHouse = result and result:GetFullName() or "NIL"
    onyxHwDiag.lastStage = result and "RUMAH DITEMUKAN" or "RUMAH TIDAK DITEMUKAN"
    return result
end

local hwMoveOriginal = hwMove
hwMove = function(prompt)
    onyxHwDiag.moveCalls = onyxHwDiag.moveCalls + 1
    onyxHwDiag.lastStage = "HW MOVE DIPANGGIL"
    onyxHwDiag.lastMove = prompt and (prompt:GetFullName() .. " | " .. tostring(prompt.ActionText)) or "PROMPT NIL"
    local ok, result = pcall(hwMoveOriginal, prompt)
    onyxHwDiag.lastMoveResult = ok and tostring(result) or ("ERROR: " .. tostring(result))
    if prompt and prompt.ActionText == "Bersihkan" then
        local folder = W:FindFirstChild("KosanSpawned")
        local house = prompt
        while house and house.Parent ~= folder do
            house = house.Parent
        end
        if house and house.Parent == folder then
            if not ok or not result then
                onyxHwFailedHouseUntil[house] = os.clock() + 20
                onyxHwDiag.lastHouse = house:GetFullName() .. " (COOLDOWN 20S - PINDAH TARGET)"
            else
                onyxHwFailedHouseUntil[house] = nil
            end
        end
    end
    onyxHwDiag.lastStage = "HW MOVE SELESAI"
    return ok and result or false
end

-- Diagnostik sekarang hanya dibuat ketika karakter benar-benar tidak bergerak
-- selama ambang stuck pada waypoint, bukan saat GUI muncul / timer 7 detik.
getgenv().ONYX_HW_CAPTURE_STUCK_DIAG = function(data)
    local lines = {
        "ONYX HOMEWORK STUCK DIAGNOSTIC V2",
        "TRIGGER=KARAKTER TIDAK ADA PROGRESS SAAT MOVETO",
        "TIME=" .. tostring(os.clock()),
        "HOMEWORK=" .. tostring(homeworkEnabled),
        "PLAYER=" .. tostring(player.Name) .. " / " .. tostring(player.UserId),
        "HOUSE=" .. tostring(data.house),
        "PROMPT=" .. tostring(data.prompt),
        "WAYPOINT=" .. tostring(data.waypoint),
        "ROOT=" .. tostring(data.root),
        "TARGET=" .. tostring(data.target),
        "DISTANCE=" .. tostring(data.distance),
        "STUCK_SECONDS=" .. tostring(data.stuckSeconds),
        "LAST_POSITION=" .. tostring(data.lastPosition),
        "VELOCITY=" .. tostring(data.velocity),
        "HUMANOID_STATE=" .. tostring(data.humanoidState),
        "RECOVERY=" .. tostring(data.recovery),
        "",
        "=== PART COLLIDABLE TERDEKAT ==="
    }
    for i, item in ipairs(data.nearby or {}) do
        lines[#lines + 1] = string.format(
            "[%02d] DIST=%.2f NAME=%s PATH=%s POS=%s SIZE=%s",
            i, item.distance, item.name, item.path, item.position, item.size
        )
    end
    local report = table.concat(lines, "\\n")
    pcall(function()
        if typeof(setclipboard) == "function" then setclipboard(report) end
    end)
    pcall(function() warn(report) end)
    getgenv().ONYX_HW_STUCK_LAST_REPORT = report
end

]=]
local diagMarker = "local function homeworkRun()"
local diagAt = source:find(diagMarker, 1, true)
assert(diagAt, "HOMEWORK DIAGNOSTIC: marker homeworkRun tidak ditemukan")
source = source:sub(1, diagAt - 1) .. diagInsert .. "\n" .. source:sub(diagAt)
]====]

]==]
assert(response:find(onyxHomeworkPathfindingMarker, 1, true),
    "ONYX TEST: marker loader pathfinding tidak ditemukan")
local onyxHomeworkPathfindingAt = response:find(onyxHomeworkPathfindingMarker, 1, true)
assert(onyxHomeworkPathfindingAt, "ONYX TEST: marker pathfinding tidak ditemukan (plain search)")
response = response:sub(1, onyxHomeworkPathfindingAt - 1)
    .. onyxHomeworkPathfindingPatch .. "\n"
    .. response:sub(onyxHomeworkPathfindingAt)

local chunk, compileError = loadstring(response)
assert(type(chunk) == "function", "ONYX HUB: kompilasi gagal: " .. tostring(compileError))
chunk()

-- =========================================================
-- ONYX TEST: AUTO CLEAN PORT DARI RAEL-TRICKS/base.lua
-- main.lua Onyx dijalankan utuh; hanya menambahkan Auto Clean.
-- Tidak memuat ulang Farm/Feed/Convert dan tidak mengubah core Onyx.
-- =========================================================

local function onyxCleanReport(message)
    local report = "ONYX TEST AUTO CLEAN: " .. tostring(message)
    pcall(function()
        if typeof(setclipboard) == "function" then setclipboard(report) end
    end)
    pcall(function() warn(report) end)
end

local cleanInitOK, cleanInitError = pcall(function()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local mainGui = playerGui:WaitForChild("RaelsTricksV18", 20)
    assert(mainGui, "GUI ONYX TIDAK DITEMUKAN")

    local scroll = mainGui:FindFirstChild("FeatureScroll", true)
    assert(scroll and scroll:IsA("ScrollingFrame"), "FEATURESCROLL ONYX TIDAK DITEMUKAN")

    local env = getgenv()
    env.ONYX_TEST_CLEAN_RUNNING = false
    if type(env.ONYX_TEST_CLEAN_CONNECTIONS) == "table" then
        for _, connection in ipairs(env.ONYX_TEST_CLEAN_CONNECTIONS) do
            pcall(function() connection:Disconnect() end)
        end
    end
    env.ONYX_TEST_CLEAN_CONNECTIONS = {}
    env.ONYX_TEST_CLEAN_RUNNING = true
    env.ONYX_TEST_CLEAN_ENABLED = false
    local cleanSession = tick()
    env.ONYX_TEST_CLEAN_SESSION = cleanSession

    local function cleanAlive()
        return env.ONYX_TEST_CLEAN_RUNNING
            and env.ONYX_TEST_CLEAN_SESSION == cleanSession
            and mainGui.Parent ~= nil
    end

    local function cleanConnect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(env.ONYX_TEST_CLEAN_CONNECTIONS, connection)
        return connection
    end

    -- Letakkan Auto Clean setelah seluruh konten Onyx yang sudah ada.
    local bottom = 0
    for _, item in ipairs(scroll:GetDescendants()) do
        if item:IsA("GuiObject") and item.Visible then
            local relativeY = item.Position.Y.Offset
            local parent = item.Parent
            while parent and parent ~= scroll do
                if parent:IsA("GuiObject") then
                    relativeY += parent.Position.Y.Offset
                end
                parent = parent.Parent
            end
            bottom = math.max(bottom, relativeY + item.Size.Y.Offset)
        end
    end
    local sectionY = math.max(300, bottom + 14)

    local cleanSection = Instance.new("TextLabel")
    cleanSection.Name = "OnyxTestCleanSection"
    cleanSection.Size = UDim2.new(1, -24, 0, 20)
    cleanSection.Position = UDim2.fromOffset(12, sectionY)
    cleanSection.BackgroundTransparency = 1
    cleanSection.Text = "AUTO CLEANER"
    cleanSection.TextColor3 = Color3.fromRGB(104, 220, 195)
    cleanSection.Font = Enum.Font.GothamBlack
    cleanSection.TextSize = 10
    cleanSection.TextXAlignment = Enum.TextXAlignment.Left
    cleanSection.ZIndex = 30
    cleanSection.Parent = scroll

    local cleanButton = Instance.new("TextButton")
    cleanButton.Name = "OnyxTestAutoClean"
    cleanButton.Size = UDim2.new(1, -24, 0, 36)
    cleanButton.Position = UDim2.fromOffset(12, sectionY + 24)
    cleanButton.BackgroundColor3 = Color3.fromRGB(145, 48, 55)
    cleanButton.BorderSizePixel = 0
    cleanButton.Text = "AUTO CLEAN  [OFF]"
    cleanButton.TextColor3 = Color3.new(1, 1, 1)
    cleanButton.TextSize = 11
    cleanButton.Font = Enum.Font.GothamBold
    cleanButton.ZIndex = 30
    cleanButton.Visible = true
    cleanButton.Active = true
    cleanButton.AutoButtonColor = true
    cleanButton.Parent = scroll
    Instance.new("UICorner", cleanButton).CornerRadius = UDim.new(0, 8)
    local cleanStroke = Instance.new("UIStroke")
    cleanStroke.Color = Color3.fromRGB(47, 88, 105)
    cleanStroke.Thickness = 1
    cleanStroke.Parent = cleanButton

    local CLEAN_RANGE = 100
    local TRASH_RANGE = 30
    local SCAN_DELAY = 0.2
    local RETRY_DELAY = 1
    local DROPPING_RETRY = 2
    local prompts = setmetatable({}, {__mode = "k"})
    local lastAttempt = setmetatable({}, {__mode = "k"})

    local function isAllowed(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then return false end
        local action = (prompt.ActionText or ""):lower()
        local object = (prompt.ObjectText or ""):lower()
        local name = (prompt.Name or ""):lower()
        local path = prompt:GetFullName():lower()
        if action:find("keranjang", 1, true)
        or object:find("keranjang", 1, true)
        or name:find("keranjang", 1, true)
        or path:find("keranjang", 1, true) then
            return false
        end
        return action:find("bersihkan", 1, true) ~= nil
            or action:find("ambil", 1, true) ~= nil
            or action:find("buang", 1, true) ~= nil
    end

    local function addPrompt(object)
        if object:IsA("ProximityPrompt") and isAllowed(object) then
            prompts[object] = true
        end
    end

    local function getPosition(prompt)
        if not prompt or not prompt.Parent then return nil end
        local parent = prompt.Parent
        if parent:IsA("Attachment") then return parent.WorldPosition end
        if parent:IsA("BasePart") then return parent.Position end
        local model = parent:IsA("Model") and parent
            or parent:FindFirstAncestorWhichIsA("Model")
        if model then
            local part = model.PrimaryPart
                or model:FindFirstChildWhichIsA("BasePart", true)
            if part then return part.Position end
        end
        local part = parent:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position or nil
    end

    -- Sama dengan deteksi TrashBag Auto Clean di Rael-Tricks/base.lua.
    local function isCarryingTrash()
        local character = player.Character
        local trash = character and character:FindFirstChild("TrashBag", true)
        return trash ~= nil and trash:IsA("BasePart")
    end

    local function isDroppingPrompt(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then return false end
        local action = (prompt.ActionText or ""):lower()
        local object = (prompt.ObjectText or ""):lower()
        local name = (prompt.Name or ""):lower()
        return action:find("ambil", 1, true) ~= nil
            and (object:find("kotoran", 1, true) ~= nil
                or name:find("ambilkotoran", 1, true) ~= nil)
    end

    local function activatePrompt(prompt)
        if not cleanAlive() or not prompt
        or not prompt.Parent or not prompt.Enabled then
            return false
        end
        if typeof(fireproximityprompt) == "function" then
            local ok = pcall(function() fireproximityprompt(prompt) end)
            if ok then return true end
        end
        local ok = pcall(function()
            prompt:InputHoldBegin()
            task.wait(math.max(prompt.HoldDuration, 0.2) + 0.15)
            prompt:InputHoldEnd()
        end)
        return ok
    end

    local function findNearest(root)
        local now = os.clock()
        local carrying = isCarryingTrash()
        local nearest, shortest = nil, math.huge
        for prompt in pairs(prompts) do
            if prompt.Parent and prompt.Enabled and isAllowed(prompt) then
                -- Kotoran ditangani scanner kandang khusus di bawah.
                -- Jangan campurkan prompt kotoran dengan alur sampah/keranjang.
                if isDroppingPrompt(prompt) then continue end
                local action = (prompt.ActionText or ""):lower()
                local isClean = action:find("bersihkan", 1, true) ~= nil
                local isTake = action:find("ambil", 1, true) ~= nil
                local isDrop = action:find("buang", 1, true) ~= nil
                if isTake and carrying then continue end
                if isDrop and not carrying then continue end
                local ready = not lastAttempt[prompt]
                    or now - lastAttempt[prompt] >= RETRY_DELAY
                if ready then
                    local position = getPosition(prompt)
                    local range = isClean and CLEAN_RANGE or TRASH_RANGE
                    if position then
                        local distance = (root.Position - position).Magnitude
                        if distance <= range and distance < shortest then
                            nearest, shortest = prompt, distance
                        end
                    end
                end
            end
        end
        return nearest
    end

    -- Scanner kotoran dibatasi ke folder kandang milik pemain.
    -- Ini mencegah prompt kandang/sampah lain mengganggu alur keranjang.
    local function getDroppingFolder()
        local kandang = player:GetAttribute("Ternak_Kandang")
        if typeof(kandang) ~= "string" or not kandang:match("^Kandang_%d+$") then
            return nil
        end
        local farm = workspace:FindFirstChild("TernakLokal")
        local owner = farm and farm:FindFirstChild("KotoranSaya_" .. kandang)
        return owner and owner:FindFirstChild("Kotoran")
    end

    local function findNearestDropping(root)
        local folder = getDroppingFolder()
        if not folder then return nil end
        local nearest, shortest = nil, math.huge
        local now = os.clock()
        for _, prompt in ipairs(folder:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled
            and isDroppingPrompt(prompt) then
                local ready = not lastAttempt[prompt]
                    or now - lastAttempt[prompt] >= DROPPING_RETRY
                if ready then
                    local position = getPosition(prompt)
                    if position then
                        local distance = (root.Position - position).Magnitude
                        if distance <= TRASH_RANGE and distance < shortest then
                            nearest, shortest = prompt, distance
                        end
                    end
                end
            end
        end
        return nearest
    end

    for _, object in ipairs(workspace:GetDescendants()) do
        addPrompt(object)
    end
    cleanConnect(workspace.DescendantAdded, function(object)
        if cleanAlive() then addPrompt(object) end
    end)

    cleanConnect(cleanButton.Activated, function()
        if not cleanAlive() then return end
        env.ONYX_TEST_CLEAN_ENABLED = not env.ONYX_TEST_CLEAN_ENABLED
        local active = env.ONYX_TEST_CLEAN_ENABLED
        cleanButton.Text = active and "AUTO CLEAN  [ON]" or "AUTO CLEAN  [OFF]"
        cleanButton.BackgroundColor3 = active
            and Color3.fromRGB(35, 145, 70)
            or Color3.fromRGB(145, 48, 55)
    end)

    cleanConnect(mainGui.Destroying, function()
        env.ONYX_TEST_CLEAN_RUNNING = false
        env.ONYX_TEST_CLEAN_ENABLED = false
        for _, connection in ipairs(env.ONYX_TEST_CLEAN_CONNECTIONS) do
            pcall(function() connection:Disconnect() end)
        end
        env.ONYX_TEST_CLEAN_CONNECTIONS = {}
    end)

    task.spawn(function()
        while cleanAlive() do
            task.wait(SCAN_DELAY)
            if not env.ONYX_TEST_CLEAN_ENABLED then continue end

            -- Jangan biarkan Auto Clean tambahan mengambil prompt
            -- saat Homework sedang mengatur batch sampah hingga 6.
            local homeworkButton = mainGui:FindFirstChild("HomeworkButton", true)
            if homeworkButton and homeworkButton:IsA("TextButton")
            and homeworkButton.Text:upper():find("HOMEWORK: ON", 1, true) then
                continue
            end

            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            local prompt = findNearest(root)
            local droppingPrompt = findNearestDropping(root)

            -- Pilih target kandang hanya dari folder kotoran milik pemain.
            -- Alur prompt sampah/keranjang tetap memakai perilaku sebelumnya.
            if droppingPrompt then
                local droppingPosition = getPosition(droppingPrompt)
                local normalPosition = getPosition(prompt)
                if not prompt or (droppingPosition and normalPosition
                    and (root.Position - droppingPosition).Magnitude
                    < (root.Position - normalPosition).Magnitude) then
                    prompt = droppingPrompt
                end
            end

            if prompt and env.ONYX_TEST_CLEAN_ENABLED then
                lastAttempt[prompt] = os.clock()
                activatePrompt(prompt)
                task.wait(0.1)
            end
        end
    end)
end)

if not cleanInitOK then
    onyxCleanReport("GAGAL: " .. tostring(cleanInitError):sub(1, 220))
end
