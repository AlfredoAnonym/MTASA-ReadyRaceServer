local teams = {}
local tags = {}
local playerData = {}
local rounds = 10
local c_round = 0
local f_round = false
local round_started = false
local round_ended = true
local isWarEnded  = false
local warActive = false
local captain1
local captain2
local ffaActive = false
local carbonActive = false
local checkpointRanks = {}
local pointsScoredCurrentRound = false

addEventHandler('onResourceStart', resourceRoot, function() 
    for i, player in ipairs(getElementsByType('player')) do
        removeElementData(player, 'captain')
    end
end)

function removeHex (text, digits)
    assert (type (text) == "string", "Bad argument 1 @ removeHex [String expected, got "..tostring(text).."]")
    assert (digits == nil or (type (digits) == "number" and digits > 0), "Bad argument 2 @ removeHex [Number greater than zero expected, got "..tostring (digits).."]")
    return string.gsub (text, "#"..(digits and string.rep("%x", digits) or "%x+"), "")
end

function serverCall(funcname, ...)
	local arg = { ... }
	if (arg[1]) then
		for key, value in next, arg do arg[key] = tonumber(value) or value end
	end
	if type(funcname) == "function" then
		return funcname(unpack(arg))
	end
	if type(funcname) == "string" then
		if _G and type(_G[funcname]) == "function" then
			return _G[funcname](unpack(arg))
		end
		-- Removed loadstring unsafe call
	end
	outputDebugString("serverCall: function '"..tostring(funcname).."' not found or cannot be called")
	return nil
end

function broadcastClientCall(funcname, ...)
    for i,player in ipairs(getElementsByType('player')) do
        clientCall(player, funcname, ...)
    end
end

function assignSpectator(p)
    if not isElement(p) then return end
    
    -- Try to find Spectators team if variable is lost but team exists
    if not isElement(teams[3]) then
        teams[3] = getTeamFromName("Spectators")
    end
    
    -- If still not found, create it
    if not isElement(teams[3]) then
        teams[3] = createTeam("Spectators", 255, 255, 255)
    end

    if isElement(teams[3]) then
        setPlayerTeam(p, teams[3])
    end
    -- Reset score when moving to spectators
    setElementData(p, 'Score', 0)
    
    -- Trigger the event that race resource uses to enable spectate mode
    triggerClientEvent(p, 'onClientCall_race', getRootElement(), "spectate") -- Attempt to force race spectate if supported
    triggerClientEvent(p, 'onSpectateRequest', getRootElement())
end

addEvent("onClientCallsServerFunction", true)
addEventHandler("onClientCallsServerFunction", resourceRoot , serverCall)

function clientCall(client, funcname, ...)
    local arg = { ... }
    if (arg[1]) then
        for key, value in next, arg do
            if (type(value) == "number") then arg[key] = tostring(value) end
        end
    end
    triggerClientEvent(client, "onServerCallsClientFunction", resourceRoot, funcname, unpack(arg or {}))
end

--------------
function preStart(player, command, t1_name, t2_name, t1tag, t2tag)
	if isAdmin(player) then
        -- Reset mode flags when starting a new Clan War
        ffaActive = false
        carbonActive = false
        broadcastClientCall('updateFFAState', false)
        broadcastClientCall('updateCarbonState', false)
		-- Do not automatically destroy or overwrite existing teams.
		-- Create teams only if they don't exist yet. Admin can manually edit names/colors/tags via Apply.
		if not isElement(teams[1]) then
			if t1_name ~= nil then
				teams[1] = createTeam(t1_name, 255, 0, 0)
			else
				teams[1] = createTeam('Team 1', 255, 0, 0)
			end
		end
		if not isElement(teams[2]) then
			if t2_name ~= nil then
				teams[2] = createTeam(t2_name, 0, 0, 255)
			else
				teams[2] = createTeam('Team 2', 0, 0, 255)
			end
		end
		if t1tag ~= nil and t2tag ~= nil then
			tags[1] = t1tag
			tags[2] = t2tag
		else
			tags[1] = tags[1] or 't1'
			tags[2] = tags[2] or 't2'
		end
		teams[3] = teams[3] or createTeam('Spectators', 255, 255, 255)
		for i,player in ipairs(getElementsByType('player')) do 
			assignSpectator(player)
			setElementData(player, 'Maps played', 0)
			setElementData(player, 'Maps won', 0)
			setElementData(player, 'Pts per map', 0)
		end
    -- Setup defaults for standard CW
    c_round = 0
    rounds = 10 -- Default to 10 rounds for standard CW
    f_round = false
    round_ended = true
		call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Pts per map")
		call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Score")
		call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Maps played")
		call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Maps won")
		broadcastClientCall('updateTeamData', teams[1], teams[2], teams[3])
		broadcastClientCall('updateTagData', tags[1], tags[2])
		broadcastClientCall('updateRoundData', c_round, rounds, f_round)
		broadcastClientCall('createGUI', getTeamName(teams[1]), getTeamName(teams[2]))
	else
		outputChatBox('[CW] #ffffffYou are not admin', player, 155, 155, 255, true)
	end
end

