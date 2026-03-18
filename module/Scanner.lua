local Scanner = {

    NPCOnCallState = {
        NPCIdle = 0,
        NPCNeedsScan = 1,
        NPCScanned = 2
    },
    LastScannedTarget = nil,
}


function Scanner.Init()
    Override('ScannerNPCHeaderGameController', 'OnNameChanged', function(this, value, wrappedMethod)
		Scanner.OnNameChangedEvent(this, value, wrappedMethod)		
	end)
end
function Scanner.Dispose()
    
end

-- this function only works IF there is only one friend active
function Scanner.OnNameChangedEvent(scan, value, wrappedMethod)
    print("+++++ OnNameChangedEvent +++++")
    local objLook = TargetHelper.GetLookAtTarget()
    -- peektargetinfo returns a display name if the npc is already cached
    local targetInfo = CyberNPC.PeekTargetInfo(objLook)

    if targetInfo ~= nil then
        if Scanner.LastScannedTarget == nil then
            print("update Scanner.LastScannedTarget")
            Scanner.LastScannedTarget = targetInfo
        else
            if targetInfo.record_id_hash ~= Scanner.LastScannedTarget.record_id_hash then
                print("targetInfo.record_id_hash ~= Scanner.LastScannedTarget.record_id_hash")
                Scanner.LastScannedTarget = targetInfo
            else
                print("targetInfo.record_id_hash == Scanner.LastScannedTarget.record_id_hash")
                if targetInfo.display_name ~= Scanner.LastScannedTarget.display_name then
                    print("!!!! targetInfo.display_name ~= Scanner.LastScannedTarget.display_name")
                    -- CyberNPC.UpdateTargetInfo(Scanner.LastScannedTarget)
                else
                    print("!!!! targetInfo.display_name == Scanner.LastScannedTarget.display_name")
                    Scanner.OnMainPartScanNameChangedEvent(targetInfo, scan, value, wrappedMethod)
                    return
                end
            end
        end
    end 
	if not objLook then
        print("not objLook")
        return wrappedMethod(value)
        -- return
    else
        Scanner.OnMainPartScanNameChangedEvent(targetInfo, scan, value, wrappedMethod)
    end
end

function Scanner.OnMainPartScanNameChangedEvent(targetInfo, scan, value, wrappedMethod)
    print("MAIN PART +++++ Scanner.OnNameChangedEvent +++++")
    -- local entId = objLook:GetRecordID()
    print("record_id_hash: ")
    print(targetInfo.record_id_hash)

    if Merc.IsAMerc(Scanner.LastScannedTarget) then
        if not Scanner.LastScannedTarget.dialog_lock then
            Scanner.LastScannedTarget.dialog_lock = true
            Scanner.VScansNPCDialog(Scanner.LastScannedTarget)
            inkTextRef.SetText(scan.nameText, Scanner.LastScannedTarget.display_name)
            scan.isValidName = true
            scan:UpdateGlobalVisibility()
            return
        end
        return wrappedMethod(value)
    end

    if not PhoneControl.cachedSelectedContactIdx or PhoneControl.cachedSelectedContactIdx == 0 then
        print("cachedSelectedContactIdx is nil or 0")
        return wrappedMethod(value)
    end
    
    local cachedContact = PhoneControl.contacts[PhoneControl.cachedSelectedContactIdx]
    print("record_id_hash to look:")
    print(cachedContact.contact.record_id_hash_to_scan)
    print(cachedContact.contact.record_id_hash)

    -- depends on SpawnNPC setting display_name_changed to 1 in NPCOnCall
    -- this can fail if the user scans other npcs than the one pending        
    if cachedContact.contact.record_id_hash_to_scan == targetInfo.record_id_hash then
        HUD.QuestMessage("Friend scanned")

        cachedContact.contact.display_name_changed = Scanner.NPCOnCallState.NPCScanned
        CyberNPC.LastNPCTarget.record_id_scanned = cachedContact.contact.record_id_hash_to_scan
        CyberNPC.LastNPCTarget.display_name_scanned = cachedContact.contact.display_name
        CyberNPC.LastNPCTarget.display_name = cachedContact.contact.display_name
        Scanner.LastScannedTarget.display_name = cachedContact.contact.display_name
        CyberNPC.LastNPCTarget.tweaks_name = cachedContact.contact.tweaks_name
        targetInfo.display_name = cachedContact.contact.display_name
        targetInfo.tweaks_name = cachedContact.contact.tweaks_name
        targetInfo.display_name_scanned = cachedContact.contact.display_name
        local foundFool = false
        CyberNPC.ForEachCachedNPCTargetByRecordIdHash(targetInfo.record_id_hash, function(fool)
            print("FOUND A FOOL!")
            foundFool = true
            fool.display_name = cachedContact.contact.display_name
            fool.tweaks_name = cachedContact.contact.tweaks_name
        end)
        if not foundFool then            
            CyberNPC.UpdateCachedTargetByRecordIdHash(targetInfo, targetInfo.record_id_hash)
        end

        print("Scanner.OnNameChangedEvent changing name")
        inkTextRef.SetText(scan.nameText, cachedContact.contact.display_name)
        scan.isValidName = true
        scan:UpdateGlobalVisibility()

    end
    if cachedContact.contact.display_name_changed == Scanner.NPCOnCallState.NPCScanned then
        -- dont know if needs to be commented out
        -- return wrappedMethod(value)
    else         
        print("Scanner.OnNameChangedEvent entity id not the same")
        return wrappedMethod(value)
    end
end

function Scanner.VScansNPCDialog(targetInfo)
    local vLine = CyberV.VScansNPCRandomLine()
    local VLineWaitTime = Subtitles.CalcTimeOfString(vLine)+2
    local positiveRudeIronicOrName = math.random(133)
    local response = ''
    if positiveRudeIronicOrName < 33 then
        response = CyberNPC.NPCScannedRudeNegativeLinesRandomLine()
    elseif positiveRudeIronicOrName < 66 then
        response = CyberNPC.NPCScannedIronicLinesRandomLine()
    elseif positiveRudeIronicOrName < 99 then
        response = CyberNPC.NPCScannedPositiveLinesRandomLine()
    else
        CyberNPC.NPCSpeakLast(CyberNPC.NPCIntroduceLinesRandomLine(targetInfo.display_name))
        return
    end
    CyberV.VSpeak(vLine)
    Cron.After(VLineWaitTime, function()
        CyberNPC.NPCSpeakExtended(response, targetInfo.id_hash, targetInfo.display_name, CyberNPC.GetNPCTargetForServer(targetInfo))
    end)
    return response
end

return Scanner