--
-- toptimes_client.lua
--

CToptimes = {}
CToptimes.__index = CToptimes
CToptimes.instances = {}
g_Settings = {}
g_AllowTimesLabel = false
g_TotalToptimes = 0
g_ToptimeR, g_ToptimeG, g_ToptimeB = 0, 255, 255
g_MainColorR, g_MainColorG, g_MainColorB = 255, 255, 255
g_MainColorHex = '202020' -- without # to avoid bugs - meh color = 0080FF
g_ToptimeHeader = ''	

---------------------------------------------------------------------------
-- Client
-- Handle events from Race
--
-- This is the 'interface' from Race
--
---------------------------------------------------------------------------

addEventHandler('onClientResourceStart', g_ResRoot,
	function()
		triggerServerEvent('onLoadedAtClient_tt', g_Me)
	end
)

addEvent('onClientMapStarting', true)
addEventHandler('onClientMapStarting', getRootElement(),
	function(mapinfo)
		outputDebug( 'TOPTIMES', 'onClientMapStarting' )
		if g_CToptimes then
			g_CToptimes:onMapStarting(mapinfo)
		end
	end
)

addEvent('onClientMapStopping', true)
addEventHandler('onClientMapStopping', getRootElement(),
	function()
		outputDebug( 'TOPTIMES', 'onClientMapStopping' )
		if g_CToptimes then
			g_CToptimes:onMapStopping()
		end
	end
)

addEvent('onClientPlayerFinish', true)
addEventHandler('onClientPlayerFinish', getRootElement(),
	function()
		outputDebug( 'TOPTIMES', 'onClientPlayerFinish' )
		if g_CToptimes then
			g_CToptimes:doToggleToptimes(true)
		end
	end
)

addEvent('onClientSetMapName', true)
addEventHandler('onClientSetMapName', getRootElement(),
	function(manName)
		if g_CToptimes then
			g_CToptimes:setWindowTitle(manName)
		end
	end
)


function updateSettings(settings, playeradmin)
	outputDebug( 'TOPTIMES', 'updateSettings' )
	if g_CToptimes then
		totaltimes = settings.numtimes
		if settings and settings.gui_x and settings.gui_y then
			g_CToptimes:setWindowPosition( settings.gui_x, settings.gui_y )
			g_CToptimes.startshow = settings.startshow
		end
		-- If admin changed this setting manually, then show the table to him
		if playeradmin == getLocalPlayer() then
			g_CToptimes:doToggleToptimes(true)
		end
	end
end

---------------------------------------------------------------------------
--
-- CToptimes:create()
--
--
--
---------------------------------------------------------------------------
function CToptimes:create()
	outputDebug ( 'TOPTIMES', 'CToptimes:create' )
	local id = #CToptimes.instances + 1
	CToptimes.instances[id] = setmetatable(
		{
			id = id,
			bManualShow		= false,		-- via key press
			bAutoShow		= false,		-- when player finished
			bGettingUpdates = false,		-- server should send us updates to the toptimes
			listStatus		= 'Empty',		-- 'Empty', 'Loading' or 'Full'
			gui				= {},			-- all gui items
			lastSeconds		= 0,
			targetFade		= 0,
			currentFade		= 0,
			autoOffTimer	= Timer:create(),
		},
		self
	)

	CToptimes.instances[id]:postCreate()
	return CToptimes.instances[id]
end


---------------------------------------------------------------------------
--
-- CToptimes:destroy()
--
--
--
---------------------------------------------------------------------------
function CToptimes:destroy()
	self:setHotKey(nil)
	self:closeWindow()
	self.autoOffTimer:destroy()
	CToptimes.instances[self.id] = nil
	self.id = 0
end


---------------------------------------------------------------------------
--
-- CToptimes:postCreate()
--
--
--
---------------------------------------------------------------------------
function CToptimes:postCreate()
	self:openWindow()
	self:setWindowPosition( 0.7, 0.02 )
	self:setHotKey('F5')
