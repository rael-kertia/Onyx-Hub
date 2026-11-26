-- Onyx-Hub | Homework Diagnosis 2
-- Read-only. Inspects house ownership metadata and nearby dirt/trash object names.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local char = player and player.Character
local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
local origin = root and root.Position or Vector3.zero
local function posOf(x)
    if not x then return nil end
    if x:IsA("BasePart") then return x.Position end
    if x:IsA("Model") then
        local ok, cf = pcall(function() return x:GetPivot() end)
        if ok then return cf.Position end
    end
    local p = x:FindFirstChildWhichIsA("BasePart", true)
    return p and p.Position
end
local function v3(v) return v and string.format("%.1f, %.1f, %.1f",v.X,v.Y,v.Z) or "n/a" end
local function pathOf(x)
    local t, n = {}, x
    for _=1,6 do if not n then break end table.insert(t,1,n.Name) n=n.Parent end
    return table.concat(t,"/")
end
local lines = {}
local function add(s) table.insert(lines,tostring(s)) end
add("ONYX-HUB HOMEWORK DIAGNOSIS 2")
add("Player name="..tostring(player.Name).." | UserId="..tostring(player.UserId))
add("Character position="..v3(origin))
add("")

local folder = Workspace:FindFirstChild("KosanSpawned")
add("=== KOSANSPAWNED ROOT ===")
add("Found="..tostring(folder~=nil))
if folder then
    add("Direct children="..#folder:GetChildren())
    local houses={}
    for _,h in ipairs(folder:GetChildren()) do
        local p=posOf(h)
        local d=p and (p-origin).Magnitude or math.huge
        if d<140 then table.insert(houses,{h=h,p=p,d=d}) end
    end
    table.sort(houses,function(a,b) return a.d<b.d end)
    add("House models within 140 studs="..#houses)
    for i,item in ipairs(houses) do
        if i>35 then add("... capped at 35 nearby houses"); break end
        local h=item.h
        add("")
        add(string.format("HOUSE %02d | %s | class=%s | pivot=%s | dist=%.1f",i,pathOf(h),h.ClassName,v3(item.p),item.d))
        local attrs=h:GetAttributes()
        for k,v in pairs(attrs) do add("  ATTRIBUTE "..tostring(k).."="..tostring(v).." ("..typeof(v)..")") end
        local valueCount=0
        for _,d in ipairs(h:GetDescendants()) do
            if d:IsA("ValueBase") then
                valueCount=valueCount+1
                if valueCount<=35 then add("  VALUE "..pathOf(d).."="..tostring(d.Value).." ("..d.ClassName..")") end
            end
        end
        add("  ValueBase descendants="..valueCount)
        local promptCount=0
        for _,d in ipairs(h:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                promptCount=promptCount+1
                if promptCount<=35 then
                    add(string.format("  PROMPT %s | action=%s | object=%s | enabled=%s | at=%s",
                        pathOf(d),tostring(d.ActionText),tostring(d.ObjectText),tostring(d.Enabled),v3(posOf(d.Parent))))
                end
            end
        end
        add("  Prompt count="..promptCount)
    end
end

add("")
add("=== NEARBY DIRT/TRASH CANDIDATES ===")
local keys={"dirt","kotor","sampah","trash","bag","debu","bersih","clean","limbah"}
local candidates={}
for _,d in ipairs(Workspace:GetDescendants()) do
    local name=string.lower(d.Name)
    local hit=false
    for _,k in ipairs(keys) do if string.find(name,k,1,true) then hit=true break end end
    if hit then
        local p=posOf(d)
        if p and (p-origin).Magnitude<=220 then
            table.insert(candidates,{x=d,p=p,dist=(p-origin).Magnitude})
        end
    end
end
table.sort(candidates,function(a,b) return a.dist<b.dist end)
add("Matching instances within 220 studs="..#candidates)
for i,item in ipairs(candidates) do
    if i>160 then add("... candidate list capped at 160"); break end
    local d=item.x
    local detail=""
    if d:IsA("BasePart") then detail=" | size="..v3(d.Size).." | collide="..tostring(d.CanCollide) end
    if d:IsA("ProximityPrompt") then detail=" | action="..tostring(d.ActionText).." | enabled="..tostring(d.Enabled) end
    add(string.format("%03d | %s | class=%s | pos=%s | dist=%.1f%s",i,pathOf(d),d.ClassName,v3(item.p),item.dist,detail))
end

add("")
add("=== PROMPTS IN ALL NEARBY KOSAN HOUSES ===")
if folder then
    local count=0
    for _,h in ipairs(folder:GetChildren()) do
        local p=posOf(h)
        if p and (p-origin).Magnitude<=140 then
            for _,d in ipairs(h:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    count=count+1
                    if count<=120 then
                        add(string.format("%03d | house=%s | prompt=%s | action=%s | enabled=%s | pos=%s",
                            count,h.Name,pathOf(d),tostring(d.ActionText),tostring(d.Enabled),v3(posOf(d.Parent))))
                    end
                end
            end
        end
    end
    add("Total nearby house prompts="..count)
end
add("")
add("END OF DIAGNOSIS 2")

local report=table.concat(lines,"\n")
local copied=false
if typeof(setclipboard)=="function" then copied=pcall(setclipboard,report)
elseif typeof(toclipboard)=="function" then copied=pcall(toclipboard,report) end

local gui=Instance.new("ScreenGui")
gui.Name="HomeworkDiagnosis2Gui"
gui.ResetOnSpawn=false
pcall(function() gui.Parent=game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent=player:WaitForChild("PlayerGui") end
local frame=Instance.new("Frame")
frame.Size=UDim2.fromOffset(330,170)
frame.Position=UDim2.new(0.5,-165,0.5,-85)
frame.BackgroundColor3=Color3.fromRGB(25,28,35)
frame.BorderSizePixel=0
frame.Parent=gui
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-20,0,32)
title.Position=UDim2.fromOffset(10,5)
title.BackgroundTransparency=1
title.Text="HOMEWORK DIAGNOSIS 2"
title.TextColor3=Color3.new(1,1,1)
title.Font=Enum.Font.GothamBold
title.TextSize=14
title.Parent=frame
local status=Instance.new("TextLabel")
status.Size=UDim2.new(1,-24,0,48)
status.Position=UDim2.fromOffset(12,40)
status.BackgroundTransparency=1
status.TextWrapped=true
status.TextColor3=Color3.fromRGB(215,225,240)
status.Font=Enum.Font.Gotham
status.TextSize=12
status.Text=copied and "Laporan diagnosis 2 tersalin. Paste ke chat." or "Clipboard gagal otomatis. Tekan SALIN ULANG."
status.Parent=frame
local function button(label,x,w)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(w,36)
    b.Position=UDim2.fromOffset(x,105)
    b.BackgroundColor3=Color3.fromRGB(55,105,180)
    b.Text=label
    b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold
    b.TextSize=12
    b.Parent=frame
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    return b
end
button("SALIN ULANG",12,180).MouseButton1Click:Connect(function()
    local ok=false
    if typeof(setclipboard)=="function" then ok=pcall(setclipboard,report)
    elseif typeof(toclipboard)=="function" then ok=pcall(toclipboard,report) end
    status.Text=ok and "Berhasil disalin. Paste ke chat." or "Clipboard API tidak tersedia."
end)
local close=button("TUTUP",202,116)
close.BackgroundColor3=Color3.fromRGB(85,90,100)
close.MouseButton1Click:Connect(function() gui:Destroy() end)
print("Homework Diagnosis 2 complete; clipboard="..tostring(copied))
