--
-- toptimes_server.lua
--

SToptimesManager = {}
SToptimesManager.__index = SToptimesManager
SToptimesManager.instances = {}

countryNames = {
    ['AD'] = 'Andorra',
    ['AE'] = 'United Arab Emirates',
    ['AF'] = 'Afghanistan',
    ['AG'] = 'Antigua and Barbuda',
    ['AI'] = 'Anguilla',
    ['AL'] = 'Albania',
    ['AM'] = 'Armenia',
    ['AO'] = 'Angola',
    ['AP'] = 'Aripo',
    ['AR'] = 'Argentina',
    ['AT'] = 'Austria',
    ['AU'] = 'Australia',
    ['AW'] = 'Aruba',
    ['AZ'] = 'Azerbaijan',
    ['BA'] = 'Bosnia and Herzegovina',
    ['BB'] = 'Barbados',
    ['BD'] = 'Bangladesh',
    ['BE'] = 'Belgium',
    ['BF'] = 'Burkina Faso',
    ['BG'] = 'Bulgaria',
    ['BH'] = 'Bahrain',
    ['BI'] = 'Burundi',
    ['BJ'] = 'Benin',
    ['BM'] = 'Bermuda',
    ['BN'] = 'Brunei Darussalam',
    ['BO'] = 'Bolivia',
    ['BQ'] = 'Bonaire',
    ['BR'] = 'Brazil',
    ['BS'] = 'Bahamas',
    ['BT'] = 'Bhutan',
    ['BV'] = 'Bouvet Island',
    ['BW'] = 'Botswana',
    ['BY'] = 'Belarus',
    ['BZ'] = 'Belize',
    ['CA'] = 'Canada',
    ['CD'] = 'Congo',
    ['CF'] = 'Central African Republic',
    ['CG'] = 'Congo',
    ['CH'] = 'Switzerland',
    ['CI'] = 'Cote d Ivoire',
    ['CK'] = 'Cook Islands',
    ['CL'] = 'Chile',
    ['CM'] = 'Cameroon',
    ['CN'] = 'China',
    ['CO'] = 'Colombia',
    ['CR'] = 'Costa Rica',
    ['CU'] = 'Cuba',
    ['CV'] = 'Cape Verde',
    ['CW'] = 'Curacao',
    ['CY'] = 'Cyprus',
    ['CZ'] = 'Czech Republic',
    ['DE'] = 'Germany',
    ['DJ'] = 'Djibouti',
    ['DK'] = 'Denmark',
    ['DM'] = 'Dominica',
    ['DO'] = 'Dominican Republic',
    ['DZ'] = 'Algeria',
    ['EC'] = 'Ecuador',
    ['EE'] = 'Estonia',
    ['EG'] = 'Egypt',
    ['EH'] = 'Western Sahara',
    ['ER'] = 'Eritrea',
    ['ES'] = 'Spain',
    ['ET'] = 'Ethiopia',
    ['FI'] = 'Finland',
    ['FJ'] = 'Fiji',
    ['FK'] = 'Malvinas',
    ['FO'] = 'Faroe Islands',
    ['FR'] = 'France',
    ['GA'] = 'Gabon',
    ['GB'] = 'United Kingdom',
    ['GD'] = 'Grenada',
    ['GE'] = 'Georgia',
    ['GG'] = 'Guernsey',
    ['GH'] = 'Ghana',
    ['GI'] = 'Gibraltar',
    ['GL'] = 'Greenland',
    ['GM'] = 'Gambia',
    ['GN'] = 'Guinea',
    ['GQ'] = 'Equatorial Guinea',
    ['GR'] = 'Greece',
    ['GT'] = 'Guatemala',
    ['GW'] = 'Guinea-Bissau',
    ['GY'] = 'Guyana',
    ['HN'] = 'Honduras',
    ['HR'] = 'Croatia',
    ['HT'] = 'Haiti',
    ['HU'] = 'Hungary',
    ['ID'] = 'Indonesia',
    ['IE'] = 'Ireland',
    ['IL'] = 'Israel',
    ['IM'] = 'Isle of Man',
    ['IN'] = 'India',
    ['IQ'] = 'Iraq',
    ['IR'] = 'Iran',
    ['IS'] = 'Iceland',
    ['IT'] = 'Italy',
    ['JE'] = 'Jersey',
    ['JM'] = 'Jamaica',
    ['JO'] = 'Jordan',
    ['JP'] = 'Japan',
    ['KE'] = 'Kenya',
    ['KG'] = 'Kyrgyzstan',
    ['KH'] = 'Cambodia',
    ['KI'] = 'Kiribati',
    ['KM'] = 'Comoros',
    ['KN'] = 'Saint Kitts and Nevis',
    ['KP'] = 'Korea',
    ['KR'] = 'Korea',
    ['KW'] = 'Kuwait',
    ['KY'] = 'Cayman Islands',
    ['KZ'] = 'Kazakhstan',
    ['LA'] = 'Lao Peoples Republic',
    ['LB'] = 'Lebanon',
    ['LC'] = 'Saint Lucia',
    ['LI'] = 'Liechtenstein',
    ['LK'] = 'Sri Lanka',
    ['LR'] = 'Liberia',
    ['LS'] = 'Lesotho',
    ['LT'] = 'Lithuania',
    ['LU'] = 'Luxembourg',
    ['LV'] = 'Latvia',
    ['LY'] = 'Libyan Arab Jamahiriya',
    ['MA'] = 'Morocco',
    ['MC'] = 'Monaco',
    ['MD'] = 'Moldova',
    ['ME'] = 'Montenegro',
    ['MG'] = 'Madagascar',
    ['MK'] = 'Macedonia',
    ['ML'] = 'Mali',
    ['MM'] = 'Myanmar',
    ['MN'] = 'Mongolia',
    ['MO'] = 'Macao',
    ['MP'] = 'Northern Mariana Islands',
    ['MR'] = 'Mauritania',
    ['MS'] = 'Montserrat',
    ['MT'] = 'Malta',
    ['MU'] = 'Mauritius',
    ['MV'] = 'Maldives',
    ['MW'] = 'Malawi',
    ['MX'] = 'Mexico',
    ['MY'] = 'Malaysia',
    ['MZ'] = 'Mozambique',
    ['NA'] = 'Namibia',
    ['NE'] = 'Niger',
    ['NG'] = 'Nigeria',
    ['NI'] = 'Nicaragua',
    ['NL'] = 'Netherlands',
    ['NO'] = 'Norway',
    ['NP'] = 'Nepal',
    ['NR'] = 'Nauru',
    ['NZ'] = 'New Zealand',
    ['OM'] = 'Oman',
    ['PA'] = 'Panama',
    ['PE'] = 'Peru',
    ['PG'] = 'Papua New Guinea',
    ['PH'] = 'Philippines',
    ['PK'] = 'Pakistan',
    ['PL'] = 'Poland',
    ['PT'] = 'Portugal',
    ['PW'] = 'Palau',
    ['PY'] = 'Paraguay',
    ['QA'] = 'Qatar',
    ['RO'] = 'Romania',
    ['RS'] = 'Serbia',
    ['RU'] = 'Russian Federation',
    ['RW'] = 'Rwanda',
    ['SA'] = 'Saudi Arabia',
    ['SB'] = 'Solomon Islands',
    ['SC'] = 'Seychelles',
    ['SD'] = 'Sudan',
    ['SE'] = 'Sweden',
    ['SG'] = 'Singapore',
    ['SH'] = 'Saint Helena',
    ['SI'] = 'Slovenia',
    ['SK'] = 'Slovakia',
    ['SL'] = 'Sierra Leone',
    ['SM'] = 'San Marino',
    ['SN'] = 'Senegal',
    ['SO'] = 'Somalia',
    ['SR'] = 'Suriname',
    ['ST'] = 'Sao Tome and Principe',
    ['SV'] = 'Salvador',
    ['SX'] = 'Sint Maarten (Dutch part)',
    ['SY'] = 'Syrian Arab Republic',
    ['SZ'] = 'Swaziland',
    ['TC'] = 'Turks and Caicos Islands',
    ['TD'] = 'Chad',
    ['TG'] = 'Togo',
    ['TH'] = 'Thailand',
    ['TJ'] = 'Tajikistan',
    ['TL'] = 'Timor Leste',
    ['TM'] = 'Turkmenistan',
    ['TN'] = 'Tunisia',
    ['TO'] = 'Tonga',
    ['TR'] = 'Turkey',
    ['TT'] = 'Trinidad and Tobago',
    ['TV'] = 'Tuvalu',
    ['TW'] = 'Taiwan',
    ['TZ'] = 'Tanzania',
    ['UA'] = 'Ukraine',
    ['UG'] = 'Uganda',
    ['US'] = 'United States of America',
    ['UY'] = 'Uruguay',
    ['UZ'] = 'Uzbekistan',
    ['VA'] = 'Holy See',
    ['VC'] = 'Saint Vincent',
    ['VE'] = 'Venezuela',
    ['VG'] = 'Virgin Islands',
    ['VN'] = 'Viet Nam',
    ['VU'] = 'Vanuatu',
    ['WS'] = 'Samoa',
    ['YE'] = 'Yemen',
    ['ZA'] = 'South Africa',
    ['ZM'] = 'Zambia',
    ['ZW'] = 'Zimbabwe'
}

