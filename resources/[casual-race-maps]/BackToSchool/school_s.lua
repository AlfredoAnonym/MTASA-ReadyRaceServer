-- Driving School Race by Discoordination Journey
-- All 12 tests from SP game, custom leaderboards, custom ghostmode
-- Final release: 07.08.2024
-- Update 08.01.2025
-- Version: 1.0.1

DATABASE = dbConnect("sqlite", ":/backToSchoolRecords.db")
mapPlayedTrigger = true
setElementData(resourceRoot, "lastPoliceDimension", 800)

addEvent("onMapStarting", true)
addEventHandler("onMapStarting", resourceRoot, function()
	setTimer(updateCar, 1, 0)
	exports.scoreboard:scoreboardAddColumn("Test", getRootElement(), 120)
end)

addEventHandler("onResourceStop", resourceRoot, function()
	exports.scoreboard:removeScoreboardColumn("Test")
end )

addEventHandler("onElementDataChange", getRootElement(), function(key, old, new)
	-- PIT test fixes
	if getElementType(source) == "player" and key == "dim" and new ~= 0 and getElementData(source, "level") == 10 then
		setElementData(resourceRoot, "lastPoliceDimension", getElementData(resourceRoot, "lastPoliceDimension") + 1)
	end
end )

-- Function that changes vehicle model required by current test and changes weather and time
function updateCar()
	for _, players in ipairs(getAlivePlayers()) do
		if getPedOccupiedVehicle(players) then
			if getElementModel(getPedOccupiedVehicle(players)) ~= getElementData(players, "carid") then
				-- Changes the vehicle model
				setElementModel(getPedOccupiedVehicle(players), getElementData(players, "carid"))

				-- Sets the colors for vehicles
				if getElementData(players, "carid") == 597 then
					-- Police SF
					setVehicleColor(getPedOccupiedVehicle(players), 0, 0, 0, 255, 255, 255)
				elseif getElementData(players, "carid") == 420 then
					-- Taxi
					setVehicleColor(getPedOccupiedVehicle(players), 215, 142, 16, 165, 138, 65)
				else
					math.randomseed(getTickCount())
					local colors = {}
					for i = 1, 4 do table.insert(colors, i, math.random(0, 126)) end

					setVehicleColor(getPedOccupiedVehicle(players), colors[1], colors[2], colors[3], colors[4])
				end
			end

			--if getElementCollisionsEnabled(getPedOccupiedVehicle(players)) and getElementData(players, "level") ~= 10 then
				--iprint("Back to School forced collisions off.")
				--setElementData(players, "overrideCollide." ..getTickCount(), 0, false)
			--end
		end

		-- Dimension sets there
		if getPedOccupiedVehicle(players) and getElementData(players, "dim") and getElementData(players, "dim") ~= getElementDimension(players) then
			-- Set dimension for the player and player's vehicle
			setElementDimension(players, getElementData(players, "dim"))
			setElementDimension(getPedOccupiedVehicle(players), getElementData(players, "dim"))
		end
	end

	setWeather(6)
	local time = getRealTime()
	setTime(time.hour, time.minute)
end

-- Event sets up timer for updating players
addEvent("onRaceStateChanging", true)
addEventHandler("onRaceStateChanging", root, function(newState, oldState)
	if oldState == "GridCountdown" and newState == "Running" then
		updatePlayers()
		setTimer(updatePlayers, 100, 0)
	end
end )

-- Function update triggers Driving School start when joined and checks if player are logged
function updatePlayers()
	-- Send data back to clients
	for index, players in ipairs(getElementsByType("player")) do
		-- Trigger for loading first level
		if getElementData(players, "trigger") == 1 and getElementData(players, "state") ~= "spectating" then
			setElementData(players, "trigger", 0)
			if not isGuestAccount(getPlayerAccount(players)) then setElementData(players, "logged", 1) end
		end
	end
end