function startFreeForAll()
    ffaActive = true
    carbonActive = false
    
    -- Ustawienia Team 1 (FFA)
    if not isElement(teams[1]) then
        teams[1] = createTeam('Free-For-All', 0, 191, 255) -- Deep Sky Blue
    else
        setTeamName(teams[1], 'Free-For-All')
        setTeamColor(teams[1], 0, 191, 255)
    end
    
    -- Usuwanie Team 2
    if isElement(teams[2]) then
        destroyElement(teams[2])
        teams[2] = nil
    end

    -- Tworzenie Spectators jesli nie ma
    teams[3] = teams[3] or createTeam('Spectators', 255, 255, 255)

    -- Przeniesienie wszystkich graczy do Team 1 (chyba ze sa w spec)
    for i, p in ipairs(getElementsByType('player')) do
        local currentTeam = getPlayerTeam(p)
        if currentTeam ~= teams[3] then
            setPlayerTeam(p, teams[1])
        end
        -- Reset flagi kapitana
        removeElementData(p, 'captain')
        
        -- Reset wynikow gracza
        setElementData(p, 'Score', 0)
        setElementData(p, 'Pts per map', 0)
        setElementData(p, 'Maps played', 0)
        setElementData(p, 'Maps won', 0)
    end
    
    captain1 = nil
    captain2 = nil
    
    -- Reset rund i punktow teamu
    setElementData(teams[1], 'Score', 0)
    c_round = 0
    rounds = 10 -- Default to 10 rounds
    round_ended = true
    
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Score")
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Pts per map")
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Maps played")
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Maps won")

    -- Aktualizacja klientow
    broadcastClientCall('updateTeamData', teams[1], teams[2], teams[3])
    broadcastClientCall('updateRoundData', c_round, rounds, f_round)
    
    warActive = true -- Set server-side warActive state
    broadcastClientCall('updateWarActive', true) 
    broadcastClientCall('updateFFAState', true) -- Nowa funkcja u klienta do blokady GUI
    broadcastClientCall('updateCarbonState', false)
    broadcastClientCall('createGUI', 'Free-For-All', '')
    
    -- W FFA chcemy automatyczną zmianę map (losową), ale bez głosowania graczy
    local raceRes = getResourceFromName("race")
    if raceRes and getResourceState(raceRes) == "running" then
         set("race.postfinish_duration", 5000) -- Krótki czas po wyścigu
         set("race.autopick_map", true) -- Automatyczny wybór
         set("race.randommaps", true) -- Losowe mapy
    end
    
    outputInfo("Mode Free-For-All activated! Captains disabled.")
end
addEvent("onRequestFFA", true)
addEventHandler("onRequestFFA", resourceRoot, startFreeForAll)

function startCarbonMode()
    ffaActive = true
    carbonActive = true
    checkpointRanks = {} -- Reset leaderboard for checkpoints

    -- Setup Team 1 (Carbon Mode)
    if not isElement(teams[1]) then
        teams[1] = createTeam('Carbon Mode', 186, 85, 211) -- Medium Orchid
    else
        setTeamName(teams[1], 'Carbon Mode')
        setTeamColor(teams[1], 186, 85, 211)
    end
    
    if isElement(teams[2]) then
        destroyElement(teams[2])
        teams[2] = nil
    end

    teams[3] = teams[3] or createTeam('Spectators', 255, 255, 255)

    for i, p in ipairs(getElementsByType('player')) do
        local currentTeam = getPlayerTeam(p)
        if currentTeam ~= teams[3] then
            setPlayerTeam(p, teams[1])
        end
        removeElementData(p, 'captain')
        setElementData(p, 'Score', 0)
        setElementData(p, 'Pts per map', 0)
        setElementData(p, 'Maps played', 0)
        setElementData(p, 'Maps won', 0)
    end
    
    captain1 = nil
    captain2 = nil
    
    setElementData(teams[1], 'Score', 0)
    c_round = 0
    rounds = 10 -- Default to 10 rounds
    round_ended = true
    
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Score")
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Pts per map")
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Maps played")
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Maps won")

    broadcastClientCall('updateTeamData', teams[1], teams[2], teams[3])
    broadcastClientCall('updateRoundData', c_round, rounds, f_round)
    
    warActive = true
    broadcastClientCall('updateWarActive', true)
    broadcastClientCall('updateFFAState', true)
    broadcastClientCall('updateCarbonState', true)
    broadcastClientCall('createGUI', 'Carbon Mode', '')
    
    local raceRes = getResourceFromName("race")
    if raceRes and getResourceState(raceRes) == "running" then
         set("race.postfinish_duration", 5000)
         set("race.autopick_map", true)
         set("race.randommaps", true)
    end
    
    outputInfo("Carbon Mode activated! Points per checkpoint.")
