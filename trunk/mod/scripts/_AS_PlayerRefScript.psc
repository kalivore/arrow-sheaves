Scriptname _AS_PlayerRefScript extends ReferenceAlias  

_AS_QuestScript Property ASQuestScript  Auto

Keyword Property VendorItemArrow  Auto

GlobalVariable Property _AS_ArrowsInSheaf  Auto  
GlobalVariable Property _AS_SheafValueMult  Auto  

Actor Property PlayerRef Auto

Ammo[] modifiedArrows

int[] playerArrowLeftovers
string[] playerArrowNames

int[] vendorArrowLeftovers
string[] vendorArrowNames

event OnPlayerLoadGame()
	ASQuestScript.Maintenance()
endEvent


State Bartering

	Event OnBeginState()
	
		Actor vendor = ASQuestScript.GetPlayerDialogueTarget()
		
		if (!vendor)
			ASQuestScript.DebugStuff("Can't find barter target - aborting")
			return
		endIf
		
		string vendorName = vendor.GetLeveledActorBase().GetName()
		ASQuestScript.DebugStuff("Bartering with " + vendorName + " - swap items", "Bartering with " + vendorName + " - swap items")
		
		Faction[] vendorFactions = vendor.GetFactions(-128, 127)
		int factionCount = vendorFactions.Length
		ObjectReference vendorRef
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
		
		int arrowsInSheaf = _AS_ArrowsInSheaf.GetValue() As Int
		int sheafValueMult = _AS_SheafValueMult.GetValue() As Int
		
		DoArrowSwapsies(playerRef, playerArrowLeftovers, playerArrowNames, arrowsInSheaf, sheafValueMult)
		DoArrowSwapsies(vendorRef, vendorArrowLeftovers, vendorArrowNames, arrowsInSheaf, sheafValueMult)
		
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

	Event OnEndState()
	
		ASQuestScript.DebugStuff("Ended Bartering, swap items")
		int arrowsInSheaf = _AS_ArrowsInSheaf.GetValue() As Int
		int sheafValueMult = _AS_SheafValueMult.GetValue() As Int
		
	EndEvent

endState

function DoArrowSwapsies(ObjectReference akContainer, int[] akLeftoversArray, string[] akNamesArray, int aiArrowsInSheaf, int aiSheafValueMult)
	int arrowTypeCount = _Q2C_Functions.GetNumItemsWithKeyword(akContainer, VendorItemArrow)
	ASQuestScript.DebugStuff("Found " + arrowTypeCount + " arrow types", "Found " + arrowTypeCount + " arrow types")
	akLeftoversArray = Utility.CreateIntArray(arrowTypeCount)
	while (arrowTypeCount)
		arrowTypeCount -= 1
		Ammo arrowForm = _Q2C_Functions.GetNthFormWithKeyword(akContainer, VendorItemArrow, arrowTypeCount) as Ammo
		if (arrowForm)
			if (modifiedArrows.Find(arrowForm) < 0)
				modifiedArrows[arrowTypeCount] = arrowForm
				
				int arrowCount = akContainer.GetItemCount(arrowForm)
				int sheafCount = (arrowCount / aiArrowsInSheaf) as int
				int removeCount = arrowCount - sheafCount
				int leftoverCount = arrowCount - (sheafCount * aiArrowsInSheaf)
				
				ASQuestScript.DebugStuff("Total " + arrowCount + "; removing " + removeCount + "; leaving " + leftoverCount)
				
				akLeftoversArray[arrowTypeCount] = leftoverCount
				akNamesArray[arrowTypeCount] = arrowForm.GetName()
				
				akContainer.RemoveItem(arrowForm, removeCount, true)
				arrowForm.SetGoldValue(arrowForm.GetGoldValue() * aiSheafValueMult)
				arrowForm.SetName(arrowForm.GetName() + " (sheaf of " + aiArrowsInSheaf + ")")
			else
				ASQuestScript.DebugStuff("Form at index " + arrowTypeCount + " already modified")
			endIf
		else
			ASQuestScript.DebugStuff("No Form at index " + arrowTypeCount)
		endIf
	endWhile
endFunction
