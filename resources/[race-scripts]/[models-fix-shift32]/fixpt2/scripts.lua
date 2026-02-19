local models = {

["5113"] = {
		dff = "blockaa_las2.dff",
		col = "blockaa_las2.col",
	},
["5178"] = {
		dff = "cutrdn1_las2.dff",
		col = "cutrdn1_las2.col",
	},
["10087"] = {
		dff = "landsl01_sfe.dff",
		col = "landsl01_sfe.col",
	},
["16190"] = {
		dff = "ne_bit_20.dff",
		col = "ne_bit_20.col",
	},
["11511"] = {
		dff = "nw_bit_09.dff",
		col = "nw_bit_09.col",
	},
["11512"] = {
		dff = "nw_bit_10.dff",
		col = "nw_bit_10.col",
	},
["5188"] = {
		dff = "nwrrdssplt_las2.dff",
		col = "nwrrdssplt_las2.col",
	},
["9556"] = {
		dff = "park2_sfw.dff",
		col = "park2_sfw.col",
	},
["5806"] = {
		dff = "road_lawn17.dff",
		col = "road_lawn17.col",
	},
["5801"] = {
		dff = "road_lawn28.dff",
		col = "road_lawn28.col",
	},

["6311"] = {
		dff = "roads33_law2.dff",
		col = "roads33_law2.col",
	},
["5106"] = {
		dff = "roadsbx_las2.dff",
		col = "roadsbx_las2.col",
	},
["10473"] = {
		dff = "roadssfs28.dff",
		col = "roadssfs28.col",
	},
["11532"] = {
		dff = "sw_bit_03.dff",
		col = "sw_bit_03.col",
	},
["6968"] = {
		col = "vgnsqrefnce2.col",
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