end
addEventHandler('onPlayerReachCheckpoint', root, function(checkpointIndex)
    if not carbonActive then return end
    if f_round or c_round == 0 then return end
    
    local cIndex = tonumber(checkpointIndex)
    if not cIndex then return end

    if not checkpointRanks[cIndex] then
        checkpointRanks[cIndex] = 0
    end
    checkpointRanks[cIndex] = checkpointRanks[cIndex] + 1
    local rank = checkpointRanks[cIndex]
    
    -- 1st=15, 2nd=13, 3rd=11, 4th=9, 5th=7, 6th=5, 7th=4, 8th=3, 9th=2, 10th+=1
    local points = 1
    if rank == 1 then points = 15
    elseif rank == 2 then points = 13
    elseif rank == 3 then points = 11
    elseif rank == 4 then points = 9
    elseif rank == 5 then points = 7
    elseif rank == 6 then points = 5
    elseif rank == 7 then points = 4
    elseif rank == 8 then points = 3
    elseif rank == 9 then points = 2
    end
    
    local currentScore = getElementData(source, 'Score') or 0
    setElementData(source, 'Score', currentScore + points)
    pointsScoredCurrentRound = true
    
    recalcAvg(source)

    -- Optionally keep team score in sync just for display
    if isElement(teams[1]) then
        local tScore = getElementData(teams[1], 'Score') or 0
        setElementData(teams[1], 'Score', tScore + points)
    end
end)

function destroyTeams(player)
	if isAdmin(player) or player == false then
        warActive = false
        ffaActive = false
        carbonActive = false -- Force disable Carbon Mode
        broadcastClientCall('updateFFAState', false)
        broadcastClientCall('updateCarbonState', false)
        -- Przywracamy domyślny czas i ustawienia race po zakończeniu CW
        local raceRes = getResourceFromName("race")
        if raceRes and getResourceState(raceRes) == "running" then
             set("race.postfinish_duration", 30000)
             set("race.autopick_map", true)
             set("race.randommaps", true)
        end
        captain1 = nil
        captain2 = nil
        broadcastClientCall('updateWarActive', false)
		for i,team in pairs(teams) do
			if isElement(team) then
				destroyElement(team)
			end	
		end
        teams = {}
		for i,player in ipairs(getElementsByType('player')) do
			removeElementData(player, 'captain')
			setElementData(player, 'Score', 0)
			setElementData(player, 'Maps played', 0)
			setElementData(player, 'Maps won', 0)
			setElementData(player, 'Pts per map', 0)
			clientCall(player, 'updateTeamData', teams[1], teams[2], teams[3])
			clientCall(player, 'updateTagData', tags[1], tags[2])
			clientCall(player, 'updateRoundData', c_round, rounds, f_round)
		end
	else
		outputChatBox('[CW] #ffffffYou are not admin', player, 155, 155, 255, true)
	end
end

function funRound(player)
	if isAdmin(player) then
		f_round = true
		for i,player in ipairs(getElementsByType('player')) do
			clientCall(player, 'updateRoundData', c_round, rounds, f_round)
		end
		outputInfo('#ffffffFree round')
	else
		outputChatBox('[CW] #ffffffYou are not admin', player, 155, 155, 255, true)
	end
end

addCommandHandler('newtr', preStart)
addCommandHandler('endtr', destroyTeams)
addCommandHandler('fun', funRound)

function outputInfo(info)
	for i, player in ipairs(getElementsByType('player')) do
		outputChatBox('[CW]: #ffffff' ..info, player, 155, 155, 255, true)
	end
end

function recalcAvg(player)
    local score = getElementData(player, 'Score') or 0
    local played = getElementData(player, 'Maps played') or 1
    if played == 0 then played = 1 end
    
    local avg = score / played
    
    -- Format to 1 decimal place using a string to ensure exact representation
    -- e.g. 7.1251512 -> "7.1", 1000.515221 -> "1000.5"
    -- We convert to number to enable sorting, but handle precision cleanly
    -- We use a math round approach which is robust for float representation
    
    -- Zaokrąglamy do najbliższej liczby całkowitej (integer)
    local rounded = math.floor(avg + 0.5)
    
    setElementData(player, 'Pts per map', rounded)
end

function startRound()
	f_round = false
    if carbonActive then
        checkpointRanks = {}
    end

	if c_round < rounds  then
		if round_ended then
            if c_round == 0 or pointsScoredCurrentRound then
			    c_round = c_round + 1
            end
		end
		round_started = true
        pointsScoredCurrentRound = false
    else
        -- Also reset for the last round replay scenario
        pointsScoredCurrentRound = false
	end

	for i,player in ipairs(getElementsByType('player')) do
		clientCall(player, 'updateRoundData', c_round, rounds, f_round)
	end
	round_ended = false
	if isWarEnded then
		destroyTeams(false)
		isWarEnded = false
	end
end

function isRoundEnded()
	local c_ActivePlayers = 0
	if isElement(teams[1]) then
		for i,player in ipairs(getPlayersInTeam(teams[1])) do
			-- Check if player is active (not finished) and alive
			local state = getElementData(player, "state")
			if state == "alive" and not getElementData(player, 'race.finished') and not isPedDead(player) then
				c_ActivePlayers = c_ActivePlayers + 1
			end
		end
	end
	if not ffaActive and isElement(teams[2]) then
		for i,player in ipairs(getPlayersInTeam(teams[2])) do
			local state = getElementData(player, "state")
			if state == "alive" and not getElementData(player, 'race.finished') and not isPedDead(player) then
				c_ActivePlayers = c_ActivePlayers + 1
			end
		end
	end
	if c_ActivePlayers == 0 then return true else return false end
end

