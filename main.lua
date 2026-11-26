-- ONYX HUB | MAIN LOADER | VISIBLE DIAGNOSTIC
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "OnyxLoaderDiagnostic"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100000
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(1, -24, 0, 86)
panel.Position = UDim2.fromOffset(12, 12)
panel.BackgroundColor3 = Color3.fromRGB(17, 48, 62)
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 9)

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 1, -12)
label.Position = UDim2.fromOffset(10, 6)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.TextWrapped = true
label.TextSize = 13
label.Font = Enum.Font.GothamBold
label.Text = "ONYX: LOADER AKTIF - MENUNGGU CORE"
label.Parent = panel

local function status(message, failed)
    label.Text = "ONYX: " .. tostring(message)
    panel.BackgroundColor3 = failed
        and Color3.fromRGB(85, 24, 30)
        or Color3.fromRGB(17, 48, 62)
    if failed then
        pcall(function()
            if typeof(setclipboard) == "function" then
                setclipboard("ONYX LOADER ERROR: " .. tostring(message))
            end
        end)
    end
end

local ok, err = pcall(function()
    status("MENGUNDUH CORE...", false)
    local url = "https://raw.githubusercontent.com/rael-kertia/Onyx-Hub/main/onyx_hub.lua?v=onyx-cache-refresh-20261126f"
    local response = game:HttpGet(url)
    assert(type(response) == "string" and #response > 10000,
        "CORE TIDAK TERUNDUH / RESPONSE KOSONG")
    status("CORE TERUNDUH (" .. #response .. " BYTES), KOMPILASI...", false)
    local chunk, compileError = loadstring(response)
    assert(type(chunk) == "function",
        "KOMPILASI CORE GAGAL: " .. tostring(compileError))
    status("CORE DIJALANKAN...", false)
    chunk()
    status("CORE SELESAI DIPANGGIL. CEK GUI ONYX.", false)

    -- Setelah GUI utama Onyx muncul, bersihkan kedua GUI diagnostik.
    task.delay(2, function()
        pcall(function()
            local currentPlayerGui = player:FindFirstChildOfClass("PlayerGui")
            if not currentPlayerGui then return end

            local loaderDiagnostic = currentPlayerGui:FindFirstChild("OnyxLoaderDiagnostic")
            if loaderDiagnostic then loaderDiagnostic:Destroy() end

            local coreDiagnostic = currentPlayerGui:FindFirstChild("OnyxBootDiagnostic")
            if coreDiagnostic then coreDiagnostic:Destroy() end
        end)
    end)
end)

if not ok then
    status("GAGAL: " .. tostring(err):sub(1, 260), true)
end

-- Cleanup final: jalankan terlepas dari hasil pcall, karena GUI Onyx
-- dapat sudah tampil meskipun panel diagnostik lama masih tertinggal.
task.delay(3, function()
    pcall(function()
        local currentPlayerGui = player:FindFirstChildOfClass("PlayerGui")
        if not currentPlayerGui then return end
        for _, guiName in ipairs({
            "OnyxLoaderDiagnostic",
            "OnyxBootDiagnostic"
        }) do
            local diagnostic = currentPlayerGui:FindFirstChild(guiName)
            if diagnostic then diagnostic:Destroy() end
        end
    end)
end)
