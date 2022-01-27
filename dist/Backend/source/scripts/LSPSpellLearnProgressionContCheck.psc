Scriptname LSPSpellLearnProgressionCheck Extends ReferenceAlias
{Main script for the Linear Spell Progression system}

; All Debug.Trace() statements assume SKSE is present. If it is not, the script will not compile anyway.

FormList Property LSPMasterTomesList  Auto
{An unordered list of all spell tomes supported by the Linear Spell Progression system.
This script WILL remove forms from this list. You have been warned!}
FormList Property LSPMasterList Auto
{The list of many lists

See https://github.com/BellCubeDev/LinearSpellProgression/wiki/Creating-A-Plugin for more ;)};/ 😉
  ========================|                |=========================
  ========================|     Format     |========================
  ========================|                |=========================

  Master List (in LinearSpellProgression.esl)
    YOUR Plugin!
        Spell Tomes
            Some Spell Tome (Repeatable)
            Some Spell Tome (Repeatable)
            Some Spell Tome (Repeatable)
        Spells
            Matching Spell (repeatable)
            Matching Spell (repeatable)
            Matching Spell (repeatable)
        Prerequisites
            Spell 0's Prerequisites
                Single Spell OR
                Requirements List
                    Some Spell (Repeatable)
                    Some Spell (Repeatable)
                    Some Spell (Repeatable)
            Spell 1's Prerequisites
                Single Spell OR
                Requirements List
                    Some Spell (Repeatable)
                    Some Spell (Repeatable)
                    Some Spell (Repeatable)
            Spell 2's Prerequisites
                Single Spell OR
                Requirements List
                    Some Spell (Repeatable)
                    Some Spell (Repeatable)
                    Some Spell (Repeatable)

/;


Message Property asMessageNoSKSE  Auto
{Message to display when a spell's requirements are not met
Only used when SKSE is **not** present!

TODO: Alias Madness!!!
}

Message Property asMessageSKSE  Auto
{Text to display when a spell's requirements are not met
Unfulfilled requirements are seperated by line breaks and appended to the end of the message.
The first occurance of "%s%" will be replaced with the spell's name.}

Message Property asMessageSKSESingular  Auto
{Text to display when a spell's requirements are not met
Unfulfilled requirements are seperated by line breaks and appended to the end of the message.
The first occurance of "%s%" will be replaced with the spell's name.}

LSPSpellLearnProgressionContCheck Property containerAlias  Auto
{Reference Alias to be assigned to the container the player is currently using. Very hacky.
ONLY used with SKSE}

Actor Property actorAliasRef  Auto Hidden
Bool Property UseSKSE  Auto Hidden

Bool Property initUnfinished = true  Auto Hidden
{Used to signal to the Container Checker that we're done initializing.
ONLY used with SKSE}

ObjectReference Property newCont  Auto Hidden
{ONLY used with SKSE}

Event OnInit()

    ; AddInventoryEventFilter(LSPMasterTomesList) ; FormLists are checked each time an Event is sent :]
    actorAliasRef = GetReference() as Actor ; I know GetActor() exists, and I don't care. It's a slightly laggier wrapper function.
    while !actorAliasRef
        Utility.WaitMenuMode(0.025)
        actorAliasRef = GetReference() as Actor
    EndWhile
    Debug.Trace("[LSP] Alias initialized to " + actorAliasRef.GetDisplayName() + " (" + actorAliasRef + ")")

    UseSKSE = SKSE.GetVersionRelease() && SKSE.GetVersionRelease() == skse.GetScriptVersionRelease()

    ; This value is used to tell the other script that the values are set
    initUnfinished = false

    if DEST.GetAPIVersion()
        GoToState("DEST")
        return
    EndIf

    ; Check for Powerofthree's Papyrus Extender
    if PO3_SKSEFunctions.GetPapyrusExtenderVersion()
        GoToState("PO3")
        return
    EndIf






    If UseSKSE
        RegisterForControl("Activate")
        RegisterForMenu("ContainerMenu")
        GoToState("SKSE")
    Else
        Debug.Trace("[LSP-Vanilla] Linear Spell Progression: SKSE not detected. The system will not work with containers, though the player inventory will work like normal.", 1)
        UnregisterForControl("Activate")
        UnregisterForMenu("ContainerMenu")
        GoToState("Vanilla")
    EndIf

EndEvent
;//;


Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
EndEvent

Event OnPlayerLoadGame()

    UseSKSE = SKSE.GetVersionRelease() && SKSE.GetVersionRelease() == skse.GetScriptVersionRelease()

    If UseSKSE

        ; Check for Don't Eat Spell Tomes
        if DEST.GetAPIVersion()
            GoToState("DEST")
            return
        EndIf

        ; Check for Powerofthree's Papyrus Extender
        if PO3_SKSEFunctions.GetPapyrusExtenderVersion()
            GoToState("PO3")
            return
        EndIf

        RegisterForControl("Activate")
        RegisterForMenu("ContainerMenu")
        GoToState("SKSE")
    Else
        Debug.Trace("[LSP-Loading] Linear Spell Progression: SKSE not detected. The system will not work with containers, though the player inventory will work like normal.", 1)
        UnregisterForControl("Activate")
        UnregisterForMenu("ContainerMenu")
        GoToState("Vanilla")
    EndIf
EndEvent

State Vanilla

    Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
        Debug.Trace("[LSP-Vanilla]  Item Equipped Event Recieved for "+akBaseObject.GetName()+" ("+akBaseObject+")")

        If LSPMasterTomesList.HasForm(akBaseObject)
            Int i = 0
            Int iMax = LSPMasterList.GetSize()

            while i < iMax ; iMax will always be the highest index, plus 1
                Debug.Trace("[LSP-Vanilla] Checking list #"+(i+1)+"/"+iMax+"...")
                FormList curList = LSPMasterList.GetAt(i) as FormList
                FormList curTomes = curList.GetAt(0) as FormList
                Int curSpellIndex = curTomes.Find(akBaseObject)
                Spell curSpell = (curList.GetAt(1) as FormList).GetAt(curSpellIndex) as Spell
                bool hasSpell = curSpellIndex >= 0 && actorAliasRef.HasSpell(curSpell)

                Debug.Trace("[LSP-Vanilla] Bool hasSpell: "+hasSpell)
                Debug.Trace("[LSP-Vanilla] Player has "+curSpell.GetName()+"? "+actorAliasRef.HasSpell(curSpell))

                If hasSpell ; If it's in the tome list, check for its requirements
                    Debug.Trace("[LSP-Vanilla] Spell found. Checking for requirements...")
                    Form curSpellOrList = (curList.GetAt(2) as FormList).GetAt(curSpellIndex)
                    FormList curRequirementsList = curSpellOrList as FormList

                    Debug.Trace("[LSP-Vanilla] Current Spell/List: "+curSpellOrList+" ("+curSpellOrList.GetName()+"), is list? "+(curRequirementsList as Bool))

                    If curRequirementsList
                        Debug.Trace("[LSP-Vanilla] Requirements are using a list. Checking all requirements...")
                        Int j = 0
                        Int jMax = curRequirementsList.GetSize()
                        Bool doRemoveSpell = false
                        Int numSpellsNeeded = 0

                        while j < jMax
                            Form curRequirement = curRequirementsList.GetAt(j)
                            If !actorAliasRef.HasSpell(curRequirement)
                                Debug.Trace("[LSP-Vanilla] Requirements not met. Removing spell...")
                                actorAliasRef.RemoveSpell(curSpell as Spell)
                                If akReference
                                    Debug.Trace("[LSP-Vanilla] Tome was a reference")
                                    actorAliasRef.AddItem(akReference)
                                Else
                                    Debug.Trace("[LSP-Vanilla] Tome was not a reference")
                                    actorAliasRef.AddItem(akBaseObject)
                                EndIf
                                asMessageNoSKSE.Show()
                                doRemoveSpell = true
                                j = jMax
                            Else
                                j += 1
                            EndIf
                        EndWhile

                        If !doRemoveSpell
                            ; Prevent further events for this tome
                            LSPMasterTomesList.RemoveAddedForm(curTomes.GetAt(curSpellIndex))
                            Debug.Trace("[LSP-Vanilla] Master Tomes List:\n"+LSPMasterTomesList.ToArray())
                        EndIf
                    Else
                        Debug.Trace("[LSP-Vanilla] Requirement is a single spell. Checking...")
                        If !actorAliasRef.HasSpell(curSpellOrList as Spell)
                            actorAliasRef.RemoveSpell(curSpell)
                            If akReference
                                Debug.Trace("[LSP-Vanilla] Tome was a reference")
                                actorAliasRef.AddItem(akReference)
                            Else
                                Debug.Trace("[LSP-Vanilla] Tome was not a reference")
                                actorAliasRef.AddItem(akBaseObject)
                            EndIf

                            asMessageNoSKSE.Show()
                        Else
                            ; Stop checking this tome
                            LSPMasterTomesList.RemoveAddedForm(curTomes.GetAt(curSpellIndex))
                            Debug.Trace("[LSP-Vanilla] Master Tomes List:\n"+LSPMasterTomesList.ToArray())
                        EndIf
                    EndIf
                    i = iMax
                ElseIf curSpellIndex >= 0
                    i = iMax
                Else
                    i += 1
                EndIf
            endWhile
        Else
            Debug.Trace("[LSP-Vanilla] Item is not a tracked Spell Tome")
        EndIf
    EndEvent

EndState

; TODO: Split into functions


State SKSE

    Event OnPlayerLoadGame()
        UseSKSE = SKSE.GetVersionRelease() && SKSE.GetVersionRelease() == skse.GetScriptVersionRelease()
        containerAlias.UseSKSE = UseSKSE

        If UseSKSE
            RegisterForControl("Activate")
            RegisterForMenu("ContainerMenu")
        Else
            Debug.Trace("[LSP-SKSE] Linear Spell Progression: SKSE not detected. The system will not work with containers, though the player inventory will work like normal.", 1)
            UnregisterForControl("Activate")
            UnregisterForMenu("ContainerMenu")
            GoToState("")
        EndIf
    EndEvent

    Event OnControlUp(string control, float holdTime)
        containerAlias.StartCheckingProcess(Game.GetCurrentCrosshairRef())
    EndEvent

    Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
        Debug.Trace("[LSP-SKSE] Item Removed Event Recieved\n Item: "+aiItemCount+"x "+akBaseItem.GetName()+" ("+akBaseItem+"), reference: "+akItemReference+"\nDestination Container:"+akDestContainer.GetName()+" ("+akDestContainer+")")
    EndEvent

    Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
        ;FormList iList = LSPMasterList

        Debug.Trace("[LSP-SKSE] Item Equipped Event Recieved for "+akBaseObject.GetName()+" ("+akBaseObject+")")

        If LSPMasterTomesList.HasForm(akBaseObject)
            Int i = 0
            Int iMax = LSPMasterList.GetSize()

            while i < iMax ; iMax will always be the highest index, plus 1
                Debug.Trace("[LSP-SKSE] Checking list #"+(i+1)+"/"+iMax+"...")
                FormList curList = LSPMasterList.GetAt(i) as FormList
                FormList curTomes = curList.GetAt(0) as FormList
                Int curSpellIndex = curTomes.Find(akBaseObject)
                Spell curSpell = (curList.GetAt(1) as FormList).GetAt(curSpellIndex) as Spell
                bool hasSpell = curSpellIndex >= 0 && actorAliasRef.HasSpell(curSpell)

                Debug.Trace("[LSP-SKSE] Bool hasSpell: "+hasSpell)
                Debug.Trace("[LSP-SKSE] Player has "+curSpell.GetName()+"? "+actorAliasRef.HasSpell(curSpell))

                If hasSpell ; If it's in the tome list, check for its requirements
                    Debug.Trace("[LSP-SKSE] Spell found. Checking for requirements...")
                    Form curSpellOrList = (curList.GetAt(2) as FormList).GetAt(curSpellIndex)
                    FormList curRequirementsList = curSpellOrList as FormList

                    Debug.Trace("[LSP-SKSE] Current Spell/List: "+curSpellOrList+" ("+curSpellOrList.GetName()+"), is list? "+(curRequirementsList as Bool))

                    If curRequirementsList
                        Debug.Trace("[LSP-SKSE] Requirements are using a list. Checking all requirements...")
                        Int j = 0
                        Int jMax = curRequirementsList.GetSize()
                        Int numSpellsNeeded = 0

                        Form[] listOfSpells = curRequirementsList.ToArray()
                        String[] spellNames = Utility.CreateStringArray(jMax)
                        while j < jMax
                            If !actorAliasRef.HasSpell(listOfSpells[j])
                                spellNames[j] = listOfSpells[j].GetName()
                                Debug.Trace("[LSP-SKSE] Requirement #"+(j+1)+"/"+jMax+": Known")
                                numSpellsNeeded += 1
                            Else
                                Debug.Trace("[LSP-SKSE] Requirement "+curSpell.GetName()+" ("+(j+1)+"/"+jMax+"): Known")
                            EndIf
                            j += 1
                        EndWhile

                        If numSpellsNeeded
                            Debug.Trace("[LSP-SKSE] Requirements not met. Removing spell (with SKSE)...")
                            String curSpellName = curSpell.GetName()
                            actorAliasRef.RemoveSpell(curSpell)
                            If akReference
                                Debug.Trace("[LSP-SKSE] Tome was a reference")
                                actorAliasRef.AddItem(akReference)
                            Else
                                Debug.Trace("[LSP-SKSE] Tome was not a reference")
                                actorAliasRef.AddItem(akBaseObject)
                            EndIf
                            LSP_SendSKSEMessage(curSpell, spellNames, numSpellsNeeded)
                        Else
                            ; Prevent further events for this tome
                            LSPMasterTomesList.RemoveAddedForm(curTomes.GetAt(curSpellIndex))
                            Debug.Trace("[LSP-SKSE] Master Tomes List:\n"+LSPMasterTomesList.ToArray())
                        EndIf
                    Else
                        Debug.Trace("[LSP-SKSE] Requirement is a single spell. Checking...")
                        If !actorAliasRef.HasSpell(curSpellOrList as Spell)
                            actorAliasRef.RemoveSpell(curSpell)
                            If akReference
                                Debug.Trace("[LSP-SKSE] Tome was a reference")
                                actorAliasRef.AddItem(akReference)
                            Else
                                Debug.Trace("[LSP-SKSE] Tome was not a reference")
                                actorAliasRef.AddItem(akBaseObject)
                            EndIf
                            String asMessageTextSKSE = asMessageSKSESingular.GetName()
                            Int namePos = StringUtil.Find(asMessageTextSKSE, "%s%")
                            Debug.MessageBox(StringUtil.Substring(asMessageTextSKSE, 0, namePos) + curSpell.GetName() + StringUtil.Substring(asMessageTextSKSE, namePos + 3, StringUtil.GetLength(asMessageTextSKSE) - (namePos + 3)) + curSpellOrList.GetName())
                        Else
                            ; Stop checking this tome
                            LSPMasterTomesList.RemoveAddedForm(curTomes.GetAt(curSpellIndex))
                            Debug.Trace("[LSP-SKSE] Master Tomes List:\n"+LSPMasterTomesList.ToArray())
                        EndIf
                    EndIf
                    i = iMax
                ElseIf curSpellIndex >= 0
                    i = iMax
                Else
                    i += 1
                EndIf
            endWhile
        Else
            Debug.Trace("[LSP-SKSE] Item is not a tracked Spell Tome")
        EndIf
        Debug.Trace("[LSP-SKSE] Container Alias' State: "+containerAlias.GetState())
    EndEvent
EndState

;//;
; UNFINISHED

Event OnSpellLearned(Spell akSpell)
    ; Defined here because the compiler said so
EndEvent

State PO3
    Event OnBeginState()
        PO3_Events_Alias.RegisterForSpellLearned(self)
        Debug.Trace("[LSP-PO3] Registered for spell learned events")
    EndEvent
    Event OnEndState()
        PO3_Events_Alias.UnregisterForSpellLearned(self)
        Debug.Trace("[LSP-PO3] PO3 state ending. So long and thanks for all the events.")
    EndEvent

    Event OnSpellLearned(Spell akSpell)

        Debug.Trace("[LSP-PO3] Spell Learned Event recieved, Spell: "+akSpell.GetName())

        Int i = 0
        Int iMax = LSPMasterList.GetSize()
        while i < iMax ; iMax will always be the highest index, plus 1
            Debug.Trace("[LSP-PO3] Checking list #"+(i+1)+"/"+iMax+"...")
            FormList curList = LSPMasterList.GetAt(i) as FormList

            ; Look for the spell
            Int curSpellIndex = (curList.GetAt(1) as FormList).Find(akSpell)

            Spell curSpell = (curList.GetAt(1) as FormList).GetAt(curSpellIndex) as Spell

            If curSpellIndex >= 0 ; If it's in the spell list, check for its requirements
                Debug.Trace("[LSP-PO3] Spell found. Checking for requirements...")
                Form curSpellOrList = (curList.GetAt(2) as FormList).GetAt(curSpellIndex)
                FormList curRequirementsList = curSpellOrList as FormList

                Debug.Trace("[LSP-PO3] Current Spell/List: "+curSpellOrList+" ("+curSpellOrList.GetName()+"), is list? "+(curRequirementsList as Bool))

                If curRequirementsList
                    Debug.Trace("[LSP-PO3] Requirements are using a list. Checking all requirements...")
                    Int j = 0
                    Int jMax = curRequirementsList.GetSize()
                    Int numSpellsNeeded = 0

                    Form[] listOfSpells = curRequirementsList.ToArray()
                    String[] spellNames = Utility.CreateStringArray(jMax)
                    while j < jMax
                        If !actorAliasRef.HasSpell(listOfSpells[j])
                            spellNames[numSpellsNeeded] = listOfSpells[j].GetName()
                            Debug.Trace("[LSP-PO3] Requirement "+curSpell.GetName()+" ("+(j+1)+"/"+jMax+"): Missing")
                            numSpellsNeeded += 1
                        Else
                            Debug.Trace("[LSP-PO3] Requirement "+curSpell.GetName()+" ("+(j+1)+"/"+jMax+"): Known")
                        EndIf
                        j += 1
                    EndWhile

                    If numSpellsNeeded
                        LSP_SendSKSEMessage(curSpell, spellNames, numSpellsNeeded)
                    Else
                        ; Prevent further events for this tome
                        LSPMasterTomesList.RemoveAddedForm((curList.GetAt(0) as FormList).GetAt(curSpellIndex))
                        Debug.Trace("[LSP-PO3] Master Tomes List:\n"+LSPMasterTomesList.ToArray())
                    EndIf
                Else
                    Debug.Trace("[LSP-PO3] Requirement is a single spell. Checking...")
                    If !actorAliasRef.HasSpell(curSpellOrList as Spell)
                        actorAliasRef.RemoveSpell(curSpell)
                        actorAliasRef.AddItem((curList.GetAt(0) as FormList).GetAt(curSpellIndex), 1, true)

                        String asMessageTextSKSE = asMessageSKSESingular.GetName()
                        Int namePos = StringUtil.Find(asMessageTextSKSE, "%s%")
                        Debug.MessageBox(StringUtil.Substring(asMessageTextSKSE, 0, namePos) + curSpell.GetName() + StringUtil.Substring(asMessageTextSKSE, namePos + 3, StringUtil.GetLength(asMessageTextSKSE) - (namePos + 3)) + curSpellOrList.GetName())
                    Else
                        ; Stop checking this tome
                        LSPMasterTomesList.RemoveAddedForm((curList.GetAt(0) as FormList).GetAt(curSpellIndex))
                    EndIf
                EndIf
                i = iMax
            ElseIf curSpellIndex >= 0
                i = iMax
            Else
                i += 1
            EndIf
        endWhile
    EndEvent
EndState
;/
/;

Event OnSpellTomeRead(Book akBook, Spell akSpell, ObjectReference akContainer)
    ; Compiler says it has to be here, but it's not used
EndEvent


Bool isProcessing = false
Form lastTome

; Don't Eat Spell Tomes
State DEST

    Event OnBeginState()
        isProcessing = false
        lastTome = None
        DEST_AliasExt.RegisterForSpellTomeReadEvent(self)
        Debug.Trace("[LSP-DEST] DEST state beginning. Registered for Spell Tome Read event.")
    EndEvent
    Event OnEndState()
        isProcessing = false
        lastTome = None
        DEST_AliasExt.UnRegisterForSpellTomeReadEvent(self)
        Debug.Trace("[LSP-DEST] DEST state ended. So long and thanks for all the events.")
    EndEvent

    ; Hijacks spell tome processing. Thanks, Don't Eat Spell Tomes!
    Event OnSpellTomeRead(Book akBook, Spell akSpell, ObjectReference akContainer)

        ; I'm using this because of a strange double-event bug causing 2 messages to appear at once. Rather annoying.
        if lastTome == akBook
            return
        EndIf

        ; Stop users from breaking the script by spamming tomes
        ; Used in the case a user uses multiple tomes
        if isProcessing
            return
        EndIf

        ; Both of these variables are cleared in TomeReadEventEndingCalls()
        isProcessing = true
        lastTome = akBook

        ; "Already has spell" behavior
        If actorAliasRef.HasSpell(akSpell)
            Debug.Trace("[LSP-DEST] Spell \""+akSpell.GetName()+"\" already known. Ignoring.")
            DEST_UIExt.Notification(Game.GetGameSettingString("sAlreadyKnown") + " " + akSpell.GetName(), "", true)

            ; Standard early return behavior
            returnStuffs(akBook)
            return
        EndIf

        ; If we're tracking this tome, check for requirements and send a message. Otherwise, we'll just eat it like normal.
        If LSPMasterTomesList.HasForm(akBook)
            Int i = 0
            Int iMax = LSPMasterList.GetSize()

            while i < iMax ; iMax will always be the highest index, plus 1

                Debug.Trace("[LSP-DEST] Checking list #"+(i+1)+"/"+iMax+"...")

                ; Get the current plugin-level list
                FormList curList = LSPMasterList.GetAt(i) as FormList

                ; Get the index we're looking at
                Int curSpellIndex = (curList.GetAt(0) as FormList).Find(akBook)


                Debug.Trace("[LSP-DEST] Current Spell Index: "+curSpellIndex)

                ; See if the book was found
                if curSpellIndex < 0
                    i += 1
                else
                    Debug.Trace("[LSP-DEST] Spell found!")

                    ; See if the book and spell match up
                    if !((curList.GetAt(0) as FormList).GetAt(curSpellIndex) as Book).GetSpell() == akSpell
                        i += 1
                        Debug.Trace("[LSP-DEST] Book and spell do NOT match up. Looking for another occurance.", 2)
                    else
    
                        Debug.Trace("[LSP-DEST] Spell and book match up. Checking for requirements...")
    
                        ; Find the requirements spell/list Logic later will determine which it is.
                        ; Looks like a mess now, but the naming is intentional. It'll look better further down.
                        Form curSpell = (curList.GetAt(2) as FormList).GetAt(curSpellIndex)
                        FormList curRequirementsList = curSpell as FormList ; Confusing here, but much more tame later.
    
                        Debug.Trace("[LSP-DEST] Current Spell/List: "+curSpell+" ("+curSpell.GetName()+"), is list? "+(curRequirementsList as Bool))
                        
                        If curRequirementsList
                            Debug.Trace("[LSP-DEST] Requirements are using a list. Checking all requirements...")
                            Int j = 0
                            Int jMax = curRequirementsList.GetSize()
                            Int numSpellsNeeded = 0 ; This variable here is crafty
                            ; If it's 0, then the message is skipped and the spell is added.
                            ; It it's 1, the Single Spell message is sent.
                            ; If it's greater than 1, the Multiple Spells message is sent, and this variable acts as jMax.
    
                            Form[] listOfSpells = curRequirementsList.ToArray()
                            String[] spellNames = Utility.CreateStringArray(jMax)
                            while j < jMax
                                If !actorAliasRef.HasSpell(listOfSpells[j])
                                    spellNames[numSpellsNeeded] = listOfSpells[j].GetName()
                                    Debug.Trace("[LSP-DEST] Requirement NOT LEARNED:\t\""+akSpell.GetName()+"\" ("+(j+1)+"/"+jMax+")")
                                    numSpellsNeeded += 1
                                Else
                                    Debug.Trace("[LSP-DEST] Requirement Known:\t\t\t\""+akSpell.GetName()+"\" ("+(j+1)+"/"+jMax+"): Known")
                                EndIf
                                j += 1
                            EndWhile
    
                            if numSpellsNeeded
                                LSP_SendSKSEMessage(akSpell, SpellNames, numSpellsNeeded)
                                returnStuffs(akBook)
                                return
                            EndIf ;Condition: numSpellsNeeded
    
                        Else ;New Condition: !curRequirementsList
                            Debug.Trace("[LSP-DEST] Requirement is a single spell. Checking...")
    
                            if !actorAliasRef.HasSpell(curSpell)
    
                                LSP_SendSKSEMessage(akSpell, Utility.CreateStringArray(1, curSpell.GetName()), 1)
                                returnStuffs(akBook)
                                return
                            EndIf ;Condition: actorAliasRef.HasSpell(curSpell)
                        EndIf ;Last Condition: !curRequirementsList
                        i = iMax
    
                    EndIf
                EndIf

            EndWhile ;End Condition: i >= iMax
        Else ;New Condition: !LSPMasterTomesList.HasForm(akBook)
            Debug.Trace("[LSP-DEST] Item is not a tracked Spell Tome")
        EndIf


        ; This part will only be reached if the spell's requirements are met, since the above code will return if they're not.
        if akContainer
            akContainer.RemoveItem(akBook, 1, true ;/ silent /;)
        else
            actorAliasRef.RemoveItem(akBook, 1, true ;/ silent /;)
        endif

        LSPMasterTomesList.RemoveAddedForm(akBook)
        Debug.Trace("[LSP-DEST] Master Tomes List:\n"+LSPMasterTomesList.ToArray())
        actorAliasRef.AddSpell(akSpell, false)
        DEST_UIExt.Notification(Game.GetGameSettingString("sSpellAdded") + ": " + akSpell.GetName(), "UISpellLearned")

        returnStuffs(akBook)
    EndEvent

    Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
        ; Empty event because I was having issues with Vanilla events bleeding over
    EndEvent

    
EndState

Function returnStuffs(Form akBook)
    isProcessing = false
    Utility.WaitMenuMode(0.25)
    if lastTome == akBook
        lastTome = None
    EndIf
EndFunction

; Shows the SKSE Message Box for when the Player hasn't learned the spell.
;
; akSpellToLearn = The spell that the player is trying (and failing) to learn
; asSpellNames = List of names for the spells that the player still needs to learn
; aiSpellCount = Number of spells included in asSpellNames. UNINTENDED CONSEQUENCES IF aiSpellCount = 0
Function LSP_SendSKSEMessage(Spell akSpellToLearn, String[] asSpellNames, Int aiSpellCount)
    Debug.Trace("[LSP-SKSE+] Sending MessageBox.")
    String akSpellName = akSpellToLearn.GetName()

    If aiSpellCount == 1 ; Only one spell needed
        String asMessageTextSKSE = asMessageSKSESingular.GetName()
        Int namePos = StringUtil.Find(asMessageTextSKSE, "%s%")
        String constructionMsg = StringUtil.Substring(asMessageTextSKSE, 0, namePos) + akSpellName + StringUtil.Substring(asMessageTextSKSE, namePos + 3)
        Int prereqNamePos = StringUtil.Find(constructionMsg, "%p%")
        constructionMsg = StringUtil.Substring(constructionMsg, 0, prereqNamePos) + asSpellNames[0] + StringUtil.Substring(constructionMsg, prereqNamePos + 3, StringUtil.GetLength(constructionMsg) - (prereqNamePos + 3))
        Debug.Trace("[LSP-SKSE+] Message sent:\n=====================================================\n"+constructionMsg+"\n=====================================================")
        Debug.MessageBox(constructionMsg)

    Else ; There are multiple spells needed

        String asMessageTextSKSE = asMessageSKSE.GetName()
        Int namePos = StringUtil.Find(asMessageTextSKSE, "%s%")
        String constructionMsg = StringUtil.Substring(asMessageTextSKSE, 0, namePos) + akSpellName + StringUtil.Substring(asMessageTextSKSE, namePos + 3)
        Int j = 0
        ; jMax = numSpellsNeeded
        while j < aiSpellCount
            constructionMsg = constructionMsg + "\n" + asSpellNames[j]
            j += 1
        EndWhile
        Debug.Trace("[LSP-SKSE+] Message sent:\n=====================================================\n"+constructionMsg+"\n=====================================================")
        Debug.MessageBox(constructionMsg)

    EndIf
EndFunction