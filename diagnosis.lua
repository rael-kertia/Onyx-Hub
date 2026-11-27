-- ONYX AUTO ACC DIAGNOSIS (READ ONLY)
local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local out = {}
local function add(s) out[#out+1] = tostring(s) end
local function amount(s)
    local n = tostring(s or ""):match("[Rr][Pp]%s*%.?%s*([%d][%d%.,]*)")
    return n and tonumber(n:gsub("[^%d]", "")) or nil
end
for _,ui in ipairs(pg:GetDescendants()) do
    if ui.Name == "PermintaanSewaUI" then
        local stack = ui:FindFirstChild("Tumpukan", true)
        if stack then
            for _,card in ipairs(stack:GetDescendants()) do
                if card.Name:match("^Kartu_%d+$") then
                    local body = card:FindFirstChild("Isi")
                    local info = body and body:FindFirstChild("Info")
                    local a = amount(info and info.Text)
                    local acc = body and body:FindFirstChild("AccBtn")
                    local tol = body and body:FindFirstChild("TolakBtn")
                    add(card.Name.." | "..tostring(info and info.Text))
                    add("Nominal="..tostring(a).." | Seharusnya="..(a and (a>20000000 and "ACC" or "TOLAK") or "SKIP"))
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