-- Event called from client when player finished the race
addEvent("setPlayerFinish", true)
addEventHandler("setPlayerFinish", getRootElement(), function(data)
	local time = exports.race:getTimePassed()
	local rank = exports.race:getPlayerRank(source)

	local mapPlayed = 0

	local cutTime = data["golds"] * 11500
	local newtime = 0
	if time - cutTime > 0 then newtime = time - cutTime
	else newtime = time - 1000 end

	-- Deside won player or not based on number of players (>0)
	local won = 0
	if rank == 1 and getPlayerCount() > 1 then won = 1 end

	if mapPlayedTrigger then
		mapPlayed = 1
		mapPlayedTrigger = false
	end

	triggerEvent("onPlayerFinish", source, rank, newtime)

	-- Text messages
	if data["golds"] == 1 then outputChatBox("#E7D9B0" ..getPlayerName(source).. " #E7D9B0finished the Driving School in #00A000" ..convertToRaceTime(newtime).. " #E7D9B0with #BDA402" ..data["golds"].. " #E7D9B0gold medal and a #00A000"..(cutTime/1000).. " #E7D9B0seconds advantage.", root, 255, 255, 255, true)
	elseif data["golds"] == 6 then outputChatBox("#E7D9B0" ..getPlayerName(source).. " #E7D9B0finished the Driving School in #00A000" ..convertToRaceTime(newtime).. " #E7D9B0with #BDA402" ..data["golds"].. " #E7D9B0gold medals and a #00A000"..(cutTime/1000).. " #E7D9B0seconds advantage. Nice.", root, 255, 255, 255, true)
	else outputChatBox("#E7D9B0" ..getPlayerName(source).. " #E7D9B0finished the Driving School in #00A000" ..convertToRaceTime(newtime).. " #E7D9B0with #BDA402" ..data["golds"].. " #E7D9B0gold medals and a #00A000"..(cutTime/1000).. " #E7D9B0seconds advantage.", root, 255, 255, 255, true) end

	-- Achievements stuff
	exports.achievements:triggerAchievement(source, "disco11", nil)
	if data["golds"] == 12 then exports.achievements:triggerAchievement(source, "disco12", nil) end
	if data["cones"] == 0 then exports.achievements:triggerAchievement(source, "drschoolNoCones", nil) end

	if not DATABASE then return end

	-- Create all tables
	dbExec(DATABASE, "CREATE TABLE IF NOT EXISTS PlayersTable(playername TEXT, cones INTEGER, passed INTEGER, attempts INTEGER, won INTEGER, playing INTEGER, golds INTEGER, silvers INTEGER, bronzes INTEGER)")
	dbExec(DATABASE, "CREATE TABLE IF NOT EXISTS AllGoldsTable(playername TEXT, score INTEGER)")
	dbExec(DATABASE, "CREATE TABLE IF NOT EXISTS MiscTable(cones INTEGER, played INTEGER)")

	-- Select data
	PlayerQuery = dbQuery(DATABASE, "SELECT * FROM PlayersTable WHERE playername = ?", getAccountName(getPlayerAccount(source)))
	AllGoldsQuery = dbQuery(DATABASE, "SELECT * FROM AllGoldsTable WHERE playername = ?", getAccountName(getPlayerAccount(source)))
	MiscQuery = dbQuery(DATABASE, "SELECT * FROM MiscTable")

	-- Get data
	PlayerResults = dbPoll(PlayerQuery, -1)
	AllGoldsResults = dbPoll(AllGoldsQuery, -1)
	MiscResults = dbPoll(MiscQuery, -1)

	-- Update player's data
	if not isGuestAccount(getPlayerAccount(source)) then
		if PlayerResults and #PlayerResults > 0 then dbExec(DATABASE, "UPDATE PlayersTable SET cones = ?, passed = ?, attempts = ?, won = ?, playing = ?, golds = ?, silvers = ?, bronzes = ? WHERE playername = ?", PlayerResults[1]["cones"] + data["cones"], PlayerResults[1]["passed"] + 12, PlayerResults[1]["attempts"] + data["attempts"], PlayerResults[1]["won"] + won, PlayerResults[1]["playing"] + time, PlayerResults[1]["golds"] + data["golds"], PlayerResults[1]["silvers"] + data["silvers"], PlayerResults[1]["bronzes"] + data["bronzes"], getAccountName(getPlayerAccount(source)))
		else dbExec(DATABASE, "INSERT INTO PlayersTable(playername, cones, passed, attempts, won, playing, golds, silvers, bronzes) VALUES (?,?,?,?,?,?,?,?,?)", getAccountName(getPlayerAccount(source)), data["cones"], 12, data["attempts"], won, newtime, data["golds"], data["silvers"], data["bronzes"]) end

		-- Player got all golds in the tests - update All Golds leaderboard
		if data["golds"] == 12 then
			if AllGoldsResults and #AllGoldsResults > 0 then
				if newtime < AllGoldsResults[1]["score"] then
					dbExec(DATABASE, "UPDATE AllGoldsTable SET score = ? WHERE playername = ?", newtime, getAccountName(getPlayerAccount(source)))
				end
			else
				dbExec(DATABASE, "INSERT INTO AllGoldsTable(playername, score) VALUES (?,?)", getAccountName(getPlayerAccount(source)), newtime)
				sortQuery = dbQuery(DATABASE, "SELECT * FROM AllGoldsTable ORDER BY score ASC LIMIT 11")
				goldsResults = dbPoll(sortQuery, -1)

				for i, goldsData in pairs(goldsResults) do
					if goldsData["playername"] == getAccountName(getPlayerAccount(source)) and newtime == goldsData["score"] then
						outputChatBox("#BDA402[All Golds] New top time #" ..i.. ": " ..getAccountName(getPlayerAccount(source)).. "#BDA402, " ..convertToRaceTime(newtime), root, 255, 255, 255, true)
						break
					end

					if i == 11 then break end -- over 11th place
				end
			end
		end
	end

	-- Update misc stats
	if MiscResults and #MiscResults > 0 then dbExec(DATABASE, "UPDATE MiscTable SET cones = ?, played = ?", MiscResults[1]["cones"] + data["cones"], MiscResults[1]["played"] + mapPlayed)
	else dbExec(DATABASE, "INSERT INTO MiscTable(cones, played) VALUES (?,?)", data["cones"], mapPlayed) end
end )
