--init
local s_x, s_y = guiGetScreenSize()
local text_offset = 20
local teams = {}
local c_round = 0
local m_round = 0
local f_round = false
local isLeagueMode = false
local isAdmin = false
local isTechPause = false
local leagueWarmupEndTime = 0
local isHudVisible = true

-- GUI Variables
local c_window = nil
local a_window = nil
local map_grid = nil
local queue_grid = nil

local cmb_players = nil
local cmb_referee = nil
local player_combo_map = {}
local lbl_cap1 = nil
local lbl_cap2 = nil
local selected_cap1 = ""
local selected_cap2 = ""
local chk_league = nil

-- CC Limit Variables
local ban_limit_field = nil
local pick_limit_field = nil

-----------------
-- Call functions
-----------------
function serverCall(funcname, ...) triggerServerEvent("onClientCallsServerFunction", resourceRoot, funcname, ...) end
addEvent("onServerCallsClientFunction", true)
addEventHandler("onServerCallsClientFunction", resourceRoot, function(funcname, ...) if _G[funcname] then _G[funcname](...) end end)

------------------------
-- HELPER
------------------------
function hexToRGB(hex)
    if not hex then return 255, 0, 0 end
    hex = hex:gsub("#","")
    if #hex ~= 6 then return 255, 0, 0 end 
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end
function rgbToHex(r, g, b)
    if not r or not g or not b then return "#FFFFFF" end
    return string.format("#%02X%02X%02X", r, g, b)
end