end


---------------------------------------------------------------------------
--
-- CToptimes:openWindow()
--
--
--
---------------------------------------------------------------------------
function CToptimes:openWindow ()
	if self.gui['container'] then
		return
	end

	self.size = {}
	self.size.x = 450-110
	self.size.y = 46 + 17 * 8

	local sizeX = self.size.x
	local sizeY = self.size.y

	-- windowbg is the root gui element.
	-- windowbg holds the backround image, to which the required alpha is applied
	self.gui['windowbg'] = guiCreateStaticImage(100, 100, sizeX, sizeY, 'img/timepassedbg.png', false, nil)
	guiSetAlpha(self.gui['windowbg'], 1.0)
	guiSetVisible( self.gui['windowbg'], false )
	guiSetProperty ( self.gui['windowbg'], 'AlwaysOnTop', 'true' )

	-- windowbg as parent:

	self.gui['container'] = guiCreateStaticImage(0, 0, 1, 1, 'img/blank.png', true, self.gui['windowbg'])
	guiSetProperty ( self.gui['container'], 'InheritsAlpha', 'false' )
	
	-- container as parent:
	self.gui['bar'] = guiCreateStaticImage(0, 0, sizeX, 18, 'img/timetitlebarbg.png', false, self.gui['container'])
	guiSetProperty(self.gui['bar'], "ImageColours", "tl:FF"..g_MainColorHex.." tr:FF"..g_MainColorHex.. "bl:FF"..g_MainColorHex.." br:FF"..g_MainColorHex.."")  
	
	self.gui['title'] = guiCreateLabel(0, 1, sizeX, 15, 'Top Times - ', false, self.gui['container'] )
	guiLabelSetHorizontalAlign ( self.gui['title'], 'center' )
	guiSetFont(self.gui['title'], 'default-bold-small')
	guiLabelSetColor ( self.gui['title'], g_MainColorR, g_MainColorG, g_MainColorB )

	g_ToptimeHeader = 'pos & country        name                           		         time                date'
	self.gui['header'] = guiCreateLabel(10, 22, sizeX-30, 15, g_ToptimeHeader, false, self.gui['container'] )
	guiSetFont(self.gui['header'], 'default-small')
	guiLabelSetColor ( self.gui['header'], g_MainColorR, g_MainColorG, g_MainColorB )
			
	self.gui['headerul'] = guiCreateLabel(0, 26, sizeX, 15, string.rep('-', 80), false, self.gui['container'] )
	guiLabelSetHorizontalAlign ( self.gui['headerul'], 'center' )
	guiLabelSetColor ( self.gui['headerul'], g_MainColorR, g_MainColorG, g_MainColorB )

	self.gui['paneLoading'] = guiCreateStaticImage(0, 0, 1, 1, 'img/blank.png', true, self.gui['container'])

			
	-- paneLoading as parent:
	
	g_AllowTimesLabel = guiCreateLabel(sizeX/4, 38, sizeX/2, 15, '', false, self.gui['paneLoading'] )

	self.gui['busy'] = guiCreateLabel(sizeX/4, 38, sizeX/2, 15, 'Please wait', false, self.gui['paneLoading'] )
	self.gui['busy2'] = guiCreateLabel(sizeX/4, 53, sizeX/2, 15, 'until next map ..', false, self.gui['paneLoading'] )
	guiLabelSetHorizontalAlign ( self.gui['busy'], 'center' )
	guiLabelSetHorizontalAlign ( self.gui['busy2'], 'center' )
	guiSetFont(self.gui['busy'], 'default-bold')
	
	self.gui['paneTimes'] = guiCreateStaticImage(0, 0, 1, 1, 'img/blank.png', true, self.gui['container'])
	
	-- paneTimes as parent:

	-- All the labels in the time list
	self.gui['listPos'] = {}
	self.gui['listNames'] = {}
	self.gui['listTimes'] = {}
	self.gui['listDate'] = {}
	self.gui['listFlags'] = {}
	self:updateLabelCount(8)
	self:updateLabelTimesDate(8)
	self:updateTimesCountryFlags(8)
