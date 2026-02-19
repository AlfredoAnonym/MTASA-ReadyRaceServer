-- server.lua
local mapQueue = {}
local matchStats = {}
local roundStats = {} 

local teamNames = { [1] = (Config and Config.TeamNames[1]) or "Team 1", [2] = (Config and Config.TeamNames[2]) or "Team 2" }
local teamTags = { [1] = (Config and Config.TeamTags[1]) or "T1", [2] = (Config and Config.TeamTags[2]) or "T2" }
local defCol1 = (Config and Config.DefaultColors and Config.DefaultColors[1]) or "#FF3232"
local defCol2 = (Config and Config.DefaultColors and Config.DefaultColors[2]) or "#3264FF"
local teamColors = { [1] = defCol1, [2] = defCol2 }
local teamLogos = { [1] = (Config and Config.TeamLogos[1]) or "placeholder", [2] = (Config and Config.TeamLogos[2]) or "placeholder" }
local teamCaptains = { [1] = nil, [2] = nil } 
local captainReady = { [1] = false, [2] = false } 

local currentMode = (Config and Config.DefaultMode) or "Classic"
local roundLimit = (Config and Config.RoundLimit) or 10
local currentRound = 0 
local isCWActive = false 
local isMatchPaused = false 
local isTechPause = false 
local interruptedMap = nil 
local scores = {0, 0}
local checkpointRanks = {} 
local teamElements = { [1] = nil, [2] = nil, [3] = nil }

-- Block Vote Manager
addEventHandler("onPollStarting", root, function() if isCWActive then cancelEvent() end end)
addEventHandler("onPollStart", root, function() if isCWActive then cancelEvent() end end)

function hexToRGB(hex)
    if not hex then return 255, 255, 255 end
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)) or 255, tonumber("0x"..hex:sub(3,4)) or 255, tonumber("0x"..hex:sub(5,6)) or 255
end

function applyTeamColor(player)
    if not isCWActive then return end
    local teamID = getElementData(player, "cw.team")
    if teamID == 1 or teamID == 2 then
        local r, g, b = hexToRGB(teamColors[teamID])
        local vehicle = getPedOccupiedVehicle(player)
        if vehicle then setVehicleColor(vehicle, r, g, b, r, g, b, r, g, b, r, g, b) end
        setPlayerNametagColor(player, r, g, b)
    else
        setPlayerNametagColor(player, 255, 255, 255)
    end
end

----------------------------------------------------
-- MANUAL FAIL-SAFE: SAVE & LOAD SYSTEM (F2)
----------------------------------------------------
addEvent("onAdminSaveMatch", true)
addEventHandler("onAdminSaveMatch", root, function(filename)
    if not isCWActive then outputChatBox("Match not active, nothing to save.", client, 255, 50, 50); return end
    if not filename or filename == "" then filename = "match_auto" end
    filename = filename .. ".txt"
    
    local data = {
        active = isCWActive,
        scores = scores,
        names = teamNames,
        tags = teamTags,
        colors = teamColors,
        logos = teamLogos,
        round = currentRound,
        limit = roundLimit,
        mode = currentMode,
        queue = mapQueue,
        stats = matchStats
    }
    local file = fileCreate(filename)
    if file then
        fileWrite(file, toJSON(data))
        fileClose(file)
        outputChatBox("#2ecc71[CW] #ffffffMatch Saved to: #ffff00" .. filename, root, 255, 255, 255, true)
    end
end)

