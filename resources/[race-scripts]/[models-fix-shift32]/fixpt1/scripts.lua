local models = {
	
["13730"] = {
		dff = "ceroad_6.dff",
		col = "ceroad_6.col",
	},

["6321"] = {
		dff = "roads18_law2.dff",
		col = "roads18_law2.col",
	},

["6320"] = {
		dff = "roads15_law2.dff",
		col = "roads15_law2.col",
	},

["6345"] = {
		dff = "roads04_law2.dff",
		col = "roads04_law2.col",
	},


["6330"] = {
		dff = "roads06_law2.dff",
		col = "roads06_law2.col",
	},

["6323"] = {
		dff = "roads21_law2.dff",
		col = "roads21_law2.col",
	},

["6302"] = {
		dff = "roads14_law2.dff",
		col = "roads14_law2.col",
	},

["9617"] = {
		col = "boigagr_sfw.col",
	},

["7661"] = {
		col = "venetiancpark05.col",
	},

["5813"] = {
		col = "lawnshop1.col",
	},

["17526"] = {
		col = "gangshops1_lae.col",
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







