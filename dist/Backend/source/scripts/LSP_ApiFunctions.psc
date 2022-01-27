Scriptname LSP_ApiFunctions Extends Quest
{Script that holds functions used to easily interact with the Linear Spell Progression system
To use, cast the Backend Quest to this script}

FormList Property LSPMasterList  Auto
FormList Property LSPMasterTomesList  Auto

; FUNCTION AddToList

; Adds the specified FormList from the Master List and optionally removes tomes from the Master Tomes List
Function AddToList(FormList listToAdd, bool addTomesToList = True)

    Debug.Trace("[LSP] AddToList called with listToAdd = " + listToAdd.GetName() + "("+listToAdd+") and addTomesToList = " + addTomesToList)

    LSPMasterList.AddForm(listToAdd)
    
    if addTomesToList
        if (self.GetAlias(0) as LSPSpellLearnProgressionCheck).UseSKSE
            LSPMasterTomesList.AddForms((listToAdd.GetAt(0) as FormList).ToArray())
        else
            ; TODO: Make Vanilla alternative that works
            LSPMasterTomesList.AddForms((listToAdd.GetAt(0) as FormList).ToArray())
        EndIf
    EndIf

    Debug.Trace("[LSP] AddToList finished\nMaster List now contains " + LSPMasterList.GetSize() + " forms\nMaster Tomes List now contains " + LSPMasterTomesList.GetSize() + " forms")
EndFunction ; !FUNCTION


; FUNCTION RemoveFromList

; Removes the specified FormList from the Master List and optionally removes tomes from the Master Tomes List
Function RemoveFromList(FormList listToRemove, bool removeTomesFromList = True) ; Not sure when you'd ever use this, but OK

    LSPMasterList.RemoveAddedForm(listToRemove)

    if (self.GetAlias(0) as LSPSpellLearnProgressionCheck).UseSKSE
        if removeTomesFromList
            Form[] oldTomesList = (listToRemove.GetAt(1) as FormList).ToArray()
            Int i = 0
            Int iMax = oldTomesList.Length
    
            While i < iMax
                LSPMasterTomesList.RemoveAddedForm(oldTomesList[i])
                i += 1
            EndWhile
        EndIf
    else
        ; TODO: Make Vanilla alternative that works
        if removeTomesFromList
            Form[] oldTomesList = (listToRemove.GetAt(1) as FormList).ToArray()
            Int i = 0
            Int iMax = oldTomesList.Length
    
            While i < iMax
                LSPMasterTomesList.RemoveAddedForm(oldTomesList[i])
                i += 1
            EndWhile
        EndIf
    EndIf

EndFunction ; !FUNCTION