addEvent("onAdminLoadMatch", true)
addEventHandler("onAdminLoadMatch", root, function(filename)
    if not filename or filename == "" then return end
    filename = filename .. ".txt"
    
    if fileExists(filename) then
        local file = fileOpen(filename)
        if file then
            local content = fileRead(file, fileGetSize(file))
            fileClose(file)
            local data = fromJSON(content)
            if data and data.active then
                isCWActive = true
                scores = data.scores or {0,0}
                teamNames = data.names
                teamTags = data.tags
                teamColors = data.colors
                teamLogos = data.logos
                currentRound = data.round
                roundLimit = data.limit
                currentMode = data.mode
                mapQueue = data.queue or {}
                matchStats = data.stats or {}
                
                -- Recreate Teams
                if isElement(teamElements[1]) then destroyElement(teamElements[1]) end
                if isElement(teamElements[2]) then destroyElement(teamElements[2]) end
                if isElement(teamElements[3]) then destroyElement(teamElements[3]) end

                local r1, g1, b1 = hexToRGB(teamColors[1])
                local r2, g2, b2 = hexToRGB(teamColors[2])
                teamElements[1] = createTeam(teamNames[1], r1, g1, b1)
                teamElements[2] = createTeam(teamNames[2], r2, g2, b2)
                teamElements[3] = createTeam("Spectators", 255, 255, 255)
                
                outputChatBox("#2ecc71[CW] #ffffffMatch Loaded from " .. filename, root, 255, 255, 255, true)
                outputChatBox("#2ecc71[CW] #ffffffPlease rejoin your teams (F3)!", root, 255, 255, 255, true)
                updateClientHUD()
            end
        end
    else
        outputChatBox("Save file not found.", client, 255, 50, 50)
    end
end)

----------------------------------------------------
-- SPECTATOR ENFORCEMENT (FIXED LOOP)
----------------------------------------------------
function forceSpectatorMode(player)
    if not isElement(player) then return end
    
    -- Prevent repeat calls if already spectating
    if getElementData(player, "state") == "spectating" and getPlayerTeam(player) == teamElements[3] then
        return
    end

    -- 1. Move to spectators team
    if teamElements[3] and getPlayerTeam(player) ~= teamElements[3] then
        setPlayerTeam(player, teamElements[3])
    end
    
    -- 2. Kill only if alive (This prevents the loop if called from onPlayerSpawn where cancelEvent handles the rest)
    if not isPedDead(player) then
        setElementHealth(player, 0) 
    end
    
    removePedFromVehicle(player)
    
    -- 3. Set Race State
    setElementData(player, "state", "spectating")
    
    -- 4. FORCE CAMERA SWITCH (Directly tell Race resource to start spectating)
    -- This fixes "player dies but doesn't spectate"
    triggerClientEvent(player, "onClientCall_race", resourceRoot, "Spectate.start", "manual")
    
    -- 5. Trigger local client backup
    triggerClientEvent(player, "onSpectateRequest", root)
    triggerClientEvent(player, "onForceClientSpectate", player)
end

-- Prevent Respawning for Spectators (Fixed Stack Overflow)
addEventHandler("onPlayerSpawn", root, function()
    if not isCWActive then return end
    local teamID = getElementData(source, "cw.team")
    -- If match is running and player is NOT in team 1 or 2
    if (teamID == 3 or teamID == 0) and currentRound > 0 and not isTechPause then
        cancelEvent() -- STOP the spawn physically
        
        -- Just ensure state is correct WITHOUT killing (breaking the loop)
        setElementData(source, "state", "spectating")
        if teamElements[3] then setPlayerTeam(source, teamElements[3]) end
        
        -- Force spectate camera again in case they are stuck on "Dead" screen
        triggerClientEvent(source, "onClientCall_race", resourceRoot, "Spectate.start", "manual")
        triggerClientEvent(source, "onSpectateRequest", root)
    end
end)

function killToSpectate(player)
    forceSpectatorMode(player)
end

