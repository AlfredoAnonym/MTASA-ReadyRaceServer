--made by Wojak aka Wojak[PL] aka [2RT]Wojak [PL]
--Remixed for global mayhem, fast start, and direct aiming

addEvent("onclientbotstart",true)
addEvent("onclientfirstplayerDEAD",true)
addEvent("onclientpausestop",true)
addEvent("onnewfirstplayer",true)
addEvent("onClientMapStarting",true)

local screenWidth, screenHeight = guiGetScreenSize()
local state = 0
local shoot = 1
local dist = 0

-- Helper function to fire a rocket straight at the player
function fireHomingRocket(veh, speed)
    local px, py, pz = getElementPosition(getLocalPlayer())
    local x, y, z = getElementPosition(veh)
    local rx, ry, rz = getElementRotation(veh)
    
    -- Aim slightly ahead/center of the player's car
    local targetZ = pz + 0.5 
    local startZ = z - 3.5 -- Spawn beneath the hunter so it doesn't hit itself
    
    -- Calculate directional vector
    local dirX, dirY, dirZ = px - x, py - y, targetZ - startZ
    local distance = math.sqrt(dirX^2 + dirY^2 + dirZ^2)
    
    -- Apply velocity
    local vX = (dirX / distance) * speed
    local vY = (dirY / distance) * speed
    local vZ = (dirZ / distance) * speed

    createProjectile(getLocalPlayer(), 19, x, y, startZ, 1, nil, rx, ry, rz, vX, vY, vZ)
end

function rock(veh,obj,n)
	local n2 = n+1
	if isTimer(rocktimer) then
		killTimer(rocktimer)
	end
	if state == 1 then
		local ox,oy,oz = getElementPosition(obj)
		local px,py,pz = getElementPosition(getLocalPlayer())
		dist = getDistanceBetweenPoints2D(px,py,ox,oy)
        
        if (shoot == 1) and (dist < 160) and (getElementData(getLocalPlayer(), "state") == "alive") then
            -- Fire Rocket 1 (Speed 3.0)
            fireHomingRocket(veh, 3.0)
            
            setTimer(function()
                if isElement(obj) and isElement(veh) then
                    -- Fire Rocket 2 (Speed 3.5)
                    fireHomingRocket(veh, 3.5)
                    
                    setTimer(function()
                        if isElement(obj) and isElement(veh) then
                            -- Fire Rocket 3 (Speed 4.0)
                            fireHomingRocket(veh, 4.0)
                        end
                    end, 1000, 1)
                end
            end, 1000, 1)
        end
		rocktimer = setTimer(rock,3000,1,veh,obj,n2)
	end
end

function rockbufor(veh,obj,first,fstate)
	if isElement(first) then
		localfirstplayer = first
	end
	state = 0
	setTimer(function()
		state = 1
		if fstate ~= "dead" then
			shoot = 1
		end
		rock(veh,obj,1)
	end, 500, 1) -- Cut the old 4000ms delay down to 500ms
end

addEventHandler("onclientbotstart", getRootElement(), rockbufor)

addEventHandler("onclientfirstplayerDEAD", getRootElement(), function()
	shoot = 0
end)

addEventHandler("onclientpausestop", getRootElement(), function()
	shoot = 1
end)

addEventHandler("onnewfirstplayer", getRootElement(), function(olsfirst)
	localfirstplayer = source
end)

addEventHandler("onClientMapStarting", getRootElement(), function(olsfirst)
	state = 0
	shoot = 0
end)

triggerServerEvent("onNewPlayerDetected", getLocalPlayer())