-- client.lua
local sW, sH = guiGetScreenSize()

-- RESTORED CONFIG & VARIABLES
local teamNames = { [1] = Config.TeamNames[1], [2] = Config.TeamNames[2] }
local teamTags = { [1] = Config.TeamTags[1], [2] = Config.TeamTags[2] }
local teamColors = { [1] = Config.DefaultColors[1], [2] = Config.DefaultColors[2] }
local teamLogos = { [1] = Config.TeamLogos[1], [2] = Config.TeamLogos[2] }
local teamCaptains = { [1] = "", [2] = "" }

local teamScores = { [1] = 0, [2] = 0 }
local currentMode = Config.DefaultMode
local currentRound = 0
local roundLimit = Config.RoundLimit
local isCWActive = false 
local isTechPause = false
local clientMapQueue = {}

local isHudVisible = true
bindKey("F4", "down", function() isHudVisible = not isHudVisible end)

---------------------------------------------------
-- INPUT BLOCKING (Fix for 'B' key)
---------------------------------------------------
addEventHandler("onClientKey", root, function(button, press)
    if not isCWActive then return end
    if button == "b" and press then
        local tID = getElementData(localPlayer, "cw.team")
        if (tID == 3 or tID == 0) and currentRound > 0 and not isTechPause then
            cancelEvent() 
        end
    end
end)

---------------------------------------------------
-- SPECTATOR & VEHICLE LOCK LOGIC
---------------------------------------------------
addEvent("onForceClientSpectate", true)
addEventHandler("onForceClientSpectate", root, function()
    -- FIXED: Removed the triggerEvent("onSpectateRequest") to prevent infinite loop
    -- Just execute the command directly
    executeCommandHandler("spectate")
end)

-- LISTENER: Catches the event sent from the server
addEvent("onSpectateRequest", true)
addEventHandler("onSpectateRequest", root, function()
    triggerEvent("onForceClientSpectate", localPlayer)
end)

-- FAILSAFE: Strict Vehicle Lock for Spectators
addEventHandler("onClientRender", root, function()
    if not isCWActive then return end
    
    local tID = getElementData(localPlayer, "cw.team") or 0
    -- If player is Spectator (3) or Unassigned (0) and the match is running
    if (tID == 3 or tID == 0) and currentRound > 0 and not isTechPause then
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh then
            -- Freeze, cut engine, and make invisible to prevent interference
            setElementFrozen(veh, true)
            setVehicleEngineState(veh, false)
            setElementCollisionsEnabled(veh, false)
        end
    end
end)

---------------------------------------------------
-- HUD
---------------------------------------------------
local hudY = 80 
local hudW = 400
local hudH = 50
local hudX = (sW - hudW) / 2

