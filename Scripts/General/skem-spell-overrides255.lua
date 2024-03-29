local u1, u2, u4, i1, i2, i4 = mem.u1, mem.u2, mem.u4, mem.i1, mem.i2, mem.i4
local hook, autohook, autohook2, asmpatch = mem.hook, mem.autohook, mem.autohook2, mem.asmpatch
local StaticAlloc = mem.StaticAlloc
local max, min, floor, ceil, round, random = math.max, math.min, math.floor, math.ceil, math.round, math.random
local format = string.format

local mmver = offsets.MMVersion
function mmv(...)
	local r = select(mmver - 5, ...)
	assert(r ~= nil)
	return r
end

-- returns party index
local function getSlot(player)
	for i, pl in Party do
		if pl == player then
			return i
		end
	end
end						

local function getSpellQueueData(spellQueuePtr, targetPtr)
	local t = {Spell = i2[spellQueuePtr], Caster = Party.PlayersArray[i2[spellQueuePtr + 2]]}
	t.SpellSchool = ceil(t.Spell / 11)
	local flags = u2[spellQueuePtr + 8]
	if flags:And(0x10) ~= 0 then -- caster is target
		t.Caster = Party[i2[spellQueuePtr + 4]]
	end
    t.CasterIndex = getSlot(t.Caster)

	if flags:And(1) ~= 0 then
		t.FromScroll = true
		t.Skill, t.Mastery = SplitSkill(u2[spellQueuePtr + 0xA])
	else
		if mmver > 6 then
			t.Skill, t.Mastery = SplitSkill(t.Caster:GetSkill(const.Skills.Fire + t.SpellSchool - 1))
		else -- no GetSkill
			t.Skill, t.Mastery = SplitSkill(t.Caster.Skills[const.Skills.Fire + t.SpellSchool - 1])
		end
	end

	local targetIdKey = mmv("TargetIndex", "TargetIndex", "TargetRosterId")
	if targetPtr then
		if type(targetPtr) == "number" then
			t[targetIdKey], t.Target = internal.GetPlayer(targetPtr)
		else
			t[targetIdKey], t.Target = targetPtr:GetIndex(), targetPtr
		end
	else
		local pl = Party[i2[spellQueuePtr + 4]]
		t[targetIdKey], t.Target = pl:GetIndex(), pl
	end
	return t
end

--[[ 
	Skill Emphasis Mod - RawSugar's Spell Overrides
	Supersedes various parts of Core; segments list lines to remove from 0.8.2
]]
if SETTINGS["255MOD"]==true then
-- set to true to show damage in the spell descriptions as a dice string
local SHOW_DAMAGE_AS_DICE = SETTINGS["ShowDiceInSpellDescription"]
local ADAPTIVE = string.lower(SETTINGS["AdaptiveMonsterMode"])

-- NOT IMPLEMENTED YET
-- set to true to show "dynamic" damage in spell descriptions, rather than generic damage.
local DYNAMIC_DESCRIPTION_DAMAGE = false

local training = {
	["Normal"] = "Novice", 
	["Expert"] = "Expert", 
	["Master"] = "Master"
}

local spellTxtIds = {}

local DifficultyModifier = SETTINGS["DifficultyModifier"]

-- helper functions

local function GetPlayer(p)
	local i = (p - Party.PlayersArray["?ptr"]) / Party.PlayersArray[0]["?size"]
	return i, Party.PlayersArray[i]
end

local function GetMonster(p)
	if p == 0 then
		return
	end
	local i = (p - Map.Monsters["?ptr"]) / Map.Monsters[0]["?size"]
	return i, Map.Monsters[i]
end

local function GetMonsterTxt(p)
	if p == 0 then
		return
	end
	local i = (p - Game.MonstersTxt["?ptr"]) / Game.MonstersTxt[0]["?size"]
	return i, Game.MonstersTxt[i]
end
--[[ for player-centered spell description code; need to figure out tech for this
local function getAttackSpellRange(p,spellID)
	player = GetPlayer(p)
	spell = Game.Spells[spellID]
	spellTxt = Game.SpellsTxt[spellID]

	spellGroup = 

	rank, mastery = splitSkill
end
]]
-- randomSpellPower
-- supersedes skill-mod.lua:1095-1101

local function randomSpellPower(spellPower, level)
	local r = math.random(spellPower.fixedMin, spellPower.fixedMax)
	for i = 1, level do
		r = r + math.random(spellPower.variableMin, spellPower.variableMax)
	end
	return r
end

-- Spell Powers
-- supersedes skill-mod.lua:374-637

local protectionSpellExtraMultiplier = 2

local spellResists =
{
	["Harm"] = const.Damage.Phys,
	["Flying Fist"] = const.Damage.Phys,
}

local spellBuffPowers =
{
	-- Stone Skin
	["StoneSkin"] =
	{
		["fixed"] = 5,
		["proportional"] = 2,
	},
	-- Bless
	["Bless"] =
	{
		["fixed"] = 5,
		["proportional"] = 2,
	},
	-- Heroism
	["Heroism"] =
	{
		["fixed"] = 5,
		["proportional"] = 2,
	},
}
local spellStatsBuffPowers =
{
	["StatsBuff"] =
	{
		["fixed"] = 5,
		["proportional"] = 2,
	},
}

local function setProtectionSpellDescriptions(name, page, resist)
	id = spellTxtIds[name]
	Game.SpellsTxt[id].Description = "Increases all your characters' resistance to " .. resist .. " damage.  Lasts one hour per point of skill in " .. page .. " magic."
	for k,v in pairs(training) do
		Game.SpellsTxt[id][k] = string.format("Adds %d resistance per point of skill.", (const[v] + protectionSpellExtraMultiplier))
	end
end

local function setStatSpellDescriptions(name, page, stat)
	id = spellTxtIds[name]
	Game.SpellsTxt[id].Description = "Temporarily increases all your characters' " .. stat .. string.format(" by 10 + %d per point of skill.",spellStatsBuffPowers["StatsBuff"]["proportional"]) .. "  Lasts one hour per point of skill in " .. page .. " magic."
	Game.SpellsTxt[id].Normal = "Slow Recovery Time."
	Game.SpellsTxt[id].Expert = "Faster Recovery Time."
	Game.SpellsTxt[id].Master = "Fastest Recovery Time." 
end

local function getSkillAndBookForSpell(name)
	id = spellTxtIds[name]
	position = 1 + (id % 11)
	book = id + 299
	skill = math.floor(id / 11) + 12
	return skill,position,book
end

local function dynamicSpellDescriptions(spell, player)
	
end



local dayOfProtection = {
	["Protection from Fire"] = {["School"] = "Fire", ["Type"] = "Fire"},
	["Protection from Electricity"] = {["School"] = "Air", ["Type"] = "Electricity"},
	["Protection from Cold"] = {["School"] = "Water", ["Type"] = "Cold"},
	["Protection from Magic"] = {["School"] = "Earth", ["Type"] = "Magic"},
	["Protection from Poison"] = {["School"] = "Body", ["Type"] = "Poison"}
}

local dayOfTheGods = {
	["Lucky Day"] = {["School"] = "Spirit", ["Stat"] = "Luck"},
	["Meditation"] = {["School"] = "Mind", ["Stat"] = "Intellect and Personality"},
	["Precision"] = {["School"] = "Mind", ["Stat"] = "Accuracy"},
	["Speed"] = {["School"] = "Body", ["Stat"] = "Speed"},
	["Power"] = {["School"] = "Body", ["Stat"] = "Might and Endurance"}
}

local hourOfPower = {
	["Haste"] = {["School"] = "Fire", ["flat"] = true, ["Duration"] = {["Novice"] = 1, ["Master"] = 3}},
	["Shield"] = {["School"] = "Air", ["flat"] = true, ["Duration"] = {["Novice"] = 5, ["Master"] = 15}},
	["Stone Skin"] = {["School"] = "Earth", ["flat"] = false, ["Duration"] = {["Novice"] = 5, ["Master"] = 15}},
	["Bless"] = {["School"] = "Spirit", ["flat"] = false, ["Duration"] = {["Novice"] = 5, ["Master"] = 15}},
	["Heroism"] = {["School"] = "Spirit", ["flat"] = false, ["Duration"] = {["Novice"] = 5, ["Master"] = 15}},
}

