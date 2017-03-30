Scriptname _AS_PlayerRefScript extends ReferenceAlias  

_AS_QuestScript Property ASQuestScript Auto

GlobalVariable Property _AS_ArrowsInSheaf Auto  
GlobalVariable Property _AS_SheafValueMult Auto  


Keyword Property VendorItemArrow Auto
Perk Property _KLV_StashRefPerk Auto
Actor Property PlayerRef Auto
MiscObject Property _AS_RefreshToken Auto  
{This only exists so it can be added to the inventory to force a SkyUI refresh}


Ammo[] Property modifiedArrows Auto
Ammo[] Property tokenedArrows Auto


; internal
int arrowsInSheaf
float sheafValueMult
Actor vendor
ObjectReference vendorContainerRef


event OnInit()
	Maintenance()
endEvent

event OnPlayerLoadGame()
	ASQuestScript.Maintenance()
	Maintenance()
endEvent

event OnContainerActivated(Form akTargetRef)
	vendor = akTargetRef as Actor
	if (vendor)
		ASQuestScript.DebugStuff("Vendor set to " + vendor.GetLeveledActorBase().GetName())
	else
		ASQuestScript.DebugStuff("Could not set vendor")
	endIf
endEvent

event OnMenuOpen(String MenuName)
	If MenuName == "BarterMenu"
		GoToState("Bartering")
	EndIf
endEvent

function Maintenance()
	if (!playerRef.HasPerk(_KLV_StashRefPerk))
		playerRef.AddPerk(_KLV_StashRefPerk)
	endIf
	RegisterForModEvent("_KLV_ContainerActivated", "OnContainerActivated")
	RegisterForMenu("BarterMenu")
endFunction

State Bartering

	event OnMenuClose(String MenuName)
		If MenuName == "BarterMenu"
			GoToState("")
		EndIf
	endEvent

	Event OnBeginState()
		
		arrowsInSheaf = _AS_ArrowsInSheaf.GetValue() as int
		sheafValueMult = _AS_SheafValueMult.GetValue() as float
		
		if (!vendor)
			ASQuestScript.DebugStuff("Can't find barter target - aborting", "Can't find barter target; arrows will not be grouped", true)
			return
		endIf
		
		string vendorName = vendor.GetLeveledActorBase().GetName()
		ASQuestScript.DebugStuff("Bartering with " + vendorName + " - swap items")
		
		Faction[] vendorFactions = vendor.GetFactions(0, 127)
		int factionCount = vendorFactions.Length
		vendorContainerRef = None
		while (factionCount && !vendorContainerRef)
			factionCount -= 1
			vendorContainerRef = vendorFactions[factionCount].GetMerchantContainer()
		endWhile
		
		string msg
		if (vendorContainerRef)
			msg = "Found faction container " + vendorContainerRef.GetFormId()
		else
			vendorContainerRef = vendor
			msg = "Couldn't find faction container, using vendor directly"
		endIf
		ASQuestScript.DebugStuff(msg)
		
		DoArrowSwapsies("Player", playerRef)
		DoArrowSwapsies("Vendor", vendorContainerRef)
		
		playerRef.AddItem(_AS_RefreshToken, 1, true)
		
	EndEvent

	Event OnEndState()
	
		ASQuestScript.DebugStuff("Ended Bartering, swap items back")
		
		if (!vendorContainerRef)
			ASQuestScript.DebugStuff("Can't find barter container - aborting")
			return
		endIf
		
		DoArrowSwapsiesBack("Player", playerRef)
		DoArrowSwapsiesBack("Vendor", vendorContainerRef)
		
		playerRef.RemoveItem(_AS_RefreshToken, 1, true)
		
	EndEvent

endState