end

---------------------------------------------------------------------------
--
-- CToptimes:closeWindow()
--
--
--
---------------------------------------------------------------------------
function CToptimes:closeWindow ()
	destroyElement( self.gui['windowbg'] )
	self.gui = {}
end


---------------------------------------------------------------------------
--
-- CToptimes:setWindowPosition()
--
--
--
---------------------------------------------------------------------------
function CToptimes:setWindowPosition ( gui_x, gui_y )
	if self.gui['windowbg'] then
		local screenWidth, screenHeight = guiGetScreenSize()
		local posX = screenWidth/2 + 63 + ( screenWidth * (gui_x - 0.56) )
		local posY = 14 + ( screenHeight * (gui_y - 0.02) )

		local posXCurve = { {0, 0}, {0.7, screenWidth/2 + 63}, {1, screenWidth - self.size.x} }
		local posYCurve = { {0, 0}, {0.02, 14}, {1, screenHeight - self.size.y} }

		posX = math.evalCurve( posXCurve, gui_x )
		posY = math.evalCurve( posYCurve, gui_y )
		guiSetPosition( self.gui['windowbg'], posX, posY, false )
	end
end


---------------------------------------------------------------------------
--
-- CToptimes:setWindowTitle()
--
--
--
---------------------------------------------------------------------------
function CToptimes:setWindowTitle( mapName )
	if self.gui['title'] then
		-- Set the title
		guiSetText ( self.gui['title'], mapName )
		-- Hide the 'until next map' message
		guiSetVisible (self.gui['busy2'], false)
	end
end


---------------------------------------------------------------------------
--
-- CToptimes:setHotKey()
--
--
--
---------------------------------------------------------------------------
function CToptimes:setHotKey ( hotkey )
	if self.hotkey then
		unbindKey ( self.hotkey, 'down', "showtimes" )
	end
	if hotkey and self.hotkey and hotkey ~= self.hotkey then
		outputConsole( "Race Toptimes hotkey is now '" .. tostring(hotkey) .. "'" )
	end
	self.hotkey = hotkey
	if self.hotkey then
		bindKey ( self.hotkey, 'down', "showtimes" )
	end
end


---------------------------------------------------------------------------
--
-- CToptimes:onMapStarting()
--
--
--
---------------------------------------------------------------------------
function CToptimes:onMapStarting(mapinfo)
	
	self.bAutoShow			= false
	self.bGettingUpdates	= false	 -- Updates are automatically cleared on the server at the start of a new map,
	self.listStatus		 	= 'Empty'
	self.clientRevision	 	= -1
	self:updateShow()
	self:setWindowTitle( mapinfo.name )

	if self.startshow then
		self:doToggleToptimes( true )
	end
end


---------------------------------------------------------------------------
--
-- CToptimes:onMapStopping()
--
--
--
---------------------------------------------------------------------------
function CToptimes:onMapStopping()
	
	self.bAutoShow			= false
	self.bGettingUpdates	= false	 -- Updates are automatically cleared on the server at the start of a new map,
	self.listStatus		 	= 'Empty'
	self.clientRevision	 	= -1
	self:doToggleToptimes(false)
	self:setWindowTitle( '' )
	if g_TotalToptimes > 0 then
		for i=1, g_TotalToptimes do
			setElementData(getResourceRootElement(getThisResource()), 'labelvisible', nil)
			setElementData(getLocalPlayer(), 'ttposition', nil)
			setElementData(getLocalPlayer(), 'label', nil)
			setElementData(getLocalPlayer(), 'names'..i, nil)
			setElementData(getLocalPlayer(), 'namesposx'..i, nil)
			setElementData(getLocalPlayer(), 'namesposx2'..i, nil)
			setElementData(getLocalPlayer(), 'namesposy'..i, nil)
			setElementData(getLocalPlayer(), 'namesposy2'..i, nil)
		end
	end
