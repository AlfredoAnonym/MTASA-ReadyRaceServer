-- Stats
totalConesBroken = 0
citySlickingTime = 0
burnAndLapTime = 0
testAttempts = 0
displayStats = false
statsInited = false
statsAlpha = 0
statsPage = 0 -- 0 is player, 1 is burn and lap, 2 is city slicking, 3 is all golds
displayedStats = {}

-- Actual data in the leaderboards
local displayedLeaderboards = {
	[1] = { name = "Burn and Lap", data = {} },
	[2] = { name = "City Slicking", data = {} },
	[3] = { name = "All Golds", data = {} }
}

addEventHandler("onClientRender", root, function()
	if not showLevelResults and displayStats then
		-- Fade In
		if statsAlpha < 255 then statsAlpha = statsAlpha + 51
		else statsAlpha = 255 end
	else
		-- Fade out
		if statsAlpha > 0 then statsAlpha = statsAlpha - 51
		else statsAlpha = 0 end
	end

	-- Draw Stats
	if statsAlpha > 200 then
		dxDrawRectangle(screenX*s_offsets[1], screenY*s_offsets[2], screenX*s_offsets[3], screenY*s_offsets[4], tocolor(0, 0, 0, 200, 50))
	else
		dxDrawRectangle(screenX*s_offsets[1], screenY*s_offsets[2], screenX*s_offsets[3], screenY*s_offsets[4], tocolor(0, 0, 0, statsAlpha, 50))
	end
	drawStats()
end )

-- Called from key bind and finish of the race
function showStats()
	-- Request data for stats
	triggerServerEvent("getStats", getLocalPlayer())

	-- Show stats
	displayStats = not displayStats
end