local spellDescs = {											
	["Guardian Angel"] = {										
		["Description"] = "The Guardian Angel spell helps to reduce the effects of death upon the party. First, the body is preserved from destruction by massive damage, such that only the mightiest of monsters will be able to kill characters outright. Secondly, it sets up a compact with Higher Powers to revive the Party at the last Temple that was visited (the cost of this service is half of the gold that the party has on hand upon death).\nThis compact lasts for one hour, plus five minutes per point of skill in Spirit Magic.",									
		["Normal"] = "Party is revived at 1 HP each.",									
		["Expert"] = "Party is revived at half HP.",									
		["Master"] = "Party is revived at full HP."									
	},										
	["Stone Skin"] = {										
		["Description"] = string.format("Increases the Armor Class of a character by %d + %d per point of skill in Earth Magic.", spellBuffPowers["StoneSkin"]["fixed"], spellBuffPowers["StoneSkin"]["proportional"])									
	},										
	["Bless"] = {										
		["Description"] = string.format("Increases the Attack Bonus (both Melee and Bow) of a character by %d + %d per point of skill in Spirit Magic.",spellBuffPowers["Bless"]["fixed"], spellBuffPowers["Bless"]["proportional"])									
	},										
	["Heroism"] = {										
		["Description"] = string.format("Increases the melee damage of a character by %d + %d per point of skill in Spirit Magic.", spellBuffPowers["Heroism"]["fixed"], spellBuffPowers["Heroism"]["proportional"])									
	},										
	["Healing Touch"] = {										
		["Description"] = "Heals a single character. Skill increases the recovery rate of this spell.",									
		["Normal"] = "Costs 50 SP.\nHeals 5+12 HP per skill level.",									
		["Expert"] = "Costs 100 SP.\nHeals 10+18 HP per skill level.",									
		["Master"] = "Costs 200 SP.\nHeals 15+26 HP per skill level.",									
	},										
	["First Aid"] = {										
		["Description"] = "Cheaply heals a single character. Skill increases the recovery rate of this spell.\nAt Master becomes Final Aid, healing a huge amount of health",									
		["Normal"] = "Costs 100 SP.\nHeals 100+15/rank HP",									
		["Expert"] = "Costs 100 SP.\nHeals 100+18/rank HP",									
		["Master"] = "Final Aid: costs 300 SP.\nHeals 100+25 HP per skill level.",									
	},										
	["Cure Wounds"] = {										
		["Description"] = "Heals a single character. Potency increases relative to the caster's skill in Body Magic.",									
		["Normal"] = "Costs 16 SP.\nHeals 10 HP + 9 per point of skill.",									
		["Expert"] = "Costs 16 SP.\nHeals 15 HP + 12 per point of skill.",									
		["Master"] = "Costs 16 SP.\nHeals 25 HP + 16 per point of skill.",									
	},										
	["Power Cure"] = {										
		["Description"] = "Cures hit points of all characters in your party at once. The number cured is equal to 10 plus 3 per point of skill in Body Magic.",									
		["Normal"] = "Costs 30 SP.\nHeals 10+3 HP per skill level.",									
		["Expert"] = "Costs 200 SP.\nHeals 10+6 HP per skill level.",									
		["Master"] = "Costs 200 SP.\nHeals 10+7 HP per skill level.",									
	},										
		["Resurrection"] = {									
		["Description"] = "The final healing magic. Resurrects an eradicated (body destroyed) character if you cast this spell in time. The greater the skill and rank in Spirit Magic the longer the condition could have been present before the “point of no return” is reached. After that, the only way to resurrect the character is to visit a temple. Casting this spell will leave your character in the weak condition.",									
		["Normal"] = "Works if eradicated less than 3 minutes per point of skill.\nHeals 50 HP + 15 per point of skill.",									
		["Expert"] = "Works if eradicated less than 1 hour per point of skill.\nHeals 100 HP + 20 per point of skill.",									
		["Master"] = "Works if eradicated less than 1 day per point of skill.\nHeals 150 HP + 25 per point of skill.",									
	},										
	["Shared Life"] = {										
		["Description"] = "Shared Life combines the life force of your characters and redistributes it amongst them as evenly as possible. All current hit points are totaled and 9 extra point per point of skill in Spirit Magic is added to this total. Then the points are distributed back to the characters, with no individual character being allowed to have more points than his maximum total hit points.",									
		["Normal"] = "Moderate recovery rate. Heals 9 points pr rank.",									
		["Expert"] = "Faster recovery rate. Heals 12 points pr rank.",									
		["Master"] = "Fastest recovery rate. Heals 15 points pr rank.",									
	},										
	["Cure Poison"] = {										
		["Description"] = "Heals and cures poison in a character if you cast this spell in time. The greater the skill and rank in Body Magic the longer the character could have been poisoned before the “point of no return” is reached. After that, the only way to remove the condition short of Divine Intervention is to visit a temple.",									
		["Normal"] = "Works if poisoned less than 3 minutes per point of skill\nHeals 215 HP.",									
		["Expert"] = "Works if poisoned less than 1 hour per point of skill\nHeals 430 HP.",									
		["Master"] = "Works if poisoned less than 1 day per point of skill\nHeals 665 HP.",									
	},										
		["Cure Insanity"] = {									
		["Description"] = "Heals and cures insanity if you cast this spell in time. The greater the skill and rank in Mind Magic the longer the character could have been insane before the “point of no return” is reached. After that, the only way to remove the condition short of Divine Intervention is to visit a temple.",									
		["Normal"] = "Works if insane less than 3 minutes per point of skill\nCosts 40 SP.\nHeals 15+12 HP per point of skill.",									
		["Expert"] = "Works if insane less than 1 hour per point of skill\nCosts 80 SP.\nHeals 25+16 HP per point of skill.",									
		["Master"] = "Works if insane less than 1 day per point of skill\nCosts 160 SP.\nHeals 35+20 HP per point of skill.",									
	},										
			["Remove Fear"] = {								
		["Description"] = "Heals and removes fear if you cast this spell in time. The greater the skill and rank in Mind Magic the longer the character could have been insane before the “point of no return” is reached. After that, the only way to remove the condition short of Divine Intervention is to visit a temple.",									
		["Normal"] = "Works if afraid less than 3 minutes per point of skill\nCosts 6 SP.\nHeals 200 HP.",									
		["Expert"] = "Works if afraid less than 1 hour per point of skill\nCosts 6 SP.\nHeals 400 HP.",									
		["Master"] = "Works if afraid less than 1 day per point of skill\nCosts 6 SP.\nHeals 650 HP.",									
	},										
			["Remove Curse"] = {								
		["Description"] = "Heals and removes the cursed condition from a character if you cast this spell in time. The greater the skill and rank in Spirit Magic the longer the condition could have been present before the “point of no return” is reached. After that, the only way to remove the condition short of Divine Intervention is to visit a temple.",									
		["Normal"] = "Works if cursed less than 3 minutes per point of skill\nCosts 12 SP.\nHeals 300 HP.",									
		["Expert"] = "Works if cursed less than 1 hour per point of skill\nCosts 24 SP.\nHeals 600 HP.",									
		["Master"] = "Works if cursed less than 1 day per point of skill\nCosts 48 SP.\nHeals 1000 HP.",									
	},										
			["Cure Disease"] = {								
		["Description"] = "Heals and cures disease in a character if you cast this spell in time. The greater the skill and rank in Body Magic the longer the character could have been diseased before the “point of no return” is reached. After that, the only way to remove the condition short of Divine Intervention is to visit a temple.",									
		["Normal"] = "Works if cursed less than 3 minutes per point of skill\nHeals 265 HP.",									
		["Expert"] = "Works if cursed less than 1 hour per point of skill\nHeals 475 HP.",									
		["Master"] = "Works if cursed less than 1 day per point of skill\nHeals 745 HP.",									
	},										
			["Flame Arrow"] = {								
		["Description"] = "Creates and fires a single flaming arrow. The arrow does 6 + 1-2 points of damage per skill.",									
		["Normal"] = "The arrow does 45 + 1-8 points of damage per skill.",									
		["Expert"] = "The arrow does 100 + 1-12 points of damage per skill",									
		["Master"] = "The arrow does 175 + 1-20 points of damage per skill",									
	},										
			["Magic Arrow"] = {								
		["Description"] = "Creates and fires a single magical arrow. Also unlike most spells, Magic Arrow is free to cast when you become a Master of Earth. The arrow does 6 + 1 points of damage per skill.",									
		["Normal"] = "The arrow does 45 + 1-8 points of damage per skill.",									
		["Expert"] = "The arrow does 100 + 1-12 points of damage per skill",									
		["Master"] = "The arrow does 175 + 1-20 points of damage per skill",									
	},
			["Spirit Arrow"] = {								
		["Description"] = "Fires an ectoplasmic bolt of negative spiritual energy at a single target. The arrow causes 1-5 points of damage.",									
		["Normal"] = "The arrow does 45 + 1-8 points of damage per skill.",									
		["Expert"] = "The arrow does 100 + 1-12 points of damage per skill",									
		["Master"] = "The arrow does 175 + 1-20 points of damage per skill",									
	},										
}											
											
