-- paramedic_s.lua (Server-side)

local pedLocations = {}
local activePeds = {}
local hospitalMarker = nil
local hospLoc = {x=0, y=0, z=0}
local currentLevel = 0
local pedsDeliveredThisLevel = 0
local totalPedsThisLevel = 0

addEventHandler("onResourceStart", resourceRoot, function()
    outputChatBox("This race is based on the real Paramedics sub-mission. Locations are random. #000096Patients#FFFFFF were put in the editor to determinate the coordinates, so they are not random-random, the coordinates are copied from the editor. It would be too risky to create random #000096patients#FFFFFF with scripts and for example: they would end up inside walls. Deliver them safely to the #FFFF00Hospital#FFFFFF. Enjoy!", root, 255, 255, 255, true)

    local markers = getElementsByType("marker", resourceRoot)
    for _, m in ipairs(markers) do
        if getMarkerType(m) == "cylinder" then
            hospitalMarker = m
            hospLoc.x, hospLoc.y, hospLoc.z = getElementPosition(hospitalMarker)
            createBlip(hospLoc.x, hospLoc.y, hospLoc.z, 22, 2, 255, 255, 0, 255, 0, 99999.0, root)
            break
        end
    end

    local mapPeds = getElementsByType("ped", resourceRoot)
    for _, p in ipairs(mapPeds) do
        local x, y, z = getElementPosition(p)
        local rz = getPedRotation(p)
        table.insert(pedLocations, {x=x, y=y, z=z, rz=rz, dist=getDistanceBetweenPoints3D(x, y, z, hospLoc.x, hospLoc.y, hospLoc.z)})
        destroyElement(p)
    end
end)

addEvent("onRaceStateChanging", true)
addEventHandler("onRaceStateChanging", getRootElement(), function(newState, oldState)
    if newState == "Running" then
        for i, player in ipairs(getElementsByType("player")) do
            triggerClientEvent(player, "startParamedicMission", player)
        end
        startLevel(1)
    end
end)