---------------------------------------------------------------------------
-- Server
-- Handle events from Race
--
-- This is the 'interface' from Race
--
---------------------------------------------------------------------------

addEvent('onMapStarting')
addEventHandler('onMapStarting', g_Root,
	function(mapInfo, mapOptions, gameOptions)
		if g_SToptimesManager then
			g_SToptimesManager:setModeAndMap( mapInfo.modename, mapInfo.name, gameOptions.statsKey )
			for _, p in ipairs(getElementsByType("player")) do g_SToptimesManager:playerShowPersonalBest(p) end
		end
	end
)

addEvent('onPlayerPickUpRacePickup')
addEventHandler('onPlayerPickUpRacePickup', g_Root,
	function(number, sort, model)
		if sort == "vehiclechange" then
			if getMapDM() then
				if model == 425 then
					if g_SToptimesManager then
						g_SToptimesManager:playerFinished(source, exports.race:getTimePassed())
						triggerClientEvent('onClientPlayerFinish', source)
					end
				end
			end
		end
	end
)

addEvent('onPlayerFinish')
addEventHandler('onPlayerFinish', g_Root,
	function(rank, time)
		if g_SToptimesManager then
			g_SToptimesManager:playerFinished(source, time)
		end
	end
)

addEventHandler('onResourceStop', g_ResRoot,
	function()
		if g_SToptimesManager then
			g_SToptimesManager:unloadingMap()
		end
	end
)