addEventHandler("onRaceStateChanging", root, function(newState)
    if not isCWActive then return end
    
    if newState == "GridCountdown" then
        checkpointRanks = {} 
        for _, player in ipairs(getElementsByType("player")) do
             local teamID = getElementData(player, "cw.team") or 0
             if teamID == 1 or teamID == 2 then
                 setElementData(player, "state", "alive")
                 applyTeamColor(player)
             elseif teamID == 3 or teamID == 0 then
                 -- Setup for spectate: freeze and prepare
                 setElementData(player, "state", "spectating") 
                 local veh = getPedOccupiedVehicle(player)
                 if veh then setElementFrozen(veh, true) end
             end
        end

    elseif newState == "Running" then
        -- 1. Immediate Check
        for _, player in ipairs(getElementsByType("player")) do
            local teamID = getElementData(player, "cw.team") or 0
            if teamID ~= 1 and teamID ~= 2 then
                forceSpectatorMode(player)
            else
                applyTeamColor(player)
            end
        end
        
        -- 2. REPEATED CHECKS (Timer to catch respawns/glitches)
        setTimer(function()
            if not isCWActive then return end
            for _, player in ipairs(getElementsByType("player")) do
                local teamID = getElementData(player, "cw.team") or 0
                if teamID ~= 1 and teamID ~= 2 then
                    forceSpectatorMode(player)
                end
            end
        end, 1000, 1) 
        
        setTimer(function()
            if not isCWActive then return end
            for _, player in ipairs(getElementsByType("player")) do
                local teamID = getElementData(player, "cw.team") or 0
                if teamID ~= 1 and teamID ~= 2 then
                    forceSpectatorMode(player)
                end
            end
        end, 3000, 1) 
    end
end)

addEventHandler("onPlayerVehicleEnter", root, function() applyTeamColor(source) end)

addEventHandler("onPlayerReachCheckpoint", root, function(cpID, time)
    if not isCWActive then return end
    applyTeamColor(source)
    if currentMode == "PlayerL" and currentRound > 0 and not isTechPause and not isMatchPaused then
        local tID = getPlayerTeamID(source)
        if tID == 1 or tID == 2 then
            local currentRankForCP = (checkpointRanks[cpID] or 0) + 1
            checkpointRanks[cpID] = currentRankForCP
            local pointSystem = (Config and Config.PointSystem) or {[1]=15}
            local pts = pointSystem[currentRankForCP] or 0
            if pts > 0 then 
                scores[tID] = scores[tID] + pts
                addMatchPoints(source, pts)
                updateClientHUD() 
            end
        end
    end
end)

function setupScoreboard()
    local sb = getResourceFromName("scoreboard")
    if sb and getResourceState(sb) == "running" then
        call(sb, "scoreboardAddColumn", "Points", root, 60, "Points", 5)
    end
end
addEventHandler("onResourceStart", resourceRoot, setupScoreboard)
addEventHandler("onResourceStart", root, function(res) if getResourceName(res) == "scoreboard" then setupScoreboard() end end)

function stripHex(name)
    return name:gsub("#%x%x%x%x%x%x", "")
end

function getPlayerFromPartialName(name)
    if not name then return nil end
    local searchName = stripHex(name):lower()
    
    for _, player in ipairs(getElementsByType("player")) do
        local playerName = stripHex(getPlayerName(player)):lower()
        if playerName:find(searchName, 1, true) then
            return player
        end
    end
    return nil
end

function setCaptain(teamID, partialName)
    local target = getPlayerFromPartialName(partialName)
    if target then
        teamCaptains[teamID] = target
        outputChatBox("#3498db[CW] #ffffff" .. getPlayerName(target) .. " is now Captain of " .. teamNames[teamID], root, 255, 255, 255, true)
    else
        outputChatBox("#e74c3c[CW] #ffffffCould not find player: " .. partialName, root, 255, 255, 255, true)
    end
end

function updateClientHUD()
    local caps = { [1] = (isElement(teamCaptains[1]) and getPlayerName(teamCaptains[1])) or "", [2] = (isElement(teamCaptains[2]) and getPlayerName(teamCaptains[2])) or "" }
    triggerClientEvent("updateCWHUD", root, teamNames, scores, teamTags, teamColors, teamLogos, currentMode, currentRound, roundLimit, isCWActive, mapQueue, isTechPause, caps)
end

function getPlayerTeamID(player) return getElementData(player, "cw.team") or 0 end

