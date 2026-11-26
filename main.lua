-- ONYX HUB | MAIN LOADER
-- Tidak membuat GUI/status panel tambahan.
local url = "https://raw.githubusercontent.com/rael-kertia/Onyx-Hub/main/onyx_hub.lua?v=onyx-cache-refresh-20261126g"

local ok, err = pcall(function()
    local response = game:HttpGet(url)
    assert(type(response) == "string" and #response > 10000,
        "CORE TIDAK TERUNDUH / RESPONSE KOSONG")

    local chunk, compileError = loadstring(response)
    assert(type(chunk) == "function",
        "KOMPILASI CORE GAGAL: " .. tostring(compileError))

    chunk()
end)

if not ok then
    local report = "ONYX LOADER ERROR: " .. tostring(err)
    pcall(function()
        if typeof(setclipboard) == "function" then
            setclipboard(report)
        end
    end)
    pcall(function() warn(report) end)
end
