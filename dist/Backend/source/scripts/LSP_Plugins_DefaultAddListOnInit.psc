Scriptname LSP_Plugins_DefaultAddListOnInit Extends Package
{Calls LSP_ApiFunctions' AddToList() function OnInit}

LSP_ApiFunctions Property LinearSpellProgressionBackendQuest  Auto
{LSP Backend Quest (which has the script LSP_ApiFunctions attached to it)}
FormList Property listToAdd  Auto
{FormList to add to the Master List OnInit}
Bool Property addToTomesList = True Auto
{Add the tomes to the tomes list?}

Event OnInit()
    LinearSpellProgressionBackendQuest.AddToList(listToAdd, addToTomesList)
    ;Debug.MessageBox("LSP Quest Started Successfully")
EndEvent
