-- repo.lua (Server-side)

local targetModels = {
    [600] = true, -- Picador
    [555] = true, -- Windsor
    [560] = true, -- Sultan
    [402] = true, -- Buffalo
}

local targetVehicles = {}
local blips = {}
local deliveredCount = 0
local totalVehicles = 0

local policeGarageMarker = nil
local customFinishCheckpoint = nil

addEventHandler("onResourceStart", resourceRoot, function()
    outputChatBox("[INFO] Tow all the vehicles to the SF Police Department to finish the map.", root, 255, 200, 0)

    -- 1. Find the delivery marker (police garage) and add Police Blip (30)
    local markers = getElementsByType("marker", resourceRoot)
    for _, m in ipairs(markers) do
        if getMarkerType(m) == "cylinder" then
            policeGarageMarker = m
            addEventHandler("onMarkerHit", policeGarageMarker, onPoliceGarageHit)
            
            -- Create the Police station blip directly on the cylinder
            local mx, my, mz = getElementPosition(policeGarageMarker)
            createBlip(mx, my, mz, 30, 2, 255, 0, 0, 255, 0, 99999.0, root)
            break
        end
    end

    -- 2. Setup target vehicles and Impound Blips (55)
    local vehicles = getElementsByType("vehicle", resourceRoot)
    for i, veh in ipairs(vehicles) do
        local model = getElementModel(veh)
        if targetModels[model] then
            totalVehicles = totalVehicles + 1
            targetVehicles[veh] = true
            
            -- Add the impound blip to each target car
            blips[veh] = createBlipAttachedTo(veh, 55)
        end
    end
end)

function onPoliceGarageHit(hitElement, matchingDimension)
    -- Ensure it's a vehicle hitting the marker in the correct dimension
    if not matchingDimension or getElementType(hitElement) ~= "vehicle" then return end

    local vehToDeliver = nil

    if targetVehicles[hitElement] then
        vehToDeliver = hitElement
    elseif getElementModel(hitElement) == 525 then
        local towed = getVehicleTowedByVehicle(hitElement)
        if towed and targetVehicles[towed] then
            vehToDeliver = towed
        end
    end

    if vehToDeliver then
        deliveredCount = deliveredCount + 1
        outputChatBox("[REPO] Vehicle delivered! (" .. deliveredCount .. "/" .. totalVehicles .. ")", root, 0, 255, 0)

        -- Cleanup the vehicle and its blip
        if isElement(blips[vehToDeliver]) then
            destroyElement(blips[vehToDeliver])
        end
        destroyElement(vehToDeliver)
        targetVehicles[vehToDeliver] = nil

        -- Check if all vehicles are delivered
        if deliveredCount >= totalVehicles then
            outputChatBox("[REPO] All vehicles delivered! The finish checkpoint is now activated at the garage!", root, 0, 255, 0)
            
            -- 3. Create a custom "Fake" checkpoint at the garage
            local mx, my, mz = getElementPosition(policeGarageMarker)
            
            -- CHANGED: Now a "cylinder", size 5, matching the ground Z-level perfectly.
            -- I set it to a nice bright blue (0, 0, 255, 150) to make it look like a finish point, 
            -- but you can change the RGB values if you want it a different color!
            customFinishCheckpoint = createMarker(mx, my, mz, "cylinder", 5, 0, 0, 255, 150)
            createBlipAttachedTo(customFinishCheckpoint, 53) -- Finish flag blip
            
            addEventHandler("onMarkerHit", customFinishCheckpoint, onCustomFinishHit)
        end
    end
end

function onCustomFinishHit(hitElement, matchingDimension)
    if not matchingDimension or getElementType(hitElement) ~= "vehicle" then return end
    
    -- When the Towtruck hits our custom garage checkpoint, trigger the remote collection!
    if getElementModel(hitElement) == 525 then
        local driver = getVehicleOccupant(hitElement)
        if driver then
            triggerClientEvent(driver, "onTowRaceCompleted", driver)
        end
    end
end