local SC = 0											
local SD = 1											
if ADAPTIVE == "100" then											
SC = 35											
SD = 2											
else											
end											
											
local spellCosts =											
{											
	-- healing spells										
	["Healing Touch"] = {["Normal"] = 50, ["Expert"] = 100, ["Master"] = 200},										
	["Cure Wounds"] = {["Normal"] = 16, ["Expert"] = 16, ["Master"] = 16},										
	["First Aid"] = {["Normal"] = 100, ["Expert"] = 100, ["Master"] = 250},										
	["Remove Fear"] = {["Normal"] = 6, ["Expert"] = 6, ["Master"] = 6},										
	["Remove Curse"] = {["Normal"] = 25, ["Expert"] = 50, ["Master"] = 100},										
	["Cure Insanity"] = {["Normal"] = 40, ["Expert"] = 80, ["Master"] = 160},										
	["Resurrection"] = {["Normal"] = 200, ["Expert"] = 200, ["Master"] = 200},										
	["Power Cure"] = {["Normal"] = 30, ["Expert"] = 100, ["Master"] = 200},										
											
	-- damage spells										
	["Fireball"] = {["Normal"] = 50, ["Expert"] = 50, ["Master"] = 250},										
	["Fire Blast"] = {["Normal"] = 50, ["Expert"] = 125, ["Master"] = 250},										
	["Incinerate"] = {["Normal"] = 30, ["Expert"] = 100, ["Master"] = 250},										
	["Inferno"] = {["Normal"] = 25, ["Expert"] = 50, ["Master"] = 100},										
	["Ice Bolt"] = {["Normal"] = 11, ["Expert"] = 100, ["Master"] = 150},										
	["Acid Burst"] = {["Normal"] = 50, ["Expert"] = 50, ["Master"] = 50},
	["Ice Blast"] = {["Normal"] = 25, ["Expert"] = 250, ["Master"] = 250},										
	["Fire Bolt"] = {["Normal"] = 25, ["Expert"] = 50, ["Master"] = 250},
	["Ring of Fire"] = {["Normal"] = 100, ["Expert"] = 100, ["Master"] = 250},											
	["Deadly Swarm"] = {["Normal"] = 100, ["Expert"] = 100, ["Master"] = 250},										
	["Blades"] = {["Normal"] = 20, ["Expert"] = 200, ["Master"] = 250},										
	["Rock Blast"] = {["Normal"] = 50, ["Expert"] = 150, ["Master"] = 250},										
	["Mind Blast"] = {["Normal"] = 1, ["Expert"] = 1, ["Master"] = 25},										
	["Lightning Bolt"] = {["Normal"] = 50, ["Expert"] = 50, ["Master"] = 50},										
	["Implosion"] = {["Normal"] = 20, ["Expert"] = 250, ["Master"] = 250},										
	["Moon Ray"] = {["Normal"] = 50, ["Expert"] = 50, ["Master"] = 50},										
	["Dark Containment"] = {["Normal"] = 100, ["Expert"] = 75, ["Master"] = 50},										
	["Poison Spray"] = {["Normal"] = 50, ["Expert"] = 50, ["Master"] = 250},										
	["Sparks"] = {["Normal"] = 50, ["Expert"] = 150, ["Master"] = 250},										
	["Shrapmetal"] = {["Normal"] = 75, ["Expert"] = 150, ["Master"] = 250},										
	["Mass Distortion"] = {["Normal"] = 50, ["Expert"] = 150, ["Master"] = 250},										
	["Toxic Cloud"] = {["Normal"] = 30, ["Expert"] = 100, ["Master"] = 100},										
	["Flying Fist"] = {["Normal"] = 25, ["Expert"] = 35, ["Master"] = 50},	
	["Psychic Shock"] = {["Normal"] = 75, ["Expert"] = 75, ["Master"] = 250},
										
											
	--debuff spells										
	["Slow"] = {["Master"] = 5},										
	["Paralyze"] = {["Normal"] = 40, ["Expert"] = 40, ["Master"] = 40},										
	["Mass Curse"] = {["Normal"] = 32, ["Expert"] = 32, ["Master"] = 32},										
	["Shrinking Ray"] =  {["Normal"] = 32, ["Expert"] = 32, ["Master"] = 32},									
											
											
}											
											
