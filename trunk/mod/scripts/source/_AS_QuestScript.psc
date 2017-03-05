Scriptname _AS_QuestScript extends Quest  

_AS_PlayerRefScript Property ASPlayerRefScript  Auto  

float Property CurrentVersion = 0.0100 AutoReadonly
bool Property DebugToFile Auto

float previousVersion

event OnInit()
	Update()
endEvent

function Update()

	if (CurrentVersion != PreviousVersion)

		; version-specific updates


		; notify current version
		string msg = "Arrow Sheaves"
		if (PreviousVersion > 0)
			msg += " updated from v" + GetVersionAsString(PreviousVersion) + " to "
		else
			msg += " running "
		endIf
		msg += "v" + GetVersionAsString(CurrentVersion)
		DebugStuff(msg, msg, true)

		PreviousVersion = CurrentVersion
	endIf

	Maintenance()

endFunction

Function Maintenance()

DebugToFile = true
	RegisterForMenu("BarterMenu")

EndFunction


event OnMenuOpen(String MenuName)
	If MenuName == "BarterMenu"
		ASPlayerRefScript.GoToState("Bartering")
	EndIf
endEvent

event OnMenuClose(String MenuName)
	If MenuName == "BarterMenu"
		ASPlayerRefScript.GoToState("")
	EndIf
endEvent


Actor function GetPlayerDialogueTarget()

	Actor kPlayerDialogueTarget
	Actor kPlayerRef = Game.GetPlayer()
	int iLoopCount = 10
	while iLoopCount > 0
		iLoopCount -= 1
		kPlayerDialogueTarget = Game.FindRandomActorFromRef(kPlayerRef , 200.0)
		if kPlayerDialogueTarget != kPlayerRef && kPlayerDialogueTarget.IsInDialogueWithPlayer() 
			return kPlayerDialogueTarget
		endIf
	endWhile
	
	return None
	
endFunction


string function GetVersionAsString(float afVersion)

	string raw = afVersion as string
	int dotPos = StringUtil.Find(raw, ".")
	string major = StringUtil.SubString(raw, 0, dotPos)
	string minor = StringUtil.SubString(raw, dotPos + 1, 2)
	string revsn = StringUtil.SubString(raw, dotPos + 3, 2)
	return major + "." + minor + "." + revsn

endFunction

function DebugStuff(string asLogMsg, string asScreenMsg = "", bool abFpPrefix = false)

	if (DebugToFile)
		Debug.Trace("[ArrowSheaves] " + asLogMsg)
	endIf
	if (asScreenMsg != "")
		if (abFpPrefix)
			asScreenMsg = "Arrow Sheaves - " + asScreenMsg
		endIf
		Debug.Notification(asScreenMsg)
	endIf

endFunction


MiscObject Property _AS_RefreshToken  Auto  
{This only exists so it can be added to the inventory to force a SkyUI refresh}