addEventHandler('onPlayerQuit', g_Root,
	function()
		if g_SToptimesManager then
			g_SToptimesManager:removePlayerFromUpdateList(source)
			g_SToptimesManager:unqueueUpdate(source)
		end
	end
)

addEventHandler('onResourceStart', g_ResRoot,
	function()
		local raceInfo = getRaceInfo()
		if raceInfo and g_SToptimesManager then
			g_SToptimesManager:setModeAndMap( raceInfo.mapInfo.modename, raceInfo.mapInfo.name, raceInfo.gameOptions.statsKey )
		end
	end
)

function getRaceInfo()
	local raceResRoot = getResourceRootElement( getResourceFromName( "race" ) )
	return raceResRoot and getElementData( raceResRoot, "info" )
end

---------------------------------------------------------------------------
--
-- Events fired from here
--
---------------------------------------------------------------------------

addEvent("onPlayerToptimeImprovement")

---------------------------------------------------------------------------


---------------------------------------------------------------------------
--
-- SToptimesManager:create()
--
-- Create a SToptimesManager instance
--
---------------------------------------------------------------------------
function SToptimesManager:create()
	local id = #SToptimesManager.instances + 1
	SToptimesManager.instances[id] = setmetatable(
		{
			id = id,
			playersWhoWantUpdates	= {},
			updateQueue				= {},
			serviceQueueTimer		= nil,
			displayTopCount		 	= 8,		-- Top number of times to display
			mapTimes				= nil,		-- SMaptimes:create()
			serverRevision			= 0,		-- To prevent redundant updating to clients
		},
		self
	)
	SToptimesManager.instances[id]:postCreate()
	return SToptimesManager.instances[id]
