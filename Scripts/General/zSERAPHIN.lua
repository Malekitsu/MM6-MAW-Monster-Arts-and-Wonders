SERAPHIN=SETTINGS["PaladinAsSeraphin"]
BERSERKER=SETTINGS["PaladinAsBerserker"]
if BERSERKER==false then
if SERAPHIN==true then

--body magic will increase healing done on attack
function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()
	if data.Player and (data.Player.Class==const.Class.Hero or data.Player.Class==const.Class.Crusader or data.Player.Class==const.Class.Paladin) and t.DamageKind==0 and data.Object==nil then
		--get body
		body=data.Player.Skills[const.Skills.Body]
		rankBonus=1
		if body>=64 then 
		body=body-64
		rankBonus=1.5
		end
		if body>=64 then
		body=body-64
		rankBonus=2
		end
		--get mastery
		mastery=data.Player.Skills[const.Skills.Thievery]
		if mastery>=64 then 
		mastery=mastery-64
		end
		if mastery>=64 then
		mastery=mastery-64
		end
		rankBonusMH=1
if data.Player.Class==const.Class.Crusader then
		rankBonusMH=2
end
if data.Player.Class==const.Class.Hero then
		rankBonusMH=3
end
				--get light
		light=data.Player.Skills[const.Skills.Light]
		rankBonus=1
		if light>=64 then 
		light=light-64
		rankBonus=1
		end
		if light>=64 then
		light=light-64
		rankBonus=1
		end
		--get spirit
		spirit=data.Player.Skills[const.Skills.Spirit]
		rankBonus=1
		if body>=64 then 
		spirit=spirit-64
		rankBonus=1
		end
		if spirit>=64 then
		spirit=spirit-64
		rankBonus=1
		end
		
		--bunch of code for healing most injured player
		function indexof(table, value)
		for i, v in ipairs(table) do
		if v == value then
		return i
		end
		end
		return nil
		end

		-- Define the variables
		if Party[0].Dead==0 and Party[0].Eradicated==0 then
		a = Party[0].HP/Party[0]:GetFullHP()
		else 
		a=2
		end
		if Party[1].Dead==0 and Party[1].Eradicated==0 then
		b = Party[1].HP/Party[1]:GetFullHP()
		else
		b=2
		end
		if Party[2].Dead==0 and Party[2].Eradicated==0 then
		c = Party[2].HP/Party[2]:GetFullHP()
		else
		c=2
		end
		if Party[3].Dead==0 and Party[3].Eradicated==0 then
		d = Party[3].HP/Party[3]:GetFullHP()
		else
		d=2
		end

		-- Find the maximum value and its position
		min_value = math.min(a, b, c, d)
		min_index = indexof({a, b, c, d}, min_value)
		min_index = min_index - 1
		--Calculate heal value and apply
		healValue=body*rankBonus+mastery*rankBonusMH+math.max(4*spirit-2*light-mastery*2+body, 0)
		evt[min_index].Add("HP",healValue)		
		--bug fix
		if Party[min_index].HP>0 then
		Party[min_index].Unconscious=0
		end
	end
		
end

--light and mastery increases melee damage

function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()
	if data.Player and (data.Player.Class==const.Class.Hero or data.Player.Class==const.Class.Crusader or data.Player.Class==const.Class.Paladin) and t.DamageKind==0 and data.Object==nil then
		--get light
		light=data.Player.Skills[const.Skills.Light]
		rankBonus=1
		if light>=64 then 
		light=light-64
		rankBonus=1.5
		end
		if light>=64 then
		light=light-64
		rankBonus=2
		end
		--get mastery
		mastery=data.Player.Skills[const.Skills.Thievery]
		if mastery>=64 then 
		mastery=mastery-64
		end
		if mastery>=64 then
		mastery=mastery-64
		end
		rankBonusMD=1
if data.Player.Class==const.Class.Crusader then
		rankBonusMD=1.5
end
if data.Player.Class==const.Class.Hero then
		rankBonusMD=3
end


		t.Result=t.Result+light*rankBonus+(mastery*rankBonusMD)
		end
end

--AUTORESS SKILL

function events.LoadMap(wasInGame)
vars.divineProtectionCooldown=vars.divineProtectionCooldown or {}
end