end


---------------------------------------------------------------------------
--
-- CToptimes:doAutoShow()
--
--
--
---------------------------------------------------------------------------
function CToptimes:doAutoShow()
	self.bAutoShow = true
	self:updateShow()
end


---------------------------------------------------------------------------
--
-- CToptimes:updateShow()
--
--
--
---------------------------------------------------------------------------
function CToptimes:updateShow()

	local bShowAny = self.bAutoShow or self.bManualShow
	self:enableToptimeUpdatesFromServer( bShowAny )

	--outputDebug( 'TOPTIMES', 'updateShow bAutoShow:'..tostring(self.bAutoShow)..' bManualShow:'..tostring(self.bManualShow)..' listStatus:'..self.listStatus )
	if not bShowAny then
		self.targetFade = 0
	elseif not self.bManualShow and self.listStatus ~= 'Full' then
		-- No change
	else
		local bShowLoading	= self.listStatus=='Loading'
		local bShowTimes	= self.listStatus=='Full'

		self.targetFade = 1
		guiSetVisible (self.gui['paneLoading'], bShowLoading)
		guiSetVisible (self.gui['paneTimes'], bShowTimes)
		guiSetText ( self.gui['busy2'], 'loading times ..' )
		guiSetVisible (self.gui['busy2'], true)
	end
end


---------------------------------------------------------------------------
--
-- CToptimes:enableUpdatesFromServer()
--
--
--
---------------------------------------------------------------------------
function CToptimes:enableToptimeUpdatesFromServer( bOn )
	if bOn ~= self.bGettingUpdates then
		self.bGettingUpdates = bOn
		triggerServerEvent('onClientRequestToptimesUpdates', g_Me, bOn, self.clientRevision )
	end
	if self.bGettingUpdates and self.listStatus == 'Empty' then
		self.listStatus = 'Loading'
		guiSetText ( self.gui['busy2'], 'until next map ..' )
	end
end

---------------------------------------------------------------------------
--
-- CToptimes:updateTimesCountryFlags()
--
--
--
---------------------------------------------------------------------------
function CToptimes:updateTimesCountryFlags(numLines)

	local sizeX = self.size.x
	local sizeY = self.size.y

	local parentGui = self.gui['paneTimes']
	local f = self.gui['listFlags']
	
	-- Expand/shrink the list
	while #f < numLines do
		local y = #f
		local x = #f < numLines and 20 or 13
		local flag = guiCreateStaticImage(x+13, 41+17*y, 16, 11, 'img/unk.png', false, parentGui)
		guiSetAlpha(flag, 9.0)
		table.insert(f, flag)
	end

	while #f > numLines do
		local lastFlag = table.popLast(f)
		destroyElement(lastFlag)
	end

end

---------------------------------------------------------------------------
--
-- CToptimes:updateLabelCount()
--
--
--
---------------------------------------------------------------------------
function CToptimes:updateLabelCount(numLines)

	local sizeX = self.size.x
	local sizeY = self.size.y

	local parentGui = self.gui['paneTimes']
	local t = self.gui['listPos']
	local t2 = self.gui['listNames']

	-- Expand/shrink the list
	while #t < numLines do
		local y = #t
		local x = #t < 9 and 20 or 13
		local label = guiCreateLabel(x-6, 38+17*y, sizeX-x-10, 15, '', false, parentGui )
		guiSetFont(label, 'default-bold-small')
		guiSetAlpha(label, 9.0)
		table.insert(t, label)
	end
	while #t2 > numLines do
		local lastPos = table.popLast(t2)
		destroyElement(lastPos)
	end
	------------------------------------------
	while #t2 < numLines do
		local y = #t2
		local x = #t2 < numLines and 20 or 13
		local label2 = guiCreateLabel(x+38, 38+17*y, 117, 15, '', false, parentGui )
		guiSetFont(label2, 'default-bold-small')
		guiSetAlpha(label2, 9.0)
		guiSetVisible(label2, false)
		table.insert(t2, label2)
	end
	while #t2 > numLines do
		local lastNames = table.popLast(t2)
		destroyElement(lastNames)
	end

