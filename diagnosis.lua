-- ONYX AUTO ACC DIAGNOSTIC (READ ONLY)
local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local out = {}
local function add(s) out[#out+1] = tostring(s) end

local function inspect(value)
    local raw = tostring(value or "")
    -- Extract the final numeric group, which is the displayed rental price.
    local cleaned = raw:gsub("%s+$", "")
    local token = cleaned:match("([%d][%d%.,]*)$")
    local digits = token and token:gsub("[^%d]", "") or ""
    local number = digits ~= "" and tonumber(digits) or nil

    -- Show exact bytes around the visible Rp marker to expose hidden characters.
    local lower = raw:lower()
    local pos = lower:find("r", 1, true)
    local bytes = {}
    if pos then
        for i = pos, math.min(#raw, pos + 15) do
            bytes[#bytes+1] = string.byte(raw, i)
        end
    end
    return number, raw, token, table.concat(bytes, ",")
end

for _,ui in ipairs(pg:GetDescendants()) do
    if ui.Name == "PermintaanSewaUI" then
        local stack = ui:FindFirstChild("Tumpukan", true)
        if stack then
            for _,card in ipairs(stack:GetDescendants()) do
                if card.Name:match("^Kartu_%d+$") then
                    local body = card:FindFirstChild("Isi")
                    local info = body and body:FindFirstChild("Info")
                    local a, raw, token, bytes = inspect(info and info.Text)
                    local acc = body and body:FindFirstChild("AccBtn")
                    local tol = body and body:FindFirstChild("TolakBtn")
                    add(card.Name.." | "..raw)
                    add("RawQuoted="..string.format("%q", raw))
                    add("PriceToken="..tostring(token).." | Nominal="..tostring(a))
                    add("BytesAroundR="..bytes)
                    add("Seharusnya="..(a and (a>20000000 and "ACC" or "TOLAK") or "SKIP"))
                    add("AccBtn="..tostring(acc~=nil).." | TolakBtn="..tostring(tol~=nil))
                end
            end
        end
    end
end
if #out==0 then add("UI/kartu permintaan sewa tidak ditemukan.") end
local report="ONYX AUTO ACC DIAGNOSIS\n"..table.concat(out,"\n")
if typeof(setclipboard)=="function" then pcall(setclipboard,report) end
warn(report)