function playerFinished(rank)
	-- Ensure teams exist before processing (FFA requires only team 1)
	if (ffaActive and isElement(teams[1])) or (isElement(teams[1]) and isElement(teams[2])) then
		local playerTeam = getPlayerTeam(source)
		
		local validTeam = false
		if ffaActive then
			if playerTeam == teams[1] then validTeam = true end
		else
			if playerTeam == teams[1] or playerTeam == teams[2] then validTeam = true end
		end

		-- Requirements:
		-- 1. Must be in a valid Team
		-- 2. Must not be a Free round (f_round must be false)
		-- 3. Must strict check c_round > 0 to avoid points on round 0/10
		if validTeam and not f_round and c_round > 0 then

			-- Standard scoring based on rank
            if not carbonActive then
                local pointsTable = {[1]=15, [2]=13, [3]=11, [4]=9, [5]=7, [6]=5, [7]=4, [8]=3, [9]=2, [10]=1}
                local p_score = pointsTable[rank] or 1 -- Give 1 point for rank > 10
                
                local mw = 0
                if rank == 1 then mw = 1 end
                
                -- Only proceed if points were actually awarded
                if p_score > 0 then
                    pointsScoredCurrentRound = true
                    
                    local old_score = getElementData(playerTeam, 'Score') or 0
                    local new_score = old_score + p_score
                    local old_p_score = getElementData(source, 'Score') or 0
                    local new_p_score = old_p_score + p_score
                    local old_mw = getElementData(source, 'Maps won') or 0
                    local new_mw = old_mw + mw
                    
                    setElementData(source, 'Score', new_p_score)
                    if not ffaActive then
                        setElementData(playerTeam, 'Score', new_score)
                    end
                    
                    setElementData(source, 'Maps won', new_mw)
                    recalcAvg(source)
                    
                    local tColorHex = "#FFFFFF"
                    local r, g, b = getTeamColor(playerTeam)
                    tColorHex = rgb2hex(r, g, b)

                    local pName = getPlayerName(source)
                    
                    outputInfo(tColorHex .. pName .. ' #ffffffgot #9b9bff' .. p_score .. ' #ffffffpoints #9b9bff('.. new_p_score .. ')')
                end
            elseif carbonActive then
                 -- Add points for finishing (treating finish line as a checkpoint)
                 -- 1st=15, 2nd=13, 3rd=11, 4th=9, 5th=7, 6th=5, 7th=4, 8th=3, 9th=2, 10th+=1
                 local points = 1
                 if rank == 1 then points = 15
                 elseif rank == 2 then points = 13
                 elseif rank == 3 then points = 11
                 elseif rank == 4 then points = 9
                 elseif rank == 5 then points = 7
                 elseif rank == 6 then points = 5
                 elseif rank == 7 then points = 4
                 elseif rank == 8 then points = 3
                 elseif rank == 9 then points = 2
                 end

                 local currentScore = getElementData(source, 'Score') or 0
                 setElementData(source, 'Score', currentScore + points)
                 pointsScoredCurrentRound = true
                 
                 recalcAvg(source)
                
                 if isElement(teams[1]) then
                    local tScore = getElementData(teams[1], 'Score') or 0
                    setElementData(teams[1], 'Score', tScore + points)
                 end

                 if rank == 1 then
                     local old_mw = getElementData(source, 'Maps won') or 0
                     setElementData(source, 'Maps won', old_mw + 1)
                     outputInfo('#ffffff' .. getPlayerName(source) .. ' #fffffffinished 1st!')
                 end
            end
            
            -- Add Maps Played to everyone when the first player finishes
            if rank == 1 then
                 local function addMapPlayed(team)
                    if isElement(team) then
                        for i, player in ipairs(getPlayersInTeam(team)) do
                            local currentMP = getElementData(player, 'Maps played') or 0
                            setElementData(player, 'Maps played', currentMP + 1)
                            recalcAvg(player)
                        end
                    end
                 end
                 addMapPlayed(teams[1])
                 if not ffaActive then
                    addMapPlayed(teams[2])
                 end
            end
		end
		
		-- Check if round should end
		if isRoundEnded() then
			endRound()
		end
	end
end

function getPlayerScore(player)
	local c_score = 0
	if getPlayerTeam(player) ~= teams[3] then
		c_score = getElementData(player, 'Score')
	end
end

