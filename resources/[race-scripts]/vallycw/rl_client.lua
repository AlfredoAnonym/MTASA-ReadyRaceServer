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

-----------------
-- Call functions
-----------------
function serverCall(funcname, ...)
    triggerServerEvent("onClientCallsServerFunction", resourceRoot, funcname, ...)
end

addEvent("onServerCallsClientFunction", true)
addEventHandler("onServerCallsClientFunction", resourceRoot, function(funcname, ...)
    if _G[funcname] then
        _G[funcname](...)
    end
end)

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
        
        -- Configurable Box Parameters
        local boxWidth = 220 
        local startX = s_x - boxWidth - 20
        local centerX = startX + (boxWidth / 2)
        local baseY = 250 
        
        if not f_round then
            local hudHeight = 110 -- Tighter default height for Classic mode
            local textY = baseY + 25 
            
            local ranked = {}
            if isLeagueMode then
                local players = getElementsByType("player")
                for i, p in ipairs(players) do
                    if getPlayerTeam(p) == teams[1] then
                        table.insert(ranked, p)
                    end
                end
                table.sort(ranked, function(a,b) 
                    return (tonumber(getElementData(a, "Score") or 0) > tonumber(getElementData(b, "Score") or 0)) 
                end)
                
                local playerCount = math.min(5, #ranked)
                hudHeight = 45 + (playerCount * 20)
                if playerCount == 0 then hudHeight = 45 end
                
                textY = baseY + 20 
            end

            -- Background
            dxDrawRectangle(startX, baseY, boxWidth, hudHeight, tocolor(0, 0, 0, 160))
            
            if c_round == m_round then
                dxDrawText('FINAL ROUND', centerX, textY, centerX, textY, tocolor(255, 255, 0, 255), 1.2, "default-bold", 'center', 'center')
            else
                dxDrawText('Round ' ..c_round.. ' of ' ..m_round, centerX, textY, centerX, textY, tocolor(255, 255, 150, 255), 1.2, "default-bold", 'center', 'center')
            end
            
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
                local r1, g1, b1 = getTeamColor(teams[1])
                local r2, g2, b2 = getTeamColor(teams[2])
                local t1s = tonumber(getElementData(teams[1], 'Score')) or 0
                local t2s = tonumber(getElementData(teams[2], 'Score')) or 0

                local t1n = getTeamName(teams[1])
                local t2n = getTeamName(teams[2])
                if #t1n > 15 then t1n = string.sub(t1n, 1, 13)..".." end
                if #t2n > 15 then t2n = string.sub(t2n, 1, 13)..".." end
                
                local t1Y = textY + 30
                local t2Y = textY + 60

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
                else
                    dxDrawText('Wait for Ready', centerX, warmTextY+25, centerX, warmTextY+25, tocolor(200, 200, 200, 255), 1.0, "default-bold", 'center', 'center')
                end
            end
        end
    end
end
addEventHandler('onClientRender', root, updateDisplay)

function toggleClanwarHUD()
    isHudVisible = not isHudVisible
end
bindKey("F1", "down", toggleClanwarHUD)

------------------------
-- GUI: TEAM SELECTION
------------------------
function createGUI(team1, team2, _isLeague) 
    if isElement(c_window) then destroyElement(c_window) end
    
    if _isLeague ~= nil then
        isLeagueMode = _isLeague
    end

    c_window = guiCreateWindow(s_x/2-150, s_y/2-75, 300, 160, 'Race League Selection', false)
    guiWindowSetMovable(c_window, false)
    guiWindowSetSizable(c_window, false)
    
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
    addEventHandler("onClientGUIClick", t3_button, function() 
        if isElement(teams[3]) then
            selectTeam(teams[3]) 
        else
            selectTeam(3) 
        end
    end, false)
    
    showCursor(true)
    guiSetInputMode("no_binds_when_editing")
end
addEvent("createGUI", true)
addEventHandler("createGUI", root, createGUI)

function selectTeam(teamInput)
    local teamElem = teamInput
    
    if type(teamInput) == "number" then
        if teams[teamInput] then
            teamElem = teams[teamInput]
        end
    end

    if isElement(teamElem) then
        triggerServerEvent("onPlayerRequestTeam", localPlayer, teamElem)
        if isElement(c_window) then guiSetVisible(c_window, false) end
        showCursor(false)
        
        if getTeamName(teamElem) == "Spectators" then
            triggerEvent("onSpectateRequest", localPlayer)
        end
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

    -- BUTTONS
    local btn_start = guiCreateButton(10, 130, 140, 35, "START / APPLY", false, tab_gen)
    addEventHandler("onClientGUIClick", btn_start, function() requestStartWar(false) end, false)

    local btn_stop = guiCreateButton(160, 130, 140, 35, "Stop Match", false, tab_gen)
    addEventHandler("onClientGUIClick", btn_stop, function() serverCall('destroyTeams', localPlayer) end, false)

    local btn_end = guiCreateButton(310, 130, 140, 35, "Force End", false, tab_gen)
    addEventHandler("onClientGUIClick", btn_end, function() serverCall('forceEndMatch') end, false)

    local btn_fstart = guiCreateButton(460, 130, 140, 35, "Force Start", false, tab_gen)
    addEventHandler("onClientGUIClick", btn_fstart, function()
        if isElement(teams[1]) then
            serverCall('forceStartMatch')
        else
            requestStartWar(true)
        end
    end, false)

    -- PERSONNEL
    guiCreateLabel(10, 180, 150, 20, "Select Referee:", false, tab_gen)
    cmb_referee = guiCreateComboBox(10, 200, 180, 300, "Select Referee", false, tab_gen)
    
    local btn_ref = guiCreateButton(200, 200, 80, 25, "Set Ref", false, tab_gen)
    addEventHandler("onClientGUIClick", btn_ref, function() 
        local row = guiComboBoxGetSelected(cmb_referee)
        if row ~= -1 then
            local name = player_combo_map[row]
            if name then serverCall('setReferee', name) end
        end
    end, false)

    -- CAPTAINS
    guiCreateLabel(310, 175, 150, 20, "Select Captains:", false, tab_gen)
    cmb_players = guiCreateComboBox(310, 195, 180, 300, "Select Player", false, tab_gen)
    
    local btn_set_c1 = guiCreateButton(500, 195, 60, 25, "Set T1", false, tab_gen)
    local btn_set_c2 = guiCreateButton(570, 195, 60, 25, "Set T2", false, tab_gen)
    
    lbl_cap1 = guiCreateLabel(310, 230, 140, 20, "T1: None", false, tab_gen)
    lbl_cap2 = guiCreateLabel(500, 230, 140, 20, "T2: None", false, tab_gen)
    
    local btn_rem_cap = guiCreateButton(310, 255, 320, 25, "Remove Captains", false, tab_gen)

    addEventHandler("onClientGUIClick", btn_set_c1, function()
        if guiCheckBoxGetSelected(chk_league) then
            outputChatBox("[RL] Error: Captains are disabled in Player League mode.", 255, 0, 0)
            return
        end
        local row = guiComboBoxGetSelected(cmb_players)
        if row ~= -1 then
            local selected = player_combo_map[row]
            if selected then
                selected_cap1 = selected
                guiSetText(lbl_cap1, "T1: " .. (selected:gsub("#%x%x%x%x%x%x", "")))
                serverCall('setCaptains', selected_cap1, selected_cap2)
            end
        end
    end, false)

    addEventHandler("onClientGUIClick", btn_set_c2, function()
        if guiCheckBoxGetSelected(chk_league) then
            outputChatBox("[RL] Error: Captains are disabled in Player League mode.", 255, 0, 0)
            return
        end
        local row = guiComboBoxGetSelected(cmb_players)
        if row ~= -1 then
            local selected = player_combo_map[row]
            if selected then
                selected_cap2 = selected
                guiSetText(lbl_cap2, "T2: " .. (selected:gsub("#%x%x%x%x%x%x", "")))
                serverCall('setCaptains', selected_cap1, selected_cap2)
            end
        end
    end, false)

    addEventHandler("onClientGUIClick", btn_rem_cap, function()
        selected_cap1 = ""
        selected_cap2 = ""
        guiSetText(lbl_cap1, "T1: None")
        guiSetText(lbl_cap2, "T2: None")
        serverCall('setCaptains', "", "")
    end, false)

    -- === TAB 2: SCORE/ROUNDS ===
    local tab_scr = guiCreateTab('Score', tab_panel)
    guiCreateLabel(20, 20, 400, 20, "Edit Scores manually (Will announce in chat):", false, tab_scr)
    
    guiCreateLabel(20, 60, 60, 20, "T1 Score:", false, tab_scr)
    t1cur_field = guiCreateEdit(90, 60, 80, 30, "0", false, tab_scr)
    
    guiCreateLabel(20, 100, 60, 20, "T2 Score:", false, tab_scr)
    t2cur_field = guiCreateEdit(90, 100, 80, 30, "0", false, tab_scr)
    
    guiCreateLabel(250, 60, 80, 20, "Cur Round:", false, tab_scr)
    cr_field = guiCreateEdit(330, 60, 80, 30, "0", false, tab_scr)
    
    guiCreateLabel(250, 100, 80, 20, "Max Rnds:", false, tab_scr)
    ct_field = guiCreateEdit(330, 100, 80, 30, "10", false, tab_scr)
    
    local btn_upd = guiCreateButton(20, 160, 200, 40, "Update Stats & Announce", false, tab_scr)
    addEventHandler("onClientGUIClick", btn_upd, requestUpdateScore, false)

    -- === TAB 3: MAP QUEUE ===
    local tab_map = guiCreateTab('Map Queue', tab_panel)
    
    map_grid = guiCreateGridList(10, 10, 280, 280, false, tab_map)
    guiGridListAddColumn(map_grid, "Server Maps", 0.9)
    
    queue_grid = guiCreateGridList(350, 10, 280, 280, false, tab_map)
    guiGridListAddColumn(queue_grid, "Match Queue", 0.9)
    
    local btn_add = guiCreateButton(300, 100, 40, 40, "->", false, tab_map)
    local btn_rem = guiCreateButton(300, 150, 40, 40, "<-", false, tab_map)
    
    addEventHandler("onClientGUIClick", btn_add, addMapToQueue, false)
    addEventHandler("onClientGUIClick", btn_rem, removeMapFromQueue, false)
    
    serverCall("requestMapList")

    -- === TAB 4: HELP / COMMANDS ===
    local tab_help = guiCreateTab('Help / Commands', tab_panel)
    local helpText = [[
--- RACE LEAGUE / CLANWAR COMMANDS ---

[CAPTAIN COMMANDS]
/rd - Readys up your team during warmup or between rounds.
/tech - Calls a technical pause. Returns the match to warmup and resets current round.

[ADMIN / REFEREE COMMANDS]
F2 - Opens the Race League / Clanwar Admin Panel.
/forcerd - or /forcestart - Forces both teams to be ready and starts the map.
/playerpts [exact_nickname] [amount] - Sets the points of a specific player manually.
/tech - Admins can force a tech pause at any time (locked 10s after map starts).
/redo - Restarts the map (locked 10s after map starts).
/mvp [nick] [t1/t2/spec] - Moves a player to a specific team (ignores hex colors).

[INFO]
- Clanwar maps will not progress until both captains type /rd.
- Player League mode has an automatic 60-second warmup timer.
- Team colors are applied to race vehicles and reset upon match completion.
]]
    local memo_help = guiCreateMemo(10, 10, 610, 310, helpText, false, tab_help)
    guiMemoSetReadOnly(memo_help, true)

    local btn_close = guiCreateButton(10, 365, 630, 25, "Close Panel", false, a_window)
    addEventHandler("onClientGUIClick", btn_close, function() guiSetVisible(a_window, false) showCursor(false) end, false)
    
    guiSetVisible(a_window, false)
end

------------------------
-- LOGIC
------------------------
function toggleGUI()
    if isElement(c_window) then
        local vis = not guiGetVisible(c_window)
        guiSetVisible(c_window, vis)
        showCursor(vis or (isElement(a_window) and guiGetVisible(a_window)))
        if vis then guiSetInputMode("no_binds_when_editing") end
    end
end
bindKey('F3', 'down', toggleGUI)

function toggleAdminGUI()
    triggerServerEvent("checkAdminAccess", localPlayer)
end
bindKey('F2', 'down', toggleAdminGUI)

addEvent("openAdminPanel", true)
addEventHandler("openAdminPanel", root, function(hasAccess)
    isAdmin = hasAccess
    if isAdmin then
        if not isElement(a_window) then createAdminGUI() end
        
        guiComboBoxClear(cmb_players)
        guiComboBoxClear(cmb_referee)
        player_combo_map = {}
        for i, p in ipairs(getElementsByType("player")) do
            local name = getPlayerName(p)
            local cleanName = name:gsub("#%x%x%x%x%x%x", "")
            local row = guiComboBoxAddItem(cmb_players, cleanName)
            local row2 = guiComboBoxAddItem(cmb_referee, cleanName)
            player_combo_map[row] = name
        end
        
        local vis = not guiGetVisible(a_window)
        guiSetVisible(a_window, vis)
        showCursor(vis)
        
        if vis then 
            guiSetInputMode("no_binds_when_editing")
            updateAdminFields() 
        end
    else
        outputChatBox("[RL] You are not logged in as Admin/Referee.", 255, 0, 0)
    end
end)

function updateAdminFields()
    if isElement(teams[1]) and t1_field then
        guiSetText(t1_field, getTeamName(teams[1]))
        guiSetText(t1c_field, rgbToHex(getTeamColor(teams[1])))
        if isElement(teams[2]) then
            guiSetText(t2_field, getTeamName(teams[2]))
            guiSetText(t2c_field, rgbToHex(getTeamColor(teams[2])))
            guiSetText(t2cur_field, tostring(getElementData(teams[2], 'Score') or 0))
        end
        guiSetText(t1cur_field, tostring(getElementData(teams[1], 'Score') or 0))
        guiSetText(cr_field, tostring(c_round))
        guiSetText(ct_field, tostring(m_round))
    end
end

function requestStartWar(isForce)
    local t1 = guiGetText(t1_field)
    local t2 = guiGetText(t2_field)
    local c1 = guiGetText(t1c_field)
    local c2 = guiGetText(t2c_field)
    local league = guiCheckBoxGetSelected(chk_league)
    local rounds = tonumber(guiGetText(ct_field)) or 10
    local r1, g1, b1 = hexToRGB(c1)
    local r2, g2, b2 = hexToRGB(c2)
    triggerServerEvent("requestStartWar", localPlayer, t1, t2, r1, g1, b1, r2, g2, b2, league, rounds, isForce)
end

function requestUpdateScore()
    local t1s = guiGetText(t1cur_field)
    local t2s = guiGetText(t2cur_field)
    local cr = guiGetText(cr_field)
    local mr = guiGetText(ct_field)
    serverCall("adminUpdateScores", t1s, t2s, cr, mr)
end

-- DATA UPDATES
addEvent("updateClientData", true)
addEventHandler("updateClientData", root, function(t1, t2, t3, cr, mr, fr, league, leagueTimerRemaining, techPauseFlag)
    teams[1] = t1
    teams[2] = t2
    teams[3] = t3
    c_round = cr
    m_round = mr
    f_round = fr
    isLeagueMode = league
    isTechPause = techPauseFlag
    if leagueTimerRemaining and leagueTimerRemaining > 0 then
        leagueWarmupEndTime = getTickCount() + leagueTimerRemaining
    else
        leagueWarmupEndTime = 0
    end
end)

addEventHandler('onClientResourceStart', resourceRoot, function()
    triggerServerEvent("onClientJoinGame", localPlayer)
end)

-- MAP QUEUE
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
        local qRow = guiGridListAddRow(queue_grid)
        guiGridListSetItemText(queue_grid, qRow, 1, mapName, false, false)
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
            local qRow = guiGridListAddRow(queue_grid)
            guiGridListSetItemText(queue_grid, qRow, 1, mapName, false, false)
        end
    end
end)

-- SPECTATE
addEvent('onSpectateRequest', true)
addEventHandler('onSpectateRequest', root, function()
    if Spectate and Spectate.start then
        Spectate.start('auto')
    else
        executeCommandHandler("spectate")
    end
end)