end


---------------------------------------------------------------------------
--
-- CToptimes:updateLabelTimesDate()
--
--
--
---------------------------------------------------------------------------
function CToptimes:updateLabelTimesDate(numLines)

	local sizeX = self.size.x
	local sizeY = self.size.y

	local parentGui = self.gui['paneTimes']
	local td = self.gui['listDate']

	-- Expand/shrink the list
	while #td < numLines do
		local y = #td
		local x = #td < numLines and 20 or 13
		local labelDate = guiCreateLabel(x+245, 38+17*y, sizeX-x-10, 15, '', false, parentGui )
		guiSetFont(labelDate, 'default-bold-small')
		guiSetAlpha(labelDate, 9.0)
		guiLabelSetHorizontalAlign(labelDate, 'left')
		table.insert(td, labelDate)
	end
	while #td > numLines do
		local lastTimes = table.popLast(td)
		destroyElement(lastTimes)
	end
	------------------------------------------
	local td2 = self.gui['listTimes']
	while #td2 < numLines do
		local y = #td2
		local x = #td2 < numLines and 20 or 13
		local labelTimes = guiCreateLabel(x-77, 38+17*y, sizeX-x-10, 15, '', false, parentGui )
		guiSetFont(labelTimes, 'default-bold-small')
		guiSetAlpha(labelTimes, 9.0)
		guiLabelSetHorizontalAlign(labelTimes, 'right')
		table.insert(td2, labelTimes)
	end
	while #td2 > numLines do
		local lastDate = table.popLast(td2)
		destroyElement(lastDate)
	end
end