function events.CalcDamageToPlayer(t)
	if (t.Player.Class==const.Class.Hero or t.Player.Class==const.Class.Crusader or t.Player.Class==const.Class.Paladin) and t.Player.Unconscious==0 and t.Player.Dead==0 and t.Player.Eradicated==0 then
		if vars.divineProtectionCooldown[t.PlayerIndex]==nil then
			vars.divineProtectionCooldown[t.PlayerIndex]=0
		end		
			if t.Result>=t.Player.HP and Game.Time>vars.divineProtectionCooldown[t.PlayerIndex] then
				totMana=t.Player:GetFullSP()
				currentMana=t.Player.SP
				treshold=totMana/4
				if currentMana>=treshold then
				t.Player.SP=t.Player.SP-(totMana/4)
				--calculate healing
				mastery=t.Player.Skills[const.Skills.Thievery]
					if mastery>=64 then 
					mastery=mastery-64
					end
					if mastery>=64 then
					mastery=mastery-64
					end
					heal=(totMana/4)*(1+mastery*0.05)
					evt[t.PlayerIndex].Add("HP",heal)
					vars.divineProtectionCooldown[t.PlayerIndex] = Game.Time + const.Minute * 150
					Game.ShowStatusText("Divine Protection saves you from lethal damage")

				end
			end	
		
	end
end

-- DIVINE SHIELD 
--tables
function events.LoadMap(wasInGame)
vars.divineShieldTime=vars.divineShieldTime or {}
vars.divineShieldCooldown=vars.divineShieldCooldown or {}
vars.divineShield=vars.divineShield or {}
end
--end table
function events.CalcDamageToPlayer(t)
	if (t.Player.Class==const.Class.Hero or t.Player.Class==const.Class.Crusader or t.Player.Class==const.Class.Paladin) and t.Player.Unconscious==0 and t.Player.Dead==0 and t.Player.Eradicated==0  and vars.divineShield[t.PlayerIndex]==1 then
	t.Result=0
	Game.ShowStatusText("Immune")
	end
end
--activation button	
function Keys.E(t)
CPI=Game.CurrentPlayer
	if CPI==-1 then
	return
	end
if Party[CPI].Class==const.Class.Hero or Party[CPI].Class==const.Class.Crusader or Party[CPI].Class==const.Class.Paladin then
	if vars.divineShield[CPI]==1 then
	Game.ShowStatusText(string.format("Divine Shield is already Active, expiring in %s seconds. ",math.max(math.floor((vars.divineShieldTime[CPI] - Game.Time) / 128 * 10) / 10,0)))
		else if vars.divineShieldCooldown[CPI] ~= nil and vars.divineShieldCooldown[CPI] > Game.Time then
		Game.ShowStatusText(string.format("Divine Shield is on cooldown. Try again in %s seconds.",math.floor((vars.divineShieldCooldown[CPI] - Game.Time) / 128 * 10) / 10))
			else
				cost=Party[CPI].LevelBase+5
				if Party[CPI].SP>cost then
				Party[CPI].SP=Party[CPI].SP-cost
				Game.ShowStatusText(string.format("%s activates 'Divine Shield'",Party[CPI].Name))
				vars.divineShield[CPI] = 1
				vars.divineShieldTime[CPI] = Game.Time + const.Minute * 6
				vars.divineShieldCooldown[CPI] = Game.Time + const.Minute * 90
				else 
				Game.ShowStatusText(string.format("Not enought mana (%s mana needed)",cost))
				end
			end
		end
	end
end
--
function events.LoadMap(wasInGame)
local function divineShieldTimer() 
	for i = 0, 3 do
		if vars.divineShieldTime[i]~=nil and vars.divineShield[i]~=0 then
			if vars.divineShieldTime[i]<Game.Time then
			vars.divineShield[i]=0
			Game.ShowStatusText(string.format("%s's Divine Shield effect expired",Party[i].Name))
			end 
		end
	end
end
Timer(divineShieldTimer, const.Minute/2) 
end
--reduced damage when in divine shield
function events.CalcDamageToMonster(t)
	 data=WhoHitMonster()
	 ind=data.Player:GetIndex()
		if data.Player and (data.Player.Class==const.Class.Hero or data.Player.Class==const.Class.Crusader or data.Player.Class==const.Class.Paladin) and vars.divineShield[ind]==1 then
			t.Result=t.Result/2
		end
end

-------------end of divine shield---------------

---deactivate offhand weapon
function events.CalcDamageToMonster(t)
	 data=WhoHitMonster()
	 ind=data.Player:GetIndex()
		if data.Player and (data.Player.Class==const.Class.Hero or data.Player.Class==const.Class.Crusader or data.Player.Class==const.Class.Paladin) and data.Player.ItemExtraHand >= 1 and data.Player.ItemExtraHand <= 14 or (data.Player.ItemExtraHand ==403 or data.Player.ItemExtraHand >= 415) then
			t.Result=0
			Message("Seraphin aren't able to dual wield")
		end
end



