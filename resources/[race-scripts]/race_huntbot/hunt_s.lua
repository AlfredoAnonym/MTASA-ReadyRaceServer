--made by Wojak aka Wojak[PL] aka [2RT]Wojak[PL]
--Remixed for global mayhem, persistent admin tracking, instant activation, and smart retreats

local core = createObject(1155,0,0,-5000) -- Spawn it underground initially
local coreveh = createVehicle(425,0,0,-5000)
attachElements(coreveh,core,0,1,0,0,0,0)
setVehicleDamageProof(coreveh,true)
local coreped = createPed(252,0,0,0)
warpPedIntoVehicle(coreped,coreveh,0)
-- Radar blip has been removed for stealth

addEvent("onRaceStateChanging",true)
addEvent("onNewPlayerDetected",true)
addEvent("onMapStarting",true)

local racestate = ""
local activestate = 0
local huntMode = "none" -- States: "none", "player", "all"
local trackedAccount = nil 
local botActive = false
local botWaitingForTarget = false -- Tracks if bot is waiting for a player to log back in

-----------------------------
local defmodspd = 20
local defaitime = 5.2
local defsplimit = 150
local defstartdely = 10 
local modspd = ""
local aitime = ""
local splimit = ""
local startdely = ""
-----------------------------

local myTextDisplay = textCreateDisplay ()                                        
local myTextItem = textCreateTextItem ( "HuntBot will start in:", 0.5, 0.048, "low", 255, 0, 0, 255, 1, "center")    
textDisplayAddText ( myTextDisplay, myTextItem ) 

function showtext()
	for i, p in ipairs (getElementsByType("player")) do 
		textDisplayAddObserver(myTextDisplay,p)
	end
end

function hidetext()
	for i, p in ipairs (getElementsByType("player")) do 
		textDisplayRemoveObserver(myTextDisplay,p)
	end
end

function isNumSettingOK(setting,arg)
	if setting and setting >= arg then return setting else return nil end
end

function setupBotSettings(locals,globalse,defs)
	if locals then return locals elseif globalse then return globalse else return defs end
end

-- HELPER: Find a player by partial name
function getPlayerFromPartialName(name)
    local name = name and name:gsub("#%x%x%x%x%x%x", ""):lower() or nil
    if not name then return false end
    for _, player in ipairs(getElementsByType("player")) do
        local name_ = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
        if name_:find(name, 1, true) then
            return player
        end
    end
    return false
end

-- HELPER: Deactivate and hide the bot
function deactivate()
    if isTimer(aitimer) then killTimer(aitimer) end
    if isTimer(delytimer) then killTimer(delytimer) end
    if isTimer(pausetimer) then killTimer(pausetimer) end
    if isElement(dely_MissionTimer) then destroyElement(dely_MissionTimer) end
    hidetext()
    
    moveObject(core, 100, 0, 0, -5000, 0, 0, 0) -- Hide it underground
    botActive = false
    botWaitingForTarget = false
    triggerClientEvent(getRootElement(), "onclientfirstplayerDEAD", getRootElement()) -- Stops client rockets
end

-- ADMIN COMMAND: /track [player/all]
addCommandHandler("track", function(player, cmd, targetName)
    local accountName = getAccountName(getPlayerAccount(player))
    if isGuestAccount(getPlayerAccount(player)) or not isObjectInACLGroup("user."..accountName, aclGetGroup("Admin")) then
        outputChatBox("You do not have permission to use this command.", player, 255, 0, 0)
        return
    end

    if not targetName then
        outputChatBox("Syntax: /track <nick> OR /track all", player, 255, 255, 0)
        return
    end

    if targetName:lower() == "all" then
        huntMode = "all"
        trackedAccount = nil
        outputChatBox("HuntBot is now tracking ALL players. It will deploy after the race countdown.", player, 255, 0, 0)
        
        -- INSTANTLY activate if race is already running
        if racestate == "Running" or racestate == "MidMapVote" then
            if isTimer(delytimer) then killTimer(delytimer) end
            if isElement(dely_MissionTimer) then destroyElement(dely_MissionTimer) end
            hidetext()
            activate()
        end
        return
    end

    -- Specific Player Tracking
    local target = getPlayerFromPartialName(targetName)
    if target then
        local targetAcc = getPlayerAccount(target)
        if isGuestAccount(targetAcc) then
            outputChatBox("Target player is not logged in! They must be logged in to track them.", player, 255, 0, 0)
        else
            trackedAccount = getAccountName(targetAcc)
            huntMode = "player"
            outputChatBox("HuntBot is now tracking account: " .. trackedAccount .. " ("..getPlayerName(target)..")", player, 255, 0, 0)
            
            -- INSTANTLY activate (skip mission timer)
            if isTimer(delytimer) then killTimer(delytimer) end
            if isElement(dely_MissionTimer) then destroyElement(dely_MissionTimer) end
            hidetext()
            if racestate == "Running" or racestate == "MidMapVote" then
                activate()
            end
        end
    else
        outputChatBox("Player not found.", player, 255, 0, 0)
    end
end)

