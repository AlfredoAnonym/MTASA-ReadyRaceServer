-- paramedic_c.lua (Client-side)

local screenX, screenY = guiGetScreenSize()
local offsets = (math.floor(screenX / screenY) >= 1.7) and {0.8, 0.92} or {0.72, 0.9}

local timer = 55
local TimerS = nil
local missionActive = false
local failedText = false
local passedText = false
local introText = false 
local timeBonusString = false
local seatsLeft = 3
local currentLevel = 0 
local bottomWarning = ""
local pedArrows = {}
local patientHealth = 100

addEvent("startParamedicMission", true)
addEventHandler("startParamedicMission", getRootElement(), function()
    missionActive = true
    patientHealth = 100
    
    -- Reduced delay to 250ms so it appears quickly, stays for 4000ms
    setTimer(function()
        introText = true
        setTimer(function() introText = false end, 4000, 1)
    end, 250, 1)
    
    if not isTimer(TimerS) then 
        TimerS = setTimer(updateParamedicTimer, 1000, 0) 
    end
end)

addEvent("onLevelStart", true)
addEventHandler("onLevelStart", getRootElement(), function(level, peds)
    currentLevel = level 
    
    if currentLevel == 1 then
        bottomWarning = "Drive the patients to Hospital CAREFULLY. Each bump reduces their chances of survival"
        setTimer(function() bottomWarning = "" end, 8000, 1)
    end
    
    for _, ped in ipairs(peds) do
        if isElement(ped) then
            local arrow = createMarker(0, 0, 0, "arrow", 0.5, 0, 0, 150, 200)
            attachElements(arrow, ped, 0, 0, 1.8) 
            pedArrows[ped] = arrow
        end
    end
end)

addEvent("onPedPickedUp", true)
addEventHandler("onPedPickedUp", localPlayer, function(ped, distFromHospital)
    if pedArrows[ped] and isElement(pedArrows[ped]) then
        destroyElement(pedArrows[ped])
        pedArrows[ped] = nil
    end

    local timeBonusAmount = 0
    
    -- Dynamic pickup bonuses for Level 4+ based on time remaining and distance
    if currentLevel >= 4 then
        if timer <= 30 then
            -- Time is critically low, give a massive bonus to save the run
            timeBonusAmount = math.random(40, 50)
        elseif timer >= 130 then
            -- Time is very high (2:10+), drastically lower the bonus
            timeBonusAmount = math.random(5, 10)
        elseif timer <= 90 then 
            -- Time is under 1:30, give a moderate bonus if far away
            if distFromHospital > 300 then
                timeBonusAmount = math.random(25, 35)
            else
                timeBonusAmount = math.random(18, 25)
            end
        else
            -- Time is between 1:30 and 2:10
            timeBonusAmount = math.random(12, 18)
        end
    elseif distFromHospital > 300 then 
        timeBonusAmount = math.random(20, 25) 
    else 
        timeBonusAmount = math.random(15, 20) 
    end
    
    if timeBonusAmount > 0 then
        timer = timer + timeBonusAmount
        timeBonusString = "+"..timeBonusAmount.." seconds"
        setTimer(function() timeBonusString = false end, 2000, 1)
    end
    
    seatsLeft = seatsLeft - 1
end)

addEvent("onPatientsDropped", true)
addEventHandler("onPatientsDropped", localPlayer, function(droppedOff, levelAtTime)
    seatsLeft = 3 
    patientHealth = 100 
    
    local bonus = 0

    -- Severely reduced drop-off bonuses to balance the pickup bonuses
    if droppedOff == 3 then
        bonus = math.random(10, 15)
    else
        bonus = math.random(5, 10)
    end

    if bonus > 0 then
        timer = timer + bonus
        timeBonusString = "BONUS! +"..bonus.." seconds"
        setTimer(function() timeBonusString = false end, 3000, 1)
    end
end)