local spellPowers =											
{											
	-- Flame Arrow										
	[2] =										
	{										
		[const.Novice] = {fixedMin = 45, fixedMax = 45, variableMin = 1, variableMax = 8, },									
		[const.Expert] = {fixedMin = 100, fixedMax = 100, variableMin = 1, variableMax = 12, },									
		[const.Master] = {fixedMin = 175, fixedMax = 175, variableMin = 1, variableMax = 20, },									
	},										
	-- Fire Bolt										
	[4] =										
	{										
		[const.Novice] = {fixedMin = 8, fixedMax = 8, variableMin = 1, variableMax = 15, },									
		[const.Expert] = {fixedMin = 8, fixedMax = 8, variableMin = 1, variableMax = 30, },									
		[const.Master] = {fixedMin = 8, fixedMax = 8, variableMin = 1, variableMax = 40, },									
	},										
	--Fireball										
	[6] =										
	{										
		[const.Novice] = {fixedMin = 12, fixedMax = 12, variableMin = 1, variableMax = 15, },									
		[const.Expert] = {fixedMin = 12, fixedMax = 12, variableMin = 1, variableMax = 18, },									
		[const.Master] = {fixedMin = 12, fixedMax = 12, variableMin = 1, variableMax = 36, },									
	},										
	-- Ring of Fire										
	[7] =										
	{										
		[const.Novice] = {fixedMin = 46, fixedMax = 46, variableMin = 1, variableMax = 10, },									
		[const.Expert] = {fixedMin = 46, fixedMax = 46, variableMin = 1, variableMax = 12, },									
		[const.Master] = {fixedMin = 46, fixedMax = 46, variableMin = 1, variableMax = 17, },									
	},										
	-- Fire Blast										
	[8] =										
	{										
		[const.Novice] = {fixedMin = 4, fixedMax = 4, variableMin = 1, variableMax = 15, },									
		[const.Expert] = {fixedMin = 4, fixedMax = 4, variableMin = 1, variableMax = 18, },									
		[const.Master] = {fixedMin = 4, fixedMax = 4, variableMin = 1, variableMax = 21, },									
	},										
	-- Meteor Shower										
	[9] =										
	{										
		[const.Novice] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 4, },									
		[const.Expert] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 5, },									
		[const.Master] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 6, },									
	},										
	-- Inferno										
	[10] =										
	{										
		[const.Novice] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 5, },									
		[const.Expert] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 9, },									
		[const.Master] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 13, },									
	},										
	-- Incinerate										
	[11] =										
	{										
		[const.Novice] = {fixedMin = 32, fixedMax = 32, variableMin = 1, variableMax = 21, },									
		[const.Expert] = {fixedMin = 32, fixedMax = 32, variableMin = 1, variableMax = 37, },									
		[const.Master] = {fixedMin = 32, fixedMax = 32, variableMin = 1, variableMax = 55, },									
	},										
	-- Static Charge										
	[13] =										
	{										
		[const.Novice] = {fixedMin = 85, fixedMax = 85, variableMin = 3, variableMax = 3, },									
		[const.Expert] = {fixedMin = 200, fixedMax = 200, variableMin = 4, variableMax = 4, },									
		[const.Master] = {fixedMin = 350, fixedMax = 350, variableMin = 5, variableMax = 5, },									
	},										
	-- Sparks										
	[15] =										
	{										
		[const.Novice] = {fixedMin = 3, fixedMax = 3, variableMin = 1, variableMax = 14, },									
		[const.Expert] = {fixedMin = 3, fixedMax = 3, variableMin = 1, variableMax = 15, },									
		[const.Master] = {fixedMin = 1, fixedMax = 1, variableMin = 1, variableMax = 16, },									
	},										
	-- Lightning Bolt										
	[18] =										
	{										
		[const.Novice] = {fixedMin = 15, fixedMax = 15, variableMin = 1, variableMax = 24, },									
		[const.Expert] = {fixedMin = 15, fixedMax = 15, variableMin = 1, variableMax = 27, },									
		[const.Master] = {fixedMin = 15, fixedMax = 15, variableMin = 1, variableMax = 30, },									
	},										
	-- Implosion										
	[20] =										
	{										
		[const.Novice] = {fixedMin = 18, fixedMax = 18, variableMin = 1, variableMax = 19, },									
		[const.Expert] = {fixedMin = 18, fixedMax = 18, variableMin = 1, variableMax = 48, },									
		[const.Master] = {fixedMin = 18, fixedMax = 18, variableMin = 1, variableMax = 56, },									
	},										
	-- Cold Beam										
	[24] =										
	{										
		[const.Novice] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 11, },									
		[const.Expert] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 17, },									
		[const.Master] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 23, },									
	},										
	-- Poison Spray										
	[26] =										
	{										
		[const.Novice] = {fixedMin = 4, fixedMax = 4, variableMin = 1, variableMax = 20, },									
		[const.Expert] = {fixedMin = 4, fixedMax = 4, variableMin = 1, variableMax = 20, },									
		[const.Master] = {fixedMin = 4, fixedMax = 4, variableMin = 1, variableMax = 20, },									
	},										
	-- Ice Bolt										
	[28] =										
	{										
		[const.Novice] = {fixedMin = 12, fixedMax = 12, variableMin = 1, variableMax = 18, },									
		[const.Expert] = {fixedMin = 22, fixedMax = 22, variableMin = 1, variableMax = 26, },									
		[const.Master] = {fixedMin = 20, fixedMax = 20, variableMin = 1, variableMax = 30, },									
	},										
	-- Acid Burst										
	[30] =										
	{										
		[const.Novice] = {fixedMin = 20, fixedMax = 20, variableMin = 1, variableMax = 24, },									
		[const.Expert] = {fixedMin = 20, fixedMax = 20, variableMin = 1, variableMax = 27, },									
		[const.Master] = {fixedMin = 20, fixedMax = 20, variableMin = 1, variableMax = 36, },									
	},										
	-- Ice Blast										
	[32] =										
	{										
		[const.Novice] = {fixedMin = 6, fixedMax = 6, variableMin = 1, variableMax = 9, },									
		[const.Expert] = {fixedMin = 6, fixedMax = 6, variableMin = 1, variableMax = 21, },									
		[const.Master] = {fixedMin = 6, fixedMax = 6, variableMin = 1, variableMax = 27, },									
	},										
	-- Magic Arrow										
	[35] =										
	{										
		[const.Novice] = {fixedMin = 80, fixedMax = 80, variableMin = 2, variableMax = 2, },									
		[const.Expert] = {fixedMin = 175, fixedMax = 175, variableMin = 3, variableMax = 3, },									
		[const.Master] = {fixedMin = 300, fixedMax = 300, variableMin = 4, variableMax = 4, },									
	},										
	-- Deadly Swarm										
	[37] =										
	{										
		[const.Novice] = {fixedMin = 8, fixedMax = 8, variableMin = 1, variableMax = 18, },									
		[const.Expert] = {fixedMin = 8, fixedMax = 8, variableMin = 1, variableMax = 24, },									
		[const.Master] = {fixedMin = 8, fixedMax = 8, variableMin = 1, variableMax = 30, },									
	},										
	-- Blades										
	[39] =										
	{										
		[const.Novice] = {fixedMin = 20, fixedMax = 20, variableMin = 1, variableMax = 15, },									
		[const.Expert] = {fixedMin = 20, fixedMax = 20, variableMin = 1, variableMax = 35, },									
		[const.Master] = {fixedMin = 20, fixedMax = 20, variableMin = 1, variableMax = 45, },									
	},										
	-- Rock Blast										
	[41] =										
	{										
		[const.Novice] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 15, },									
		[const.Expert] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 22, },									
		[const.Master] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 33, },									
	},										
	-- Death blossom										
	[43] =										
	{										
		[const.Novice] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 11, },									
		[const.Expert] = {fixedMin = 0, fixedMax = 0, variableMin = 2, variableMax = 19, },									
		[const.Master] = {fixedMin = 0, fixedMax = 0, variableMin = 2, variableMax = 31, },									
	},										
	-- Spirit Arrow										
	[45] =										
	{										
		[const.Novice] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 14, },									
		[const.Expert] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 24, },									
		[const.Master] = {fixedMin = 0, fixedMax = 0, variableMin = 1, variableMax = 30, },									
	},										
	-- Mind Blast										
	[58] =										
	{										
		[const.Novice] = {fixedMin = 6, fixedMax = 6, variableMin = 1, variableMax = 15, },									
		[const.Expert] = {fixedMin = 6, fixedMax = 6, variableMin = 1, variableMax = 25, },									
		[const.Master] = {fixedMin = 6, fixedMax = 6, variableMin = 1, variableMax = 45, },									
	},										
	-- Psychic Shock										
	[65] =										
	{										
		[const.Novice] = {fixedMin = 47, fixedMax = 47, variableMin = 1, variableMax = 40, },									
		[const.Expert] = {fixedMin = 47, fixedMax = 47, variableMin = 1, variableMax = 50, },									
		[const.Master] = {fixedMin = 47, fixedMax = 47, variableMin = 1, variableMax = 70, },									
	},										
	-- Harm deals physical damage, so should use vanilla numbers										
	[70] =										
	{										
		[const.Novice] = {fixedMin = 8, fixedMax = 8, variableMin = 1, variableMax = 10, },									
		[const.Expert] = {fixedMin = 8, fixedMax = 8, variableMin = 1, variableMax = 13, },									
		[const.Master] = {fixedMin = 8, fixedMax = 8, variableMin = 1, variableMax = 16, },									
	},										
	-- Flying Fist deals physical damage, so should use vanilla numbers										
	[76] =										
	{										
		[const.Novice] = {fixedMin = 30, fixedMax = 30, variableMin = 1, variableMax = 18, },									
		[const.Expert] = {fixedMin = 30, fixedMax = 30, variableMin = 1, variableMax = 22, },									
		[const.Master] = {fixedMin = 30, fixedMax = 30, variableMin = 1, variableMax = 26, },									
	},										
	-- Destroy Undead										
	[82] =										
	{										
		[const.Novice] = {fixedMin = 50, fixedMax = 50, variableMin = 1, variableMax = 40, },									
		[const.Expert] = {fixedMin = 50, fixedMax = 50, variableMin = 1, variableMax = 60, },									
		[const.Master] = {fixedMin = 50, fixedMax = 50, variableMin = 1, variableMax = 90, },									
	},										
	-- Prismatic Light										
	[84] =										
	{										
		[const.Novice] = {fixedMin = 25, fixedMax = 25, variableMin = 1, variableMax = 7, },									
		[const.Expert] = {fixedMin = 25, fixedMax = 25, variableMin = 1, variableMax = 14, },									
		[const.Master] = {fixedMin = 25, fixedMax = 25, variableMin = 1, variableMax = 21, },									
	},										
	-- Sun Ray										
	[87] =										
	{										
		[const.Novice] = {fixedMin = 90, fixedMax = 90, variableMin = 1, variableMax = 60, },									
		[const.Expert] = {fixedMin = 90, fixedMax = 90, variableMin = 1, variableMax = 90, },									
		[const.Master] = {fixedMin = 90, fixedMax = 90, variableMin = 1, variableMax = 120, },									
	},										
	--Toxic Cloud										
	[90] =										
	{										
		[const.Novice] = {fixedMin = 32, fixedMax = 32, variableMin = 1, variableMax = 20, },									
		[const.Expert] = {fixedMin = 32, fixedMax = 32, variableMin = 1, variableMax = 37, },									
		[const.Master] = {fixedMin = 32, fixedMax = 32, variableMin = 1, variableMax = 43, },									
	},										
	-- Shrapmetal deals physical damage, so should use vanilla numbers										
	[92] =										
	{										
		[const.Novice] = {fixedMin = 6, fixedMax = 6, variableMin = 1, variableMax = 12, },									
		[const.Expert] = {fixedMin = 6, fixedMax = 6, variableMin = 1, variableMax = 13, },									
		[const.Master] = {fixedMin = 6, fixedMax = 6, variableMin = 1, variableMax = 14, },									
	},										
}											




