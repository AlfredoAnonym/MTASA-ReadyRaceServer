local models = {

["9719"] = {
		dff = "road_sfw37.dff",
		col = "road_sfw37.col",
	},

["13101"] = {
		col = "palomino_fix.col",
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




