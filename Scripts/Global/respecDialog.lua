--local npc = 399
local npc = 123

-- TO TEST, enter any npc house and execute: "evt.MoveNPC{NPC = 399, HouseId = Game.GetCurrentHouse()}" and then reenter house

NPCTopic {
    NPC = npc,
    Slot = 0, -- adjust slot here
    Branch = "", -- initial branch after entering npc dialog if there is no persisted one
    Ungive = function() -- run on topic click
        QuestBranch("doRespec") -- switch to actual respec branch (topic and code)
    end,
    Texts = {   
        Topic = "Respec",
        Ungive = "Do you want to reset all your learned skills (with a fee)?",
    },
}

vars.respecs = vars.respecs or {}

local function calcGoldCost(pl)
    -- put your gold calculation here
    return pl.LevelBase * 1000
end

local function respec(pl)
    -- execute your respec code here
    pl.MightBase = pl.MightBase + 100
end

local function relearnMasteries(pl)
    Party.Gold = Party.Gold + 250000
end

Quest {
    Name = "respecQuest", -- means it's part of above quest
    NPC = npc,
    Slot = 0,
    Branch = "doRespec", -- only show if respec topic was clicked
    NeverGiven = true, -- skip given state
    NeverDone = true, -- quest completable multiple times
    GetTopic = function()
        return string.format("Respec for %d gold", calcGoldCost(Party[Game.CurrentPlayer]))
    end,
    CheckDone = function()
        return Party.Gold >= calcGoldCost(Party[Game.CurrentPlayer])
    end,
    Done = function()
        Party.Gold = Party.Gold - calcGoldCost(Party[Game.CurrentPlayer])
        QuestBranch"" -- return to "respec" topic
        respec(Party[Game.CurrentPlayer])
        vars.respecs[Game.CurrentPlayer] = true
    end,
    Texts = {
        Undone = "You don't have enough gold.",
        Done = "Skills are reset. Enjoy building your character again."
    }
}

NPCTopic {
    "Relearn masteries",
    NPC = npc,
    Slot = 1,
    NeverDone = true,
    NeverGiven = true,
    CheckDone = function()
        return vars.respecs[Game.CurrentPlayer] == true
    end,
    Done = function()
        relearnMasteries(Party[Game.CurrentPlayer])
        vars.respecs[Game.CurrentPlayer] = false
    end,
    Texts = {
        Done = "Masteries have been restored.",
        Undone = "You haven't performed respec yet.",
    }
}