function drawCSGOHud()
    if not isCWActive or not isHudVisible then return end 
    if isPlayerMapVisible() then return end

    local c1r, c1g, c1b = 255, 50, 50
    local c2r, c2g, c2b = 50, 100, 255
    
    if teamColors[1] then
        local hex = teamColors[1]:gsub("#","")
        c1r, c1g, c1b = tonumber("0x"..hex:sub(1,2)) or 255, tonumber("0x"..hex:sub(3,4)) or 50, tonumber("0x"..hex:sub(5,6)) or 50
    end
    if teamColors[2] then
        local hex = teamColors[2]:gsub("#","")
        c2r, c2g, c2b = tonumber("0x"..hex:sub(1,2)) or 50, tonumber("0x"..hex:sub(3,4)) or 100, tonumber("0x"..hex:sub(5,6)) or 255
    end

    dxDrawRectangle(hudX, hudY, hudW, hudH, tocolor(20, 20, 20, 200))
    dxDrawRectangle(hudX, hudY, hudW/2 - 30, hudH, tocolor(60, 20, 20, 150))
    dxDrawRectangle(hudX, hudY + hudH - 3, hudW/2 - 30, 3, tocolor(c1r, c1g, c1b, 255)) 
    dxDrawRectangle(hudX + hudW/2 + 30, hudY, hudW/2 - 30, hudH, tocolor(20, 20, 60, 150))
    dxDrawRectangle(hudX + hudW/2 + 30, hudY + hudH - 3, hudW/2 - 30, 3, tocolor(c2r, c2g, c2b, 255)) 
    dxDrawRectangle(hudX + hudW/2 - 30, hudY, 60, hudH, tocolor(40, 40, 40, 230))
    
    local img1 = "logos/" .. (teamLogos[1] or "placeholder") .. ".png"
    if fileExists(img1) then dxDrawImage(hudX - 60, hudY, 50, 50, img1, 0, 0, 0, tocolor(255, 255, 255, 255)) end

    local img2 = "logos/" .. (teamLogos[2] or "placeholder") .. ".png"
    if fileExists(img2) then dxDrawImage(hudX + hudW + 10, hudY, 50, 50, img2, 0, 0, 0, tocolor(255, 255, 255, 255)) end

    dxDrawText(teamNames[1], hudX + 10, hudY + 5, hudX + hudW/2 - 40, hudY + 25, tocolor(255,255,255,255), 1, "default-bold", "left", "center", true, false)
    dxDrawText(teamScores[1], hudX + 10, hudY + 25, hudX + hudW/2 - 40, hudY + 45, tocolor(255,255,255,255), 1.5, "default-bold", "right", "center")
    dxDrawText(teamNames[2], hudX + hudW/2 + 40, hudY + 5, hudX + hudW - 10, hudY + 25, tocolor(255,255,255,255), 1, "default-bold", "right", "center", true, false)
    dxDrawText(teamScores[2], hudX + hudW/2 + 40, hudY + 25, hudX + hudW - 10, hudY + 45, tocolor(255,255,255,255), 1.5, "default-bold", "left", "center")

    if isTechPause then
        dxDrawText("TECH", hudX + hudW/2 - 30, hudY + 20, hudX + hudW/2 + 30, hudY + 32, tocolor(255, 50, 50, 255), 0.7, "default-bold", "center", "center")
        dxDrawText("PAUSE", hudX + hudW/2 - 30, hudY + 32, hudX + hudW/2 + 30, hudY + 45, tocolor(255, 50, 50, 255), 0.7, "default-bold", "center", "center")
    elseif currentRound == 0 then
        dxDrawText("WARMUP", hudX + hudW/2 - 30, hudY + 20, hudX + hudW/2 + 30, hudY + 45, tocolor(255,215,0,255), 0.7, "default-bold", "center", "center")
    else
        dxDrawText(currentRound .. "/" .. roundLimit, hudX + hudW/2 - 30, hudY + 20, hudX + hudW/2 + 30, hudY + 45, tocolor(255,255,255,255), 1, "default-bold", "center", "center")
    end
    
    if #clientMapQueue > 0 then
        dxDrawText("Next: " .. clientMapQueue[1].displayName, hudX, hudY + hudH + 5, hudX + hudW, hudY + hudH + 20, tocolor(255,255,255,150), 0.9, "default", "center", "top")
    end
end
addEventHandler("onClientRender", root, drawCSGOHud)

local adminWin = nil
local mapGrid, queueGrid
local mapCache = {}
local comboMode = nil 

function refreshQueueList()
    if isElement(queueGrid) then
        guiGridListClear(queueGrid)
        for i, mapData in ipairs(clientMapQueue) do
            local row = guiGridListAddRow(queueGrid)
            guiGridListSetItemText(queueGrid, row, 1, i .. ". " .. mapData.displayName, false, false)
            guiGridListSetItemData(queueGrid, row, 1, mapData.resName)
        end
    end
end