function startLevel(level)
    if level > 12 then return end
    currentLevel = level
    totalPedsThisLevel = level
    pedsDeliveredThisLevel = 0
    
    -- Clear previous level's active peds table to avoid overlaps/bugs
    activePeds = {} 
    
    local availableLocations = {}
    for i, loc in ipairs(pedLocations) do table.insert(availableLocations, loc) end
    table.sort(availableLocations, function(a, b) return a.dist < b.dist end)
    
    local selectedLocations = {}
    
    -- Increased pool sizes slightly so the distance filter has enough options to actually work
    if level <= 2 then
        for i=1, math.min(#availableLocations, 15) do table.insert(selectedLocations, availableLocations[i]) end
    elseif level == 3 then
        for i=1, math.min(#availableLocations, 20) do table.insert(selectedLocations, availableLocations[i]) end
    else
        local poolSize = math.min(#availableLocations, level * 10)
        for i=1, poolSize do table.insert(selectedLocations, availableLocations[i]) end
    end
    
    -- Shuffle the valid pool
    for i = #selectedLocations, 2, -1 do
        local j = math.random(i)
        selectedLocations[i], selectedLocations[j] = selectedLocations[j], selectedLocations[i]
    end
    
    local finalPeds = {}
    
    -- Dynamic spread tuning based on level progression
    local minSpawnDistance = 60.0
    if currentLevel >= 11 then
        minSpawnDistance = 90.0
    elseif currentLevel >= 9 then
        minSpawnDistance = 80.0
    elseif currentLevel >= 7 then
        minSpawnDistance = 70.0
    elseif currentLevel >= 4 then
        minSpawnDistance = 65.0
    end
    
    -- Filtering logic to ensure peds aren't spawned directly next to each other
    for _, loc in ipairs(selectedLocations) do
        local tooClose = false
        for _, pickedLoc in ipairs(finalPeds) do
            if getDistanceBetweenPoints3D(loc.x, loc.y, loc.z, pickedLoc.x, pickedLoc.y, pickedLoc.z) < minSpawnDistance then
                tooClose = true
                break
            end
        end
        
        if not tooClose then
            table.insert(finalPeds, loc)
        end
        
        if #finalPeds >= totalPedsThisLevel then break end
    end
    
    -- Fallback safety check: Just in case the filtering above removes too many coordinates
    if #finalPeds < totalPedsThisLevel then
        for _, loc in ipairs(selectedLocations) do
            if #finalPeds >= totalPedsThisLevel then break end
            local alreadyIn = false
            for _, p in ipairs(finalPeds) do 
                if p == loc then alreadyIn = true break end 
            end
            if not alreadyIn then 
                table.insert(finalPeds, loc) 
            end
        end
    end
    
    local spawnedPedsForClient = {}
    
    for i = 1, totalPedsThisLevel do
        local loc = finalPeds[i]
        if loc then
            local ped = false
            -- Safe-guard: MTA's createPed returns 'false' for some invalid random model IDs.
            -- This loop guarantees we grab a valid ped ID before proceeding.
            while not ped do
                ped = createPed(math.random(10, 250), loc.x, loc.y, loc.z, loc.rz)
            end
            
            local blip = createBlipAttachedTo(ped, 0, 2, 0, 0, 150, 255)
            setElementData(ped, "paramedic_target", true)
            setElementData(ped, "spawn_dist", loc.dist) 
            table.insert(activePeds, {element = ped, blip = blip})
            table.insert(spawnedPedsForClient, ped)
        end
    end
    
    triggerClientEvent("onLevelStart", resourceRoot, currentLevel, spawnedPedsForClient)
end

setTimer(function()
    if currentLevel == 0 then return end
    
    for _, player in ipairs(getElementsByType("player")) do
        local veh = getPedOccupiedVehicle(player)
        if veh and getElementModel(veh) == 416 then 
            local vx, vy, vz = getElementPosition(veh)
            local speed = (Vector3(getElementVelocity(veh))).length
            
            if speed < 0.05 then
                if getDistanceBetweenPoints3D(vx, vy, vz, hospLoc.x, hospLoc.y, hospLoc.z) < 6.0 then
                    local occupants = getVehicleOccupants(veh)
                    local droppedOff = 0
                    
                    for seat, occupant in pairs(occupants) do
                        if seat > 0 and getElementType(occupant) == "ped" and getElementData(occupant, "paramedic_target") then
                            destroyElement(occupant)
                            droppedOff = droppedOff + 1
                            pedsDeliveredThisLevel = pedsDeliveredThisLevel + 1
                        end
                    end
                    
                    if droppedOff > 0 then
                        triggerClientEvent(player, "onPatientsDropped", player, droppedOff, currentLevel)
                        
                        if pedsDeliveredThisLevel >= totalPedsThisLevel then
                            triggerClientEvent(player, "onLevelCompleted", player, currentLevel)
                            
                            if currentLevel == 12 then
                                triggerClientEvent(player, "onMissionPassed", player)
                            else
                                startLevel(currentLevel + 1)
                            end
                        end
                    end
                end

                for i, pedData in ipairs(activePeds) do
                    local ped = pedData.element
                    if isElement(ped) and not getPedOccupiedVehicle(ped) and not getElementData(ped, "entering_veh") then
                        local px, py, pz = getElementPosition(ped)
                        if getDistanceBetweenPoints3D(vx, vy, vz, px, py, pz) < 15.0 then
                            local emptySeat = getEmptyAmbulanceSeat(veh)
                            if emptySeat then
                                setElementData(ped, "entering_veh", true)
                                
                                local distFromHospital = getElementData(ped, "spawn_dist") or 0
                                if isElement(pedData.blip) then destroyElement(pedData.blip) end
                                triggerClientEvent(player, "onPedPickedUp", player, ped, distFromHospital)
                                
                                setTimer(function(p, v, s)
                                    if isElement(p) and isElement(v) and not getPedOccupiedVehicle(p) then
                                        warpPedIntoVehicle(p, v, s)
                                    end
                                end, 250, 1, ped, veh, emptySeat)
                            else
                                triggerClientEvent(player, "onAmbulanceFull", player)
                            end
                        end
                    end
                end
            end
        end
    end
end, 1000, 0)

function getEmptyAmbulanceSeat(veh)
    for seat = 1, 3 do
        if not getVehicleOccupant(veh, seat) then return seat end
    end
    return nil
end

addEventHandler("onPedWasted", resourceRoot, function(totalAmmo, killer, killerWeapon)
    if getElementData(source, "paramedic_target") and killer and getElementType(killer) == "vehicle" then
        local driver = getVehicleOccupant(killer, 0)
        if driver then
            killPed(driver)
            triggerClientEvent(driver, "onMissionFailed", driver, "You dolt! You were supposed to save them, not kill them!")
        end
    end
end)