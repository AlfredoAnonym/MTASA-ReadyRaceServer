local models = {

["3335"] = {
		dff = "ce_roadsign1.dff",
	},
}

addEventHandler("onClientResourceStart",resourceRoot,
function()
	for id, data in pairs(models) do
		local n = tonumber(id)
		engineReplaceModel(engineLoadDFF(data.dff, n), n)
		engineReplaceCOL(engineLoadCOL(data.col, n), n)
	end
end)

addEventHandler("onClientResourceStop",resourceRoot,
function()
	for id, data in pairs(models) do
		local n = tonumber(id)
		engineRestoreCOL(n)
		engineRestoreModel(n)
	end
end)