addEvent("updateCWHUD", true)
addEventHandler("updateCWHUD", root, function(tNames, tScores, tTags, tColors, tLogos, mode, rnd, rndLim, active, queue, tech, captains)
    teamNames = tNames
    teamScores = tScores
    teamTags = tTags
    teamColors = tColors
    teamLogos = tLogos
    currentMode = mode
    currentRound = rnd
    roundLimit = rndLim
    isCWActive = active
    isTechPause = tech
    clientMapQueue = queue or {}
    if captains then teamCaptains = captains end
    refreshQueueList()
end)

local function isMouseInPosition(x, y, w, h)
	if not isCursorShowing() then return false end
	local cx, cy = getCursorPosition()
	cx, cy = cx * sW, cy * sH
	return (cx >= x and cx <= x + w) and (cy >= y and cy <= y + h)
end

function drawTooltips()
    if not isElement(adminWin) or not guiGetVisible(adminWin) or not isElement(comboMode) then return end
    local x, y = guiGetPosition(comboMode, false)
    local w, h = guiGetSize(comboMode, false)
    local wx, wy = guiGetPosition(adminWin, false)
    if isMouseInPosition(wx + x, wy + y, w, 25) then
        local cx, cy = getCursorPosition()
        cx, cy = cx * sW, cy * sH
        local text = ""
        local selected = guiComboBoxGetSelected(comboMode)
        local itemText = guiComboBoxGetItemText(comboMode, selected)
        if itemText == "Classic" then text = "Classic: Default system.\nPoints awarded based on finish rank.\nUsed for standard matches."
        elseif itemText == "PlayerL" then text = "PlayerL: Player League System.\nOriginated from Jacob tournaments.\nTeams/Players get points for every checkpoint." end
        if text ~= "" then
            local tw = dxGetTextWidth(text, 1, "default") + 10
            local th = 55
            dxDrawRectangle(cx + 15, cy, tw, th, tocolor(0, 0, 0, 220), true)
            dxDrawText(text, cx + 20, cy + 5, cx + 20 + tw, cy + th, tocolor(255, 255, 255, 255), 1, "default", "left", "top", false, false, true)
        end
    end
end
addEventHandler("onClientRender", root, drawTooltips)

