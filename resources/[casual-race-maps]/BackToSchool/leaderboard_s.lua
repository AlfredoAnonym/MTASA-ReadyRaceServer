-- Event called from client when player want to see stats, event returns data from database
addEvent("getStats", true)
addEventHandler("getStats", getRootElement(), function()
	if not DATABASE then return end

	-- Database management
	dbExec(DATABASE, "CREATE TABLE IF NOT EXISTS PlayersTable(playername TEXT, cones INTEGER, passed INTEGER, attempts INTEGER, won INTEGER, playing INTEGER, golds INTEGER, silvers INTEGER, bronzes INTEGER)")
	dbExec(DATABASE, "CREATE TABLE IF NOT EXISTS AllGoldsTable(playername TEXT, score INTEGER)")
	dbExec(DATABASE, "CREATE TABLE IF NOT EXISTS MiscTable(cones INTEGER, played INTEGER)")
	dbExec(DATABASE, "CREATE TABLE IF NOT EXISTS BurnAndLapTable(playername TEXT, score INTEGER)")
	dbExec(DATABASE, "CREATE TABLE IF NOT EXISTS CitySlickingTable(playername TEXT, score INTEGER)")

	-- Get data
	PlayerResults = dbPoll(dbQuery(DATABASE, "SELECT * FROM PlayersTable WHERE playername = ?", getAccountName(getPlayerAccount(source))), -1)
	MiscResults = dbPoll(dbQuery(DATABASE, "SELECT * FROM MiscTable"), -1)

	BurnAndLapResults = dbPoll(dbQuery(DATABASE, "SELECT * FROM BurnAndLapTable ORDER BY score ASC"), -1)
	CitySlickingResults = dbPoll(dbQuery(DATABASE, "SELECT * FROM CitySlickingTable ORDER BY score ASC"), -1)
	AllGoldsResults = dbPoll(dbQuery(DATABASE, "SELECT * FROM AllGoldsTable ORDER BY score ASC"), -1)

	local formattedData = {}
	local dbTables = { BurnAndLapResults, CitySlickingResults, AllGoldsResults }
	for i = 1, 3 do
		formattedData[i] = {}
		if dbTables[i] and #dbTables[i] > 0 then
			for index, data in ipairs(dbTables[i]) do
				if index <= 11 then table.insert(formattedData[i], index, data) end

				-- Insert player's record if it's index > 11
				if index > 11 and data["playername"] == getPlayerName(source) then
					data["id"] = index
					table.remove(formattedData[i], 11)
					table.insert(formattedData[i], 11, data)
					break
				end
			end
		end
	end

	-- Init player's data
	if PlayerResults and #PlayerResults < 1 then
		dbExec(DATABASE, "INSERT INTO PlayersTable(playername, cones, passed, attempts, won, playing, golds, silvers, bronzes) VALUES (?,?,?,?,?,?,?,?,?)", getAccountName(getPlayerAccount(source)), 0, 0, 0, 0, 0, 0, 0, 0)
	end

	-- INIT miscTable
	if MiscResults and #MiscResults < 1 then
		dbExec(DATABASE, "INSERT INTO MiscTable(cones, played) VALUES (?,?)", 0, 0)
		MiscResults = dbPoll(dbQuery(DATABASE, "SELECT * FROM MiscTable"), -1)
	end

	PlayerResults = dbPoll(dbQuery(DATABASE, "SELECT * FROM PlayersTable WHERE playername = ?", getAccountName(getPlayerAccount(source))), -1)
	PBBurnResults = dbPoll(dbQuery(DATABASE, "SELECT * FROM BurnAndLapTable WHERE playername = ?", getPlayerName(source)), -1)
	PBCityResults = dbPoll(dbQuery(DATABASE, "SELECT * FROM CitySlickingTable WHERE playername = ?", getPlayerName(source)), -1)
	GoldResults = dbPoll(dbQuery(DATABASE, "SELECT * FROM AllGoldsTable WHERE playername = ?", getAccountName(getPlayerAccount(source))), -1)

	triggerClientEvent(source, "receiveStats", source, PlayerResults, formattedData[3], MiscResults, formattedData[1], formattedData[2], PBBurnResults, PBCityResults, GoldResults)
end )

addEvent("updateIndividualRecords", true)
addEventHandler("updateIndividualRecords", getRootElement(), function(test, time)
	if not DATABASE then return end
	local tests = {[1] = "BurnAndLapTable", [2] = "CitySlickingTable"}
	local testsName = {[1] = "Burn and Lap", [2] = "City Slicking"}
	local oldScore

	dbExec(DATABASE, "CREATE TABLE IF NOT EXISTS " ..tests[test].. "(playername TEXT, score INTEGER)")
	local results = dbPoll(dbQuery(DATABASE, "SELECT * FROM " ..tests[test].. " WHERE playername = ?", getPlayerName(source)), -1)

	-- Updating Database
	if results and #results > 0 then
		if time < results[1]["score"] then
			oldScore = results[1]["score"]
			dbExec(DATABASE, "UPDATE " ..tests[test].. " SET score = ? WHERE playername = ?", time, getPlayerName(source))
		end
	else dbExec(DATABASE, "INSERT INTO " ..tests[test].. "(playername, score) VALUES (?,?)", getPlayerName(source), time) end

	-- Check for new top time
	results = dbPoll(dbQuery(DATABASE, "SELECT * FROM " ..tests[test].. " ORDER BY score ASC LIMIT 11"), -1)
	for i, data in pairs(results) do
		if data["playername"] == getPlayerName(source) and time == data["score"] then
			if oldScore then outputChatBox("#00FF00[" ..testsName[test].. "] New top time #" ..i.. ": " ..getPlayerName(source).. "#00FF00, " ..convertToRaceTime(time).. " (-" ..convertToRaceTime(oldScore - time).. ")", root, 255, 255, 255, true)
			else outputChatBox("#00FF00[" ..testsName[test].. "] New top time #" ..i.. ": " ..getPlayerName(source).. "#00FF00, " ..convertToRaceTime(time), root, 255, 255, 255, true) end
			break
		end
	end
end )