---------------------------------------------------------------------------
--
-- CToptimes:doOnServerSentToptimes()
--
--
--
---------------------------------------------------------------------------
function CToptimes:doOnServerSentToptimes( data, serverRevision, playerPosition )
	outputDebug( 'TOPTIMES', 'CToptimes:doOnServerSentToptimes ' .. tostring(#data) )

	-- Calc number lines to use and height of window
	local numLines = math.clamp( 0, #data, 50 )
	self.size.y = 46 + 17 * numLines

	-- Set height of window
	local sizeX = self.size.x
	local sizeY = self.size.y
	guiSetSize( self.gui['windowbg'], sizeX, sizeY, false )
	
	-- Make toptimes contains the correct number of labels
	self:updateLabelCount(numLines)
	self:updateLabelTimesDate(numLines)
	
	-- Create toptimes country flags
	self:updateTimesCountryFlags(numLines)

	-- Update the list items
	for i=1,numLines do
	
		local timeText = tostring(data[i].timeText)
		if timeText:sub(1,1) == '0' then
			timeText = '  ' .. timeText:sub(2)
		end
		data[i].dateRecorded = string.sub(data[i].dateRecorded,1,10)
		data[i].dateRecorded = string.gsub(data[i].dateRecorded, '-', '.' )
		
		--[[
		-- Lines for tests
		local randflags = {'BR','ES','JM','EE','PL','MN','US','TR','AU','TN','AZ','SA','TT','AR','AT','BM','BN'}
		data[i].playerCountry = randflags[math.random(#randflags)]
		local randnames = {'RandomDude21','WOOOoooW.','TestName21','NooB','PRO-RACER','Blank','MTA'}
		data[i].playerName = randnames[math.random(#randnames)]
		local randtimes = {'1:00:000','120:00:000', '111:00:000', '1:00:000', '2:00:000', '5:00:000'}
		--timeText = randtimes[math.random(#randtimes)]
		timeText = '1:00:000'
		data[i].dateRecorded = '2021-01-01'
		data[i].dateRecorded = string.gsub(data[i].dateRecorded, '-', '.' )
		--]]
		
		local line = string.format( '%d.', i)
		guiSetText ( self.gui['listPos'][i], line )
		local line2 = string.format( '%s', data[i].playerName )
		guiSetText ( self.gui['listNames'][i], line2 )
		guiSetVisible(self.gui['listNames'][i], false)
		local posx, posy = guiGetPosition( self.gui['listNames'][i], false )
		local posx2, posy2 = guiGetPosition( self.gui['windowbg'], false )
		g_TotalToptimes = numLines
		setElementData(getResourceRootElement(getThisResource()), 'labelvisible', self.gui['busy'])
		setElementData(getLocalPlayer(), 'ttposition', playerPosition)
		setElementData(getLocalPlayer(), 'label', self.gui['windowbg'])
		setElementData(getLocalPlayer(), 'names'..i, data[i].playerName)
		setElementData(getLocalPlayer(), 'namesposx'..i, posx)
		setElementData(getLocalPlayer(), 'namesposx2'..i, posx2)
		setElementData(getLocalPlayer(), 'namesposy'..i, posy)
		setElementData(getLocalPlayer(), 'namesposy2'..i, posy2)
		
		local line3 =  string.format( '%s', timeText )
		guiSetText ( self.gui['listTimes'][i], line3 )
		local line4 = string.format( '%s', data[i].dateRecorded )
		guiSetText ( self.gui['listDate'][i], line4 )
	
		if i == playerPosition then
			guiLabelSetColor ( self.gui['listPos'][i], g_ToptimeR, g_ToptimeG, g_ToptimeB )
			guiLabelSetColor ( self.gui['listNames'][i], g_ToptimeR, g_ToptimeG, g_ToptimeB )
			guiLabelSetColor ( self.gui['listTimes'][i], g_ToptimeR, g_ToptimeG, g_ToptimeB )
			guiLabelSetColor ( self.gui['listDate'][i], g_ToptimeR, g_ToptimeG, g_ToptimeB )
		else
			guiLabelSetColor ( self.gui['listPos'][i], 255, 255, 255 )
			guiLabelSetColor ( self.gui['listNames'][i], 255, 255, 255 )
			guiLabelSetColor ( self.gui['listTimes'][i], 255, 255, 255 )
			guiLabelSetColor ( self.gui['listDate'][i], 255, 255, 255 )
		end
		
		local playerCountry = data[i].playerCountry
		if playerCountry then
			if playerCountry ~= "" and fileExists(":admin/client/images/flags/"..playerCountry..".png") then
				guiStaticImageLoadImage ( self.gui['listFlags'][i], ':admin/client/images/flags/'..playerCountry..'.png' )
			else
				if timeText ~= "" then
					guiStaticImageLoadImage ( self.gui['listFlags'][i], 'img/unk.png' )
				else
					guiStaticImageLoadImage ( self.gui['listFlags'][i], 'img/blank.png' )
				end
			end
		else
			if timeText ~= "" then
				guiStaticImageLoadImage ( self.gui['listFlags'][i], 'img/unk.png' )
			else
				guiStaticImageLoadImage ( self.gui['listFlags'][i], 'img/blank.png' )
			end
		end
	end

	-- Debug
	if _DEBUG_CHECK then
		outputDebug( 'TOPTIMES', 'toptimes', string.format('crev:%s  srev:%s', tostring(self.clientRevision), tostring(serverRevision) ) )
		if self.clientRevision == serverRevision then
			outputDebug( 'TOPTIMES', 'Already have this revision' )
		end
	end

	-- Update status
	self.clientRevision = serverRevision
	self.listStatus = 'Full'
	self:updateShow()
end

function onServerSentToptimes( data, serverRevision, playerPosition )
	g_CToptimes:doOnServerSentToptimes( data, serverRevision, playerPosition )
end

---------------------------------------------------------------------------
--
-- CToptimes:doOnClientRender
--
--
--
---------------------------------------------------------------------------
function CToptimes:doOnClientRender()
	-- Early out test
	if self.targetFade == self.currentFade then
		return
	end

	-- Calc delta seconds since last call
	local currentSeconds = getTickCount() / 1000
	local deltaSeconds = currentSeconds - self.lastSeconds
	self.lastSeconds = currentSeconds

	deltaSeconds = math.clamp( 0, deltaSeconds, 1/25 )

	-- Calc max fade change for this call
	local fadeSpeed = self.targetFade < self.currentFade and 2 or 6
	local maxChange = deltaSeconds * fadeSpeed

	-- Update current fade
	local dif = self.targetFade - self.currentFade
	dif = math.clamp( -maxChange, dif, maxChange )
	self.currentFade = self.currentFade + dif

	-- Apply
	guiSetAlpha( self.gui['windowbg'], self.currentFade * 0.4 )
	guiSetAlpha( self.gui['container'], self.currentFade)
	guiSetVisible( self.gui['windowbg'], self.currentFade > 0 )
end

addEventHandler ( 'onClientRender', getRootElement(),
	function()
		if guiGetVisible(g_AllowTimesLabel) == false and g_TotalToptimes > 0 then
			for i=1, g_TotalToptimes do
				if getElementData(getLocalPlayer(), 'names'..i) ~= nil then
					names = getElementData(getLocalPlayer(), 'names'..i)
					x = getElementData(getLocalPlayer(), 'namesposx'..i)
					x2 = getElementData(getLocalPlayer(), 'namesposx2'..i)
					y = getElementData(getLocalPlayer(), 'namesposy'..i)
					y2 = getElementData(getLocalPlayer(), 'namesposy2'..i)
					if getElementData(getLocalPlayer(), 'ttposition') == i then
						dxDrawText(names:gsub('#%x%x%x%x%x%x', ''), x+x2, y+y2, 0, 0, tocolor(g_ToptimeR, g_ToptimeG, g_ToptimeB, 540*guiGetAlpha(getElementData(getLocalPlayer(), 'label'))), 1.00, 'default-bold', 'left', 'top', false, true, true, true, false)
					else
						dxDrawText(names, x+x2, y+y2, 0, 0, tocolor(255, 255, 255, 540*guiGetAlpha(getElementData(getLocalPlayer(), 'label'))), 1.00, 'default-bold', 'left', 'top', false, true, true, true, false)
					end
				end
			end
		end
	end
)

addEventHandler ( 'onClientRender', getRootElement(),
	function(...)
		if g_CToptimes then
			g_CToptimes:doOnClientRender(...)
		end
	end
)


---------------------------------------------------------------------------
--
-- CToptimes:doToggleToptimes()
--
--
--
---------------------------------------------------------------------------
function CToptimes:doToggleToptimes( bOn )

	-- Kill any auto off timer
	self.autoOffTimer:killTimer()

	-- Set bManualShow from bOn, or toggle if nil
	if bOn ~= nil then
		self.bManualShow = bOn
	else
		self.bManualShow = not self.bManualShow
	end

	-- Set auto off timer if switching on
	if self.bManualShow then
		self.autoOffTimer:setTimer( function() self:doToggleToptimes(false) end, 15000, 1 )
	end

	self:updateShow()

end


---------------------------------------------------------------------------
--
-- Commands and binds
--
--
--
---------------------------------------------------------------------------

function onHotKey()
	if g_CToptimes then
		g_CToptimes:doToggleToptimes()
	end
end
addCommandHandler('showtimes', onHotKey)

addCommandHandler('doF5',
	function(player,command,...)
		outputDebugString('doF5')
		if g_CToptimes then
			g_CToptimes:doToggleToptimes()
		end
	end
)

---------------------------------------------------------------------------
-- Global instance
---------------------------------------------------------------------------
g_CToptimes = CToptimes:create()