function toggleAdminGUI()
    if isElement(adminWin) then
        destroyElement(adminWin)
        adminWin = nil
        comboMode = nil
        showCursor(false)
        guiSetInputMode("allow_binds")
        return
    end
    
    guiSetInputMode("no_binds_when_editing")

    -- Increased height for new options
    local w, h = 600, 700 
    local x, y = (sW - w)/2, (sH - h)/2
    adminWin = guiCreateWindow(x, y, w, h, "Clan War Control Panel", false)
    guiWindowSetSizable(adminWin, false)
    
    local ly = 25
    guiCreateLabel(20, ly, 200, 20, "Team 1 Name:", false, adminWin)
    local editT1 = guiCreateEdit(20, ly+20, 200, 25, teamNames[1], false, adminWin)
    -- NEW: Score Edit
    guiCreateLabel(230, ly, 50, 20, "Score:", false, adminWin)
    local editScore1 = guiCreateEdit(230, ly+20, 50, 25, tostring(teamScores[1]), false, adminWin)
    
    ly = ly + 50
    guiCreateLabel(20, ly, 200, 20, "Team 2 Name:", false, adminWin)
    local editT2 = guiCreateEdit(20, ly+20, 200, 25, teamNames[2], false, adminWin)
    -- NEW: Score Edit
    guiCreateLabel(230, ly, 50, 20, "Score:", false, adminWin)
    local editScore2 = guiCreateEdit(230, ly+20, 50, 25, tostring(teamScores[2]), false, adminWin)
    
    ly = ly + 50
    guiCreateLabel(20, ly, 80, 20, "Tag T1:", false, adminWin)
    local editTag1 = guiCreateEdit(20, ly+20, 80, 25, teamTags[1], false, adminWin)
    guiCreateLabel(140, ly, 80, 20, "Tag T2:", false, adminWin)
    local editTag2 = guiCreateEdit(140, ly+20, 80, 25, teamTags[2], false, adminWin)
    
    ly = ly + 50
    guiCreateLabel(20, ly, 80, 20, "Color T1:", false, adminWin)
    local editCol1 = guiCreateEdit(20, ly+20, 80, 25, teamColors[1], false, adminWin)
    guiCreateLabel(140, ly, 80, 20, "Color T2:", false, adminWin)
    local editCol2 = guiCreateEdit(140, ly+20, 80, 25, teamColors[2], false, adminWin)

    ly = ly + 50
    guiCreateLabel(20, ly, 80, 20, "Logo T1:", false, adminWin)
    local editLogo1 = guiCreateEdit(20, ly+20, 80, 25, teamLogos[1], false, adminWin)
    guiSetProperty(editLogo1, "Tooltip", "File name without .png (e.g. lsr)")
    guiCreateLabel(140, ly, 80, 20, "Logo T2:", false, adminWin)
    local editLogo2 = guiCreateEdit(140, ly+20, 80, 25, teamLogos[2], false, adminWin)
    guiSetProperty(editLogo2, "Tooltip", "File name without .png (e.g. poland)")

    ly = ly + 50
    guiCreateLabel(20, ly, 200, 20, "Captain T1 (Name):", false, adminWin)
    local editCap1 = guiCreateEdit(20, ly+20, 200, 25, teamCaptains[1] or "", false, adminWin)
    guiSetProperty(editCap1, "Tooltip", "Exact name (colors ignored)")

    ly = ly + 50
    guiCreateLabel(20, ly, 200, 20, "Captain T2 (Name):", false, adminWin)
    local editCap2 = guiCreateEdit(20, ly+20, 200, 25, teamCaptains[2] or "", false, adminWin)
    guiSetProperty(editCap2, "Tooltip", "Exact name (colors ignored)")
    
    ly = ly + 55
    guiCreateLabel(20, ly, 80, 20, "Total Rnds:", false, adminWin)
    local editRounds = guiCreateEdit(20, ly+20, 80, 25, tostring(roundLimit), false, adminWin)
    guiCreateLabel(110, ly, 80, 20, "Cur Rnd:", false, adminWin)
    local editCurRnd = guiCreateEdit(110, ly+20, 50, 25, tostring(currentRound), false, adminWin)

    ly = ly + 50
    guiCreateLabel(20, ly, 200, 20, "Points System (Hover for Info):", false, adminWin)
    comboMode = guiCreateComboBox(20, ly+20, 200, 100, currentMode, false, adminWin)
    guiComboBoxAddItem(comboMode, "Classic")
    guiComboBoxAddItem(comboMode, "PlayerL")
    if currentMode == "Classic" then guiComboBoxSetSelected(comboMode, 0)
    elseif currentMode == "PlayerL" then guiComboBoxSetSelected(comboMode, 1) end
    
    local btnApply = guiCreateButton(20, ly+70, 95, 30, "Apply Settings", false, adminWin)
    local btnAction = guiCreateButton(125, ly+70, 95, 30, isCWActive and "STOP Match" or "START Match", false, adminWin)
    guiSetProperty(btnAction, "NormalTextColour", isCWActive and "FFFF0000" or "FF00FF00")

    -- MAP MANAGEMENT
    guiCreateLabel(320, 30, 240, 20, "Map Management", false, adminWin)
    local editSearch = guiCreateEdit(320, 50, 240, 25, "", false, adminWin)
    mapGrid = guiCreateGridList(320, 80, 260, 150, false, adminWin)
    guiGridListAddColumn(mapGrid, "Available Maps", 0.9)
    local btnAddMap = guiCreateButton(320, 240, 110, 30, "Add to Queue", false, adminWin)
    queueGrid = guiCreateGridList(320, 280, 260, 150, false, adminWin)
    guiGridListAddColumn(queueGrid, "Map Queue", 0.9)
    local btnRemMap = guiCreateButton(320, 440, 100, 30, "Remove Map", false, adminWin)
    local btnForceStart = guiCreateButton(450, 440, 110, 30, "Force Start", false, adminWin)

    -- NEW: FAIL-SAFE SAVE/LOAD SECTION
    guiCreateLabel(320, 500, 240, 20, "File Manager (Save/Load)", false, adminWin)
    local editFileName = guiCreateEdit(320, 520, 240, 25, "match1", false, adminWin)
    guiSetProperty(editFileName, "Tooltip", "Enter filename (e.g. final_match)")
    local btnSave = guiCreateButton(320, 550, 110, 30, "Save to File", false, adminWin)
    local btnLoad = guiCreateButton(450, 550, 110, 30, "Load from File", false, adminWin)

    refreshQueueList()
    triggerServerEvent("requestMapList", localPlayer)

    addEventHandler("onClientGUIChanged", editSearch, function()
        local text = string.lower(guiGetText(source))
        guiGridListClear(mapGrid)
        for _, mapData in ipairs(mapCache) do
            if text == "" or string.find(string.lower(mapData.displayName), text, 1, true) then
                local row = guiGridListAddRow(mapGrid)
                guiGridListSetItemText(mapGrid, row, 1, mapData.displayName, false, false)
                guiGridListSetItemData(mapGrid, row, 1, mapData.resName)
            end
        end
    end, false)
    
    local function getComboText()
        local item = guiComboBoxGetSelected(comboMode)
        if item == -1 then return currentMode end 
        return guiComboBoxGetItemText(comboMode, item)
    end
    
    local function collectData()
        return {
            t1name = guiGetText(editT1), t2name = guiGetText(editT2),
            t1tag = guiGetText(editTag1), t2tag = guiGetText(editTag2),
            c1 = guiGetText(editCol1), c2 = guiGetText(editCol2),
            l1 = guiGetText(editLogo1), l2 = guiGetText(editLogo2),
            rounds = guiGetText(editRounds), currentRnd = guiGetText(editCurRnd),
            mode = getComboText(),
            cap1 = guiGetText(editCap1), cap2 = guiGetText(editCap2),
            -- NEW SCORES
            score1 = guiGetText(editScore1), score2 = guiGetText(editScore2)
        }
    end

    addEventHandler("onClientGUIClick", btnApply, function() triggerServerEvent("onAdminApplySettings", localPlayer, collectData()) end, false)
    addEventHandler("onClientGUIClick", btnAction, function()
        if isCWActive then triggerServerEvent("onAdminStopCW", localPlayer) else triggerServerEvent("onAdminStartCW", localPlayer, collectData()) end
        toggleAdminGUI()
    end, false)
    addEventHandler("onClientGUIClick", btnAddMap, function()
        local row = guiGridListGetSelectedItem(mapGrid)
        if row ~= -1 then triggerServerEvent("onAdminAddMap", localPlayer, guiGridListGetItemData(mapGrid, row, 1), guiGridListGetItemText(mapGrid, row, 1)) end
    end, false)
    addEventHandler("onClientGUIClick", btnRemMap, function()
        local row = guiGridListGetSelectedItem(queueGrid)
        if row ~= -1 then triggerServerEvent("onAdminRemoveMap", localPlayer, row + 1) end
    end, false)
    addEventHandler("onClientGUIClick", btnForceStart, function()
        local row = guiGridListGetSelectedItem(queueGrid)
        if row ~= -1 then triggerServerEvent("onAdminStartQueuedMap", localPlayer, row + 1); toggleAdminGUI() end
    end, false)
    
    -- SAVE/LOAD EVENTS
    addEventHandler("onClientGUIClick", btnSave, function()
        local fname = guiGetText(editFileName)
        if fname ~= "" then triggerServerEvent("onAdminSaveMatch", localPlayer, fname) end
    end, false)
    addEventHandler("onClientGUIClick", btnLoad, function()
        local fname = guiGetText(editFileName)
        if fname ~= "" then triggerServerEvent("onAdminLoadMatch", localPlayer, fname) end
    end, false)

    showCursor(true)