function endRound()
	-- Ensure teams exist (FFA requires only team 1)
	if (ffaActive and isElement(teams[1])) or (isElement(teams[1]) and isElement(teams[2])) then
		if isWarEnded then return end
		
		-- Always mark round as ended regardless of round number
		if not round_ended then
			round_ended = true
			if c_round > 0 and not f_round then 
				outputInfo('#9b9bff[CW] #ffffffRound has been ended')
			end
		end

		if c_round == rounds and not f_round then
			if ffaActive then
				-- Continuous FFA Logic: 
                -- 1. Display winner of the "match" (set of rounds)
                -- 2. Reset scores to keep playing fresh
                -- 3. Do NOT destroy teams, just keep going
				local players = getPlayersInTeam(teams[1])
				table.sort(players, function(a,b) return (getElementData(a, 'Score') or 0) > (getElementData(b, 'Score') or 0) end)
				
				local winner = players[1]
				if winner then
					outputInfo('#FFD700' .. getPlayerName(winner) .. ' #ffffffwon the Free-For-All/Carbon round set with score: ' .. (getElementData(winner, 'Score') or 0))
				end
                
                -- Reset variables for next "set" of rounds (or endless play)
                if carbonActive then
                    outputInfo("Carbon Mode continues...")
                else
                    outputInfo("Free-For-All continues...")
                end
                
                -- Reset scores for new "match" block
                for i, p in ipairs(getPlayersInTeam(teams[1])) do
                    setElementData(p, 'Score', 0)
                end
                c_round = 0
                broadcastClientCall('updateRoundData', c_round, rounds, f_round)
                
                -- Force Race to pick a new map if it hasn't already started the process
                -- Usually, race handles this on its own after finish.
                -- We only need to ensure we don't Kill the mode via endThisWar.
                -- Race should proceed to next map automatically due to autopick=true.
			else
				-- CW Logic for Match End
				local t1 = teams[1]
				local t2 = teams[2]
				local function getMVP(team)
					local players = getPlayersInTeam(team)
					table.sort(players, function(a,b) return (getElementData(a, 'Score') or 0) > (getElementData(b, 'Score') or 0) end)
					local mvp = players[1]
					if mvp then
						return getPlayerName(mvp), getElementData(mvp, 'Score') or 0
					else
						return '-', 0
					end
				end

				local t1mvp, pts1 = getMVP(t1)
				local t2mvp, pts2 = getMVP(t2)
				
				local r1, g1, b1 = getTeamColor(t1)
				local r2, g2, b2 = getTeamColor(t2)
				local t1c, t2c = rgb2hex(r1, g1, b1), rgb2hex(r2, g2, b2)
				
				endThisWar()
				
				outputInfo(t1c .. (tags[1] or '') .. ' #ffffffMVP: ' .. t1c .. t1mvp .. (t1mvp ~= '-' and (' #9b9bff(' .. pts1 .. ')') or ''))
				outputInfo(t2c .. (tags[2] or '') .. ' #ffffffMVP: ' .. t2c .. t2mvp .. (t2mvp ~= '-' and (' #9b9bff(' .. pts2 .. ')') or ''))
			end
		end
	end
end

function rgb2hex(r,g,b) 
	return string.format("#%02X%02X%02X", r,g,b) 
end 

function endThisWar()
	if isWarEnded then return end
	isWarEnded = true
	
	if ffaActive then
		outputInfo('#9b9bff[FFA] #ffffffMatch has ended!')
		
        local modeName = "Free-For-All"
        if carbonActive then
            modeName = "Carbon Mode"
        end

		local content = ""
		local time = getRealTime()
		local timestamp = string.format("[%02d/%02d/%04d %02d:%02d]", time.monthday, time.month+1, time.year+1900, time.hour, time.minute)
		content = content .. timestamp .. " " .. modeName .. " Match Ended\r\n"
		
		if isElement(teams[1]) then
			local players = getPlayersInTeam(teams[1])
			table.sort(players, function(a,b) return (getElementData(a, 'Score') or 0) > (getElementData(b, 'Score') or 0) end)
			for i, player in ipairs(players) do
				local score = getElementData(player, 'Score') or 0
                local mp = getElementData(player, 'Maps played') or 0
                local mw = getElementData(player, 'Maps won') or 0
                local ppm = 0
                if mp > 0 then ppm = score / mp end
                local cleanName = string.gsub(getPlayerName(player), "#%x%x%x%x%x%x", "")
                
				content = content .. string.format("  - %-20s | Score: %3d | MP: %2d | MW: %2d | PPM: %.1f\r\n", cleanName, score, mp, mw, ppm)
			end
		end
		
        content = content .. string.rep("-", 50) .. "\r\n"

		local file = fileOpen("stats.txt")
		if not file then
			file = fileCreate("stats.txt")
		end
		fileSetPos(file, fileGetSize(file))
		fileWrite(file, content .. "\r\n")
		fileClose(file)
        
        outputInfo(modeName .. " stats saved to #9b9bffstats.txt")
		
		destroyTeams(false) -- Ending the war properly for FFA
		return -- Exit early for FFA
	end

	-- Standard CW Logic
	if not isElement(teams[1]) or not isElement(teams[2]) then return end
	
	local t1score = tonumber(getElementData(teams[1], 'Score')) or 0
	local t2score = tonumber(getElementData(teams[2], 'Score')) or 0
	local t1r, t1g, t1b = getTeamColor(teams[1])
	local t1c = string.format("#%02X%02X%02X", t1r, t1g, t1b)
	local t2r, t2g, t2b = getTeamColor(teams[2])
	local t2c = string.format("#%02X%02X%02X", t2r, t2g, t2b)
	
	local t1Name = getTeamName(teams[1])
	local t2Name = getTeamName(teams[2])
	
	if t1score > t2score then
		outputInfo(t1c .. t1Name.. ' #ffffffwon ' .. t2c .. t2Name.. ' #ffffffwith score ' ..t1score.. ' : ' ..t2score)
	elseif t1score < t2score then
		outputInfo(t2c .. t2Name.. ' #ffffffwon ' .. t1c .. t1Name.. ' #ffffffwith score ' ..t2score.. ' : ' ..t1score)
	else
		outputInfo(t1c .. t1Name.. ' #ffffffand '.. t2c .. t2Name.. ' #ffffffplayed draw with score ' ..t1score.. ' : ' ..t2score)
	end
    
    -- Save stats to file
    local time = getRealTime()

    local timestamp = string.format("[%02d/%02d/%04d %02d:%02d]", time.monthday, time.month+1, time.year+1900, time.hour, time.minute)
    local resultString = string.format("%s %s (%d) vs %s (%d) - ", timestamp, t1Name, t1score, t2Name, t2score)
    
    if t1score > t2score then
        resultString = resultString .. t1Name .. " won"
    elseif t1score < t2score then
         resultString = resultString .. t2Name .. " won"
    else
         resultString = resultString .. "Draw"
    end
    
    local content = resultString .. "\r\n"

    local function appendTeamStats(team)
        content = content .. " Team: " .. getTeamName(team) .. "\r\n"
        local players = getPlayersInTeam(team)
        table.sort(players, function(a,b) return (getElementData(a, 'Score') or 0) > (getElementData(b, 'Score') or 0) end)
        for i, player in ipairs(players) do
             local score = getElementData(player, 'Score') or 0
             local mp = getElementData(player, 'Maps played') or 0
             local mw = getElementData(player, 'Maps won') or 0
             local ppm = 0
             if mp > 0 then ppm = score / mp end
             local cleanName = string.gsub(getPlayerName(player), "#%x%x%x%x%x%x", "")
             content = content .. string.format("  - %-20s | Score: %3d | MP: %2d | MW: %2d | PPM: %.1f\r\n", cleanName, score, mp, mw, ppm)
        end
    end

    if isElement(teams[1]) then appendTeamStats(teams[1]) end
    if isElement(teams[2]) then appendTeamStats(teams[2]) end
    content = content .. string.rep("-", 50) .. "\r\n"

    local file = fileOpen("stats.txt")
    if not file then
        file = fileCreate("stats.txt")
    end
    if file then
        fileSetPos(file, fileGetSize(file))
        fileWrite(file, content)
        fileClose(file)
        outputInfo("Match stats saved to #9b9bffstats.txt")
    end

    -- Automatyczne zakończenie wojny po ostatniej rundzie (czyszczenie teamów i przywrócenie ustawień mapy)
    destroyTeams(false)