function addMatchPoints(player, points)
    if currentRound < 1 or isTechPause or isMatchPaused then return end
    local serial = getPlayerSerial(player)
    local name = stripHex(getPlayerName(player))
    local current = (matchStats[serial] and matchStats[serial].points) or 0
    matchStats[serial] = { name = name, points = current + points, teamID = getPlayerTeamID(player) }
    setElementData(player, "Points", matchStats[serial].points)
    roundStats[serial] = (roundStats[serial] or 0) + points
end

addEventHandler("onPlayerFinish", root, function(rank, time)
    if not isCWActive or currentRound == 0 or isTechPause then return end
    if currentMode == "Classic" then
        local pts = 0
        local pointSystem = (Config and Config.PointSystem) or {[1]=15}
        pts = pointSystem[rank] or 0
        if pts > 0 then
            local tID = getPlayerTeamID(source)
            if tID == 1 or tID == 2 then 
                scores[tID] = scores[tID] + pts
                addMatchPoints(source, pts)
                updateClientHUD()
            end
        end
    end
end)

local function changeMap(mapName)
    local mapRes = getResourceFromName(mapName)
    local raceRes = getResourceFromName("race")
    local mapManager = getResourceFromName("mapmanager")
    if mapRes and raceRes and mapManager then
        checkpointRanks = {} -- RESET CHECKPOINT RANKS ON MAP CHANGE
        call(mapManager, "changeGamemodeMap", mapRes, raceRes)
    else
        outputChatBox("#e74c3c[CW] #ffffffError loading map: " .. tostring(mapName), root, 255, 255, 255, true)
    end
end

local function getRaceMaps()
    local maps = {}
    for _, res in ipairs(getResources()) do
        local type = getResourceInfo(res, "type")
        local gamemodes = getResourceInfo(res, "gamemodes")
        if type == "map" and gamemodes and string.find(string.lower(gamemodes), "race") then
            local resName = getResourceName(res)
            if not string.find(resName, "^editor_") and not string.find(resName, "^test_") then
                 local friendly = getResourceInfo(res, "name") or resName
                 if friendly == resName then friendly = friendly:gsub("^race%-", "") end
                 table.insert(maps, {resName = resName, displayName = friendly})
            end
        end
    end
    return maps
end

