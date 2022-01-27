Scriptname LSPStartQuestOnInit Extends Package
{Starts the specified quest on script initiation.}

Quest Property QuestToStart  Auto

Event OnInit()
    Debug.Trace("[LSP] Quest Started Successfully: " + QuestToStart.Start())
EndEvent