function DoArrowSwapsies(string asName, ObjectReference akContainer)
	int arrowTypeCount = _Q2C_Functions.GetNumItemsWithKeyword(akContainer, VendorItemArrow)
	ASQuestScript.DebugStuff(asName + ": has " + arrowTypeCount + " arrow types")
	if (arrowTypeCount > 127)
		arrowTypeCount = 127
	endIf
	while (arrowTypeCount)
		arrowTypeCount -= 1
		Ammo arrowForm = _Q2C_Functions.GetNthFormWithKeyword(akContainer, VendorItemArrow, arrowTypeCount) as Ammo
		Ammo tokenForm
		if (arrowForm)
			int iArrow = modifiedArrows.Find(arrowForm)
			if (iArrow < 0)
				iArrow = modifiedArrows.Find(None)
				modifiedArrows[iArrow] = arrowForm
				ASQuestScript.DebugStuff("New arrow type, form " + arrowForm.GetFormId() + ", mapped to token at index " + iArrow)
			endIf
			
			tokenForm = tokenedArrows[iArrow]
			if (!tokenForm)
				ASQuestScript.DebugStuff("Blank token at " + iArrow + " - BAD!", "Blank token at " + iArrow + " - BAD!")
				return
			endIf
			
			; update token data to match real arrow
			string arrowName = arrowForm.GetName()
			string arrowModelPath = arrowForm.GetWorldModelPath()
			float arrowWeight = arrowForm.GetWeight()
			int arrowValue = (arrowForm.GetGoldValue() * arrowsInSheaf * sheafValueMult) as int
			bool arrowIsBolt = arrowForm.IsBolt()
			Projectile arrowProjectile = arrowForm.GetProjectile()
			float arrowDamage = arrowForm.GetDamage()
			
			tokenForm.SetName(arrowName + " (sheaf of " + arrowsInSheaf + ")")
			tokenForm.SetWorldModelPath(arrowModelPath)
			tokenForm.SetWeight(arrowWeight)
			tokenForm.SetGoldValue(arrowValue)
			_Q2C_Functions.SetIsBolt(tokenForm, arrowIsBolt)
			_Q2C_Functions.SetProjectile(tokenForm, arrowProjectile)
			_Q2C_Functions.SetDamage(tokenForm, arrowDamage)
			
			int arrowCount = akContainer.GetItemCount(arrowForm)
			int sheafCount = (arrowCount / arrowsInSheaf) as int
			int removeCount = (sheafCount * arrowsInSheaf)
			
			akContainer.RemoveItem(arrowForm, removeCount, true)
			akContainer.AddItem(tokenForm, sheafCount, true)
			ASQuestScript.DebugStuff(asName + ": " + arrowName + " x" + arrowCount + " (" + sheafCount + " sheaves), removing " + removeCount + " (leaving " + (arrowCount - removeCount) + ")")
		else
			ASQuestScript.DebugStuff(asName + ": No Form at position " + arrowTypeCount)
		endIf
	endWhile
endFunction

function DoArrowSwapsiesBack(string asName, ObjectReference akContainer)
	int iArrow = modifiedArrows.Find(None)
	ASQuestScript.DebugStuff(asName + ", start at index " + iArrow)
	while (iArrow)
		iArrow -= 1
		Ammo arrowForm = modifiedArrows[iArrow]
		Ammo tokenForm = tokenedArrows[iArrow]
		if (arrowForm && tokenForm)
			int sheafCount = akContainer.GetItemCount(tokenForm)
			if (sheafCount > 0)
				int restoreCount = sheafCount * arrowsInSheaf
				akContainer.AddItem(arrowForm, restoreCount, true)
				akContainer.RemoveItem(tokenForm, sheafCount, true)
				ASQuestScript.DebugStuff(asName + ": " + arrowForm.GetName() + " x" + sheafCount + " sheaves, restoring " + restoreCount + " arrows")
			else
				ASQuestScript.DebugStuff(asName + ": No " + arrowForm.GetName() + " to restore (index " + iArrow + ")")
			endIf
		else
			ASQuestScript.DebugStuff(asName + ": Form or token at index " + iArrow + " not found (arrow " + arrowForm + ", token " + tokenForm + ") - cannot swap items back")
		endIf
	endWhile
endFunction
