-- ONYX HUB | MAIN LOADER
-- Silent bootstrap: tidak membuat GUI status atau overlay tambahan.

pcall(function() getgenv().ONYX_HW_PATH_DIAG = "TEST LOADER V7 START" end)

local url = "https://raw.githubusercontent.com/rael-kertia/Onyx-Hub/main/onyx_hub.lua?v=homework-pathfinding-test-20261126-7"
local response = game:HttpGet(url)
assert(type(response) == "string" and #response > 10000, "ONYX HUB: core gagal diunduh")

local onyxHomeworkPathfindingMarker = "wrapper = wrapper:sub(1, at - 1) .. patch .. \"\\n\" .. wrapper:sub(at)"
local onyxHomeworkPathfindingPatch = [==[

patch = patch .. [====[
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
    [=[
local function hwMove(prompt)
    local function hwDiag(value)
        pcall(function() getgenv().ONYX_HW_PATH_DIAG = tostring(value) end)
    end
    if not alive() or not homeworkEnabled then
        hwDiag("HOMEWORK OFF / NOT ALIVE")
        return false
    end

    local root = hwRoot()
    local targetPart = hwPart(prompt)
    if not root or not targetPart then
        hwDiag("ROOT ATAU TARGET PROMPT TIDAK DITEMUKAN")
        return false
    end

    hwForceStand()
    root = hwRoot()
    if not root then return false end

    local targetPosition = targetPart.Position + Vector3.new(0, 3.5, 0)
    local distance = (root.Position - targetPosition).Magnitude
    local speed = 18 -- studs per second; berlaku untuk Bersihkan dan TrashBag
    local duration = math.max(0.15, distance / speed)
    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

    hwDiag("TWEEN MENUJU " .. tostring(prompt.ActionText)
        .. " | JARAK=" .. string.format("%.1f", distance)
        .. " | DURASI=" .. string.format("%.2f", duration))

    local tween
    local ok, err = pcall(function()
        tween = tweenService:Create(root, tweenInfo, {
            CFrame = CFrame.new(targetPosition)
        })
        tween:Play()
    end)
    if not ok or not tween then
        hwDiag("TWEEN GAGAL: " .. tostring(err))
        return false
    end

    local startedAt = os.clock()
    while alive() and homeworkEnabled and os.clock() - startedAt < duration + 2 do
        local state = tween.PlaybackState
        if state == Enum.PlaybackState.Completed then
            break
        elseif state == Enum.PlaybackState.Cancelled then
            hwDiag("TWEEN DIBATALKAN")
            return false
        end
        task.wait(0.05)
    end

    if not alive() or not homeworkEnabled then
        pcall(function() tween:Cancel() end)
        hwDiag("TWEEN DIHENTIKAN: HOMEWORK OFF")
        return false
    end

    if tween.PlaybackState ~= Enum.PlaybackState.Completed then
        pcall(function() tween:Cancel() end)
        hwDiag("TWEEN TIMEOUT / BELUM SELESAI")
        return false
    end

    hwForceStand()
    root = hwRoot()
    if not root then return false end
    local finalDistance = (root.Position - targetPosition).Magnitude
    hwDiag("TWEEN SELESAI | SISA JARAK=" .. string.format("%.2f", finalDistance))
    return finalDistance <= 5 and alive() and homeworkEnabled
end
]=],
    "local function hwUse(prompt)",
    [=[
local onyxHwComputePending = false

local function hwMove(prompt)
    local function pathDiag(value)
        pcall(function() getgenv().ONYX_HW_PATH_DIAG = tostring(value) end)
    end
    pathDiag("APPROACH PATCH V14 - TARGET HOUSE DOOR COLLISION")
    if not alive() or not homeworkEnabled then pathDiag("HOMEWORK OFF / NOT ALIVE"); return false end

    local r = hwRoot()
    local q = hwPart(prompt)
    if not r or not q then return false end

    -- TP lama tetap dipakai untuk mengambil/membuang TrashBag.
    if prompt.ActionText ~= "Bersihkan" then
        hwForceStand()
        r = hwRoot()
        if not r then return false end
        r.CFrame = CFrame.new(q.Position + Vector3.new(0, 3.5, 0))
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.15)
        hwForceStand()
        task.wait(0.15)
        hwForceStand()
        return alive() and homeworkEnabled
    end

    hwForceStand()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    r = hwRoot()
    if not humanoid or not r then return false end

    local pathService = game:GetService("PathfindingService")
    local destination = q.Position
    local houseFolder = W:FindFirstChild("KosanSpawned")
    local promptHouse = prompt
    while promptHouse and promptHouse.Parent ~= houseFolder do
        promptHouse = promptHouse.Parent
    end
    if not promptHouse or promptHouse.Parent ~= houseFolder then
        pathDiag("RUMAH TARGET PROMPT TIDAK DITEMUKAN")
        return false
    end
    -- V15: buka collision daun pintu RUMAH TARGET sebelum ComputeAsync.
    -- V14 baru menonaktifkannya setelah karakter macet, padahal path sudah
    -- dihitung saat pintu masih menjadi penghalang.
    local onyxHwTargetDoorParts = {}
    for _, part in ipairs(promptHouse:GetDescendants()) do
        if part:IsA("BasePart")
        and string.lower(part.Name) == "door"
        and part.CanCollide then
            onyxHwTargetDoorParts[part] = true
            part.CanCollide = false
        end
    end
    local onyxHwDoorsRestored = false
    local function restoreOnyxHwTargetDoors()
        if onyxHwDoorsRestored then return end
        onyxHwDoorsRestored = true
        for part in pairs(onyxHwTargetDoorParts) do
            if part and part.Parent then
                pcall(function() part.CanCollide = true end)
            end
        end
        pathDiag("COLLISION PINTU TARGET DIPULIHKAN")
    end
    if next(onyxHwTargetDoorParts) then
        local count = 0
        for _ in pairs(onyxHwTargetDoorParts) do count = count + 1 end
        pathDiag("PINTU TARGET DIBUKA SEBELUM PATH COMPUTE: " .. tostring(count) .. " PART")
        -- Beri physics satu frame untuk menerapkan perubahan collision.
        task.wait(0.25)
        -- Safety restore bila proses berhenti di tengah jalan.
        task.delay(20, restoreOnyxHwTargetDoors)
    else
        pathDiag("TIDAK ADA DAUN PINTU COLLIDABLE DI RUMAH TARGET")
    end

    local allowedDistance = math.max(prompt.MaxActivationDistance or 10, 8) + 2
    local lastPathError = "BELUM ADA KANDIDAT"

    local function makePath(targetPosition)
        if onyxHwComputePending then
            lastPathError = "COMPUTE MASIH BERJALAN DARI PERCOBAAN SEBELUMNYA"
            return nil
        end
        r = hwRoot()
        if not r then return nil end
        local startPosition = r.Position
        local path = pathService:CreatePath({
            AgentRadius = 1.5,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 3
        })
        -- ComputeAsync dapat yield lama. Jalankan terpisah dan batasi
        -- waktu tunggu agar Homework tidak terkunci pada satu kandidat.
        local completed = false
        local computed = false
        local computeError = nil
        onyxHwComputePending = true
        task.spawn(function()
            computed, computeError = pcall(function()
                path:ComputeAsync(startPosition, targetPosition)
            end)
            onyxHwComputePending = false
            completed = true
        end)

        local startedAt = os.clock()
        while not completed and os.clock() - startedAt < 3 do
            if not alive() or not homeworkEnabled then
                lastPathError = "HOMEWORK OFF SAAT COMPUTE"
                return nil
            end
            task.wait(0.05)
        end

        if not completed then
            lastPathError = "COMPUTE TIMEOUT 3S - PROSES LAMA DIBIARKAN SELESAI"
            return nil
        end
        if not computed or path.Status ~= Enum.PathStatus.Success then
            lastPathError = "NO PATH / COMPUTE ERROR: STATUS=" .. tostring(path.Status)
                .. " ERROR=" .. tostring(computeError)
            return nil
        end
        local waypoints = path:GetWaypoints()
        if #waypoints == 0 then
            lastPathError = "ZERO WAYPOINTS"
            return nil
        end
        local length = 0
        local previous = r.Position
        for _, waypoint in ipairs(waypoints) do
            length = length + (waypoint.Position - previous).Magnitude
            previous = waypoint.Position
        end
        return {path = path, waypoints = waypoints, length = length, target = targetPosition}
    end

    -- Maksimal 8 titik pendekatan: 4 arah pada radius dekat,
    -- lalu 4 arah pada radius kedua. Berhenti pada jalur valid pertama.
    -- Ini menghindari puluhan ComputeAsync sebelum karakter mulai bergerak.
    local function findApproachPath()
        local radii = {3, 6}
        local directions = {
            Vector3.new(1, 0, 0),
            Vector3.new(-1, 0, 0),
            Vector3.new(0, 0, 1),
            Vector3.new(0, 0, -1)
        }
        local checked = 0
        for _, radius in ipairs(radii) do
            for index, direction in ipairs(directions) do
                if not alive() or not homeworkEnabled then return nil end
                local candidatePosition = destination + direction * radius
                if (candidatePosition - destination).Magnitude <= allowedDistance - 1 then
                    checked = checked + 1
                    pathDiag("CEK TITIK PENDEKATAN " .. tostring(checked) .. "/8")
                    local candidatePath = makePath(candidatePosition)
                    if candidatePath then
                        pathDiag("TITIK " .. tostring(checked) .. ": SUCCESS")
                        pathDiag("TITIK PENDEKATAN VALID " .. tostring(checked) .. "/8")
                        return candidatePath
                    end
                    pathDiag("TITIK " .. tostring(checked) .. ": " .. tostring(lastPathError))
                    if lastPathError:find("TIMEOUT", 1, true)
                    or lastPathError:find("MASIH BERJALAN", 1, true) then
                        pathDiag("PENCARIAN DIHENTIKAN AGAR COMPUTE TIDAK MENUMPUK")
                        return nil
                    end
                end
            end
        end
        pathDiag("8 TITIK PENDEKATAN GAGAL")
        return nil
    end

    local function isDoorPart(part)
        if not part or not part:IsA("BasePart") then return false end
        local node = part
        for _ = 1, 5 do
            if not node then break end
            local name = string.lower(node.Name)
            if name:find("door", 1, true)
            or name:find("pintu", 1, true)
            or name:find("daunpintu", 1, true) then
                return true
            end
            node = node.Parent
        end
        return false
    end

    local function phaseDoorPartsNearSegment(fromPosition, toPosition, targetHouse)
        -- Scanner menemukan daun pintu aktual di rumah target sebagai:
        -- KosanSpawned/<rumah>/Door/Door/Door (CanCollide=true, Anchored=true).
        -- Jangan scan seluruh Workspace: hanya daun pintu di rumah prompt yang sedang dikerjakan.
        local changed = {}
        if not targetHouse or not targetHouse.Parent then return changed, 0 end
        for _, part in ipairs(targetHouse:GetDescendants()) do
            if part:IsA("BasePart")
            and part.CanCollide
            and string.lower(part.Name) == "door" then
                changed[part] = part.CanCollide
                part.CanCollide = false
            end
        end
        local count = 0
        for _ in pairs(changed) do count = count + 1 end
        return changed, count
    end

    local function restoreDoorParts(changed)
        for part, originalCanCollide in pairs(changed or {}) do
            if part and part.Parent then
                pcall(function() part.CanCollide = originalCanCollide end)
            end
        end
    end

    local function followPath(route)
        if not route then return false end
        local path = route.path
        local waypoints = route.waypoints
        pathDiag("APPROACH PATH OK; WAYPOINTS=" .. tostring(#waypoints)
            .. " LENGTH=" .. string.format("%.1f", route.length))

        local blockedAt = nil
        local blockedConnection = path.Blocked:Connect(function(index)
            blockedAt = index
        end)

        local playerScripts = player:FindFirstChild("PlayerScripts")
        local controls
        pcall(function()
            local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
            controls = playerModule:GetControls()
        end)

        for index, waypoint in ipairs(waypoints) do
            if not alive() or not homeworkEnabled then
                blockedConnection:Disconnect()
                return false
            end
            if blockedAt and blockedAt <= index then
                pathDiag("BLOCKED AT WAYPOINT " .. tostring(blockedAt) .. "/" .. tostring(index))
                blockedConnection:Disconnect()
                return false
            end

            r = hwRoot()
            if not r then
                blockedConnection:Disconnect()
                return false
            end
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            pathDiag("MOVETO WAYPOINT " .. tostring(index) .. "/" .. tostring(#waypoints))
            humanoid:MoveTo(waypoint.Position)
            local distance = (r.Position - waypoint.Position).Magnitude
            local deadline = os.clock() + math.max(6, distance / 7 + 3)
            local lastPosition = r.Position
            local lastProgressAt = os.clock()
            local lastMoveCommand = os.clock()
            local doorWaitAttempts = 0
            local phasedDoorParts = nil
            local phasedDoorCount = 0
            local phasedDoorUntil = 0

            while os.clock() < deadline do
                if not alive() or not homeworkEnabled then
                    blockedConnection:Disconnect()
                    return false
                end
                r = hwRoot()
                if not r then
                    blockedConnection:Disconnect()
                    return false
                end

                -- Input analog manual mengambil prioritas sementara. Setelah dilepas,
                -- rute dihitung ulang dari posisi karakter yang terbaru.
                local manualMove = false
                if controls then
                    pcall(function()
                        manualMove = controls:GetMoveVector().Magnitude > 0.15
                    end)
                end
                if manualMove then
                    humanoid:MoveTo(r.Position)
                    pathDiag("INPUT MANUAL - MENUNGGU ANALOG DILEPAS")
                    repeat
                        task.wait(0.15)
                        if not alive() or not homeworkEnabled then
                            blockedConnection:Disconnect()
                            return false
                        end
                        if controls then
                            local ok, moveVector = pcall(function()
                                return controls:GetMoveVector()
                            end)
                            manualMove = ok and moveVector.Magnitude > 0.15
                        else
                            manualMove = false
                        end
                    until not manualMove
                    blockedConnection:Disconnect()
                    pathDiag("ANALOG DILEPAS - HITUNG ULANG RUTE")
                    return false
                end

                if phasedDoorParts then
                    if os.clock() >= phasedDoorUntil then
                        restoreDoorParts(phasedDoorParts)
                        phasedDoorParts = nil
                        pathDiag("COLLISION PINTU DIPULIHKAN")
                    else
                        for part in pairs(phasedDoorParts) do
                            if part and part.Parent then
                                pcall(function() part.CanCollide = false end)
                            end
                        end
                    end
                end

                local remainingNow = (r.Position - waypoint.Position).Magnitude
                if remainingNow <= 3 then
                    if phasedDoorParts then restoreDoorParts(phasedDoorParts) end
                    break
                end
                if blockedAt and blockedAt <= index then
                    blockedConnection:Disconnect()
                    return false
                end

                if (r.Position - lastPosition).Magnitude >= 0.65 then
                    lastPosition = r.Position
                    lastProgressAt = os.clock()
                elseif os.clock() - lastProgressAt >= 1.8 then
                    -- Daun pintu dapat mendorong karakter saat melewati ambang.
                    -- Tunggu ayunan pintu selesai, lalu coba waypoint yang sama sekali lagi
                    -- sebelum membatalkan rute dan melakukan replan.
                    if doorWaitAttempts < 3 then
                        doorWaitAttempts = doorWaitAttempts + 1
                        if not phasedDoorParts then
                            local currentRoot = hwRoot()
                            if currentRoot then
                                phasedDoorParts, phasedDoorCount =
                                    phaseDoorPartsNearSegment(currentRoot.Position, waypoint.Position, promptHouse)
                                if phasedDoorCount > 0 then
                                    phasedDoorUntil = os.clock() + 5
                                    pathDiag("COLLISION PINTU DIMATIKAN SEMENTARA: "
                                        .. tostring(phasedDoorCount) .. " PART / 5 DETIK")
                                else
                                    pathDiag("PINTU TIDAK TERDETEKSI - CEK NAMA PART/MODEL")
                                    phasedDoorParts = nil
                                end
                            end
                        end
                        -- Sentuh pintu sebentar untuk memicu animasi bukaan,
                        -- lalu berhenti agar karakter tidak terus melawan daun pintu.
                        pathDiag("PICU PINTU " .. tostring(doorWaitAttempts) .. "/3 - WAYPOINT "
                            .. tostring(index) .. "/" .. tostring(#waypoints))
                        humanoid:MoveTo(waypoint.Position)
                        task.wait(0.35)
                        r = hwRoot()
                        if not r then
                            blockedConnection:Disconnect()
                            return false
                        end
                        humanoid:MoveTo(r.Position)
                        task.wait(2.5)
                        if not alive() or not homeworkEnabled then
                            blockedConnection:Disconnect()
                            return false
                        end
                        r = hwRoot()
                        if not r then
                            blockedConnection:Disconnect()
                            return false
                        end
                        if (r.Position - waypoint.Position).Magnitude <= 3 then
                            break
                        end
                        lastPosition = r.Position
                        lastProgressAt = os.clock()
                        lastMoveCommand = os.clock()
                        deadline = deadline + 3.5
                        humanoid:MoveTo(waypoint.Position)
                        pathDiag("SELESAI MENUNGGU PINTU - COBA LINTASI LAGI")
                    else
                        humanoid:MoveTo(r.Position)
                        if phasedDoorParts then restoreDoorParts(phasedDoorParts) end
                        pathDiag("PINTU TETAP MENGHALANG SETELAH 3 PICU - REPLAN WAYPOINT "
                            .. tostring(index) .. "/" .. tostring(#waypoints))
                        task.wait(0.65)
                        blockedConnection:Disconnect()
                        return false
                    end
                end

                if os.clock() - lastMoveCommand >= 0.8 then
                    humanoid:MoveTo(waypoint.Position)
                    lastMoveCommand = os.clock()
                end
                task.wait(0.1)
            end

            if phasedDoorParts then restoreDoorParts(phasedDoorParts) end
            r = hwRoot()
            local remaining = r and (r.Position - waypoint.Position).Magnitude or -1
            if not r or remaining > 4 then
                pathDiag("WAYPOINT TIMEOUT " .. tostring(index) .. "/" .. tostring(#waypoints)
                    .. " DIST=" .. tostring(remaining))
                blockedConnection:Disconnect()
                return false
            end
        end

        blockedConnection:Disconnect()
        r = hwRoot()
        local finalDistance = r and (r.Position - destination).Magnitude or -1
        pathDiag("APPROACH END DIST TO PROMPT=" .. tostring(finalDistance)
            .. " ALLOWED=" .. tostring(allowedDistance))
        return r ~= nil and finalDistance <= allowedDistance
    end

    --    -- Cari rute ke titik pendekatan yang dapat dicapai, lalu jalankan.
    local reached = false
    for attempt = 1, 3 do
        if not alive() or not homeworkEnabled then return false end
        pathDiag("PENCARIAN RUTE UNTUK PROMPT YANG SAMA - PERCOBAAN "
            .. tostring(attempt) .. "/3")
        local route = findApproachPath()
        if route and followPath(route) then
            reached = true
            break
        elseif route then
            pathDiag("RUTE TERHALANG - TETAP PADA PROMPT INI, COBA ULANG")
        else
            pathDiag("TITIK PENDEKATAN GAGAL: " .. tostring(lastPathError))
        end
        if attempt < 3 then task.wait(1.0) end
    end

    if not reached then
        restoreOnyxHwTargetDoors()
        pathDiag("GAGAL SETELAH 3 PERCOBAAN PADA PROMPT YANG SAMA; LAST_ERROR=" .. tostring(lastPathError))
        setStatus("PATHFINDING RUMAH TERHALANG")
        return false
    end

    restoreOnyxHwTargetDoors()
    hwForceStand()
    return alive() and homeworkEnabled
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

local onyxHwPinnedHouse = nil
local hwFindHouseOriginal = hwFindHouse
hwFindHouse = function(...)
    onyxHwDiag.findCalls = onyxHwDiag.findCalls + 1
    onyxHwDiag.lastStage = "MENCARI RUMAH"
    if onyxHwPinnedHouse then
        if onyxHwPinnedHouse.Parent == W:FindFirstChild("KosanSpawned")
        and #hwGet(onyxHwPinnedHouse, 1) > 0 then
            onyxHwDiag.lastHouse = onyxHwPinnedHouse:GetFullName() .. " (PINNED)"
            onyxHwDiag.lastStage = "MENGULANG RUMAH YANG SAMA"
            return onyxHwPinnedHouse
        end
        onyxHwPinnedHouse = nil
    end
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
    if prompt and prompt.ActionText == "Bersihkan" and (not ok or not result) then
        local folder = W:FindFirstChild("KosanSpawned")
        local house = prompt
        while house and house.Parent ~= folder do
            house = house.Parent
        end
        if house and house.Parent == folder then
            onyxHwPinnedHouse = house
            onyxHwDiag.lastHouse = house:GetFullName() .. " (PINNED AFTER PATH FAILURE)"
        end
    end
    onyxHwDiag.lastStage = "HW MOVE SELESAI"
    return ok and result or false
end

task.spawn(function()
    local reportedForEnable = false
    while alive() do
        if homeworkEnabled and not reportedForEnable then
            task.wait(7)
            if not alive() then break end
            if homeworkEnabled then
                local lines = {}
                local function add(k, v)
                    lines[#lines + 1] = k .. "=" .. tostring(v)
                end
                local folder = W:FindFirstChild("KosanSpawned")
                local houses = folder and folder:GetChildren() or {}
                local ownedCount, activeOwnedCount, inactiveOwnedCount = 0, 0, 0
                local promptCount, enabledCount = 0, 0
                add("HOMEWORK", homeworkEnabled)
                add("PLAYER_USER_ID", player.UserId)
                add("ROOT", hwRoot() and tostring(hwRoot().Position) or "NIL")
                add("KOSANSPAWNED", folder and "ADA" or "NIL")
                add("JUMLAH_INSTANCE_TOTAL", #houses)
                for _, house in ipairs(houses) do
                    local owner = house:GetAttribute("OwnerUserId")
                    local isOwned = hwOwnsHouse(house)
                    local state = house:GetAttribute("KosanState")
                    local isActiveOwned = isOwned and state == "Disewa"
                    if isOwned then ownedCount = ownedCount + 1 end
                    if isActiveOwned then
                        activeOwnedCount = activeOwnedCount + 1
                        local total, enabled = 0, 0
                        for _, obj in ipairs(house:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and obj.ActionText == "Bersihkan" then
                                total = total + 1
                                promptCount = promptCount + 1
                                if obj.Enabled then
                                    enabled = enabled + 1
                                    enabledCount = enabledCount + 1
                                end
                            end
                        end
                        add("RUMAH_AKTIF_" .. house.Name,
                            "KosanState=" .. tostring(state)
                            .. ", Bersihkan=" .. tostring(enabled) .. "/" .. tostring(total))
                    elseif isOwned then
                        inactiveOwnedCount = inactiveOwnedCount + 1
                    end
                end
                add("RUMAH_MILIK_PLAYER_TOTAL_INSTANCE", ownedCount)
                add("RUMAH_AKTIF_MILIK_PLAYER", activeOwnedCount)
                add("RUMAH_MILIK_PLAYER_TIDAK_DISewa", inactiveOwnedCount)
                add("PROMPT_BERSIHKAN_AKTIF_TOTAL", enabledCount)
                add("PROMPT_BERSIHKAN_SEMUA_RUMAH_AKTIF", promptCount)
                add("FIND_HOUSE_CALLS", onyxHwDiag.findCalls)
                add("LAST_STAGE", onyxHwDiag.lastStage)
                add("LAST_HOUSE", onyxHwDiag.lastHouse or "BELUM ADA")
                add("MOVE_CALLS", onyxHwDiag.moveCalls)
                add("LAST_MOVE", onyxHwDiag.lastMove)
                add("LAST_MOVE_RESULT", onyxHwDiag.lastMoveResult)
                add("PATH_DIAGNOSTIC", (function() local ok, value = pcall(function() return getgenv().ONYX_HW_PATH_DIAG end); return ok and tostring(value) or "UNAVAILABLE" end)())
                add("CARRYING_TRASH", hwCarrying() ~= nil)
                local report = "ONYX HOMEWORK DIAGNOSTIC\n" .. table.concat(lines, "\n")
                pcall(function()
                    if typeof(setclipboard) == "function" then setclipboard(report) end
                end)
                pcall(function() warn(report) end)
            end
            reportedForEnable = true
        elseif not homeworkEnabled then
            reportedForEnable = false
        end
        task.wait(0.5)
    end
end)
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


-- =========================================================
-- ONYX DOOR DIAGNOSTIC V1
-- Read-only: memindai part fisik di sekitar karakter.
-- Tidak mengubah collision, posisi, prompt, atau state pintu.
-- Jalankan saat berdiri di luar pintu rumah yang tertutup.
-- =========================================================
task.spawn(function()
    task.wait(2)
    local ok, err = pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        assert(root, "HumanoidRootPart tidak ditemukan")

        local center = root.Position
        local radius = 32
        local candidates = {}
        local constraints = {}
        local prompts = {}

        local function chainName(instance, maxDepth)
            local names = {}
            local node = instance
            for _ = 1, maxDepth do
                if not node then break end
                table.insert(names, 1, node.Name)
                node = node.Parent
            end
            return table.concat(names, "/")
        end

        local function positionOf(instance)
            if instance:IsA("BasePart") then return instance.Position end
            if instance:IsA("Attachment") then return instance.WorldPosition end
            if instance:IsA("ProximityPrompt") then
                local parent = instance.Parent
                if parent and parent:IsA("Attachment") then return parent.WorldPosition end
                if parent and parent:IsA("BasePart") then return parent.Position end
            end
            return nil
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local distance = (obj.Position - center).Magnitude
                if distance <= radius then
                    table.insert(candidates, {
                        instance = obj,
                        distance = distance
                    })
                end
            elseif obj:IsA("HingeConstraint")
                or obj:IsA("WeldConstraint")
                or obj:IsA("Motor6D")
                or obj:IsA("AlignPosition")
                or obj:IsA("AlignOrientation") then
                local p0, p1
                pcall(function()
                    if obj:IsA("HingeConstraint") then
                        p0 = obj.Attachment0 and obj.Attachment0.WorldPosition
                        p1 = obj.Attachment1 and obj.Attachment1.WorldPosition
                    elseif obj:IsA("WeldConstraint") then
                        p0 = obj.Part0 and obj.Part0.Position
                        p1 = obj.Part1 and obj.Part1.Position
                    elseif obj:IsA("Motor6D") then
                        p0 = obj.Part0 and obj.Part0.Position
                        p1 = obj.Part1 and obj.Part1.Position
                    end
                end)
                local d0 = p0 and (p0 - center).Magnitude or math.huge
                local d1 = p1 and (p1 - center).Magnitude or math.huge
                if math.min(d0, d1) <= radius + 8 then
                    table.insert(constraints, {
                        instance = obj,
                        distance = math.min(d0, d1),
                        p0 = p0,
                        p1 = p1
                    })
                end
            elseif obj:IsA("ProximityPrompt") then
                local pos = positionOf(obj)
                if pos and (pos - center).Magnitude <= radius + 12 then
                    table.insert(prompts, {
                        instance = obj,
                        distance = (pos - center).Magnitude,
                        position = pos
                    })
                end
            end
        end

        table.sort(candidates, function(a, b) return a.distance < b.distance end)
        table.sort(constraints, function(a, b) return a.distance < b.distance end)
        table.sort(prompts, function(a, b) return a.distance < b.distance end)

        local lines = {
            "ONYX DOOR DIAGNOSTIC V1",
            "MODE=READ ONLY - TIDAK ADA PROPERTY YANG DIUBAH",
            "PLAYER=" .. tostring(player and player.Name),
            "ROOT=" .. tostring(center),
            "SCAN_RADIUS=" .. tostring(radius),
            "BASEPART_FOUND=" .. tostring(#candidates),
            "CONSTRAINT_FOUND=" .. tostring(#constraints),
            "PROMPT_FOUND=" .. tostring(#prompts),
            "",
            "=== BASEPART TERDEKAT (MAKS 60) ==="
        }

        for i = 1, math.min(#candidates, 60) do
            local item = candidates[i]
            local part = item.instance
            local okGroup, group = pcall(function() return part.CollisionGroup end)
            local okMaterial, material = pcall(function() return tostring(part.Material) end)
            table.insert(lines,
                string.format(
                    "[PART %02d] DIST=%.1f PATH=%s POS=%s SIZE=%s COLLIDE=%s TOUCH=%s QUERY=%s ANCHORED=%s TRANSP=%.2f GROUP=%s MATERIAL=%s",
                    i, item.distance, chainName(part, 6), tostring(part.Position),
                    tostring(part.Size), tostring(part.CanCollide), tostring(part.CanTouch),
                    tostring(part.CanQuery), tostring(part.Anchored),
                    part.Transparency, okGroup and tostring(group) or "?", okMaterial and material or "?"
                )
            )
        end

        table.insert(lines, "")
        table.insert(lines, "=== CONSTRAINT TERDEKAT (MAKS 30) ===")
        for i = 1, math.min(#constraints, 30) do
            local item = constraints[i]
            table.insert(lines,
                string.format("[JOINT %02d] TYPE=%s PATH=%s DIST=%.1f ATT0/PART0=%s ATT1/PART1=%s",
                    i, item.instance.ClassName, chainName(item.instance, 6),
                    item.distance, tostring(item.p0), tostring(item.p1))
            )
        end

        table.insert(lines, "")
        table.insert(lines, "=== PROMPT TERDEKAT (MAKS 25) ===")
        for i = 1, math.min(#prompts, 25) do
            local item = prompts[i]
            local prompt = item.instance
            table.insert(lines,
                string.format("[PROMPT %02d] DIST=%.1f ACTION=%s OBJECT=%s ENABLED=%s HOLD=%.2f PATH=%s POS=%s",
                    i, item.distance, tostring(prompt.ActionText), tostring(prompt.ObjectText),
                    tostring(prompt.Enabled), prompt.HoldDuration,
                    chainName(prompt, 6), tostring(item.position))
            )
        end

        local report = table.concat(lines, "\n")
        pcall(function()
            if typeof(setclipboard) == "function" then setclipboard(report) end
        end)
        pcall(function() warn(report) end)
        pcall(function() getgenv().ONYX_DOOR_DIAG = report end)
    end)

    if not ok then
        local report = "ONYX DOOR DIAGNOSTIC ERROR: " .. tostring(err)
        pcall(function()
            if typeof(setclipboard) == "function" then setclipboard(report) end
        end)
        pcall(function() warn(report) end)
    end
end)
