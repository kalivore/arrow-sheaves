Scriptname _AS_PlayerRefScript extends ReferenceAlias  

_AS_QuestScript Property ASQuestScript  Auto

Keyword Property VendorItemArrow  Auto

GlobalVariable Property _AS_ArrowsInSheaf  Auto  
GlobalVariable Property _AS_SheafValueMult  Auto  

Actor Property PlayerRef Auto

Ammo[] modifiedArrows
string[] arrowNames
int arrowsInSheaf
int sheafValueMult
ObjectReference vendorRef

int[] playerArrowLeftovers
int[] vendorArrowLeftovers


event OnPlayerLoadGame()
	ASQuestScript.Maintenance()
endEvent


State Bartering

	Event OnBeginState()
		
		modifiedArrows = new Ammo[127]
		arrowNames = new string[127]
		playerArrowLeftovers = new int[127]
		vendorArrowLeftovers = new int[127]
		arrowsInSheaf = _AS_ArrowsInSheaf.GetValue() As int
		sheafValueMult = _AS_SheafValueMult.GetValue() As int
		
		Actor vendor = ASQuestScript.GetPlayerDialogueTarget()
		
		if (!vendor)
			ASQuestScript.DebugStuff("Can't find barter target - aborting")
			return
		endIf
		
		string vendorName = vendor.GetLeveledActorBase().GetName()
		ASQuestScript.DebugStuff("Bartering with " + vendorName + " - swap items", "Bartering with " + vendorName + " - swap items")
		
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
		
		DoArrowSwapsies("Player", playerRef, playerArrowLeftovers)
		DoArrowSwapsies("Vendor", vendorRef, vendorArrowLeftovers)
		
	EndEvent

	Event OnEndState()
	
		if (!vendorRef)
			ASQuestScript.DebugStuff("Can't find barter container - aborting")
			return
		endIf
		
		ASQuestScript.DebugStuff("Ended Bartering, swap items back")
		
		DoArrowSwapsiesBack("Player", playerRef, playerArrowLeftovers)
		DoArrowSwapsiesBack("Vendor", vendorRef, vendorArrowLeftovers)
		
		ResetArrowForms()
		
		modifiedArrows = new Ammo[127]
		arrowNames = new string[127]
		playerArrowLeftovers = new int[127]
		vendorArrowLeftovers = new int[127]
	
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

function DoArrowSwapsies(string asName, ObjectReference akContainer, int[] akStashArray)
	int arrowTypeCount = _Q2C_Functions.GetNumItemsWithKeyword(akContainer, VendorItemArrow)
	ASQuestScript.DebugStuff(asName + ": has " + arrowTypeCount + " arrow types")
	int iArrow = 0
	while (arrowTypeCount)
		arrowTypeCount -= 1
		Ammo arrowForm = _Q2C_Functions.GetNthFormWithKeyword(akContainer, VendorItemArrow, arrowTypeCount) as Ammo
		if (arrowForm)
			string msg
			iArrow = modifiedArrows.Find(arrowForm)
			if (iArrow < 0)
				iArrow = modifiedArrows.Find(None)
				modifiedArrows[iArrow] = arrowForm
				arrowNames[iArrow] = arrowForm.GetName()
				string newName = arrowForm.GetName() + " (sheaf of " + arrowsInSheaf + ")"
				int newValue = arrowForm.GetGoldValue() * sheafValueMult
				arrowForm.SetName(newName)
				arrowForm.SetGoldValue(newValue)
				msg = asName + ": Form " + arrowForm.GetFormId() + " added at index " + iArrow
			else
				msg = asName + ": Form " + arrowForm.GetFormId() + " present at index " + iArrow
			endIf
			
			int arrowCount = akContainer.GetItemCount(arrowForm)
			int sheafCount = (arrowCount / arrowsInSheaf) as int
			int stashCount = arrowCount - (sheafCount * arrowsInSheaf)
			
			if (sheafCount < 1)
				sheafCount = 1
				stashCount = 0
			endIf
			
			int removeCount = arrowCount - sheafCount
			akStashArray[iArrow] = stashCount
			
			msg += "; " + arrowCount + " arrows (" + sheafCount + " sheaves); removing " + removeCount + "; stashing " + stashCount
			ASQuestScript.DebugStuff(msg)
			akContainer.RemoveItem(arrowForm, removeCount, true)
		else
			ASQuestScript.DebugStuff(asName + ": No Form at position " + arrowTypeCount)
		endIf
	endWhile
endFunction

function ResetArrowForms()
	int iArrow = modifiedArrows.Find(None)
	while (iArrow)
		iArrow -= 1
		Ammo arrowForm = modifiedArrows[iArrow]
		if (arrowForm)
			string origName = arrowNames[iArrow]
			int origValue = (arrowForm.GetGoldValue() / sheafValueMult) as int
			arrowForm.SetName(origName)
			arrowForm.SetGoldValue(origValue)
			ASQuestScript.DebugStuff("Form at index " + iArrow + " reset")
		else
			ASQuestScript.DebugStuff("Form at index " + iArrow + " not found - cannot change back :(")
		endIf
	endWhile
endFunction

function DoArrowSwapsiesBack(string asName, ObjectReference akContainer, int[] akStashArray)
	int iArrow = modifiedArrows.Find(None)
	while (iArrow)
		iArrow -= 1
		Ammo arrowForm = modifiedArrows[iArrow]
		if (arrowForm)
			int stashCount = akStashArray[iArrow]
			int sheafCount = akContainer.GetItemCount(arrowForm)
			if (stashCount > 0 || sheafCount > 0)
				int arrowCount = sheafCount * arrowsInSheaf
				int restoreCount = arrowCount + stashCount - sheafCount
				
				ASQuestScript.DebugStuff(asName + ": Form " + arrowForm.GetFormId() + "; " + sheafCount + " sheaves (" + arrowCount + " arrows); stashed " + stashCount + "; restoring " + restoreCount)
				akContainer.AddItem(arrowForm, restoreCount, true)
			else
				ASQuestScript.DebugStuff(asName + ": No arrows of Id " + arrowForm.GetFormId() + " to restore (index " + iArrow + ")")
			endIf
		else
			ASQuestScript.DebugStuff(asName + ": Form at index " + iArrow + " not found - cannot swap items")
		endIf
	endWhile
endFunction