end

function isAdmin(thePlayer)
	if not thePlayer then return true end
	if isObjectInACLGroup("user."..getAccountName(getPlayerAccount(thePlayer)), aclGetGroup("Admin")) then
		return true
	else
		return false
	end
end

function isClientAdmin(client)
	local accName = getAccountName(getPlayerAccount(client))
	if isObjectInACLGroup("user."..accName, aclGetGroup("Admin")) then
		clientCall(client, 'updateAdminInfo', true)
	else
		clientCall(client, 'updateAdminInfo', false)
	end
end

function playerJoin(source)
	if isElement(teams[1]) then
		clientCall(source, 'updateTeamData', teams[1], teams[2], teams[3])
		clientCall(source, 'updateTagData', tags[1] or '', tags[2] or '')
		clientCall(source, 'updateRoundData', c_round, rounds, f_round)
        if ffaActive then
             clientCall(source, 'updateFFAState', true)
        end
        if carbonActive then
             clientCall(source, 'updateCarbonState', true)
        end
        -- Pass tags to createGUI as well to ensure they are available immediately as arguments
        local t1NameOrTag = (tags[1] and tags[1] ~= "") and tags[1] or getTeamName(teams[1])
        local t2NameOrTag = (tags[2] and tags[2] ~= "") and tags[2] or (isElement(teams[2]) and getTeamName(teams[2]) or '')
        clientCall(source, 'createGUI', t1NameOrTag, t2NameOrTag)
		assignSpectator(source)
	end
    
    clientCall(source, 'updateWarActive', warActive)

    local serial = getPlayerSerial(source)
    if playerData[serial] ~= nil then
            setElementData(source, 'Score', playerData[serial]["score"])
            setElementData(source, 'Pts per map', playerData[serial]["ppm"])
            setElementData(source, 'Maps played', playerData[serial]["mp"])
            setElementData(source, 'Maps won', playerData[serial]["mw"])
        else
            setElementData(source, 'Score', 0)
            setElementData(source, 'Pts per map', 0)
            setElementData(source, 'Maps played', 0)
            setElementData(source, 'Maps won', 0)
    end
end

function playerLogin(p_a, c_a)
	local accName = getAccountName(c_a)
	if isObjectInACLGroup("user."..accName, aclGetGroup("Admin")) then
		clientCall(source, 'updateAdminInfo', true)
	else
		clientCall(source, 'updateAdminInfo', false)
	end
end