end


function getModeAndMap ( gMode, mapName )
	return 'race maptimes ' .. gMode .. ' ' .. mapName
end

---------------------------------------------------------------------------
--
-- SToptimesManager:destroy()
--
-- Destroy a SToptimesManager instance
--
---------------------------------------------------------------------------
function SToptimesManager:destroy()
	SToptimesManager.instances[self.id] = nil
	self.id = 0
end


---------------------------------------------------------------------------
--
-- SToptimesManager:postCreate()
--
--
--
---------------------------------------------------------------------------
function SToptimesManager:postCreate()
	cacheSettings()
	self.displayTopCount = g_Settings.numtimes
end


---------------------------------------------------------------------------
--
-- SToptimesManager:setModeAndMap()
--
-- Called when a new map has been loaded
--
---------------------------------------------------------------------------
function SToptimesManager:setModeAndMap( raceModeName, mapName, statsKey )
	outputDebug( 'TOPTIMES', 'SToptimesManager:setModeAndMap ' .. raceModeName .. '<>' .. mapName )

	-- Reset updatings from the previous map
	self.playersWhoWantUpdates = {}
	self.updateQueue = {}
	if self.serviceQueueTimer then
		killTimer(self.serviceQueueTimer)
	end
	self.serviceQueueTimer = nil

	-- Remove old map times
	if self.mapTimes then
		self.mapTimes:flush()	-- Ensure last stuff is saved
		self.mapTimes:destroy()
	end

	-- Get map times for this map
	self.mapTimes = SMaptimes:create( raceModeName, mapName, statsKey )
	self.mapTimes:load()

	-- Get the toptimes data ready to send
	self:updateTopText()
end


---------------------------------------------------------------------------
--
-- SToptimesManager:unloadingMap()
--
-- Called when unloading
--
---------------------------------------------------------------------------
function SToptimesManager:unloadingMap()
	if self.mapTimes then
		self.mapTimes:flush()	-- Ensure last stuff is saved
	end
end