-- ADMIN COMMAND: /untrack
addCommandHandler("untrack", function(player, cmd, arg)
    local accountName = getAccountName(getPlayerAccount(player))
    if isGuestAccount(getPlayerAccount(player)) or not isObjectInACLGroup("user."..accountName, aclGetGroup("Admin")) then
        outputChatBox("You do not have permission to use this command.", player, 255, 0, 0)
        return
    end

    huntMode = "none"
    trackedAccount = nil
    deactivate()
    outputChatBox("HuntBot tracking disabled. It has retreated.", player, 0, 255, 0)
end)

-- LOGIC: Determine who the bot should follow right now
function getTargetPlayer()
    if huntMode == "player" and trackedAccount then
        for _, p in ipairs(getElementsByType("player")) do
            local acc = getPlayerAccount(p)
            if not isGuestAccount(acc) and getAccountName(acc) == trackedAccount then
                return p
            end
        end
    elseif huntMode == "all" then
        local alivePlayers = {}
        for _, p in ipairs(getElementsByType("player")) do
            if getElementData(p, "state") == "alive" then
                table.insert(alivePlayers, p)
            end
        end
        if #alivePlayers > 0 then
            return alivePlayers[math.random(1, #alivePlayers)]
        end
    end
    return false
end

addEventHandler("onRaceStateChanging", getRootElement(), function(state)	
	racestate = state
	if (state == "Running") and (activestate == 1) then
		if huntMode == "all" or huntMode == "player" then
			botActive = false
			activate() -- Instant activation, no timer
		end
	elseif state == "GridCountdown" then
		activestate = 1
		modspd = setupBotSettings(nil, nil, defmodspd)
		aitime = setupBotSettings(nil, nil, defaitime)
		splimit = setupBotSettings(nil, nil, defsplimit)
		startdely = defstartdely
	else
		activestate = 0
		if state == "SomeoneWon" or state == "TimesUp" then
			deactivate()
		end
	end
end)

function activate()
    if botActive or huntMode == "none" then return end
    botActive = true
    botWaitingForTarget = false
    
	local firstplayer = getTargetPlayer()
	if not firstplayer then 
        -- Player logged out before activation, start polling loop anyway!
        botai(nil)
        return 
    end

	local firststate = getElementData(firstplayer, "state")
	for i,pla in ipairs(getElementsByType("player")) do
		triggerClientEvent(pla,"onclientbotstart",pla,coreveh,core,firstplayer,firststate)
	end
	local x,y,z = getElementPosition(firstplayer)
	setElementPosition(core, x+200, y, z+50)
	botai(firstplayer)
	triggerClientEvent(getRootElement(),"onnewfirstplayer",firstplayer,firstplayer)
end

function botai(benfirst)
    if huntMode == "none" then return end -- Kill loop if disabled
	if isTimer(aitimer) then killTimer(aitimer) end

	if (racestate == "Running") or (racestate == "MidMapVote") then
		warpPedIntoVehicle(coreped,coreveh,0)
		
        local firstplayer = getTargetPlayer()
        
        -- IF TARGET DISCONNECTS/LOGS OUT
        if not firstplayer then
            if not botWaitingForTarget then
                botWaitingForTarget = true
                triggerClientEvent(getRootElement(), "onclientfirstplayerDEAD", getRootElement())
                local bx, by, bz = getElementPosition(core)
                moveObject(core, 2000, bx, by, bz + 100) -- Fly up and freeze
            end
            setTimer(botai, 1000, 1, benfirst)
            return
        end

        -- IF TARGET LOGS BACK IN
        if botWaitingForTarget then
            botWaitingForTarget = false
            triggerClientEvent(getRootElement(), "onclientpausestop", firstplayer)
            
            -- If it was waiting underground, warp it above the player so it doesn't take forever to arrive
            local bx, by, bz = getElementPosition(core)
            if bz < -1000 then
                local px, py, pz = getElementPosition(firstplayer)
                setElementPosition(core, px + 200, py, pz + 50)
            end
        end

		if firstplayer ~= benfirst then
			triggerClientEvent(getRootElement(),"onnewfirstplayer",firstplayer,benfirst)
		end	

		local px,py,z = getElementPosition(firstplayer)
        if not px then return end -- Guard against missing coords
		
        local veh = getPedOccupiedVehicle(firstplayer)
        local x,y = px,py
		local vx,vy,vz = 0,0,0
		if veh then vx,vy,vz = getElementVelocity(veh) end
		
		if vx then x = x + 10*modspd*vx end
		if vy then y = y + 10*modspd*vy end 
		
		local bx,by,bz = getElementPosition(core)
		local waypointangle = ( 360 - math.deg ( math.atan2 ( ( x - bx ), ( y - by ) ) ) ) % 360
		local rx,ry,rz = getElementRotation(core)
		local angle = (waypointangle - rz)
		
		if angle < (-180) then angle = (360 - rz + waypointangle)
		elseif angle > 180 then angle = -(360 - waypointangle + rz) end
		
		local distlimit = 0.36*splimit*aitime
		if distlimit < getDistanceBetweenPoints2D(px,py,bx,by) then x,y = px,py end
		
		local realdist = getDistanceBetweenPoints2D(x,y,bx,by)
		local percdist = distlimit/realdist
		if percdist < 1 then
			x = bx + percdist*(x - bx)
			y = by + percdist*(y - by)
		end
		realdist = getDistanceBetweenPoints2D(x,y,bx,by)
		local curspeed = realdist/(0.36*aitime)
		
		local wayhangle = -((30*curspeed)/100)
		if wayhangle <= -30 then wayhangle = -30 end
		local hangle = (360 - rx + wayhangle)
		if hangle > 30 then hangle = -30 end

		if getElementData(firstplayer, "state") == "dead" then
			-- Tell client to stop firing rockets
			triggerClientEvent(getRootElement(),"onclientfirstplayerDEAD",firstplayer)
			
			-- Retreat Logic: Push the bot backward 150 units from the kill zone
            local dirX = bx - px
            local dirY = by - py
            local length = math.sqrt(dirX^2 + dirY^2)
            if length < 1 then length = 1 end
            local retreatX = bx + (dirX / length) * 150
            local retreatY = by + (dirY / length) * 150
            
            -- Move bot to the retreat position (slightly higher in the air) over 2 seconds
            moveObject(core, 2000, retreatX, retreatY, z + 70)
            
            -- Keep polling every second to see if the target (or a new target) has respawned
            local function checkRespawn()
                if huntMode == "none" then return end
                local target = getTargetPlayer()
                if target and getElementData(target, "state") == "alive" then
                    triggerClientEvent(getRootElement(),"onclientpausestop",target)
                    botai(target) -- Instantly strike again!
                else
                    pausetimer = setTimer(checkRespawn, 1000, 1)
                end
            end
            
            -- Wait 2 seconds for the retreat to finish before polling
            pausetimer = setTimer(checkRespawn, 2000, 1)
		else
			moveObject(core,(0.25 * aitime * 1000) - 50,bx + (0.25 *(x - bx)),by + (0.25 * (y - by)),z + 25,hangle,0,angle)
			aitimer = setTimer(function()
				moveObject(core, 0.75 * aitime * 1000, x,y,z+25)
			end,0.25 * aitime * 1000,1)
			setTimer(botai,(aitime * 1000) + 10,1,firstplayer)
		end
	else
		moveObject(core,(0.25 * aitime * 1000) - 50,0,0,-5000,0,0,0)
		triggerClientEvent(getRootElement(),"onclientfirstplayerDEAD", benfirst)
	end
end

addEventHandler("onNewPlayerDetected", getRootElement(),function ()
	local pla = source
	if ((racestate == "Running") or (racestate == "MidMapVote")) and (not isElement(dely_MissionTimer)) and botActive then
		setTimer(function()
            local firstplayer = getTargetPlayer()
            if firstplayer then
                local firststate = getElementData(firstplayer, "state")
                triggerClientEvent(pla,"onclientbotstart",pla,coreveh,core,firstplayer,firststate)
            end
		end,1000,1)
	end
end)

addEventHandler("onMapStarting", getRootElement(),function ()	
	deactivate()
end)