function startWar(team1name, team2name, t1tag, t2tag, r1, g1, b1, r2, g2, b2)
	-- Do not automatically destroy or overwrite admin-managed teams/colors/tags.
	tags[1] = t1tag or tags[1]
	tags[2] = t2tag or tags[2]
	
	-- Only create if missing, do NOT overwrite existing settings
	if not isElement(teams[1]) then
		teams[1] = createTeam(team1name or 'Team 1', r1 or 255, g1 or 0, b1 or 0)
	end

	if not isElement(teams[2]) then
		teams[2] = createTeam(team2name or 'Team 2', r2 or 0, g2 or 0, b2 or 255)
	end

	teams[3] = teams[3] or createTeam('Spectators', 255, 255, 255)
	for i,player in ipairs(getElementsByType('player')) do 
		assignSpectator(player) 
		setElementData(player, 'Score', 0) -- Reset player score whenever war starts
		setElementData(player, 'Maps played', 0)
		setElementData(player, 'Maps won', 0)
		setElementData(player, 'Pts per map', 0)
	end
	setElementData(teams[1], 'Score', 0)
	setElementData(teams[2], 'Score', 0)
	round_ended = true
	c_round = 0
	rounds = 10 -- Auto set 10 rounds
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Score")
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Pts per map")
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Maps played")
	call(getResourceFromName("scoreboard"), "scoreboardAddColumn", "Maps won")
	broadcastClientCall('updateTeamData', teams[1], teams[2], teams[3])
	broadcastClientCall('updateTagData', tags[1], tags[2])
	broadcastClientCall('updateRoundData', c_round, rounds, f_round)
	broadcastClientCall('createGUI', t1tag, t2tag)
    
    warActive = true
    broadcastClientCall('updateWarActive', true)
    
    -- Blokujemy automatyczną zmianę mapy ustawiając bardzo długi czas post-finish
    local raceRes = getResourceFromName("race")
    if raceRes and getResourceState(raceRes) == "running" then
         set("race.postfinish_duration", 3600000)
         -- Blokujemy autopick_map w race
         set("race.autopick_map", false)
         -- Blokujemy randommaps w race
         set("race.randommaps", false)
    end
end

