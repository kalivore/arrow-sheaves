Scriptname _AS_QuestScript extends Quest  

_AS_PlayerRefScript Property ASPlayerRefScript  Auto  


float Property CurrentVersion = 0.0100 AutoReadonly
float previousVersion

bool Property DebugToFile Auto
GlobalVariable Property _AS_DebugToFile  Auto


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

	Debug.OpenUserLog("ArrowSheaves")

	RegisterForMenu("BarterMenu")
	
	DebugToFile = _AS_DebugToFile.GetValue() as bool

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


string function GetVersionAsString(float afVersion)

	string raw = afVersion as string
	int dotPos = StringUtil.Find(raw, ".")
	string major = StringUtil.SubString(raw, 0, dotPos)
	string minor = StringUtil.SubString(raw, dotPos + 1, 2)
	string revsn = StringUtil.SubString(raw, dotPos + 3, 2)
	return major + "." + minor + "." + revsn

endFunction

function DebugStuff(string asLogMsg, string asScreenMsg = "", bool abPrefix = false)

	if (DebugToFile)
		Debug.TraceUser("ArrowSheaves", asLogMsg)
	endIf
	if (asScreenMsg != "")
		if (abPrefix)
			asScreenMsg = "Arrow Sheaves - " + asScreenMsg
		endIf
		Debug.Notification(asScreenMsg)
	endIf

endFunction
