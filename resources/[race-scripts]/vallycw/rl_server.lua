-- Settings
local teams = {}
local rounds = 10
local c_round = 0
local f_round = false
local isLeagueMode = false

-- State
local mapQueue = {}
local warmupState = false
local isWarmupMap = false 
local isTechPause = false
local isWarEnded = false
local techLocked = false 
local techLockTimer = nil 
local checkpointRanks = {} 
local leagueTimer = nil
local leagueTimerDuration = 60000 
local carColorTimer = nil
local isManualMapLoad = false 
local reminderTimer = nil
local currentMapWinner = nil

-- Point Tracking
local roundScores = {} -- Tracks points for the CURRENT round only
local roundEndedProcessDone = false
local leagueRoundStartScores = {}

-- Personnel
local captain1 = nil
local captain2 = nil
local referee = nil
local readyStatus = {t1 = false, t2 = false}

-----------------
-- CANCEL VOTEMANAGER
-----------------
addEvent("onPollStarting")
addEventHandler("onPollStarting", root, function()
    if isElement(teams[1]) then
        cancelEvent()
    end
end)

-----------------
-- RPC Helper
-----------------
addEvent("onClientCallsServerFunction", true)
addEventHandler("onClientCallsServerFunction", resourceRoot, function(funcname, ...)
    local args = {...}
    if funcname == "requestMapList" then
        sendMapList(client)
    elseif funcname == "addMapToQueue" then
        if isAdmin(client) then table.insert(mapQueue, args[1]) end
    elseif funcname == "removeMapFromQueue" then
        if isAdmin(client) then 
            for i,v in ipairs(mapQueue) do 
                if v == args[1] then table.remove(mapQueue, i) break end 
            end
        end
    elseif funcname == "destroyTeams" then
        destroyTeams(client)
    elseif funcname == "forceEndMatch" then
        if isAdmin(client) then finishWar() end
    elseif funcname == "setReferee" then
        if isAdmin(client) then setReferee(args[1]) end
    elseif funcname == "setCaptains" then
        if isAdmin(client) then setCaptains(args[1], args[2]) end
    elseif funcname == "adminUpdateScores" then
        if isAdmin(client) then
            local t1s_new = tonumber(args[1]) or 0
            local t2s_new = tonumber(args[2]) or 0
            local cr_new = tonumber(args[3]) or 0
            local mr_new = tonumber(args[4]) or rounds

            local cr_old = c_round
            local mr_old = rounds
            
            c_round = cr_new
            rounds = mr_new
            
            local changes = {}
            if cr_old ~= cr_new then table.insert(changes, "Round: "..cr_old.." -> "..c_round) end
            if mr_old ~= mr_new then table.insert(changes, "MaxRounds: "..mr_old.." -> "..rounds) end
            
            -- If match has NOT started yet, apply round updates and broadcast
            if not isElement(teams[1]) then
                if #changes > 0 then
                    outputChatBox("[RL] Admin Updated Stats: " .. table.concat(changes, " | "), root, 255, 150, 0)
                else
                    outputChatBox("[RL] Admin updated stats (No changes detected).", client, 255, 150, 0)
                end
                return 
            end

            -- Match is active, process team points
            local t1s_old = tonumber(getElementData(teams[1], "Score")) or 0
            local t2s_old = (isElement(teams[2]) and tonumber(getElementData(teams[2], "Score"))) or 0

            setElementData(teams[1], "Score", t1s_new)
            if isElement(teams[2]) then setElementData(teams[2], "Score", t2s_new) end
            
            if t1s_old ~= t1s_new then table.insert(changes, "T1: "..t1s_old.." -> "..t1s_new) end
            if isElement(teams[2]) and t2s_old ~= t2s_new then table.insert(changes, "T2: "..t2s_old.." -> "..t2s_new) end
            
            if not isLeagueMode then
                for i, p in ipairs(getElementsByType("player")) do
                    local s = tonumber(getElementData(p, "Score")) or 0
                    setElementData(p, "Pts/Round", string.format("%.2f", s / math.max(1, c_round)))
                end
            end
            
            if #changes > 0 then
                outputChatBox("[RL] Admin Updated Stats: " .. table.concat(changes, " | "), root, 255, 150, 0)
            else
                outputChatBox("[RL] Admin updated stats (No changes detected).", client, 255, 150, 0)
            end
            
            syncClients()
        end
    elseif funcname == "forceStartMatch" then
        if isAdmin(client) then forceStartMatchLogic(client) end
    end
end)