---------------------------------------------------------------------------
--
-- SToptimesManager:playerFinished()
--
-- If time is good enough, insert into database
--
---------------------------------------------------------------------------
function SToptimesManager:playerFinished( player, newTime, dateRecorded )

	-- Check if top time recording is disabled for this player
	if getElementData ( player, "toptimes" ) == "off" then
		return
	end

	if not self.mapTimes then
		outputDebug( 'TOPTIMES', 'SToptimesManager:playerFinished - self.mapTimes == nil' )
		return
	end

	dateRecorded = dateRecorded or getRealDateTimeNowString()

	local oldTime	= self.mapTimes:getTimeForPlayer( player )	-- Can be false if no previous time
	local newPos	= self.mapTimes:getPositionForTime( newTime, dateRecorded )

	-- See if time is an improvement for this player
	if not oldTime or newTime < oldTime then

		local oldPos	= self.mapTimes:getIndexForPlayer( player )
		triggerEvent("onPlayerToptimeImprovement", player, newPos, newTime, oldPos, oldTime, self.displayTopCount, self.mapTimes:getValidEntryCount() )

		-- See if its in the top display
		if newPos <= self.displayTopCount then
			outputDebug( 'TOPTIMES', getPlayerName(player) .. ' got toptime position ' .. newPos )
		end
		
		if newPos == 1 then
			outputChatBox('* #FFFFFF'..getPlayerName(player)..'#FF6464 finished and set a new record! Time: #FFFFFF'..SMaptimes:timeMsToTimeText(newTime)..'#FF6464.', g_Root, 255, 100, 100, true )
		else
			if newPos <= self.displayTopCount then
				outputChatBox('* #FFFFFF'..getPlayerName(player)..'#FF6464 finished in #FFFFFF'..newPos..getPrefix(newPos)..'#FF6464! Time: #FFFFFF'..SMaptimes:timeMsToTimeText(newTime)..'#FF6464.', g_Root, 255, 100, 100, true )
			end
		end

		if not oldPos then
			outputChatBox('* A new personal time on this map: #FFFFFF#'..newPos..' '..SMaptimes:timeMsToTimeText(newTime)..'#FF6464.' , player, 255, 100, 100, true)
		else
			outputChatBox('* Improved your personal time on this map:', player, 255, 100, 100, true)
			outputChatBox('From #FFFFFF#'..oldPos..' '..SMaptimes:timeMsToTimeText(oldTime)..' #FF6464to #FFFFFF#'..newPos..' '..SMaptimes:timeMsToTimeText(newTime)..' #FF6464(#FFFFFF-'..SMaptimes:timeMsToTimeText(oldTime - newTime)..'#FF6464)', player, 255, 100, 100, true)
		end

		if oldTime then
			outputDebug( 'TOPTIMES', getPlayerName(player) .. ' new personal best ' .. newTime .. ' ' .. oldTime - newTime )
		end
		self.mapTimes:setTimeForPlayer( player, newTime, dateRecorded )

		-- updateTopText if database was changed
		if newPos <= self.displayTopCount then
			self:updateTopText()
		end
	end

	outputDebug( 'TOPTIMES', '++ SToptimesManager:playerFinished ' .. tostring(getPlayerName(player)) .. ' time:' .. tostring(newTime) )
end


---------------------------------------------------------------------------
--
-- SToptimesManager:updateTopText()
--
-- Update the toptimes client data for the current map
--
---------------------------------------------------------------------------
function SToptimesManager:updateTopText()
	if not self.mapTimes then return end
	-- Update data

	-- Read top rows from map toptimes table and send to all players who want to know
	self.toptimesDataForMap = self.mapTimes:getToptimes( self.displayTopCount )
	self.serverRevision = self.serverRevision + 1

	-- Queue send to all players
	for i,player in ipairs(self.playersWhoWantUpdates) do
		self:queueUpdate(player)
	end
end


---------------------------------------------------------------------------
--
-- SToptimesManager:onServiceQueueTimer()
--
-- Pop a player off the updateQueue and send them an update
--
---------------------------------------------------------------------------
function SToptimesManager:onServiceQueueTimer()
	outputDebug( 'TOPTIMES', 'SToptimesManager:onServiceQueueTimer()' )
	-- Process next player
	if #self.updateQueue > 0 and self.mapTimes then
		local player = self.updateQueue[1]
		local playerPosition = self.mapTimes:getIndexForPlayer( player )
		clientCall( player, 'onServerSentToptimes', self.toptimesDataForMap, self.serverRevision, playerPosition );
	end
	table.remove(self.updateQueue,1)
	-- Stop timer if end of update queue
	if #self.updateQueue < 1 then
		killTimer(self.serviceQueueTimer)
		self.serviceQueueTimer = nil
	end
end