-- Function that draws stats on the screen
function drawStats()
	if not statsInited then return end
	if statsPage == 0 then -- Player Stats
		local nick = getPlayerName(localPlayer):gsub("#%x%x%x%x%x%x", "")
		if displayedStats["playername"] == "guest" then nick = nick..  " (guest)" end

		dxDrawText(nick, screenX*(st_offsets[1]+0.005), screenY*(st_offsets[2]+0.003), screenX, screenY, tocolor(0, 0, 0, statsAlpha), st_offsets[5]*4.02, st_offsets[5]*4.15, "beckett")
		dxDrawText(nick, screenX*st_offsets[1], screenY*st_offsets[2], screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[5]*4, st_offsets[5]*4, "beckett")

		dxDrawText("BEST TIME AT:", screenX*st_offsets[1], screenY*(st_offsets[2]+0.10), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Burn and Lap", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.13), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("City Slicking", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.16), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("All Golds", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.19), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")

		dxDrawText("TOTAL:", screenX*st_offsets[1], screenY*(st_offsets[2]+0.25), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Cones Destroyed", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.28), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Tests Passed", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.31), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Tests Attempted", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.34), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Times Won", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.37), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Time Played", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.40), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Gold Medals", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.43), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Silver Medals", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.46), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Bronze Medals", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.49), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")

		dxDrawText("MAP RECORDS:", screenX*st_offsets[1], screenY*(st_offsets[2]+0.55), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Cones Destroyed", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.58), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")
			dxDrawText("Times Played", screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.61), screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic")

		--data

		dxDrawText(convertToRaceTime(displayedStats["burn"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.13), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(convertToRaceTime(displayedStats["city"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.16), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(convertToRaceTime(displayedStats["goldPB"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.19), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(tostring(displayedStats["cones"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.28), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(tostring(displayedStats["passed"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.31), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(tostring(displayedStats["attempts"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.34), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(tostring(displayedStats["won"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.37), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(convertToPlayingTime(displayedStats["playing"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.40), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(tostring(displayedStats["golds"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.43), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(tostring(displayedStats["silvers"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.46), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(tostring(displayedStats["bronzes"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.49), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")

		dxDrawText(displayedStats["conesall"], screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.58), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
		dxDrawText(displayedStats["playedall"], screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.61), screenX*(st_offsets[1]+0.45), screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[4], st_offsets[4], "bankgothic", "right")
	else
		-- Drawing leaderboars
		dxDrawText(displayedLeaderboards[statsPage].name, screenX*(st_offsets[1]+0.005), screenY*(st_offsets[2]+0.003), screenX, screenY, tocolor(0, 0, 0, statsAlpha), st_offsets[5]*4.02, st_offsets[5]*4.15, "beckett")
		dxDrawText(displayedLeaderboards[statsPage].name, screenX*st_offsets[1], screenY*st_offsets[2], screenX*st_offsets[1], screenY, tocolor(175, 202, 230, statsAlpha), st_offsets[5]*4, st_offsets[5]*4, "beckett")

		local box_height = (screenY*s_offsets[4]) * 0.9
		local textSize = box_height / 75 / (12 / 2)
		local offset = box_height / 12

		-- Draw stats
		for i = 1, 11 do
			-- Empty records handling
			if not displayedLeaderboards[statsPage].data[i] then
				displayedLeaderboards[statsPage].data[i] = {}
				displayedLeaderboards[statsPage].data[i]["playername"] = "-- EMPTY --"
				displayedLeaderboards[statsPage].data[i]["score"] = 0
			end

			-- Changes color for Player's record in LBs to blue
			local color
			if displayedLeaderboards[statsPage].data[i]["playername"]:gsub("#%x%x%x%x%x%x", "") == getPlayerName(localPlayer):gsub("#%x%x%x%x%x%x", "") then color = tocolor(0, 200, 200, statsAlpha)
			else color = tocolor(175, 202, 230, statsAlpha) end

			if i == 11 and displayedLeaderboards[statsPage].data[11]["id"] then
				dxDrawText(displayedLeaderboards[statsPage].data[11]["id"].. ".", screenX*st_offsets[1], screenY*(st_offsets[2]+0.07) + offset, screenX*st_offsets[1]*1.105, screenY, color, textSize, textSize, "bankgothic", "right")
			else
				dxDrawText(i.. ".", screenX*st_offsets[1], screenY*(st_offsets[2]+0.07) + offset, screenX*st_offsets[1]*1.105, screenY, color, textSize, textSize, "bankgothic", "right")
			end

			dxDrawText(tostring(displayedLeaderboards[statsPage].data[i]["playername"]):gsub("#%x%x%x%x%x%x", ""), screenX*(st_offsets[1]*1.12), screenY*(st_offsets[2]+0.07) + offset, screenX*st_offsets[1], screenY, color, textSize, textSize, "bankgothic")
			dxDrawText(convertToRaceTime(displayedLeaderboards[statsPage].data[i]["score"]), screenX*(st_offsets[1]+0.03), screenY*(st_offsets[2]+0.07) + offset, screenX*(st_offsets[1]+0.45), screenY, color, textSize, textSize, "bankgothic", "right")
			offset = offset + (box_height / 12)
		end
	end

	if displayStats then
		dxDrawImage((screenX*s_offsets[1])+(screenX*s_offsets[3])-(screenX/22), (screenY*b_offsets[2])-(screenY*i_size[2]/2)-(screenX/60), screenX/30, screenX/60, arrowTexture, 0, 0, 0, tocolor(255, 255, 255, statsAlpha))
	end
end

-- Event called from the server script for receiving stats data
addEvent("receiveStats", true)
addEventHandler("receiveStats", getRootElement(), function(playerStats, AllGoldsStats, MiscStats, BurnAndLapStats, CitySlickingStats, PBBurnStats, PBCityStats, GoldStats)
	-- Player's Stats
	displayedStats = playerStats[1]

	if PBBurnStats[1] then displayedStats["burn"] = PBBurnStats[1]["score"] else displayedStats["burn"] =  0 end
	if PBCityStats[1] then displayedStats["city"] = PBCityStats[1]["score"] else displayedStats["city"] =  0 end
	if GoldStats[1] then displayedStats["goldPB"] = GoldStats[1]["score"] else displayedStats["goldPB"] =  0 end

	-- LBs PogChamp :O
	displayedLeaderboards[1].data = BurnAndLapStats
	displayedLeaderboards[2].data = CitySlickingStats
	displayedLeaderboards[3].data = AllGoldsStats

	-- Handle Misc Stats
	if MiscStats[1] then
		displayedStats["conesall"] = MiscStats[1]["cones"]
		displayedStats["playedall"] = MiscStats[1]["played"]
	else
		displayedStats["conesall"] = 0
		displayedStats["playedall"] = 0
	end

	statsInited = true
end )
