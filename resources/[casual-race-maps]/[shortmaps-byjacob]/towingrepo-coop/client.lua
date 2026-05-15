-- client.lua (Client-side)

addEvent("onTowRaceCompleted", true)
addEventHandler("onTowRaceCompleted", localPlayer, function()
    -- Get the root of the active race resource
    local race_resource = getResourceDynamicElementRoot(getResourceFromName("race"))
    
    if not race_resource then
        outputConsole("[REPO] Race resource not running or not found!")
        return
    end

    -- Grab all colshapes managed by the race map
    local colshapes = getElementsByType("colshape", race_resource)
    
    if #colshapes == 0 then
        outputConsole("[REPO] Something went wrong: No race checkpoints found!")
        return
    end

    local vehicle = getPedOccupiedVehicle(localPlayer)
    if vehicle then
        -- Remotely trigger the hit event on the final race colshape
        triggerEvent("onClientColShapeHit", colshapes[#colshapes], vehicle, true)
    end
end)