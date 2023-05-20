local mysteriousScrollId = 579
local oracle, seer = 8, 9 -- npc IDs
local NG = "newGamePlus" -- quest ID as a string, mmext quests are identified by them
vars.Quests = vars.Quests or {} -- just in case, this is the table where quest data is saved by default
local Q = vars.Quests -- convenient alias
local qBit = 500
--Game.QuestsTxt[qBit] = "asdgsdfgdsfdfs"
--Party.QBits[qBit] = true
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

Quest {
    NG, -- quest id
    NPC = seer, -- NPC who manages quest
    Slot = 2, -- topic number (0-2 in mm6, 0-5 in mm7+) which will host quest topic
    CheckDone = false, -- quest can't be completed here, can also be a function which returns whether quest is completed
    CanShow = function() -- if it returns false, no topic will appear
        return evt.All.Cmp("Inventory", mysteriousScrollId) and not Q[NG] -- has item and quest is not started
    end,
    Texts = {
        Quest = "You found mysterious scroll. Go talk to oracle to shed some light on its purpose.", -- TODO: not working
        QuestGoToOracle = "test",
        Topic = "Mysterious Scroll",
        Give = "Some lengthy flavor text telling to go to oracle",
        TopicGiven = false,
        TopicDone = false,
    },
    Give = function() -- run on topic click if quest is given
        Q[NG] = "GoToOracle" -- custom quest state
    end
}

-- give scroll
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

NPCTopic {
    BaseName = NG, -- link to other quest, means that it's another part of same quest
    NPC = oracle,
    Slot = 2,
    CheckDone = false,
    CanShow = function()
        return Q[NG] == "GoToOracle" -- check that quest state is appropriate
    end,
    GoToOracle = function() -- run on "GoToOracle" quest state
        Q[NG] = "ControlCenter"
    end,
    "Imminent Danger", -- topic text
    [[Good that you've come with the scroll. But first, you need to deal with the danger in control center.]], -- message text
    Texts = {
        Quest = "Clear control center and return to the oracle",
        GoToOracle = "You need to clear control center first." -- shown on "GoToOracle" quest state
    }
}

function events.LeaveMap()
    if Map.Name == "sci-fi.blv" and Q[NG] == "ControlCenter" then
        Q[NG] = "ControlCenterDone"
    end
end

NPCTopic {
    BaseName = NG,
    NPC = oracle,
    Slot = 2,
    --NeverGiven = true,
    Gold = 387483974, -- gold reward
    Exp = 43848234, -- exp reward
    CheckDone = true, -- always completable
    CanShow = function()
        return Q[NG] == "ControlCenterDone"
    end,
    Done = function()
        Q[NG] = "Done"
        -- enable new game stuff here
    end,
    Texts = {
        Topic = "Success!",
        TopicDone = false,
        ControlCenterDone = "Good job! Now you may reset the game."
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