-- Shared Script: Force 30 FPS for all maps.
-- Load this file as both "server" and "client" in your meta.xml.

if not localPlayer then
    --------------------------------------------------
    -- SERVER-SIDE LOGIC
    --------------------------------------------------
    local readyClients = {} 

    addEventHandler("onResourceStart", resourceRoot, function()
        local serverFPS = getServerConfigSetting("fpslimit") or 60 
    end)

    addEvent("onClientReadyForFPS", true)
    addEventHandler("onClientReadyForFPS", resourceRoot, function()
        local serverFPS = getServerConfigSetting("fpslimit") or 60
        readyClients[client] = true 
        triggerClientEvent(client, "onClientReceiveForceFPSServerFPS", resourceRoot, serverFPS)
    end)

    addEvent("onClientRequestServerFPS", true)
    addEventHandler("onClientRequestServerFPS", resourceRoot, function()
        local serverFPS = getServerConfigSetting("fpslimit") or 60
        if readyClients[client] then
            triggerClientEvent(client, "onClientReceiveForceFPSServerFPS", resourceRoot, serverFPS)
        end
    end)

    addEventHandler("onPlayerQuit", root, function()
        readyClients[source] = nil
    end)

else
    --------------------------------------------------
    -- CLIENT-SIDE LOGIC
    --------------------------------------------------
    addEvent("onClientReceiveForceFPSServerFPS", true)

    local forcedFPS = 30 
    local originalFPS = nil 
    local isFPSForced = false 

    -- Added a 'silent' parameter to avoid chat spam on restarts
    function resetFPS(silent)
        if isFPSForced then 
            if not originalFPS then
                originalFPS = 60 
            end
            setFPSLimit(originalFPS)
            isFPSForced = false
            if not silent then
                outputChatBox("#55FF55[Race] #FFFFFFRestored original FPS to " .. tostring(originalFPS) .. ".", 255, 255, 255, true)
            end
        end
    end

    function applyFPSCap()
        if not isFPSForced then
            setFPSLimit(forcedFPS) 
            isFPSForced = true
            outputChatBox("#FF5555[Race] #FFFFFFThis map is configured to run at 30 FPS.", 255, 255, 255, true)
        end
    end

    addEventHandler("onClientReceiveForceFPSServerFPS", resourceRoot, function(serverFPS)
        originalFPS = serverFPS
        -- Only apply the cap immediately if a race is actually running
        local raceResource = getResourceFromName("race")
        if raceResource and getResourceState(raceResource) == "running" then
            applyFPSCap()
        end
    end)

    addEvent("onClientMapStarting", true)
    addEventHandler("onClientMapStarting", root, function()
        applyFPSCap()
    end)

    addEventHandler("onClientResourceStart", resourceRoot, function()
        triggerServerEvent("onClientReadyForFPS", resourceRoot)
        
        -- Retry timers
        local retryDelays = {5000, 10000, 15000}
        for _, delay in ipairs(retryDelays) do
            setTimer(function()
                if not originalFPS then
                    triggerServerEvent("onClientRequestServerFPS", resourceRoot)
                end
            end, delay, 1)
        end
        
        -- Final fallback
        setTimer(function()
            if not originalFPS then
                originalFPS = 60
                local raceResource = getResourceFromName("race")
                if raceResource and getResourceState(raceResource) == "running" then
                    applyFPSCap()
                end
            end
        end, 20000, 1)
    end)

    -- Trigger normal reset when the race naturally ends
    addEvent("onClientRaceStateChanging", true)
    addEventHandler("onClientRaceStateChanging", root, function(newState)
        if isFPSForced and (newState == "timesup" or newState == "everyonefinished" or newState == "postfinish") then
            resetFPS(false) -- not silent
        end
    end)

    -- Silently restore if the map/resource is stopped abruptly (like a restart)
    addEventHandler("onClientResourceStop", resourceRoot, function()
        resetFPS(true) -- silent
    end)

    -- Restore if the entire race gamemode gets shut down
    addEventHandler("onClientResourceStop", root, function(stoppedResource)
        if getResourceName(stoppedResource) == "race" then
            resetFPS(false) 
        end
    end)

    addCommandHandler("resetfps", function()
        if isFPSForced then
            resetFPS(false)
        else
            outputChatBox("#FF5555[Race] #FFFFFFFPS is not currently capped.", 255, 255, 255, true)
        end
    end)
end