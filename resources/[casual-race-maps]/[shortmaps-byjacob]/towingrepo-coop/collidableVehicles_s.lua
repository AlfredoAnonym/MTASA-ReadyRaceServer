addEventHandler("onResourceStart", resourceRoot, function()
	outputChatBox("Notice: Collisions with static vehicles is enabled on this map")
	for _, veh in ipairs(getElementsByType("vehicle")) do
		setVehicleDamageProof(veh, true)
		setElementFrozen(veh, false)
		setElementData(veh, "race.collideothers", 1, true)
	end
end )
