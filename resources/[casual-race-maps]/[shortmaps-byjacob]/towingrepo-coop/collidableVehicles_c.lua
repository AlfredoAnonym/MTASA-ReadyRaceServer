addEventHandler("onClientRender", root, function()
	local playerVehicle = getPedOccupiedVehicle(localPlayer)
	if isElement(playerVehicle) then
		for _, veh in ipairs(getElementsByType("vehicle")) do
			if getElementData(veh, "race.collideothers") == 1 then
				setElementCollidableWith(playerVehicle, veh, true)
			end
		end
	end
end )