-- Zapobiegamy vote'owaniu nowej mapy przez votemanager
addEvent("onPollStarting")
addEventHandler("onPollStarting", root, function()
    if warActive then
        cancelEvent()
        if ffaActive then
            -- Force random map change for FFA/Carbon without voting
            local raceRes = getResourceFromName("race")
            local mapManagerRes = getResourceFromName("mapmanager")
            if raceRes and mapManagerRes and getResourceState(raceRes) == "running" and getResourceState(mapManagerRes) == "running" then
                local maps = call(mapManagerRes, "getMapsCompatibleWithGamemode", raceRes)
                if maps and #maps > 0 then
                    local randomMap = maps[math.random(1, #maps)]
                    call(mapManagerRes, "changeGamemodeMap", randomMap, raceRes)
                end
            end
        end
        return false
    end
end)

-- Blokujemy również draw (rysowanie) panelu votemanager
addEvent("onPollStart", true)
addEventHandler("onPollStart", root, function()
    if warActive then
        cancelEvent()
    end
end)

addEventHandler('onMapStarting', getRootElement(), function()
    -- Ensure race settings for FFA
    if ffaActive then
         local raceRes = getResourceFromName("race")
         if raceRes and getResourceState(raceRes) == "running" then
             set("race.autopick_map", true) 
             set("race.randommaps", true) 
             set("race.postfinish_duration", 5000) -- Short duration to proceed quickly
         end
    end
    startRound()
end)

-- Admin-controlled updates: change name, color or tags via Apply in admin GUI
function setTeamNameCustom(teamElem, newName)
	-- Admin check removed as per request
	if not isElement(teamElem) then return end
	
    -- Instantly update existing team element instead of recreating it
    local success = setElementData(teamElem, "overrideName", newName) -- Just in case name is used else where
    local successMTA = setTeamName(teamElem, newName or getTeamName(teamElem)) 
    
    -- If native setTeamName fails (e.g. name taken), try appending a space or handle gracefully
    if not successMTA then
         -- Fallback: try to force it or log error, but for now we attempt to keep the team object alive
    end
    
	broadcastClientCall('updateTeamData', teams[1], teams[2], teams[3])
	broadcastClientCall('updateTagData', tags[1], tags[2])
	broadcastClientCall('updateRoundData', c_round, rounds, f_round)
end

function setTeamColorCustom(teamElem, r, g, b)
	-- Admin check removed as per request
	if not isElement(teamElem) then return end
	
    -- Instantly update color on existing element
    setTeamColor(teamElem, tonumber(r) or 255, tonumber(g) or 0, tonumber(b) or 0)
    
	broadcastClientCall('updateTeamData', teams[1], teams[2], teams[3])
	broadcastClientCall('updateTagData', tags[1], tags[2])
	broadcastClientCall('updateRoundData', c_round, rounds, f_round)
end

function setTags(t1, t2)
	local player = source
	-- Admin check removed as per request
	tags[1] = tostring(t1 or tags[1])
	tags[2] = tostring(t2 or tags[2])
	broadcastClientCall('updateTagData', tags[1], tags[2])
	broadcastClientCall('updateAdminPanelText')
end

function updateRounds(cur_round, ma_round)
	c_round = cur_round
	rounds = ma_round
	for i, player in ipairs(getElementsByType('player')) do
		clientCall(player, 'updateRoundData', c_round, rounds, f_round)
	end
end

function sincAP()
	for i,player in ipairs(getElementsByType('player')) do
		clientCall(player, 'updateAdminPanelText')
	end
end


function setColors()
	local s_team = getPlayerTeam(source)
	local p_veh = getPedOccupiedVehicle(source)
	if s_team then
		local r, g, b = getTeamColor(s_team)
		setVehicleColor(p_veh, r, g, b, 255, 255, 255)
	end
end

function getBlipAttachedTo(thePlayer)
	local blips = getElementsByType("blip")
	for k, theBlip in ipairs(blips) do
		if getElementAttachedTo(theBlip) == thePlayer then
			return theBlip
		end
   end
   return false
end

addEvent('onMapStarting', true)
-- addEventHandler('onMapStarting', getRootElement(), startRound) -- Handled by custom handler above

addEvent('onPlayerFinish', true)
addEventHandler('onPlayerFinish', getRootElement(), playerFinished)

addEvent('onPostFinish', true)
addEventHandler('onPostFinish', getRootElement(), endRound)

addEventHandler('onPlayerLogin', getRootElement(), playerLogin)

addEventHandler('onPlayerVehicleEnter', getRootElement(), setColors)

addEvent('onPlayerReachCheckpoint', true)
addEventHandler('onPlayerReachCheckpoint', getRootElement(), setColors)

addEvent("onRaceStateChanging")
addEventHandler("onRaceStateChanging",getRootElement(),
	function(newState, oldState)
		local players = getElementsByType("player")
		for k,v in ipairs(players) do
			local thePlayer = v
			local playerTeam = getPlayerTeam (thePlayer)
			local theBlip = getBlipAttachedTo(thePlayer)
			local r,g,b
			if ( playerTeam ) then
				if newState == "Running" and oldState == "GridCountdown" then
					r, g, b = getTeamColor (playerTeam)
					setBlipColor(theBlip, tostring(r), tostring(g), tostring(b), 255)
					if playerTeam == teams[3] then
						triggerClientEvent(thePlayer, 'onSpectateRequest', getRootElement())
					end
				end
			end
		end
	end
)


addEventHandler("onPlayerQuit", getRootElement(),
    function()
        if warActive or (isElement(teams[1]) and (ffaActive or isElement(teams[2]))) then
            if isWarEnded == false then
                local serial = getPlayerSerial(source)
                playerData[serial] = {}
                playerData[serial]["score"] = getElementData(source, 'Score') or 0
                playerData[serial]["ppm"] = getElementData(source, 'Pts per map') or 0
                playerData[serial]["mp"] = getElementData(source, 'Maps played') or 0
                playerData[serial]["mw"] = getElementData(source, 'Maps won') or 0
            end
        end
    end
)
addEvent ('onCaptainsChosen', true )
addEventHandler ('onCaptainsChosen', root, function (t1_text, t2_text)
	if ffaActive then
		if client then
			outputChatBox('[FFA] #ffffffCaptains are disabled in Free-For-All mode.', client, 255, 100, 100, true)
		end
		return
	end

	-- Clean old captains data
	for i, p in ipairs(getElementsByType('player')) do
		removeElementData(p, 'captain')
	end

	if t1_text == '' or t2_text == '' then
		outputInfo('None or one captain were chosen. Get your things straight, manager.')
	else
		outputInfo(t1_text..' and '..t2_text..' were selected as captains')
		outputInfo('They can use the following commands: #00FF00/r #FF0000/f #FFFF00/haha #7FFFD4/gg')
		
		-- Set new captains data
		for i, p in ipairs(getElementsByType('player')) do
			local pName = removeHex(getPlayerName(p), 6)
			if pName == t1_text or pName == t2_text then
				setElementData(p, 'captain', true)
			end
		end
	end
	captain1 = t1_text
	captain2 = t2_text
end )

function readyFunc(player)
if captain1 and captain2 then
if captain1 == removeHex(getPlayerName(player),6) or captain2 == removeHex(getPlayerName(player),6) then
outputChatBox(removeHex(getPlayerName(player),6)..' says his team is ready!', root,  0, 255, 0, true)
end
end
end
addCommandHandler('r', readyFunc)

function stopFunc(player)
if captain1 and captain2 then
if captain1 == removeHex(getPlayerName(player),6) or captain2 == removeHex(getPlayerName(player),6) then
outputChatBox(removeHex(getPlayerName(player),6)..' requests a FUN ROUND!', root, 255, 0, 0, true)
end
end
end
addCommandHandler('f', stopFunc)

function hahaFunc(player)
if captain1 and captain2 then
if captain1 == removeHex(getPlayerName(player),6) or captain2 == removeHex(getPlayerName(player),6) then
outputChatBox(removeHex(getPlayerName(player),6)..' laughs at all the n00bs in enemy team!', root, 255, 215, 0, true)
end
end
end
addCommandHandler('haha', hahaFunc)

function ggFunc(player)
if captain1 and captain2 then
if captain1 == removeHex(getPlayerName(player),6) or captain2 == removeHex(getPlayerName(player),6) then
outputChatBox(removeHex(getPlayerName(player),6)..' thanks enemy team for a great game!', root, 127, 255, 212, true)
end
end
end
addCommandHandler('gg', ggFunc)

addEventHandler('onPlayerJoin', root, function()
    local name = removeHex(getPlayerName(source), 6)
    if (captain1 and name == captain1) or (captain2 and name == captain2) then
        setElementData(source, 'captain', true)
    end
end)

