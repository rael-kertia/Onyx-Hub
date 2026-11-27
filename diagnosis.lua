-- ONYX AUTO ACC DIAG V4 | READ ONLY
local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local out = {}
local function add(v) out[#out+1] = tostring(v) end
local function parse(s)
    local raw = tostring(s or "")
    local p = raw:lower():find("rp", 1, true)
    local tail = p and raw:sub(p + 2) or raw
    local d = tail:gsub("%D", "")
    return d ~= "" and tonumber(d) or nil, raw, d
end
local function connections(signal)
    if typeof(getconnections) ~= "function" then return nil end
    local ok, list = pcall(getconnections, signal)
    if not ok or type(list) ~= "table" then return nil end
    return list
end
local function describe(signal)
    local list = connections(signal)
    if not list then return "UNAVAILABLE" end
    local parts = {"count=" .. #list}
    for i, c in ipairs(list) do
        if i > 4 then parts[#parts+1] = "..." break end
        local fn = c.Function or c["function"]
        local src, name = "?", "?"
        if type(fn) == "function" and debug and debug.info then
            pcall(function() src = debug.info(fn, "s") or "?" end)
            pcall(function() name = debug.info(fn, "n") or "?" end)
        end
        parts[#parts+1] = "[" .. i .. "]" .. tostring(name) .. "@" .. tostring(src)
    end
    return table.concat(parts, " ")
end
add("ONYX AUTO ACC DIAG V4")
add("READ_ONLY=true")
add("getconnections=" .. tostring(typeof(getconnections)))
local count = 0
for _, ui in ipairs(pg:GetDescendants()) do
    if ui.Name == "PermintaanSewaUI" then
        local stack = ui:FindFirstChild("Tumpukan", true)
        if stack then
            for _, card in ipairs(stack:GetDescendants()) do
                if card.Name:match("^Kartu_%d+$") then
                    local body = card:FindFirstChild("Isi")
                    local info = body and body:FindFirstChild("Info", true)
                    local amount, raw, digits = parse(info and info.Text)
                    local expected = amount and (amount > 20000000 and "AccBtn" or "TolakBtn") or "SKIP"
                    local acc = body and body:FindFirstChild("AccBtn", true)
                    local tol = body and body:FindFirstChild("TolakBtn", true)
                    count += 1
                    add("")
                    add(card.Name .. " | " .. raw)
                    add("DIGITS=" .. digits .. " | AMOUNT=" .. tostring(amount) .. " | EXPECTED=" .. expected)
                    for _, pair in ipairs({{"ACC",acc},{"TOLAK",tol}}) do
                        local label, btn = pair[1], pair[2]
                        if btn and btn:IsA("GuiButton") then
                            add(label .. " name=" .. btn.Name .. " visible=" .. tostring(btn.Visible) .. " active=" .. tostring(btn.Active))
                            add(label .. " Activated: " .. describe(btn.Activated))
                            add(label .. " MouseButton1Click: " .. describe(btn.MouseButton1Click))
                        else
                            add(label .. " BUTTON_MISSING_OR_NOT_GUIBUTTON")
                        end
                    end
                    add("SELECTED_BUTTON_EXISTS=" .. tostring(expected == "AccBtn" and acc ~= nil or expected == "TolakBtn" and tol ~= nil))
                end
            end
        end
    end
end
add("")
add("CARD_COUNT=" .. count)
if count == 0 then add("NO_CARDS_FOUND") end
local report = table.concat(out, "\n")
if typeof(setclipboard) == "function" then pcall(setclipboard, report) end
warn(report)