end
bindKey("F2", "down", toggleAdminGUI)

addEventHandler("onClientResourceStart", resourceRoot, function() triggerServerEvent("checkAdminForWelcome", localPlayer) end)

local teamWin = nil
function toggleTeamGUI()
    if isElement(teamWin) then destroyElement(teamWin); teamWin = nil; showCursor(false); return end
    if not isCWActive then outputChatBox("Clan War is not active.", 255, 50, 50); return end
    local w, h = 300, 220
    local x, y = (sW - w)/2, (sH - h)/2
    teamWin = guiCreateWindow(x, y, w, h, "Join Team", false)
    guiWindowSetSizable(teamWin, false)
    local btnT1 = guiCreateButton(0.1, 0.2, 0.8, 0.2, "Join " .. teamNames[1], true, teamWin)
    local btnT2 = guiCreateButton(0.1, 0.45, 0.8, 0.2, "Join " .. teamNames[2], true, teamWin)
    local btnSpec = guiCreateButton(0.1, 0.7, 0.8, 0.2, "Spectator", true, teamWin)
    addEventHandler("onClientGUIClick", btnT1, function() triggerServerEvent("onPlayerRequestJoinTeam", localPlayer, 1); toggleTeamGUI() end, false)
    addEventHandler("onClientGUIClick", btnT2, function() triggerServerEvent("onPlayerRequestJoinTeam", localPlayer, 2); toggleTeamGUI() end, false)
    addEventHandler("onClientGUIClick", btnSpec, function() triggerServerEvent("onPlayerRequestJoinTeam", localPlayer, 0); toggleTeamGUI() end, false)
    showCursor(true)