addEvent("onAmbulanceFull", true)
addEventHandler("onAmbulanceFull", localPlayer, function()
    bottomWarning = "Ambulance is FULL! Drop patients off at the hospital first!"
    setTimer(function() bottomWarning = "" end, 3000, 1)
end)

addEvent("onLevelCompleted", true)
addEventHandler("onLevelCompleted", localPlayer, function(level)
    local race_resource = getResourceDynamicElementRoot(getResourceFromName("race"))
    if race_resource then
        local colshapes = getElementsByType("colshape", race_resource)
        local vehicle = getPedOccupiedVehicle(localPlayer)
        
        if #colshapes > 0 and vehicle then
            triggerEvent("onClientColShapeHit", colshapes[1], vehicle, true)
        end
    end
end)

addEvent("onMissionFailed", true)
addEventHandler("onMissionFailed", localPlayer, function(reason)
    if isTimer(TimerS) then killTimer(TimerS) end
    missionActive = false
    failedText = reason
end)

addEvent("onMissionPassed", true)
addEventHandler("onMissionPassed", localPlayer, function()
    if isTimer(TimerS) then killTimer(TimerS) end
    missionActive = false
    passedText = true
    setTimer(function() passedText = false end, 6000, 1)
end)

addEventHandler("onClientVehicleDamage", getRootElement(), function(attacker, weapon, loss)
    if source == getPedOccupiedVehicle(localPlayer) and missionActive and seatsLeft < 3 then
        patientHealth = patientHealth - 10 
        
        if patientHealth <= 0 then
            setElementHealth(localPlayer, 0)
            triggerEvent("onMissionFailed", localPlayer, "The patients died from their injuries!")
        else
            bottomWarning = "Careful, the patients are hurt!"
            setTimer(function() bottomWarning = "" end, 3000, 1)
        end
    end
end)

function updateParamedicTimer()
    if not missionActive then return end
    timer = timer - 1
    if timer <= 0 then
        killTimer(TimerS)
        setElementHealth(localPlayer, 0)
        triggerEvent("onMissionFailed", localPlayer, "You ran out of time!")
    end
end