-----------------
-- CORE LOGIC
-----------------
function isAdmin(player)
    if not isElement(player) then return false end
    if referee and getPlayerName(player) == referee then return true end
    
    local acc = getPlayerAccount(player)
    if not isGuestAccount(acc) then
        local accName = getAccountName(acc)
        if isObjectInACLGroup("user."..accName, aclGetGroup("Admin")) then
            return true
        end
    end
    return false
end

-- Helper to find player ignoring HEX codes
function getPlayerFromPartialName(name)
    local name = name and name:gsub("#%x%x%x%x%x%x", ""):lower() or ""
    if name == "" then return false end
    for i, player in ipairs(getElementsByType("player")) do
        local playerName = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
        if playerName:find(name, 1, true) then
            return player
        end
    end
    return false
end

addEvent("checkAdminAccess", true)
addEventHandler("checkAdminAccess", root, function()
    triggerClientEvent(client, "openAdminPanel", client, isAdmin(client))
    if isAdmin(client) then
        triggerClientEvent(client, "syncMapQueue", resourceRoot, mapQueue)
    end
end)

addEvent("onClientJoinGame", true)
addEventHandler("onClientJoinGame", root, function()
    if isAdmin(client) then
        outputChatBox("[RL] Welcome Admin! Press F2 for Clanwar Panel.", client, 0, 255, 0)
    end
    if isElement(teams[1]) then syncClients() end
end)

-- TEAM MANAGEMENT
addEvent("requestStartWar", true)
addEventHandler("requestStartWar", root, function(t1n, t2n, r1, g1, b1, r2, g2, b2, league, max_rounds, isForce)
    if not isAdmin(client) then return end
    
    if league then
        t1n = "Player League"
        captain1 = nil
        captain2 = nil
        outputChatBox("[RL] Captains auto-cleared for League Mode.", client, 255, 150, 0)
    else
        if not captain1 or captain1 == "" or not captain2 or captain2 == "" then
            outputChatBox("[RL] Cannot start match: Captains must be assigned first!", client, 255, 0, 0)
            return
        end
    end
    
    if isElement(teams[1]) then destroyElement(teams[1]) end
    if isElement(teams[2]) then destroyElement(teams[2]) end
    if isElement(teams[3]) then destroyElement(teams[3]) end
    if isTimer(leagueTimer) then killTimer(leagueTimer) end
    if isTimer(carColorTimer) then killTimer(carColorTimer) end
    if isTimer(techLockTimer) then killTimer(techLockTimer) end 
    
    isLeagueMode = league
    teams[1] = createTeam(t1n, r1, g1, b1)
    
    if not isLeagueMode then
        teams[2] = createTeam(t2n, r2, g2, b2)
        setElementData(teams[2], "Score", 0)
    end
    
    teams[3] = createTeam('Spectators', 200, 200, 200)
    
    rounds = max_rounds
    c_round = 0
    isWarEnded = false
    isTechPause = false
    techLocked = false 
    warmupState = not isForce
    isWarmupMap = warmupState 
    isManualMapLoad = false
    readyStatus = {t1 = false, t2 = false}
    
    exports.scoreboard:scoreboardAddColumn("Score")
    exports.scoreboard:scoreboardAddColumn("Maps Won")
    exports.scoreboard:scoreboardAddColumn("Maps Played") 
    
    if not isLeagueMode then
        exports.scoreboard:scoreboardAddColumn("Pts/Round")
    end
    
    syncClients()
    
    for i,p in ipairs(getElementsByType("player")) do
        setPlayerTeam(p, teams[3])
        setElementData(p, "Score", 0)
        setElementData(p, "Maps Won", 0) 
        setElementData(p, "Maps Played", 0) 
        if not isLeagueMode then setElementData(p, "Pts/Round", 0) end
        triggerClientEvent(p, "createGUI", p, t1n, t2n, isLeagueMode)
    end
    
    setElementData(teams[1], "Score", 0)
    
    outputChatBox("[RL] Match Initialized! Mode: "..(league and "Player League" or "Classic"), root, 0, 255, 0)
    outputChatBox("Press F1 to hide / show clanwar scoreboard.", root, 255, 255, 255)
    
    if isLeagueMode then
        if isForce then
            outputChatBox("[RL] League Match Force Started! Warmup skipped.", root, 0, 255, 0)
            loadNextMap()
        else
            leagueTimer = setTimer(function()
                warmupState = false
                outputChatBox("[RL] WARMUP ENDED - STARTING LEAGUE MATCH!", root, 0, 255, 0)
                loadNextMap()
            end, leagueTimerDuration, 1)
            loadRandomMap()
        end
    else
        startReminderLoop() 
        if isForce then
            outputChatBox("[RL] Clanwar Force Started! Warmup skipped.", root, 0, 255, 0)
            readyStatus.t1 = true
            readyStatus.t2 = true
            loadNextMap()
        else
            loadRandomMap()
        end
    end

    startCarColorEnforcement()
end)

