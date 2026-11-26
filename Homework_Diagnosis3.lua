-- ONYX-HUB | HOMEWORK DIAGNOSIS 3 - HOUSE GEOMETRY ONLY
-- Read-only: does not move character, activate prompts, or change game state.
-- Selects the same nearest dirty owned house as Homework; falls back to nearest owned house.
local Players = game:GetService("Players")
local W = workspace
local player = Players.LocalPlayer
if not player then return end

local function rootPart()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function partOfPrompt(p)
    local x = p and p.Parent
    if not x then return nil end
    if x:IsA("BasePart") then return x end
    return x:FindFirstChildWhichIsA("BasePart", true)
end
local function housePivot(h)
    local ok, cf = pcall(function() return h:GetPivot() end)
    return ok and cf.Position or nil
end
local function owns(h)
    return tonumber(h:GetAttribute("OwnerUserId")) == player.UserId
end
local function prompts(h, includeDisabled)
    local out = {}
    for _,v in ipairs(h:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.ActionText == "Bersihkan"
        and (includeDisabled or v.Enabled) then
            table.insert(out,v)
        end
    end
    return out
end
local function selectHouse()
    local folder = W:FindFirstChild("KosanSpawned")
    local root = rootPart()
    if not folder then return nil, "KosanSpawned tidak ditemukan" end
    if not root then return nil, "HumanoidRootPart tidak ditemukan" end
    local best, bestD, mode
    for _,h in ipairs(folder:GetChildren()) do
        if owns(h) then
            for _,p in ipairs(prompts(h,false)) do
                local q = partOfPrompt(p)
                if q then
                    local d = (root.Position-q.Position).Magnitude
                    if not bestD or d<bestD then best,bestD,mode=h,d,"RUMAH KOTOR (sesuai pilihan Homework)" end
                end
            end
        end
    end
    if best then return best,mode,bestD end
    for _,h in ipairs(folder:GetChildren()) do
        if owns(h) then
            local pos=housePivot(h)
            if pos then
                local d=(root.Position-pos).Magnitude
                if not bestD or d<bestD then best,bestD=h,d end
            end
        end
    end
    if best then return best,"RUMAH SENDIRI TERDEKAT (tidak ada prompt Bersihkan aktif)",bestD end
    return nil,"Rumah milik player tidak ditemukan"
end
local function pathOf(x, stop)
    local t,n={},x
    while n and n~=stop do table.insert(t,1,n.Name); n=n.Parent end
    return table.concat(t,"/")
end
local function v3(v)
    return string.format("(%.1f, %.1f, %.1f)",v.X,v.Y,v.Z)
end
local function round(n) return math.floor(n*10+0.5)/10 end

local lines={}
local function add(s) lines[#lines+1]=tostring(s) end
add("ONYX-HUB HOMEWORK DIAGNOSIS 3 | GEOMETRI RUMAH")
add("READ ONLY | Tidak ada TP, gerakan, atau aktivasi prompt")
add("Player="..player.Name.." | UserId="..player.UserId)
local root=rootPart()
add("Posisi player="..(root and v3(root.Position) or "n/a"))
local house,selection,dist=selectHouse()
add("")
add("=== TARGET RUMAH ===")
add("Metode="..tostring(selection))
if house then
    add("Nama="..house.Name.." | Class="..house.ClassName)
    add("Pivot="..(housePivot(house) and v3(housePivot(house)) or "n/a"))
    add("Jarak="..string.format("%.1f studs",dist or 0))
    add("BoundingBox:")
    local ok,cf,size=pcall(function() return house:GetBoundingBox() end)
    if ok then add("  Center="..v3(cf.Position).." | Size="..v3(size)) end
    local ps={}
    for _,d in ipairs(house:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(ps,d) end
    end
    add("")
    add("=== RINGKASAN GEOMETRI ===")
    add("Total BasePart="..#ps)
    local collidable,noncollidable=0,0
    local floors,walls,large=0,0,0
    local minY,maxY=math.huge,-math.huge
    local levels={}
    for _,p in ipairs(ps) do
        if p.CanCollide then collidable=collidable+1 else noncollidable=noncollidable+1 end
        minY=math.min(minY,p.Position.Y-p.Size.Y/2)
        maxY=math.max(maxY,p.Position.Y+p.Size.Y/2)
        local s=p.Size
        local horizontal=(s.X>=7 and s.Z>=7 and s.Y<=2.5)
        local vertical=(s.Y>=5 and math.max(s.X,s.Z)<=3.5 and math.min(s.X,s.Z)>=0.2)
        if horizontal then floors=floors+1 end
        if vertical then walls=walls+1 end
        if s.X>=8 or s.Y>=8 or s.Z>=8 then large=large+1 end
        local band=math.floor(p.Position.Y/8+0.5)*8
        levels[band]=(levels[band] or 0)+1
    end
    add("Collidable="..collidable.." | Non-collidable="..noncollidable)
    add("Kandidat bidang lantai (lebar X/Z >=7, tebal Y <=2.5)="..floors)
    add("Kandidat tembok vertikal (tinggi Y >=5, lebar <=3.5)="..walls)
    add("Part besar (salah satu dimensi >=8)="..large)
    add("Rentang tinggi Y="..(minY<math.huge and string.format("%.1f sampai %.1f",minY,maxY) or "n/a"))
    add("Sebaran ketinggian per band 8 studs:")
    local ys={}
    for y in pairs(levels) do table.insert(ys,y) end
    table.sort(ys)
    for _,y in ipairs(ys) do add(string.format("  sekitar Y=%d : %d part",y,levels[y])) end

    add("")
    add("=== PART STRUKTURAL / PENGHALANG ===")
    add("Format: nama-path | posisi | ukuran | collision | transparency | material")
    local entries={}
    for _,p in ipairs(ps) do
        local s=p.Size
        local structural=(p.CanCollide and (s.X>=5 or s.Y>=4 or s.Z>=5))
            or (s.X>=7 and s.Z>=7 and s.Y<=3)
        if structural then
            table.insert(entries,p)
        end
    end
    table.sort(entries,function(a,b)
        if a.Position.Y~=b.Position.Y then return a.Position.Y<b.Position.Y end
        return a.Name<b.Name
    end)
    add("Part struktural terpilih="..#entries)
    for i,p in ipairs(entries) do
        if i>240 then add("... daftar dibatasi 240 part"); break end
        add(string.format("%03d | %s | pos=%s | size=%s | collide=%s | transparency=%.2f | material=%s",
            i,pathOf(p,house),v3(p.Position),v3(p.Size),tostring(p.CanCollide),p.Transparency,p.Material.Name))
    end

    add("")
    add("=== PROMPT BERSIHKAN DI RUMAH TARGET ===")
    local pp=prompts(house,true)
    add("Jumlah prompt="..#pp)
    for i,p in ipairs(pp) do
        if i>60 then add("... prompt dibatasi 60"); break end
        local q=partOfPrompt(p)
        add(string.format("%02d | %s | enabled=%s | posisi=%s",
            i,pathOf(p,house),tostring(p.Enabled),q and v3(q.Position) or "n/a"))
    end
else
    add("Rumah target tidak tersedia: "..tostring(selection))
end
add("")
add("=== CATATAN ===")
add("Kandidat lantai/tembok dihitung dari ukuran part; verifikasi nama-path dan posisi untuk membedakan dekorasi.")
add("END DIAGNOSIS 3")

local report=table.concat(lines,"\n")
local copied=false
if typeof(setclipboard)=="function" then copied=pcall(setclipboard,report)
elseif typeof(toclipboard)=="function" then copied=pcall(toclipboard,report) end

local pg=player:WaitForChild("PlayerGui")
local old=pg:FindFirstChild("HomeworkDiagnosis3Gui")
if old then old:Destroy() end
local gui=Instance.new("ScreenGui")
gui.Name="HomeworkDiagnosis3Gui"
gui.ResetOnSpawn=false
local okParent=pcall(function() gui.Parent=game:GetService("CoreGui") end)
if not okParent or not gui.Parent then gui.Parent=pg end
local frame=Instance.new("Frame")
frame.Size=UDim2.fromOffset(320,164)
frame.Position=UDim2.new(0.5,-160,0.5,-82)
frame.BackgroundColor3=Color3.fromRGB(25,28,35)
frame.BorderSizePixel=0
frame.Parent=gui
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-20,0,30)
title.Position=UDim2.fromOffset(10,5)
title.BackgroundTransparency=1
title.Text="HOMEWORK DIAGNOSIS 3"
title.TextColor3=Color3.new(1,1,1)
title.Font=Enum.Font.GothamBold
title.TextSize=14
title.Parent=frame
local status=Instance.new("TextLabel")
status.Size=UDim2.new(1,-24,0,48)
status.Position=UDim2.fromOffset(12,38)
status.BackgroundTransparency=1
status.TextWrapped=true
status.TextColor3=Color3.fromRGB(220,230,240)
status.Font=Enum.Font.Gotham
status.TextSize=12
status.Text=copied and "Peta geometri tersalin. Paste laporan ke chat." or "Clipboard tidak tersedia. Tekan SALIN ULANG."
status.Parent=frame
local function makeButton(label,x,w,color)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(w,34)
    b.Position=UDim2.fromOffset(x,112)
    b.BackgroundColor3=color
    b.Text=label
    b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold
    b.TextSize=12
    b.Parent=frame
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    return b
end
makeButton("SALIN ULANG",12,178,Color3.fromRGB(55,105,180)).MouseButton1Click:Connect(function()
    local ok=false
    if typeof(setclipboard)=="function" then ok=pcall(setclipboard,report)
    elseif typeof(toclipboard)=="function" then ok=pcall(toclipboard,report) end
    status.Text=ok and "Berhasil disalin. Paste ke chat." or "Clipboard API tidak tersedia."
end)
makeButton("TUTUP",202,106,Color3.fromRGB(85,90,100)).MouseButton1Click:Connect(function() gui:Destroy() end)
