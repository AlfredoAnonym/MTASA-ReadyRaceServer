function onResourceStart()
	for i,player in pairs(getElementsByType("player")) do
		local country = call(getResourceFromName("admin"),"getPlayerCountry",player)
		if not country then
			country = "N/A"
		end
		setElementData(player,"country",country)
	end
end
addEventHandler("onResourceStart",getResourceRootElement(getThisResource()),onResourceStart)

function onPlayerJoin()
	local country = call(getResourceFromName("admin"),"getPlayerCountry",source)
	if not country then
		country = "N/A"
	end
	setElementData(source,"country",country)
end
addEventHandler("onPlayerJoin",getRootElement(),onPlayerJoin)