-- Spell Overrides, ASM Patches, set 1
-- supersedes skill-mod.lua:1802-1987

-- all spells always hit

mem.asmpatch(0x0043188D, "jmp     0x23", 2)

-- debuff success rate - level is less important
--if ADAPTIVE == "100" then
--else
--mem.asmhook(0x421F06, "shr cl, 2")
--end

-- spell damage modification

function events.CalcSpellDamage(t)

	if spellPowers[t.Spell] ~= nil then
	
		-- custom spell power
	
		local spellPower = spellPowers[t.Spell][t.Mastery]
		t.Result = randomSpellPower(spellPower, t.Skill)
		
	end
	
end

-- spell buffs

local function calculateSpellBuffPower(spellBuffName, level)
	return spellBuffPowers[spellBuffName]["fixed"] + level * spellBuffPowers[spellBuffName]["proportional"]
end

-- StoneSkin

local function setStoneSkinPowerNovice(d)
	d.eax = calculateSpellBuffPower("StoneSkin", d.eax - 5)
end
mem.autohook(0x00426284, setStoneSkinPowerNovice, 0x8)
local function setStoneSkinPowerExpert(d)
	d.ecx = calculateSpellBuffPower("StoneSkin", d.ecx - 5)
end
mem.autohook(0x0042617F, setStoneSkinPowerExpert, 0x8)

-- Bless
local function setBlessPowerNovice(d)
	d.eax = calculateSpellBuffPower("Bless", d.eax - 5)
end
mem.autohook(0x0042680C, setBlessPowerNovice, 0x8)
local function setBlessPowerExpert(d)
	d.ecx = calculateSpellBuffPower("Bless", d.ecx - 5)
end
mem.autohook(0x00426712, setBlessPowerExpert, 0x8)

-- Heroism
local function setHeroismPowerNovice(d)
	d.ecx = calculateSpellBuffPower("Heroism", d.ecx - 5)
end
mem.autohook(0x00426D4C, setHeroismPowerNovice, 0x8)
local function setHeroismPowerExpert(d)
	d.ecx = calculateSpellBuffPower("Heroism", d.ecx - 5)
end
mem.autohook(0x00426C4F, setHeroismPowerExpert, 0x8)

-- Healing Touch
mem.asmpatch(0x00426917, "mov     edx, 5", 5)
mem.asmpatch(0x00426926, "add     eax, 25", 3)
mem.asmpatch(0x00426903, "mov     edx, 11", 5)
mem.asmpatch(0x00426912, "add     eax, 65", 3)

-- First Aid
mem.bytecodepatch(0x00427E46, "\005", 1)
mem.bytecodepatch(0x00427E3C, "\015", 1)
mem.bytecodepatch(0x00427E32, "\250", 1)

-- Cure Wounds
mem.asmpatch(0x00427FA2, "lea     edx, [ecx+ecx+10]", 4)
mem.asmpatch(0x00427F94, "lea     eax, [edx+edx*2+20]", 4)
mem.asmpatch(0x00427F86, "lea     ecx, [eax+eax*4+40]", 4)

-- Power Cure
mem.asmpatch(0x00428596, "lea     ecx, [eax+eax*2]", 4)

-- Protection from Fire
mem.asmpatch(
	0x004236E3,
	"mov    eax, DWORD [esp+0x10]\n" ..
	"mov    ecx, esi\n" ..
	string.format("add    ecx,%d\n", protectionSpellExtraMultiplier) ..
	"imul   ecx, eax\n" ..
	"mov    DWORD [esp+0x14], ecx\n",
	0x2D
)
-- duration = skill * 2 hours
-- mem.asmpatch(0x00423719, "shl     eax, 5", 2)

-- Protection from Electricity
mem.asmpatch(
	0x0042439D,
	"mov    eax, DWORD[esp+0x10]\n" ..
	"mov    ecx, esi\n" ..
	"inc    ecx\n" ..
	"inc    ecx\n" ..
	"imul   ecx, eax\n" ..
	"mov    DWORD [esp+0x14], ecx\n",
	0x2D
)

-- duration = skill * 2 hours
-- mem.asmpatch(0x004243D4, "shl     eax, 15", 2)

-- Protection from Cold
mem.asmpatch(
	0x00424F99,
	"mov    eax, DWORD[esp+0x10]\n" ..
	"mov    ecx, esi\n" ..
	string.format("add    ecx,%d\n", protectionSpellExtraMultiplier) ..
	"imul   ecx, eax\n" ..
	"mov    DWORD [esp+0x14], ecx\n",
	0x2D
)

-- duration = skill * 2 hours
-- mem.asmpatch(0x00424FD0, "shl     eax, 5", 2)

-- Protection from Magic
mem.asmpatch(
	0x00426087,
	"mov    eax, DWORD[esp+0x10]\n" ..
	"mov    ecx, esi\n" ..
	string.format("add    ecx,%d\n", protectionSpellExtraMultiplier) ..
	"imul   ecx, eax\n" ..
	"mov    DWORD [esp+0x14], ecx\n",
	0x2D
)

-- duration = skill * 2 hours
-- mem.asmpatch(0x004260BE, "shl     eax, 5", 2)

-- Protection from Poison
mem.asmpatch(
	0x00427EBB,
	"mov    eax, DWORD[esp+0x10]\n" ..
	"mov    ecx, esi\n" ..
	string.format("add    ecx,%d\n", protectionSpellExtraMultiplier) ..
	"imul   ecx, eax\n" ..
	"mov    DWORD [esp+0x14], ecx\n",
	0x2D
)

-- duration = skill * 2 hours
-- mem.asmpatch(0x00427EF1, "shl     eax, 5", 2)

-- Day of Protection

-- Novice power = 2 (same as in vanilla - no change)
-- Expert power = 3
mem.asmpatch(0x0042961A, "lea    edx,[eax+eax*1]", 3)
-- Master power = 4
mem.asmpatch(0x0042960D, "lea    ecx,[eax*2+0x0]", 7)

-- duration = 1 hour * skill
mem.asmpatch(0x0042962E, [[
		lea    eax,[eax+eax*2]
		nop
	]], 4)

-- Day of the Gods

-- Novice power = 0 + skill * 1
mem.asmpatch(0x00428A90, [[
		lea    edx,[ecx+0x0]
		nop
	]], 4)
-- Expert power = 0 + skill * 2
mem.asmpatch(0x00428A7B, [[
		lea    ecx,[ecx*2+0x0]
		nop
	]], 4)
-- Master power = 5 + skill * 2
mem.asmpatch(0x00428A62, [[
		lea    eax,[ecx*2+0x5]
		nop
		nop
		nop
		nop
	]], 7)

-- Novice duration = skill * 1 hour
mem.asmpatch(0x00428A9E, "shl     eax, 4", 3)
-- Expert duration = skill * 1 hour
mem.asmpatch(0x00428A75, "imul    eax, 3600", 6)
-- Novice duration = skill * 1 hour
mem.asmpatch(0x00428A5B, "shl     eax, 4", 3)

-- Spell Overrides, ASM Patches, set 2
-- supersedes skill-mod.lua:2560-2596

