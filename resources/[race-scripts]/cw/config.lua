-- config.lua
Config = {}

-- DEFAULT MATCH SETTINGS
Config.DefaultMode = "Classic" -- Options: "Classic" or "PlayerL"
Config.RoundLimit = 10 

-- DEFAULT TEAM SETTINGS
Config.TeamNames = { 
    [1] = "Team Alpha", 
    [2] = "Team Beta" 
}

-- DEFAULT LOGOS (Filenames inside the 'logos' folder without .png extension)
-- Available: lsr, poland, pp, rt, se, placeholder
Config.TeamLogos = {
    [1] = "placeholder",
    [2] = "placeholder"
}

-- DEFAULT HEX COLORS
Config.DefaultColors = {
    [1] = "#FF3232", -- Red
    [2] = "#3264FF"  -- Blue
}

Config.TeamTags = { 
    [1] = "[T1]", 
    [2] = "[T2]" 
}

-- POINT SYSTEM (Rank = Points)
Config.PointSystem = {
    [1] = 15, [2] = 13, [3] = 11, [4] = 9, [5] = 7,
    [6] = 5,  [7] = 4,  [8] = 3,  [9] = 2,  [10] = 1
}

-- PlayerL Mode Checkpoint Bonus
Config.CheckpointBonus = 1

Config.ExportFileName = "clanwar_results.txt"