------------------------
-- DISPLAY
------------------------
function updateDisplay()
    if isElement(teams[1]) and isHudVisible then
        local boxWidth = 220 
        local startX = s_x - boxWidth - 20
        local centerX = startX + (boxWidth / 2)
        local baseY = 250 
        
        if not f_round then
            local hudHeight = 110 
            local textY = baseY + 25 
            local ranked = {}
            if isLeagueMode then
                local players = getElementsByType("player")
                for i, p in ipairs(players) do if getPlayerTeam(p) == teams[1] then table.insert(ranked, p) end end
                table.sort(ranked, function(a,b) return (tonumber(getElementData(a, "Score") or 0) > tonumber(getElementData(b, "Score") or 0)) end)
                local playerCount = math.min(5, #ranked)
                hudHeight = 45 + (playerCount * 20)
                if playerCount == 0 then hudHeight = 45 end
                textY = baseY + 20 
            end

            dxDrawRectangle(startX, baseY, boxWidth, hudHeight, tocolor(0, 0, 0, 160))
            if c_round == m_round then dxDrawText('FINAL ROUND', centerX, textY, centerX, textY, tocolor(255, 255, 0, 255), 1.2, "default-bold", 'center', 'center')
            else dxDrawText('Round ' ..c_round.. ' of ' ..m_round, centerX, textY, centerX, textY, tocolor(255, 255, 150, 255), 1.2, "default-bold", 'center', 'center') end
            
            if isLeagueMode then
                local y_off = 25
                for i=1, math.min(5, #ranked) do
                    local p = ranked[i]
                    local score = getElementData(p, "Score") or 0
                    local name = getPlayerName(p):gsub("#%x%x%x%x%x%x", "")
                    local r, g, b = getPlayerNametagColor(p)
                    if #name > 15 then name = string.sub(name, 1, 13)..".." end
                    dxDrawText(i..". "..name.. ' : ' ..score, centerX, textY + y_off, centerX, textY + y_off, tocolor(r, g, b, 255), 1.0, "default-bold", 'center', 'center')
                    y_off = y_off + 20
                end
            elseif isElement(teams[2]) then
                local r1, g1, b1 = getTeamColor(teams[1]); local r2, g2, b2 = getTeamColor(teams[2])
                local t1s = tonumber(getElementData(teams[1], 'Score')) or 0; local t2s = tonumber(getElementData(teams[2], 'Score')) or 0
                local t1n = getTeamName(teams[1]); local t2n = getTeamName(teams[2])
                if #t1n > 15 then t1n = string.sub(t1n, 1, 13)..".." end; if #t2n > 15 then t2n = string.sub(t2n, 1, 13)..".." end
                
                local t1Y = textY + 30; local t2Y = textY + 60
                if t1s > t2s then
                    dxDrawText(t1n.. ' - ' ..t1s, centerX, t1Y, centerX, t1Y, tocolor(r1, g1, b1, 255), 1.4, "default-bold", 'center', 'center')
                    dxDrawText(t2n.. ' - ' ..t2s, centerX, t2Y, centerX, t2Y, tocolor(r2, g2, b2, 255), 1.2, "default-bold", 'center', 'center')
                else
                    dxDrawText(t2n.. ' - ' ..t2s, centerX, t1Y, centerX, t1Y, tocolor(r2, g2, b2, 255), 1.4, "default-bold", 'center', 'center')
                    dxDrawText(t1n.. ' - ' ..t1s, centerX, t2Y, centerX, t2Y, tocolor(r1, g1, b1, 255), 1.2, "default-bold", 'center', 'center')
                end
            end
        else
            dxDrawRectangle(startX, baseY, boxWidth, 80, tocolor(0, 0, 0, 160))
            local warmTextY = baseY + 25
            
            if isTechPause then
                dxDrawText('TECH PAUSE', centerX, warmTextY, centerX, warmTextY, tocolor(255, 0, 0, 255), 1.2, "default-bold", 'center', 'center')
                dxDrawText('Wait for Captains', centerX, warmTextY+25, centerX, warmTextY+25, tocolor(255, 200, 200, 255), 1.0, "default-bold", 'center', 'center')
            else
                dxDrawText('WARMUP', centerX, warmTextY, centerX, warmTextY, tocolor(255, 255, 255, 255), 1.2, "default-bold", 'center', 'center')
                if isLeagueMode and leagueWarmupEndTime > 0 then
                    local remaining = math.max(0, math.floor((leagueWarmupEndTime - getTickCount()) / 1000))
                    dxDrawText('Starts in: '..remaining..'s', centerX, warmTextY+25, centerX, warmTextY+25, tocolor(200, 200, 200, 255), 1.0, "default-bold", 'center', 'center')
                else dxDrawText('Wait for Ready', centerX, warmTextY+25, centerX, warmTextY+25, tocolor(200, 200, 200, 255), 1.0, "default-bold", 'center', 'center') end
            end
        end
    end
end
addEventHandler('onClientRender', root, updateDisplay)
function toggleClanwarHUD() isHudVisible = not isHudVisible end
bindKey("F1", "down", toggleClanwarHUD)

------------------------
-- GUI: TEAM SELECTION
------------------------
function createGUI(team1, team2, _isLeague) 
    if isElement(c_window) then destroyElement(c_window) end
    if _isLeague ~= nil then isLeagueMode = _isLeague end

    c_window = guiCreateWindow(s_x/2-150, s_y/2-75, 300, 160, 'Race League Selection', false)
    guiWindowSetMovable(c_window, false); guiWindowSetSizable(c_window, false)
    
    local lbl = guiCreateLabel(10, 20, 280, 15, "Choose your team:", false, c_window)
    guiLabelSetHorizontalAlign(lbl, "center")

    if isLeagueMode then
        local t1_button = guiCreateButton(40, 45, 220, 30, team1, false, c_window)
        addEventHandler("onClientGUIClick", t1_button, function() selectTeam(teams[1]) end, false)
    else
        local t1_button = guiCreateButton(40, 45, 100, 30, team1, false, c_window)
        addEventHandler("onClientGUIClick", t1_button, function() selectTeam(teams[1]) end, false)
        local t2_button = guiCreateButton(160, 45, 100, 30, team2, false, c_window)
        addEventHandler("onClientGUIClick", t2_button, function() selectTeam(teams[2]) end, false)
    end
    
    local t3_button = guiCreateButton(40, 90, 220, 30, 'Spectators (Spec Mode)', false, c_window)
    addEventHandler("onClientGUIClick", t3_button, function() selectTeam(isElement(teams[3]) and teams[3] or 3) end, false)
    
    showCursor(true); guiSetInputMode("no_binds_when_editing")
end
addEvent("createGUI", true)
addEventHandler("createGUI", root, createGUI)

function selectTeam(teamInput)
    local teamElem = teamInput
    if type(teamInput) == "number" and teams[teamInput] then teamElem = teams[teamInput] end
    if isElement(teamElem) then
        triggerServerEvent("onPlayerRequestTeam", localPlayer, teamElem)
        if isElement(c_window) then guiSetVisible(c_window, false) end
        showCursor(false)
        if getTeamName(teamElem) == "Spectators" then triggerEvent("onSpectateRequest", localPlayer) end
    end
end

------------------------
-- GUI: ADMIN PANEL
------------------------
function createAdminGUI()
    if isElement(a_window) then destroyElement(a_window) end
    a_window = guiCreateWindow(s_x/2-325, s_y/2-200, 650, 400, 'Race League Admin Panel', false)
    guiWindowSetSizable(a_window, false)
    
    local tab_panel = guiCreateTabPanel(0, 0.08, 1, 0.82, true, a_window)
    
    -- === TAB 1: SETTINGS ===
    local tab_gen = guiCreateTab('General', tab_panel)
    guiCreateLabel(10, 10, 100, 20, "Team 1 Tag:", false, tab_gen)
    t1_field = guiCreateEdit(10, 30, 150, 25, "TeamA", false, tab_gen)
    guiCreateLabel(170, 10, 100, 20, "Color (HEX):", false, tab_gen)
    t1c_field = guiCreateEdit(170, 30, 80, 25, "#FF0000", false, tab_gen)
    guiCreateLabel(10, 60, 100, 20, "Team 2 Tag:", false, tab_gen)
    t2_field = guiCreateEdit(10, 80, 150, 25, "TeamB", false, tab_gen)
    guiCreateLabel(170, 60, 100, 20, "Color (HEX):", false, tab_gen)
    t2c_field = guiCreateEdit(170, 80, 80, 25, "#0000FF", false, tab_gen)
    chk_league = guiCreateCheckBox(270, 30, 180, 20, "Player League Mode", false, false, tab_gen)
    guiCreateLabel(270, 50, 350, 30, "(Points per Checkpoint - All join Team 1)", false, tab_gen)

    local btn_start = guiCreateButton(10, 130, 140, 35, "START / APPLY", false, tab_gen)
    addEventHandler("onClientGUIClick", btn_start, function() requestStartWar(false) end, false)
    local btn_stop = guiCreateButton(160, 130, 140, 35, "Stop Match", false, tab_gen)
    addEventHandler("onClientGUIClick", btn_stop, function() serverCall('destroyTeams', localPlayer) end, false)
    local btn_end = guiCreateButton(310, 130, 140, 35, "Force End", false, tab_gen)
    addEventHandler("onClientGUIClick", btn_end, function() serverCall('forceEndMatch') end, false)
    local btn_fstart = guiCreateButton(460, 130, 140, 35, "Force Start", false, tab_gen)
    addEventHandler("onClientGUIClick", btn_fstart, function()
        if isElement(teams[1]) then serverCall('forceStartMatch') else requestStartWar(true) end
    end, false)

    guiCreateLabel(10, 180, 150, 20, "Select Referee:", false, tab_gen)
    cmb_referee = guiCreateComboBox(10, 200, 180, 300, "Select Referee", false, tab_gen)
    local btn_ref = guiCreateButton(200, 200, 80, 25, "Set Ref", false, tab_gen)
    addEventHandler("onClientGUIClick", btn_ref, function() 
        local row = guiComboBoxGetSelected(cmb_referee)
        if row ~= -1 then local name = player_combo_map[row]; if name then serverCall('setReferee', name) end end
    end, false)

    guiCreateLabel(310, 175, 150, 20, "Select Captains:", false, tab_gen)
    cmb_players = guiCreateComboBox(310, 195, 180, 300, "Select Player", false, tab_gen)
    local btn_set_c1 = guiCreateButton(500, 195, 60, 25, "Set T1", false, tab_gen)
    local btn_set_c2 = guiCreateButton(570, 195, 60, 25, "Set T2", false, tab_gen)
    lbl_cap1 = guiCreateLabel(310, 230, 140, 20, "T1: None", false, tab_gen)
    lbl_cap2 = guiCreateLabel(500, 230, 140, 20, "T2: None", false, tab_gen)
    local btn_rem_cap = guiCreateButton(310, 255, 320, 25, "Remove Captains", false, tab_gen)

    addEventHandler("onClientGUIClick", btn_set_c1, function()
        if guiCheckBoxGetSelected(chk_league) then outputChatBox("[RL] Error: Captains are disabled in Player League mode.", 255, 0, 0); return end
        local row = guiComboBoxGetSelected(cmb_players)
        if row ~= -1 then
            local selected = player_combo_map[row]
            if selected then selected_cap1 = selected; guiSetText(lbl_cap1, "T1: " .. (selected:gsub("#%x%x%x%x%x%x", ""))); serverCall('setCaptains', selected_cap1, selected_cap2) end
        end
    end, false)

    addEventHandler("onClientGUIClick", btn_set_c2, function()
        if guiCheckBoxGetSelected(chk_league) then outputChatBox("[RL] Error: Captains are disabled in Player League mode.", 255, 0, 0); return end
        local row = guiComboBoxGetSelected(cmb_players)
        if row ~= -1 then
            local selected = player_combo_map[row]
            if selected then selected_cap2 = selected; guiSetText(lbl_cap2, "T2: " .. (selected:gsub("#%x%x%x%x%x%x", ""))); serverCall('setCaptains', selected_cap1, selected_cap2) end
        end
    end, false)

    addEventHandler("onClientGUIClick", btn_rem_cap, function()
        selected_cap1 = ""; selected_cap2 = ""; guiSetText(lbl_cap1, "T1: None"); guiSetText(lbl_cap2, "T2: None"); serverCall('setCaptains', "", "")
    end, false)

    -- === TAB 2: SCORE/ROUNDS ===
    local tab_scr = guiCreateTab('Score', tab_panel)
    guiCreateLabel(20, 20, 400, 20, "Edit Scores manually:", false, tab_scr)
    guiCreateLabel(20, 60, 60, 20, "T1 Score:", false, tab_scr); t1cur_field = guiCreateEdit(90, 60, 80, 30, "0", false, tab_scr)
    guiCreateLabel(20, 100, 60, 20, "T2 Score:", false, tab_scr); t2cur_field = guiCreateEdit(90, 100, 80, 30, "0", false, tab_scr)
    guiCreateLabel(250, 60, 80, 20, "Cur Round:", false, tab_scr); cr_field = guiCreateEdit(330, 60, 80, 30, "0", false, tab_scr)
    guiCreateLabel(250, 100, 80, 20, "Max Rnds:", false, tab_scr); ct_field = guiCreateEdit(330, 100, 80, 30, "10", false, tab_scr)
    local btn_upd = guiCreateButton(20, 160, 200, 40, "Update Stats & Announce", false, tab_scr)
    addEventHandler("onClientGUIClick", btn_upd, requestUpdateScore, false)

    -- === TAB 3: MAP QUEUE ===
    local tab_map = guiCreateTab('Map Queue', tab_panel)
    map_grid = guiCreateGridList(10, 10, 280, 280, false, tab_map); guiGridListAddColumn(map_grid, "Server Maps", 0.9)
    queue_grid = guiCreateGridList(350, 10, 280, 280, false, tab_map); guiGridListAddColumn(queue_grid, "Match Queue", 0.9)
    local btn_add = guiCreateButton(300, 100, 40, 40, "->", false, tab_map)
    local btn_rem = guiCreateButton(300, 150, 40, 40, "<-", false, tab_map)
    addEventHandler("onClientGUIClick", btn_add, addMapToQueue, false)
    addEventHandler("onClientGUIClick", btn_rem, removeMapFromQueue, false)
    serverCall("requestMapList")

    -- === TAB 4: HELP ===
    local tab_help = guiCreateTab('Help / Commands', tab_panel)
    local memo_help = guiCreateMemo(10, 10, 610, 310, "Commands:\n/rd - Ready up\n/tech - Tech Pause\nF2 - Admin Panel\n/forcerd, /forcestart\n/playerpts [nick] [amount]\n/mvp [nick] [t1/t2/spec]\n/ccrandom - Fill queue automatically from CC pool", false, tab_help)
    guiMemoSetReadOnly(memo_help, true)
    
    -- === TAB 5: CAPTAINS MODE (CC26) ===
    local tab_cc = guiCreateTab('Captains Mode', tab_panel)
    guiCreateLabel(20, 20, 600, 20, "Ensure Captains are set in the 'General' tab.", false, tab_cc)
    
    guiCreateLabel(20, 100, 120, 20, "Max Bans per Cat:", false, tab_cc)
    ban_limit_field = guiCreateEdit(140, 100, 50, 25, "2", false, tab_cc)
    
    guiCreateLabel(210, 100, 120, 20, "Max Picks per Cat:", false, tab_cc)
    pick_limit_field = guiCreateEdit(330, 100, 50, 25, "2", false, tab_cc)

    local btn_start_cc = guiCreateButton(20, 140, 200, 40, "Start Captains Mode", false, tab_cc)
    addEventHandler("onClientGUIClick", btn_start_cc, function()
        if guiCheckBoxGetSelected(chk_league) then
            outputChatBox("[CC] Error: Captains Mode cannot be used in Player League Mode.", 255, 0, 0)
            return
        end
        local t1 = guiGetText(t1_field); local t2 = guiGetText(t2_field)
        local c1 = guiGetText(t1c_field); local c2 = guiGetText(t2c_field)
        local rounds = tonumber(guiGetText(ct_field)) or 10
        local r1, g1, b1 = hexToRGB(c1); local r2, g2, b2 = hexToRGB(c2)
        local bLim = guiGetText(ban_limit_field)
        local pLim = guiGetText(pick_limit_field)
        triggerServerEvent("onRequestStartCaptainsCup", localPlayer, t1, t2, r1, g1, b1, r2, g2, b2, rounds, bLim, pLim)
    end, false)

    local btn_cc_maps = guiCreateButton(230, 140, 200, 40, "Manage CC Maps", false, tab_cc)
    addEventHandler("onClientGUIClick", btn_cc_maps, function()
        triggerServerEvent("onRequestCCMaps", localPlayer)
    end, false)

    local btn_close = guiCreateButton(10, 365, 630, 25, "Close Panel", false, a_window)
    addEventHandler("onClientGUIClick", btn_close, function()
        guiSetVisible(a_window, false)
        if adminWindow and isElement(adminWindow) then guiSetVisible(adminWindow, false) end
        
        -- Restore cursor only if CC Draft panel isn't currently needing it
        local newCursorState = isPanelVisible or (isElement(c_window) and guiGetVisible(c_window))
        showCursor(newCursorState)
    end, false)
    guiSetVisible(a_window, false)
end

function toggleGUI()
    if isElement(c_window) then
        local vis = not guiGetVisible(c_window)
        guiSetVisible(c_window, vis)
        showCursor(vis or (isElement(a_window) and guiGetVisible(a_window)) or isPanelVisible)
        if vis then guiSetInputMode("no_binds_when_editing") end
    end
end
bindKey('F3', 'down', toggleGUI)

function toggleAdminGUI() 
    local mainVis = isElement(a_window) and guiGetVisible(a_window)
    local ccVis = adminWindow and isElement(adminWindow) and guiGetVisible(adminWindow)
    
    if mainVis or ccVis then
        if isElement(a_window) then guiSetVisible(a_window, false) end
        if isElement(adminWindow) then guiSetVisible(adminWindow, false) end
        
        -- Evaluate proper cursor state to leave behind
        local newCursorState = isPanelVisible or (isElement(c_window) and guiGetVisible(c_window))
        showCursor(newCursorState)
    else
        triggerServerEvent("checkAdminAccess", localPlayer) 
    end
end
bindKey('F2', 'down', toggleAdminGUI)

addEvent("openAdminPanel", true)
addEventHandler("openAdminPanel", root, function(hasAccess)
    isAdmin = hasAccess
    if isAdmin then
        if not isElement(a_window) then createAdminGUI() end
        guiComboBoxClear(cmb_players); guiComboBoxClear(cmb_referee); player_combo_map = {}
        for i, p in ipairs(getElementsByType("player")) do
            local name = getPlayerName(p); local cleanName = name:gsub("#%x%x%x%x%x%x", "")
            local row = guiComboBoxAddItem(cmb_players, cleanName); local row2 = guiComboBoxAddItem(cmb_referee, cleanName)
            player_combo_map[row] = name
        end
        
        guiSetVisible(a_window, true)
        showCursor(true)
        guiSetInputMode("no_binds_when_editing")
        updateAdminFields()
    else 
        outputChatBox("[RL] You are not logged in as Admin/Referee.", 255, 0, 0) 
    end
end)

function updateAdminFields()
    if isElement(teams[1]) and t1_field then
        guiSetText(t1_field, getTeamName(teams[1])); guiSetText(t1c_field, rgbToHex(getTeamColor(teams[1])))
        if isElement(teams[2]) then
            guiSetText(t2_field, getTeamName(teams[2])); guiSetText(t2c_field, rgbToHex(getTeamColor(teams[2])))
            guiSetText(t2cur_field, tostring(getElementData(teams[2], 'Score') or 0))
        end
        guiSetText(t1cur_field, tostring(getElementData(teams[1], 'Score') or 0))
        guiSetText(cr_field, tostring(c_round)); guiSetText(ct_field, tostring(m_round))
    end
end

function requestStartWar(isForce)
    local t1 = guiGetText(t1_field); local t2 = guiGetText(t2_field)
    local c1 = guiGetText(t1c_field); local c2 = guiGetText(t2c_field)
    local league = guiCheckBoxGetSelected(chk_league)
    local rounds = tonumber(guiGetText(ct_field)) or 10
    local r1, g1, b1 = hexToRGB(c1); local r2, g2, b2 = hexToRGB(c2)
    triggerServerEvent("requestStartWar", localPlayer, t1, t2, r1, g1, b1, r2, g2, b2, league, rounds, isForce)
end

function requestUpdateScore()
    local t1s = guiGetText(t1cur_field); local t2s = guiGetText(t2cur_field)
    local cr = guiGetText(cr_field); local mr = guiGetText(ct_field)
    serverCall("adminUpdateScores", t1s, t2s, cr, mr)
end

addEvent("updateClientData", true)
addEventHandler("updateClientData", root, function(t1, t2, t3, cr, mr, fr, league, leagueTimerRemaining, techPauseFlag)
    teams[1] = t1; teams[2] = t2; teams[3] = t3; c_round = cr; m_round = mr; f_round = fr; isLeagueMode = league; isTechPause = techPauseFlag
    leagueWarmupEndTime = (leagueTimerRemaining and leagueTimerRemaining > 0) and (getTickCount() + leagueTimerRemaining) or 0
    
    -- Lock CC panel if match goes live
    if isDraftFinished and isPanelVisible then
        local isSpectator = (getPlayerTeam(localPlayer) == teams[3])
        local myName = removeHex(getPlayerName(localPlayer))
        local isCap = (myName == (captains.Captain1 or "") or myName == (captains.Captain2 or ""))
        
        if not isSpectator and isCap and not f_round then
            isPanelVisible = false
            guiSetVisible(tabela, false)
            local newCursorState = (isElement(a_window) and guiGetVisible(a_window)) or (isElement(c_window) and guiGetVisible(c_window))
            showCursor(newCursorState)
            stopMusic()
            outputChatBox("[CC] Match is live! The map panel has been locked.", 255, 150, 0)
        end
    end
end)

addEventHandler('onClientResourceStart', resourceRoot, function() triggerServerEvent("onClientJoinGame", localPlayer) end)

addEvent("receiveMapList", true)
addEventHandler("receiveMapList", resourceRoot, function(mapTable)
    if isElement(map_grid) then
        guiGridListClear(map_grid)
        for _, mapName in ipairs(mapTable) do
            local row = guiGridListAddRow(map_grid)
            guiGridListSetItemText(map_grid, row, 1, mapName, false, false)
        end
    end
end)

function addMapToQueue()
    local row = guiGridListGetSelectedItem(map_grid)
    if row ~= -1 then
        local mapName = guiGridListGetItemText(map_grid, row, 1)
        local qRow = guiGridListAddRow(queue_grid); guiGridListSetItemText(queue_grid, qRow, 1, mapName, false, false)
        serverCall("addMapToQueue", mapName)
    end
end

function removeMapFromQueue()
    local row = guiGridListGetSelectedItem(queue_grid)
    if row ~= -1 then
        local mapName = guiGridListGetItemText(queue_grid, row, 1)
        guiGridListRemoveRow(queue_grid, row)
        serverCall("removeMapFromQueue", mapName)
    end
end

addEvent("syncMapQueue", true)
addEventHandler("syncMapQueue", resourceRoot, function(q)
    if isElement(queue_grid) then
        guiGridListClear(queue_grid)
        for _, mapName in ipairs(q) do
            local qRow = guiGridListAddRow(queue_grid); guiGridListSetItemText(queue_grid, qRow, 1, mapName, false, false)
        end
    end
end)

addEvent('onSpectateRequest', true)
addEventHandler('onSpectateRequest', root, function()
    if Spectate and Spectate.start then Spectate.start('auto') else executeCommandHandler("spectate") end
end)


---------------------------------------------------------
-- CAPTAINS CUP MODE INTEGRATION (CC26)
---------------------------------------------------------
local tabela, MapScrollPane, categoryGrids = nil, nil, {}
local Team1Grid, Team2Grid, Captain1Grid, Captain2Grid, BanTeam1, BanTeam2, PickTeam1, PickTeam2
local Przycisk, BackgroundImage, TimerGrid, ExtraImage
local currentTurnData = {}
local ccMapsClient = {}
local ccTeamsClient = {}
local captains = {}
local banList = {}
local pickList = {}
isPanelVisible = false 
local canOpenCCPanel = false
local isDraftFinished = false
local sound = nil
local timeLeft = 0
local clientTimer = nil
local ccReadyStatusClient = { Team1 = false, Team2 = false }
local isWaitingForReady = false

local screenX, screenY = guiGetScreenSize()
local scale = math.min(screenX / 1920, screenY / 1080) * 0.9
local pickSound, banSound, timeoutSound

-- Admin GUI Variables
adminWindow = nil
local mapTabPanel, tabMaps, tabCategories
local searchEdit, unassignedGrid, catCombo, assignedGrid, btnAddMap, btnRemMap
local catListGrid, editCatName, btnAddCat, btnRenCat, btnDelCat
local cachedServerMaps = {}

function removeHex(text)
    if type(text) == "string" then return string.gsub(text, "#%x%x%x%x%x%x", "") end
    return text
end

local function startMusic() if not sound then sound = playSound("background_music.mp3", true); if sound then setSoundVolume(sound, 0.5) end end end
local function stopMusic() if sound then stopSound(sound); sound = nil end end

local function updateTimerDisplay()
    if not isElement(TimerGrid) then return end
    guiGridListClear(TimerGrid)
    local row = guiGridListAddRow(TimerGrid)
    if isWaitingForReady then
        guiGridListSetItemText(TimerGrid, row, 1, "WAITING FOR CAPTAINS TO READY UP...", false, false)
        guiGridListSetItemColor(TimerGrid, row, 1, 255, 255, 0)
    elseif timeLeft >= 0 then
        local captainName = currentTurnData.captain and removeHex(getPlayerName(currentTurnData.captain)) or "Unknown"
        local action = currentTurnData.action or "Waiting"
        guiGridListSetItemText(TimerGrid, row, 1, "Turn: " .. captainName .. " - " .. action:upper() .. " - Time Left: " .. string.format("%02d", timeLeft), false, false)
    else guiGridListSetItemText(TimerGrid, row, 1, "Waiting for Start...", false, false) end
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    local winW, winH = 1920 * scale, 1080 * scale
    local winX, winY = (screenX - winW) / 2, (screenY - winH) / 2
    tabela = guiCreateWindow(winX, winY, winW, winH, "Captain Mode 1.0 | Press H to Hide/Show Panel", false)
    guiWindowSetSizable(tabela, false)

    BackgroundImage = guiCreateStaticImage(682 * scale, 564 * scale, 590 * scale, 455 * scale, "background.png", false, tabela)
    MapScrollPane = guiCreateScrollPane(9 * scale, 24 * scale, 670 * scale, 1000 * scale, false, tabela)

    Team1Grid = guiCreateGridList(1275 * scale, 25 * scale, 315 * scale, 182 * scale, false, tabela); guiGridListAddColumn(Team1Grid, "Team 1", 0.9)
    Team2Grid = guiCreateGridList(1595 * scale, 25 * scale, 315 * scale, 182 * scale, false, tabela); guiGridListAddColumn(Team2Grid, "Team 2", 0.9)
    Captain1Grid = guiCreateGridList(1275 * scale, 210 * scale, 315 * scale, 182 * scale, false, tabela); guiGridListAddColumn(Captain1Grid, "Captain 1", 0.9)
    Captain2Grid = guiCreateGridList(1598 * scale, 210 * scale, 312 * scale, 182 * scale, false, tabela); guiGridListAddColumn(Captain2Grid, "Captain 2", 0.9)
    BanTeam1 = guiCreateGridList(1275 * scale, 400 * scale, 314 * scale, 295 * scale, false, tabela); guiGridListAddColumn(BanTeam1, "Team 1 Bans", 0.9)
    BanTeam2 = guiCreateGridList(1598 * scale, 400 * scale, 314 * scale, 295 * scale, false, tabela); guiGridListAddColumn(BanTeam2, "Team 2 Bans", 0.9)
    PickTeam1 = guiCreateGridList(1275 * scale, 700 * scale, 314 * scale, 322 * scale, false, tabela); guiGridListAddColumn(PickTeam1, "Team 1 Picks", 0.9)
    PickTeam2 = guiCreateGridList(1596 * scale, 700 * scale, 314 * scale, 322 * scale, false, tabela); guiGridListAddColumn(PickTeam2, "Team 2 Picks", 0.9)

    Przycisk = guiCreateButton(682 * scale, 442 * scale, 590 * scale, 118 * scale, "BAN/PICK", false, tabela)
    TimerGrid = guiCreateGridList(682 * scale, 24 * scale, 590 * scale, 60 * scale, false, tabela); guiGridListAddColumn(TimerGrid, "Turn Info", 0.9)
    ExtraImage = guiCreateStaticImage(682 * scale, 88 * scale, 590 * scale, 350 * scale, "extra_image.png", false, tabela)
    guiSetVisible(tabela, isPanelVisible)

    addEventHandler("onClientGUIClick", Przycisk, function(button, state)
        if button == "left" and state == "up" then
            if isWaitingForReady then triggerServerEvent("onClientRequestReady", localPlayer); return end
            if not currentTurnData.captain then outputChatBox("[CC] Ban/Pick process hasn't started yet!", 255, 0, 0); return end
            if localPlayer == currentTurnData.captain then
                local selectedCount = 0
                for _, data in ipairs(categoryGrids) do if guiGridListGetSelectedItem(data.grid) ~= -1 then selectedCount = selectedCount + 1 end end
                if selectedCount > 1 then outputChatBox("[CC] Please select only one map!", 255, 0, 0); return end

                local selectedMap, gridList = getSelectedMap()
                if selectedMap then
                    local isAlreadyUsed = false
                    for _, ban in ipairs(banList.BanTeam1 or {}) do if ban == selectedMap then isAlreadyUsed = true break end end
                    for _, ban in ipairs(banList.BanTeam2 or {}) do if ban == selectedMap then isAlreadyUsed = true break end end
                    for _, pick in ipairs(pickList.PickTeam1 or {}) do if pick == selectedMap then isAlreadyUsed = true break end end
                    for _, pick in ipairs(pickList.PickTeam2 or {}) do if pick == selectedMap then isAlreadyUsed = true break end end
                    if isAlreadyUsed then outputChatBox("[CC] This map has already been used!", 255, 0, 0); return end
                    
                    -- Let the server validate and broadcast the update. No more local deletion here!
                    triggerServerEvent("onBanPick", localPlayer, currentTurnData.action, selectedMap)
                else outputChatBox("[CC] Please select a map from the list!", 255, 0, 0) end
            else
                local captainName = currentTurnData.captain and removeHex(getPlayerName(currentTurnData.captain)) or "Unknown"
                outputChatBox("[CC] It's not your turn! Expected captain: " .. captainName, 255, 0, 0)
            end
        end
    end, false)

    bindKey("h", "down", function()
        if not canOpenCCPanel or isChatBoxInputActive() then return end
        
        if isDraftFinished then
            local isSpectator = (getPlayerTeam(localPlayer) == teams[3])
            local myName = removeHex(getPlayerName(localPlayer))
            local isCap = (myName == (captains.Captain1 or "") or myName == (captains.Captain2 or ""))
            local isWarmup = f_round 
            
            if not isSpectator then
                if not isCap then 
                    outputChatBox("[CC] Only Captains and Spectators can view the panel after the draft.", 255, 0, 0)
                    return 
                end
                if not isWarmup then 
                    outputChatBox("[CC] The map panel is locked during a live match. Wait for warmup!", 255, 0, 0)
                    return 
                end
            end
        end

        isPanelVisible = not isPanelVisible
        guiSetVisible(tabela, isPanelVisible)
        
        local newCursorState = isPanelVisible or (isElement(c_window) and guiGetVisible(c_window)) or (isElement(a_window) and guiGetVisible(a_window))
        showCursor(newCursorState)
        
        if isPanelVisible then startMusic() else stopMusic() end
    end)
    initAdminGUI()
end)

addEvent("onCCProcessStart", true)
addEventHandler("onCCProcessStart", resourceRoot, function()
    canOpenCCPanel = true
    isDraftFinished = false
    isPanelVisible = true
    guiSetVisible(tabela, true); showCursor(true)
    startMusic()
end)

addEvent("onCCProcessEnd", true)
addEventHandler("onCCProcessEnd", resourceRoot, function(forceClose)
    if forceClose then
        canOpenCCPanel = false
        isDraftFinished = false
        isPanelVisible = false
        guiSetVisible(tabela, false)
        local newCursorState = (isElement(a_window) and guiGetVisible(a_window)) or (isElement(c_window) and guiGetVisible(c_window))
        showCursor(newCursorState)
        stopMusic()
    else
        -- Draft ended normally: Hide panel but let them re-open it via H to inspect maps
        isDraftFinished = true
        isPanelVisible = false
        guiSetVisible(tabela, false)
        local newCursorState = (isElement(a_window) and guiGetVisible(a_window)) or (isElement(c_window) and guiGetVisible(c_window))
        showCursor(newCursorState)
        stopMusic()
        
        -- Update the UI to reflect completion state when they reopen it
        guiSetText(Przycisk, "DRAFT COMPLETE")
        if isTimer(clientTimer) then killTimer(clientTimer) end
        clientTimer = nil
        guiGridListClear(TimerGrid)
        local row = guiGridListAddRow(TimerGrid)
        guiGridListSetItemText(TimerGrid, row, 1, "DRAFT COMPLETE - MAPS QUEUED", false, false)
    end
end)

function getSelectedMap()
    for _, data in ipairs(categoryGrids) do
        local row = guiGridListGetSelectedItem(data.grid)
        if row ~= -1 then return guiGridListGetItemText(data.grid, row, 1), data.grid end
    end
    return nil, nil
end

addEvent("onSyncData", true)
addEventHandler("onSyncData", resourceRoot, function(syncedTeams, syncedCaptains, syncedMaps, syncedBanList, syncedPickList, turnData, status, waiting)
    ccTeamsClient = syncedTeams; captains = syncedCaptains; ccMapsClient = syncedMaps
    banList = syncedBanList; pickList = syncedPickList; currentTurnData = turnData or {}
    ccReadyStatusClient = status or {Team1=false, Team2=false}; isWaitingForReady = waiting
    
    updateCCGUI()
    if not turnData and not isWaitingForReady then
        timeLeft = 0
        if isTimer(clientTimer) then killTimer(clientTimer) end
        clientTimer = nil
    end
    updateTimerDisplay()
end)

addEvent("onTurnTimerStart", true)
addEventHandler("onTurnTimerStart", resourceRoot, function(seconds, turnData)
    timeLeft = seconds; currentTurnData = turnData
    if isTimer(clientTimer) then killTimer(clientTimer) end
    clientTimer = nil
    clientTimer = setTimer(function()
        timeLeft = timeLeft - 1; updateTimerDisplay()
        if timeLeft < 0 and isTimer(clientTimer) then killTimer(clientTimer); clientTimer = nil end
    end, 1000, 0)
    updateTimerDisplay()
end)

addEvent("onPickSound", true); addEventHandler("onPickSound", resourceRoot, function() pickSound = playSound("pick_sound.mp3") end)
addEvent("onBanSound", true); addEventHandler("onBanSound", resourceRoot, function() banSound = playSound("ban_sound.mp3") end)
addEvent("onTurnTimeoutSound", true); addEventHandler("onTurnTimeoutSound", resourceRoot, function() timeoutSound = playSound("timeout_sound.mp3") end)

function updateCCGUI()
    for _, data in ipairs(categoryGrids) do if isElement(data.grid) then destroyElement(data.grid) end end
    categoryGrids = {}

    local i = 0
    for category, mapPool in pairs(ccMapsClient) do
        local col = i % 2; local row = math.floor(i / 2)
        local gridX = col * (330 * scale + 10 * scale); local gridY = row * (327 * scale + 10 * scale)
        local grid = guiCreateGridList(gridX, gridY, 330 * scale, 327 * scale, false, MapScrollPane)
        guiGridListAddColumn(grid, category, 0.9)
        for _, map in ipairs(mapPool) do guiGridListAddRow(grid, map) end
        table.insert(categoryGrids, {grid = grid, category = category}); i = i + 1
    end

    guiGridListClear(Team1Grid); guiGridListClear(Team2Grid); guiGridListClear(Captain1Grid); guiGridListClear(Captain2Grid)
    guiGridListClear(BanTeam1); guiGridListClear(BanTeam2); guiGridListClear(PickTeam1); guiGridListClear(PickTeam2)

    guiGridListAddRow(Team1Grid, ccTeamsClient.Team1 or "Not Set"); guiGridListAddRow(Team2Grid, ccTeamsClient.Team2 or "Not Set")
    
    local c1Name = captains.Captain1 or "Not Set"
    if ccReadyStatusClient.Team1 then c1Name = c1Name .. " [READY]" end
    local row1 = guiGridListAddRow(Captain1Grid, c1Name)
    if ccReadyStatusClient.Team1 then guiGridListSetItemColor(Captain1Grid, row1, 1, 0, 255, 0) end

    local c2Name = captains.Captain2 or "Not Set"
    if ccReadyStatusClient.Team2 then c2Name = c2Name .. " [READY]" end
    local row2 = guiGridListAddRow(Captain2Grid, c2Name)
    if ccReadyStatusClient.Team2 then guiGridListSetItemColor(Captain2Grid, row2, 1, 0, 255, 0) end

    for _, ban in ipairs(banList.BanTeam1 or {}) do 
        local r = guiGridListAddRow(BanTeam1, ban)
        guiGridListSetItemColor(BanTeam1, r, 1, 255, 0, 0)
    end
    for _, ban in ipairs(banList.BanTeam2 or {}) do 
        local r = guiGridListAddRow(BanTeam2, ban)
        guiGridListSetItemColor(BanTeam2, r, 1, 255, 0, 0)
    end
    for _, pick in ipairs(pickList.PickTeam1 or {}) do 
        local r = guiGridListAddRow(PickTeam1, pick)
        guiGridListSetItemColor(PickTeam1, r, 1, 0, 255, 0)
    end
    for _, pick in ipairs(pickList.PickTeam2 or {}) do 
        local r = guiGridListAddRow(PickTeam2, pick)
        guiGridListSetItemColor(PickTeam2, r, 1, 0, 255, 0)
    end
    
    if isWaitingForReady then guiSetText(Przycisk, "CLICK TO READY") 
    elseif currentTurnData and currentTurnData.action then guiSetText(Przycisk, "BAN/PICK") end
end

function initAdminGUI()
    local w, h = 600, 450
    local x, y = (screenX - w) / 2, (screenY - h) / 2
    adminWindow = guiCreateWindow(x, y, w, h, "Captain Mode - Map Management Panel", false)
    guiWindowSetSizable(adminWindow, false); guiSetVisible(adminWindow, false)
    
    mapTabPanel = guiCreateTabPanel(10, 25, w - 20, h - 65, false, adminWindow)
    
    tabMaps = guiCreateTab("Map Queue", mapTabPanel)
    guiCreateLabel(10, 10, 150, 15, "Search map:", false, tabMaps)
    searchEdit = guiCreateEdit(10, 25, 200, 25, "", false, tabMaps)
    addEventHandler("onClientGUIFocus", searchEdit, function() guiSetInputMode("no_binds_when_editing") end, false)
    
    guiCreateLabel(10, 55, 200, 15, "Unassigned server maps:", false, tabMaps)
    unassignedGrid = guiCreateGridList(10, 70, 200, 280, false, tabMaps); guiGridListAddColumn(unassignedGrid, "Map Name", 0.9)
    guiCreateLabel(220, 55, 140, 15, "Select category:", false, tabMaps)
    catCombo = guiCreateGridList(220, 70, 140, 150, false, tabMaps); guiGridListAddColumn(catCombo, "Category", 0.9)
    btnAddMap = guiCreateButton(220, 230, 140, 30, "Add to Cat. ->", false, tabMaps)
    btnRemMap = guiCreateButton(220, 270, 140, 30, "<- Remove from Cat.", false, tabMaps)
    guiCreateLabel(370, 55, 200, 15, "Maps in selected category:", false, tabMaps)
    assignedGrid = guiCreateGridList(370, 70, 200, 280, false, tabMaps); guiGridListAddColumn(assignedGrid, "Map Name", 0.9)
    
    tabCategories = guiCreateTab("Categories", mapTabPanel)
    guiCreateLabel(10, 10, 200, 15, "Manage Categories:", false, tabCategories)
    catListGrid = guiCreateGridList(10, 30, 250, 310, false, tabCategories); guiGridListAddColumn(catListGrid, "Category Name", 0.9)
    editCatName = guiCreateEdit(280, 30, 200, 30, "", false, tabCategories)
    addEventHandler("onClientGUIFocus", editCatName, function() guiSetInputMode("no_binds_when_editing") end, false)

    btnAddCat = guiCreateButton(280, 70, 200, 30, "Add New", false, tabCategories)
    btnRenCat = guiCreateButton(280, 110, 200, 30, "Rename", false, tabCategories)
    btnDelCat = guiCreateButton(280, 150, 200, 30, "Delete Selected", false, tabCategories)

    local btnClose = guiCreateButton(10, h - 35, w - 20, 25, "Close Panel", false, adminWindow)
    addEventHandler("onClientGUIClick", btnClose, function()
        guiSetVisible(adminWindow, false)
        local newCursorState = isPanelVisible or (isElement(c_window) and guiGetVisible(c_window)) or (isElement(a_window) and guiGetVisible(a_window))
        showCursor(newCursorState)
    end, false)

    addEventHandler("onClientGUIChanged", searchEdit, refreshAdminLists, false)
    addEventHandler("onClientGUIClick", catCombo, function() refreshAdminLists() end, false)
    addEventHandler("onClientGUIClick", catListGrid, function()
        local r = guiGridListGetSelectedItem(catListGrid)
        if r ~= -1 then guiSetText(editCatName, guiGridListGetItemText(catListGrid, r, 1)) end
    end, false)
    
    addEventHandler("onClientGUIClick", btnAddMap, function()
        local cRow = guiGridListGetSelectedItem(catCombo); local mRow = guiGridListGetSelectedItem(unassignedGrid)
        if cRow ~= -1 and mRow ~= -1 then triggerServerEvent("cc:adminAction", resourceRoot, "addMap", guiGridListGetItemText(catCombo, cRow, 1), guiGridListGetItemText(unassignedGrid, mRow, 1)) end
    end, false)
    
    addEventHandler("onClientGUIClick", btnRemMap, function()
        local cRow = guiGridListGetSelectedItem(catCombo); local mRow = guiGridListGetSelectedItem(assignedGrid)
        if cRow ~= -1 and mRow ~= -1 then triggerServerEvent("cc:adminAction", resourceRoot, "remMap", guiGridListGetItemText(catCombo, cRow, 1), guiGridListGetItemText(assignedGrid, mRow, 1)) end
    end, false)
    
    addEventHandler("onClientGUIClick", btnAddCat, function() local name = guiGetText(editCatName); if name ~= "" then triggerServerEvent("cc:adminAction", resourceRoot, "addCat", name) end end, false)
    addEventHandler("onClientGUIClick", btnRenCat, function()
        local old = guiGridListGetItemText(catListGrid, guiGridListGetSelectedItem(catListGrid), 1)
        local new = guiGetText(editCatName)
        if old and old ~= "" and new ~= "" then triggerServerEvent("cc:adminAction", resourceRoot, "renCat", old, new) end
    end, false)
    addEventHandler("onClientGUIClick", btnDelCat, function()
        local name = guiGridListGetItemText(catListGrid, guiGridListGetSelectedItem(catListGrid), 1)
        if name and name ~= "" then triggerServerEvent("cc:adminAction", resourceRoot, "delCat", name) end
    end, false)
end

function refreshAdminLists()
    local unassignedScroll = guiGridListGetVerticalScrollPosition(unassignedGrid) or 0
    local assignedScroll = guiGridListGetVerticalScrollPosition(assignedGrid) or 0

    local filter = string.lower(guiGetText(searchEdit))
    local selCatRow = guiGridListGetSelectedItem(catCombo)
    local selectedCategory = selCatRow ~= -1 and guiGridListGetItemText(catCombo, selCatRow, 1) or nil
    
    guiGridListClear(catCombo); guiGridListClear(catListGrid)
    local usedMaps = {}
    for catName, mapArray in pairs(ccMapsClient) do
        local r1 = guiGridListAddRow(catCombo, catName)
        if catName == selectedCategory then guiGridListSetSelectedItem(catCombo, r1, 1) end
        guiGridListAddRow(catListGrid, catName)
        for _, m in ipairs(mapArray) do usedMaps[m] = true end
    end
    
    guiGridListClear(unassignedGrid)
    for _, mapName in ipairs(cachedServerMaps) do
        if not usedMaps[mapName] and (filter == "" or string.find(string.lower(mapName), filter, 1, true)) then guiGridListAddRow(unassignedGrid, mapName) end
    end
    
    guiGridListClear(assignedGrid)
    if selectedCategory and ccMapsClient[selectedCategory] then
        for _, mapName in ipairs(ccMapsClient[selectedCategory]) do guiGridListAddRow(assignedGrid, mapName) end
    end

    -- Slight timer ensures list heights correctly digest items before scrolling down.
    setTimer(function()
        if isElement(unassignedGrid) then guiGridListSetVerticalScrollPosition(unassignedGrid, unassignedScroll) end
        if isElement(assignedGrid) then guiGridListSetVerticalScrollPosition(assignedGrid, assignedScroll) end
    end, 50, 1)
end

addEvent("cc:openAdminGUI", true)
addEventHandler("cc:openAdminGUI", resourceRoot, function(serverMaps, currentMaps)
    cachedServerMaps = serverMaps; ccMapsClient = currentMaps
    guiSetVisible(adminWindow, true); guiBringToFront(adminWindow)
    guiSetInputMode("no_binds_when_editing")
    showCursor(true); refreshAdminLists()
end)

addEvent("cc:refreshAdminGUI", true)
addEventHandler("cc:refreshAdminGUI", resourceRoot, function(serverMaps, currentMaps)
    cachedServerMaps = serverMaps; ccMapsClient = currentMaps
    if guiGetVisible(adminWindow) then refreshAdminLists() end
end)