end
bindKey("F3", "down", toggleTeamGUI)
addEvent("showTeamJoinGUI", true); addEventHandler("showTeamJoinGUI", root, toggleTeamGUI)

---------------------------------------------------
-- HELP MENU (F10)
---------------------------------------------------
local helpWin = nil
function toggleHelpGUI()
    if isElement(helpWin) then destroyElement(helpWin); helpWin = nil; showCursor(false); return end
    
    local w, h = sW * 0.4, sH * 0.5 
    if w < 400 then w = 400 end
    local x, y = (sW - w)/2, (sH - h)/2
    
    helpWin = guiCreateWindow(x, y, w, h, "Clan War Help", false)
    guiWindowSetSizable(helpWin, false)
    
    local helpText = [[
Welcome to the Clan War Manager!

KEYBINDS:
* F2: Open Admin Control Panel (Admins Only)
* F3: Join Team / Spectate
* F4: Toggle CW HUD
* /rd: Captain sets team to READY
* /nr: Captain sets team to NOT READY
* /tech: Technical Pause (Admins Only)

MODES:
1. Classic: Standard race scoring. Points awarded by finish position (1st=15pts, etc).
2. PlayerL (League): Points awarded for every checkpoint collected + team bonus.

SPECTATING:
If you join the Spectators team, or join mid-game without a team, you will automatically be put into spectate mode.
]]
    
    local memo = guiCreateMemo(0.05, 0.1, 0.9, 0.8, helpText, true, helpWin)
    guiMemoSetReadOnly(memo, true)
    
    showCursor(true)
end
bindKey("F10", "down", toggleHelpGUI)

addEvent("receiveMapList", true)
addEventHandler("receiveMapList", root, function(maps)
    mapCache = maps 
    if not isElement(mapGrid) then return end
    guiGridListClear(mapGrid)
    for _, mapData in ipairs(maps) do
        local row = guiGridListAddRow(mapGrid)
        guiGridListSetItemText(mapGrid, row, 1, mapData.displayName, false, false)
        guiGridListSetItemData(mapGrid, row, 1, mapData.resName)
    end
end)