addEvent("onPlayerRequestTeam", true)
addEventHandler("onPlayerRequestTeam", root, function(team)
    if not isElement(team) and isElement(teams[3]) then
        team = teams[3]
    end

    if isElement(team) then
        setPlayerTeam(client, team)
        outputChatBox(getPlayerName(client).." joined "..getTeamName(team), root, 200, 200, 200)
    end
end)

function destroyTeams(player)
    if player and not isAdmin(player) then return end
    if isTimer(leagueTimer) then killTimer(leagueTimer) end
    if isTimer(carColorTimer) then killTimer(carColorTimer) end
    if isTimer(techLockTimer) then killTimer(techLockTimer) end 
    stopReminderLoop() 
    
    isLeagueMode = false
    
    for i,p in ipairs(getElementsByType("player")) do
        local v = getPedOccupiedVehicle(p)
        if v then setVehicleColor(v, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255) end
    end
    
    for k,t in pairs(teams) do
        if isElement(t) then destroyElement(t) end
    end
    teams = {}
    mapQueue = {}
    exports.scoreboard:scoreboardRemoveColumn("Score")
    exports.scoreboard:scoreboardRemoveColumn("Maps Won")
    exports.scoreboard:scoreboardRemoveColumn("Maps Played") 
    exports.scoreboard:scoreboardRemoveColumn("Pts/Round")   
    syncClients()
end

function syncClients()
    local f_disp = warmupState or (c_round == 0)
    local remain = 0
    if isLeagueMode and isTimer(leagueTimer) then
        remain = getTimerDetails(leagueTimer)
    end
    for i,p in ipairs(getElementsByType("player")) do
        triggerClientEvent(p, "updateClientData", p, teams[1], teams[2] or false, teams[3], c_round, rounds, f_disp, isLeagueMode, remain, isTechPause)
    end
end

-----------------
-- GAMEPLAY LOGIC
-----------------
local leaguePoints = {15, 13, 11, 9, 7, 5, 4, 3, 2, 1}

addEvent("onPlayerReachCheckpoint", true)
addEventHandler("onPlayerReachCheckpoint", root, function(cp, time)
    if not isLeagueMode or isWarmupMap or getPlayerTeam(source) == teams[3] then return end
    
    if not checkpointRanks[cp] then checkpointRanks[cp] = 0 end
    checkpointRanks[cp] = checkpointRanks[cp] + 1
    
    local rank = checkpointRanks[cp]
    local pts = leaguePoints[rank] or 0
    
    if pts > 0 then
        local cur = tonumber(getElementData(source, "Score")) or 0
        local newScore = cur + pts
        setElementData(source, "Score", newScore)
        roundScores[source] = (roundScores[source] or 0) + pts
    end
end)

