local mysteriousScrollId = 580
local oracle, seer = 8, 9 -- npc IDs
local NG = "newGamePlus" -- quest ID as a string, mmext quests are identified by them
vars.Quests = vars.Quests or {} -- just in case, this is the table where quest data is saved by default
local Q = vars.Quests -- convenient alias
-- helpers for testing
function goToQueen()
    evt.MoveToMap{Name = "hive.blv", X = 3970, Y = 26861, Z = -2287}
end
function goToSeer()
    evt.MoveToMap{Name = "outd3.odm", X = -3824, Y = 19719, Z = 3297}
end
function goToControlCenter()
    evt.MoveToMap{Name = "sci-fi.blv", X = -9280, Y = 4160, Z = 197}
end
function goToOracle()
    evt.MoveToMap{Name = "oracle.blv", X = -1415, Y = 1920, Z = -511}
end
function events.AfterLoadMap()
    if Map.Name ~= "oracle.blv" then return end
    evt.Set  {"MapVar6", Value = 1} -- power panel on
    for k, v in Map.Doors do
        evt.SetDoorState(v.Id, 1)
    end
end

function killMouseover()
    Map.Monsters[Mouse:GetTarget().Index].HP = 0
end

function getState()
    return Q[NG]
end

local qBits = {seer = 238, oracle = 239, controlCenter = 240}
Game.QuestsTxt[qBits.seer] = "You found mysterious scroll. Go talk to seer to shed some light on its purpose."
Game.QuestsTxt[qBits.oracle] = "Ask the Oracle about the Misterious Scroll"
Game.QuestsTxt[qBits.controlCenter] = "Open the dimensional prison in Control Center."

-- give scroll to queen
function events.AfterLoadMap()
    if Map.Name == "hive.blv" then
        if mapvars.scrollAdded then return end
        mapvars.scrollAdded = true
        for i, mon in Map.Monsters do
            if mon.Name == "Demon Queen" then
                mon.Item = mysteriousScrollId
                break
            end
        end
    end
end

-- add quest "go to seer" if queen is looted
function events.PickCorpse(t)
    if Map.Name == "hive.blv" and t.Monster.Name == "Demon Queen" then
        evt.Set("QBits", qBits.seer)
    end
end

Quest {
    NG, -- quest id
    NPC = seer, -- NPC who manages quest
    Slot = 2, -- topic number (0-2 in mm6, 0-5 in mm7+) which will host quest topic
    CheckDone = false, -- quest can't be completed here, can also be a function which returns whether quest is completed
    CanShow = function() -- if it returns false, no topic will appear
        return evt.All.Cmp("Inventory", mysteriousScrollId) and not Q[NG] -- has item and quest is not started
    end,
    Texts = {
        Topic = "Mysterious Scroll",
        Give = "Ah, the scroll you bring holds the key to a forgotten prophecy, seek the wisdom of the Oracle to unveil its true purpose.",
        TopicGiven = false, -- no topic if quest is in "Given" state
        TopicDone = false, -- no topic if quest is in "Done" state
    },
    Give = function() -- run on topic click if quest is given
        Q[NG] = "GoToOracle" -- custom quest state
        evt.Sub("QBits", qBits.seer) -- remove "go to seer" quest
        evt.Set("QBits", qBits.oracle) -- add "go to oracle" quest
    end
}

Quest {
    BaseName = NG, -- link to other quest, means that it's another part of same quest
    NPC = oracle,
    Slot = 2,
    CheckDone = false,
    CanShow = function()
        return Q[NG] == "GoToOracle" -- check that quest state is appropriate
    end,
    GoToOracle = function() -- run on "GoToOracle" quest state
        Q[NG] = "ControlCenter"
        evt.Add("QBits", qBits.controlCenter)
        evt.Sub("QBits", qBits.oracle)
        -- uncomment to remove item from inventory
        -- evt.All.Sub("Inventory", mysteriousScrollId)
    end,
    Texts = {
        Topic = "Dimensional Prison", -- topic text
        GoToOracle = "Ah, seeker of truth, your arrival heralds a long-awaited moment, for the scroll you possess holds within it the means to unlock the dimensional prison in control center, a place where an insidious and malevolent evil has been locked away for ages, and I, as the keeper of prophecies, have patiently awaited its arrival so that we may join forces and wield the combined might of the scroll and your valiant spirit to vanquish this ancient threat once and for all, restoring peace and harmony to our troubled world." -- message text shown on "GoToOracle" quest state
    }
}

function events.LeaveMap()
    -- put check for having cleared control center here
    if Map.Name == "sci-fi.blv" and Q[NG] == "ControlCenter" then
        Q[NG] = "ControlCenterDone"
    end
end

Quest {
    BaseName = NG,
    NPC = oracle,
    Slot = 2,
    NeverGiven = true,
    Gold = 3874, -- gold reward
    Exp = 4823434, -- exp reward
    CheckDone = true, -- always completable
    CanShow = function()
        return Q[NG] == "ControlCenterDone"
    end,
    ControlCenterDone = function()
        evt.Sub("QBits", qBits.controlCenter)
        Q[NG] = "Done"
        -- enable new game stuff here
    end,
    Texts = {
        Topic = "The End",
        TopicDone = false,
        ControlCenterDone = "Heroes of unwavering valor, you have proven yourselves capable of defeating the Creator, but in the process, a space-time fracture has manifested within the control center; should you choose to investigate it, be aware that there might be no coming back, yet the opportunity to uncover hidden truths and mend the shattered reality awaits those who dare to venture forth."
    }
}

--[[
so:
looting the queen will get you a misterious scroll
after teleport to new sorpigal you get the quest, saying that you should ask someone about it, probably the seer
the seer sends you to the oracle, but the oracle inform you that there is no time for that, as some danger is awaiting in the control center
you go there and do the long chains of events
after that you talk to the oracle, complete the quest and you are able to reset the game
10:57
so basically:
quest given after the hive
step 1 seer
step 2 oracle
step 3 complete the event
turn to oracle
give a new quest saying that you are free to explore the world finishing some business or just start over at higher difficulty

]]
