local TXT = Localize{
	[20] = "Are you sure? (yes/no)",
	[21] = "yes"
}
table.copy(TXT, evt.str, true)


-----------------------
----RESET
-----------------------

AEC(647, 666)
Map.Facets[647].BitmapId=14

evt.hint[666] = "New World"
evt.map[666] = function()
if evt.Cmp("Awards", 61) then
	Message("In the new World your quests and awards will be resetted, there is no way back. (Changing settings to 255 mod is required after entering)")
	if evt.Question{Question = 20, Answer1 = 21} then   

	for i=1,60 do
		evt.ForPlayer("All")
		evt.Subtract("Awards", i)
	end

	--reset class and skills to base
	for i= 0,3 do
		for v= 0,20 do
			Party[i].Skills[v]=Party[i].Skills[v]%64
		end
		Party[i].Class=Party[i].Class-Party[i].Class%3
	end
	

	--QUEST ITEM RESET
	evt.ForPlayer("All")
	evt.Subtract("Inventory", 433)
	evt.Subtract("Inventory", 434)
	for i=448,462 do
	evt.ForPlayer("All")
	evt.Subtract("Inventory", i)
	end
	for i=464,578 do
	evt.ForPlayer("All")
	evt.Subtract("Inventory", i)
	end
	for i=448,462 do
	evt.ForPlayer("All")
	evt.Subtract("Inventory", i)
	end
	for i=464,578 do
	evt.ForPlayer("All")
	evt.Subtract("Inventory", i)
	end
	for i=448,462 do
	evt.ForPlayer("All")
	evt.Subtract("Inventory", i)
	end
	for i=464,578 do
	evt.ForPlayer("All")
	evt.Subtract("Inventory", i)
	end

	--NPC RESET
	for i=0,398 do 
		Game.NPC[i].House=Game.NPCDataTxt[i].House
		for j = 0, 2 do Game.NPC[i].Events[j] = Game.NPCDataTxt[i].Events[j] 
		end 
	end
	
	--RESET QBITS CODE

		for i=1, 512 do
			Party.QBits[i-1] = false
		end
		Party.QBits[81] = true
		Party.QBits[181] = true

	--remove 1st promotions
		evt.SetNPCTopic{NPC = 6, Index = 1, Event = 70}   
		evt.SetNPCTopic{NPC = 5, Index = 1, Event = 59} 
		evt.SetNPCTopic{NPC = 4, Index = 1, Event = 16} 
		evt.SetNPCTopic{NPC = 16, Index = 1, Event = 38} 
		evt.SetNPCTopic{NPC = 15, Index = 1, Event = 93}
		evt.SetNPCTopic{NPC = 14, Index = 1, Event = 84}  
		evt.Add("Items",505)
		evt.Set("ReputationIs", 0)
		Game.Time=Game.Time+const.Year*3-Game.Time%const.Day+const.Hour*9
		evt.MoveToMap{X = -9728, Y = -11319, Z = 0, Direction = 512, LookAngle = 0, SpeedZ = 0,HouseId = 0, Icon = 0, Name = "Oute3.odm"}
	end


	end
end