addEventHandler("onPlayerFinish", root, function(rank, time)
    if not isElement(teams[1]) or isWarmupMap then return end
    if getPlayerTeam(source) == teams[3] then return end
    
    local mapsPlayed = tonumber(getElementData(source, "Maps Played")) or 0
    setElementData(source, "Maps Played", mapsPlayed + 1)
    
    local rankNum = tonumber(rank) or 0
    
    if rankNum == 1 then
        local mapsWon = tonumber(getElementData(source, "Maps Won")) or 0
        setElementData(source, "Maps Won", mapsWon + 1)
        currentMapWinner = getPlayerName(source)
    end
    
    local pts = leaguePoints[rankNum] or 0
    
    if not isLeagueMode then
        local curP = tonumber(getElementData(source, "Score")) or 0
        local newScore = curP + pts
        setElementData(source, "Score", newScore)
        roundScores[source] = (roundScores[source] or 0) + pts
        
        local tm = getPlayerTeam(source)
        if tm then
            local curT = tonumber(getElementData(tm, "Score")) or 0
            setElementData(tm, "Score", curT + pts)
            outputChatBox("[RL] "..getPlayerName(source).." finished #"..rankNum.." for "..getTeamName(tm).." (+"..pts..")", root, 255, 255, 0)
        end
        
        setElementData(source, "Pts/Round", string.format("%.2f", newScore / math.max(1, c_round)))
    else
        -- League Mode Finish Logic (Scoreboard + Points)
        local cur = tonumber(getElementData(source, "Score")) or 0
        local newScore = cur + pts
        setElementData(source, "Score", newScore)
        
        roundScores[source] = (roundScores[source] or 0) + pts
        
        outputChatBox("[RL] "..getPlayerName(source).." finished #"..rank.." (+"..pts..")", root, 255, 255, 0)
    end
end)

addEvent('onMapStarting', true)
addEventHandler('onMapStarting', root, function()
    roundEndedProcessDone = false
    checkpointRanks = {} 
    currentMapWinner = nil
    techLocked = false
    roundScores = {} 
    if isTimer(techLockTimer) then killTimer(techLockTimer) end 
    
    isWarmupMap = warmupState
    
    if not isWarmupMap then
        if isManualMapLoad then
            c_round = c_round + 1
            if isLeagueMode then
                leagueRoundStartScores = {}
                for i, p in ipairs(getElementsByType("player")) do
                    leagueRoundStartScores[p] = tonumber(getElementData(p, "Score")) or 0
                end
            end
        else
            if isLeagueMode then
                for i, p in ipairs(getElementsByType("player")) do
                    local baseScore = leagueRoundStartScores[p] or 0
                    setElementData(p, "Score", baseScore)
                end
                outputChatBox("[RL] Map restarted. Player League scores for this round reset.", root, 255, 150, 0)
            end
        end
    end
    
    isManualMapLoad = false 
    syncClients()
end)

-----------------
-- MAP / QUEUE
-----------------
function sendMapList(client)
    local maps = {}
    for i, res in ipairs(getResources()) do
        if getResourceInfo(res, "type") == "map" and getResourceInfo(res, "gamemodes") == "race" then
            local name = getResourceInfo(res, "name") or getResourceName(res)
            table.insert(maps, name)
        end
    end
    triggerClientEvent(client, "receiveMapList", resourceRoot, maps)
end

function getMapResource(mapName)
    local res = getResourceFromName(mapName)
    if res and (getResourceInfo(res, "name") or getResourceName(res)) == mapName then 
        return res 
    end
    
    for i, r in ipairs(getResources()) do
        local n = getResourceInfo(r, "name") or getResourceName(r)
        if n == mapName then return r end
    end
    return nil
end

function loadNextMap()
    if #mapQueue > 0 then
        local mapName = table.remove(mapQueue, 1)
        local resToLoad = getMapResource(mapName)
        
        if resToLoad then
            isManualMapLoad = true 
            exports.mapmanager:changeGamemodeMap(resToLoad)
        else
            outputChatBox("[RL] Queued map '"..tostring(mapName).."' not found. Loading random map.", root, 255, 150, 0)
            loadRandomMap()
        end
    else
        loadRandomMap()
    end
