-- ONYX AUTO ACC DIAG V3 | READ ONLY
local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local out = {}
local function add(v) out[#out+1] = tostring(v) end
local function digits(s)
    return (tostring(s or ""):gsub("%D", ""))
end
local function parse(s)
    s = tostring(s or "")
    local lower = s:lower()
    local p = lower:find("rp", 1, true)
    local tail = p and s:sub(p + 2) or s
    local d = digits(tail)
    if d == "" then return nil, tail, d end
    return tonumber(d), tail, d
end

add("ONYX AUTO ACC DIAG V3")
add("MODE=READ_ONLY")
local found = 0
for _, ui in ipairs(pg:GetDescendants()) do
    if ui.Name == "PermintaanSewaUI" then
        local stack = ui:FindFirstChild("Tumpukan", true)
        if stack then
            for _, card in ipairs(stack:GetDescendants()) do
                if card.Name:match("^Kartu_%d+$") then
                    local body = card:FindFirstChild("Isi")
                    local info = body and body:FindFirstChild("Info", true)
                    local value = info and info.Text
                    local amount, tail, digitText = parse(value)
                    local acc = body and body:FindFirstChild("AccBtn", true)
                    local tol = body and body:FindFirstChild("TolakBtn", true)
                    found += 1
                    add("")
                    add(card.Name .. " | InfoClass=" .. tostring(info and info.ClassName))
                    add("RAW=" .. string.format("%q", value))
                    add("RAW_LEN=" .. tostring(value and #value))
                    add("AFTER_RP=" .. string.format("%q", tail))
                    add("DIGITS=" .. digitText .. " | AMOUNT=" .. tostring(amount))
                    add("DECISION=" .. (amount and (amount > 20000000 and "ACC" or "TOLAK") or "SKIP"))
                    add("ACC_EXISTS=" .. tostring(acc ~= nil) .. " | TOLAK_EXISTS=" .. tostring(tol ~= nil))
                end
            end
        end
    end
end
add("")
add("CARD_COUNT=" .. found)
if found == 0 then add("Tidak ada kartu ditemukan pada PermintaanSewaUI/Tumpukan.") end
local report = table.concat(out, "\n")
if typeof(setclipboard) == "function" then
    local ok = pcall(setclipboard, report)
    add("CLIPBOARD=" .. tostring(ok))
    report = table.concat(out, "\n")
end
warn(report)