---------------------------------------------------------------------------
--
-- SToptimesManager:addPlayerToUpdateList()
--
--
--
---------------------------------------------------------------------------
function SToptimesManager:addPlayerToUpdateList( player )
	if not table.find( self.playersWhoWantUpdates, player) then
		table.insert( self.playersWhoWantUpdates, player )
		outputDebug( 'TOPTIMES', 'playersWhoWantUpdates : ' .. #self.playersWhoWantUpdates )
	end
end

function SToptimesManager:removePlayerFromUpdateList( player )
	table.removevalue( self.playersWhoWantUpdates, player )
end


---------------------------------------------------------------------------
--
-- SToptimesManager:queueUpdate()
--
--
--
---------------------------------------------------------------------------
function SToptimesManager:queueUpdate( player )
	if not table.find( self.updateQueue, player) then
		table.insert( self.updateQueue, player )
	end

	if not self.serviceQueueTimer then
		self.serviceQueueTimer = setTimer( function() self:onServiceQueueTimer() end, 100, 0 )
	end
end


function SToptimesManager:unqueueUpdate( player )
	table.removevalue( self.updateQueue, player )
end


---------------------------------------------------------------------------
--
-- SToptimesManager:doOnClientRequestToptimesUpdates()
--
--
--
---------------------------------------------------------------------------
function SToptimesManager:doOnClientRequestToptimesUpdates( player, bOn, clientRevision )
	outputDebug( 'TOPTIMES', 'SToptimesManager:onClientRequestToptimesUpdates: '
			.. tostring(getPlayerName(player)) .. '<>' .. tostring(bOn) .. '< crev:'
			.. tostring(clientRevision) .. '< srev:' .. tostring(self.serverRevision) )
	if bOn then
		self:addPlayerToUpdateList(player)
		if clientRevision ~= self.serverRevision then
			outputDebug( 'TOPTIMES', 'queueUpdate for'..getPlayerName(player) )
			self:queueUpdate(player)
		end
	else
		self:removePlayerFromUpdateList(player)
		self:unqueueUpdate(player)
	end

end


addEvent('onClientRequestToptimesUpdates', true)
addEventHandler('onClientRequestToptimesUpdates', getRootElement(),
	function( bOn, clientRevision )
		g_SToptimesManager:doOnClientRequestToptimesUpdates( source, bOn, clientRevision )
	end
)


---------------------------------------------------------------------------
--
-- Commands and binds
--
--
--
---------------------------------------------------------------------------



addCommandHandler( "mytop",
	function(player)
		g_SToptimesManager:playerShowPersonalBest(player)
	end
)

function SToptimesManager:playerShowPersonalBest(player)
	local place = self.mapTimes:getIndexForPlayer(player)
	if not place then 
		return 
	end
	local time = self.mapTimes:getTimeForPlayer(player)
	if not time then 
		return 
	end
	outputChatBox('Personal best for '..tostring(g_SToptimesManager.mapTimes.mapName)..' #'..tostring(place)..': '..SMaptimes:timeMsToTimeText(time), player, 0, 255, 0)
end

addCommandHandler("deletetime",
	function(player, cmd, place)
		if not _TESTING and not isPlayerInACLGroup(player, g_Settings.admingroup) then
			return
		end
		if not place then
			return outputChatBox("***syntax: /deletetime [toptime] - example: /deletetime 1", player, 255, 180, 0)
		end
		if g_SToptimesManager and g_SToptimesManager.mapTimes then
			local row = g_SToptimesManager.mapTimes:deletetime(place)
			if row then
				g_SToptimesManager:updateTopText()
				local mapName = tostring(g_SToptimesManager.mapTimes.mapName)
				local placeText = place and "#" .. tostring(place) .. " " or ""
				local slotDesc = "'" .. placeText .. "[" .. tostring(row.timeText) .. "] " .. tostring(row.playerName) .. "#FFFFFF'"
				local adminName = tostring(getPlayerNametagText(player))
				local adminLogName = getAdminNameForLog(player)
				outputChatBox( "* #FFFFFFTop time " .. slotDesc .. " has deleted by " .. adminName .."#FFFFFF!", g_Root, 255, 100, 100, true)
				outputServerLog( "Toptimes: " .. adminLogName .. " deleted " .. slotDesc .. " from map '" .. mapName .. "'" )
			else
				return outputChatBox( "[PM] Invalid toptime place, try again", player, 255, 100, 100)
			end
		end
	end
)


addCommandHandler("addcountry",
	function(player, cmd, place, countrycode)
		if not _TESTING and not isPlayerInACLGroup(player, g_Settings.admingroup) then
			return
		end
		if not place or not countrycode then
			return outputChatBox("***syntax: /addcountry [toptime] [country] - example: /addcountry 1 US", player, 255, 180, 0)
		end
		-- Converts text to uppercase if it is in lowercase letters 
		countrycode = string.upper(countrycode) 
		if not countryNames[countrycode] then
			return outputChatBox( "[PM] Invalid country code, try again", player, 255, 100, 100)
		end
		if g_SToptimesManager and g_SToptimesManager.mapTimes then
			local row = g_SToptimesManager.mapTimes:addcountry(place, countrycode)
			if row then
				g_SToptimesManager:updateTopText()
				local mapName = tostring(g_SToptimesManager.mapTimes.mapName)
				local placeText = place and " #" .. tostring(place) or ""
				local slotDesc = "'" .. placeText .. " from " .. tostring(row.playerName) .. "'"
				local adminName = tostring(getPlayerNametagText(player))
				local adminLogName = getAdminNameForLog(player)
				local countryText = countrycode and tostring(countrycode)
				outputChatBox( "* #FFFFFFToptime " .. slotDesc .. "#FFFFFF has added country (".. countryText ..") - '".. countryNames[countryText] .."' by " .. adminName .."#FFFFFF!", g_Root, 255, 100, 100, true )
				outputServerLog( "Toptimes: " .. adminLogName .. " has added country" .. countryNames[countryText] .. " from map '" .. mapName .. "'" )
			else
				return outputChatBox( "[PM] Invalid toptime place, try again", player, 255, 100, 100)
			end
		end
	end
)

---------------------------------------------------------------------------
--
-- Settings
--
--
--
---------------------------------------------------------------------------
function cacheSettings()
	g_Settings = {}
	g_Settings.numtimes		= getNumber('numtimes',8)
	g_Settings.startshow	= getBool('startshow',false)
	g_Settings.gui_x		= getNumber('gui_x',0.56)
	g_Settings.gui_y		= getNumber('gui_y',0.02)
	g_Settings.admingroup	= getString("admingroup","Admin")
end

-- React to admin panel changes
addEvent ( "onSettingChange" )
addEventHandler('onSettingChange', g_ResRoot,
	function(name, oldvalue, value, playeradmin)
		outputDebug( 'MISC', 'Setting changed: ' .. tostring(name) .. '  value:' .. tostring(value) .. '  value:' .. tostring(oldvalue).. '  by:' .. tostring(player and getPlayerName(player) or 'n/a') )
		cacheSettings()
		-- Update here
		if g_SToptimesManager then
			g_SToptimesManager.displayTopCount = g_Settings.numtimes
			g_SToptimesManager:updateTopText()
		end
		-- Update clients
		clientCall(g_Root,'updateSettings', g_Settings, playeradmin)
	end
)

-- New player joined
addEvent('onLoadedAtClient_tt', true)
addEventHandler('onLoadedAtClient_tt', g_Root,
	function()
		-- Tell newly joined client current settings
		clientCall(source,'updateSettings', g_Settings)

		-- This could also be the toptimes resource being restarted, so send some mapinfo
		local raceInfo = getRaceInfo()
		if raceInfo then
		    triggerClientEvent('onClientSetMapName', source, raceInfo.mapInfo.name )
		end
	end
)

function getMapDM()
	local raceInfo = getRaceInfo()
	if raceInfo then
		if raceInfo.mapInfo.modename == 'Sprint' then
			return false
		else 
			return true
		end
	end
end

function getPrefix(number)
	if number == 11 or number == 12 or number == 13 then
		return 'th'
	end
	number = number % 10
	if number == 1 then
		return 'st'
	elseif number == 2 then
		return 'nd'
	elseif number == 3 then
		return 'rd'
	else
		return 'th'
	end
end

---------------------------------------------------------------------------
-- Global instance
---------------------------------------------------------------------------
g_SToptimesManager = SToptimesManager:create()

function getModeAndMap ( gMode, mapName )
	return 'race maptimes ' .. gMode .. ' ' .. mapName
end