end

function loadRandomMap()
    if not warmupState then isManualMapLoad = true end
    
    local maps = {}
    for i, res in ipairs(getResources()) do
        if getResourceInfo(res, "type") == "map" and getResourceInfo(res, "gamemodes") == "race" then
            local friendlyName = getResourceInfo(res, "name")
            local resName = getResourceName(res)
            local mapNameToCheck = friendlyName or resName
            
            -- RIGOROUS QUEUE CHECK
            -- Ensures that maps currently in the queue are NOT selected as random warmup maps
            local inQueue = false
            for _, qMap in ipairs(mapQueue) do
                if qMap == friendlyName or qMap == resName or qMap == mapNameToCheck then 
                    inQueue = true 
                    break 
                end
            end
            
            if not inQueue then
                table.insert(maps, res)
            end
        end
    end
    
    if #maps > 0 then
        local rnd = maps[math.random(#maps)]
        exports.mapmanager:changeGamemodeMap(rnd)
    end
end

-----------------
-- COMMANDS & UTILS
-----------------
addEventHandler("onPlayerCommand", root, function(command)
    if command == "redo" and techLocked and isAdmin(source) then
        outputChatBox("[RL] /redo is locked for this round! (More than 10s passed since GO)", source, 255, 0, 0)
        cancelEvent()
    end
end)

addCommandHandler("rd", function(p)
    if isLeagueMode then
        outputChatBox("[RL] Use of /rd is disabled in Player League mode.", p, 255, 0, 0)
        return
    end
    if not warmupState then return end

    if #mapQueue == 0 and c_round == 0 and not isTechPause then
        outputChatBox("[RL] Cannot start match: Map Queue is empty!", p, 255, 0, 0)
        return
    end
    
    local name = getPlayerName(p)
    local isCap = false
    
    if name == captain1 then 
        readyStatus.t1 = true 
        outputChatBox("[RL] Captain 1 ("..name..") is READY!", root, 0, 255, 0)
        isCap = true
    end
    if name == captain2 then 
        readyStatus.t2 = true 
        outputChatBox("[RL] Captain 2 ("..name..") is READY!", root, 0, 255, 0)
        isCap = true
    end
    
    if isCap and readyStatus.t1 and readyStatus.t2 then
        local wasTechPause = isTechPause
        warmupState = false
        isTechPause = false 
        outputChatBox("[RL] BOTH TEAMS READY - STARTING MATCH!", root, 0, 255, 0)
        
        loadNextMap()
    end
end)

function forceStartMatchLogic(adminPlayer)
    if isAdmin(adminPlayer) then
        if isTimer(leagueTimer) then killTimer(leagueTimer) end
        readyStatus.t1 = true; readyStatus.t2 = true
        
        local wasTechPause = isTechPause
        warmupState = false
        isTechPause = false
        outputChatBox("[RL] Admin forced start - STARTING MATCH!", root, 0, 255, 0)
        
        loadNextMap()
    end
end

addCommandHandler("forcerd", function(p) forceStartMatchLogic(p) end)
addCommandHandler("forcestart", function(p) forceStartMatchLogic(p) end)

addCommandHandler("playerpts", function(player, cmd, targetName, amount)
    if not isAdmin(player) then return end
    if not targetName or not amount then
        outputChatBox("Syntax: /playerpts [nick] [amount]", player, 255, 255, 0)
        return
    end
    
    local target = getPlayerFromPartialName(targetName)
    if target then
        local pts = tonumber(amount) or 0
        setElementData(target, "Score", pts)
        
        if not isLeagueMode then
            setElementData(target, "Pts/Round", string.format("%.2f", pts / math.max(1, c_round)))
        end
        
        outputChatBox("[RL] Set "..getPlayerName(target):gsub("#%x%x%x%x%x%x", "").."'s Score to "..pts, player, 0, 255, 0)
    else
        outputChatBox("[RL] Player '"..targetName.."' not found.", player, 255, 0, 0)
    end
end)

addCommandHandler("mvp", function(player, cmd, targetName, teamName)
    if not isAdmin(player) then return end
    if not targetName or not teamName then
        outputChatBox("Syntax: /mvp [nick] [t1/t2/spec]", player, 255, 255, 0)
        return
    end
    
    local target = getPlayerFromPartialName(targetName)
    if target then
        local teamToJoin = nil
        local tName = teamName:lower()
        if tName == "t1" and isElement(teams[1]) then teamToJoin = teams[1]
        elseif tName == "t2" and isElement(teams[2]) then teamToJoin = teams[2]
        elseif tName == "spec" and isElement(teams[3]) then teamToJoin = teams[3]
        end

        if teamToJoin then
            setPlayerTeam(target, teamToJoin)
            outputChatBox("[RL] Moved " .. getPlayerName(target):gsub("#%x%x%x%x%x%x", "") .. " to " .. getTeamName(teamToJoin), root, 0, 255, 0)
        else
            outputChatBox("[RL] Invalid or inactive team. Use t1, t2, or spec.", player, 255, 0, 0)
        end
    else
        outputChatBox("[RL] Player '"..targetName.."' not found.", player, 255, 0, 0)
    end
end)

addEventHandler("onRaceStateChanging", root, function(newState, oldState)
    if newState == "GridCountdown" then
        techLocked = false
        if isTimer(techLockTimer) then killTimer(techLockTimer) end
        
    elseif newState == "Running" then
        techLocked = false 
        if isTimer(techLockTimer) then killTimer(techLockTimer) end
        
        if isElement(teams[1]) and not isLeagueMode and not warmupState then
            techLockTimer = setTimer(function() 
                techLocked = true 
                outputChatBox("[RL] Tech Pause & Redo are now LOCKED for this round.", root, 150, 150, 150)
            end, 10000, 1)
        end
        
        for i,p in ipairs(getElementsByType("player")) do
            if getPlayerTeam(p) == teams[3] then
                triggerClientEvent(p, "onSpectateRequest", p)
            end
        end
        
    elseif newState == "PostFinish" then
        if isElement(teams[1]) and not warmupState then
            if not roundEndedProcessDone then
                roundEndedProcessDone = true
                
                if c_round <= rounds then
                    -- 1. Calculate Round MVP
                    local r_best_player = nil
                    local r_best_score = -1
                    for p, score in pairs(roundScores) do
                        if isElement(p) and score > r_best_score then
                            r_best_score = score
                            r_best_player = p
                        end
                    end
                    
                    local r_mvp_name = "None"
                    if r_best_player then r_mvp_name = getPlayerName(r_best_player) end
                    if r_best_score == -1 then r_best_score = 0 end

                    outputChatBox("[RL] Round "..c_round.." MVP: "..r_mvp_name.." ("..r_best_score.." pts)", root, 0, 255, 0)

                    if isLeagueMode then
                        local players = getElementsByType("player")
                        table.sort(players, function(a,b) 
                            return (tonumber(getElementData(a, "Score") or 0) > tonumber(getElementData(b, "Score") or 0)) 
                        end)
                        if players[1] then
                            local t_score = getElementData(players[1], "Score") or 0
                            outputChatBox("[RL] Overall Leader: "..getPlayerName(players[1]).." ("..t_score.." pts total)", root, 255, 200, 0)
                        end
                    else
                        local t1n = getTeamName(teams[1])
                        local t2n = isElement(teams[2]) and getTeamName(teams[2]) or "T2"
                        local s1 = tonumber(getElementData(teams[1], "Score")) or 0
                        local s2 = isElement(teams[2]) and tonumber(getElementData(teams[2], "Score")) or 0
                        outputChatBox("[RL] Scores: "..t1n.." ("..s1..") - "..t2n.." ("..s2..")", root, 0, 255, 0)
                    end
                end
                
                if c_round < rounds then
                    -- NEXT MAP / WARMUP LOGIC
                    setTimer(function()
                        if not isElement(teams[1]) then return end
                        
                        if isLeagueMode then
                            outputChatBox("[RL] Loading next map...", root, 0, 255, 0)
                            loadNextMap() 
                        else
                            -- CLANWAR MODE: Transition to Random Warmup (NOT from queue)
                            warmupState = true
                            readyStatus = {t1 = false, t2 = false}
                            loadRandomMap() -- FIXED: Now explicitly loads random map, ignoring queue
                            syncClients()
                        end
                    end, 5000, 1)

                elseif c_round >= rounds then
                    -- FINAL ROUND ENDED
                    outputChatBox("[RL] FINAL ROUND ENDED!", root, 255, 0, 255)
                    
                    local players = getElementsByType("player")
                    table.sort(players, function(a,b) 
                        return (tonumber(getElementData(a, "Score") or 0) > tonumber(getElementData(b, "Score") or 0)) 
                    end)
                    if players[1] then
                         local score = getElementData(players[1], "Score") or 0
                         outputChatBox("[RL] MATCH MVP: "..getPlayerName(players[1]).." ("..score.." pts)", root, 255, 255, 0)
                    end
                    
                    setTimer(finishWar, 5000, 1)
                end
            end
        end
    end
end)

addCommandHandler("tech", function(p)
    if not isElement(teams[1]) then return end
    if isLeagueMode then return end
    if warmupState then return end
    
    if techLocked then 
        outputChatBox("[RL] Tech pause is locked! (More than 10 seconds have passed since GO!)", p, 255, 0, 0) 
        return 
    end
    
    if (captain1 and getPlayerName(p) == captain1) or 
       (captain2 and getPlayerName(p) == captain2) or 
       isAdmin(p) then
        
        if isTimer(leagueTimer) then killTimer(leagueTimer) end
        if isTimer(techLockTimer) then killTimer(techLockTimer) end
        
        local currentMap = exports.mapmanager:getRunningGamemodeMap()
        if currentMap then
            local mapName = getResourceInfo(currentMap, "name") or getResourceName(currentMap)
            table.insert(mapQueue, 1, mapName)
        end

        outputChatBox("=== TECH PAUSE CALLED ===", root, 255, 0, 0)
        
        warmupState = true
        isTechPause = true
        isManualMapLoad = false 
        readyStatus = {t1=false, t2=false}
        c_round = math.max(0, c_round - 1)
        
        loadRandomMap()
        syncClients()
    end
end)

function setReferee(name) referee = name; outputChatBox("[RL] Referee: "..name, root, 0, 255, 0) end
function setCaptains(c1, c2) 
    if isLeagueMode then
        outputChatBox("[RL] Cannot set captains in Player League mode.", root, 255, 0, 0)
        return
    end
    captain1 = c1; captain2 = c2; 
    local clean_c1 = c1:gsub("#%x%x%x%x%x%x", "")
    local clean_c2 = c2:gsub("#%x%x%x%x%x%x", "")
    
    if c1 ~= "" or c2 ~= "" then
        local t1n = c1 ~= "" and clean_c1 or "None"
        local t2n = c2 ~= "" and clean_c2 or "None"
        outputChatBox("[RL] Captains updated: T1: " .. t1n .. " | T2: " .. t2n, root, 0, 255, 0) 
    else
        outputChatBox("[RL] Captains have been cleared.", root, 255, 150, 0) 
    end
end

function startCarColorEnforcement()
    if isTimer(carColorTimer) then killTimer(carColorTimer) end
    carColorTimer = setTimer(function()
        if not isElement(teams[1]) then return end
        for i, p in ipairs(getElementsByType("player")) do
            local t = getPlayerTeam(p)
            if t == teams[1] or t == teams[2] then
                local v = getPedOccupiedVehicle(p)
                if v then
                    local r, g, b = getTeamColor(t)
                    setVehicleColor(v, r, g, b, r, g, b, r, g, b, r, g, b)
                end
            end
        end
    end, 1000, 0)
end

function startReminderLoop()
    if isTimer(reminderTimer) then killTimer(reminderTimer) end
    reminderTimer = setTimer(function()
        if not warmupState then return end
        if isTechPause then
            outputChatBox("[RL] Tech pause is running. To ready up and continue the match, type /rd", root, 255, 150, 0)
        else
            if captain1 and not readyStatus.t1 then
                local p = getPlayerFromName(captain1)
                if p then outputChatBox("[RL] Your team is not ready. Type /rd and ready-up to start the match", p, 255, 150, 0) end
            end
            if captain2 and not readyStatus.t2 then
                local p = getPlayerFromName(captain2)
                if p then outputChatBox("[RL] Your team is not ready. Type /rd and ready-up to start the match", p, 255, 150, 0) end
            end
        end
    end, 60000, 0)
end

function stopReminderLoop()
    if isTimer(reminderTimer) then killTimer(reminderTimer) end
end

function finishWar()
    if isWarEnded or not isElement(teams[1]) then return end
    isWarEnded = true
    
    local file = nil
    if fileExists("stats.txt") then
        file = fileOpen("stats.txt")
        fileSetPos(file, fileGetSize(file)) 
    else
        file = fileCreate("stats.txt")
    end

    if file then
        local time = getRealTime()
        local dateStr = string.format("[%02d/%02d/%04d %02d:%02d]", time.monthday, time.month + 1, time.year + 1900, time.hour, time.minute)
        
        fileWrite(file, "\r\n========================================\r\n")
        fileWrite(file, "MATCH DATE: " .. dateStr .. "\r\n")
        
        if isLeagueMode then
            fileWrite(file, "MODE: Player League\r\n")
        else
            local t1 = getTeamName(teams[1])
            local t2 = isElement(teams[2]) and getTeamName(teams[2]) or "None"
            local s1 = tonumber(getElementData(teams[1], "Score")) or 0
            local s2 = tonumber(getElementData(teams[2], "Score")) or 0
            fileWrite(file, "MODE: Clanwar (" .. t1 .. " vs " .. t2 .. ")\r\n")
            fileWrite(file, "FINAL SCORE: " .. s1 .. " - " .. s2 .. "\r\n")
        end
        
        fileWrite(file, "----------------------------------------\r\n")
        fileWrite(file, "PLAYER RANKINGS:\r\n")
        
        local players = getElementsByType("player")
        table.sort(players, function(a,b) 
            return (tonumber(getElementData(a, "Score") or 0) > tonumber(getElementData(b, "Score") or 0)) 
        end)
        
        for i,p in ipairs(players) do
            local score = tonumber(getElementData(p, "Score")) or 0
            local won = tonumber(getElementData(p, "Maps Won")) or 0
            local played = tonumber(getElementData(p, "Maps Played")) or 0
            
            if isLeagueMode then
                if score > 0 or getPlayerTeam(p) == teams[1] then
                    local cleanName = getPlayerName(p):gsub("#%x%x%x%x%x%x", "")
                    fileWrite(file, string.format("%d. %s - Score: %d | Maps Won: %d | Maps Played: %d\r\n", i, cleanName, score, won, played))
                end
            else
                local ptsPerRound = getElementData(p, "Pts/Round") or "N/A"
                if score > 0 or getPlayerTeam(p) == teams[1] or getPlayerTeam(p) == teams[2] then
                    local cleanName = getPlayerName(p):gsub("#%x%x%x%x%x%x", "")
                    fileWrite(file, string.format("%d. %s - Score: %d | Maps Won: %d | Maps Played: %d | Pts/Round: %s\r\n", i, cleanName, score, won, played, tostring(ptsPerRound)))
                end
            end
        end
        fileWrite(file, "========================================\r\n")
        fileClose(file)
        outputChatBox("[RL] Stats exported to 'stats.txt'.", root, 0, 255, 0)
    else
        outputChatBox("[RL] Error writing to stats.txt", root, 255, 0, 0)
    end
    
    outputChatBox("[RL] MATCH FINISHED!", root, 255, 0, 255)
    destroyTeams(nil)
end