function events.GameInitialized2()
Game.ClassKinds.StartingSkills[1][const.Skills.Plate] = 3
Game.ClassKinds.StartingSkills[1][const.Skills.Light] = 1
Game.ClassKinds.StartingSkills[1][const.Skills.Sword] = 1
Game.ClassKinds.StartingSkills[1][const.Skills.Axe] = 0
Game.ClassKinds.StartingSkills[1][const.Skills.Staff] = 0
Game.ClassKinds.StartingSkills[1][const.Skills.Leather] = 3
Game.ClassKinds.StartingSkills[1][const.Skills.Chain] = 2
Game.ClassKinds.StartingSkills[1][const.Skills.Mace] = 3
Game.ClassKinds.StartingSkills[1][const.Skills.Thievery] = 1


    Game.Classes.HPFactor[const.Class.Paladin] = 3
	Game.Classes.SPFactor[const.Class.Paladin] = 1
	Game.Classes.HPFactor[const.Class.Crusader] = 4
	Game.Classes.SPFactor[const.Class.Crusader] = 2
	Game.Classes.HPFactor[const.Class.Hero] = 5
	Game.Classes.SPFactor[const.Class.Hero] = 3
--LORE BONUS Seraphin are blessed with divine powers, giving him +20 starting hp and +10 mana and light skill


Game.ClassNames[const.Class.Paladin]="Seraphin"
Game.ClassNames[const.Class.Crusader]="Angel"
Game.ClassNames[const.Class.Hero]="Archangel"
Game.ClassDescriptions[const.Class.Paladin] = "Seraphin is a divine warrior, blessed by the gods with otherworldly powers that set him apart from mortal fighters. His origins are shrouded in mystery, but it is said that he was chosen by the divine to carry out their will on the mortal plane. Some whisper that he was born from the union of a mortal and an angel, while others believe that he was created by the gods themselves. Regardless of his origins, there is no denying the power that Seraphin wields, and his presence on the battlefield is a testament to the will of the divine.\n\nStats:\n+20 starting HP and +10 mana points\nProficiency in Plate, Sword, Mace, and Shield (offhand must be disabled)\n3 HP and 2 mana points gained per level\n\nAbilities:\n\nGods Wrath:Attacks deal extra damage based on Light skill (2 damage added per point in Light and increased by 4 per mastery point)\n\nHoly Strikes: Attacking will heal the most injured party member based on Body skill (2 points per point in Body and increased by 3 per mastery point) - a further 4 points of healing is added pr rank in spirit, however this number is reduced by 2 pr rank in light and masteryand increased by 1 pr rank in Body magic, thus if you rank Body and Spirit and keep Light at minimum and mastery low your attacks will heal a lot but do low damage.\n\nDivine Protection: converts up to 25% of mana into self-healing when facing lethal attacks (increased by 5% per mastery point), 5 minutes cooldown.\n\nDivine Shield: Grants the caster invincibility for 12 seconds, rendering them impervious to all forms of harm, but dealing half damage. This ability has a cooldown of 3 minutes."
Game.ClassDescriptions[const.Class.Crusader] = "The Angel, the ultimate form of seraphic evolution. Radiant and powerful, they wield holy magic with grace, and their wings span great distances as they soar through the heavens. Their mere presence fills mortals with awe and courage, and they are protectors of the weak and defenders of the just. Truly, the Angel is a magnificent being, a testament to the glory of the divine.\n\nStats:\nProficiency in Plate, Sword, Mace, and Shield (offhand must be disabled)\n4 HP and 3 mana points gained per level\n\nAbilities:\n\nGods Wrath:Attacks deal extra damage based on Light skill (2 damage added per point in Light and increased by 4 per mastery point)\n\nHoly Strikes: Attacking will heal the most injured party member based on Body skill (2 points per point in Body and increased by 3 per mastery point)\n\nDivine Protection: converts up to 25% of mana into self-healing when facing lethal attacks (increased by 5% per mastery point), 5 minutes cooldown.\n\nDivine Shield: Grants the caster invincibility for 12 seconds, rendering them impervious to all forms of harm, but dealing half damage. This ability has a cooldown of 3 minutes."
Game.ClassDescriptions[const.Class.Hero] = "The Archangel, the pinnacle of angelic evolution. Radiant and powerful, their wings shine like the sun, and their divine presence inspires awe and reverence. They wield holy magic with effortless skill, their swords and shields imbued with the force of the cosmos. As the guardians of the divine realm, their judgment is swift and true, their mercy boundless. The Archangel is the embodiment of divine justice and the ultimate manifestation of angelic might.\n\nStats:\nProficiency in Plate, Sword, Mace, and Shield (offhand must be disabled)\n\nAbilities:\n\nGods Wrath:Attacks deal extra damage based on Light skill (2 damage added per point in Light and increased by 4 per mastery point)\n\nHoly Strikes: Attacking will heal the most injured party member based on Body skill (2 points per point in Body and increased by 3 per mastery point)\n\nDivine Protection: converts up to 25% of mana into self-healing when facing lethal attacks (increased by 5% per mastery point), 5 minutes cooldown.\n\nDivine Shield: Grants the caster invincibility for 12 seconds, rendering them impervious to all forms of harm, but dealing half damage. This ability has a cooldown of 3 minutes."
end
end
end
