Scriptname _AS_PlayerRefScript extends ReferenceAlias  

_AS_QuestScript Property ASQuestScript  Auto

Keyword Property VendorItemArrow  Auto

GlobalVariable Property _AS_ArrowsInSheaf  Auto  
GlobalVariable Property _AS_SheafValueMult  Auto  

Actor Property PlayerRef Auto

Ammo[] Property modifiedArrows Auto
Ammo[] Property tokenedArrows Auto

int arrowsInSheaf
int sheafValueMult
ObjectReference vendorRef


event OnPlayerLoadGame()
	ASQuestScript.Maintenance()
endEvent


State Bartering

	Event OnBeginState()
		
		arrowsInSheaf = _AS_ArrowsInSheaf.GetValue() As int
		sheafValueMult = _AS_SheafValueMult.GetValue() As int
		
		Actor vendor = ASQuestScript.GetPlayerDialogueTarget()
		
		if (!vendor)
			ASQuestScript.DebugStuff("Can't find barter target - aborting")
			return
		endIf
		
		string vendorName = vendor.GetLeveledActorBase().GetName()
		ASQuestScript.DebugStuff("Bartering with " + vendorName + " - swap items")
		
		Faction[] vendorFactions = vendor.GetFactions(-128, 127)
		int factionCount = vendorFactions.Length
		vendorRef = None
		while (factionCount && !vendorRef)
			factionCount -= 1
			vendorRef = vendorFactions[factionCount].GetMerchantContainer()
		endWhile
		
		string msg
		if (vendorRef)
			msg = "Found faction container " + vendorRef.GetFormId()
		else
			vendorRef = vendor
			msg = "Couldn't find faction container, using vendor directly"
		endIf
		ASQuestScript.DebugStuff(msg, msg)
		
		DoArrowSwapsies("Player", playerRef)
		DoArrowSwapsies("Vendor", vendorRef)
		
		playerRef.AddItem(ASQuestScript._AS_RefreshToken)
		
	EndEvent

	Event OnEndState()
	
		ASQuestScript.DebugStuff("Ended Bartering, swap items back")
		
		if (!vendorRef)
			ASQuestScript.DebugStuff("Can't find barter container - aborting")
			return
		endIf
		
		DoArrowSwapsiesBack("Player", playerRef)
		DoArrowSwapsiesBack("Vendor", vendorRef)
		
		playerRef.RemoveItem(ASQuestScript._AS_RefreshToken)
		
	EndEvent

;/
	Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
		string name = akBaseItem.GetName()
		string open = ", not bartering, THIS SHOULD NEVER HAPPEN!"
		bool isArrow = akBaseItem.HasKeyword(VendorItemArrow)
		string sArrow = ""
		if (UI.IsMenuOpen("BarterMenu"))
			open = ", IS bartering"
		endIf
		if (isArrow)
			sArrow = " (arrow) "
		endIf
		if !akSourceContainer
;			Debug.Notification("Got " + aiItemCount + "x " + name + sArrow + " from the world" + open)
		elseif akSourceContainer == Game.GetPlayer()
;			Debug.Notification("The player gave me " + aiItemCount + "x " + name + sArrow + open)
		else
;			Debug.Notification("Got " + aiItemCount + "x " + name + sArrow + " from another container" + open)
		endIf
	endEvent
/;

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
			string tokenModelPath = arrowForm.GetWorldModelPath()
			int tokenValue = arrowForm.GetGoldValue() * sheafValueMult
			tokenForm.SetName(arrowName + " (sheaf of " + arrowsInSheaf + ")")
			tokenForm.SetWorldModelPath(tokenModelPath)
			tokenForm.SetGoldValue(tokenValue)
			
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
				ASQuestScript.DebugStuff(asName + ": Form " + arrowForm.GetFormId() + "; " + sheafCount + " sheaves, restoring " + restoreCount + " arrows")
			else
				ASQuestScript.DebugStuff(asName + ": No arrows of Id " + arrowForm.GetFormId() + " to restore (index " + iArrow + ")")
			endIf
		else
			ASQuestScript.DebugStuff(asName + ": Form or token at index " + iArrow + " not found (arrow " + arrowForm + ", token " + tokenForm + ") - cannot swap items back")
		endIf
	endWhile
endFunction