-- Lucky day does not create pointer
mem.asmpatch(0x004220D5, "test   BYTE [eax+0x70],0xFF", 0x4)
-- Lucky day affects whole party
mem.asmpatch(0x004269CD, "cmp    esi,esi", 0x3)
-- Lucky day multiplier = 5
mem.asmpatch(0x004269B4, "lea     ecx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
mem.asmpatch(0x004269A6, "lea     edx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
mem.asmpatch(0x0042699C, "lea     ecx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
-- Meditation/Precision does not create pointer
mem.asmpatch(0x004220E3, "test   BYTE [eax+0x71],0xFF", 0x4)
-- Meditation affects whole party
mem.asmpatch(0x00427399, "cmp    esi,esi", 0x3)
-- Meditation multiplier = 5
mem.asmpatch(0x00427380, "lea     ecx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
mem.asmpatch(0x00427372, "lea     edx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
mem.asmpatch(0x00427368, "lea     ecx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
-- Precision affects whole party
mem.asmpatch(0x0042760D, "cmp    esi,esi", 0x3)
-- Precision multiplier = 5
mem.asmpatch(0x004275F4, "lea     ecx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
mem.asmpatch(0x004275E6, "lea     edx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
mem.asmpatch(0x004275DC, "lea     ecx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
-- Speed/Power does not create pointer
mem.asmpatch(0x004220F6, "test   BYTE [eax+0x72],0xFF", 0x4)
-- Speed affects whole party
mem.asmpatch(0x00428154, "cmp    esi,esi", 0x3)
-- Speed multiplier = 5
mem.asmpatch(0x0042813B, "lea     ecx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
mem.asmpatch(0x0042812D, "lea     edx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
mem.asmpatch(0x00428123, "lea     ecx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
-- Power affects whole party
mem.asmpatch(0x004283F8, "cmp    esi,esi", 0x3)
-- Power multiplier = 5
mem.asmpatch(0x004283DF, "lea     ecx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
mem.asmpatch(0x004283D1, "lea     edx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)
mem.asmpatch(0x004283C7, "lea     ecx, [eax+eax*" .. (spellStatsBuffPowers["StatsBuff"]["proportional"] - 1) .. "+0Ah]", 0x4)

-- Bless affects whole party on novice
-- no choose target screen
mem.asmpatch(0x4220BF, [[
	cmp esi, 0x2C ; bless
	je absolute 0x422104
	mov ecx,dword [esp+0x18]
	test ecx,ecx
]], 6)

-- affect everyone
-- jump to same code as expert if novice
mem.prot(true)
mem.u4[0x4266E9] = 0xF4
mem.prot()

-- Feeblemind Fixes
-- supersedes skill-mod.lua:2703-2732

local function disableFeeblemindedMonsterCasting(d, def)
	-- get default random value
	local randomRoll = def()
	-- get monster
	local monsterIndex, monster = GetMonster(d.esi)
	
		-- check monster is feebleminded
	if monster.SpellBuffs[const.MonsterBuff.Feeblemind].ExpireTime ~= 0 then
		-- set random roll to 100 to prevent casting
		randomRoll = 99
	end
	return randomRoll
end
mem.hookcall(0x00421C5C, 0, 0, disableFeeblemindedMonsterCasting)

-- Feeblemind prevents monster to do bad things

-- disabled because conflicts with mm6patch
--[[local function disableFeeblemindedMonsterSpecialAbility(d, def, playerPointer, thing)
	-- get monster
	local monsterIndex, monster = GetMonster(d.edi)
	-- check monster is feebleminded
	if monster.SpellBuffs[const.MonsterBuff.Feeblemind].ExpireTime ~= 0 then
		-- do nothing
	else
		-- do bad thing
		def(playerPointer, thing)
	end
end
mem.hookcall(0x00431DE7, 1, 1, disableFeeblemindedMonsterSpecialAbility)]]

-- this done instead
mem.autohook2(0x431DE1, function(d)
	local monsterIndex, monster = GetMonster(d.edi)
	if monster.SpellBuffs[const.MonsterBuff.Feeblemind].ExpireTime ~= 0 then
		d:push(0x431DEC)
		return true
	end
end)

-- Guardian Angel changes
-- supersedes skill-mod.lua:3316-3359
local function guardianAngelCharacterTrySubtractSpellPoints(d, def, characterPointer, spellPoints)
	-- get caster
	local playerIndex, player = GetPlayer(d.ebp)
	-- get caster skill
	local level, rank = SplitSkill(player.Skills[const.Skills.Spirit])
	-- store spell power
	guardianAngelPower = level
	-- execute original method
	return def(characterPointer, spellPoints)
end
mem.hookcall(0x00426BB0, 1, 1, guardianAngelCharacterTrySubtractSpellPoints)

local function guardianAngelSetSpellBuff(d, def, spellBuffAddress, expireTimeLow, expireTimeHigh, skill, strength, overlay, caster)
	-- set correct duration
	local duration = guardianAngelPower * 300 + 3600
	expireTimeLow = Game.Time + duration * 128 / 30
	-- set spell buff with correct power
	def(spellBuffAddress, expireTimeLow, expireTimeHigh, skill, guardianAngelPower, overlay, caster)
end
mem.hookcall(0x00426C0F, 1, 6, guardianAngelSetSpellBuff)

local guardianAngelEnduranceBonus = 1000
local function changedCharacterCalcStatBonusByItems(d, def, characterPointer, statId)
	-- calculate default bonus
	local statBonus = def(characterPointer, statId)
	-- guardian angel buff
	local guardianAngelBuff = Party.SpellBuffs[const.PartyBuff.GuardianAngel]
	-- increase bonus to make it positive so character doesn't die with guardian angel
	if guardianAngelBuff.ExpireTime ~= 0 then
		statBonus = statBonus + guardianAngelEnduranceBonus
	end
	return statBonus
end
mem.hookcall(0x0047FF37, 1, 1, changedCharacterCalcStatBonusByItems)
mem.hookcall(0x0048875B, 1, 1, changedCharacterCalcStatBonusByItems)

local ADAPTIVE = string.lower(SETTINGS["AdaptiveMonsterMode"])

-- modified Monster Calculate Damage
-- supersedes skill-mod.lua:2658-2693
local function modifiedMonsterCalculateDamage(d, def, monsterPointer, attackType)

	-- get monster

	local monsterIndex, monster = GetMonster(d.edi)
if ((ADAPTIVE == "default") or (ADAPTIVE == "disabled")) then 
	Mlevel = Game.MonstersTxt[monster.Id].Level
modi = 1
else
Xlevel = Game.MonstersTxt[monster.Id].Level
Mlevel = monsterArray["Level"]
modi =  (1+Mlevel)/(1+Xlevel)
end
if Mlevel < 1 then
Mlevel = 1
end
if modi < 1 then
modi = 1
end
	-- execute original code

	local damage = def(monsterPointer, attackType)

	if attackType == 0 then
		-- primary attack is calculated correctly
		damage = damage * DifficultyModifier
		return damage
	elseif attackType == 1 then
		-- secondary attach uses attack1 DamageAdd
		-- replace Attack1.DamageAdd with Attack2.DamageAdd
		damage = (damage - monster.Attack1.DamageAdd + monster.Attack2.DamageAdd) * DifficultyModifier
		return damage
	elseif attackType == 2 and (monster.Spell == 44 or monster.Spell == 95) then
		-- don't recalculate Mass Distortion or Finger of Death
		return damage
	end

	-- calculate spell damage same way as for party

	local spellSkill, spellMastery = SplitSkill(monster.SpellSkill)
	if SETTINGS["ItemRework"]==true and SETTINGS["StatsRework"]==true then
	damage = Game.CalcSpellDamage(monster.Spell, spellSkill, spellMastery, 0) * DifficultyModifier * ((Mlevel/20)+0.75) * (Mlevel^1.2/1000+1) * modi
	else
	damage = Game.CalcSpellDamage(monster.Spell, spellSkill, spellMastery, 0) * DifficultyModifier * ((Mlevel/20)+0.75) * modi
	end
	
	return damage

end
mem.hookcall(0x00431D4F, 1, 1, modifiedMonsterCalculateDamage)
mem.hookcall(0x00431EE3, 1, 1, modifiedMonsterCalculateDamage)


local function setAttackSpellDescriptions(name)
	
end


-- spell overrides that depend on lodfiles/txtfiles loaded
function events.GameInitialized2()
	
	-- Spell Txt Iterator 
	for spellTxtId = 1, Game.SpellsTxt.high do
		
		-- Spell Name resolver
		spellName = Game.SpellsTxt[spellTxtId].Name
		spellTxtIds[spellName] = spellTxtId
		
		-- updated costs
		if not (spellCosts[spellName] == nil) then
			for _,mastery in pairs({"Normal","Expert","Master"}) do
				if not (spellCosts[spellName][mastery] == nil) then
					Game.SpellsTxt[spellTxtId]["SpellPoints"..mastery] = spellCosts[spellName][mastery]
					Game.Spells[spellTxtId]["SpellPoints"..mastery] = spellCosts[spellName][mastery]
				end
			end
		end
		
		
		-- updated spell descriptions; manual entries 
		if not (spellDescs[spellName] == nil) then
			for k,v in pairs(spellDescs[spellName]) do
				Game.SpellsTxt[spellTxtId][k] = v
			end
		end
		
		-- updated spell descriptions; attack spells
		if not (spellPowers[spellTxtId] == nil) then
			for k1,v1 in pairs(spellPowers[spellTxtId]) do
				for k2,v2 in pairs(training) do
					local vlow = spellPowers[spellTxtId][const[v2]].variableMin
					local vhigh = spellPowers[spellTxtId][const[v2]].variableMax
					local flow = spellPowers[spellTxtId][const[v2]].fixedMin
					local fhigh = spellPowers[spellTxtId][const[v2]].fixedMax
					
					Game.SpellsTxt[spellTxtId][k2] = string.format("Cost: %d SP.",Game.SpellsTxt[spellTxtId]["SpellPoints" .. k2])
					
					if (SHOW_DAMAGE_AS_DICE == false) then
						if not (fhigh == 0) then 
							Game.SpellsTxt[spellTxtId][k2] = Game.SpellsTxt[spellTxtId][k2] .. string.format("\nDamage: %d + %d-%d per point of skill", flow, vlow, vhigh)
						else
							Game.SpellsTxt[spellTxtId][k2] = Game.SpellsTxt[spellTxtId][k2] .. string.format("\nDamage: %d-%d per point of skill", vlow, vhigh)
						end
					elseif (SHOW_DAMAGE_AS_DICE == true) then 
						if not (fhigh == 0) then
							Game.SpellsTxt[spellTxtId][k2] = Game.SpellsTxt[spellTxtId][k2] .. string.format("\nDamage: d%d + %d", vhigh, fhigh)
						else
							Game.SpellsTxt[spellTxtId][k2] = Game.SpellsTxt[spellTxtId][k2] .. string.format("\nDamage: d%d", vhigh)
						end
					end	
				end
			end
		end

		
		
		-- spell resists
		
		if not (spellResists[spellName] == nil) then
			Game.SpellsTxt[spellTxtIds[spellName]].DamageType = spellResists[spellName]
		end
	end
	
	

	-- updated spell descriptions; protection spells not DoP
	for k,t in pairs(dayOfProtection) do
		setProtectionSpellDescriptions(k, t.School, t.Type)
	end
		
	-- updated spell descriptions; stat spells not DoG
	for k, t in pairs(dayOfTheGods) do
		setStatSpellDescriptions(k, t.School, t.Stat)
	end
	
	-- guardian angel
	
	
end
if not const.Spells then
	const.Spells = {
		TorchLight = 1,
		Haste = 5,
		Fireball = 6,
		MeteorShower = 9,
		Inferno = 10,
		Incinerate = 11,
		WizardEye = 12,
		Sparks = 15,
		Shield = 17,
		LightningBolt = 18,
		Implosion = 20,
		Fly = 21,
		Starburst = 22,
		Awaken = 23,
		WaterWalk = 27,
		TownPortal = 31,
		IceBlast = 32,
		LloydsBeacon = 33,
		Stun = 34,
		DeadlySwarm = 37,
		StoneSkin = 38,
		Blades = 39,
		StoneToFlesh = 40,
		RockBlast = 41,
		DeathBlossom = 43,
		MassDistortion = 44,
		Bless = 46,
		RemoveCurse = 49,
		Heroism = 51,
		RaiseDead = 53,
		SharedLife = 54,
		Resurrection = 55,
		CureInsanity = 64,
		PsychicShock = 65,
		CureWeakness = 67,
		Harm = 70,
		CurePoison = 72,
		CureDisease = 74,
		FlyingFist = 76,
		PowerCure = 77,
		DispelMagic = 80,
		DayOfTheGods = 83,
		PrismaticLight = 84,
		DivineIntervention = 88,
		Reanimate = 89,
		ToxicCloud = 90,
		DragonBreath = 97,
		Armageddon = 98,
		ShootFire = nil,  -- unused
	}

	table.copy({
		Shoot = 100,
		ShootFire = 101,
		ShootBlaster = 102,
	}, const.Spells, true)
	table.copy({
		FlameArrow = 2,
		ProtectionFromFire = 3,
		FireBolt = 4,
		RingOfFire = 7,
		FireBlast = 8,
		StaticCharge = 13,
		ProtectionFromElectricity = 14,
		FeatherFall = 16,
		Jump = 19,
		ColdBeam = 24,
		ProtectionFromCold = 25,
		PoisonSpray = 26,
		IceBolt = 28,
		EnchantItem = 29,
		AcidBurst = 30,
		MagicArrow = 35,
		ProtectionFromMagic = 36,
		TurnToStone = 42,
		SpiritArrow = 45,
		HealingTouch = 47,
		LuckyDay = 48,
		GuardianAngel = 50,
		TurnUndead = 52,
		Meditation = 56,
		RemoveFear = 57,
		MindBlast = 58,
		Precision = 59,
		CureParalysis = 60,
		Charm = 61,
		MassFear = 62,
		Feeblemind = 63,
		Telekinesis = 66,
		FirstAid = 68,
		ProtectionFromPoison = 69,
		CureWounds = 71,
		Speed = 73,
		Power = 75,
		CreateFood = 78,
		GoldenTouch = 79,
		Slow = 81,
		DestroyUndead = 82,
		HourOfPower = 85,
		Paralyze = 86,
		SunRay = 87,
		MassCurse = 91,
		Shrapmetal = 92,
		ShrinkingRay = 93,
		DayOfProtection = 94,
		FingerOfDeath = 95,
		MoonRay = 96,
		DarkContainment = 99,
		
	}, const.Spells, true)
end

-- allow setting healing spells power
local healingSpellPowers =						
{						
	[const.Spells.FirstAid] =					
	{					
		[const.Novice] = {fixedMin = 100, fixedMax = 100, variableMin = 15, variableMax = 15, },				
		[const.Expert] = {fixedMin = 100, fixedMax = 100, variableMin = 18, variableMax = 18, },				
		[const.Master] = {fixedMin = 100, fixedMax = 100, variableMin = 25, variableMax = 25, },				
	},					
	[const.Spells.RemoveCurse] =					
	{					
		[const.Novice] = {fixedMin = 300, fixedMax = 300, variableMin = 0, variableMax = 0, },				
		[const.Expert] = {fixedMin = 600, fixedMax = 600, variableMin = 0, variableMax = 0, },				
		[const.Master] = {fixedMin = 1000, fixedMax = 1000, variableMin = 0, variableMax = 0, },				
	},					
	[const.Spells.RemoveFear] =					
	{					
		[const.Novice] = {fixedMin = 200, fixedMax = 200, variableMin = 0, variableMax = 0, },				
		[const.Expert] = {fixedMin = 400, fixedMax = 400, variableMin = 0, variableMax = 0, },				
		[const.Master] = {fixedMin = 650, fixedMax = 650, variableMin = 0, variableMax = 0, },				
	},					
	[const.Spells.CureInsanity] =					
	{					
		[const.Novice] = {fixedMin = 15, fixedMax = 15, variableMin = 11, variableMax = 11, },				
		[const.Expert] = {fixedMin = 25, fixedMax = 25, variableMin = 15, variableMax = 15, },				
		[const.Master] = {fixedMin = 35, fixedMax = 35, variableMin = 19, variableMax = 19, },				
	},					
	[const.Spells.CurePoison] =					
	{						
		[const.Novice] = {fixedMin = 215, fixedMax = 215, variableMin = 0, variableMax = 0, },				
		[const.Expert] = {fixedMin = 430, fixedMax = 430, variableMin = 0, variableMax = 0, },				
		[const.Master] = {fixedMin = 675, fixedMax = 675, variableMin = 0, variableMax = 0, },				
	},					
	[const.Spells.HealingTouch] =					
	{					
		[const.Novice] = {fixedMin = 5, fixedMax = 5, variableMin = 12, variableMax = 12, },				
		[const.Expert] = {fixedMin = 10, fixedMax = 10, variableMin = 18, variableMax = 18, },				
		[const.Master] = {fixedMin = 15, fixedMax = 15, variableMin = 26, variableMax = 26, },				
	},					
	[const.Spells.CureWounds] =					
	{					
		[const.Novice] = {fixedMin = 10, fixedMax = 10, variableMin = 9, variableMax = 9, },				
		[const.Expert] = {fixedMin = 15, fixedMax = 15, variableMin = 12, variableMax = 12, },				
		[const.Master] = {fixedMin = 25, fixedMax = 25, variableMin = 16, variableMax = 16, },				
	},					
	[const.Spells.CureDisease] =					
	{					
		[const.Novice] = {fixedMin = 265, fixedMax = 265, variableMin = 0, variableMax = 0, },				
		[const.Expert] = {fixedMin = 475, fixedMax = 475, variableMin = 0, variableMax = 0, },				
		[const.Master] = {fixedMin = 745, fixedMax = 745, variableMin = 0, variableMax = 0, },				
	},					
	[const.Spells.SharedLife] =					
	{					
		[const.Novice] = {fixedMin = 0, fixedMax = 0, variableMin = 9, variableMax = 9, },				
		[const.Expert] = {fixedMin = 0, fixedMax = 0, variableMin = 12, variableMax = 12, },				
		[const.Master] = {fixedMin = 0, fixedMax = 0, variableMin = 15, variableMax = 15, },				
	},					
	[const.Spells.PowerCure] =					
	{					
		[const.Novice] = {fixedMin = 10, fixedMax = 10, variableMin = 3, variableMax = 3, },				
		[const.Expert] = {fixedMin = 10, fixedMax = 10, variableMin = 5, variableMax = 5, },				
		[const.Master] = {fixedMin = 10, fixedMax = 10, variableMin = 7, variableMax = 7, },				
	},					
	[const.Spells.Resurrection] =					
	{					
		[const.Novice] = {fixedMin = 50, fixedMax = 50, variableMin = 15, variableMax = 15, },				
		[const.Expert] = {fixedMin = 100, fixedMax = 100, variableMin = 20, variableMax = 20, },				
		[const.Master] = {fixedMin = 150, fixedMax = 150, variableMin = 25, variableMax = 25, },				
	},					
						
}

-- def is addHP()
local function modifiedHealCharacterWithSpell(d, def, targetPtr, amount)
	local t = getSpellQueueData(d.ebx, targetPtr)
	t.Result = amount
	events.call("HealingSpellPower", t)
	def(targetPtr, t.Result)
end

mem.hookcall(0x427E9D, 1, 1, modifiedHealCharacterWithSpell) -- first aid + maybe more
mem.hookcall(0x427FFB, 1, 1, modifiedHealCharacterWithSpell) -- healing touch + maybe more
mem.hookcall(0x4285D7, 1, 1, modifiedHealCharacterWithSpell) -- power cure + maybe more, power cure amount is per player
mem.hookcall(0x4299A9, 1, 1, modifiedHealCharacterWithSpell) -- moon ray + maybe more, moon ray amount is per player
mem.autohook(0x4271DC, function(d) -- shared life, amount is total
	local t = getSpellQueueData(d.ebx)
	t.Result = mem.u4[d.esp + 0x28]
	events.call("HealingSpellPower", t)
	mem.u4[d.esp + 0x28] = t.Result
end)

local function Randoms(min, max, count)
	local r = 0
	for i = 1, count do
		r = r + math.random(min, max)
	end
	return r
end

function events.HealingSpellPower(t)
	local power = healingSpellPowers[t.Spell]
	if power then
		local s, m = t.Skill, t.Mastery
		local entry = power[m]
		if t.Spell == const.Spells.SharedLife then
			t.Result = t.Result - t.Skill * t.Mastery + Randoms(entry.variableMin, entry.variableMax, s) + math.random(entry.fixedMin or 0, entry.fixedMax or 0)
		else
			t.Result = Randoms(entry.variableMin, entry.variableMax, s) + math.random(entry.fixedMin or 0, entry.fixedMax or 0)	
		end
		
		if SETTINGS["StatsRework"]==true then
		personality=t.Caster:GetPersonality()
		intellect=t.Caster:GetIntellect()
		bonus=math.max(personality,intellect)
			if t.Spell ~= 54 then
			t.Result = t.Result*(1+bonus/500)
			end
		luck=t.Caster:GetLuck()
		roll=math.random(1,1000)
			if roll<=luck+50 then
				if t.Spell ~= 54 then
				t.Result=t.Result*(1.5+bonus/500)
				end
			Game.ShowStatusText("Critical Heal")
			end
		end
	end
end

-- condition u8 is time when it was inflicted (taken from current game time)

-- removeConditionBySpell()
mem.hookfunction(0x484840, 1, 3, function(d, def, playerPtr, cond, timeLow,  timeHigh)
	local t = getSpellQueueData(d.ebx, playerPtr)
	t.Condition = cond
	-- time is calculated by subtracting spell's time limit from Game.Time, and then
	-- checking if result is <= condition affect time,
	-- so to calc spell time limit we need to subtract time from Game.Time
	
	-- params supplied to hookfunction() by d.getparams() are signed
	
	-- lua uses doubles, which can't represent accurately full range of 64bit integer values,
	-- that's why mem arrays are needed
	t.TimeLimit = Game.Time - mem.i8[d.esp + 0x8]
	events.call("RemoveConditionBySpell", t)
	mem.i8[d.esp + 0x8] = Game.Time - t.TimeLimit
	timeLow, timeHigh = mem.u4[d.esp + 0x8], mem.i4[d.esp + 0xC]
	def(playerPtr, cond, timeLow, timeHigh)
end)

-- always call removeConditionBySpell() for cure insanity

local weaknessFromCureConditionTmp = mem.StaticAlloc(1) -- temporary to store whether to inflict weakness
mem.asmpatch(0x427A90, [[
	je @noweak
	mov byte []] .. weaknessFromCureConditionTmp .. [[], 1
	jmp absolute 0x427A96
	@noweak:
	mov byte []] .. weaknessFromCureConditionTmp .. [[], 0
	jmp absolute 0x427AB5
]], 6)

mem.asmhook(0x427AFC, [[
	mov dword [esp + 0x24], 1
	cmp byte []] .. weaknessFromCureConditionTmp .. [[], 0
	je absolute 0x427B33
]])

-- for resurrection
mem.asmpatch(0x427309, [[
	push eax ; offset from first player start to affected player (to not recalculate it)
	je @noweak
	mov byte []] .. weaknessFromCureConditionTmp .. [[], 1
	jmp @exit
	@noweak:
	mov byte []] .. weaknessFromCureConditionTmp .. [[], 0
	@exit:
]])

-- remove death unconditionally
mem.asmhook(0x42732E, [[
	pop eax
	and dword [eax+0x90A324], 0
	and dword [eax+0x90A328], 0
]])

local spellToCondition = {
	[const.Condition.Cursed] = const.Spells.RemoveCurse,
	[const.Condition.Weak] = const.Spells.CureWeakness,
	[const.Condition.Asleep] = const.Spells.Awaken,
	[const.Condition.Afraid] = const.Spells.RemoveFear,
	[const.Condition.Insane] = const.Spells.CureInsanity,
	[const.Condition.Poison3] = const.Spells.CurePoison, -- poison and disease only 1 of 3 variants to not perform effect 3 times
	[const.Condition.Disease3] = const.Spells.CureDisease,
	[const.Condition.Paralyzed] = const.Spells.CureParalysis,
	[const.Condition.Dead] = const.Spells.RaiseDead,
	[const.Condition.Stoned] = const.Spells.StoneToFlesh,
	[const.Condition.Eradicated] = const.Spells.Resurrection,
}

function events.RemoveConditionBySpell(t)
	-- if eradication, we need to remove it here, otherwise subsequent heal doesn't work because of existing eradication
	-- (call happens before original code removes it)
	if t.Condition == const.Condition.Eradicated and t.Target.Eradicated ~= 0 and Game.Time - t.TimeLimit <= t.Target.Eradicated then
		t.Target.Eradicated = 0
	end
	local sp = spellToCondition[t.Condition]
	if sp then
		local t2 = table.copy(t)
		t2.TimeLimit, t2.Condition, t2.Result = nil, nil, 0
		events.call("HealingSpellPower", t2)
		if t2.Result > 0 then
			t.Target:AddHP(t2.Result)
		end
	end
end

-- MASS DISTORSION Fix

function events.CalcSpellDamage(t)
	if t.Spell == 44 then  -- Mass Distorsion
		t.Result = t.HP*0.15+t.HP*t.Skill*0.01
	end
end

-- Town Portal
mem.autohook(0x425D3E, function (d)
	local t = getSpellQueueData(d.ebx)
	t.Can = true
	events.cocall("CanCastTownPortal", t)
	if not t.Can then
		d:push(0x4297C1)
		return true
	end
end)


end