function startWarmup()
    local maps = getRaceMaps()
    if #maps > 0 then
        local randomIndex = math.random(1, #maps)
        currentRound = 0 
        isTechPause = false
        isMatchPaused = true 
        roundStats = {} 
        checkpointRanks = {} -- Clear old data
        updateClientHUD()
        outputChatBox("#3498db[CW] #ffffffStarting Warmup Map: #ffff00" .. maps[randomIndex].displayName, root, 255, 255, 255, true)
        changeMap(maps[randomIndex].resName)
        setTimer(function() if isCWActive and currentRound == 0 then outputChatBox("#3498db[CW] #ffffffWarmup Active. Captains, type #ffff00/rd #ffffffwhen ready!", root, 255, 255, 255, true) end end, 15000, 1)
    end
end

function startNextQueuedMap()
    if interruptedMap then
        outputChatBox("#3498db[CW] #ffffffResuming Interrupted Map: #ffff00" .. interruptedMap, root, 255, 255, 255, true)
        changeMap(interruptedMap)
        interruptedMap = nil; isTechPause = false; isMatchPaused = false; updateClientHUD()
        return
    end
    if #mapQueue > 0 then
        local nextMapData = table.remove(mapQueue, 1)
        currentRound = currentRound + 1
        isTechPause = false; isMatchPaused = false; 
        roundStats = {} -- Reset round MVP stats
        checkpointRanks = {} -- Reset playerL stats
        updateClientHUD() 
        outputChatBox("#3498db[CW] #ffffffStarting Match Round "..currentRound.."/"..roundLimit..": #ffff00" .. nextMapData.displayName, root, 255, 255, 255, true)
        changeMap(nextMapData.resName)
    else
        outputChatBox("#e74c3c[CW] #ffffffQueue is empty! Pausing match.", root, 255, 255, 255, true)
        isMatchPaused = true; updateClientHUD()
    end
end

function checkReadyStart()
    if isCWActive and captainReady[1] and captainReady[2] then
        outputChatBox("#3498db[CW] #ffffffBOTH CAPTAINS READY! STARTING...", root, 255, 255, 255, true)
        captainReady = {[1]=false, [2]=false}
        startNextQueuedMap()
    end
end

function exportMatchStats()
    local fileName = (Config and Config.ExportFileName) or "cw_match_results.txt"
    if fileExists(fileName) then fileDelete(fileName) end
    local winner = "Draw!"
    if scores[1] > scores[2] then winner = teamNames[1] .. " wins!"
    elseif scores[2] > scores[1] then winner = teamNames[2] .. " wins!" end
    local exportContent = string.format("--- Clan War Results (%s) ---\n%s vs %s\nScore: %d:%d\n%s\n\n", os.date("%Y-%m-%d %H:%M:%S"), teamNames[1], teamNames[2], scores[1], scores[2], winner)
    for serial, stats in pairs(matchStats) do
        local teamTag = stats.teamID == 1 and teamTags[1] or (stats.teamID == 2 and teamTags[2] or "[SPEC]")
        exportContent = exportContent .. string.format("%s %s: %d Points\n", teamTag, stats.name, stats.points)
    end
    local file = fileCreate(fileName)
    if file then fileWrite(file, exportContent); fileClose(file) end
    outputChatBox("#2ecc71[CW] #ffffffStats exported to: #ffff00" .. fileName, root, 255, 255, 255, true)
end

function stopClanWar(shouldExport)
    if not isCWActive then return end
    if shouldExport then exportMatchStats() end
    outputChatBox(string.format("#e74c3c[CW] #ffffffMATCH ENDED. Score: %d:%d", scores[1], scores[2]), root, 255, 255, 255, true)
    isCWActive = false; isMatchPaused = false; isTechPause = false
    captainReady = { [1] = false, [2] = false }; mapQueue = {} 
    if isElement(teamElements[1]) then destroyElement(teamElements[1]) end
    if isElement(teamElements[2]) then destroyElement(teamElements[2]) end
    if isElement(teamElements[3]) then destroyElement(teamElements[3]) end
    teamElements = {nil, nil, nil}
    for _, player in ipairs(getElementsByType("player")) do
        setPlayerNametagColor(player, 255, 255, 255)
        local veh = getPedOccupiedVehicle(player)
        if veh then setVehicleColor(veh, math.random(0,255), math.random(0,255), math.random(0,255)) end
    end
    updateClientHUD()
end

function startClanWar()
    if isCWActive then return end
    isCWActive = true; currentRound = 0; isTechPause = false; scores = {0, 0}; matchStats = {}
    for _, player in ipairs(getElementsByType("player")) do setElementData(player, "cw.team", 0); setElementData(player, "Points", 0); setPlayerTeam(player, nil) end
    local r1, g1, b1 = hexToRGB(teamColors[1]); local r2, g2, b2 = hexToRGB(teamColors[2])
    teamElements[1] = createTeam(teamNames[1], r1, g1, b1)
    teamElements[2] = createTeam(teamNames[2], r2, g2, b2)
    teamElements[3] = createTeam("Spectators", 255, 255, 255) 
    updateClientHUD()
    triggerClientEvent("showTeamJoinGUI", root)
    isMatchPaused = true
    outputChatBox("#3498db[CW] #ffffffMATCH INITIALIZED. Starting Warmup.", root, 255, 255, 255, true)
    startWarmup()
end

addEvent("onPostFinish", true)
addEventHandler("onPostFinish", root, function()
    if not isCWActive then return end
    if isTechPause then return end
    
    outputChatBox(string.format("#3498db[CW] #ffffffRound Result: %s %d - %d %s", teamNames[1], scores[1], scores[2], teamNames[2]), root, 255, 255, 255, true)
    local bestPlayer, bestPts = nil, -1
    for serial, pts in pairs(roundStats) do
        if pts > bestPts then
            bestPts = pts
            bestPlayer = matchStats[serial] and matchStats[serial].name
        end
    end
    if bestPlayer and bestPts > 0 then
         outputChatBox("#3498db[CW] #ffffffRound MVP: #ffff00" .. bestPlayer .. " (" .. bestPts .. " pts)", root, 255, 255, 255, true)
    end
    
    if currentRound == 0 then outputChatBox("#3498db[CW] #ffffffWarmup Finished. Reloading Warmup in 5s...", root, 255, 255, 255, true); setTimer(startWarmup, 5000, 1); return end
    if currentRound >= roundLimit then outputChatBox("#3498db[CW] #ffffffRound Limit Reached! Ending Match...", root, 255, 255, 255, true); setTimer(stopClanWar, 1000, 1, true); return end
    if #mapQueue > 0 then
        outputChatBox("#3498db[CW] #ffffffRound Ended. Next Map: #ffff00" .. mapQueue[1].displayName, root, 255, 255, 255, true)
        outputChatBox("#3498db[CW] #ffffffWaiting for Captains (#ffff00/rd#ffffff)!", root, 255, 255, 255, true)
        isMatchPaused = true; captainReady = {[1]=false, [2]=false}
    else
        outputChatBox("#e74c3c[CW] #ffffffQueue empty. Paused.", root, 255, 255, 255, true)
        isMatchPaused = true
    end
    updateClientHUD()
end)

addCommandHandler("rd", function(player)
    if not isCWActive then return end
    local teamID = getPlayerTeamID(player)
    if teamCaptains[teamID] == player then
        if currentRound == 0 or isMatchPaused or isTechPause then
            if not captainReady[teamID] then
                captainReady[teamID] = true
                outputChatBox("#2ecc71[CW] #ffffff" .. teamNames[teamID] .. " is READY!", root, 255, 255, 255, true)
                checkReadyStart()
            end
        else
            outputChatBox("Match is live. Cannot use /rd now.", player, 255, 50, 50)
        end
    end
end)

addCommandHandler("nr", function(player)
    if not isCWActive then return end
    local teamID = getPlayerTeamID(player)
    if teamCaptains[teamID] == player and captainReady[teamID] then
        captainReady[teamID] = false
        outputChatBox("#e74c3c[CW] #ffffff" .. teamNames[teamID] .. " is NOT READY!", root, 255, 255, 255, true)
    end
end)

addCommandHandler("tech", function(player)
    if isObjectInACLGroup("user."..getAccountName(getPlayerAccount(player)), aclGetGroup("Admin")) then
        if isCWActive and not isTechPause then
            local currentMapRes = call(getResourceFromName("mapmanager"), "getRunningGamemodeMap")
            if currentMapRes then interruptedMap = getResourceName(currentMapRes) end
            local maps = getRaceMaps()
            if #maps > 0 then
                isTechPause = true; isMatchPaused = true; updateClientHUD()
                checkpointRanks = {} -- RESET POINTS TRACKER
                roundStats = {} -- RESET ROUND STATS
                outputChatBox("#e74c3c[CW] #ffffffTECHNICAL PAUSE.", root, 255, 255, 255, true)
                changeMap(maps[math.random(1, #maps)].resName)
                setTimer(function() if isTechPause then outputChatBox("#e74c3c[CW] #ffffffTech Pause Active. Captains use /rd to resume.", root, 255, 255, 255, true) end end, 5000, 1)
            end
        end
    end
end)

addEvent("checkAdminForWelcome", true)
addEventHandler("checkAdminForWelcome", root, function()
    local acc = getPlayerAccount(client)
    if not isGuestAccount(acc) and isObjectInACLGroup("user."..getAccountName(acc), aclGetGroup("Admin")) then
        outputChatBox("#3498db[CW] #ffffffAdmin detected. Press #ffff00F2 #fffffffor Clan War Controls.", client, 255, 255, 255, true)
    end
end)

addEvent("onAdminApplySettings", true)
addEventHandler("onAdminApplySettings", root, function(data)
    teamNames[1], teamNames[2] = data.t1name, data.t2name
    teamTags[1], teamTags[2] = data.t1tag, data.t2tag
    teamColors[1], teamColors[2] = data.c1, data.c2
    teamLogos[1], teamLogos[2] = data.l1, data.l2
    roundLimit = tonumber(data.rounds) or 10
    currentRound = tonumber(data.currentRnd) or currentRound
    currentMode = data.mode
    -- Apply Manual Score Edits
    scores[1] = tonumber(data.score1) or scores[1]
    scores[2] = tonumber(data.score2) or scores[2]
    
    if data.cap1 and data.cap1 ~= "" then setCaptain(1, data.cap1) end
    if data.cap2 and data.cap2 ~= "" then setCaptain(2, data.cap2) end
    if isCWActive then
        local r1, g1, b1 = hexToRGB(teamColors[1]); local r2, g2, b2 = hexToRGB(teamColors[2])
        if teamElements[1] then setTeamName(teamElements[1], teamNames[1]); setTeamColor(teamElements[1], r1, g1, b1) end
        if teamElements[2] then setTeamName(teamElements[2], teamNames[2]); setTeamColor(teamElements[2], r2, g2, b2) end
        for _, p in ipairs(getElementsByType("player")) do applyTeamColor(p) end
        updateClientHUD()
    end
    outputChatBox("#3498db[CW] #ffffffSettings applied.", client, 255, 255, 255, true)
end)

addEvent("onAdminStartCW", true)
addEventHandler("onAdminStartCW", root, function(data) triggerEvent("onAdminApplySettings", client, data); startClanWar() end)

addEvent("onAdminStartQueuedMap", true)
addEventHandler("onAdminStartQueuedMap", root, function(index)
    if not isCWActive then return end
    if mapQueue[index] then
        local selectedMapData = table.remove(mapQueue, index); table.insert(mapQueue, 1, selectedMapData)
        interruptedMap = nil; captainReady = {[1]=false, [2]=false}; startNextQueuedMap()
    end
end)

addEvent("onAdminStopCW", true); addEventHandler("onAdminStopCW", root, function() stopClanWar(true) end)
addEvent("onAdminAddMap", true); addEventHandler("onAdminAddMap", root, function(mapRes, mapName) table.insert(mapQueue, {resName = mapRes, displayName = mapName}); updateClientHUD() end)
addEvent("onAdminRemoveMap", true); addEventHandler("onAdminRemoveMap", root, function(index) if mapQueue[index] then table.remove(mapQueue, index); updateClientHUD() end end)
addEvent("requestMapList", true); addEventHandler("requestMapList", root, function() triggerClientEvent(client, "receiveMapList", client, getRaceMaps()) end)
addEvent("onPlayerRequestJoinTeam", true); addEventHandler("onPlayerRequestJoinTeam", root, function(teamID)
    if not isCWActive then return end
    if teamID == 1 or teamID == 2 then
        setElementData(client, "cw.team", teamID); setPlayerTeam(client, teamElements[teamID]); outputChatBox("#3498db[CW] #ffffffJoined " .. teamNames[teamID], client, 255, 255, 255, true); applyTeamColor(client)
    else
        setElementData(client, "cw.team", 3); setPlayerTeam(client, teamElements[3]); outputChatBox("#3498db[CW] #ffffffJoined Spectators", client, 255, 255, 255, true); setPlayerNametagColor(client, 255, 255, 255)
        local raceRes = getResourceFromName("race")
        if raceRes and getResourceState(raceRes) == "running" then killToSpectate(client) end
    end
end)

addEventHandler("onPlayerJoin", root, function() updateClientHUD(); setElementData(source, "cw.team", 0); setElementData(source, "Points", 0) end)