addEventHandler("onClientRender", root, function()
    local tick = getTickCount()
    for ped, arrow in pairs(pedArrows) do
        if isElement(ped) and isElement(arrow) then
            local zOffset = 1.8 + math.sin(tick / 250) * 0.15
            setElementAttachedOffsets(arrow, 0, 0, zOffset)
        else
            pedArrows[ped] = nil
        end
    end

    if introText then
        dxDrawBorderedText(2, "PARAMEDIC", 0, 0, screenX, screenY*0.5, tocolor(255, 200, 0, 255), 3, "pricedown", "center", "center")
    end

    if failedText then
        dxDrawBorderedText(1, "Mission Failed!", 0, 0, screenX, screenY*0.75, tocolor(156, 22, 25, 255), 3, "pricedown", "center", "center")
        dxDrawBorderedText(1, failedText, 0, 0, screenX, screenY*0.90, tocolor(255, 0, 0, 255), 1.5, "default-bold", "center", "bottom")
    end

    if passedText then
        dxDrawBorderedText(1, "Mission Passed!", 0, 0, screenX, screenY*0.75, tocolor(145, 103, 21, 255), 3, "pricedown", "center", "center")
    end
    
    if bottomWarning ~= "" and not failedText then
        dxDrawBorderedText(1, bottomWarning, 0, 0, screenX, screenY*0.90, tocolor(200, 200, 200, 255), 1.5, "default-bold", "center", "bottom")
    end

    if timeBonusString then 
        dxDrawBorderedText(2, timeBonusString, 0, 0, screenX, screenY*0.83, tocolor(194, 194, 194, 255), 1.2, "bankgothic", "center", "bottom") 
    end

    if not missionActive then return end

    local m = math.floor(timer / 60)
    local s = timer - m*60
    local timeStr = (s < 10) and (m.. ":0" ..s) or (m.. ":" ..s)

    dxDrawBorderedText(2, "LEVEL", screenX * offsets[1], screenY * 0.17, screenX, screenY, tocolor(194, 194, 194, 255), 1, "bankgothic")
    dxDrawBorderedText(2, tostring(currentLevel), screenX * offsets[2], screenY * 0.17, screenX, screenY, tocolor(194, 194, 194, 255), 1, "bankgothic")

    dxDrawBorderedText(2, "TIME LEFT", screenX * offsets[1], screenY * 0.22, screenX, screenY, tocolor(194, 194, 194, 255), 1, "bankgothic")
    dxDrawBorderedText(2, timeStr, screenX * offsets[2], screenY * 0.22, screenX, screenY, tocolor(194, 194, 194, 255), 1, "bankgothic")
    
    dxDrawBorderedText(2, "SEATS LEFT", screenX * offsets[1], screenY * 0.27, screenX, screenY, tocolor(194, 194, 194, 255), 1, "bankgothic")
    dxDrawBorderedText(2, tostring(seatsLeft), screenX * offsets[2], screenY * 0.27, screenX, screenY, tocolor(194, 194, 194, 255), 1, "bankgothic")
    
    if seatsLeft < 3 then
        dxDrawBorderedText(2, "PATIENTS HEALTH", screenX * offsets[1], screenY * 0.32, screenX, screenY, tocolor(194, 194, 194, 255), 0.8, "bankgothic")
        dxDrawRectangle(screenX * offsets[1], screenY * 0.35, 150, 15, tocolor(0, 0, 0, 200))
        
        local hpWidth = (math.max(patientHealth, 0) / 100) * 146
        local r, g, b = 255 - (patientHealth * 2.55), patientHealth * 2.55, 0
        dxDrawRectangle(screenX * offsets[1] + 2, screenY * 0.35 + 2, hpWidth, 11, tocolor(r, g, b, 255))
    end
end)

function dxDrawBorderedText(outline, text, left, top, right, bottom, color, scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
    if type(scaleY) == "string" then
        scaleY, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY = scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX
    end
    local outlineX = (scaleX or 1) * (1.333333333333334 * (outline or 1))
    local outlineY = (scaleY or 1) * (1.333333333333334 * (outline or 1))
    dxDrawText(text:gsub("#%x%x%x%x%x%x", ""), left - outlineX, top - outlineY, right - outlineX, bottom - outlineY, tocolor(0, 0, 0, 225), scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
    dxDrawText(text:gsub("#%x%x%x%x%x%x", ""), left + outlineX, top - outlineY, right + outlineX, bottom - outlineY, tocolor(0, 0, 0, 225), scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
    dxDrawText(text:gsub("#%x%x%x%x%x%x", ""), left - outlineX, top + outlineY, right - outlineX, bottom + outlineY, tocolor(0, 0, 0, 225), scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
    dxDrawText(text:gsub("#%x%x%x%x%x%x", ""), left + outlineX, top + outlineY, right + outlineX, bottom + outlineY, tocolor(0, 0, 0, 225), scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
    dxDrawText(text:gsub("#%x%x%x%x%x%x", ""), left - outlineX, top, right - outlineX, bottom, tocolor(0, 0, 0, 225), scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
    dxDrawText(text:gsub("#%x%x%x%x%x%x", ""), left + outlineX, top, right + outlineX, bottom, tocolor(0, 0, 0, 225), scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
    dxDrawText(text:gsub("#%x%x%x%x%x%x", ""), left, top - outlineY, right, bottom - outlineY, tocolor(0, 0, 0, 225), scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
    dxDrawText(text:gsub("#%x%x%x%x%x%x", ""), left, top + outlineY, right, bottom + outlineY, tocolor(0, 0, 0, 225), scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
    dxDrawText(text, left, top, right, bottom, color, scaleX, scaleY, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
end