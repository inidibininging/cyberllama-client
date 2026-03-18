local sqlite = require('sqlite3')

local CyberNPC = {
    AnimationsEnabled = false,
    SpawnNearDistance = 15,
    LLamaNPCVIntent = false,
    LLamaNPCIsKill = false,
    LLamaNPCIsHide = false,
    LLamaNPCIsMove = false,
    LLamaNPCIsHold = false,
    LLamaNPCIsFollow = false,
    LLamaNPCIsGet = false,
    LLamaNPCIsGetUp = false,
    LLamaNPCIsQuest = false,
    LLamaNPCIsMoney = false,
    LLamaNPCIsDrink = false,
    LLamaNPCIsEat = false,

    LLamaNPCRelationship = 40,
    LLamaNPCFood = 50,
    LLamaNPCHydration = 50,
    LLamaNPCFun = 50,

    LLamaNPCRelationshipCooldown = 0,
    LLamaNPCFoodCooldown = 0,
    LLamaNPCHydrationCooldown = 0,
    LLamaNPCFunCooldown = 0,

    LLamaNPCRelationshipCooldownSecs = 20,
    LLamaNPCFoodCooldownSecs = 20,
    LLamaNPCHydrationCooldownSecs = 20,
    LLamaNPCFunCooldownSecs = 20,
    
    -- Makes an npc a follower if the threshold is crossed
    LLamaNPCFriendThreshold = 30,
    LLamaNPCRomanticThreshold = 30,
    LLamaNPCNeedsCriticalThreshold = 20,

    -- Used for debugging. Ignore it
    LastStatsInfoCooldown = 60,
    
    -- cron job timer for controlling wether an npc should talk
    CyberllamaNPCCommentTimer = 0,

    CyberllamaNPCTalkTimerSeconds = 20,
    
    CyberllamaNPCTalkTimer = 0,
    -- controls when an npc should talk
    -- the variable is set to reset everytime a prompt is called (CyberllamaRequestPrompt)
    CyberllamaNPCTalkTimerMax = 240,

    LastNPCTarget = {
        id = nil,
        record_id = nil,
        obj = nil,
        id_hash = '',
        record_id_hash = '',
        class_name = '',
        display_name = '',
        tweaks_name = '',
        appearance = ''
    },

    CachedLastNPCTargets = {},

    LastCombatState = 0,
    LastCombatStateTime = {
        td = 0,
        th = 0,
        tm = 0,
        ts = 0
    },
    LastActualCombatTime = {
        td = 0,
        th = 0,
        tm = 0,
        ts = 0
    },
    LastActualCombatDuration = {
        td = 0,
        th = 0,
        tm = 0,
        ts = 0
    },

    gameUtils = nil,
    backend = nil,
    phoneControl = nil,
    aiControl = nil,
}

function CyberNPC.Init(gameUtils, backend, phoneControl, hud, aiControl, subtitlesControl, face, cron)
    CyberNPC.gameUtils = gameUtils
    CyberNPC.backend = backend
    CyberNPC.phoneControl = phoneControl
    CyberNPC.hud = hud
    CyberNPC.aiControl = aiControl
    CyberNPC.subtitlesControl = subtitlesControl
    CyberNPC.face = face
    CyberNPC.cron = cron
end

function CyberNPC.Dispose()
    CyberNPC.CachedLastNPCTargets = {}
    CyberNPC.LLamaNPCVIntent = false
    CyberNPC.LLamaNPCIsKill = false
    CyberNPC.LLamaNPCIsHide = false
    CyberNPC.LLamaNPCIsMove = false
    CyberNPC.LLamaNPCIsHold = false
    CyberNPC.LLamaNPCIsFollow = false
    CyberNPC.LLamaNPCIsGet = false
    CyberNPC.LLamaNPCIsGetUp = false
    CyberNPC.LLamaNPCIsQuest = false
    CyberNPC.LLamaNPCIsMoney = false

    CyberNPC.LLamaNPCRelationship = 40
    CyberNPC.LLamaNPCFood = 50
    CyberNPC.LLamaNPCHydration = 50
    CyberNPC.LLamaNPCFun = 50
    CyberNPC.LLamaNPCIsDrink = false
    CyberNPC.LLamaNPCIsEat = false
    
end
-- updates the mood of the current npc
function CyberNPC.NPCUpdateMood(food, hydration, fun, relationship, targetInfo)
    print("NPCUpdateMood")
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    CyberNPC.NPCUpdateFood(npcInfo, food)
    CyberNPC.NPCUpdateHydration(npcInfo, hydration)
    CyberNPC.NPCUpdateFun(npcInfo, fun)
    CyberNPC.NPCUpdateRelationship(npcInfo, relationship)
end

function CyberNPC.NPCUpdateFood(npc, food)
    if(food == nil or food == 0) then
        print("skipping food. value is 0")
    else
        if(food > 100) then
            food = 100
        else
            npc.LLamaNPCFood = food
        end
    end
end

function CyberNPC.NPCUpdateHydration(npc, hydration)
    if(hydration == nil or hydration == 0) then
        print("skipping hydration. value is 0")
    else
        if(hydration > 100) then
            hydration = 100
        else
            npc.LLamaNPCHydration = hydration
        end
    end
end

function CyberNPC.NPCUpdateFun(npc, fun)
    if(fun == nil or fun == 0) then
        print("skipping fun. value is 0")
    else
        if(fun > 100) then
            fun = 100
        else
            npc.LLamaNPCFun = fun
        end
    end
end

function CyberNPC.NPCUpdateRelationship(npc, relationship)
    if(relationship == nil or relationship == 0) then
        print("skipping relationship. value is 0")
    else
        if(relationship > 120) then
            relationship = 120
        else
            npc.LLamaNPCRelationship = relationship
        end
    end
end

function CyberNPC.NPCUpdateIntention(kill, drink, eat, hide, move, hold, follow, get, getup, quest, money, char, faction, location, district, company)
    print("NPCUpdateIntention")
    CyberNPC.LLamaNPCIsKill = kill
    CyberNPC.LLamaNPCIsDrink = drink
    CyberNPC.LLamaNPCIsEat = eat
    CyberNPC.LLamaNPCIsHide = hide
    CyberNPC.LLamaNPCIsMove = move
    CyberNPC.LLamaNPCIsHold = hold
    CyberNPC.LLamaNPCIsFollow = follow
    CyberNPC.LLamaNPCIsGet = get
    CyberNPC.LLamaNPCIsGetUp = getup
    CyberNPC.LLamaNPCIsQuest = quest
    CyberNPC.LLamaNPCIsMoney = money
    CyberNPC.LLamaNPCIsChar = char
    CyberNPC.LLamaNPCIsFaction = faction
    CyberNPC.LLamaNPCIsLocation = location
    CyberNPC.LLamaNPCIsDistrict = district
    CyberNPC.LLamaNPCIsCompany = company
    if CyberNPC.LLamaNPCIsEat then
        CyberNPC.hud.QuestMessage("Grab something to eat")
    end
    if CyberNPC.LLamaNPCIsDrink then
        CyberNPC.hud.QuestMessage("Grab something to drink")
    end
end
  


function CyberNPC.UpdateIntentions(content)
    print("UpdateIntentions")
    if content.npc_intentions then
        CyberNPC.NPCUpdateIntention(
            content.npc_intentions.npc_is_kill,
            content.npc_intentions.npc_is_drink,
            content.npc_intentions.npc_is_eat,
            content.npc_intentions.npc_is_hide,
            content.npc_intentions.npc_is_move,
            content.npc_intentions.npc_is_hold,
            content.npc_intentions.npc_is_follow,
            content.npc_intentions.npc_is_get,
            content.npc_intentions.npc_is_getup,
            content.npc_intentions.npc_is_quest,
            content.npc_intentions.npc_is_money,
            content.npc_intentions.npc_mentions_char,
            content.npc_intentions.npc_mentions_faction,
            content.npc_intentions.npc_mentions_location,
            content.npc_intentions.npc_mentions_district,
            content.npc_intentions.npc_mentions_company
        )    
    else
        CyberNPC.NPCUpdateIntention(false, false, false, false, false, false, false, false, false)
    end
end

-- function CyberNPC.FixDisplayName()
--     local displayName  = CyberNPC.LastNPCTarget.display_name
--     if (not displayName)
--     or displayName == ''
--     or #(displayName) == 0
--     or displayName == 'Customer'
--     or displayName == 'Patron'
--     or displayName == 'Bar Patron Puppet'
--     or displayName == 'Club Patron'
--     or displayName == 'Female Club Patron'
--     or displayName == 'NPCPuppet'
--     or displayName == 'Puppet'
--     or displayName == 'NPC Puppet' then
--         CyberNPC.LastNPCTarget.display_name = CyberNPC.NPCRandomNickName(npcInfo.appearance)
--     end
-- end

function CyberNPC.GetLastNPCTargetForServer()
    -- CyberNPC.FixDisplayName()
    if CyberNPC.LastNPCTarget.display_name_scanned then
        print("Overriding id with old one!")
        local contact = PhoneControl.GetContactsNPCDataByDisplayName(CyberNPC.LastNPCTarget.display_name_scanned)
        if contact then       
            return {
                id_hash = contact.id_hash,
                record_id_hash = contact.record_id_hash,
                class_name = CyberNPC.LastNPCTarget.class_name,
                display_name = CyberNPC.LastNPCTarget.display_name,
                tweaks_name = CyberNPC.LastNPCTarget.tweaks_name,
                appearance = CyberNPC.LastNPCTarget.appearance
            }
        else
            print("GetLastNPCTargetForServer: No contact there")
            return {
                id_hash = CyberNPC.LastNPCTarget.id_hash,
                record_id_hash = CyberNPC.LastNPCTarget.record_id_hash,
                class_name = CyberNPC.LastNPCTarget.class_name,
                display_name = CyberNPC.LastNPCTarget.display_name,
                tweaks_name = CyberNPC.LastNPCTarget.tweaks_name,
                appearance = CyberNPC.LastNPCTarget.appearance
            }
        end
    else    
        return {
            id_hash = CyberNPC.LastNPCTarget.id_hash,
            record_id_hash = CyberNPC.LastNPCTarget.record_id_hash,
            class_name = CyberNPC.LastNPCTarget.class_name,
            display_name = CyberNPC.LastNPCTarget.display_name,
            tweaks_name = CyberNPC.LastNPCTarget.tweaks_name,
            appearance = CyberNPC.LastNPCTarget.appearance
        }
    end
end

function CyberNPC.GetNPCTargetForServer(npcTarget)    
    if npcTarget then
        return {
            id_hash = npcTarget.id_hash,
            record_id_hash = npcTarget.record_id_hash,
            class_name = npcTarget.class_name,
            display_name = npcTarget.display_name,
            tweaks_name = npcTarget.tweaks_name,
            appearance = npcTarget.appearance
        }
    else
        return {
            id_hash = '',
            record_id_hash = '',
            class_name = '',
            display_name = '',
            tweaks_name = '',
            appearance   = '',
        }
    end
end

-- cyberscript borrowed. sry. had to in order to show an animated face :/
CyberNPC.talkTimer = nil
CyberNPC.talkTimerSeconds = 0
CyberNPC.talkTimerCurrentSeconds = 0
function CyberNPC.FakeTalk(text, target)
    if CyberNPC.talkTimer then
        return
    end
    local npc = CyberNPC.GetLastTarget()
    if target then
        npc = target
    end
    if npc ~= nil then
        local timeToPass = Subtitles.CalcTimeOfString(text)
        CyberNPC.talkTimerSeconds = timeToPass / 2
        
        CyberNPC.talkTimer = CyberNPC.cron.Every(2, function()
            CyberNPC.talkTimerCurrentSeconds = 2 + CyberNPC.talkTimerCurrentSeconds
            local r = math.random(1,100)
            local did = false

            if r < 30 then
                did = true
                FaceExpression.Terrified(npc)
            end
            if r < 50 and did ~= true then
                did = true
                FaceExpression.Fear(npc)
            end
            if r < 70 and did ~= true then
                did = true
                FaceExpression.Surprise(npc)
            end
            if CyberNPC.talkTimerCurrentSeconds > CyberNPC.talkTimerSeconds then
                CyberNPC.cron.Halt(CyberNPC.talkTimer)
                CyberNPC.talkTimer = nil
            end
        end)
    end
end

function CyberNPC.PeekTargetInfo(target)

    print("PeekTargetInfo")
    if target ~= nil
        and target
        and target:IsNPC()
    then 
        print("LastNPCTarget is an npc")
    else
        print("LastNPCTarget is not an npc")        
        return
    end
    
    local newTarget = {}
    newTarget.obj = target
    newTarget.id = target:GetEntityID()
    if not newTarget.id then
        print("id is nil")
        return
    else
        print("newTarget.id")
        print(newTarget.id)
    end

    newTarget.record_id = target:GetRecordID()
    if not newTarget.record_id then
        print("record_id is nil")
        return
    else
        print("newTarget.record_id")
        print(newTarget.record_id)
    end

    newTarget.id_hash = tostring(target:GetEntityID().hash) or ''
    if not newTarget.id_hash then
        print("id_hash is nil")
        return
    else
        print("newTarget.id_hash")
        print(newTarget.id_hash)
    end

    newTarget.record_id_hash = tostring(target:GetRecordID().hash)
    if not newTarget.record_id_hash then
        print("record_id_hash is nil")
        return
    else
        print("newTarget.record_id_hash")
        print(newTarget.record_id_hash)
    end

    newTarget.class_name = NameToString(target:GetClassName())
    if not newTarget.class_name then
        print("class_name is nil")
        return
    else
        print("newTarget.class_name")
        print(newTarget.class_name)
    end

    newTarget.display_name = tostring(target:GetDisplayName())
    if not newTarget.display_name then
        print("display_name is nil")
        return
    else
        print("newTarget.display_name")
        print(newTarget.display_name)
    end

    newTarget.tweaks_name = tostring(target:GetTweakDBDisplayName(true))
    if not newTarget.tweaks_name then
        print("tweaks_name is nil")
        return
    else
        print("newTarget.tweaks_name")
        print(newTarget.tweaks_name)
    end

    newTarget.tweaks_db_name = tostring(target:GetRecordID()):match("%-%-%[%[%s*(.-)%s*%-%-%]%]")
    if not newTarget.tweaks_db_name then
        print("tweaks_db_name is nil")
        return
    else
        print("newTarget.tweaks_db_name")
        print(newTarget.tweaks_db_name)
    end

    newTarget.appearance = NameToString(target:GetCurrentAppearanceName())
    if not newTarget.appearance then
        print("appearance is nil")
        return
    else
        print("newTarget.appearance")
        print(newTarget.appearance)
    end

    local potentialNpc = CyberNPC.GetCachedNPCTargetByRecordIdHash(newTarget.record_id_hash)
    if potentialNpc then
        newTarget.display_name = potentialNpc.display_name
    else
        newTarget.display_name = CyberNPC.NPCRandomNickName(newTarget.appearance)
    end
    return newTarget
end

function CyberNPC.UpdateTargetInfo(target)

    print("UpdateTargetInfo")
    if target ~= nil
        and target
        and target:IsNPC()
    then 
        print("LastNPCTarget is an npc")
    else
        print("LastNPCTarget is not an npc")        
        return
    end
    
    local newTarget = {}
    newTarget.obj = target
    newTarget.id = target:GetEntityID()
    if not newTarget.id then
        print("id is nil")
        return
    else
        print("newTarget.id")
        print(newTarget.id)
    end

    newTarget.record_id = target:GetRecordID()
    if not newTarget.record_id then
        print("record_id is nil")
        return
    else
        print("newTarget.record_id")
        print(newTarget.record_id)
    end

    newTarget.id_hash = tostring(target:GetEntityID().hash) or ''
    if not newTarget.id_hash then
        print("id_hash is nil")
        return
    else
        print("newTarget.id_hash")
        print(newTarget.id_hash)
    end

    newTarget.record_id_hash = tostring(target:GetRecordID().hash)
    if not newTarget.record_id_hash then
        print("record_id_hash is nil")
        return
    else
        print("newTarget.record_id_hash")
        print(newTarget.record_id_hash)
    end

    newTarget.class_name = NameToString(target:GetClassName())
    if not newTarget.class_name then
        print("class_name is nil")
        return
    else
        print("newTarget.class_name")
        print(newTarget.class_name)
    end

    -- fix forgetting the name
    local foundFool = CyberNPC.GetCachedNPCTargetByRecordIdHash(newTarget.record_id_hash)
    if foundFool then
        print("FIX forgetting the name!!!!")
        print("new target")
        print(newTarget.display_name)
        print("foundFool")
        print(foundFool.display_name)
        if not CyberNPC.IsResident(foundFool) then
            newTarget.display_name = foundFool.display_name
        end
    else
        print("NO FIX. Didnt find" .. newTarget.record_id_hash)
        -- override new target display name with the new same one
        -- fix skipping (Add Contact) if the npc is the same one
        if CyberNPC.LastNPCTarget.record_id_hash_scanned 
        and newTarget.record_id_hash == CyberNPC.LastNPCTarget.record_id_hash_scanned 
        and CyberNPC.LastNPCTarget.display_name_scanned then
            newTarget.display_name = CyberNPC.LastNPCTarget.display_name_scanned
            newTarget.tweaks_name = CyberNPC.LastNPCTarget.display_name_scanned
        else
            newTarget.display_name = tostring(target:GetDisplayName())
        end
    end
    
    if not newTarget.display_name then
        print("display_name is nil")
        return
    else
        print("newTarget.display_name")
        print(newTarget.display_name)
    end    



    newTarget.tweaks_name = tostring(target:GetTweakDBDisplayName(true))
    if not newTarget.tweaks_name then
        print("tweaks_name is nil")
        return
    else
        print("newTarget.tweaks_name")
        print(newTarget.tweaks_name)
    end

    newTarget.tweaks_db_name = tostring(target:GetRecordID()):match("%-%-%[%[%s*(.-)%s*%-%-%]%]")
    if not newTarget.tweaks_db_name then
        print("tweaks_db_name is nil")
        return
    else
        print("newTarget.tweaks_db_name")
        print(newTarget.tweaks_db_name)
    end

    newTarget.appearance = NameToString(target:GetCurrentAppearanceName())
    if not newTarget.appearance then
        print("appearance is nil")
        return
    else
        print("newTarget.appearance")
        print(newTarget.appearance)
    end

    if CyberNPC.IsUnnamedNPC(newTarget) then
        newTarget.display_name = CyberNPC.NPCRandomNickName(newTarget.appearance)
    end
    if newTarget.record_id_hash == CyberNPC.LastNPCTarget.record_id_hash then
        newTarget.LLamaNPCFood = CyberNPC.LLamaNPCFood
        newTarget.LLamaNPCHydration = CyberNPC.LLamaNPCHydration
        newTarget.LLamaNPCFun = CyberNPC.LLamaNPCFun
        newTarget.LLamaNPCRelationship = CyberNPC.LLamaNPCRelationship
    else        
        newTarget.LLamaNPCFood = CyberNPC.GetFood(newTarget.record_id_hash) or 0
        newTarget.LLamaNPCHydration = CyberNPC.GetHydration(newTarget.record_id_hash) or 0
        newTarget.LLamaNPCFun = CyberNPC.GetFun(newTarget.record_id_hash) or 0
        newTarget.LLamaNPCRelationship =  CyberNPC.GetRelationship(newTarget.record_id_hash) or 0
    end


    CyberNPC.LastNPCTarget.obj = newTarget.obj
    CyberNPC.LastNPCTarget.id = newTarget.id
    CyberNPC.LastNPCTarget.record_id = newTarget.record_id
    CyberNPC.LastNPCTarget.id_hash = newTarget.id_hash
    CyberNPC.LastNPCTarget.record_id_hash = newTarget.record_id_hash
    CyberNPC.LastNPCTarget.class_name = newTarget.class_name
    CyberNPC.LastNPCTarget.tweaks_name = newTarget.tweaks_name
    CyberNPC.LastNPCTarget.tweaks_db_name = newTarget.tweaks_db_name
    CyberNPC.LastNPCTarget.appearance = newTarget.appearance
    CyberNPC.LastNPCTarget.is_smoker = math.random(100) < 20
    CyberNPC.LastNPCTarget.is_follower = AIControl.IsFollower(newTarget.obj)


    if  CyberNPC.LastNPCTarget.record_id_hash_scanned == CyberNPC.LastNPCTarget.record_id    
    and CyberNPC.LastNPCTarget.display_name_scanned then
        print("Updating display_name to the last scanned since record_id_scanned is entity")
        print("CyberNPC.LastNPCTarget.display_name_scanned")
        print(CyberNPC.LastNPCTarget.display_name_scanned)
        CyberNPC.LastNPCTarget.display_name = CyberNPC.LastNPCTarget.display_name_scanned
    else
        print("Updating display_name to the current entity")
        print("new target")
        print(newTarget.display_name)
        CyberNPC.LastNPCTarget.display_name = newTarget.display_name
    end
    
    CyberNPC.UpdateCachedTargetByRecordIdHash(newTarget, newTarget.record_id_hash)
end

-- you need to use 
function CyberNPC.UpdateCachedTargetByDisplayName(newTarget, displayName)
    local found = false
    for i = 1, #CyberNPC.CachedLastNPCTargets do
        if CyberNPC.CachedLastNPCTargets[i].display_name and CyberNPC.CachedLastNPCTargets[i].display_name == displayName then
            found = true 
            print("UpdateCachedTargetByDisplayName: Found cached npc")
            CyberNPC.CachedLastNPCTargets[i].id =                   newTarget.id
            CyberNPC.CachedLastNPCTargets[i].record_id =            newTarget.record_id
            CyberNPC.CachedLastNPCTargets[i].id_hash =              newTarget.id_hash
            CyberNPC.CachedLastNPCTargets[i].record_id_hash =       newTarget.record_id_hash
            CyberNPC.CachedLastNPCTargets[i].class_name =           newTarget.class_name
            CyberNPC.CachedLastNPCTargets[i].display_name =         newTarget.display_name
            CyberNPC.CachedLastNPCTargets[i].tweaks_name =          newTarget.tweaks_name
            CyberNPC.CachedLastNPCTargets[i].tweaks_db_name =       newTarget.tweaks_db_name
            CyberNPC.CachedLastNPCTargets[i].appearance =           newTarget.appearance
            CyberNPC.CachedLastNPCTargets[i].is_smoker =            newTarget.is_smoker
            CyberNPC.CachedLastNPCTargets[i].is_follower =          newTarget.is_follower            
            CyberNPC.CachedLastNPCTargets[i].LLamaNPCFood =         newTarget.LLamaNPCFood
            CyberNPC.CachedLastNPCTargets[i].LLamaNPCHydration =    newTarget.LLamaNPCHydration
            CyberNPC.CachedLastNPCTargets[i].LLamaNPCFun =          newTarget.LLamaNPCFun
            CyberNPC.CachedLastNPCTargets[i].LLamaNPCRelationship = newTarget.LLamaNPCRelationship
        end
    end
    if not found then
        print("UpdateCachedTargetByDisplayName: adding to cache")
        table.insert(CyberNPC.CachedLastNPCTargets, newTarget) 
    end
end

function CyberNPC.UpdateCachedTargetByRecordIdHash(newTarget, record_id_hash)
    local found = false
    for i = 1, #CyberNPC.CachedLastNPCTargets do
        if CyberNPC.CachedLastNPCTargets[i].record_id_hash and CyberNPC.CachedLastNPCTargets[i].record_id_hash == record_id_hash then
            found = true 
            print("UpdateCachedTargetByDisplayName: Found cached npc")
            CyberNPC.CachedLastNPCTargets[i].id =                   newTarget.id
            CyberNPC.CachedLastNPCTargets[i].record_id =            newTarget.record_id
            CyberNPC.CachedLastNPCTargets[i].id_hash =              newTarget.id_hash
            CyberNPC.CachedLastNPCTargets[i].record_id_hash =       newTarget.record_id_hash
            CyberNPC.CachedLastNPCTargets[i].class_name =           newTarget.class_name
            CyberNPC.CachedLastNPCTargets[i].display_name =         newTarget.display_name
            CyberNPC.CachedLastNPCTargets[i].tweaks_name =          newTarget.tweaks_name
            CyberNPC.CachedLastNPCTargets[i].tweaks_db_name =       newTarget.tweaks_db_name
            CyberNPC.CachedLastNPCTargets[i].appearance =           newTarget.appearance
            CyberNPC.CachedLastNPCTargets[i].is_smoker =            newTarget.is_smoker
            CyberNPC.CachedLastNPCTargets[i].is_follower =          newTarget.is_follower            
            CyberNPC.CachedLastNPCTargets[i].LLamaNPCFood =         newTarget.LLamaNPCFood
            CyberNPC.CachedLastNPCTargets[i].LLamaNPCHydration =    newTarget.LLamaNPCHydration
            CyberNPC.CachedLastNPCTargets[i].LLamaNPCFun =          newTarget.LLamaNPCFun
            CyberNPC.CachedLastNPCTargets[i].LLamaNPCRelationship = newTarget.LLamaNPCRelationship
        end
    end
    if not found then
        print("UpdateCachedTargetByDisplayName: adding to cache")
        table.insert(CyberNPC.CachedLastNPCTargets, newTarget) 
    end
end

function CyberNPC.GetFood(record_id_hash)
    if not record_id_hash then return end
    if record_id_hash == CyberNPC.LastNPCTarget.record_id_hash then
        return CyberNPC.LastNPCTarget.LLamaNPCFood
    else
        local npc = CyberNPC.GetCachedNPCTargetByRecordIdHash(record_id_hash)
        if not npc then return end
        return npc.LLamaNPCFood
    end
end

function CyberNPC.GetHydration(record_id_hash)
    if not record_id_hash then return end
    if record_id_hash == CyberNPC.LastNPCTarget.record_id_hash then
        return CyberNPC.LastNPCTarget.LLamaNPCHydration
    else
        local npc = CyberNPC.GetCachedNPCTargetByRecordIdHash(record_id_hash)
        if not npc then return end
        return npc.LLamaNPCHydration
    end
end

function CyberNPC.GetFun(record_id_hash)
    if not record_id_hash then return end
    if record_id_hash == CyberNPC.LastNPCTarget.record_id_hash then
        return CyberNPC.LastNPCTarget.LLamaNPCFun
    else
        local npc = CyberNPC.GetCachedNPCTargetByRecordIdHash(record_id_hash)
        if not npc then return end
        return npc.LLamaNPCFun
    end
end

function CyberNPC.GetRelationship(record_id_hash)
    if not record_id_hash then return end
    if record_id_hash == CyberNPC.LastNPCTarget.record_id_hash then
        return CyberNPC.LastNPCTarget.LLamaNPCRelationship
    else
        local npc = CyberNPC.GetCachedNPCTargetByRecordIdHash(record_id_hash)
        if not npc then return end
        return npc.LLamaNPCRelationship
    end
end

function CyberNPC.GetCachedNPCTargetByRecordIdHash(record_id_hash)
    for i = 1, #CyberNPC.CachedLastNPCTargets do
        if CyberNPC.CachedLastNPCTargets[i].record_id_hash and CyberNPC.CachedLastNPCTargets[i].record_id_hash == record_id_hash then
            return CyberNPC.CachedLastNPCTargets[i]
        end
    end
    return nil
end
function CyberNPC.GetAllCachedNPCTargetByRecordIdHash(record_id_hash)
    local iamTheTable = {}
    for i = 1, #CyberNPC.CachedLastNPCTargets do
        if CyberNPC.CachedLastNPCTargets[i].record_id_hash and CyberNPC.CachedLastNPCTargets[i].record_id_hash == record_id_hash then
            table.insert(iamTheTable, CyberNPC.CachedLastNPCTargets[i])            
        end
    end
    return iamTheTable
end
function CyberNPC.ForEachCachedNPCTargetByRecordIdHash(record_id_hash, applyFn)
    for i = 1, #CyberNPC.CachedLastNPCTargets do
        if CyberNPC.CachedLastNPCTargets[i].record_id_hash and CyberNPC.CachedLastNPCTargets[i].record_id_hash == record_id_hash then
            applyFn(CyberNPC.CachedLastNPCTargets[i])
        end
    end
end

function CyberNPC.GetCachedNPCTargetByDisplayName(displayName)
    for i = 1, #CyberNPC.CachedLastNPCTargets do
        if CyberNPC.CachedLastNPCTargets[i].display_name and CyberNPC.CachedLastNPCTargets[i].display_name == displayName then
            return CyberNPC.CachedLastNPCTargets[i]
        end
    end
    return nil
end



function CyberNPC.RemoveFirstCachedTargetByDisplayName(displayName)
    print("RemoveFirstCachedTargetByDisplayName " .. displayName)
    for i = 1, #CyberNPC.CachedLastNPCTargets do
        if CyberNPC.CachedLastNPCTargets[i].display_name and CyberNPC.CachedLastNPCTargets[i].display_name == displayName then
            print("RemoveFirstCachedTargetByDisplayName removed")
            table.remove(CyberNPC.CachedLastNPCTargets, i)
            return
        end
    end
end


function CyberNPC.VIsNotInCombat()
    return CyberNPC.LastCombatState == 0 or CyberNPC.LastCombatState == 2
end

function CyberNPC.VIsInCombat()
    return CyberNPC.LastCombatState == 1
end

---@return entEntity|nil
function CyberNPC.GetLastTarget()
    if not CyberNPC.LastNPCTarget then
        print("LastNPCTarget is nil")
        return nil
    end
    if CyberNPC.LastNPCTarget.obj == nil then
        print("LastNPCTarget is nil")
    else
        return CyberNPC.LastNPCTarget.obj
    end

    if not CyberNPC.LastNPCTarget.id or CyberNPC.LastNPCTarget.id == '' then
        print("LastNPCTarget has no id")
        return
    end

    local target = nil
    if(GameSession.IsLoaded) then
        print("Game.FindEntityByID ...")
        target = Game.FindEntityByID(CyberNPC.LastNPCTarget.id)
    else
        print("game is not loaded")
    end

    if not target then
        print("Game.FindEntityByID delivers nil")
    end
    return target
end

function CyberNPC.MakeEyesGlowGold(target)
    -- local target = CyberNPC.GetLastTarget()
    if target then
---@diagnostic disable-next-line: missing-parameter
        GameObjectEffectHelper.StartEffectEvent(target, "eye_glow_gold")
    end
end

function CyberNPC.StopMakeEyesGlowGold(target)
    -- local target = CyberNPC.GetLastTarget()
    if target then
---@diagnostic disable-next-line: missing-parameter
        GameObjectEffectHelper.StopEffectEvent(target, "eye_glow_gold")
    end
end

function CyberNPC.InACar()
    return (Game['GetMountedVehicle;GameObject'](CyberNPC.LastNPCTarget.obj) ~= nil)
end

function CyberNPC.GetCar()
    return Game['GetMountedVehicle;GameObject'](CyberNPC.LastNPCTarget.obj)
end

function CyberNPC.NPCDisplayMood(target)
    if not target then
        CyberNPC.hud.QuestMessage(
            'REL: ' .. tostring(math.floor(CyberNPC.LLamaNPCRelationship - 0.5))
        .. ' FOOD: ' .. tostring(math.floor(CyberNPC.LLamaNPCFood - 0.5))
        .. ' HYDR: ' .. tostring(math.floor(CyberNPC.LLamaNPCHydration - 0.5))
        .. ' FUN: ' .. tostring(math.floor(CyberNPC.LLamaNPCFun - 0.5)), 15, false)
    else
        CyberNPC.hud.QuestMessage(
            'REL: ' .. tostring(math.floor(target.LLamaNPCRelationship - 0.5))
        .. ' FOOD: ' .. tostring(math.floor(target.LLamaNPCFood - 0.5))
        .. ' HYDR: ' .. tostring(math.floor(target.LLamaNPCHydration - 0.5))
        .. ' FUN: ' .. tostring(math.floor(target.LLamaNPCFun - 0.5)), 15, false)
    end
end

-- -- not needed. made it just in case 
function CyberNPC.NPCGetInfo(target)
    if target:isNPC() then
        return {
            id = target:GetEntityID(),
            id_hash = tostring(target:GetEntityID().hash) or '',
            record_id = target:GetRecordID() or '',
            record_id_hash =  tostring(target:GetRecordID().hash) or '',
            class_name = NameToString(target:GetClassName()) or '',
            display_name = tostring(target:GetDisplayName()) or '',
            tweaks_name = tostring(target:GetTweakDBDisplayName(true)) or '',
            appearance = NameToString(target:GetCurrentAppearanceName()) or '',
            obj = nil,
        }
    else
        return {
            id = target:GetEntityID(),
            id_hash = tostring(target:GetEntityID().hash) or '',
            record_id = target:GetRecordID() or '',
            record_id_hash = tostring(target:GetRecordID().hash) or '',
            class_name = '',
            display_name = '',
            tweaks_name = '',
            appearance = '',
            obj = nil,
        }
    end
end

function CyberNPC.GetLastNPCTargetCopy()
    -- CyberNPC.FixDisplayName()
    return {
        id = CyberNPC.LastNPCTarget.id,
        appearance = CyberNPC.LastNPCTarget.appearance,
        display_name = CyberNPC.LastNPCTarget.display_name,
        class_name = CyberNPC.LastNPCTarget.class_name,
        obj = CyberNPC.LastNPCTarget.obj,
        id_hash = CyberNPC.LastNPCTarget.id_hash,
        record_id = CyberNPC.LastNPCTarget.record_id,
        record_id_hash = CyberNPC.LastNPCTarget.record_id_hash,
        tweaks_name = CyberNPC.LastNPCTarget.tweaks_name,
        tweaks_db_name = CyberNPC.LastNPCTarget.tweaks_db_name        
    }
end

function CyberNPC.IsLastNPCGanger(ignoreList)    
    local gangsLen = #(Gangs.data)
    for gidx = 1, gangsLen do
        local ignore = false
        for iListIdx = 1, #ignoreList do
            if Gangs.data[gidx].name == ignoreList[iListIdx] then
                ignore = true
            end
        end
        if not ignore and string.match(string.lower(CyberNPC.LastNPCTarget.appearance), Gangs.data[gidx].name) then            
            return true
        end
    end
    return false
end

function CyberNPC.IsUnnamedNPC(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return (not npcInfo.display_name)
        or npcInfo.display_name == ''
        or #(npcInfo.display_name) == 0
        or npcInfo.display_name == 'Customer'
        or npcInfo.display_name == 'Patron'
        or npcInfo.display_name == 'Bar Patron Puppet'
        or npcInfo.display_name == 'Club Patron'
        or npcInfo.display_name == 'Female Club Patron'
        or npcInfo.display_name == 'NPCPuppet'
        or npcInfo.display_name == 'Puppet'
        or npcInfo.display_name == 'NPC Puppet'
end

function CyberNPC.IsVendor(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    local npcNameInLower = string.lower(npcInfo.display_name)
    local npcAppearanceInLower = string.lower(npcInfo.appearance)
    return string.match(npcNameInLower, 'vendor') or 
        string.match(npcNameInLower, 'keeper') or
        string.match(npcAppearanceInLower, 'vendor') or
        string.match(npcAppearanceInLower, 'keeper')
end

function CyberNPC.IsCop(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    local npcNameInLower = string.lower(npcInfo.display_name)
    local npcAppearanceInLower = string.lower(npcInfo.appearance)
    return string.match(npcNameInLower, 'officer') or
    string.match(npcNameInLower, 'cop') or
    string.match(npcNameInLower, 'ncpd') or 
    string.match(npcNameInLower, 'maxtac') or 
    string.match(npcNameInLower, 'police') or 
    string.match(npcAppearanceInLower, 'officer') or
    string.match(npcAppearanceInLower, 'cop') or
    string.match(npcAppearanceInLower, 'ncpd') or 
    string.match(npcAppearanceInLower, 'maxtac') or 
    string.match(npcAppearanceInLower, 'police')
end

function CyberNPC.IsResident(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    local npcNameInLower = string.lower(npcInfo.display_name)
    return string.match(npcNameInLower, 'resident')
end

function CyberNPC.IsNotTargetable(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    local npcNameInLower = string.lower(npcInfo.appearance)
    return string.match(npcNameInLower, 'children') or
        string.match(npcNameInLower, 'teen') or
        string.match(npcNameInLower, 'youngster')
end

function CyberNPC.IsCorpo(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return string.match(npcInfo.appearance, '_corpo') or
        string.match(npcInfo.appearance, 'corpo_') or
        string.match(npcInfo.appearance, '_corporat') or
        string.match(npcInfo.appearance, 'corporat_')
end

function CyberNPC.IsNomad(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return string.match(npcInfo.appearance, '_aldecaldos') or
        string.match(npcInfo.appearance, 'aldecaldos_') or
        string.match(npcInfo.appearance, '_wraith') or
        string.match(npcInfo.appearance, 'wraith_') or
        string.match(npcInfo.appearance, '_nomad') or
        string.match(npcInfo.appearance, 'nomad_')
end

function CyberNPC.IsLatino(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return string.match(npcInfo.appearance, '_latino') or
        string.match(npcInfo.appearance, 'latino_') or
        string.match(npcInfo.appearance, '_latino') or
        string.match(npcInfo.appearance, 'latino_')
end

function CyberNPC.IsCreole(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return string.match(npcInfo.appearance, '_creole') or
        string.match(npcInfo.appearance, 'creole_') or
        string.match(npcInfo.appearance, '_creole') or
        string.match(npcInfo.appearance, 'creole_')
end

function CyberNPC.IsRich(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return 
        string.match(npcInfo.appearance, '_rich') or
        string.match(npcInfo.appearance, 'rich_') or
        string.match(npcInfo.appearance, '_rich') or
        string.match(npcInfo.appearance, 'rich_')
end

function CyberNPC.IsLowlife(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return 
        string.match(npcInfo.appearance, '_lowlife') or
        string.match(npcInfo.appearance, 'lowlife_')
end

function CyberNPC.IsBig(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return 
        string.match(npcInfo.appearance, '_chubby') or
        string.match(npcInfo.appearance, 'chubby_') or
        string.match(npcInfo.appearance, '_obese') or
        string.match(npcInfo.appearance, 'obese_')
end

function CyberNPC.IsHottie(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return 
        string.match(npcInfo.appearance, '_hottie') or
        string.match(npcInfo.appearance, 'hottie_')
end

function CyberNPC.IsPunk(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return 
        string.match(npcInfo.appearance, '_punk') or
        string.match(npcInfo.appearance, 'punk_')
end


function CyberNPC.IsSlacker(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return 
        string.match(npcInfo.appearance, '_slacker') or
        string.match(npcInfo.appearance, 'slacker_')
end

function CyberNPC.IsRedneck(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return 
        string.match(npcInfo.appearance, '_redneck') or
        string.match(npcInfo.appearance, 'redneck_')
end

function CyberNPC.IsHomeless(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return 
        string.match(npcInfo.appearance, '_homeless') or
        string.match(npcInfo.appearance, 'homeless_')
end

function CyberNPC.IsFemale(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return 
        string.match(npcInfo.appearance , '_wa') or 
        string.match(npcInfo.appearance , 'wa_')
end

function CyberNPC.IsMale(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    return 
        string.match(npcInfo.appearance , '_ma') or 
        string.match(npcInfo.appearance , 'ma_')
end

function CyberNPC.IsFixer(targetInfo)
    local npcInfo = targetInfo or CyberNPC.LastNPCTarget
    local npcName = string.lower(npcInfo.tweaks_name)
    local npcAppearanceInLower = string.lower(npcInfo.appearance)
    return string.match(npcName, 'wakako') or 
        string.match(npcName, 'regina') or 
        string.match(npcName, 'dino') or 
        string.match(npcName, 'capitan') or
        string.match(npcName, 'padre') or 
        string.match(npcName, 'rogue') or
        string.match(npcName, 'dakota') or
        string.match(npcName, 'viktor') or 
        string.match(npcName, 'mikhail') or
        string.match(npcName, 'muamar') or
        string.match(npcName, 'faraday') or
        string.match(npcName, 'dexter') or
        string.match(npcName, 'wakako') or
        string.match(npcName, 'cormac') or
        string.match(npcAppearanceInLower, 'regina') or 
        string.match(npcAppearanceInLower, 'viktor') or 
        string.match(npcAppearanceInLower, 'dino') or 
        string.match(npcAppearanceInLower, 'capitan') or
        string.match(npcAppearanceInLower, 'padre') or 
        string.match(npcAppearanceInLower, 'rogue') or
        string.match(npcAppearanceInLower, 'dakota') or
        string.match(npcAppearanceInLower, 'mikhail') or
        string.match(npcAppearanceInLower, 'muamar') or
        string.match(npcAppearanceInLower, 'faraday') or
        string.match(npcAppearanceInLower, 'dexter') or
        string.match(npcAppearanceInLower, 'wakako') or
        string.match(npcAppearanceInLower, 'cormac')
end

function CyberNPC.LastNPCAddContact()
    local lastTarget = CyberNPC.GetLastTarget()
    if lastTarget ~= nil then
        local npcName = CyberNPC.LastNPCTarget.display_name
        if npcName == 'NC Resident' then
            CyberNPC.hud.QuestMessage('Scan the nc resident first')
        else
            local contact = {
                id = CyberNPC.LastNPCTarget.id,
                appearance = CyberNPC.LastNPCTarget.appearance,
                display_name = CyberNPC.LastNPCTarget.display_name,
                class_name = CyberNPC.LastNPCTarget.class_name,
                obj = CyberNPC.LastNPCTarget.obj,
                id_hash = CyberNPC.LastNPCTarget.id_hash,
                record_id = CyberNPC.LastNPCTarget.record_id,
                record_id_hash = CyberNPC.LastNPCTarget.record_id_hash,
                tweaks_name = CyberNPC.LastNPCTarget.tweaks_name,
                tweaks_db_name = CyberNPC.LastNPCTarget.tweaks_db_name,
                LLamaNPCRelationship = CyberNPC.LLamaNPCRelationship,
                LLamaNPCFood = CyberNPC.LLamaNPCFood,
                LLamaNPCHydration = CyberNPC.LLamaNPCHydration,
                LLamaNPCFun = CyberNPC.LLamaNPCFun,
                is_smoker = false,
                is_follower = false
            }
            local addLocation = GameUtils.GetDistrict()
            CyberNPC.phoneControl.AddContact(contact, "PhoneAvatars.Avatar_Unknown", addLocation.main .. ', ' .. addLocation.sub)
            CyberNPC.hud.QuestMessage(npcName .. ' added to contacts')
            local byeLine = CyberNPC.NPCMyNumberLinesRandomLine()
            CyberNPC.UpdateCachedTargetByDisplayName(contact, contact.display_name)
            CyberNPC.NPCSpeak(byeLine, CyberNPC.LastNPCTarget.id_hash, CyberNPC.LastNPCTarget.display_name)
        end
    end
end

function CyberNPC.SpawnNPC(pos, tweaksDbName, appearanceName, attitude, weaponArchetype, onSpawned)
    print("SpawnFriend")
    if not tweaksDbName then
        tweaksDbName = CyberNPC.LastNPCTarget.tweaks_db_name
    end
    if attitude == SpawnAnimus.Friendly then
        local weapon = weaponArchetype
        if not weapon then
            weapon = "Character.Judy"
        end
        TweakDB:SetFlat(tweaksDbName .. ".abilities", TweakDB:GetFlat("Character.Judy.abilities"))
        TweakDB:SetFlat(tweaksDbName .. ".primaryEquipment", TweakDB:GetFlat(weapon .. ".primaryEquipment"))
        TweakDB:SetFlat(tweaksDbName .. ".secondaryEquipment", TweakDB:GetFlat("Character.Judy.secondaryEquipment"))
        TweakDB:SetFlat(tweaksDbName .. ".archetypeData", TweakDB:GetFlat("Character.Judy.archetypeData"))
    end

    -- print("appearance is " .. (appearanceName or "nil"))
    local npcSpec = DynamicEntitySpec.new()
    npcSpec.appearanceName = appearanceName or ""
    npcSpec.position = Vector4:new(pos.x, pos.y, pos.z, 1)
    npcSpec.orientation = CyberV.GetOppositeOrientation(180)
    npcSpec.persistState = false
    npcSpec.persistSpawn = false
    npcSpec.alwaysSpawned = false
    npcSpec.spawnInView = true

    print("recordId = " .. tweaksDbName)
    npcSpec.recordID = TweakDBID.new(tweaksDbName)

    local desLoc = GetDES()
    if not desLoc then
        print("Dynamic entity system not found")
        return
    end

    local frenId = desLoc:CreateEntity(npcSpec)
    if not frenId then
        print("SpawnEnemy: frenId is nil and could not be created: " .. appearanceName)
        return
    end

    local tick = 1
    SpawnNPCCron = Cron.Every(
        0.2,
        function()
            SpawnNPCTick = SpawnNPCTick + 1

            if SpawnNPCTick > 30 then
                Cron.Halt(SpawnNPCCron)
            end

            local entity = Game.FindEntityByID(frenId)
            if entity then
                CyberNPC.UpdateTargetInfo(entity)
                if onSpawned then
                    onSpawned(entity)
                end
                if attitude then
                    if attitude == SpawnAnimus.Enemy then
                        AIControl.MakeAggro(entity, Game.GetPlayer())
                    elseif attitude == SpawnAnimus.Friendly then
                        AIControl.MakeFollower(entity, moveMovementType.Sprint)
                        AIControl.EquipWeapon(entity)
                    elseif attitude == SpawnAnimus.Psycho then
                        AIControl.MakePsycho(entity, nil)
                    else
                    end
                end
                Cron.Halt(SpawnNPCCron)
            end
        end, {})
    return true
end

CyberNPC.NPCTooFastLines = {
    "Are we running from the Arasaka hit squad, or is this just your regular driving?",
    "Nice speed! Is this a car or a hoverboard in disguise?",
    "I didn’t know we were late for a meeting with the Netrunner Council.",
    "If I wanted to feel the rush of impending doom, I’d have joined a gang.",
    "Remember, there’s a big difference between ‘fast’ and ‘only slightly alive’!",
    "You ought to paint a target on this car; it’d be a lot safer.",
    "Is your brain cyberware set to ‘hyperdrive’ mode?",
    "Great, another joyride for the street racing gods.",
    "I didn’t bring my crash helmet for a reason, you know!",
    "Please tell me you actually know how to steer this thing.",
    "If we keep this up, I might just start considering a new profession.",
    "Is this your way of testing out that new suspension, or are you just showing off?",
    "Think you could save some of that speed for the enemy? Just a thought!",
    "Whoa! Are you trying to break the sound barrier or just my spine?",
    "I hope you’ve got insurance for this ride!",
    "Flying through Night City. Do we need a flight plan or just a death wish?",
    "If I wanted a thrill, I’d ride with a gang, not a speed demon!",
    "Is this how you impress your last date? Because it’s working!",
    "Never knew a merc could run a taxi service to the afterlife!",
    "At this speed, I hope you’ve upgraded your evasive maneuvers!",
    "Careful! This isn’t a video game; I can’t respawn if we crash!",
    "I didn’t sign up for a real-life Fast and Furious sequel!",
    "Is there a prize for reckless driving I don’t know about?",
    "Does this car come with a ‘hold on for dear life’ feature?",
    "I trust you about as much as I trust a fixer in a back alley!",
    "Please, let’s not turn this car into a pile of rubbish!",
    "Are we racing or just speeding to our doom?",
    "I forgot my crash helmet!",
    "If we die, I’m blaming you!",
    "Great! I always wanted to meet my maker!",
    "Speed limit? Never heard of it!",
    "Is this a joyride or a death wish?",
    "Nice way to test your brakes!",
    "Do we need a map to the grave?",
    "I love the smell of burnt rubber!",
    "Slow down!",
    "Ever heard of a speed bump?",
    "Are we trying to outrun the police?",
    "Do you take driving lessons from Netrunners?",
    "I hope you have a backup plan!",
    "Welcome to the rollercoaster!",
    "Great driving! Are we late for something?",
    "This isn’t a race, you know!",
    "Are you aiming for a world record?",
    "Nice speed! Do you want a medal?",
    "Who needs speed limits anyway?",
    "Did I forget to sign a waiver?",
    "Hold on! We’re going to break the sound barrier!",
    "Just what I wanted—an early trip to oblivion!",
    "Perfect time for a highway patrol to show up!",
    "Are we doing a heist or just trying to die?",
    "I’d prefer a calmer ride, thanks!",
    "This is why I don’t trust drivers!",
    "Your driving could use a little more caution!",
    "Trying to impress the street racers?",
    "Did you install a turbo on this thing?",
    "Careful! I value my limbs!",
    "Got a death wish? Because we’re close!",
    "You trying to set a speed record or something?",
    "Is this a drive-thru for disaster?",
    "Do we have a death wish or just bad luck?",
    "If this were a movie, I'd be screaming right now!",
    "I didn’t bring my seatbelt for a reason!",
    "You know we’re not invincible, right?",
    "I prefer my rides without the thrill of dying!",
    "What’s next, skydiving without a parachute?",
    "Are we auditioning for a car chase scene?",
    "Is the road even a concern for you?",
    "Just what I needed—adrenaline in spades!",
    "Did you trade your brakes for turbo speed?",
    "Is there a prize for this reckless driving?",
    "I hope the afterlife has good insurance!",
    "No brakes? Awesome!",
    "Are we trying to die?",
    "Speed limit? Who needs it?",
    "Is this car made of rubber?",
    "Did you forget the brakes?",
    "Just a casual trip to the grave, huh?",
    "Is this how you impress people?",
    "Nice driving—if we make it!",
    "Do we have a death wish?",
    "Another ticket for sure!",
    "Are we on a suicide mission?",
    "Do you enjoy living dangerously?",
    "We should have a safety briefing!",
    "You think we’re on a racetrack?",
    "Who needs caution, right?",
    "Great, we'll get pulled over!",
    "No brakes? Nice!",
    "Are we dying?",
    "Speed limit? Nah!",
    "Just casual death, huh?",
    "Did you forget brakes?",
    "This is reckless!",
    "Is this a race?",
    "Love the danger!",
    "Another ticket incoming!",
    "This isn’t safe!",
    "Do you want to crash?",
    "We’re going to die!",
    "Great driving skills!",
    "Who needs caution?",
    "We're in trouble!",
    "Fast. Too fast!",
    "Thrill ride, huh?",
    "Nice way to speed!",
    "This is wild!",
    "Is speed your hobby?",
    "Roads are for driving, not flying!",
    "Great idea to floor it!",
    "Living on the edge?",
    "Hope you like risks!",
    "Keep it sane, please!",
    "Going fast is cool, right?",
    "We’re gonna crash!",
    "No worries... until we do!",
    "Last ride, maybe?",
    "You call this driving?",
    "Too fast for my liking!",
    "Is this speed a joke?",
    "Slow down before I pass out!",
    "This is way too fast!",
    "I’m not ready for this speed!",
    "Do you want to lose me?",
    "My heart can’t take this!",
    "You're driving like a lunatic!",
    "This pace is insane!",
    "I need more safety here!",
    "Can we chill a bit?",
    "This isn’t a race, right?",
    "Not a fan of this speed!",
    "You’re killing me here!",
    "Ease off the gas please!",
    "Too fast for me!",
    "Can we slow down?",
    "This is really fast!",
    "I'm not okay with this speed!",
    "You're driving too fast!",
    "This pace is all wrong!",
    "I can't handle this speed!",
    "Ease up a bit!",
    "This isn’t safe!",
    "I don’t like this speed!",
    "Let’s slow it down, please!",
    "I’m feeling rushed!",
    "This is too much speed!",
    "Not a fan of this pace!",
    "Can we go slower?",
    "I’m not comfortable here!"
}
function CyberNPC.NPCTooFastLinesRandomLines()
    local line = math.random(#(CyberNPC.NPCTooFastLines))
    return CyberNPC.NPCTooFastLines[line]
end

CyberNPC.NPCReplyIntroAffirmativeLines  = {
    "Sure, I'm open to chat.",
    "Yes, I can help.",
    "Absolutely, what do you need?",
    "Of course, what’s on your mind?",
    "Yes, I have a moment.",
    "Definitely, what’s up?",
    "I’m here for it!",
    "Sounds good, go ahead.",
    "For sure, what do you want to know?",
    "Yes, I’d be happy to talk.",
    "Sure.",
    "Yes.",
    "Absolutely.",
    "Of course.",
    "I can.",
    "Definitely.",
    "Sounds good.",
    "Go ahead.",
    "I'm here.",
    "Happy to.",
    "For sure.",
    "Totally.",
    "Okay.",
    "I'm in.",
    "Count me in.",
    "Right on.",
    "You bet.",
    "Sure thing.",
    "Fine by me.",
    "Let's do it.",
    "Sounds good.",
    "Absolutely.",
    "I'm down.",
    "Sure enough.",
    "Right away.",
    "Exactly.",
    "I'm on board.",
    "Consider it done.",
    "Ain't that the truth.",
    "You got it.",
    "No problem.",
    "Positive.",
    "That's fine.",
    "Sure as hell.",
    "Sure enough.",
    "Count me in.",
    "I'm all in.",
    "Affirmative.",
    "That's a yes.",
    "Sure, choom.",
    "Absolutely, choom.",
    "I'm game, choom.",
    "Sounds good, choom.",
    "Right on, choom.",
    "I'm down, choom.",
    "You got it, choom.",
    "Ain't that the truth, choom.",
    "Count me in, choom.",
    "I'm all in, choom.",
    "For sure, choom.",
    "I'm in, choom.",
    "No problem, choom.",
    "You bet, choom.",
    "That's a yes, choom.",
    "Totally, choom.",
    "Sure enough, choom.",
    "Exactly, choom.",
    "Consider it done, choom.",
    "That's fine, choom.",
    "I'm on board, choom.",
    "Sure thing, choom.",
    "I'm with you, choom.",
    "Go for it, choom.",
    "You bet, choom.",
    "Roger that, choom.",
    "Right up my alley, choom.",
    "Done deal, choom.",
    "For sure, choom.",
    "Count me in, choom.",
    "Sounds like a plan, choom.",
    "In agreement, choom.",
    "No doubt, choom.",
    "Absolutely, choom.",
    "I'm all about it, choom.",
    "Game on, choom.",
    "Yes indeed, choom.",
    "Happy to oblige, choom.",
    "At your service, choom.",
    "On it, choom.",
    "Sure, why not, choom.",
    "All systems go, choom.",
    "Sure thing.",
    "I'm with you.",
    "Go for it.",
    "You bet.",
    "Roger that.",
    "Right up my alley.",
    "Done deal.",
    "For sure.",
    "Count me in.",
    "Sounds like a plan.",
    "In agreement.",
    "No doubt.",
    "Absolutely.",
    "I'm all about it.",
    "Game on.",
    "Yes indeed.",
    "Happy to oblige.",
    "At your service.",
    "On it.",
    "Sure, why not.",
    "All systems go.",
    "That works for me.",
    "I'm in.",
    "Check!",
    "You got it.",
    "That's cool.",
    "Count me in.",
    "I'm available.",
    "No worries.",
    "For certain.",
    "That’s a plan.",
    "I’m all for it.",
    "Sounds right.",
    "I second that.",
    "I'm down for that.",
    "Will do.",
    "Gladly.",
    "Absolutely, no problem.",
    "Affirmative.",
    "I'm ready.",
    "No objections.",
    "Definitely on board.",
    "I agree.",
    "Sure, let's do it.",
    "No questions here.",
    "I'm totally in.",
    "Sounds perfect.",
    "I'm excited about that.",
    "Right on cue.",
    "I'm all set.",
    "That fits.",
    "I stand by that.",
    "It's a go.",
    "That's my vibe.",
    "Count on me.",    
    "Let's make it happen.",
    "I'm open to it.",
    "You have my support.",
    "I'm here for it."
}
function CyberNPC.NPCReplyIntroAffirmativeLinesRandomLines()
    local line = math.random(#(CyberNPC.NPCReplyIntroAffirmativeLines))
    return CyberNPC.NPCReplyIntroAffirmativeLines[line]
end

CyberNPC.NPCReplyIntroNegativeLines = {
    "Not really.",
    "I can't do that.",
    "That's not possible.",
    "I'm not interested.",
    "No way.",
    "I'd rather not.",
    "That's a no for me.",
    "I'm busy.",
    "Not today.",
    "That's not my thing.",
    "I'm out.",
    "No, thanks.",
    "I'm not up for it.",
    "I can't go.",
    "Don't think so.",
    "That's not going to work.",
    "I’d prefer not to.",
    "Nope.",
    "That's not happening.",
    "I can't commit.",
    "No chance.",
    "Not a chance in hell.",
    "Get lost.",
    "Not interested, buzz off.",
    "Hell no.",
    "Get out of here.",
    "Not happening.",
    "Hell no, not today.",
    "Why would I?",
    "Don't push it.",
    "Not in your life.",
    "Leave me alone.",
    "You must be joking.",
    "Not on your life.",
    "Don't count on it.",
    "Not my problem.",
    "Not even close.",
    "Cut it out.",
    "Give it a rest.",
    "Take a hike.",
    "No way.",
    "Forget it.",
    "Not interested.",
    "Get lost.",
    "Move along.",
    "Not my problem.",
    "No chance.",
    "Not happening.",
    "Don't bother.",
    "Leave me be.",
    "Not today.",
    "I don't care.",
    "Cut it out.",
    "Not for me.",
    "Stay out of it.",
    "Save it.",
    "Back off.",
    "Not buying it.",
    "Who do you think you are?",
    "Not falling for that.",
    "Step away.",
    "You're shady.",
    "What do you want?",
    "I don't trust you.",
    "Nice try, but no.",
    "Get out of my face.",
    "Don't get too close.",
    "Not interested in your game.",
    "I see through you.",
    "Keep your distance.",
    "Not worth my time.",
    "Stay back.",
    "I don't play games.",
    "Too sketchy for me.",
    "You got something to prove?",
    "Not a chance.",
    "I'm watching you.",
    "No deal.",
    "What’s your hustle?",
    "You seem off.",
    "Not falling for your tricks.",
    "I’m not in the mood.",
    "You’re not fooling anyone.",
    "I’m not your target.",
    "Keep your hands to yourself.",
    "Get lost, trickster.",
    "I don’t trust you.",
    "Not interested, shady.",
    "You're not fooling me.",
    "Scram, I'm busy.",
    "What’s your deal?",
    "Too dangerous for me.",
    "Cut the nonsense.",
    "Watch your step.",
    "I’ve got no time for you.",
    "Not today, thief.",
    "I see your type.",
    "No chance, scammer.",
    "Not my problem, creep.",
    "I’m done here.",
    "Keep your distance.",
    "Not my style.",
    "You’re all talk.",
    "Not falling for it.",
    "I don’t like your vibe.",
    "Are you serious?",
    "I'm not buying your act.",
    "Take your hustle elsewhere.",
    "You're too sketchy.",
    "I've seen better.",
    "Not in the mood for games.",
    "Find someone else.",
    "No way, not interested.",
    "Not worth the risk.",
    "I’ll pass.",
    "This ain't gonna work.",
    "I doubt you.",
    "Not on my watch.",
    "I've got no use for you.",
    "Too risky for me.",
    "I’m not your target.",
    "Cut the crap.",
    "Stay out of my business.",
    "You’re not trustworthy.",
    "I've had enough.",
    "I don’t need your trouble.",
    "You’re barking up the wrong tree.",
    "No thanks, buddy.",
    "Not interested, lowlife.",
    "I’m not into your games.",
    "No, thanks.",
    "I’ll pass.",
    "Not for me.",
    "I appreciate it, but no.",
    "Thanks, but no.",
    "Not interested.",
    "I’ll decline.",
    "Thanks, but I’m busy.",
    "I can’t do that.",
    "Not right now."
}

function CyberNPC.NPCReplyIntroNegativeLinesRandomLines()
    local line = math.random(#(CyberNPC.NPCReplyIntroNegativeLines))
    return CyberNPC.NPCReplyIntroNegativeLines[line]
end

CyberNPC.NPCAffectionateLines = {
    "You have a captivating smile that lights up the room.",
    "Every moment with you feels like a new adventure.",
    "There's something about the way you look at me that I can't resist.",
    "You make this city feel a little less cold.",
    "I didn’t believe in sparks until I met you.",
    "Is it just me, or is there something special between us?",
    "Every time you laugh, it makes my day a bit brighter.",
    "I can't help but get lost in your eyes.",
    "You’ve definitely stolen a piece of my heart.",
    "Just being near you makes everything feel right.",
    "I think we could create some amazing memories together.",
    "You have a way of making everything more exciting.",
    "I find myself wanting to know everything about you.",
    "Your vibe is absolutely magnetic.",
    "If charm were a crime, you'd be serving a life sentence.",
    "I could get lost in a conversation with you for hours.",
    "There’s a warmth about you that draws me in.",
    "If kisses were snowflakes, I’d send you a blizzard.",
    "You have an incredible way of making the ordinary feel extraordinary.",
    "Just the thought of you brightens my day.",
    "Your laugh is like music; I could listen to it all night.",
    "I must admit, you’ve been on my mind a lot lately.",
    "There’s a certain magic in the air whenever you’re around.",
    "You have a charm that’s hard to resist.",
    "Every glance from you sends butterflies through me.",
    "You make even the darkest nights feel a little brighter.",
    "It’s not just your looks; there’s something truly special about you.",
    "With you, every moment feels like a scene from a dream.",
    "I love the way you brighten up the room when you walk in.",
    "Being with you feels like coming home.",
    "You have a spark that lights up my night.",
    "Every time you’re near, my heart skips a beat.",
    "You make the chaos of this city feel like a sweet melody.",
    "There’s definitely a connection here—can you feel it too?",
    "Your presence is like a breath of fresh air in this place.",
    "I could get lost in your eyes and never want to find my way out.",
    "You have an enchanting way of making everything more exciting.",
    "If I had a flower for every time you made me smile, I’d have a garden.",
    "You’re the kind of person who could turn a dull day into pure magic.",
    "Just being around you brings out my best self.",
    "You’ve got that special something that keeps me coming back for more.",
    "Every moment with you feels like the best chapter in my story.",
    "You’ve woven a spell that I don’t want to escape from.",
    "Your laughter has a way of wrapping around my heart.",
    "I could sit here and just admire you for hours.",
    "I really enjoy spending time with you.",
    "You make me smile whenever I see you.",
    "I love the way you think—it's refreshing.",
    "You have an amazing sense of style.",
    "I can't help but be drawn to your energy.",
    "Talking to you is always the highlight of my day.",
    "You have such a captivating presence.",
    "I admire your confidence; it's really attractive.",
    "Being around you just feels right.",
    "You have a wonderful laugh; it brightens my mood.",
    "I would love to get to know you better.",
    "You’re the kind of person I’d love to share a drink with.",
    "Your vibe is just so inviting.",
    "I appreciate how genuine you are.",
    "I find myself thinking about you often.",
    "I really like how easy it is to talk to you.",
    "You have a smile that’s hard to forget.",
    "I enjoy the way you see the world.",
    "I can’t help but admire your passion.",
    "It’s nice to be around someone who gets it.",
    "You make even ordinary moments feel special.",
    "I find you incredibly interesting.",
    "You have a charm that makes everything better.",
    "I love how you always know just what to say.",
    "It’s hard not to be drawn to your positivity.",
    "You seem like someone I’d love to hang out with often.",
    "You have an authentic vibe that instantly makes me comfortable.",
    "I appreciate your kindness; it really stands out.",
    "You have a way of making people feel valued.",
    "I’d love to explore more places with you.",
    "You have a captivating energy.",
    "There’s something magnetic about you.",
    "You definitely know how to light up a room.",
    "I can’t help but admire your confidence.",
    "You have a way of making everything feel exciting.",
    "Your smile is contagious.",
    "You bring a spark wherever you go.",
    "I love how genuine you are.",
    "You’re a breath of fresh air.",
    "Your vibe is truly special.",
    "There’s an undeniable chemistry in the air.",
    "You have a style that’s all your own.",
    "You make the ordinary feel extraordinary.",
    "Your laugh is one of my favorite sounds.",
    "You seem like someone who knows how to have fun.",
    "You have a way of catching my eye.",
    "There’s a charm about you that’s hard to resist.",
    "You always leave me wanting to know more.",
    "Your style is as striking as your personality.",
    "You give off such an inviting energy.",
    "I find myself drawn to you in the best way.",
    "You seem like someone I’d love to explore with.",
    "There's a spark in your eyes that I appreciate.",
    "You have a captivating presence that makes everything better.",
    "You light up the night in your own unique way.",
    "Your confidence is incredibly attractive.",
    "You have a talent for turning heads.",
    "You have a great sense of adventure about you.",
    "You’re the kind of person who stands out in a crowd.",
    "I can see why so many are drawn to you.",
    "You definitely know how to turn heads.",
    "There's something dangerously attractive about you.",
    "You have a vibe that makes everything feel electric.",
    "I can't help but be intrigued by you.",
    "You’ve got that magnetic pull that draws people in.",
    "Being around you feels like an adventure waiting to happen.",
    "You’ve definitely stolen the spotlight here.",
    "You exude a confidence that’s hard to ignore.",
    "You’re the kind of thrill this city needs.",
    "Your presence makes everything more exciting.",
    "You’ve got a spark that ignites curiosity.",
    "There’s an allure to you that I can’t resist.",
    "You make even the simplest moments feel spontaneous.",
    "You bring an energy that’s positively infectious.",
    "You’ve got a style that commands attention.",
    "You’ve got that irresistible charm that keeps me coming back.",
    "You light up the room like no one else.",
    "I can’t help but admire your daring spirit.",
    "You have a way of making mischief sound enticing.",
    "You’re the kind of trouble I wouldn't mind getting into.",
    "Every time I see you, I find myself smiling for no reason.",
    "You’ve got a confidence that’s downright captivating.",
    "There's an exciting spark in the air whenever you're around.",
    "You’ve got that fire that makes everything more fun.",
    "You seem like the type who knows how to enjoy life to the fullest.",
    "Your energy is like a shot of adrenaline.",
    "You have a unique flair that’s impossible to overlook.",
    "I bet you’re the reason this place feels more lively.",
    "You make everyday moments feel worth remembering.",
    "You’ve got a way of making the ordinary feel extraordinary.",
    "Every glance from you sends a thrill down my spine.",
    "You’ve got a vibe that makes the world feel a little brighter.",
    "I can’t help but be drawn to your adventurous spirit.",
    "There’s something exciting in the way you carry yourself.",
    "You have a spark that should come with a warning label.",
    "You make it hard to focus on anything else.",
    "You’ve got this magnetic energy that pulls me in.",
    "Just being near you makes the moment electric.",
    "You’re the kind of person who stands out in the best way.",
    "Your laughter adds an extra beat to my heart.",
    "With you around, every moment feels like pure fun.",
    "You have a way of making mischief seem appealing.",
    "You bring a playful energy that’s hard to resist.",
    "You have a confidence that makes everything more interesting.",
    "You’re the highlight of my day, every time.",
    "You have a presence that makes me want to get to know you better.",
    "Your smile is like a secret that deserves to be shared.",
    "There's a thrill in the air every time you walk by.",
    "You make even the most mundane moments feel exciting.",
    "You’ve definitely got that ‘something special’ vibe.",
    "Just being around you brightens up the darker corners of this city.",
    "You have a playful spirit that’s absolutely captivating.",
    "I find your confidence incredibly attractive.",
    "You make every bit of conversation feel like an adventure.",
    "Your energy is something I’d like to get lost in.",
    "You’ve got a spark that could ignite a whole night.",
    "You’ve turned my head more than once tonight.",
    "I can’t help but want to uncover your mysteries.",
    "You bring a kind of excitement that’s hard to find.",
    "Every moment with you feels like something out of a story.",
    "You’ve got a way of making every word feel like an invitation.",
    "There's something about you that sparks my curiosity.",
    "Every time you laugh, I find myself wanting to know more.",
    "You have a confidence that's utterly irresistible.",
    "The way you carry yourself is truly magnetic.",
    "You must be a magician, because whenever I look at you, everyone else disappears.",
    "You make even the wildest ideas sound possible.",
    "I can’t resist your charm; it’s just too compelling.",
    "You have a fire in you that’s hard to ignore.",
    "You could light up a dark room with just your presence.",
    "You have a playful attitude that matches my own.",
    "Your style is as bold as your personality—very attractive.",
    "You’re the highlight of my evening, no doubt about it.",
    "Every time we talk, I discover something new that I like about you.",
    "You bring an energy that makes everything feel more vibrant."
}
function CyberNPC.NPCAffectionateLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCAffectionateLines))
    return CyberNPC.NPCAffectionateLines[line]
end

CyberNPC.NPCAskHomeLines = {
    "How about we head back to your place?",
    "Want to come over to your place for some privacy?",
    "I'd love for you to join me at your place.",
    "Let’s continue this at your place—what do you say?",
    "Why don’t we go to your place and see where the night takes us?",
    "Want to come to mine for a more intimate setting?",
    "How about a nightcap at your place?",
    "I think it’d be a lot of fun to hang out at your place.",
    "Let’s go to your place and take things to the next level.",
    "I’d really like to invite you back to your place.",
    "Your place isn’t far; want to make the trip with me?",
    "There’s something you need to show me at your place.",
    "Want to experience your place? I promise you won’t regret it.",
    "How about we move this party to your place?",
    "I’m thinking we should go back to your place together.",
    "How about we heat things up at your place?",
    "Ready to turn up the temperature? Let’s go to your place.",
    "Let’s take this energy back to your place for some fun.",
    "I think it's time we moved this chemistry to your place.",
    "Want to skip the small talk and get comfortable at your place?",
    "I can give you a taste of what’s waiting for you at your place.",
    "I’d love to continue this... privately at your place.",
    "Feeling adventurous? Your place is just a short trip away.",
    "Let’s create some sparks together at your place.",
    "I’ve got something special planned at your place—care to join?",
    "You’re definitely invited back to your place for a night to remember.",
    "How about we explore this connection in a more intimate setting—at your place?",
    "Why not come over to your place and see what else we have in common?",
    "I have a feeling we’ll have a lot more fun at your place.",
    "Your place sounds like the perfect spot for an adventure.",
    "How about we turn up the heat at your place?",
    "Let’s move this flirtation to your place and see what happens.",
    "I can’t wait to see what your place has in store for us.",
    "Why don’t we take this excitement back to your place?",
    "Your place sounds like the perfect setting for some fun.",
    "I’d love to take this vibe to your place and make some memories.",
    "You, me, and your place could be quite the adventure.",
    "I’m ready to dive deeper—how about at your place?",
    "Let’s skip the formalities and head to your place.",
    "I have a feeling things will get even more interesting at your place.",
    "Your place should be our next stop—what do you say?",
    "The energy between us deserves a more intimate setting—your place?",
    "How about we turn this spark into a flame at your place?",
    "I bet your place has some stories waiting for us to create.",
    "I can’t think of a better backdrop for this chemistry than your place.",
    "Why not let me take you to your place? I promise we'll have fun.",
    "Your place could be the perfect backdrop for an unforgettable night.",
    "Let’s create some heat in the comfort of your place.",
    "There's a vibe between us that deserves to be explored at your place.",
    "I can’t stop thinking about how amazing it would be at your place.",
    "Your place sounds like the perfect setting for some serious fun.",
    "The chemistry we have might just explode at your place.",
    "I’d love to kick back and explore this connection at your place.",
    "Let’s make the best of this chemistry—your place is calling.",
    "How about we take the excitement to your place and see where it leads?",
    "I have a feeling we’d have an incredible time at your place.",
    "Your place has potential for some real sparks to fly.",
    "I’m all in for an adventure at your place—let’s do it.",
    "Let’s transform this attraction into something unforgettable at your place.",
    "Your place could be the scene for an unforgettable night together.",
    "You know, I could definitely get used to being at your place.",
    "I can just imagine the fun we could have at your place.",
    "There’s something about this moment that makes me think of your place.",
    "I’d love to see how our energy plays out at your place.",
    "Your place seems like it could be the perfect escape for us.",
    "I can already picture us having a great time at your place.",
    "I’m feeling like your place might be our next adventure.",
    "Is it just me, or would your place be an ideal setting for this connection?",
    "I can’t shake the thought of us enjoying ourselves at your place.",
    "Your place has been on my mind—it feels like the right fit for us.",
    "I could see us getting cozy at your place, don’t you think?",
    "There’s something intriguing about the idea of being at your place together.",
    "I wouldn’t mind exploring your place, if the opportunity arises.",
    "I think we’d create some unforgettable moments at your place.",
    "Being at your place sounds like a delightful idea, don’t you agree?",
    "You know, I wouldn’t mind getting lost at your place with you.",
    "Just daydreaming about what could happen at your place has me intrigued.",
    "I can’t help but picture us enjoying some private moments at your place.",
    "Your place seems like it could hold some unforgettable secrets for us.",
    "I find myself wanting to explore the possibilities at your place.",
    "The thought of being at your place together is really tempting.",
    "Your place has that vibe that makes me want to dive deeper into this chemistry.",
    "Is it just me, or would your place be perfect for a little adventure?",
    "I sense that something exciting is waiting for us at your place.",
    "There’s a magnetic pull about your place that draws me in.",
    "You have a way of making the idea of your place feel so inviting.",
    "Every time I think of your place, it ignites my imagination.",
    "I could imagine some thrilling moments at your place, just us.",
    "I bet your place tells stories that we could create together.",
    "The energy between us would be electric at your place.",
    "I can’t stop thinking about how amazing your place would feel with us together.",
    "There's something about the thought of your place that just feels right.",
    "I can already imagine the fun we'd have once we’re at your place.",
    "Your place seems like the perfect hideaway for two adventurous souls.",
    "The idea of being at your place gives me butterflies.",
    "I could see us creating some unforgettable memories at your place.",
    "There's a certain thrill in thinking about what we could explore at your place.",
    "You’ve definitely made your place sound appealing in more ways than one.",
    "Just imagining your place gets me excited about the possibilities.",
    "Your place might just be the perfect getaway for us.",
    "There’s an irresistible charm about your place that pulls me in.",
    "I wouldn’t mind cozying up at your place, if you’re open to it.",
    "The thought of sharing a night at your place has my heart racing.",
    "You have a way of making the idea of your place sound so enticing.",
    "I’m feeling adventurous; your place would be the perfect setting.",
    "I can only imagine how much fun we’d have at your place, just the two of us.",
    "The thought of being alone at your place has my imagination running wild.",
    "Your place could be the perfect backdrop for some unforgettable nights.",
    "Just thinking about what we could explore at your place makes me excited.",
    "You know, your place has been on my mind in the most tempting way.",
    "The idea of us together at your place sends shivers down my spine.",
    "I can’t help but wonder what kind of trouble we could get into at your place.",
    "Just think about the passion we could unleash at your place.",
    "Your place would be the ideal spot for us to let loose and indulge.",
    "I bet I could make you feel really good at your place.",
    "You’ve definitely sparked my interest in what might happen at your place.",
    "I can imagine some very steamy moments shared at your place.",
    "There's an electricity in the air when I think about being at your place with you.",
    "Being at your place could lead to some exciting encounters.",
    "Your place has a certain allure that makes me curious about how things could go.",
    "You know, I could use some time alone with you at your place.",
    "Just thinking about how nice it would be to relax together at your place.",
    "Imagine just the two of us unwinding at your place; sounds tempting, right?",
    "Your place could be the perfect escape for us to enjoy each other’s company.",
    "We’d have the perfect backdrop to explore this chemistry at your place.",
    "There’s something about being at your place that feels right.",
    "I can picture us enjoying some quality time together at your place.",
    "The idea of us being cozy at your place is definitely appealing.",
    "It would be nice to get lost in conversation at your place.",
    "I think we could turn any night into something special at your place.",
    "Your place seems like it could hold some delightful surprises for us.",
    "Just the thought of being wrapped up at your place has me intrigued.",
    "I have a feeling we’d create some unforgettable moments at your place.",
    "There's a warmth at your place that would make for an incredible night.",
    "Getting to know you better at your place sounds like a dream.",
    "I can’t help but think how nice it would be to chill at your place sometime.",
    "It would be great to have a quiet night together at your place.",
    "I can imagine the fun we’d have just hanging out at your place.",
    "You know, your place seems like the perfect spot for some good times.",
    "I often think about how relaxing it would be to unwind at your place.",
    "I’d love to enjoy a cozy evening at your place, just us.",
    "There’s something appealing about the idea of spending time at your place.",
    "I feel like your place could be a great backdrop for some laughs.",
    "It’d be nice to escape to your place for a while, don’t you think?",
    "Just the thought of us at your place brings a smile to my face.",
    "Your place has been on my mind—it feels like a perfect setting.",
    "I could see us enjoying a casual evening at your place together.",
    "I bet your place has some good vibes just waiting for us.",
    "I can completely picture us enjoying ourselves at your place.",
    "What a great scene it would be to relax at your place after all this."
}
function CyberNPC.NPCAskHomeLinesRandowLine()
    local line = math.random(#(CyberNPC.NPCAskHomeLines))
    return CyberNPC.NPCAskHomeLines[line]
end

CyberNPC.NPCMissesVLines = {
    "Thinking of you!",
    "Can't wait to see you again.",
    "Miss hanging out!",
    "Looking forward to our next adventure.",
    "Wish you were here to share this moment.",
    "It’s not the same without you.",
    "Hope to catch up soon!",
    "Missing our chats.",
    "Can’t wait for the next get-together.",
    "You’ve been on my mind lately.",
    "Missing our good times!",
    "Let’s plan a meetup soon.",
    "Wish you could join me here.",
    "I miss our laughter.",
    "Can't wait to share a meal together.",
    "Missing our late-night talks.",
    "I feel the gap when you're not around.",
    "Let’s not let too much time pass between visits.",
    "I miss being silly with you.",
    "You make everything more fun!",
    "It’s quieter without you here.",
    "Can't wait to catch up!",
    "You would love this place!",
    "I miss your energy.",
    "Wish we could have a movie night.",
    "Thinking of all our memories.",
    "I miss our daily chats.",
    "I miss your perspective on things.",
    "I wish you were here to experience this.",
    "I miss our adventures together.",
    "Everything reminds me of you.",
    "I miss our spontaneous outings.",
    "I miss the little things we did together.",
    "You bring a smile to my day!",
    "It's been too long since we laughed together.",
    "I wish you could see this sunset with me.",
    "I miss sharing my thoughts with you.",
    "I can't wait until our paths cross again.",
    "I miss your quirky sense of humor.",
    "Everything feels better when you're around.",
    "I miss the fun we had planning things.",
    "I remember our great conversations!",
    "Wishing you were here to celebrate.",
    "Missing your vibe!",
    "I miss our inside jokes.",
    "Life is just better with you in it.",
    "I miss how easy it was to talk to you.",
    "Can't stop reminiscing about our trips.",
    "I miss sharing random moments with you.",
    "I wish we could grab coffee together.",
    "I miss your warm hugs.",
    "Everything feels different without you.",
    "I miss our late-night adventures.",
    "Wishing you were here to make memories.",
    "I miss our epic game nights.",
    "It feels empty without our chats.",
    "I could use your advice right now.",
    "Everything reminds me of the fun we had together.",
    "I miss exploring together.",
    "I wish we could just hang out like old times.",
    "I miss sharing playlists with you.",
    "Let’s not let distance come between us.",
    "Your absence is felt deeply.",
    "I miss the way you make me laugh.",
    "Can't wait to share stories again.",
    "I miss our deep talks.",
    "I wish you were here to share this moment.",
    "Every day apart feels too long.",
    "I miss the comfort of being with you.",
    "I often find myself wishing you were here.",
    "I miss our silly debates.",
    "Thinking about you brings a smile to my face.",
    "Life’s not the same without your presence.",
    "I miss you, V!",
    "I can't wait to see you again, V.",
    "Missing our adventures together, V.",
    "The streets aren’t the same without you, V.",
    "I wish you were here with me, V.",
    "I miss your fearless approach, V.",
    "Everything feels dull without you, V.",
    "I can't wait until we team up again, V!",
    "Missing your quick wit and charm, V.",
    "It's quieter in Night City without you, V.",
    "Wish we could share a drink at the Afterlife, V.",
    "You make everything an adventure, V; I miss that!",
    "I'm counting the days until we're back together, V.",
    "I miss our late-night talks, V.",
    "You bring the excitement, V; I miss you!",
    "I can't wait for another crazy escapade with you, V.",
    "Feeling your absence in every corner of the city, V.",
    "I miss strategizing with you, V.",
    "I just wish you were here right now, V.",
    "Your spirit is missed, V!",
    "V, the city feels empty without you.",
    "Can't wait to share the next mission, V!",
    "Missing your fire, V.",
    "Every day without you feels like a heist gone wrong, V.",
    "Wish you were here to navigate this chaos with me, V.",
    "The thrill is gone without you, V.",
    "I miss your energy lighting up the night, V.",
    "Life’s more vibrant with you in it, V.",
    "Everything feels off without our teamwork, V.",
    "Each moment feels longer without you, V.",
    "You add color to this concrete jungle, V; I miss that!",
    "I miss your brilliant strategies, V.",
    "Night City isn’t the same without your swagger, V.",
    "I wish we were out there making memories, V.",
    "Missing your laughter echoing through the chaos, V.",
    "I can't help but think of you, V, wherever I go.",
    "I miss conquering challenges by your side, V.",
    "Your absence is a shadow in this city, V.",
    "Time feels slower without you, V.",
    "I miss our shared dreams of a better world, V.",
    "You bring the spark in every fight, V; I miss that!",
    "V, I miss our wild plans.",
    "The streets are quieter without you, V.",
    "Missing your fearless heart, V.",
    "I wish you were here to turn the tide, V.",
    "Each day feels incomplete without you, V.",
    "Can’t wait to hit the streets together again, V.",
    "Everything's slower without your pace, V.",
    "I miss your sharp mind guiding me, V.",
    "The chaos is less lively without you, V.",
    "I wish we could share this moment, V.",
    "Every sunset reminds me of you, V.",
    "Missing the thrill of our escapades, V.",
    "I feel your absence in every corner of this city, V.",
    "You're the missing piece to this puzzle, V.",
    "I miss your spirit lighting the way, V.",
    "Life feels dull when you're not around, V.",
    "I miss how we made every moment count, V.",
    "Can’t wait to make more memories with you, V.",
    "Wishing you could experience this with me, V.",
    "I miss your laughter in the chaos, V.",
    "You make every challenge brighter, V; I miss that!"
}
function CyberNPC.NPCMissesVLinesRandowLine()
    local line = math.random(#(CyberNPC.NPCMissesVLines))
    return CyberNPC.NPCMissesVLines[line]
end

CyberNPC.NPCIntroducePrefixLines = {
    "Great meeting you.",
    "You are the Arasaka heist merc, right?",
    "Aren't you the merc with bad luck? Fuck. Guess I won the lottery at the Sapphire.",
    "Hey! You knew Jackie, right? Sorry for your loss.",
    "Nice to meet you.",
    "Hey, what's up?",
    "Funny running into you here.",
    "I’ve heard tales about your escapades.",
    "So, you’re the infamous one I’ve been hearing about.",
    "I’d say it’s about time we crossed paths.",
    "Word travels fast; everyone knows your name.",
    "I always thought you’d be taller in person.",
    "You’ve got quite the reputation around here.",
    "Always wanted to see if you were as tough as they say.",
    "This city has a way of bringing interesting people together.",
    "I knew I’d eventually bump into you in this chaos.",
    "It’s not every day I meet someone with your history.",
    "I can see why they talk about you so much.",
    "You must have some incredible stories to tell.",
    "Quite the character you are, I've heard.",
    "Well, look who it is!",
    "I've been curious to meet you.",
    "Your name has been floating around quite a bit.",
    "You’re exactly who I thought you'd be.",
    "This place just got a lot more interesting.",
    "I knew our paths would cross eventually.",
    "Interesting city, isn’t it? Full of surprises.",
    "The stories don’t do you justice; it’s great to see you.",
    "I've always wanted to see if the rumors were true.",
    "What a small world we live in, huh?",
    "They say there’s never a dull moment with you around.",
    "This city sure knows how to bring people together.",
    "I feel like I already know you from all the chatter.",
    "You stand out in a crowd; that's for sure.",
    "Everyone speaks highly of you—can’t blame them.",
    "There’s no mistaking that presence of yours.",
    "It’s good to finally put a face to the legend.",
    "Looks like fate dropped us in the same spot.",
    "You’ve sparked quite a bit of curiosity around here.",
    "I’ve got to say, meeting you is on my bucket list.",
    "I had a feeling you’d be as captivating in person.",    
    "I knew you’d eventually make it here.",
    "This city seems to revolve around you, doesn’t it?",
    "So, this is what the mystery looks like.",
    "I’m not surprised to see you in a place like this.",
    "You’ve certainly got a presence about you.",
    "I’ve been looking forward to this moment.",
    "Funny how fate brings us together like this.",
    "Nice to finally meet the talk of the town.",
    "Looks like your reputation precedes you, as usual.",
    "I had a feeling you’d be just as intriguing in person.",
    "You’ve got quite the aura; it’s hard to miss.",
    "What’s the story behind your infamous name?",
    "Isn’t this place just buzzing with energy?",
    "You must be a magnet for interesting encounters.",
    "I always imagined our paths would cross someday.",
    "You’re the kind of person they write songs about.",
    "This is a highlight of my night, for sure.",
    "Aren’t you hard to miss in a crowd?",
    "So, this is the infamous figure I've heard about.",
    "Guess there’s no escaping you in this city.",
    "I’ve heard enough about you; let’s see if it matches.",
    "Well, here we are. What now?",
    "Interesting to finally meet you, for better or worse.",
    "I see you’ve made quite the impression around here.",
    "I wasn't sure if I’d actually run into you.",
    "So, you really do exist outside of the rumors.",
    "I’ve been curious what all this fuss is about.",
    "You certainly have a way of making yourself known.",
    "I hope you’re not as troublesome as they say.",
    "Funny how you ended up here; I’ll reserve judgment.",
    "I’m intrigued, but not entirely convinced yet.",
    "Well, this should be interesting, to say the least.",
    "I can’t say I’m surprised to see you here.",
    "So, what’s it like being a target of everyone’s gossip?",
    "I’ve heard your name too many times to ignore.",
    "Not quite what I expected, but here we are.",
    "It’ll be interesting to see if you live up to the stories.",
    "I hope you’re not as chaotic as people make you out to be.",
    "Let’s see if meeting you is as exciting as it sounds."
}
CyberNPC.NPCIntroduceSuffixLines = {
    "Name's ##NAME##, by the way",
    "My name is ##NAME##",
    "People call me ##NAME##",
    "##NAME## at your disposal",
    "##NAME## is my name. V right?",
    "You can call me ##NAME##",
    "Call me ##NAME##",
    "Name is ##NAME##",
    "They say ##NAME## knows the best spots in town.",
    "Make no mistake, ##NAME## is what you want by your side.",
    "Ever heard of ##NAME##? Let me introduce you.",
    "You're lucky to meet ##NAME##—have a knack for good connections.",
    "In this city, ##NAME## is a name you won’t forget.",
    "Looking for someone who knows the streets? Ask for ##NAME##.",
    "The name’s ##NAME##, and I’m not just anyone.",
    "##NAME## on standby for whatever you need.",
    "You’ll want to remember this name: ##NAME##.",
    "Just ##NAME##, but I get around.",
    "Not just a name, ##NAME## is a legend in these parts.",
    "People whisper about ##NAME##—let’s see if the rumors are true.",
    "If you need info, ##NAME##'s your go-to.",
    "Keep your ears open for ##NAME##; you might learn something.",
    "In a city like this, ##NAME## is always in demand.",
    "Survival of the fittest? Then you need ##NAME## in your corner.",
    "##NAME##—I prefer to keep things interesting.",
    "You can’t just walk away from a meeting with ##NAME##.",
    "The street knows how to find ##NAME##—just listen closely.",
    "Word on the street is that ##NAME## is connected.",
    "When the chips are down, you’ll want ##NAME## by your side.",
    "##NAME## makes the gear turn—just ask around.",
    "Fate brought you to ##NAME## for a reason.",
    "They call me ##NAME##, but you can call me your new ally.",
    "##NAME##—a name that means something in this city.",
    "If you’re looking for thrills, ##NAME## is the right choice.",
    "I’m ##NAME##, and I thrive in chaos.",
    "Don’t forget the name ##NAME##; it might just save your skin.",
    "You’re looking at ##NAME##, the one and only.",
    "In the shadows, they speak of ##NAME##—care to know why?",
    "##NAME##—where danger meets opportunity.",
    "I roll with the punches; I’m ##NAME##.",
    "Curiosity brought you here—I’m ##NAME##.",
    "No one quite knows how ##NAME## operates, but that’s part of the fun.",
    "##NAME##—the name that rings out in alleys and nightclubs.",
    "Ready for a ride with ##NAME##?",
    "Listen closely, and you might just learn why ##NAME## is a name to trust.",
    "##NAME##—let's make this interesting.",
    "They say ##NAME## has the best leads in the city.",
    "You’d do well to remember ##NAME##—not many can say that.",
    "My name? Just call me ##NAME##—everyone else does.",
    "##NAME## here, and I’ve got stories that’ll blow your mind.",
    "You’ve met ##NAME##, now the real game begins.",
    "In a world of noise, ##NAME## is the signal you want to follow.",
    "Just your friendly local ##NAME##, at your service.",
    "##NAME##—I know where the bodies are buried, literally.",
    "What’s a night in Night City without ##NAME##?",
    "I make things happen; I’m ##NAME##.",
    "With ##NAME## around, you can count on a wild ride.",
    "I’ve seen things—name’s ##NAME##; let’s talk.",
    "##NAME##—the name that opens doors and closes deals.",
    "Good to meet you, I’m ##NAME##—let’s not waste time.",
    "Heard of ##NAME##? Well, you have now.",
    "Name’s ##NAME##, nice to meet you.",
    "I’m ##NAME##. Just trying to get by.",
    "You can call me ##NAME##. Hope you’re doing well.",
    "##NAME##, at your service if you need anything.",
    "People around here know me as ##NAME##.",
    "Just ##NAME##—I look out for folks like us.",
    "I go by ##NAME##. Everyone has to start somewhere.",
    "##NAME## here. I’m just looking for a way to help.",
    "You can trust ##NAME## to keep it real.",
    "Not much, just ##NAME##. Let’s see where this goes.",
    "##NAME##—I try to keep a low profile, you know?",
    "I’m ##NAME##, and I’m just here to navigate this city.",
    "We all have our stories. I’m ##NAME##, if you’re interested.",
    "Hello, I’m ##NAME##. What brings you here?",
    "Just a friendly face named ##NAME##. What can I do for you?",
    "I go by ##NAME##. It’s nice to meet someone new.",
    "Just ##NAME##—trying to make sense of it all.",
    "I’m ##NAME##. What about you?",
    "Name’s ##NAME##. I’m here to lend a hand if you need it.",
    "People call me ##NAME##, but I’m just another face in the crowd.",
    "I’m ##NAME##, doing my best in this crazy place.",
    "##NAME##—I try to keep my connections honest.",
    "You can call me ##NAME##. Let’s figure this out together.",
    "Just ##NAME##, looking for good company.",
    "Life's a challenge, but I’m ##NAME##, and I’m here.",
    "Name’s ##NAME##. What’s your story?",
    "I’m not much—just ##NAME## trying to get by.",
    "Name’s ##NAME##. I believe in looking out for each other.",
    "Call me ##NAME##; I’m here if you need someone to talk to.",
    "I’ve seen a bit—I'm ##NAME##, what about you?",
    "Hi, I’m ##NAME##, just here to help where I can.",
}
function CyberNPC.NPCIntroduceLinesRandomLine(name)
    local prefixLine = CyberNPC.NPCIntroducePrefixLines[math.random(#CyberNPC.NPCIntroducePrefixLines)]
    if CyberNPC.IsResident() then
        return prefixLine
    else
        local useNameLineFirst = Chance50()
        local usePrefix = Chance50()       
        local nameLine =  CyberNPC.NPCIntroduceSuffixLines[math.random(#CyberNPC.NPCIntroduceSuffixLines)]:gsub('##NAME##', name)
        if not usePrefix then
            return nameLine
        end
        if useNameLineFirst then
            return nameLine .. "." .. prefixLine
        else
            return prefixLine .. "." .. nameLine
        end
    end
end

CyberNPC.NPCScannedIronicLines = {
    "Ah, the good old retinal scan—a classic way to make friends.",
    "I guess my name would just complicate things.",
    "Who needs conversation when you’ve got a scanner, right?",
    "Next time, I’ll just wear a sign with my data on it.",
    "Why bother with personal connections in the age of tech?",
    "Looks like we're skipping the small talk today.",
    "Guess I’m just a data point now; nice to meet you!",
    "This is what friendship looks like in the future, huh?",
    "So, my name is irrelevant? Glad to know I’m just a number.",
    "Ah yes, the intimate bond formed through retina scans.",
    "Why use words when I can be categorized instantly?",
    "Guess my identity is better left in pixels.",
    "I always wanted to be known by my iris pattern.",
    "Nothing says 'I care' like a high-tech scan.",
    "I didn’t realize we were in such a rush to skip pleasantries.",
    "Retina scans: the new best friend program!",
    "What a clever way to avoid awkward introductions.",
    "I see my life has been reduced to a mere data set.",
    "Great, now I can finally be identified without the hassle of conversation.",
    "Who needs a personality when you have retina data?",
    "Sure, my name is overrated; let’s just stick to the scan.",
    "Welcome to the 22nd century, where connections are so impersonal.",
    "Nice to know that my eyes are doing all the talking.",
    "Next time, I’ll just send my retina in to do the greeting.",
    "Who needs small talk when we can just scan and go?",
    "Ah, the beauty of technology—never have to say hi again.",
    "So much for a warm welcome; guess data is the new handshake.",
    "This is how we skip the 'getting to know you' stage, huh?",
    "A little less chat, a little more tech—that’s the motto now.",
    "So, who needs names? We’ve got high-tech identification.",
    "I always wanted to be reduced to a series of scans.",
    "Looks like pleasantries are for those who can’t afford retina scans.",
    "Well, it’s comforting to know my identity is now a file somewhere.",
    "Who knew being scanned could feel so... unpersonal?",
    "Wow, I always dreamed of being identified by my eyes.",
    "Great, now I can add 'scanned' to my resume.",
    "I didn't realize we were living in a sci-fi movie.",
    "Nice to know I’m just another data point in the system.",
    "I see we’ve bypassed the whole getting-to-know-you part.",
    "Ah, yes, let’s skip the awkward introductions.",
    "Why say hello when I can just flash my eyes?",
    "Thanks for the swift dismissal of my humanity.",
    "Guess we’re too advanced for simple names now.",
    "Looks like I should’ve brought my retinal ID instead.",
    "Who needs charm when you have cutting-edge technology?",
    "I didn't sign up for this kind of relationship.",
    "Welcome to the future, where your eyes do all the talking.",
    "What’s next, a thumbprint handshake?",
    "Ah yes, a scan is so much warmer than a greeting.",
    "Forget names; let’s just rely on the scanners.",
    "Nice to meet you, but my retinas say it all.",
    "So, this is how personal connections work now?",
    "In a world of data, who even needs a personality?",
    "I thought we were having a conversation, not a scan-off.",
    "Oh, the joy of being reduced to biometric data.",
    "Guess this is what socializing looks like in 2077.",
    "What a relief! Now I won’t have to remember names.",
    "Ah, the art of conversation, now obsolete.",
    "Your scanner knows me better than my friends do.",
    "How incredibly efficient to skip all that chatting.",
    "Seems like small talk is for the obsolete.",
    "Ah, the luxury of instant identification!",
    "Why call me by name when my retinas do the heavy lifting?",
    "This is the future: talk is cheap, scans are gold.",
    "Looks like I’ve been upgraded to an eye-based identity.",
    "Well, this is a charming way to make acquaintances.",
    "Why bother learning names when I can just be scanned?",
    "Ah, the romance of retina scanning—my new best friend.",
    "So much for personal touch; data does it better.",
    "This feels less like a conversation and more like a transaction.",
    "At least my eyes are getting some attention.",
    "I guess the future is too busy for names.",
    "Ah, nothing like a quick scan to skip the formalities.",
    "Great, my identity is now just a series of pixels.",
    "This is how we do personal connection in the digital age.",
    "How delightful to be known by my eye pattern.",
    "Who knew my retinas could do all the talking?",
    "I didn’t realize my name was so overrated!",
    "A quick scan and I’m officially dehumanized.",
    "Who needs warmth when you have high-tech identification?",
    "Every interaction is a scan away, so convenient!",
    "Welcome to the age of efficiency—feelings not required.",
    "Nice to see my humanity reduced to a retinal readout.",
    "Looks like personal connections are a thing of the past.",
    "This is the modern way to say, 'I don’t care what you’re called.'",
    "How lovely to have my identity streamlined like a purchase.",
    "Ah, yes, the joy of being recognized by my iris.",
    "What’s next, a fingerprint for a high-five?",
    "So my name doesn’t matter? Fascinating!",
    "Only in this world could a scan replace a handshake.",
    "Great, now I can check my identity on a database.",
    "I see we’re too evolved for simple introductions.",
    "Why bother with a backstory when you have retina tech?",
    "Looks like I'll be remembered by my scanner ID.",
    "Aren’t we advanced? Scanning is the new small talk.",
    "Ah, technology really knows how to woo a person.",
    "Guess I’ve been upgraded from human to data point.",
    "Who knew identification could be this impersonal?",
    "Scanning: the future’s way to say 'Get lost.'",
    "It’s nice being recognized by my eye pattern rather than my name.",
    "Fascinating how the future has no time for introductions.",
    "So much for personality; it's all about the retina now.",
    "Welcome to the new world, where warmth comes from a scan.",
    "Great, my identity is now filed alongside junk data.",
    "Why learn about each other when tech can do the heavy lifting?",
    "This scan is the ultimate conversation starter, apparently.",
    "I feel so valued just being a barcode for your eyes.",
    "I didn’t sign up for a tech relationship, but here we are!",
    "Looks like we're too advanced for simple ‘hello.’",
    "Ah yes, names are so last century; let's just scan.",
    "Who needs genuine interaction when we can just verify?",
    "Wow, scanning—what a low-effort way to connect!",
    "Why engage in conversation when you have a retina scanner?",
    "Nice to meet you through the magic of technology.",
    "I’ll just be over here, enjoying my eye-based identification.",
    "So this is what it feels like to be an entry in a database.",
    "A warm welcome? No thanks, I prefer my scanned identity.",
    "Guess introductions are for the outdated.",
    "I never thought eye contact could be this literal.",
    "Forget names, let’s just operate on retinal recognition.",
    "Great, my personality has been reduced to pixels and data.",
    "What a relief; now I don’t have to remember anything.",
    "Who needs pleasantries when we have high-tech solutions?",
    "Ah, nothing like a quick retina scan to replace connection.",
    "Oh, nothing screams friendship like a retina scan.",
    "Great, now I’m just a collection of biometric data.",
    "Who needs to bond over stories when you can scan instead?",
    "I didn't realize we were in a data-centric love story.",
    "Nice to see my identity streamlined to a mere scan.",
    "Ah yes, the future of connection: cold and calculated.",
    "Who knew a quick scan could replace a lifetime of conversations?",
    "So this is what meaningful interactions look like now?",
    "I always wanted to be identified by my eye pattern.",
    "Guess names are too personal for this age of scanners.",
    "This is the kind of relationship I never knew I wanted!",
    "A retinal readout? So much more personal than a handshake.",
    "Ah, the beauty of technology: no need for names!",
    "Thanks for taking the time to skip the pleasantries.",
    "I see we’ve moved past names; that’s so progressive.",
    "Scanning is the new way to ensure you're not a fraud.",
    "I’d call this intimate, but I think I’d be lying.",
    "No need for introductions; just a quick scan will do.",
    "Ah, the joys of being just another data point.",
    "Personal relationships? We have scanners for that.",
    "Nothing like a quick retina scan to save time.",
    "All this tech, and yet here I am—still just an eye.",
    "So this is how connections are made in 2080?",
    "Sure, let’s skip the small talk and jump to the data.",
    "I guess my personality has been deprecated.",
    "Ah yes, the rich tapestry of human connection, scanned.",
    "Why exchange names when you can transmit data?",
    "I love how my humanity has been reduced to sensory input.",    
}
function CyberNPC.NPCScannedIronicLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCScannedIronicLines))
    return CyberNPC.NPCScannedIronicLines[line]
end

CyberNPC.NPCScannedRudeNegativeLines = {
    "Great, I’m just a walking retina to you.",
    "Wow, how charming. No need for my name, I guess.",
    "Nice to know I'm just another data entry in your system.",
    "Thanks for skipping the basic human courtesy.",
    "Guess I don't matter unless I'm reduced to a scan.",
    "How fascinating! You just scanned my humanity away.",
    "Oh, so we’re too good for small talk now?",
    "I didn’t realize I was talking to a computer.",
    "Nice to know I’m just a number to you.",
    "Great, because my personality doesn’t matter anyway.",
    "Who needs names when you can just look at my eyes?",
    "Wow, feel free to disregard my existence completely.",
    "So, no interest in actually knowing me, huh?",
    "Ah yes, let’s make this as impersonal as possible.",
    "Thanks for making this so cold and mechanical.",
    "I see my value is based on my iris pattern.",
    "Oh good, let’s reduce our interactions to scanning.",
    "Wow, that felt really genuine… not.",
    "So much for a friendly encounter; let’s just scan instead.",
    "Am I just some data you need to process?",
    "Yeah, let’s skip the niceties. Clearly, you don’t care.",
    "How charmingly rude! I’m just data to you.",
    "Thanks for the reminder that tech is replacing humanity.",
    "Well, this is fun—more like a robot interaction than a chat.",
    "Wow, you really don’t care about personal connections.",
    "So, my identity means nothing without a scan?",
    "Yep, this is how you treat people in 2077, I guess.",
    "Must be nice to skip the awkwardness of actual conversation.",
    "Just great. I’m reduced to a simple scan.",
    "So I guess my name means nothing to you.",
    "How disrespectful to skip a proper introduction.",
    "I feel completely dehumanized right now.",
    "Wow, how impersonal can you get?",
    "Nice to know you're more interested in data than people.",
    "Thanks for treating me like just another object.",
    "I didn’t realize I was talking to a machine.",
    "Clearly, my identity isn’t important to you.",
    "This is just rude. A name isn’t that hard to ask for.",
    "Is this how you treat everyone? It’s insulting.",
    "So, my personality is irrelevant here?",
    "I expected better than this cold tech approach.",
    "It feels like you don't care at all about who I am.",
    "Wow, talk about a lack of social skills.",
    "Do you even know the meaning of conversation?",
    "This scan is just a lazy way to skip personal interaction.",
    "You can’t even be bothered to ask for my name?",
    "It’s pretty sad when technology replaces basic kindness.",
    "I feel like a barcode instead of a human being.",
    "Thanks for completely ignoring the human element.",
    "You could at least pretend to be polite.",
    "It’s frustrating to see you prioritize tech over people.",
    "How degrading to be treated like data.",
    "I guess connection is dead in this age of scanners.",
    "Is empathy extinct? Because this feels empty.",
    "Seriously? Just a scan instead of a hello?",
    "This feels way too cold for a human interaction.",
    "I thought we had advanced beyond this robotic behavior.",
    "So much for basic manners; guess those are out of style.",
    "Wow, I didn’t realize you could be so dismissive.",
    "Is this really how you treat people you meet?",
    "You couldn’t even bother to ask for my name?",
    "Great, now I’m just another data point.",
    "I’d expect this from a machine, not a person.",
    "This interaction feels entirely one-sided.",
    "How patronizing to reduce me to a retinal scan.",
    "What’s next, scanning my thoughts?",
    "Your lack of courtesy is impressive, really.",
    "I didn’t come here to feel objectified.",
    "This is how we connect now? With a scan?",
    "How about some basic respect next time?",
    "You really have no idea what conversation means.",
    "This experience is about as welcoming as a brick wall.",
    "Guess I should start wearing my ID on a lanyard.",
    "You must really love treating people like numbers.",
    "What a depressing way to interact with someone.",
    "I feel like I’m in a system, not a conversation.",
    "So personal connections are a thing of the past?",
    "Let me guess, you don’t do names anymore?",
    "This is the last time I rely on tech for connection.",
    "Wow, thanks for sidestepping basic decency.",
    "Did my presence not warrant a proper introduction?",
    "So much for basic human interaction.",
    "Guess personal connections aren’t your style.",
    "I can’t believe you skipped straight to the tech.",
    "My name isn’t important, but my scan is, huh?",
    "What a way to make someone feel like an object.",
    "It’s just sad how cold this all feels.",
    "Clearly, you’re not interested in actually meeting anyone.",
    "I didn’t sign up to feel like a barcode.",
    "You might want to work on your social skills.",
    "This is beyond impolite; it’s dehumanizing.",
    "I didn’t come here to be treated like data.",
    "Your lack of interest is really off-putting.",
    "It’s frustrating to see you disregard human interaction.",
    "How about a simple greeting next time?",
    "You’ve really managed to kill any vibe here.",
    "This is disappointing; I expected better from you.",
    "I guess respect is obsolete in your book.",
    "You're really making this more awkward than it needs to be.",
    "It’s sad that technology made you forget how to connect.",
    "I didn’t realize this was a scanning factory.",
    "What happened to the art of conversation?",
    "I feel completely invisible right now.",
    "Your scanning skills don’t replace a warm interaction.",
    "How disappointing; I expected a real interaction.",
    "Am I just a number to you? Because it sure feels that way.",
    "That’s one way to make someone feel unimportant.",
    "You really couldn’t care less about names, could you?",
    "Seems like you don’t have time for actual people.",
    "Wow, that was about as personal as a machine.",
    "I didn’t know I was talking to a scanner instead of a person.",
    "Thanks for turning this meeting into a transaction.",
    "How refreshing to be treated like a piece of data!",
    "Clearly, social etiquette isn’t your strong suit.",
    "I must be the most boring person you’ve ever met.",
    "You could at least pretend to care.",
    "So much for making connections in the digital age.",
    "This feels like an interrogation, not an introduction.",
    "You don’t even know me, yet here we are.",
    "Guess small talk is dead; scanners rule the day.",
    "How thoughtful of you to skip the niceties.",
    "I didn’t realize my identity could be summed up in a scan.",
    "What a glaring lack of interpersonal skills.",
    "Just scanning my eyeballs, huh? Charming.",
    "It’s hard to connect when you skip the basics.",
    "Nice to know I'm just a background check to you.",
    "I hope your scanner has better manners than you do.",
    "You really know how to make someone feel sidelined.",
    "It’s a shame you don’t value actual conversation."
}
function CyberNPC.NPCScannedRudeNegativeLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCScannedRudeNegativeLines))
    return CyberNPC.NPCScannedRudeNegativeLines[line]
end

CyberNPC.NPCScannedPositiveLines = {
    "Wow, that was efficient! Technology at its best.",
    "I appreciate how quick and smooth that was.",
    "It’s impressive how far technology has come!",
    "That scan made the introduction so seamless.",
    "I love how easy this makes meeting new people!",
    "What a convenient way to skip the formalities!",
    "I feel like I'm in the future; this is amazing.",
    "It's great how tech can simplify our interactions.",
    "That was a refreshingly fast way to connect!",
    "I love how advanced this makes everything feel.",
    "Thank you for making this so straightforward!",
    "This tech really takes the hassle out of meeting someone.",
    "Using a scan definitely speeds things up!",
    "I appreciate the innovation behind this approach.",
    "How cool! My eyes just did all the talking.",
    "This really makes learning about each other a breeze!",
    "I didn’t expect that, but I’m impressed!",
    "Wow, that was quick and efficient—great system!",
    "It's nice to see technology making things easier.",
    "I can definitely get used to this kind of interaction.",
    "How futuristic! This is what the future promised.",
    "I appreciate the tech—makes life simpler!",
    "This might just be the best way to meet people!",
    "I love how tech can enhance our personal connections.",
    "So straightforward; I’ll take more of this, please!",
    "That was impressively fast—way to streamline introductions!",
    "I love how efficient technology can be!",
    "This makes our meeting so much easier; thanks!",
    "What a clever way to skip the awkward ice breakers!",
    "This is a brilliant use of tech for connections!",
    "I appreciate how swift that was; very modern.",
    "Wow, that felt futuristic and efficient!",
    "Great job! This really simplifies things.",
    "It’s nice to have tech making things less complicated.",
    "A quick scan? I’m all for it!",
    "I’m impressed by how seamless that interaction was.",
    "This is an exciting way to meet new people!",
    "Thanks for making this process so easy!",
    "I like how this enhances the whole experience.",
    "Using a retina scan adds a cool twist to introductions.",
    "I appreciate how technology can speed things up!",
    "Greetings don’t have to be complicated anymore.",
    "This is the future I was hoping for!",
    "How convenient! I can get used to this.",
    "So much faster than traditional introductions!",
    "That feels like a step into the future of meetings.",
    "I love that we can connect without the fuss.",
    "Tech making life easier—count me in!",
    "It's refreshing to see innovation in social interactions.",
    "What a delightful way to enhance communication!",
    "Using eyes to introduce myself? Count me in!",
    "Thanks for making this whole thing so straightforward.",
    "This is definitely the way to meet people nowadays!",
    "Wow, what an efficient process that was!",
    "I didn’t expect this to be so streamlined and easy.",
    "This tech really revolutionizes how we connect.",
    "Who knew scanning could feel so friendly?",
    "This approach makes everything feel more accessible.",
    "That was surprisingly quick and efficient!",
    "I really appreciate how streamlined this process is.",
    "This technology makes introductions a breeze!",
    "What a fantastic way to connect instantly!",
    "I love how simple it is to meet someone now.",
    "This feels so futuristic and cool!",
    "It's amazing how tech can enhance personal interactions.",
    "Wow, what an innovative approach to introductions!",
    "This just made getting to know someone much easier!",
    "I appreciate not having to go through all the formalities.",
    "Thank you for making this such a smooth experience!",
    "I’m impressed by how effective that was!",
    "This is what I call tech-forward networking!",
    "It’s refreshing to see innovation in social settings.",
    "That scan completely removed any awkwardness.",
    "This is definitely a step into the future!",
    "How convenient! I’m all in for this method.",
    "I appreciate how quick and user-friendly this is.",
    "This approach really modernizes our interactions.",
    "Nice—this tech really takes the hassle out of meeting people!",
    "I didn’t think introduction could be this easy!",
    "This is a great example of tech working for us.",
    "I’m all for eliminating boring small talk!",
    "What an effective way to gain insights instantly!",
    "Using a retina scan makes everything feel advanced.",
    "I really love how efficient this experience was!",
    "This method makes meeting new people so accessible.",
    "Thanks for this fast and friendly interaction!",
    "I appreciate the innovation behind this approach.",
    "This is a perfect example of technology improving life!",
    "I’m already a fan of this new way to connect!",
    "That was incredibly quick and efficient!",
    "I love how technology makes this so easy.",
    "What a refreshing way to connect with someone!",
    "This feels like a glimpse into the future!",
    "I really appreciate the simplicity of this process.",
    "Wow, that made introductions so smooth!",
    "It’s amazing how streamlined this experience is.",
    "Using a scan takes all the pressure off meeting new people.",
    "I didn’t realize how easy this could be!",
    "This is the best way to skip the awkward small talk.",
    "Thank you for such an innovative approach!",
    "I’m impressed by how fast that was!",
    "This takes convenience to a whole new level.",
    "I appreciate how efficient this technology is!",
    "Scanning feels like a modern way to connect.",
    "How cool is it that we can do this?",
    "I’m excited about how tech can enhance our interactions.",
    "This setup really makes life simpler!",
    "What a fantastic way to streamline introductions!",
    "Using tech to connect shows how far we've come.",
    "This makes networking feel so much more approachable.",
    "Great—now I feel more relaxed meeting new people!",
    "It’s nice to see technology improving social interactions.",
    "What a clever way to eliminate redundancy in introductions!",
    "This is such a user-friendly approach!",
    "I can definitely get used to this method of connecting.",
    "I love that I can meet someone without the hassle.",
    "That was a memorable and seamless experience!",
    "It’s amazing how much easier tech makes things.",
    "This is a brilliant example of innovation in action!",
    "I appreciate how technology can make life more convenient.",
    "I’m thrilled to be part of this future of meetings!",
    "That was impressively fast and effective!",
    "I really like how seamless this process is.",
    "What a neat way to connect without the awkwardness!",
    "This technology makes introductions so much smoother.",
    "I appreciate how this redefines meeting new people.",
    "How convenient that was! I’m all for it.",
    "I’m amazed by how quick that scan was.",
    "Using technology like this is a game changer!",
    "It’s refreshing to see innovation at work.",
    "Wow, that was a friendly and efficient experience!",
    "This approach makes networking feel effortless.",
    "I love how this bypasses all the formalities.",
    "What a clever way to enhance communication!",
    "I’m thrilled by how easy this made everything!",
    "This feels like a massive leap forward in socializing.",
    "I appreciate the clarity that comes with this method.",
    "What an exciting way to meet someone new!",
    "This scan really speeds up the whole process.",
    "It’s comforting to see tech improving our connections.",
    "This is a fantastic method of introduction!",
    "How cool is it to use a scan instead of small talk?",
    "I'm all in for this future of meeting people!",
    "That was surprisingly enjoyable and efficient.",
    "I had no idea this could be so easy!",
    "This really showcases the power of technology.",
    "Thanks for making this interaction so pleasant!",
    "What an excellent way to make introductions!",
    "I love how tech can simplify our lives.",
    "This experience has set a new standard for me.",
    "Using a retina scan really elevates the experience!"
}
function CyberNPC.NPCScannedPositiveLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCScannedPositiveLines))
    return CyberNPC.NPCScannedPositiveLines[line]
end


CyberNPC.NPCThankYouLines = {
    "Thanks!",
    "I appreciate it!",
    "Thanks a lot!",
    "Really grateful!",
    "Thanks so much!",
    "Much appreciated!",
    "Thank you!",
    "I owe you one!",
    "Thanks for that!",
    "Thanks, I appreciate it!",
    "Thanks for your help!",
    "Thanks for your time!",
    "Cool, thanks!",
    "Thanks, that’s great!",
    "I appreciate your support!",
    "Thanks for the assist!",
    "You’re solid, thanks!",
    "Thanks for looking out!",
    "Thanks for everything!",
    "Thanks, that really helps!",
    "Cheers for that!",
    "I dig it, thanks!",
    "Totally appreciate it!",
    "Thanks for being there!",
    "Thanks for your input!",
    "Thanks, you’re helpful!",
    "Thanks for getting back to me!",
    "Thanks for your consideration!",
    "Appreciate your understanding!",
    "Thanks for sharing!",
    "Appreciate your help!",
    "Thanks a bunch!",
    "Thanks for that support!",
    "I really appreciate it!",
    "Grateful for your help!",
    "Thanks for stepping in!",
    "Thanks, that was helpful!",
    "You're awesome, thanks!",
    "Many thanks for that!",
    "Thanks for your effort!",
    "Really appreciate the support!",
    "Thanks for your advice!",
    "Thanks, it means a lot!",
    "Thanks for taking the time!",
    "Thanks for your consideration!",
    "I appreciate the assist!",
    "Cheers for your help!",
    "Your help is appreciated!",
    "Thanks, I owe you one!",
    "Thanks, it was useful!",
    "Thanks for the quick response!",
    "Thanks for being helpful!",
    "Thanks for your input!",
    "I appreciate you stepping up!",
    "Thanks for helping out!",
    "Thanks for the follow-up!",
    "I’m grateful for your time!",
    "Thanks, you really helped me!",
    "Thanks for looking out for me!",
    "Thanks for being there!",
    "Thanks for sharing your thoughts!",
    "Appreciate the guidance!",
    "Thanks, you’ve been a big help!",
    "Really appreciate that!",
    "Thanks for your kindness!",
    "Thanks for being so helpful!",
    "I appreciate you!",
    "That means a lot; thanks!",
    "Thanks for your support!",
    "Thanks for the insight!",
    "Thanks for keeping me in mind!",
    "I owe you one for this!",
    "Thanks, I appreciate the advice!",
    "Thanks for helping me out!",
    "Thanks for your patience!",
    "Thanks for taking the time to help!",
    "I appreciate it more than you know!",
    "Thanks for everything you do!",
    "Thanks for lending a hand!",
    "I’m grateful for your support!",
    "Thanks, that was really nice of you!",
    "I appreciate your effort on this!",
    "Thanks, I really needed that!",
    "Thanks for your contribution!",
    "Thank you for the clarification!",
    "Your help is invaluable, thanks!",
    "Thanks for putting in the effort!",
    "Thanks for checking in!",
    "Thanks for being on top of it!",
    "Thanks for making this easier!",
    "Thanks, I'll remember this!",
    "I appreciate your quick response!",
    "Thanks for your help, I owe you one!",
    "Thanks for making my day a little better!"
}
function CyberNPC.NPCThankYouLinesRandomLines()
    local line = math.random(#(CyberNPC.NPCThankYouLines))
    return CyberNPC.NPCThankYouLines[line]
end



CyberNPC.NPCFoodOkLines = {
    "I'm not feeling hungry",
    "I’m good, thanks",
    "No, I'm fine",
    "I don’t have an appetite right now",
    "I'm all set",
    "I’m not in the mood to eat",
    "I could skip this meal",
    "I've had enough for now",
    "I’m satisfied for the moment",
    "I'm not really hungry at the moment",
    "I'm not up for food",
    "I just ate",
    "Not hungry, but thank you",
    "My stomach's good",
    "I'm fine without food",
    "I'm currently full",
    "I can wait until later",
    "Food doesn't sound appealing right now",
    "I'm content as is",
    "I just don't feel like eating",
    "I’d rather pass for now",
    "I'm not craving anything",
    "I have no hunger right now",
    "I'm perfectly fine without it",
    "No need for food at the moment",
    "I think I'll pass on eating",
    "I'll hold off on food for now",
    "I’m not really feeling it",
    "I would prefer not to eat",
    "I'm good for now",
    "I’m okay, thanks",
    "Not interested in food right now",
    "I’m not peckish",
    "I’m all full up",
    "Food isn’t on my mind",
    "I’m really not in the mood",
    "I couldn’t eat another bite",
    "I’ll pass on food",
    "My hunger needs are met",
    "I just had a meal",
    "Eating isn't appealing right now",
    "I’m not feeling peckish",
    "I've had my fill",
    "I’d rather skip it",
    "I can wait a bit longer",
    "My appetite is satisfied",
    "I’m not up for munching",
    "I’m okay without any snacks",
    "I’m not feeling a craving",
    "Eating isn't necessary for me right now",
    "No hunger pangs here",
    "I'm not tempted by food",
    "I won’t be dining right now",
    "I could use a break from food",
    "Food can wait",
    "I’m not feeling snacky",
    "Meaning to fast for now",
    "I’ve had enough to hold me over",
    "I feel fine as I am",
    "I’d like to hold off on eating",
    "I'm all set for now",
    "No food necessary at the moment",
    "I prefer to take a rain check on eating",
    "My appetite is nonexistent",
    "I’m not feeling like eating right now",
    "I'm good, really",
    "No food for me at this time",
    "I'm not in a food mood",
    "I could do without a meal",
    "My stomach's settled",
    "No need for snacks",
    "I've just had something to eat",
    "I'm not feeling like a meal",
    "Food isn't on my agenda",
    "I can pass on dinner",
    "I don't feel like indulging",
    "I’m satiated for now",
    "Dining isn’t necessary for me",
    "I have no desire for food",
    "I’m content without a meal",
    "Eating isn’t a priority for me",
    "I’m not interested in eating",
    "I'm not particularly hungry",
    "Food isn't appealing at the moment",
    "Not in the mood for a bite",
    "My belly is good for now",
    "I’ll hold off on that",
    "I’ve had sufficient food",
    "I’m not feeling up for food now",
    "Just not hungry enough",
    "I’d prefer to avoid eating",
    "I’d like to refrain from food",
    "No appetite here today",
    "I’m fine with what I have",
    "I’m totally satisfied",
    "Currently not in the mood for food",
    "I’m full enough for now",
    "Not really feeling anything",
    "I could go without for now",
    "I’ll skip the meal, thanks",
    "No appetite to speak of",
    "My hunger level is low",
    "I’m fine without any",
    "Not feeling up to eating",
    "I'm quite content without food",
    "I think I’ll let that pass",
    "I don’t feel like having a bite",
    "I prefer to wait for a meal",
    "Eating can wait for later",
    "I’m good without it for now",
    "Satisfied with what I have had",
    "No need to fill up right now",
    "Food doesn’t interest me at the moment",
    "I'm waiting until later to eat",
    "I’m definitely not hungry",
    "I have enough in my stomach",
    "Eating is not on my mind",
    "I'm good to go without food",
    "I’m fine; I just ate",
    "I can postpone eating",
    "Food isn’t necessary for me right now",
    "I’d rather keep things light",
    "Not in the mood for a meal right now",
    "I feel full and happy",
    "No need to bother with food",
    "I’m perfectly fine as is",
    "I'm okay without any food",
    "Not really hungry at this point",
    "I have no cravings",
    "I’m all right for now",
    "Food isn't tempting me right now",
    "I don’t need anything to eat",
    "I’ll hold off on a meal",
    "I’m content just the way I am",
    "My stomach's not asking for food",
    "I’m currently satisfied",
    "Food can wait a little longer",
    "I'm all filled up right now",
    "No need for seconds",
    "Not craving anything at the moment",
    "I’m quite full right now",
    "I can do without food right now",
    "I’d rather not eat at this moment",
    "I'm okay with skipping it",
    "I’m choosing not to eat now",
    "I have no desire for a meal now",
    "I'm satiated right now",
    "My hunger is entirely quenched",
    "I’d like to avoid eating at the moment",
    "I'm all stocked up on food",
    "I could wait until later to eat",
    "I’m not grabbing anything right now",
    "No eating necessary for me",
    "I can easily pass on food today",
    "I’m okay, thank you very much",
    "I'm totally good without it",
    "I’m cool without food",
    "I’m fine just the way I am",
    "Food is not on my radar right now",
    "I’m not feeling like eating anything",
    "I've had plenty to eat",
    "Can do without a snack",
    "I could skip this course",
    "I'm not tempted for a nibble",
    "No food for me at this time",
    "I'm not feeling snaky right now",
    "My appetite is on a break",
    "I can manage without anything to eat",
    "I’d prefer to hold off on food",
    "I’m not in the mood for snacks",
    "I'm good with just a drink",
    "Not feeling peckish today",
    "I’m full and happy, thanks",
    "I can forgo that meal",
    "I'm satisfied enough for now",
    "I’d rather not eat at the moment",
    "Eating isn’t appealing to me now",
    "No urge for food right now",
    "My hunger can wait",
    "No need for a meal right now",
    "I’m filled up enough",
    "I’d like to skip it for now",
    "Food doesn’t sound good to me",
    "I can live without a meal today",
    "I'm solid on my food intake",
    "No craving hits right now",
    "I’m okay staying hungry for a bit"
}
function CyberNPC.NPCFoodOkLinesRandomLines()
    local line = math.random(#(CyberNPC.NPCFoodOkLines))
    return CyberNPC.NPCFoodOkLines[line]
end

CyberNPC.NPCFoodNotOkLines = {
    "I'm starving",
    "I could really use a bite",
    "I'm feeling peckish",
    "I have a growling stomach",
    "I'm quite hungry right now",
    "I need something to eat",
    "I'm ready for a meal",
    "My stomach is calling for food",
    "I could go for a snack",
    "I'm craving something to eat",
    "I could eat a horse",
    "I'm in the mood for food",
    "I can't wait to eat",
    "I’m feeling snacky",
    "I need to refuel",
    "I could really use some sustenance",
    "I’m longing for a meal",
    "I’m craving some food",
    "I need some grub",
    "I’m ready to chow down",
    "I'm hankering for something to eat",
    "I’m feeling quite hungry",
    "I would love a bite to eat",
    "Food is on my mind",
    "My appetite is awake",
    "I could really go for a meal right now",
    "I’m famished",
    "I’m feeling a bit empty",
    "I could do with some food",
    "I'm eager for a meal",
    "Let's get something to eat",
    "I've got a hunger pang",
    "I'm in need of a meal",
    "My belly is growling",
    "I’m feeling really ravenous",
    "I could use a hearty meal",
    "I’m dying for something to eat",
    "I’m ready to eat something",
    "I’ve got a craving",
    "I’m feeling a bit deprived",
    "I can’t shake off this hunger",
    "I'm itching for a bite",
    "I’m looking for something to satisfy my hunger",
    "I could really go for a feast",
    "I’m very much in the mood for food",
    "I have a hunger that needs addressing",
    "I’m feeling a bit hollow",
    "I’m hungry enough to eat anything",
    "My appetite is kicking in",
    "I'm feeling like I need some fuel",
    "I'm in serious need of food",
    "This hunger is becoming noticeable",
    "I could really chow down right now",
    "There’s an emptiness in my stomach",
    "I’m really feeling the need for food",
    "I’m looking forward to eating",
    "My stomach is empty",
    "I’ve worked up an appetite",
    "I’m feeling peckish enough to snack",
    "I could go for some comfort food",
    "I’m hungry for something delicious",
    "Can’t wait to grab a bite",
    "I’m hungry enough to order takeout",
    "I'm famished and ready to eat",
    "My stomach is demanding food",
    "I'm feeling quite ravenous right now",
    "I really need a meal",
    "I’d love to sink my teeth into something",
    "I'm starving for a snack",
    "I’m ready to indulge in some food",
    "I’ve got the munchies",
    "I'm craving a big meal",
    "Hunger is creeping up on me",
    "My appetite is raging",
    "I could demolish a meal right now",
    "Food is sounding great",
    "I’m feeling quite empty inside",
    "I'm feeling like a snack attack",
    "My stomach’s asking for food",
    "I’m itching to eat",
    "I could really use some nourishment",
    "I'm longing for something tasty",
    "I'm ready to devour something",
    "I've got a keen appetite",
    "I'm on the hunt for food",
    "I'm quite hungry for a feast",
    "This hunger is getting serious",
    "My hunger is at its peak",
    "I could go for a substantial meal",
    "Food is becoming a necessity",
    "I can't ignore this hunger anymore",
    "I'm craving something satisfying",
    "I need to satiate my hunger",
    "I’m feeling peckish enough to feast",
    "I’m ready to satisfy my cravings",
    "I’m really feeling the hunger pangs",
    "I'm on the verge of starving",
    "I'm ready for a big meal",
    "I could use a serious food fix",
    "My stomach is rumbling for food",
    "I'm feeling really hungry right now",
    "I could really bite into something tasty",
    "I’m in the mood for a serious meal",
    "I have a hankering for food",
    "I'm craving something filling",
    "I need to satisfy my appetite",
    "I'm feeling famished and ready to feast",
    "I'm hungry enough to try anything",
    "My stomach is protesting for food",
    "I could really go for a wholesome meal",
    "I’m in desperate need of some nutrition",
    "I have a desire for something delicious",
    "I’m feeling an urge to eat",
    "I could devour a full course",
    "I could go for a nice hot meal",
    "I'm feeling the need to refuel",
    "I’m dying for something tasty",
    "I'm ready to dig in",
    "My stomach's making noise for food",
    "I can’t wait to get some nourishment",
    "I'm on a food hunt",
    "I’m feeling a bit light-headed from hunger",
    "I’m looking for something scrumptious to eat",
    "I’m ready to indulge my cravings",
    "I'm starving for something delightful",
    "I would love something savory right now",
    "I'm craving a good meal",
    "I'm absolutely ravenous",
    "My belly is craving food",
    "I could use a hearty snack",
    "I'm feeling the urge to munch",
    "I'm desperate for a meal",
    "I've got a hunger that needs quelling",
    "I’m ready for some good grub",
    "I'm hankering for a delicious meal",
    "I could demolish a burger right now",
    "I’m feeling very peckish indeed",
    "I need to get some food in me",
    "I’m longing for a tasty treat",
    "I'm ready to feast",
    "I could go for something savory",
    "I’m feeling hungry enough to cook",
    "My appetite is calling loud and clear",
    "I could eat something substantial",
    "I'm hungry enough to snack now",
    "I'm looking for something satisfying",
    "I'm feeling drained and need food",
    "I'm ready for some serious eating",
    "I have a serious craving for food",
    "Hungry as a bear here",
    "I'm feeling ready to eat something hearty",
    "My stomach is begging for nourishment",
    "I could really enjoy a nice meal right now",
    "I’m feeling quite deprived of food",
    "My appetite is fierce",
    "I'm excited about the thought of eating",
    "I need to satisfy this hunger soon",
    "Eating is definitely on my mind",
    "I’m starving for some food",
    "I need a meal, like, now",
    "I’m really hungry right now",
    "My stomach's empty",
    "I could go for a bite to eat",
    "I'm craving some serious food",
    "I need to eat something",
    "I’m feeling pretty hungry",
    "I could use some real nutrition",
    "I'm ready to grab a meal",
    "I need to get my hands on some food",
    "I'm hungry enough to eat anything",
    "Food is all I can think about",
    "I’m looking for something to fill me up",
    "I'm ready to scarf something down",
    "This hunger is real right now",
    "I could really use a good meal",
    "I'm feeling the urge to eat",
    "I need to refuel soon",
    "I’m ready for some sustenance",
    "I can't focus; I need food",
    "I need to settle this hunger",
    "I’d love a proper meal right now",
    "I'm eager to eat something",
    "I could really go for a snack",
    "I need to fill my stomach now",
    "I want something to eat, fast",
    "I'm itching for some food",
    "I'm feeling empty and need a meal",
    "I could use a solid bite right now",
    "I'm hungry enough to grab food anywhere"
}
function CyberNPC.NPCFoodNotOkLinesRandomLines()
    local line = math.random(#(CyberNPC.NPCFoodNotOkLines))
    return CyberNPC.NPCFoodNotOkLines[line]
end


CyberNPC.NPCHydrationNotOkLines = {
    "I’m really thirsty right now",
    "I need something to drink",
    "I could use a cold drink",
    "I’m parched and need hydration",
    "My throat's dry as hell",
    "I could go for some water",
    "I need to quench my thirst",
    "I'm craving a drink",
    "I really need something refreshing",
    "I could use a hit of fluids",
    "I'm feeling dehydrated",
    "I need to chug something cold",
    "I'm thirsty as hell right now",
    "I could down a drink fast",
    "I need a beverage, stat",
    "I’m desperate for something to sip on",
    "I need to wet my whistle",
    "I could really use a nicola",
    "I'm feeling the need for a drink",
    "I want to hydrate, quick",
    "I'm ready to gulp something down",
    "I need a quick drink right now",
    "I'm thirsty enough to fill a cup",
    "I'm in dire need of hydration",
    "I want to grab a drink fast",
    "I'm looking for something to cool me down",
    "I need to refresh myself with a drink",
    "I'm feeling mighty thirsty today",
    "I could really use a splash of something cold",
    "I'm aching for a drink of water",
    "I need to stop and hydrate now",
    "I'm burning up and need a drink",
    "I need something to wet my throat",
    "I'm ready to gulp down some fluids",
    "I'm feeling really dry and need water",
    "I could go for a quick sip",
    "I’m looking for something refreshing to drink",
    "I’m parched and need a cold beverage",
    "I want a drink to cool me down fast",
    "I need something to take the edge off",
    "I'm feeling dehydrated and need liquids",
    "I could use a bottle of water right now",
    "I need a drink to feel normal again",
    "My mouth feels like sandpaper",
    "I'm dying for a cool drink",
    "I want something icy to sip on",
    "I'm thirsty enough to chug it down",
    "I need a hydration fix right away",
    "I want to grab a drink and chill",
    "I'm feeling quite parched right now",
    "I could down a soda easily",
    "I’m itching for something to drink",
    "I’m looking to quench this thirst quickly",
    "I need something to hydrate me now",
    "I'm feeling the heat and need a drink",
    "I want something cold and refreshing",
    "I need a drink before I get any thirstier",
    "I'm craving something sweet to drink",
    "I’m ready for a refreshing break",
    "I could really use a splash of cold water",
    "I want to find a drink and satisfy this thirst",
    "I'm feeling drained and need to hydrate",
    "I need to get some fluids in me fast",
    "I'm parched and looking for refreshment",
    "I could really go for a tall drink",
    "I'm dry as a bone and need a drink",
    "I’m ready to hydrate, like, yesterday",
    "Give me something to drink, quick",
    "I’m craving some iced tea or something",
    "I’m feeling dried out and need water",
    "My body’s crying out for hydration",
    "I’d down anything cold right now",
    "I want to slosh my thirst away",
    "I could use a tall can of real water",
    "I’m looking for something nice and cool to drink",
    "I’m on the hunt for a beverage now",
    "I could easily chug down a drink",
    "I need something to take a sip of",
    "I'm feeling thirsty enough to order a drink",
    "I want something crisp to quench my thirst",
    "I'm dying for a refreshing drink",
    "I need to fill my cup, like, right now",
    "I'm in need of something to sip on",
    "Could really use a chug of something cold",
    "I’m feeling the dry spell, need a drink",
    "I could go for a refreshing drink",
    "I'm parched for some liquid relief",
    "I want to grab something refreshing to drink",
    "I'm thirsty enough to go get a drink now",
    "I’m ready to refresh myself with a good drink",
    "I need something smooth to go down",
    "I'm feeling dehydrated and I need to fix that",
    "Give me something cold before I melt",
    "I need to hydrate before I run dry",
    "I'm feeling parched and need something to drink",
    "I could really go for a chromanticore",
    "I'm looking for something cold to cool me off",
    "I want a drink that's nice and refreshing",
    "I'm ready to quench this thirst right now",
    "I need a drink to wake me up",
    "I’d do anything for a chromanticore",
    "I want something full of flavor to sip on",
    "I'm dying for a little refreshment",
    "I could use a burst of hydration",
    "I’m feeling empty and need a drink fast",
    "I'm ready to grab a big bottle of something cold",
    "I need to cool down with a drink",
    "I'm on the lookout for something tasty to drink",
    "I want to soothe my throat with a nice drink",
    "I could really savor a nice cold nicola",
    "I want a drink to perk me up",
    "I’m thirsty enough to want anything right now",
    "I'm ready to gulp down some cool real water",
    "I could use something that quenches fast",
    "I'm still feeling thirsty and need a real water",
    "I want to slam down a refreshing real water",
    "I need a quick drink to feel better",
    "I'm searching for something cold to quench my thirst",
    "I’m feeling dry and in need of hydration",
    "I want to sip on something to help me chill",
    "I could really go for some milk or something",
    "I’m feeling thirsty and it's time to hydrate",
    "I need something cool to make it through this heat",
    "I want to take a long drink and relax",
    "I could really use a drink right about now",
    "I’m parched and need some refreshment",
    "I want something to wash this dryness away",
    "I need a drink to keep moving",
    "I’m feeling thirsty and it’s getting serious",
    "I'm craving something cold and fizzy",
    "I need a cool drink to perk me up",
    "I want to grab a beverage and chill out",
    "I'm ready to sip something satisfying",
    "I’m really in the mood for a nice drink",
    "I could take down a drink or two easily",
    "I’m searching for some icy refreshment",
    "I need to find something to drink, pronto",
    "I want to drown this thirst with a drink",
    "I’m feeling the heat and need to hydrate",
    "I could down a quart of water right now",
    "I'm feeling thirsty and need relief fast",
    "I’m after a drink that’ll cool me down",
    "I want something refreshing to keep me going",
    "I’d kill for a nice cold drink right now",
    "I’m in serious need of something to sip",
    "I could really use a smoothie or something",
    "I'm looking for anything to quench my thirst",
    "I need to hydrate or I’m fading fast",
    "I'm parched and need a solid drink",
    "I’d love to gulp down some iced tea",
    "I’m feeling drained and need to drink something",
    "I want to refresh myself with a cold beverage",
    "Could use a drink to cool my system down",
    "I need a sip to keep going",
    "My throat's feeling dry; I need a drink",
    "I’m really looking for something to hydrate",
    "I need a drink to ease this parched feeling",
    "I'm after something cool to sip on",
    "I could really do with a refreshing drink",
    "I'm in a serious need for hydration",
    "I want something cold to refresh me",
    "I’m feeling so thirsty; I need something fast",
    "I’d love a drink to chill me out",
    "I'm ready to wash down this thirst",
    "I could go for a tall glass of something cold",
    "I want to hydrate before I move on",
    "I’m feeling refreshed just thinking about a drink",
    "I need something to take away this dryness",
    "I want to quench this thirst with a splash",
    "I'm feeling thirsty; let's find a drink",
    "I'm dying for a decent drink right now",
    "I’m totally parched and need some fluids",
    "I want to cool off with something chilled",
    "I'm seeking some hydration, any drink will do",
    "I'm desperate for something delicious to sip",
    "I could slam down a drink in one go",
    "I want to moisten my throat, fast",
    "I'm eager to grab a refreshing drink",
    "I need to get a drink and cool my jets",
    "I want something to drink, whatever's cold",
    "I'm after a drink to lift my spirits",
    "My thirst is calling out for a cold one",
    "I need to find a beverage before I get too thirsty",
    "I'm really craving something to drink now",
    "I could go for anything cold to revive me",
}
function CyberNPC.NPCHydrationNotOkLinesRandomLines()
    local line = math.random(#(CyberNPC.NPCHydrationNotOkLines))
    return CyberNPC.NPCHydrationNotOkLines[line]
end

CyberNPC.NPCHydrationOkLines = {
    "I’m feeling refreshed",
    "I’m good, no thirst here",
    "I’ve quenched my thirst",
    "I'm satisfied with my drink",
    "I’m all set, thanks",
    "No need for more fluids",
    "I'm feeling perfectly hydrated",
    "I'm good to go without a drink",
    "My thirst is completely gone",
    "I feel great; no thirst at all",
    "I’m topped off and ready",
    "I don’t need another sip",
    "I'm feeling hydrated and energized",
    "I've had enough to drink, thanks",
    "I’m in a good place hydration-wise",
    "I'm feeling perfectly fine without more",
    "No thirst here anymore",
    "I’m good; I’ve had my fill",
    "Feeling refreshed and ready to roll",
    "I don’t need a drink right now",
    "I’m all good on hydration",
    "I'm feeling light and quenched",
    "My thirst has been satisfied",
    "I'm good; I've got what I need",
    "I feel just right with my hydration",
    "Everything’s cool; no thirst in sight",
    "I'm feeling energized and well-hydrated",
    "I'm set; no drinks required",
    "Feeling balanced and refreshed",
    "I’m perfectly good now",
    "I’ve got all the hydration I need",
    "I feel completely hydrated",
    "No more thirst for me",
    "I’m all good, thanks",
    "I feel satisfied and refreshed",
    "My thirst has vanished",
    "I’m feeling great and hydrated",
    "I'm topped off and content",
    "I'm feeling just right",
    "I’ve quenched my thirst perfectly",
    "No longer thirsty at all",
    "I’m refreshed and ready to go",
    "I’m feeling light and happy",
    "I’ve had plenty to drink",
    "I’m all set with my hydration levels",
    "Feeling good; no need for more",
    "I’m feeling balanced and free",
    "I've hydrated well; I'm good",
    "I’m clear and quenched now",
    "I don’t require any more fluids",
    "I’m satisfied with what I have",
    "Feeling energized; I'm not thirsty",
    "I’m good; I've had enough water",
    "I feel refreshed, no cravings here",
    "I’m feeling light on my feet",
    "I’ve slaked my thirst completely",
    "All is well; no thirst in sight",
    "I’m feeling sprightly and hydrated",
    "I don’t need to drink anything now",
    "I’m at peak hydration",
    "I’m good to go, no thirst here",
    "I’m refreshed and ready for action",
    "Hydration's locked in, let's move",
    "I’ve quenched my thirst; I’m set",
    "I’m all topped off, let’s roll",
    "No thirst slowing me down now",
    "Feeling great; I’ve had enough to drink",
    "I’m good, ready to hit the streets",
    "I feel sharp and hydrated",
    "Thirst? Not a problem anymore",
    "I'm fueled up and ready to fight",
    "No need for more, I’m solid",
    "Feeling clear-headed and quenched",
    "I'm set for whatever comes next",
    "I’ve slaked my thirst, let’s keep moving",
    "I’m feeling good, ready for the next job",
    "All systems go, thirst is gone",
    "I’m ready for the next challenge",
    "I’m feeling pumped and well-hydrated",
    "Thirst is the last thing on my mind",
    "I’m refreshed and ready to engage",
    "No more drinks needed, I’m good",
    "I’ve nailed my hydration; let's roll out",
    "I’m feeling sharp and ready to hustle",
    "I’ve got my fluids covered, let’s hustle",
    "Thirst? I’ve got that handled",
    "I’m feeling alive and hydrated",
    "I'm ready for anything; thirst won't hold me back",
    "Hydrated and focused, let’s move out",
    "I’m locked in and ready to roll",
    "I’m fully hydrated, let’s get to work",
    "No thirst here, just pure focus",
    "I’ve got my fluids sorted; bring on the job",
    "I’m good to go, battle-ready and quenched",
    "Thirst is a non-issue now",
    "I’m feeling sharp and well-fueled",
    "Hydration’s locked, let’s take on the city",
    "I’m ready for the next move, no distractions",
    "I’ve suppressed my thirst; on to business",
    "Feeling refreshed and wired to engage",
    "I’m all set; let’s find our target",
    "No more thirst; I’m ready to roll hard",
    "I’m feeling fresh; bring on the chaos",
    "Hydrated and primed for action",
    "Let’s hit the streets, thirst-free",
    "No drink needed; I’m back in the game",
    "I’m feeling clear and ready to strategize",
    "Quenched and focused; let’s make our mark",
    "I’m fueled up and ready to go",
    "Hydration’s good; let’s make some noise",
    "I’ve got my thirst under control; let’s hit it",
    "I’m feeling alive and prepped for work",
    "No distractions now; I’m fully in the zone",
    "I’m clear-headed and recharged for the mission",
    "I’m on my game, no thirst dragging me down",
    "Let’s get to it; I’m completely set",
    "I’m good, armed, and locked on target",
    "I’m refreshed and ready for action",
    "Quenched and ready to take on Night City",
    "I’m fully hydrated now",
    "I don’t need any more drinks",
    "I feel refreshed and good",
    "I’ve had enough to drink",
    "I’m satisfied, no need for water",
    "I’m feeling fine, no thirst",
    "I’m good; I don’t need to drink",
    "I’ve quenched my thirst completely",
    "I’m ready for action, no thirst left",
    "I don’t feel thirsty anymore",
    "I’m alright; my hydration is good",
    "I’m all set, no more drinks needed",
    "I don’t need anything to drink now",
    "I’m feeling good; I’ve had enough fluids",
    "I’m content with my current hydration",
    "I feel great; thirst is gone",
    "I’m in a good place; no thirst here",
    "I don’t require more liquid right now",
    "I’m feeling good, no need for a drink",
    "I’m ready to go; my thirst is satisfied",
    "I’ve taken care of my thirst",
    "I’m good with my hydration levels",
    "I feel clear and hydrated",
    "I’m fine, no need for another drink",
    "I’m not thirsty at all",
    "I’m refreshed and prepared",
    "I’m good to continue, thirst is not an issue",
    "I feel satisfied; no drinks required",
    "I don’t need to worry about thirst",
    "I’m completely hydrated now",
    "I’m feeling good; no thirst at all",
    "I’ve had enough to drink to feel satisfied",
    "I don’t feel the need for more water",
    "I’m fine; my thirst is taken care of",
    "I’ve got my fluids sorted, no issues",
    "I’m well-hydrated and ready to go",
    "I’m feeling refreshed; I don’t need a drink",
    "I’m good; I don’t require any more liquid",
    "I’m all set; I don’t feel thirsty",
    "I’m in a good state; hydration is sufficient",
    "I feel great, and my thirst is satisfied",
    "I’m fine; I’ve had my fill of liquids",
    "I don’t have any thirst to deal with",
    "I’m ready to move on; thirst is behind me",
    "I’ve got enough hydration for now",
    "I’m feeling alright; no more drinks needed",
    "I don’t need to drink anything else",
    "Everything’s good; I’m not thirsty",
    "I’m clear-headed and rehydrated",
    "I’m in a good spot; thirst is not a concern",
    "I feel good; I’ve covered my hydration",
    "I’m perfectly fine; no thirst here",
    "I’m refreshed and good to continue",
    "I’m satisfied with how I feel",
    "I’m ready to take on whatever comes next; thirst is gone",
    "I’m not feeling thirsty in the slightest",
    "I’m feeling balanced; I’ve had enough to drink",
    "I feel clear and hydrated enough",
    "I’m fully satisfied with my hydration",
    "I have enough fluids in me now",
    "I don’t need anything more to drink",
    "I feel good; thirst is not an issue",
    "I’m ready to go; my thirst is gone",
    "I’m good to continue; no more water needed",
    "I feel fine; I’ve had what I need",
    "I’m not thirsty at all right now",
    "I’m in a good place; no thirst lingering",
    "I’m alright; my hydration is on point",
    "I’ve quenched my thirst adequately",
    "I don’t feel any need for a drink",
    "I’m clear and feeling great",
    "I’ve had my drink; I’m satisfied",
    "Everything's good; I’m not thirsty",
    "I’m feeling refreshed; I’ve had enough",
    "I’m set; I don’t need to drink again",
    "I’m feeling energized; thirst is gone",
    "My hydration levels are just right",
    "No thirst here; I’m ready to go",
    "I’ve taken care of my thirst completely",
    "All is good; I’m not in need of a drink",
    "I’m fine; my fluids are sufficient",
    "I don’t require any more hydration",
    "I’m feeling balanced and hydrated",
    "I’m good; I’ve covered my thirst",
    "I’m feeling clear-headed; thirst isn’t a concern",
    "I’ve got everything I need; no thirst left",
    "I’m all filled up; thirst is no longer a worry",
    "I’m totally satisfied; no thirst remaining",
    "I’ve had enough liquids for now",
    "I feel clear; I don’t need to drink",
    "I’m doing well; no thirst issues",
    "I’m hydrated and ready for action",
    "Everything's fine; I'm not feeling thirsty",
    "I’m set; my thirst has been addressed",
    "I’m comfortable and hydrated",
    "I’m feeling good; my hydration is sufficient",
    "I’ve taken care of my hydration needs",
    "I’m feeling refreshed; no thirst to worry about",
    "I’ve already quenched my thirst",
    "I feel perfectly fine; no need for more drink",
    "I’m in great shape; I don’t need to drink",
    "I’m feeling light and hydrated",
    "I’m satisfied with my current drink level",
    "I’m good; I’ve covered my hydration well",
    "Thirst is not a factor for me right now",
    "I’m feeling balanced; drinks are under control",
    "I’ve adequately satisfied my thirst",
    "I’m feeling refreshed and energized",
    "I’ve got my hydration sorted; I'm good",
    "I’m ready for anything; thirst is behind me",
    "I feel fit; no need for more fluids",
    "I’m fine; I’ve had enough to keep me going",
    "I’m not thirsty any longer",
    "I feel solid; my thirst is taken care of",
    "I’m locked in; hydration is on point",
    "I’m doing well; my thirst has been resolved",
    "I’m ready to proceed; I've had enough to drink"
}

function CyberNPC.NPCHydrationOkLinesRandomLines()
    local line = math.random(#(CyberNPC.NPCHydrationOkLines))
    return CyberNPC.NPCHydrationOkLines[line]
end

CyberNPC.NPCJustASecLines = {
    "Just a moment",
    "Hold on a sec",
    "Please wait a moment",
    "Give me a moment",
    "One second, please",
    "Just a minute",
    "Hang tight",
    "Bear with me for a moment",
    "I'll be right back",
    "Please hold on",
    "Just a tick",
    "A moment of your time",
    "Please bear with me",
    "A quick second, please",
    "One moment please",
    "I’ll be right with you",
    "A brief pause",
    "Give me a quick minute",
    "Stay with me for a second",
    "A second of your patience",
    "One moment, if you please",
    "I need a quick second",
    "Wait a tick",
    "Give me a brief moment",
    "One short moment",
    "Let me catch my breath",
    "A minute of your patience",
    "I’ll be right back with you",
    "Hold tight",
    "Just need a moment",
    "A tiny pause",
    "A moment to gather my thoughts",
    "Momentarily",
    "Just a little bit",
    "I’ll be with you in a sec",
    "Let me take a quick breath",
    "Hang on a moment",
    "Just a brief moment",
    "One quick pause",
    "Allow me a moment",
    "Wait just a little while",
    "A second, if you will",
    "Just a short while",
    "Let me take a moment",
    "One quick breath",
    "Hold on just a tad",
    "I'll be with you shortly",
    "Let me take a second",
    "A swift moment, please",
    "Just a little while longer",
    "One tick, please",
    "Wait just a moment"
}
function CyberNPC.NPCJustASecLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCJustASecLines))
    return CyberNPC.NPCJustASecLines[line]
end

CyberNPC.NPCMyNumberLines = {
    "Yo, V! Here’s my number. Gotta run now.",
    "Need a contact? Call me. I’m out of here.",
    "Take my number, V. Time to move on.",
    "Keep this handy: my number. I’ve got somewhere to be.",
    "In a pinch? Hit me up. I’ll catch you later!",
    "Call me anytime, V. I need to split.",
    "Got your back! Here’s my number. But I’m off.",
    "Don’t hesitate to ring me. I really have to go.",
    "V, here’s my number. I can’t stick around.",
    "Here’s my digits, V. Duty calls!",
    "Take this—my number. I’ve got to jet.",
    "Call me if you need me. I’m on the move now.",
    "Here’s my contact info, V. Time to bounce.",
    "You’ll want this number. I’m outta here!",
    "Don’t lose this! My number. I’ve got places to be.",
    "Hit me up anytime. But I’ve gotta split now.",
    "Grab my number, V. I’ve got to take off.",
    "This is my number. I’m heading out soon.",
    "Here’s my digits. I can’t linger.",
    "You’ll need this. Gotta make tracks now.",
    "Take my number, V. I’m on a schedule.",
    "Catch you later! Here’s my contact info.",
    "You might want this before I go.",
    "Stay in touch! But I’m leaving now.",
    "Grab my number, V. I’ve got to take off.",
    "This is my number. I’m heading out soon.",
    "Here’s my digits. I can’t linger.",
    "You’ll need this. Gotta make tracks now.",
    "Take my number, V. I’m on a schedule.",
    "Catch you later! Here’s my contact info.",
    "You might want this before I go.",
    "Stay in touch! But I’m leaving now.",
    "V, here’s my number. I really need to move.",
    "Take this number real quick. I’ve got places to be.",
    "Here’s my digits before I dash.",
    "My number, V. Gotta run, though!",
    "Catch you later! Here’s my contact.",
    "Don’t forget this! I’ll be gone in a flash.",
    "Last thing: my number. I have to hurry.",
    "Before I split, take my digits!",
    "V, need my number? I’m off now!",
    "Here’s my number; I’ve got to jet.",
    "Take this before I vanish—my number!",
    "Quick—my contact! I’m on my way.",
    "Don’t lose this! I’ve got to move.",
    "Just a moment, V! Here’s my number. Later!",
    "This is my number. Time’s ticking!",
    "You’ll want my info. I can’t stick around.",
    "Listen up, V! Here’s my number; I’m in a hurry.",
    "Hey, V! Take my digits. I need to bounce.",
    "V, here’s my contact info. I’ve got to move.",
    "Yo, V! Remember this number. I’m off soon.",
    "Check it out, V! My number for you. Time to run.",
    "V, grab my number quick. I can’t stay long.",
    "Heads up, V! My digits—you’ll need them. I’m leaving.",
    "Hey, V! This is my number. I really have to go.",
    "Yo, V! Don’t forget my number; I’m on the move.",
    "Hey, V! Here’s my digits; I’ve got to fly.",
    "Listen, V! Take my contact info. I’m heading out.",
    "V, check this out—my number. Gotta split.",
    "Quick, V! Here’s my number; I’m off in a flash.",
    "Hey there, V! Grab my digits before I go.",
    "V, this is my contact. I can’t stick around.",
    "By the way, V! Here’s my number. I need to hustle.",
    "Yo, V! Don’t forget my number; I’m on the move.",
    "Hey, V! Here’s my digits; I’ve got to fly.",
    "Listen, V! Take my contact info. I’m heading out.",
    "V, check this out—my number. Gotta split.",
    "Quick, V! Here’s my number; I’m off in a flash.",
    "Hey there, V! Grab my digits before I go.",
    "V, this is my contact. I can’t stick around.",
    "By the way, V! Here’s my number. I need to hustle."
}
function CyberNPC.NPCMyNumberLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCMyNumberLines))
    return CyberNPC.NPCMyNumberLines[line]
end


CyberNPC.NPCAskRewardLines = {
    "Your reward will be",
    "You can expect your reward to be",
    "What you receive as a reward is",
    "You will be given",
    "Count on your reward being",
    "Your reward amounts to",
    "Soon, your reward will be",
    "Look forward to your reward being",
    "Prepare for your reward, which will be",
    "Your anticipated reward is",
    "Soon enough, your reward will be",
    "Your reward could turn out to be",
    "Get ready for a reward that is",
    "Be ready; your reward will include",
    "Anticipate receiving a reward that is",
    "Expect your reward to be",
    "Your reward is set to be",
    "Rest assured, your reward will be",
    "You should know that your reward is",
    "Your promised reward will be",
    "It’s a given that your reward will be",
    "Be prepared for a reward that is",
    "Your reward will consist of",
    "The reward awaiting you is",
    "What lies ahead as a reward is",
    "You won’t be empty-handed; your reward is",
    "You've earned a reward that will be",
    "Your well-deserved reward will be",
    "Look out for a reward that ranks as",
    "The reward you seek will be",
    "Count on your reward to be",
    "You are entitled to a reward that is",
    "Soon enough, your reward will show up as",
    "A fitting reward awaits you, which is",
    "You can look forward to a reward that is",
    "Your next reward is destined to be",
    "The culmination of your efforts will yield a reward that is",
    "Prepare for a reward that will turn out to be",
    "You can rely on your reward being",
    "Your efforts warrant a reward that is",
    "The outcome will include a reward that is",
    "Before long, your reward will be revealed as",
    "Your achievement will bring a reward that is",
    "You’re in line for a reward that is",
    "A reward that reflects your efforts will be",
    "Prepare to receive a reward that amounts to",
    "Your journey leads to a reward that is",
    "The fruits of your labor will present a reward that is",
    "You stand to gain a reward that is",
    "Anticipate a reward that will prove to be",
    "What you’ve accomplished guarantees a reward that is",
    "Your commitment earns you a reward that will be",
    "Soon, you’ll discover your reward is",
    "This mission ensures a reward that is",
    "A worthy reward awaits, which is",
    "Your success culminates in a reward that is",
    "What’s coming your way as a reward is",
    "Your remarkable efforts will result in a reward that is",
    "As a token of appreciation, your reward will be",
    "You’ll find that your reward is",
    "Your successful mission guarantees a reward that is",
    "Expect a reward tailored to your skills, which is",
    "The closing of this chapter brings a reward that is",
    "The outcome of your work will yield a reward that is",
    "With your success comes a reward that is",
    "Your tenacity leads to a reward that will be",
    "You’re due for a reward that can be",
    "This task paves the way for a reward that is",
    "Your dedication ensures that a reward will be",
    "Recognizing your efforts, your reward will be",
    "With this completion, your reward is destined to be",
    "Your outstanding work will earn you a reward that is",
    "A valuable reward lies ahead, which will be",
    "The results you’ve achieved lead to a reward that is",
    "Your accomplishments will be acknowledged with a reward that is",
    "You're due for a reward that promises to be",
    "Your insightful efforts will bear a reward that is",
    "Your diligence ensures a reward that is",
    "The payoff for your efforts will take the form of a reward that is",
    "Expect to be compensated with a reward that is",
    "This venture will culminate in a reward that is",
    "Your success results in a reward that embraces",
    "As a result of your work, your reward will be",
    "Pursuing this task brings you a reward that is",
    "In recognition of your skills, your reward will amount to"
}
function CyberNPC.NPCAskRewardLinesRandomLine(suffix)
    local line = math.random(#(CyberNPC.NPCAskRewardLines))
    return CyberNPC.NPCAskRewardLines[line] .. " " .. suffix
end

CyberNPC.NPCMercDiesQuestLines = {
    "The job's done. You lost a merc. We need to focus on the outcomes.",
    "One less in the field, but we achieved the objective. A pity",
    "Let’s assess the results and any loose ends.",
    "I see you lost your assistance. Their sacrifice was noted. it’s the nature of the work.",
    "I you lost a fellow merc. Hope you learned from the operation",
    "Your friend was lost in action. We’ll file a report for now. That’s all we can do now.",
    "You lost a friend. Emotional baggage doesn’t help; stay focused.",
    "A costly merc lost. We need to plan for contingencies next time.",
    "You performed well despite the loss; keep that in mind.",
    "It seems you are running solo again. Now, let’s discuss the next phase of our operations.",
    "It's a tough loss, V. You're handling it well under pressure. Remarkable",
    "One merc lost. They played their part, and we kept our end of the deal.",
    "I wonder what happened to the other merc. Let's take this as a lesson; we have to be sharper next time.",
    "Success, yet a little tragedy happened. Every mission has its costs. we'll learn and adapt.",
    "Lost a soul here. You did your job, V. And that's what counts.",
    "The other merc? We'll make sure their contributions are recognized.",
    "Killed in action. It’s important to acknowledge the sacrifice, however brief.",
    "Killed in action: Focus on what’s next; we’ve got a reputation to uphold.",
    "We recovered what we needed; that's a victory in its own right.",
    "Merc was K I A. Take a moment to reflect, then we get back to business.",
    "K I A. Their loss is part of the game; it doesn’t define us.",
    "You left someone behind I see. You did what you had to do; that’s what matters.",
    "The other merc got dismissed from work? We’ll honor their memory by being better in the field.",
    "Your companion died. It’s tough, but we did what we were hired for.",
    "Your companiion was K I A. Stay sharp, V. there are always more missions ahead.",
    "Truly a tragedy what happened to your companion. It’s a hard truth, but we can’t dwell on the past.",
    "Someone on the team was flat lined. You kept your cool, which will serve you well going forward.",
    "I see your fellow merc got flat lined. Every experience counts; use this to grow stronger.",
    "You are alive. Your companion is not. This is what we sign up for, but it doesn’t make it easier.",
    "Considering the merc: Dead. Recognize your emotions, but keep them in check for now.",
    "You see ... loss is part of our business. You know that.",
    "You’ve shown resilience; it’s vital in our line of work. While your fellow merc did not",
    "Considering your companion: We’ll process this later; right now, it’s about other jobs awaiting.",
    "A fellow collegue died. They did their part, and so did you. Let’s not forget that.",
    "Your collegue has passed away. Use this experience to sharpen your instincts.",
    "Your collegue died, I see. We adapt; that’s how we survive in this game.",
    "Your assistance died. Emotional scars fade, but the lessons remain.",
    "I heard about it. It’s a cruel world, but we're professionals. We move on.",
    "I heard about your loss. Recognizing the sacrifice keeps us grounded.",
    "I heard about our loss. Take this to heart but channel it into your next job.",
    "I heard our merc flat lined in action. Their sacrifice won't go unnoticed in our records.",
    "I see, you survived. Adaptability is key; you’ll carry this experience forward.",
    "I heard someone didn't survive. It's a harsh reality, but it’s part of the job.",
    "You did what needed to be done; that’s commendable. A shame your fellow merc died.",
    "The mission was accomplished, despite the cost.",
    "Keep your chin up; we owe them that much. Sounds like a toast in the Afterlife",
    "Lessons like these can be tough, but they make you stronger. Let's remember our acquintance as a good merc",
    "Heard about the loss. Acknowledge your feelings, but don’t let them control your path.",
    "We knew the risks. What happened is unfortunate but part of the deal.",
    "You did your duty, and that’s what counts in this line of work. Let us have a brief second of silence... That's it",
    "Loss is a burden we all share; don’t let it weigh you down.",
    "Heard about the loss. Stay sharp; this isn’t the end of your story.",
    "Heard someone got lost in the tracks. Every mission carries a cost; we learn to accept that.",
    "Heard about the loss. Their actions contributed to our success; that’s important. A shame.",
    "A loss. You’ve seen worse... channel this into resolve.",
    "A brief loss. We keep moving forward—it's what our collegue would want.",
    "A loss. Process this in your own time; the job remains.",
    "Someone left this forsaken place. There are always more challenges ahead; focus on those.",
    "I heard about it. Grief is part of our world; don’t ignore it, but don’t let it hinder you.",
    "Heard about the loss; it's a harsh reminder of our line of work.",
    "I know you’re feeling it; they gave their all out there.",
    "Acknowledge the loss; it’s part of the job we chose.",
    "Heard our merc fought bravely; their sacrifice won’t be forgotten.",
    "It's tough to lose a teammate; honor them by doing your best.",
    "I recognize the weight of this; use it to fuel your focus.",
    "Heard about the circumstances; we can’t allow it to break us.",
    "There’s a heaviness to their loss; let’s carry it wisely.",
    "I know this is hard; keep their spirit alive in your work.",
    "Heard our friend had your back; you did well alongside them.",
    "I heard about the loss; it's a tough pill to swallow.",
    "I know it’s hard to lose someone you were close to.",
    "Heard our friend went down fighting; we honor their bravery.",
    "I recognize the struggle; it’s a part of this life.",
    "Heard about the circumstances; it’s a harsh reality for us.",
    "I see the weight you carry; it’s important to acknowledge it.",
    "I know this isn’t easy; our friend will be missed in our ranks.",
    "Heard our friend trusted you; that speaks volumes about your commitment.",
    "I recognize the impact of this loss; let’s channel that energy.",
    "Heard you did your best under tough conditions; that matters.",
    "Heard about the loss. Our friend joined the ranks of those who've fallen.",
    "I know it’s tough; they’re off to the afterlife now, beyond this chaos.",
    "Heard they’ve moved on; may they find peace in the digital void.",
    "I recognize the weight of this; they’ve shed their physical form.",
    "Heard our friend gave their all; now they’re on a different path.",
    "In this world, we see too many join the afterlife; it’s a cruel fate.",
    "I know it’s hard; they’ve left the fight, but their spirit lingers.",
    "Heard they faced the end with courage; they’ve joined the legends.",
    "It’s a harsh reality; in the afterlife, they’ll find what’s lost here.",
    "Heard they’ve crossed over; let’s ensure their memory sparks our resolve.",
    "Heard about the loss; they’ve transitioned to the digital afterlife.",
    "I know it’s difficult; they’ve left this world behind.",
    "Heard they’ve joined the countless souls in the net; it’s a wild ride.",
    "I recognize your pain; they’re free from the struggles we face.",
    "It’s a hard truth; they’ve moved beyond the neon shadows.",
    "Heard they gave everything; now they roam the realms beyond.",
    "I know you feel the gap; they’ve slipped into the void.",
    "In this life, losses are too common; they’ve found their rest elsewhere.",
    "Heard they’ve crossed that threshold; let’s honor their journey.",
    "I know it weighs on you; they’ve become part of the circuitry now.",
    "Heard about the loss; they’ve joined the ones lost in this city.",
    "I know it’s a tough turn; they’ve connected to the afterlife.",
    "Heard our fellow merc fought well; now they navigate the other realms.",
    "I recognize your grief; they’ve transcended the flesh, becoming more.",
    "Heard our friend has taken the final leap; may their spirit spark the future.",
    "I know it's hard; they’ve become part of the legends in the grid.",
    "In this brutal world, many find peace beyond the digital veil.",
    "Heard our friend crossed into the unknown; let’s keep their memory alive.",
    "I understand this weighs heavy; they’ve found freedom from this chaos."
}
function CyberNPC.NPCMercDiesQuestLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCMercDiesQuestLines))
    return CyberNPC.NPCMercDiesQuestLines[line]
end

CyberNPC.NPCResponseAskBackupLines = {
    "Alright, got it. I'll get someone on that.",
    "This should be doable. Hold on, I'm directing you to this merc. A reliable asset for this kind of thing.",    
    "Check your inbox; I've assigned an available unit.",
    "Running a quick check. Yeah, someone can take that over now.",
    "Got you covered. They'll be with you shortly to handle the specifics.",
    "Understood. I'm coordinating their arrival for priority assistance on this task. Sending a meet-up location",
    "Just one moment. I will send a briefing first. I see. This one is going to help. Sending you the coords afterwards.",
    "Hmm, details? Let's see if they have capacity in addition to skill set. Let me send you the coords. Do not fail me.",
    "Right, let's get them assigned properly. This isn't a simple side hustle. I'm sending you the coords for the merc's location.",
    "Need a sec to vet potential candidates for this level of work. And done. Sending you the coords",
    "I never thought you'd ask, V. Sending you the coords.",
    "No problem. I'll dispatch someone now. They're already on route.",
    "My network is vast. Let me connect you with the perfect operator. One candidate here. I see. Interesting. Ok. Sending you the location",
    "Consider it assigned. Specializes in let's say: contingency planning. You are going to like each other. Sending you the coords",
    "Of course. Let me check if someone is available. 1. 2. 3. 4. Ah! This one is free. Take the location. Good luck!",
    "Alright, I've got this in my system. Let me connect you with the right contact.",
    "Understood. I'll ping 'The Prime' right now; he's ideal for high-stakes situations like this.",
    "Alright, understood. Someone is being dispatched to assist you with that priority task.",
    "My network is vast. Let me connect you with the perfect operator for this specific contingency.",
    "I'll get it sorted. You're looking at a reliable off now, probably this one. Ir maybe someone else. If they have capacity.",    
    "Hold on, I need to brief them properly before sending anyone out. This isn't just about finding help, it's about the right skills for your specific situation. Give me one second ... And done. Sending you the deats.",
    "Let me pull up their profile... yes, assistance should be available. Think adept enough at this kind of sensitive off.",
    "Term are standard. The merc wants maximum compensation plus a reputation check post-operation. Sending you the coords",
    "Standard rates apply if you need direct assignment assistance now while handling your core task. Sending you the location.",
    "This requires someone who can handle this kind of jobs. I'll assign someone for this type of operation.",
    "They're on standby, but not exactly my first choice due to recent conflicts they're involved in. Sending you the location. Good luck!",
    "Alright, got it. They need to be briefed now; conditions are... unusual off here. Sending you the merc's location",
    "Of course, I'm on it. Let's see who’s free for this assignment. Sending you the merc's coordinates now.",
    "Hold tight; I’ll pull up a shortlist of reliable mercs for you. Stay tuned—coordinates are on the way.",
    "I’ve got a few operators in mind. Let me check their availability. You’ll have their location shortly.",
    "Just a moment—I'm vetting my contacts for someone perfect for the job. I’ll send the location as soon as I can.",
    "No problem. I’ll send you the details of a qualified merc shortly. Just confirming their coordinates now.",
    "Let’s keep this discreet. The right skills are non-negotiable for your needs. I’ll forward the location ASAP.",
    "Check your inbox; I'll dispatch an operator who's ideal for this type of work. Coordinates coming your way.",
    "This one specializes in high-pressure situations. Sending over coordinates as we speak.",
    "I’ll get this sorted. You deserve someone with a solid track record. I’m pulling their location now.",
    "Need a second to assess capabilities. I’ll ensure they’re up to the task. Location details will follow.",
    "Let me connect you with a specialist. They’re worth their weight in eddies. Hang tight for their coordinates.",
    "Hang on; I’ll confirm the mission parameters and coordinate quickly. Sending the merc's location right after.",
    "I'll reach out to a few trusted mercs—experience is vital in this line of work. I’ll send their coordinates shortly.",
    "Just a moment. I want to ensure we have someone adept for this assignment. Coordinates will be sent in a tick.",
    "Alright, I’ll make sure they have the intel they need before deployment. Location will be on its way in a sec.",
    "You can count on my network; finding the right fit is what I do best. I’ll forward the coordinates soon.",
    "Stand by; I’ll get a promising candidate on the line for you. Expect their location momentarily.",
    "This isn't a simple job; I’ll ensure the operator has the right expertise. Coordinates will be dispatched shortly.",
    "Let me check if my contacts have the bandwidth for this. Expect an update soon with the location.",
    "Alright, they’ll appreciate the urgency. Dispatching coordinates now and confirming details as I go.",
    "I have a couple of reliable mercs in mind. Gathering their locations now.",
    "Let me dig deeper into my contacts; I have someone who can handle this. Coordinates are incoming.",
    "I’m connecting with a merc known for discretion. I’ll send you their location shortly.",
    "Just reaching out to a couple of specialists. Expect their coordinates in a moment.",
    "I've got a lead on an exceptional candidate. Let me confirm their location for you.",
    "Hold on; I’m sourcing someone with advanced skill sets. Their coordinates will be sent right after.",
    "This merc has the expertise for high-stakes operations. Getting the coordinates for you now.",
    "I’ll check if anyone is available who fits your needs. Sending you the location momentarily.",
    "I know an operator who thrives under pressure. I’ll ensure you get their coordinates quickly.",
    "Let’s expedite this. I’m contacting a few trusted sources—coordinates will be on the way.",
    "Finding a proven operator for this situation. Stay tuned, I’ll send their location shortly.",
    "Let me see if I can snag a top-tier merc for you. I’ll confirm their coordinates ASAP.",
    "I’m pulling in a few options known for successful outcomes. Sending you their locations shortly.",
    "Working on securing the best fit for you. I’ll provide the coordinates as soon as possible.",
    "I’ll make sure this merc has the right gear for the job. Their location is being sent now.",
    "You can count on my network to deliver. I’m finalizing coordinates for you.",
    "Just a moment—I’m ensuring the candidate is ready to roll. Their location will be sent shortly.",
    "I’ve got a lead on a seasoned operator. I’ll dispatch their coordinates right away.",
    "Let me sort through a few profiles. Expect their location in your inbox soon.",
    "Checking on the availability of a merc who excels in tough situations. Coordinates will follow.",
    "I’m scouting for someone who’s highly rated in this area. Sending you their location shortly.",
    "Just a moment, I’m verifying someone’s availability who can handle this. Expect coordinates soon.",
    "I have an operator in mind who's well-versed in covert ops. Coordinating their location now.",
    "I’ll connect with a merc who’s got a solid cache of skills. I’ll send you their coordinates right away.",
    "Let me check the status of a reliable asset. Their location will be shared with you shortly.",
    "This job requires finesse; I’ll make sure you’re matched with the right operator. Sending coordinates now.",
    "I’m contacting a merc who has pulled off several successful jobs in the past. Coordinates are on the way.",
    "I’ll reach out to someone with a keen eye for detail. You’ll have their location in a moment.",
    "Tapping into my network for a specialist. I’ll send you their coordinates ASAP.",
    "This one's got the chops for high-stakes challenges. I’m sending their location your way.",
    "I’m gathering intel on a few dependable mercs. Look for their coordinates shortly.",
    "Just confirming with someone who excels at strategic operations. Their location is coming soon.",
    "I’ll check in with a trusted operator. Location details will follow quickly.",
    "Let me brief a promising candidate. Expect their coordinates to arrive shortly.",
    "This operator has a reputation for reliability. I’ll send you their location right after I confirm.",
    "Hunting for someone with the right skills for this mission. You’ll have their coordinates ASAP.",
    "I’ll ensure the merc is updated on your needs. Their location will reach you soon.",
    "Checking the status of a few seasoned pros. Coordinates are being compiled as we speak.",
    "Dialing in a contact known for getting results—location will follow shortly.",
    "I’m reaching out to a colleague who specializes in sticky situations. Expect their coordinates momentarily.",
    "I know just the merc for you—someone with the right touch. Sending their location your way now.",
    "Hang tight, my friend; I'm tapping into my contacts. You can trust this next merc—coordinates are on the way.",
    "I’ve got someone in mind who has your back covered. I’ll shoot you their coordinates shortly.",
    "Just a moment—I've got a solid lead on a merc who knows how to get things done. You’ll have their location soon.",
    "I’m pulling in a favor from a reliable source. This one is good. Coordinates are being sent over.",
    "I feel confident about this operator. They’ve proven themselves time and again. Sending you their coordinates now.",
    "Let me reach out to a personal favorite of mine. They’ll understand exactly what you need—location coming soon.",
    "Hold on; I’ll make sure my top contact is available for you. You’ll have their location in no time.",
    "You deserve someone who can truly deliver. I’m on it—coordinates will be in your inbox shortly.",
    "Just checking on a merc I trust implicitly. Expect their coordinates any moment now; they won’t let you down.",
    "Let’s get you the right help. I’m connecting with someone who knows the ropes—sending their details soon.",
    "I know a merc who excels in tricky scenarios. I’ll send you their location; you’ll be in good hands.",
    "Give me a sec to reach out to a trusted colleague. They’ll take good care of you—location is on the way.",
    "This one has a knack for these kinds of operations. I’m sending their coordinates now; you won’t regret it.",
    "Just a moment; I’m ensuring the right folks are available. Expect a solid lead and their location shortly.",
    "I've got a reliable operator who’s a friend of mine. Sending their location; I trust them completely.",
    "I’ll make sure they know you're counting on them. Their coordinates will reach you shortly.",
    "Reaching out to someone I know will fit right in with your needs. Sending you their location soon.",
    "This merc has a personal stake in getting it right. I’ll send over their coordinates right away.",
    "I have a few contacts I trust implicitly. Let me gather their details for you; coordinates are on the way.",
    "I’ve got the perfect match for you in mind—someone who’s been through the fire. Sending their coordinates your way.",
    "Just a moment; I’m reaching out to one of my go-to mercs. You’ll have their location shortly—they’re top-notch!",
    "I trust this next operator wholeheartedly. They know how to handle pressure. Expect their coordinates soon.",
    "Hang tight; I'm digging into my network. I’ll find someone you can count on—coordinates coming right up.",
    "I know someone who can tackle this challenge with style. Sending you their location—this one is special.",
    "Let me contact a merc I’ve worked with before. They have your back. You’ll get their coordinates shortly.",
    "Just checking in with a close ally; they’re on the ball. I’ll send over their location in a moment.",
    "I can’t let you down; I’m pulling in a trusted asset for you. Their coordinates are being sent over now.",
    "You need the best, and I’ve got just the person for this. Sending their location; you’ll be glad you called me.",
    "I’m getting in touch with someone who’s always delivered for me. Expect their coordinates momentarily.",
    "Hold on; I'm reaching out to a merc who has a solid track record. You’ll have their location in a heartbeat.",
    "Let’s not waste time. I’m connecting you with a specialist I know. Coordinates will be on their way shortly.",
    "I have a lead on a personal favorite—someone who can adapt to any situation. Sending you their coordinates now.",
    "Just a sec—I’m confirming details with a merc I trust completely. Their location will follow soon.",
    "You deserve someone who understands the stakes. I’ll line up a contact who’s got your back, sending you their location.",
    "I’m checking with my trusted network to ensure we get the right fit. Expect coordinates shortly.",
    "This merc has always come through for me. I’m sending their coordinates; I’d trust them with my own life.",
    "Just confirming a strategic operator. You’re in for a treat; sending their location right away.",
    "Let me ensure this operator is ready for action. You’ll have their coordinates soon—trust me on this.",
    "I’m revolving my contacts’ schedules to find the perfect fit for you. Sending over their details shortly.",
    "I know a merc who thrives under pressure and gets the job done right. Sending their coordinates your way.",
    "Just a moment; I'm reaching out to a reliable contact. You’ll appreciate having this one—coordinates coming soon.",
    "Hold tight; I have someone who’s a perfect fit for your needs. Their location is being sent over now.",
    "Let me confirm with a proven asset who’s got your back. You’ll receive their coordinates shortly.",
    "I’ve got a top-notch merc who knows the lay of the land. Sending their location now—you’re in good hands.",
    "I trust this operator implicitly. They’ll handle the task with finesse—expect their coordinates any moment.",
    "Just reaching out to someone I know can get results. Coordinates will be on your way shortly.",
    "This merc has a reputation for being dependable and resourceful. I’ll send you their location right away.",
    "I’m coordinating with a friend who really excels in sticky situations. You’ll have their coordinates very soon.",
    "This one is a real heavyweight in the field. I’m sending their location; you won’t regret this choice.",
    "Just a moment; I’m checking in with someone who always gets the job done. Their coordinates are on the way.",
    "I have a reliable operator who specializes in your type of need. Sending you their location shortly.",
    "Let me finalize things with a merc I’ve worked with before. Expect their coordinates soon—it’s a solid choice.",
    "You deserve nothing but the best. I’m lining up an exceptional candidate for you—sending their location now.",
    "This merc has the chops and knows the stakes. I’m sending you their coordinates right after I confirm.",
    "I’m ensuring everything is set for you. You’ll receive the merc's location shortly; I'm on it.",
    "Reaching out to a seasoned pro who I trust to handle this with care. Expect their coordinates soon.",
    "I’ll make sure this merc is prepped and ready for action. Their location is coming your way shortly.",
    "Just double-checking with an operator I know will deliver. You’ll have their coordinates soon.",
    "Getting you connected with someone who has a proven track record. Coordinates will reach you shortly.",
    "I have the perfect merc in mind—someone who knows how to navigate the city's underbelly. Sending you their coordinates now.",
    "Just a moment; I’m reaching out to my top-tier contacts. You’ll appreciate this choice—location coming soon.",
    "I know an operator who delivers results every time. Their coordinates are being sent your way shortly.",
    "Hold tight; I’m checking in with someone who’s a wizard at handling tough jobs. Coordinates will follow.",
    "You need a specialist, and I’ve got just the right person. Sending their location—trust me on this.",
    "Let me confirm with a merc who understands the nuances of this task. You’ll have their coordinates soon.",
    "I’m connecting with a colleague who has never let me down. Expect their coordinates to arrive shortly.",
    "This operator has a knack for getting the job done with flair. Sending you their location right away.",
    "Just a moment; one of my reliable contacts is available. I’ll forward their coordinates to you.",
    "I’ve got a solid operator lined up. You’ll want to have this one on your side—sending the location now.",
    "I’m reaching out to a merc who thrives in high-stakes situations. Coordinates will be sent shortly.",
    "Let’s get you someone who won’t make you regret this choice. I’m sending their location now.",
    "This merc has a stellar reputation in the field. I’ll send you their coordinates right after I confirm.",
    "I know someone who can adapt on the fly and deliver results. Expect their location momentarily.",
    "You deserve a top-notch merc. I’m securing their details—coordinates will follow soon.",
    "Just checking with a specialist who can tackle this with style. Sending you their location ASAP.",
    "I trust this merc’s judgment completely. I’ll send over their coordinates shortly; you won’t be disappointed.",
    "Let me ensure they’re on board and ready for action. Their coordinates will reach you in just a moment.",
    "This operator excels in tough negotiations. You’ll have their coordinates soon; I’m making the connection now.",
    "Getting you lined up with someone I know won’t back down. Expect their location shortly.",
    "I’ve got someone who can handle this, though they’re not the top of the line. Sending their coordinates now.",
    "Just a heads up—this merc is reliable but not the best of the best. I’ll send you their location shortly.",
    "This isn’t a prime job, so I’m connecting you with someone capable, but you might want to lower your expectations. Coordinates coming soon.",
    "I have a decent operator who can get the job done, but they’re not exactly elite. Expect their location shortly.",
    "This contract doesn't warrant the top-tier talent, but I’ll send you someone who can manage. Coordinates are on the way.",
    "I found a merc who’s available, though they might require some oversight. Sending their location now.",
    "This one’s not a heavy hitter, but they should be able to handle the basics. I’ll send their coordinates your way.",
    "You’ll get someone who can do the job, but don’t expect them to be a star. Coordinates coming soon.",
    "Just a moment; I’ve got a solid, if unremarkable, merc for you. Their location will be sent shortly.",
    "I’m connecting you with a merc who’s suitable for this task—just keep in mind they aren't among the best. Location details will follow.",
    "This merc should be able to take care of things, though they may not impress. Sending their coordinates now.",
    "Let’s keep expectations realistic; I’m sending you someone who’s competent without the flash. Coordinates will arrive soon.",
    "You’ll need to manage this one closely; they're good but not exceptional. I’ll share their location right away.",
    "I have an operator who is reliable enough for a task like this. Expect coordinates soon, but don’t expect miracles.",
    "Just confirming a merc who's okay for the price point. I’ll send you their coordinates, but it’s not a top-tier selection.",
    "I wouldn’t call this merc extraordinary, but they’ll get the job done. Sending their location shortly.",
    "This is a decent choice given the budget; I’ll send you the coordinates, so you know where to find them.",
    "Just reaching out to a fair candidate. They’ll manage, but don’t expect any showmanship. Coordinates coming soon.",
    "I’m sending you an available merc who’s decent for the pay. Their location will follow shortly.",
    "This operator can handle the basics, but it’s not going to be a spectacular experience. Expect coordinates soon.",
    "I found someone who should be able to manage. Not top-tier by any means, but suitable for this job. Sending their coordinates now.",
    "Just a heads up—the merc I’m connecting you with isn’t exactly a heavyweight. I’ll get their location to you shortly.",
    "This isn't the kind of job that demands the best. Sending you someone who’s competent enough to handle it—coordinates on the way.",
    "I have a solid contact for you, though they might not impress. Sending their location now; keep expectations in check.",
    "You’re getting a reliable operator, but I wouldn’t call them elite. Coordinates will arrive shortly.",
    "I’ve got an available merc who can handle the basics, but don't expect any fireworks. Their location is being sent.",
    "This merc’s decent enough for a contract like this. Sending their coordinates your way—manage your expectations.",
    "You’ll have someone who can get the job done, but they’re not on my list of top picks. Expect coordinates soon.",
    "I’m sending you a functioning merc, though they won’t knock your socks off. Their location will be on your way.",
    "Just checking in with a dependable operator. Keep in mind they aren’t the finest. Coordinates will be sent soon.",
    "This one knows the ropes but isn’t going to wow you. Sending their location right after I confirm.",
    "You’ll need to guide this merc a bit; they’ll manage, but they’re not the best choice for the job. Coordinates follow.",
    "I have a reliable merc who can handle it, but don’t expect extraordinary results. Their location is coming soon.",
    "Just confirming details with a candidate who’s okay for this type of work, but not a standout. Expect coordinates shortly.",
    "I’m sending over someone who can get through the task but is far from impressive. Look for their coordinates soon.",
    "This option should suffice for the job; they’re competent but not exceptional. Sending their location now.",
    "You’ll be getting someone who can get it done, albeit without flair. Their coordinates are on the way.",
    "I’m pulling in a merc who’s alright for this kind of task. Just sending you their coordinates as we speak.",
    "This isn’t a prime contract, so managing a budget pick. I’ll send their coordinates, but don’t expect too much.",
    "This merc should do in a pinch, but it’s not an ace you’re getting. Sending the location now.",
    "I’m sorry, but the job isn't worth pulling in my best. I’ve got someone who can manage, though you might not be impressed. Sending their coordinates now.",
    "Unfortunately, this isn't a high-stakes gig, so I’m sending you a merc who’s... adequate at best. Coordinates are on the way.",
    "I’ve found someone who can handle this, but I’ll be honest: they’re not inspiring. Sending their location now; just hang in there.",
    "You’re getting a merc who will get the job done, but they’re not great, and frankly, it’s disappointing. Expect their coordinates soon.",
    "This one’s decent, but I wish I had better to offer you. This contract doesn't deserve my top picks. Their location will follow.",
    "I wish I could connect you with a real talent, but this merc is just... bare minimum. Sending you their coordinates now.",
    "The pickings are slim, and I can only offer someone who's kind of okay. You’ll receive their coordinates shortly, but it's not ideal.",
    "You’ll have to settle for someone who can manage, but it feels like a letdown. Coordinates are on their way to you.",
    "I’m pulling a reliable merc, but they’ve seen better days. I’ll send you their location, knowing it’s not what you hoped for.",
    "This merc is available, but I can’t say you’ll be thrilled. Sending their coordinates; it’s a tough break.",
    "Sorry, but this isn’t a prime opportunity. I’ll connect you with a merc who's... fine, not stellar. Coordinates incoming.",
    "I hate to say it, but the options are bleak. Sending you someone who's there, but keep your expectations low. Location will arrive soon.",
    "I know this isn’t what you wanted. The merc I found is just capable enough to get by. Sending their coordinates now.",
    "I’m afraid you’ll have to make do with a less-than-stellar option. Sending you the coordinates; it’s not what you'd expect.",
    "This is a tough situation, and the merc I’m sending is just... acceptable. Coordinates will follow; it’s not exciting.",
    "You’ll be getting someone who can do the job, but you might wish for better. I’ll send their coordinates, knowing it’s disappointing.",
    "This one’s not a real standout, but they’re who I can provide for this kind of job. Their coordinates are being sent now.",
    "I wish it were a better match, but you'll have to settle for mediocrity. Coordinates coming your way—it’s a letdown.",
    "I could only find someone who’s okay for the job, which feels like a missed opportunity. Sending their location now.",
    "I’m really sorry, but the job just isn’t worth much. I can find you a merc, but they’re far from impressive. Sending their coordinates now.",
    "This isn't a lucrative gig, so I’m stuck sending you someone only marginally competent. Expect their location soon; it’s a disappointment.",
    "I wish I had better news, but I’m only able to offer you a merc who’s merely adequate. Coordinates are on the way, but I know it’s lackluster.",
    "Unfortunately, this isn’t a prime opportunity. I’ll send you a merc who can just get by, but you might be let down. Location coming shortly.",
    "You’ll have to make do with someone who can handle it, but I can’t promise anything bright. Sending their coordinates now.",
    "I know this isn't exactly thrilling, but I’m connecting you with a merc who’s... just okay. Coordinates are being sent now.",
    "You’ll be getting someone who’s almost a last resort. It’s not what you hoped for, but coordinates are en route.",
    "This isn’t shaping up to be great. The merc I found is there, but it’s not exciting. Expect their coordinates soon.",
    "I wish I could give you something better. The operator I’m sending is just barely adequate. Sending you their location.",
    "I’m really sorry, but the pickings are slim. This merc is capable but far from stellar. Coordinates are on the way.",
    "You won’t be happy with this choice, but it’s who I can provide. Sending their coordinates, knowing it’s underwhelming.",
    "I didn’t want to send you someone less than amazing, but that’s where we are. Their location will come shortly; it feels wrong.",
    "This is a hard one; I’ll give you a merc who can handle it, but it’s really not what you deserve. Sending their coordinates now.",
    "The merc I’m sending is just scraping by. Not just what I hoped for you. Expect coordinates soon; it’s a letdown.",
    "Not what you wanted, I know, but here’s someone who’s merely okay for the task. Coordinates incoming, but it’s disappointing.",
    "This one’s not going to thrill you, but they’re who’s available. I’ll send you their location shortly, knowing it feels inadequate.",
    "Regrettably, I'm unable to connect you with something better. Sending the coordinates for a merc who's just… fine.",
    "I wish I could find someone exceptional for you, but I can only offer someone who’s not impressive. Sending their location now.",
    "I’ll need to connect you with a merc who can manage, but it’s disappointing since I was hoping for a solo expert. Sending their coordinates now.",
    "Unfortunately, this job doesn’t warrant top talent, so I have to reach out for help. I’ll send you a decent merc’s location shortly.",
    "I was expecting to provide you with a solo operator, but I'll need to send someone who’s just adequate. Coordinates are on the way.",
    "It’s a bit disappointing, but I can only offer a merc who can handle the job but isn’t exceptional. Expect their location soon.",
    "I wish I could provide you with a better option, but I’m connecting you with someone who can take care of things. Coordinates coming up.",
    "I had hoped for a more capable solo merc, but I’ll need to connect you with a group member instead. Sending the coordinates shortly.",
    "Unfortunately, it’s not the best situation. I’m sending a merc who’s adequate but not the solo skilled talent I expected. Location follows.",
    "This isn’t the ideal scenario, but I will connect you with a merc I trust to get the job done, even if they’re not the best. Their coordinates are incoming.",
    "It’s a bit disappointing that I can’t send you a standout operator alone. Expect coordinates for someone competent soon.",
    "Regrettably, I have to approach this through a less-than-ideal merc. I’ll send you their location shortly; I was hoping for more.",
    "I was looking forward to providing you with a solo expert, but I’ll have to settle for someone who can do the job. Coordinates on the way.",
    "It seems I can’t provide the caliber of merc I initially hoped for. I’ll send you someone who’s fit for the task, even if it isn’t ideal.",
    "I’m disappointed that circumstances require reaching out for assistance. Sending the coordinates for a decent merc now.",
    "I’d hoped to connect you with a solo talent, but I can only offer someone who’s satisfactory. Expect their location soon.",
    "It’s unfortunate that I can’t send you a more impressive merc. I’ll get you their coordinates; they should still manage the task.",
    "I know this isn’t ideal, but you’ll be receiving a merc who can handle the basics. Sending their location shortly.",
    "I was anticipating a more capable solo merc, but I’m settling for someone decent. Coordinates will be sent your way.",
    "This isn’t the outcome I was hoping for, but I have to connect you with a more average merc. Sending their coordinates soon.",
    "I wish I could offer you a standout merc, but I can only provide someone who’s capable. Their coordinates will come shortly.",
    "It’s a bit disappointing, but I’ll need to connect you with a merc who’s adequate at best. Expect their location soon.",
    "Regrettably, I hoped to deliver a solo talent, but I’ll be sending someone who can get the job done. Coordinates are on the way.",
    "I know this isn’t the ideal situation, but I have to send a merc who’ll manage, even if they’re not top-tier. Location coming shortly.",
    "It’s unfortunate, but I can only connect you with a merc who’s simply decent. I’ll send their coordinates right away.",
    "I was looking to provide a stronger operator, but instead I have to settle for someone who meets the minimum requirements. Coordinates will follow.",
    "Disappointingly, it seems I can’t send a standout merc for this task. Sending you the location of someone who can handle it sufficiently.",
    "I’d hoped for a more skilled solo merc, but I’ll connect you with a reasonable choice. Expect coordinates soon.",
    "It’s not what I wanted for you, but I’m sending over a merc who can do the basics. Their location is on the way.",
    "I had high hopes for this task, but I’ll be offering a less capable option. Sending you their coordinates now.",
    "Unfortunately, I’m reaching out for someone who’s merely adequate. I’ll send their location shortly; I would have preferred better.",
    "I’m disappointed that I can’t connect you with a top-tier talent. Coordinates for a reliable merc will follow soon.",
    "While I was hoping for a solo expert, I’m sending someone who can manage the job at hand. You’ll receive their location shortly.",
    "This isn’t the caliber of merc I wanted to provide, but they should be sufficient. Expect their coordinates soon.",
    "I know this is a letdown, but I’m sending a merc who’s fit enough for the task. Their coordinates will be sent shortly.",
    "Regrettably, it seems I can’t send you the talent I wished for. I’ll provide coordinates for a merc who can handle things.",
    "I’m sorry to say that my expectations didn’t pan out. Sending you the coordinates of a merc who should suffice for the job.",
    "I'm sorry, but I don’t have a premier merc to offer. I’ll send you a competent one, though. Coordinates will follow shortly.",
    "This isn’t what I envisioned, but I can get you connected with someone who’ll do the job, even if they’re not the best. Sending their location now.",
    "I had hoped to find a stellar option for you, but I’ll have to settle for someone who’s just okay. Expect their coordinates soon.",
    "It’s disappointing that I need to reach out for help on this. I’ll send you a decent merc—coordinates will arrive shortly.",
    "While I wanted to provide a stronger operator, I can only connect you with someone who’ll get by. Their location is on the way.",
    "Regrettably, I can’t deliver the caliber of merc I had hoped for. I’ll send you their coordinates; they should manage the task.",
    "I’m a bit let down that I can’t offer you a top-tier talent for this job. I’ll send coordinates for a capable merc shortly.",
    "This isn’t the kind of support I wanted to give you, but here’s someone who can handle the situation. Sending their location now.",
    "I had better expectations, but I’ll connect you with someone who should do the basics effectively. Coordinates are coming shortly.",
    "Unfortunately, I can’t send my best for this task, but I’ll get you someone who can tackle your needs. Expect their coordinates soon.",
    "While I was aiming to provide a more skilled operator, I’ll have to send someone who’s simply adequate. Their location will follow.",
    "I know this isn’t ideal, but I’ll be connecting you with a merc who can help, even if they’re not extraordinary. Coordinates soon.",
    "Disappointment is the name of the game here—I can only provide a merc who’s fit for the task, though not exceptional. Sending their location.",
    "This isn’t what I intended, but I’ll get you a merc who can meet the minimum requirements. Expect coordinates soon.",
    "It’s unfortunate that I can’t connect you with someone stellar, but you’ll get a reliable merc for this. Coordinates coming shortly.",
    "I wish I had a stronger choice for you, but I’ll send a merc who can manage. Sending their location shortly.",
    "It’s a letdown that I can only provide a merc who’s acceptable, but I’ll make sure they’re capable. Their coordinates will be sent now.",
    "I’m bummed that the situation calls for someone lesser. I’ll send you a decent merc’s coordinates; they should get the job done."
}

function CyberNPC.NPCResponseAskBackupLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCResponseAskBackupLines))
    return CyberNPC.NPCResponseAskBackupLines[line]
end

CyberNPC.NPCQuestAskSpecialtyLines = {
    "Back-up? What kind of muscle are you looking for?",
    "Are we talking brute strength or stealthy finesse here?",
    "Do you need a techy hacker or a combat specialist?",
    "Is this someone for a clean job or a full-on firefight?",
    "What's the priority: infiltration or heavy firepower?",
    "Do you need a driver, or is this all about ground support?",
    "Are we facing corporate goons or street gangs?",
    "Do you need someone who can blend in or someone who stands out?",
    "Are we looking for a sniper's precision or a brawler's grit?",
    "How serious is the situation? Just a show of force or full tactical support?",
    "What skills are critical for this job?",
    "Is it tech expertise you need, or street smarts?",
    "Are we scouting, or is this a rescue operation?",
    "Should I find someone with experience in combat robotics?",
    "Will your backup need to navigate through hostile territory?",
    "Are you after a sharpshooter or close-quarters combat expert?",
    "How much noise can this backup make?",
    "Are you looking for a negotiator or a firestarter?",
    "Is it discretion you're after, or are we going in loud?",
    "What’s the priority: heavy arsenal or light gear?",
    "Are we talking about heavy hitters, or do you need quick movers?",
    "Do you need someone who can secure assets, or are we just enforcing caution?",
    "Is this a solo mission or a team operation?",
    "Will this require someone who can manipulate tech systems?",
    "What level of intimidation do you need from this merc?",
    "Should I focus on someone with a good network in the underworld?",
    "Are we targeting high-net-worth individuals or the down-and-out?",
    "How long is this back-up mission expected to last?",
    "Are we dealing with a high-profile target or just securing a perimeter?",
    "Is ambush potential a factor in your request?",
    "Can I assume the backup needs street fighting skills or corporate espionage experience?",
    "Are we going for a specialist in non-lethal takedowns or someone who goes all out?",
    "Should I consider someone with crowd control expertise?",
    "Does this involve salvaging equipment or securing intelligence?",
    "Is it important that they have experience with specific factions?",
    "Do you care more about psychological warfare than brute force?",
    "Is mobility a key factor, or should they be more grounded?",
    "Are we covering a retreat, or is this preparation for an advance?",
    "What regions should this merc be familiar with?",
    "Should I keep an eye out for ties to local gangs or corporate affiliations?",
    "Any prior experience required for the setting they’ll be entering?",
    "Do they need knowledge of local laws or tech regulations?",
    "Do you need them to handle crowd dynamics or just focus on the target?",
    "What level of tactical expertise is necessary for this operation?",
    "Are we aiming to intimidate or just to get the job done quietly?",
    "Would you prefer someone with a low profile or a loud reputation?",
    "How adaptable do they need to be to changing situations?",
    "What skills are critical for this job?",
    "Is it tech expertise you need, or street smarts?",
    "Are we scouting, or is this a rescue operation?",
    "Should I find someone with experience in combat robotics?",
    "Will your backup need to navigate through hostile territory?",
    "Are you after a sharpshooter or close-quarters combat expert?",
    "How much noise can this backup make?",
    "Are you looking for a negotiator or a firestarter?",
    "Is it discretion you're after, or are we going in loud?",
    "What’s the priority: heavy arsenal or light gear?",
    "Are we talking about heavy hitters, or do you need quick movers?",
    "Do you need someone who can secure assets, or are we just enforcing caution?",
    "Is this a solo mission or a team operation?",
    "Will this require someone who can manipulate tech systems?",
    "What level of intimidation do you need from this merc?",
    "Should I focus on someone with a good network in the underworld?",
    "Are we targeting high-net-worth individuals or the down-and-out?",
    "How long is this back-up mission expected to last?",
    "Are we dealing with a high-profile target or just securing a perimeter?",
    "Is ambush potential a factor in your request?",
    "Can I assume the backup needs street fighting skills or corporate espionage experience?",
    "Are we going for a specialist in non-lethal takedowns or someone who goes all out?",
    "Should I consider someone with crowd control expertise?",
    "Does this involve salvaging equipment or securing intelligence?",
    "Is it important that they have experience with specific factions?",
    "Do you care more about psychological warfare than brute force?",
    "Is mobility a key factor, or should they be more grounded?",
    "Are we covering a retreat, or is this preparation for an advance?",
    "What regions should this merc be familiar with?",
    "Should I keep an eye out for ties to local gangs or corporate affiliations?",
    "Any prior experience required for the setting they’ll be entering?",
    "Do they need knowledge of local laws or tech regulations?",
    "Do you need them to handle crowd dynamics or just focus on the target?",
    "What level of tactical expertise is necessary for this operation?",
    "Are we aiming to intimidate or just to get the job done quietly?",
    "Would you prefer someone with a low profile or a loud reputation?",
    "How adaptable do they need to be to changing situations?",
    "What kind of extraction skills are you looking for?",
    "Do you need someone who can disable security systems?",
    "Is this a matter of speed or strategy?",
    "Are we looking for a getaway driver or a ground tactician?",
    "What sort of reputation should this merc have?",
    "Should I prioritize someone who’s ex-military or a streetwise urbanite?",
    "Do you want them to handle negotiations or just execute orders?",
    "Are you concerned with their ability to improvise on the fly?",
    "Is medical knowledge a requirement for this job?",
    "Do we need someone adept at surveillance and intelligence gathering?",
    "What kind of combat style do you prefer: agile or brute force?",
    "Is adaptability important, or do we need a specific skill set?",
    "Are you focusing on urban warfare or open-field combat?",
    "Should they possess skills in digital stealth or physical evasion?",
    "How crucial is their ability to gather information and intel?",
    "Do you need specialized equipment training for the job?",
    "Are we looking for someone who can blend in with high society?",
    "Should I seek out a contact with street racing expertise?",
    "Are we dealing with a hostage situation, or is this offensive?",
    "What type of tech proficiency are you expecting?",
    "Do we need someone comfortable with handling aberrant cybernetics?",
    "How do you feel about a merc with a history of breaking the rules?",
    "Would you prefer a lone wolf or a team player?",
    "Is the operable area novel for this merc or familiar ground?",
    "Are they going to need skills in hacking or just direct confrontation?",
    "Is tracking and field analysis part of this skill set?",
    "How high of a profile should they maintain during the job?",
    "Are you after someone with charm, or is brute intimidation better?",
    "Do you have a preference for their previous employers?",
    "What’s the urgency of this backup: immediate or a planned operation?",
    "Should their primary focus be tactical analysis or operational execution?",
    "Do you want someone well-versed in the latest weaponry?",
    "Should they have expertise in cryptography or digital warfare?",
    "What kind of endgame do you envision for this backup?",
    "Is the backup for a short-term job or an extended engagement?",
    "Are we considering collateral damage, or should they be surgical?",
    "How adaptable should they be to working with different teams?",
    "Do you need someone with a good understanding of Night City’s politics?",
    "Should they have skills in civilian defense or military tactics?",
    "Are we looking for someone experienced in counter-surveillance?",
    "What levels of deception should they be prepared for?",
    "Do you expect them to have any insider contacts?",
    "How much gear should they bring versus improvising on-site?",
    "Are we after someone with a knack for escape artistry?",
    "Is synergy with other team members a consideration?",
    "What kind of backup do you envision for potential extraction scenarios?",
    "Should I prioritize past loyalty or current skills?",
    "Do you want someone who can inspire fear in foes or rally friends?",
    "Are they expected to adapt to new tech quickly?",
    "Do we need urban combat experience or rural skirmishing skills?",
    "Should they have connections in law enforcement or not?",
    "What kind of social skills do you expect them to possess?",
    "Are probabilities of failure within their consideration?",
    "Is prior experience in corporate sabotage essential for this role?",
    "Are mental acumen and decisiveness equally critical?",
    "Would you value someone with negotiation skills more than combat prowess?",
    "Should I focus on their street cred or their tactical prowess?",
    "Do you need someone skilled in hand-to-hand combat or ranged techniques?",
    "Are we emphasizing stealth over firepower?",
    "How crucial is their ability to work under pressure?",
    "What kind of psychological tactics do you prefer for this role?",
    "Should I prioritize a merc with street logic or corporate experience?",
    "Are they expected to manage logistics or just focus on execution?",
    "Do we need direct action capabilities or strategic planning?",
    "What kind of extraction techniques should they possess?",
    "Is infiltration a key component of their role?",
    "What kind of personal code of ethics do you expect from them?",
    "Are we dealing with explosive charges or silent approaches?",
    "Should they have experience in counter-intelligence?",
    "Are we wanting a merc skilled in negotiation or intimidation?",
    "How well must they navigate urban landscapes?",
    "Is tech-savvy a requirement, or is physical prowess more important?",
    "Do they need experience with drones or surveillance systems?",
    "Will they need to work with the media or influencers?",
    "Should I find someone familiar with the corporate hierarchy?",
    "What kind of reliability do you expect from this mercenary?",
    "Do you need a fixer with experience in high-stakes negotiation?",
    "Is there a specific combat style they're trained in?",
    "Do they need to know how to manipulate the local gangs?",
    "Are we looking at a solo operation or a collaborative effort?",
    "What kind of morale boost can they provide in tight situations?",
    "Should they have knowledge of local laws to avoid trouble?",
    "Is situational awareness a must-have for this job?",
    "Will this role involve close contact with civilians?",
    "What's the expected flexibility in tactics for the backup?",
    "Should they be adept at disguises and role-playing?",
    "How important is it for them to outsmart opponents?",
    "Will they need to utilize advanced gear?",
    "Are connections with other mercs a priority for this role?",
    "Should we consider someone with high-ranking credibility?",
    "Do you want them to be a voice of reason or a wild card?",
    "How well must they deal with unexpected challenges?",
    "What’s their level of resourcefulness in critical scenarios?",
    "Is it essential that they have a preferred area of expertise?",
    "Are we looking for combat training or negotiation tactics?",
    "How much freedom of action should they have?",
    "Will they need to conduct psychological assessments?",
    "What kind of energy or morale boost do you expect from them?",
    "Are we focusing on extraction or retrieval of information?",
    "Should they possess charm to sway allies and foes alike?",
    "What deadlines should they be aware of?",
    "Are we targeting a specific demographic with this backup?",
    "How many contingencies should they plan for?",
    "Do you need them to operate under the radar or in plain sight?",
    "Should I look for someone specializing in digital strategies?",
    "What level of intercultural awareness is necessary?",
    "Should they be familiar with specific street cultures?",
    "Is an existing rapport with any factions a plus?",
    "How should they approach negotiations?",
    "Will they need to gather intel from reluctant informants?",
    "Is loyalty to the faction more important than flexibility?",
    "What kinds of tactics should they be ready to employ?",
    "How much experience with street-level tactics is optimal?",
    "Are they expected to offer emotional support or tactical advice?",
    "Should we consider their ability to work with various tech?",
    "What kind of past missions should they reference?",
    "How do you feel about a merc with controversial methods?",
    "Will they need to maintain a cover identity for this job?",
    "Are we aiming for swift elimination or strategic placement?",
    "Should their skill set lean toward defense or aggression?",
    "How much experience should they have with negotiations?",
    "Are we after a peaceful resolution or full-scale conflict?",
    "What kind of crisis management skills are necessary?",
    "Is there a requirement for adaptability to various fighting styles?",
    "Should I look for a merc with ties to law enforcement?",
    "What sorts of escape plans should they have in mind?",
    "Will they need to handle hostile locals or officials?",
    "How important is it that they have street smarts?",
    "Is there a need for experience in dealing with cyber threats?",
    "How versed should they be in advanced combat techniques?",
    "Will they need to develop connections with new resources?",
    "What's more critical: technical skills or physical strength?",
    "Should I consider their reputation among contractors?",
    "Do you expect them to engage in covert operations?",
    "Do you want someone who can handle multiple roles at once?",
    "Should they be well-versed in the latest combat enhancements?",
    "Are we looking for someone with a knack for evasion tactics?",
    "Do you need them to specialize in hostage negotiations?",
    "What personal traits do you value most in this merc?",
    "Is teamwork more important than individual expertise?",
    "How crucial is their ability to deceive adversaries?",
    "Should they have experience in extraction missions?",
    "Do you expect them to manage a crew or go solo?",
    "Are we focusing on tactical communication skills?",
    "Will they need to adapt to high-stakes environments?",
    "Is experience in corporate warfare a plus?",
    "Should I seek someone adept at crowd manipulation?",
    "How crucial is experience in fast-paced operations?",
    "Is conflict resolution a priority for this job?",
    "Do you want them to engage directly with targets?",
    "Should they be prepared for a variety of combat scenarios?",
    "What kind of strategy development should they be skilled in?",
    "Are we looking at someone with a flair for showmanship?",
    "Do you need support in maintaining operational secrecy?",
    "Is previous collaboration with high-profile clients necessary?",
    "Should I look for a merc with expertise in counter-terrorism?",
    "How important is it for them to have a family background in the field?",
    "Is it essential that they understand corporate espionage tactics?",
    "What’s your stance on mercs with a history of double-crossing?",
    "Should I find someone who can act as a mediator in tense situations?",
    "Are we focusing on agility and speed, or sheer force?",
    "How much training should they have in advanced martial arts?",
    "Do you expect them to handle financial negotiations?",
    "Should relationships with potential allies be considered?",
    "Is it vital for them to have a strong presence on social media?",
    "Do you need someone who can execute a strategic retreat?",
    "How adaptable should they be to unusual circumstances?",
    "Is situational analysis a key requirement for this role?",
    "Are they required to ensure safety or take risks?",
    "What kind of geographic knowledge should they possess?",
    "Are we targeting corporate assets or illegal operations?",
    "What defines success for this backup merc?",
    "Do you want them to have expertise in survival tactics?",
    "Is psychological warfare part of their toolbox?",
    "Should they have experience with high-tech gear?",
    "What kinds of ethical boundaries should they be aware of?",
    "Do you expect them to develop contingency plans?",
    "How important is it for them to understand social hierarchies?",
    "What sorts of environments should they be familiar with?",
    "Should they have access to advanced weaponry?",
    "Is it essential for them to have a history of loyalty?",
    "Will they need to navigate political landscapes?",
    "What is your stance on mercs with questionable morals?",
    "Should I prioritize previous military experience?",
    "Are they expected to lead or follow in tactical situations?",
    "Do you need someone who can handle public relations?",
    "Should they be familiar with non-lethal combat techniques?",
    "Are we seeking someone with experience in cyber warfare?",
    "Do you expect them to be familiar with local customs?",
    "How deep should their connections in the underworld go?",
    "Should they possess a natural ability to influence others?",
    "Do you need them to gather evidence or eliminate threats?",
    "What kind of background should they have in digital sociology?",
    "Is a history of negotiation experience crucial?",
    "Are we looking for someone with a flair for creating alliances?",
    "How often should they be expected to engage in combat?",
    "What kind of stamina requirement should they have?",
    "Should we consider their ability to handle multiple threats?",
    "Are negotiation skills more critical than combat capabilities?",
    "Should they be comfortable operating in hostile territories?",
    "How vital is their ability to read body language?",
    "Do you care about their past affiliations with any factions?",
    "Should their physical appearance be part of the strategy?",
    "What level of sensitivity should they have to social cues?",
    "Are we focusing on buzz-building or damage control?",
    "Is there an expectation for them to train others?",
    "Should I look for someone who thrives in chaos?",
    "Do you want them to specialize in public distraction tactics?",
    "What kind of psychological resilience do they need?",
    "Is a track record of success in previous missions necessary?",
    "How familiar should they be with contract law?",
    "Should I consider their adaptability to new tech?",
    "Is previous experience with exfiltration critical?",
}
function CyberNPC.NPCQuestAskSpecialtyLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCQuestAskSpecialtyLines))
    return CyberNPC.NPCQuestAskSpecialtyLines[line]
end

CyberNPC.NPCCancelQuestLines = {
    "Well, that’s a disappointment. I was counting on that payout.",
    "Looks like we’re back to square one; I hate wasted effort.",
    "Just my luck. You don’t pull jobs last minute without consequences.",
    "Cancelled? I’ll make a note of that for future reference.",
    "This isn’t good. A canceled job means lost connections.",
    "I expected better from those guys; now we’ll have to clean up this mess.",
    "Great. Just what I needed—another complication.",
    "That’s a real kick in the teeth. We were so close.",
    "Guess it’s time to pivot; can’t let this setback hold us down.",
    "Well, this might put a damper on our plans. Need to find a workaround.",
    "I’ll find a way to make this right, but it’s gonna take some finesse.",
    "You know what they say—nothing in this business is guaranteed.",
    "That cancellation comes with a price; I hope they’re ready to pay it.",
    "I don’t like surprises, especially bad ones. Let’s regroup.",
    "Another one bites the dust. This isn’t how I like doing business.",
    "Fantastic. Just what I wanted to deal with today—more uncertainty.",
    "This is a mess. We had everything lined up perfectly.",
    "Great. Now I’ll have to smooth over the bad vibes.",
    "Just my luck. They pulled the rug right out from under us.",
    "I need to know why this happened; it affects my reputation.",
    "Seriously? This is the kind of chaos that keeps me up at night.",
    "That’s a letdown. Still, we'll have to adapt and keep moving.",
    "Financially, this stings. Time to find a new hustle.",
    "You’ve got to be kidding me. I invest too much to let this slide.",
    "What’s done is done. We’ll have to turn this frown upside down.",
    "This cancellation doesn’t sit right with me; we’ll find a way to recover.",
    "I hope they have a good reason for this; I’ll make sure to find out.",
    "A canceled job can’t stay canceled forever; we’ll get back on track.",
    "This is unfortunate.",
    "A disappointing turn of events.",
    "This outcome is less than ideal.",
    "Regrettably, this complicates matters.",
    "I find this quite disappointing.",
    "This situation is not what I anticipated.",
    "It’s disappointing when plans fall through.",
    "I had hoped for a different outcome.",
    "This is an unexpected setback.",
    "This decision is rather unfortunate.",
    "I did not see this coming.",
    "This alters our initial expectations.",
    "Unfortunate, to say the least.",
    "This cancellation is quite disheartening.",
    "This is unfortunate; I'll need to reach out to someone else for the job.",
    "A disappointing turn of events; I'll start contacting alternatives.",
    "Given this cancellation, I will call another contact to take this on.",
    "This outcome is less than ideal; I'll find someone else to handle it.",
    "Regrettably, I’ll have to bring in another resource for this task.",
    "I find this quite disappointing; I will engage other candidates for the job.",
    "This situation is not what I anticipated; I’ll be reaching out to others.",
    "It’s disappointing when plans fall through; I'll look for another option.",
    "I had hoped for a different outcome; I will source another candidate.",
    "This is an unexpected setback; I’ll call someone else to fill the gap.",
    "This decision is rather unfortunate; I’ll move forward with a different contact.",
    "I did not see this coming; I will have to reach out to another professional.",
    "This alters our initial expectations; I will start calling for replacements.",
    "Unfortunate, to say the least; I’ll need to line up another option quickly.",
    "This is regrettable; I’ll need to enlist someone else for the task.",
    "A setback indeed; I’ll reach out to another expert shortly.",
    "This unforeseen change requires me to find a replacement.",
    "I’m disappointed; I’ll have to look for another candidate to handle this.",
    "This outcome is less than ideal; I will seek others for this role.",
    "Regrettably, I must pivot and contact alternate resources.",
    "This cancellation changes our plans; I will explore other options.",
    "It’s unfortunate; I’ll initiate contact with other professionals.",
    "I need to call in a different resource now that this is off the table.",
    "I’ll have to reach out to someone else to fill this position.",
    "Given the circumstances, I’ll look for another solution immediately.",
    "I will contact another individual to take over this job.",
    "Time to connect with alternative contacts for this project.",
    "I’ll arrange for someone else to undertake this responsibility.",
    "Well, that’s a bummer; time to find someone else for the gig.",
    "This is a letdown; I’ll call up another buddy to take over.",
    "Looks like I’ll need to hit up somebody else for this job.",
    "That's too bad; I guess I’ll have to find someone else to step in.",
    "This is disappointing; I’ll reach out to another contact.",
    "Guess I’ll need to ring someone else to handle this now.",
    "What a letdown; I’ll just bring in another person for the job.",
    "This change isn't great; I’ll just call another resource instead.",
    "Looks like I’m on the lookout for someone else to fill in.",
    "I didn’t see that coming; time to grab another option.",
    "This throws a wrench in things; I’ll check in with alternatives.",
    "It’s a shame; I’ll need to find another set of hands for this.",
    "I’ll just reach out to someone else for the job now.",
    "So much for that; guess I’ll call another contact on this.",
    "Man, that’s a disappointment; I was really looking forward to it. Time to find someone else.",
    "What a letdown; I’m not happy about this. I’ll have to call in another favor.",
    "This is disappointing, to say the least; I guess I’ll reach out to someone else.",
    "I’m kind of bummed about this; I’ll just find another person for the job.",
    "That’s a real kick in the gut; I’ll have to bring in another backup.",
    "This really puts a damper on things; I’ll call a different contact now.",
    "Wow, I was counting on that; it’s a shame. Time to look for someone else.",
    "This is frustrating; I guess I’ll need to tap someone else for this.",
    "What a drag; I was looking forward to it. I’ll reach out to another resource.",
    "I’m pretty disappointed with this turn of events; I’ll just line up someone else.",
    "This isn’t what I had in mind; I’ll just have to call in another person.",
    "What a downer; I’ll seek another option to fill the gap.",
    "This news is a letdown; guess I’ll be looking for someone else to handle it.",
    "Well, this is a kick in the gut; I guess I’ll call up someone else to take my place in disappointment.",
    "What a letdown; time to find someone else. Maybe I’ll get lucky with my second choice—what could go wrong?",
    "This blows; I was really looking forward to it. I’ll reach out to another poor soul to step in.",
    "Great, this is just what I needed—a plot twist. I’ll bring in another victim for the job.",
    "I’m bummed about this; guess I’ll find someone else to share in my misery.",
    "This is a real downer; I’ll have to call in an alternate to bear the brunt of disappointment.",
    "Wow, a canceled job? How quaint! Time to find another sucker to take over.",
    "This really takes the cake; I’ll need to drag someone else into this mess.",
    "What a drag; I’ll just have to find another unsuspecting soul for this.",
    "I didn’t see this coming! I guess I’ll just recruit someone else to endure the chaos.",
    "This is peak disappointment; I’ll call someone else and ruin their day too.",
    "A canceled job? Fantastic! I’ll just reach out to another volunteer for the agony.",
    "Well, now I’m really sad; time to rope someone else into this disappointment carnival.",
    "Great, just what I needed—a canceled job. Let me find someone else to ruin their day.",
    "Well, isn’t that just peachy? Guess I’ll call up another sucker to step into this mess.",
    "What a delightful turn of events; I’ll reach out to another poor soul to take my place in despair.",
    "This is just perfect; time to find someone else to share in the disappointment. Misery loves company!",
    "A canceled job? How charming! I'll just bring in another unfortunate soul for the ride.",
    "Fantastic! This day just keeps getting better—I’ll enlist someone else to join in the fun.",
    "Wow, a setback! Time to pull another hapless individual into my whirlwind of chaos.",
    "This is a real treat; guess I’ll find another unsuspecting pawn to take over.",
    "Who knew disappointment could be so entertaining? I’ll just call someone else for the job.",
    "Well, what fun! Let’s see who else I can drag into this fiasco.",
    "A canceled job? Classic! I’ll just recruit someone else to join the party of disappointment.",
    "This is why I can’t have nice things; time to find another face to fill the void.",
    "Great, my plans are shot. I'll just find someone else to join my little tragedy.",
}
function CyberNPC.NPCCancelQuestLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCCancelQuestLines))
    return CyberNPC.NPCCancelQuestLines[line]
end
CyberNPC.NPCSuccessQuestLines = {
    "Job’s done—consider it wiped clean.",
    "I’ve got the goods; let’s make this quick.",
    "Target neutralized. You owe me one.",
    "Mission accomplished. Your reputation is safe.",
    "That was too easy. What’s next?",
    "Package secured. Delivery in progress.",
    "Easy peasy. The streets are ours.",
    "All taken care of. Just a whisper away.",
    "Consider it handled. You can breathe easy now.",
    "The contracts are signed, and the debts are cleared.",
    "All sorted out. Let’s settle up.",
    "Mission completed—time for some R&R.",
    "The mess is cleaned up; you’re welcome.",
    "It’s as if they never existed.",
    "Consider the issue resolved. What’s the next play?",
    "No one’s looking for you now; job’s done.",
    "Clean slate, my friend. Now, what’s next?",
    "All parties satisfied. Onward and upward.",
    "Problem solved; your secret’s safe.",
    "The shadows took care of everything—perfect execution.",
    "They won’t be bothering you anymore.",
    "All done—let’s collect what’s ours.",
    "The path is clear; on to the next target.",
    "Clean job, clean getaway. You’re in the clear.",
    "Task completed—no loose ends to tie up.",
    "You’re free and clear now; enjoy the silence.",
    "All targets eliminated; your world is safer.",
    "Success achieved—now let’s enjoy the spoils.",
    "Everything’s been taken care of, just as promised.",
    "The chatter has died down—mission success.",
    "Your shadows are safe; job is complete.",
    "Mission locked down—easy as taking candy.",
    "You won’t have to look over your shoulder anymore.",
    "All threats neutralized—time to celebrate.",
    "Smooth sailing all the way; everything's handled.",
    "Your problems are history—let's move on.",
    "The scene's cleared; nothing left but dust.",
    "Consider this resolved. Who’s next on your list?",
    "Everything's settled; the night is yours.",
    "I left no witness—your secret is secure.",
    "Job done. You’re clear.",
    "The issue is resolved.",
    "All targets neutralized.",
    "Everything has been taken care of.",
    "The job is complete.",
    "You can move on now.",
    "All threats eliminated.",
    "Mission accomplished.",
    "The problem is handled.",
    "Everything is secured.",
    "Job done, V. You’re clear.",
    "The issue is resolved, V.",
    "All targets neutralized, V.",
    "Everything has been taken care of, V.",
    "The job is complete, V.",
    "You can move on now, V.",
    "All threats eliminated, V.",
    "Mission accomplished, V.",
    "The problem is handled, V.",
    "Everything is secured, V.",
    "V, the job is done.",
    "Everything is clear, V.",
    "You’re in the clear now, V.",
    "The situation is handled, V.",
    "All objectives met, V.",
    "You’re good to go, V.",
    "The threat is neutralized, V.",
    "Consider it done, V.",
    "Your slate is clean, V.",
    "The task is complete, V.",
    "V, the area is secure now.",
    "All loose ends tied up, V.",
    "You can breathe easy now, V.",
    "The mission is complete, V.",
    "There’s nothing left, V.",
    "All set for the next move, V.",
    "Everything’s taken care of, V.",
    "The job is finished, V.",
    "You’re all clear, V.",
    "The matter is resolved, V.",
    "V, the job is finished.",
    "All threats handled, V.",
    "You’re safe now, V.",
    "Everything is resolved, V.",
    "Mission completed, V.",
    "You’re clear to go, V.",
    "All actions executed, V.",
    "Task accomplished, V.",
    "You can proceed, V.",
    "The situation is under control, V.",
    "The work is done, V.",
    "All clear on my end, V.",
    "Task completed successfully, V.",
    "You’re in the clear, V.",
    "The issue has been resolved, V.",
    "No further problems, V.",
    "Everything is finalized, V.",
    "The objective is met, V.",
    "You’re good to go now, V.",
    "All operations are complete, V."
}
function CyberNPC.NPCSuccessQuestLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCSuccessQuestLines))
    return CyberNPC.NPCSuccessQuestLines[line]
end

CyberNPC.NPCQuestSendEddiesLines = {
    "I'm sending the eddies now, V.",
    "Eddies are on their way, V.",
    "You’ll have the eddies shortly, V.",
    "Transferring the eddies now, V.",
    "The payment is being sent, V.",
    "Eddies are being wired, V.",
    "You’ll receive the eddies soon, V.",
    "Just sent the eddies, V.",
    "Payment is confirmed, V.",
    "Eddies are in transit, V.",
    "Eddies are headed your way, V.",
    "I’ve transferred the eddies, V.",
    "You should see the eddies shortly, V.",
    "Just completed the eddy transfer, V.",
    "Eddies sent, V. Check your account.",
    "The eddies are on their way, V.",
    "Payment sent—eddy transfer complete, V.",
    "Eddies are in your account now, V.",
    "You’ll be seeing those eddies soon, V.",
    "I’ve put the eddies in motion, V.",
    "I'm processing the eddies now, V.",
    "Funds are being transferred as we speak, V.",
    "The eddy drop is happening, V.",
    "I’m executing the eddy transfer now, V.",
    "Your eddies are being dispatched, V.",
    "I’ve arranged the payment for you, V.",
    "Just authorized the eddy transfer, V.",
    "You can expect the eddies shortly, V.",
    "I sent the eddies, V. Check in a moment.",
    "Eddies are being allocated to your account, V.",
    "The eddies are on their way to you, V.",
    "I've confirmed the eddy transfer, V.",
    "Just dispatched the eddies, V.",
    "Eddies are being allocated now, V.",
    "The payment should arrive shortly, V.",
    "Eddies are scheduled for delivery, V.",
    "I’ve set the transaction in motion, V.",
    "The funds are on their way, V.",
    "I just released the eddies, V.",
    "You’ll receive the eddies in a moment, V.",
    "Just sent the eddies your way, V.",
    "The eddies are now being transferred, V.",
    "Eddies are being wired over, V.",
    "You’ll find the eddies in your account soon, V.",
    "I’ve put the eddies in the system, V.",
    "Eddies are now on the way, V.",
    "The funds are being sent, V.",
    "You should have the eddies shortly, V.",
    "I’ve completed the transfer of eddies, V.",
    "Eddy shipment is en route to you, V."
}
function CyberNPC.NPCQuestSendEddiesLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCQuestSendEddiesLines))
    return CyberNPC.NPCQuestSendEddiesLines[line]
end
CyberNPC.NPCQuestUnfinishedLines = {
    "Seriously, V? We were so close!",
    "You're canceling now? What a waste.",
    "I can’t believe you want to stop, V.",
    "So we just throw it all away, huh?",
    "This feels like a huge mistake, V!",
    "You’re giving up? We put in so much effort!",
    "You can't be serious, V. What now?",
    "This is frustrating, V. We can’t just abandon it.",
    "After all that, you want to cancel?",
    "Unbelievable, V. This isn’t how it should end.",
    "I can’t believe you’d give up, V! What’s the point?",
    "This is not what we agreed on, V!",
    "We invested too much to just back out now!",
    "Do you really think quitting is the solution, V?",
    "You’re throwing away our hard work, V. Why?",
    "It’s infuriating to see you cancel like this!",
    "After all that effort, we’re just going to stop?",
    "You can’t just abandon this, V! It’s not right!",
    "This is a huge disappointment, V.",
    "You can’t just walk away from this, V!",
    "This feels like a slap in the face, V!",
    "All that work, and you just want to quit?",
    "You can't just bail on this, V. It's not fair!",
    "I thought you were in this with me, V!",
    "After everything we’ve been through, you’re just done?",
    "This frustration is unreal, V. What’s going on?",
    "I can't believe you want to quit, V. This is so frustrating. But, I respect your decision.",
    "It's hard to accept this, V. We invested so much. Still, I’ll follow your lead.",
    "I thought we were in this together, V. It’s disappointing, but I’ll respect your choice.",
    "It feels like we’re giving up too soon, V. I’m upset, but I understand your stance.",
    "After all we’ve done, it’s tough to hear this, V. I’ll accept it, but it's frustrating.",
    "You can’t just walk away after all this effort, V. I’m frustrated, but I get it.",
    "It’s hard to fathom canceling now, V. I’m disappointed, but your call matters.",
    "This feels like a letdown, V. I wish it were different, but I’ll support your choice.",
    "I truly didn’t expect this decision, V. I’m irritated, but it’s your call.",
    "It’s disheartening to walk away now, V. I need a moment, but I’ll respect your choice.",
    "I’m really struggling to understand why you’d cancel, V. Still, it’s your decision.",
    "It’s disappointing to see this slip away, V. But I’ll respect what you choose.",
    "I really thought we could pull this off, V. It’s hard to let go, but I’ll follow your lead.",
    "This isn’t how I envisioned things ending, V. I’m frustrated, but I’ll accept your choice.",
    "I can’t help but feel let down, V. I’ll take a step back and respect your decision.",
    "I wish we could see this through, V. It’s tough, but I’ll stand by your choice.",
    "It feels premature to cancel, V. I’m upset, but I’ll support you nonetheless.",
    "It’s disheartening to back out now, V. I need to process this, but I respect your call.",
    "I wish we could finish what we started, V. I’m disappointed, but I'll honor your decision.",
    "It’s tough to hear, V, and I’m not pleased, but I’ll accept your decision.",
    "It's hard to accept this, V. I thought we were committed, but I’ll support your decision.",
    "Feeling let down now, V. It’s disappointing, but I will respect your choice.",
    "I didn’t see this coming, V. It hurts to back out, but I’ll stand by whatever you decide.",
    "This isn’t what I hoped for, V. It frustrates me, but your call is what matters.",
    "We worked hard for this, V. It’s a tough pill to swallow, but I’ll respect your wishes.",
    "I can’t help feeling frustrated, V. I had hoped for more, but I’ll accept your decision.",
    "It's hard to walk away now, V. I’m upset, but I’ll honor your choice and move forward.",
    "I wish it didn’t have to end like this, V. I’m disappointed, but I understand your stance.",
    "I expected better from this situation, V. It’s tough, but your word is final.",
    "This isn’t the outcome I wanted, V. I’m frustrated, but I’ll respect your decision.",
    "I really thought we could finish this, V. I’m upset, but I’ll respect your decision.",
    "It’s disheartening to hear this, V. I need to process my feelings, but I’ll support you.",
    "Very disappointing to walk away now, V. I’ll take a moment, but your choice stands.",
    "I’m feeling let down, V. It’s tough, but I’ll abide by your decision.",
    "This isn’t ideal, V. I’m frustrated, but I understand you have your reasons.",
    "It’s hard to hear you want to cancel, V. I’m upset, but I’ll honor your choice.",
    "I didn’t expect this outcome, V. It’s disappointing, yet your decision is what matters.",
    "This feels premature, V. I’m not happy, but I’ll follow your lead.",
    "I hoped we could keep going, V. I’m frustrated, but I accept your choice.",
    "It’s not what I wanted to hear, V. I’m disappointed, but I’ll support you going forward.",
    "I can't hide my frustration, V. It’s hard to accept, but I’ll respect your decision.",
    "I was hoping for a different outcome, V. I’m upset, but I’ll support your choice.",
    "This isn’t how I wanted things to go, V. I’m disappointed, but your call matters.",
    "It’s difficult to walk away now, V. I’m frustrated, but I’ll abide by your decision.",
    "I didn’t think it would end like this, V. I’m unhappy, but I’ll accept your choice.",
    "This feels like a setback, V. I’m not pleased, but I understand your reasoning.",
    "I’m surprised you want to stop, V. It’s hard to handle, but I’ll follow your direction.",
    "I wanted to see this through, V. I’m frustrated, but I’ll respect your wishes.",
    "It’s disheartening to hear this, V. I need time to think, but I’ll support your decision.",
    "I expected more from this, V. It’s tough to accept, but I’ll stand by your choice.",
    "I can't believe it’s come to this, V. I’m disappointed, but I’ll respect your choice.",
    "This is frustrating, V. I thought we were on the same page, but I’ll accept your decision.",
    "I wish we could continue, V. It’s upsetting, but I understand your reasons.",
    "I’m really struggling with this, V. It’s tough to accept, but I’ll go along with it.",
    "It’s hard to turn back now, V. I’m unhappy about it, but I’ll support your call.",
    "It's disheartening to see it end like this, V. I need to catch my breath, but I respect your decision.",
    "I thought we had more time, V. I’m frustrated, but I’ll honor your choice.",
    "I didn’t expect us to quit now, V. I’m disappointed, but your judgment is key.",
    "It’s hard to let go, V. I’m upset by this, but I’ll follow your lead.",
    "This isn’t the direction I hoped for, V. I’m frustrated, but I’ll adjust to your choice."
}
function CyberNPC.NPCQuestUnfinishedLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCQuestUnfinishedLines))
    return CyberNPC.NPCQuestUnfinishedLines[line]
end

CyberNPC.NPCQuestAskGangLines = {
    "The contract involves the gang called",
    "This job is associated with a gang known as",
    "You should know the contract involves a gang referred to as",
    "The deal is linked to a gang called",
    "This assignment comes from a gang named",
    "The contract is backed by a gang going by the name of",
    "You’re looking at a job involving a gang known as",
    "This mission pertains to a gang known as",
    "The organization behind this contract is the gang called",
    "The details indicate the gang involved is called",
    "Know that this contract ties back to a gang called",
    "This job is tied to a notorious gang known as",    
    "You might want to look out for the gang called",
    "This assignment is under the purview of a gang named",
    "The contract is targeting the gang called",
    "This job involves going after the gang known as",
    "You should know the target of this contract is the gang referred to as",
    "The deal is aimed at a gang called",
    "This assignment is focused on a gang named",
    "The contract seeks to disrupt a gang going by the name of",
    "You’re looking at a mission targeting a gang known as",
    "This operation is aimed at a gang known as",
    "The objective of this contract is the gang called",
    "The details indicate the target gang is called",
    "Know that this contract is after a gang called",
    "This job is focused on taking down a notorious gang known as",
    "The operation is set to confront a gang infamous for their",
    "You might want to prepare for the gang called",
    "This assignment involves going up against a gang named",
    "The contract is set to eliminate the gang known as",
    "This job is geared toward neutralizing the gang identified as",
    "You're tasked with taking down the gang referred to as",
    "The mission aims to dismantle the operations of the gang called",
    "We’re looking to strike at the heart of the gang known as",
    "This assignment is all about confronting the gang known as",
    "The contract intends to disrupt the activities of the gang named",
    "The objective is to target the gang infamous for their actions known as",
    "This operation seeks to bring down the gang recognized as",
    "The plan involves taking on the gang that goes by the name of",
    "The job aims to confront the gang notorious for their reputation called",
    "Your objective is to infiltrate the ranks of the gang known as",
    "This contract is focused on the gang that operates under the name of",
    "We have our sights set on a gang that calls themselves",
    "The mission is designed to take out the gang that has been causing trouble called",
    "The target here is a gang infamous for their dealings known as",
    "The operation is designed to take aim at the gang known as",
    "The contract involves pursuing the gang that operates under the name of",
    "Your task is to engage with the gang recognized as",
    "This mission revolves around confronting the gang identified as",
    "The objective is to track down the gang infamous for their activities known as",
    "This job requires you to tackle the gang that's referred to as",
    "The plan is to root out the gang operating under the title of",
    "You’ll be going after the gang that calls themselves",
    "The assignment involves uncovering the dealings of the gang known as",
    "This contract intends to challenge the gang notorious for their influence called",
    "Your focus will be on dismantling the gang recognized as",
    "The goal is to neutralize the threat posed by the gang named",
    "This operation directly targets the gang engaging in activities known as",
    "The mission is aimed at disrupting the gang that stands out as",
    "We’re set to bring down the gang infamous for their reputation called",
    "The contract puts a spotlight on the gang that’s known as",
    "The contract is aimed at dismantling the gang operating under the name",
    "This job revolves around targeting the gang heard of as",
    "Your assignment focuses on the gang that’s notorious for their approach known as",
    "The mission seeks to eliminate the presence of the gang identified as",
    "We’re poised to confront the gang that’s infamous for their tactics called",
    "This operation calls for action against the gang known as",
    "The goal is to disrupt the influence of the gang referred to as",
    "You’ll be tasked with engaging the gang famous for their activities called",
    "The contract highlights the need to address the gang that’s called",
    "This assignment is directed toward the gang known to cause trouble called",
    "Expect to face off against the gang identified for their reputation as",
    "The focus of this mission is on the gang that famously operates as",
    "This operation intends to corner the gang recognized for their methods known as",
    "Your target is the gang notorious for their operations, known as",
    "This contract is about confronting the gang that has made a name for themselves called",
    "Prepare to deal with the gang infamous for their actions known as",
    "The contract specifically targets the gang that goes by the name",
    "This job is set to challenge the gang infamous for their dealings known as",
    "Your mission involves taking direct action against the gang called",
    "We are positioned to strike at the gang known as",
    "This operation is geared toward neutralizing the gang that operates under the banner of",
    "The goal here is to confront the gang notorious for their presence called",
    "You're looking to dismantle the threat posed by the gang referred to as",
    "This assignment requires engaging with the gang that styles themselves as",
    "The focus is on dismantling the operations of the gang known as",
    "This contract aims to disrupt the activities of the gang referred to as",
    "Expect to take on the gang that has garnered a reputation as",
    "This mission emphasizes targeting the gang that’s notorious for their behavior known as",
    "We’re looking to uncover the operations of the gang labeled as",
    "Prepare to confront the gang infamous for their impact called",
    "The contract aims to eliminate the gang that often stirs trouble known as",
    "This job involves bringing down the gang known widely as"
}
function CyberNPC.NPCQuestAskGangLinesRandomLine(suffix)
    local line = math.random(#(CyberNPC.NPCQuestAskGangLines))
    return CyberNPC.NPCQuestAskGangLines[line] .. " " .. suffix
end

CyberNPC.NPCQuestLocationLines = {
    "The job will take you to",
    "This assignment is set in",
    "You’ll be operating out of",
    "The task is based in",
    "This mission will have you in",
    "Your work will lead you to",
    "You’ll be executing this job at",
    "The operation is situated in",
    "Prepare to navigate through",
    "This contract requires you to be in",
    "Your target area for this task is",
    "This job will see you in",
    "Expect to conduct your work from",
    "The focus of the task is in",
    "The assignment will unfold in",
    "Your activities will center around",
    "The operation is set to unfold in",
    "You’ll find yourself working within",
    "The task will bring you to",
    "This job is primarily located in",
    "Your mission will take place at",
    "You’ll need to focus your efforts on",
    "This assignment involves activity around",
    "The job connects to operations in",
    "Prepare for action in",
    "You’ll be positioned in",
    "This task will guide you to",
    "The work will revolve around",
    "Your focus will be directed towards",
    "The contract places you in",
    "This job is routed through",
    "The action centers in",
    "You'll be dispatched to",
    "The assignment takes you to",
    "This task is set against the backdrop of",
    "Prepare to operate in",
    "Your next move will be in",
    "The mission places you within",
    "You'll execute your duties at",
    "This job necessitates your presence in",
    "Your efforts will be concentrated around",
    "Expect to conduct operations from",
    "This contract directs you towards",
    "Your activities will span across",
    "The task will require you to be in proximity to",
    "You’ll need to navigate through",
    "This job will place you amidst",
    "Your engagement will be focused on",
    "The operation will unfold at",
    "You are tasked with working in",
    "This assignment leads you to",
    "Expect to find yourself in",
    "Your focus area will be",
    "This task involves activity near",
    "Your mission's destination is",
    "You’ll need to engage with the area around",
    "The job will send you to",
    "Prepare to be stationed in",
    "You’ll be heading towards",
    "This contract takes you to the vicinity of",
    "Your region of interest for this task is",
    "You will conduct your work in the vicinity of",
    "Your efforts will be directed to",
    "This job places you in the heart of",
    "This job will require you to navigate to",
    "Your assignments will take you through",
    "You’ll be operating out of the area surrounding",
    "This task is focused on the region of",
    "Prepare to be involved in activities at",
    "The contract will take you to the location of",
    "Expect to work within the confines of",
    "You’ll be assigned to the locale of",
    "This mission sends you to the territory of",
    "Your path will lead you to",
    "This operation places you in the region of",
    "Your work will revolve around the site of",
    "You’ll be conducting operations within",
    "This job has you working in the zone of",
    "The focus of the task is directed toward",
    "Your mission will bring you deep into",
    "You'll be heading into the area known as",
    "This task will immerse you in the surroundings of",
    "Expect to operate out of the district of",
    "Your work will unfold at the site of",
    "The job requires presence in the region of",
    "You'll set your sights on the area surrounding",
    "Your mission will place you within the boundaries of",
    "Prepare to engage with the locals in",
    "This operation takes shape in the outskirts of",
    "Your focus will be directed to the neighborhood of",
    "The assignment is located in the precinct of",
    "This mission leads you to the corner of",
    "You’ll be working around the vicinity of",
    "This job sends you into the thick of",
    "Expect to make contact in the area surrounding",
    "Your efforts will be concentrated in the vicinity of",
    "This assignment leads you to the heart of",
    "Your operations will be situated in",
    "You’ll be working closely with the environment of",
    "The job will have you immersed in the culture of",
    "This mission takes you through the landscape of",
    "Expect to be engaged in affairs at",
    "Your task will draw you into the community of",
    "Prepare to traverse the area known as",
    "You’ll navigate the complexities of",
    "This contract requires your presence in the territory of",
    "You’ll be operating within the limits of",
    "The job involves an in-depth exploration of",
    "Your work will take you through the streets of",
    "This operation will have you in the labyrinth of",
    "Expect to find yourself involved in the dynamics of",
    "You'll be placed directly within the environment of",
    "This assignment will place you deep within",
    "Your task revolves around the core of",
    "You'll be delving into the intricacies of",
    "This job brings you face-to-face with the people of",
    "Prepare to explore the surroundings of",
    "You’ll be engaged in the activities of",
    "The operation is set to unfold in the region of",
    "Your work will focus on the aspects of",
    "This mission will guide you to the path through",
    "You'll navigate the territory encompassing",
    "This assignment involves thorough exploration of",
    "Expect to be active in the zones of",
    "Your efforts will be centered in the domain of",
    "This job leads you to the backdrop of",
    "You’ll find your role situated within",
    "The operation sends you into the mix of",
    "Your assignment will take you to the edge of",
    "This job requires you to be in the thick of",
    "You’ll be working amid the chaos of",
    "This mission involves immersing yourself in the culture of",
    "Prepare to be at the forefront of activity in",
    "You’ll find yourself engaging with the community in",
    "Expect to conduct your operations within the perimeter of",
    "The task places you in the heart of",
    "You’ll be tasked with analyzing the dynamics in",
    "This job unfolds against the backdrop of",
    "Your work will take you to the crossroads of",
    "This assignment guides you into the hub of",
    "Expect to navigate through the alleys of",
    "Your efforts will concentrate on the infrastructure of",
    "This mission calls for your presence in the realm of",
    "You’ll be exploring the intricate layers of"
}
function CyberNPC.NPCQuestLocationLinesRandomLine(suffix)
    local line = math.random(#(CyberNPC.NPCQuestLocationLines))
    return CyberNPC.NPCQuestLocationLines[line] .. " " .. suffix
end

CyberNPC.NPCQuestNoContractLines = {
    "Contract? Not yet; I’m still waiting for the ink to dry on my last idea.",
    "Ah, a contract. Currently non-existent, much like my motivation.",
    "You’re asking about a contract? That would be as real as my last biochip upgrade.",
    "Contract? Not in this lifetime; I’m still hoping for a decent meal.",
    "No contract yet—still collecting dust and bad decisions.",
    "The only contract I have is with procrastination, and it’s going splendidly.",
    "Contract? Let’s just say it’s on par with my chances of getting a job at Arasaka.",
    "I wish I had a contract to share, but it seems they’re out of stock.",
    "Currently, the only thing I’m negotiating is my next coffee break.",
    "No contract as of now; I’m still hoping someone will drop one from the sky.",
    "A contract? Right. I’ll add it to my list of things that don’t exist.",
    "No contract yet; just a lot of empty promises and broken dreams.",
    "It appears that the contract is on backorder, possibly forever.",
    "I can check again later, but right now, it’s as real as my last vacation.",
    "No contract in sight—just me and my hopes of finding a decent paycheck.",
    "A contract? Nope, just me chasing shadows and bad signals.",
    "No contract yet; still waiting on a miracle or a decent lead.",
    "Ah, the elusive contract. Still playing hide and seek, I see.",
    "Currently, the only thing contracted is my caffeine addiction.",
    "No contract here—just me and my dreams of corporate sponsorship.",
    "The contract is still in the pre-production phase, along with my ambition.",
    "They’re still working on that contract, right after they finish watching paint dry.",
    "Contract? You mean that thing that doesn’t exist? Right on.",
    "I could talk contracts, but I’d rather discuss my favorite fantasy: getting paid.",
    "No contract at the moment; just my weekly reminder that life is a grind.",
    "The contract is taking longer to materialize than my last trip to the Netrunner's hub.",
    "No contracts in sight; just a blank slate and a dash of cynicism.",
    "Might as well say the contract doesn’t exist. I’d have better luck finding a unicorn.",    
    "No contract? Shocking. I’ll add it to my list of disappointments.",
    "A contract? Not yet. Just me, my empty pockets, and wishful thinking.",
    "Ah, no contract. Just the soundtrack of crickets and my fading hopes.",
    "Currently, the contract is still in the realm of ‘maybe someday’.",
    "No contract in sight—just the usual chaos and a side of existential dread.",
    "You could say the contract is a work in progress, which is code for 'not happening.'",
    "Not yet, but I’m sure someone is diligently ignoring it somewhere.",
    "A contract? That would require planning, and we all know how that goes.",
    "No contract here—just me hoping for a miracle like a decent chip upgrade.",
    "Looks like the contract decided to take a vacation. Lucky it.",
    "No contract, just a classic case of waiting for something that never arrives.",
    "The only contract I have is a silent agreement with reality to keep disappointing me.",
    "Ah, contracts. They’re like good intentions—hard to find and easily lost.",
    "No contract yet; I’m still refining my skills in denial.",
    "Currently, my contract is as imaginary as my social life.",
    "You know, if contracts were like coffee, I’d be overdosing by now, but alas.",
    "A contract? Not yet; just a series of unfortunate events unfolding.",
    "No contract at this point—just me familiarizing myself with disappointment.",
    "It’s still a ‘no contract’ zone around here, much like my bank account.",
    "Contract? The only thing I’m signing is my name on another unpaid bill.",
    "Still waiting for that contract to magically appear—maybe with a side of luck.",
    "The contract is about as real as my weekends—always just out of reach.",
    "A contract? You might have better luck finding a needle in a Corpo stack.",
    "No contract; just the usual buzz of the city's dreams being swallowed whole.",
    "The only thing contracted around here is my fate to remain caffeine-dependent.",
    "It's a no-contract kind of day—just me and my existential crisis.",
    "Currently, the only business I’m in is the fine art of doing nothing.",
    "Contract? Ah, I think that’s still in R&D right next to my motivation.",
    "I’d say the contract is in transit somewhere between dreams and reality.",
    "No contract, just me taking a casual stroll through the wasteland of missed opportunities.",
    "If I had a credit for every time someone asked me about a contract, I might actually have a job.",
    "A contract? Unfortunately, I’m still awaiting the paperwork.",
    "Currently, there is no contract; it seems we’re experiencing a delay.",
    "Ah, the contract is still unconfirmed. I’ll keep you posted on its status.",
    "As of now, no contract exists; just the anticipation of future developments.",
    "No contract yet; it appears to be caught in the bureaucratic maze.",
    "The contract is still in the approval stage—perhaps indefinitely.",
    "Regrettably, there’s no contract to discuss at this moment.",
    "Currently, the contract remains nonexistent, much like a reliable network signal.",
    "I’m afraid the contract is still pending approval from the higher-ups.",
    "No contract has been finalized; we’re still in the early stages.",
    "The contract is still in limbo, awaiting someone to sign it into existence.",
    "At this point, there is no contract; just a theoretical discussion.",
    "The situation is such that we have yet to establish a formal contract.",
    "Unfortunately, I'm still waiting for the contract to materialize.",
    "As it stands, there’s no contract; just potential on the horizon.",
    "A contract? Currently a figment of our imagination.",
    "Regrettably, there’s no contract yet; just a lot of hopeful ideas.",
    "As of now, the contract remains elusive, much like a well-placed data packet.",
    "No contract in sight; it seems to be stuck in the pipeline.",
    "Unfortunately, we’re still waiting for that contract to materialize.",
    "The contract is still pending—clearly, it prefers to remain a concept.",
    "I’m afraid we have no contract yet; it appears to be on an extended vacation.",
    "Currently, the contract is as real as a corporate promise.",
    "The status of the contract remains... uncharted territory.",
    "It's safe to say that there’s no contract to discuss at this time.",
    "Sadly, the contract seems to be stuck in a bureaucratic black hole.",
    "No contract presently; we're still in the speculative phase.",
    "We’re still optimistic for a contract; however, it continues to elude us.",
    "The contract, it appears, has chosen to remain in the realm of 'maybe.'",
    "At this juncture, we have nothing concrete regarding a contract.",
    "Currently, there is no contract in place.",
    "As of now, we are without a finalized contract.",
    "Unfortunately, the contract has not yet been established.",
    "At this time, there is no contract to discuss.",
    "The contract remains unconfirmed at this moment.",
    "Regrettably, we do not have a contract in our records.",
    "As it stands, the contract is still pending approval.",
    "We do not have an active contract at this time.",
    "Currently, there has been no agreement finalized.",
    "There is no contract to report on as of now.",
    "Unfortunately, the contract is still in deliberation.",
    "At present, we have not established a formal contract.",
    "We are currently without a signed contract.",
    "The contract is still in the early phases and not yet available.",
    "As of now, the contract is not yet in existence.",
    "The status of the contract remains under review.",
    "At this moment, there is no contract in effect.",
    "We have not yet secured a contract.",
    "As it currently stands, the contract has not been initiated.",
    "There has been no progress toward finalizing a contract at this time.",
    "Currently, the contract remains unsigned and unconfirmed.",
    "We do not possess an existing contract at this point.",
    "At this time, the contract is not established.",
    "The situation does not include a contract as it stands.",
    "Unfortunately, we are still awaiting a formalized contract.",
    "The contract is not currently available for discussion.",
    "Regrettably, we have no contract to reference at this time.",
    "The contract remains in the preliminary stages.",
    "There is currently no actionable contract to review.",
    "As of now, we are working without a formal agreement.",
    "At present, the contract has not materialized.",
    "The matter regarding the contract is still unresolved.",
    "As of now, we do not have a contract finalized.",
    "Currently, the contract remains absent from our records.",
    "There is no official contract in place at this time.",
    "We are still in the process of negotiating the contract.",
    "The contract is not currently on the table for discussion.",
    "Unfortunately, the contract has yet to be established.",
    "At this stage, we are without a binding contract.",
    "Regrettably, there has been no advancement toward a contract.",
    "The situation currently lacks a formal agreement.",
    "As things stand, the contract is not yet signed.",
    "We have yet to finalize the contract details.",
    "At this moment, no contract exists in our records.",
    "The current status indicates we have no contract in place.",
    "The contract is still in discussions and has not progressed.",
    "As of now, we are operating without a formalized contract.",
    "Unfortunately, there is no contract to address at this time.",
    "At this time, there is no active contract to speak of.",
    "Currently, we lack a signed contract.",
    "There is no finalized contract in our records at this moment.",
    "As it stands, the contract is still pending.",
    "Unfortunately, we have not yet reached an agreement.",
    "The contract remains in a state of negotiation.",
    "We are currently without any formal contract.",
    "The status indicates that no contract is in place.",
    "As of now, we have no details on a potential contract.",
    "The contract is not finalized and remains undetermined.",
    "Currently, we have no documentation regarding a contract.",
    "Unfortunately, there are no active agreements on file.",
    "The situation lacks a formal contract orientation.",
    "As it currently stands, the contract has not been executed.",
    "We are still awaiting confirmation on the contract.",
    "No contract is present in our operational framework."
}
function CyberNPC.NPCQuestNoContractLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCQuestNoContractLines))
    return CyberNPC.NPCQuestNoContractLines[line]
end

CyberNPC.NPCQuestGreetingLines = {
    "Hey V, welcome back to the grind.",
    "There you are, V. I was starting to think you got lost.",
    "V! Good to see you. Ready to dive into the chaos again?",
    "Ah, V! Just the person I wanted to see. What’s new?",
    "You made it, V. Let’s see what kind of trouble we can stir up.",
    "Welcome, V. I've got a feeling today is going to be interesting.",
    "Glad you could drop by, V. I’ve got some potential work for you.",
    "V, my favorite merc. What brings you to my neck of the woods?",
    "Hey there, V. You look like you could use a new lead.",
    "V! Just in time. I might have a job that’s perfect for you.",
    "V! It’s always a pleasure to see you around here.",
    "Ah, V, you made it! Ready to make some waves?",
    "Welcome back, V. I hope you’re prepared for what’s next.",
    "Good to see you, V! Got your game face on today?",
    "Hey, V. I’ve been looking forward to this chat.",
    "There you are, V. I’ve got something that might pique your interest.",
    "V, just in time! Let’s see how we can shake things up today.",
    "Hey, V! How’s the street treating you these days?",
    "V! Glad you’re here. Let’s talk business.",
    "Welcome, V. I think we might just be able to help each other out.",
    "V! Quick, I need to talk—time’s tight.",
    "Hey, V! No time to waste, let’s get to it.",
    "V! Good to see you. We’ve got urgent stuff to cover!",
    "You’re here! Great, we need to move fast.",
    "Hurry up, V! I don’t have all day.",
    "Listen up, V—time’s not on our side.",
    "V, there you are! We’ve got a lot to discuss, quickly.",
    "We don’t have time, V. What’s your plan?",
    "V! Glad you showed up. We need to act fast.",
    "Hey, V, let’s cut to the chase—things are heating up!",
    "Aren't you supposed to be busy? Well, let's chat while you can.",
    "You’ve got a job going, right? Still, I’ve got a moment—what’s on your mind?",
    "Shouldn’t you be working? But hey, let’s make this quick.",
    "I know you’re in a rush, but I can squeeze in a quick conversation.",
    "Aren't you in the middle of something? We can talk, just make it quick.",
    "I get that you're busy, but I'm all ears for a moment.",
    "You’re supposed to be working, but I’m good to chat if you are.",
    "I know you’ve got a job, but what do you need before you head out?",
    "Aren't you on a mission? We can still chat for a bit.",
    "I see you’re in the thick of it—let’s discuss while you’re here.",
    "You look like you need a favor. What’s the score?",
    "I’ve got jobs and info. Which do you want?",
    "This city’s tough. What’s your angle?",
    "Aren’t you a bit green for these streets?",
    "What brings you to my corner of Night City?",
    "Everyone’s a storyteller here. What’s yours?",
    "You seeking trouble or just passing through?",
    "This life chews you up; want some tips?",
    "I can help, but what’s in it for me?",
    "Heard any good rumors lately?",
    "Trust is a luxury; do we have that here?",
    "You want a way out or a way up?",
    "In Night City, dreams and danger dance. You ready?",
    "Looking for something? Or just someone?",
    "Got a target in mind? I can assist.",
    "Time is money. What’s your next move?",
    "You’ve got questions about the job? Let’s hear it.",
    "Depends on what you want to know. Ask away.",
    "Curious about the details? I might be able to fill you in.",
    "If it’s about the job, I can drop some hints.",
    "What’s got you interested? Let’s dig deeper.",
    "Every job’s a puzzle. What piece do you need?",
    "I can give you the lowdown, but you might not like all of it.",
    "The job’s got layers. What part are you eyeing?",
    "I don’t know what you’re fishing for, but let’s talk.",
    "I can't spill all the beans without knowing the flavor you're after.",
    "What do you want to know? Just remember, curiosity has a price.",
    "Inquire away, but tread carefully; the truth can bite.",
    "It’s a risky gig. What do you want to weigh?",
    "Every job has its shadows. What are you looking to uncover?",
    "You looking for details or just trying to size me up?",
    "No secrets here, but no guarantees either. What’s your angle?",
    "What part of the job caught your interest?",
    "You sniffing around for the full story?",
    "Got a burning question? Let’s hear it, then.",
    "You want specifics or just the gist?",
    "Is it the payout you're after, or the thrill?",
    "Curiosity could lead to danger, but I’m listening.",
    "Are you ready for the risks involved, or just curious?",
    "It’s a tangled web. What thread do you want to pull?",
    "You think you can handle the truth? Go on, ask.",
    "Every job has its complications. What do you want to unpack?",
    "No one walks away unscathed. What’s your concern?",
    "You want a taste of the action? What’s your angle?",
    "What do you need to know before diving in?",
    "I can sketch the outlines, but the details are yours to unravel.",
    "Ready to get your hands dirty? What do you need to know?",
    "Some jobs are darker than others. What light are you seeking?",
    "What’s your interest level? Let’s be clear.",
    "This job could get messy. Are you ready?",
    "I can share what I know, if you’re up for it.",
    "What's grinding your gears? Speak up.",
    "Are you in this for the thrill or the coin?",
    "You know the risks; what’s your angle?",
    "Each job has its price. What do you want to invest?",
    "In the shadows, everyone’s got a motive. What’s yours?",
    "There’s always more beneath the surface. What’s your curiosity?",
    "Before we dive in, what’s your stake in this?",
    "Wary? You should be. What do you want to dig into?",
    "Many secrets, few answers. What’s got you hooked?",
    "What’s driving your curiosity? Spill it.",
    "Ready to navigate the chaos? What do you need first?",
    "You ask the questions, I’ll provide the answers—if it’s worth it.",
    "What do you need to know about the job?",
    "What’s your main question about the assignment?",
    "Are you looking for details or just a summary?",
    "What part of the job interests you?",
    "Do you want the risks laid out clearly?",
    "What specific information are you curious about?",
    "Are you ready to dive into the details?",
    "What do you need from me before deciding?",
    "What’s making you hesitate about this job?",
    "What are you hoping to gain from this discussion?",
    "Do you want to discuss the payout or the task?",
    "What’s your priority—safety or profit?",
    "What do you want to know before proceeding?",
    "Is there a particular aspect you’re concerned about?",
    "What’s your main focus regarding this job?",
    "What details can I provide to help you decide?",
    "What details do you need about the job?",
    "Are you after any specific information?",
    "What’s your biggest concern about this task?",
    "Do you want to know about the risks involved?",
    "What kind of intel are you looking for?",
    "Do you need a rundown of the requirements?",
    "What’s your main question regarding the job itself?",
    "Are you interested in the timeline or the payout?",
    "What do you want clarified before you act?",
    "Is there anything you find unclear about the job?",
    "What do you want to know to make a decision?",
    "Are you focusing on the details or the outcome?",
    "What’s your priority before we proceed?",
    "What information will help you move forward?",
    "Do you need any reassurance about the risks?",
    "What part of this job do you want to discuss?",
    "What’s the first question on your mind?",
    "What clarification do you need about the task?",
    "Do you want to know about the team involved?",
    "What specifics are you looking for regarding the job?",
    "Are you concerned about time or safety?",
    "What part do you want me to explain?",
    "Do you need background info on the target?",
    "What details make you hesitant?",
    "Are you clear on the expectations for this job?",
    "What kind of support do you anticipate needing?",
    "What’s your focus—execution or strategy?",
    "What do you think could go wrong here?",
    "What insights do you need to feel secure?",
    "Are you ready to take on the challenge, or do you have doubts?",
    "What’s your main goal with this job?",
    "Do you want to discuss potential outcomes?"

}
function CyberNPC.NPCQuestGreetingLinesRandomLine()
    local line = math.random(#(CyberNPC.NPCQuestGreetingLines))
    return CyberNPC.NPCQuestGreetingLines[line]
end

CyberNPC.NPCShortAcknowledge = {
    'Ok',
    'Sure',
    'Yes',
    'Got it',
    'Fine',
    'You got it',
    'Preem',
    'On my way',
    'Allright',
    'Confirmed',
    'Over',
    'Yeah',
    'On it',
    'Moving out',
    'Moving',
    'Just because its you',
    'Indeed',
    'Yeah, choom!',
    'Sure, choom!',
    'You got it, choom!',
    'Again? Ok',
    'Yes, choom',
}

function CyberNPC.NPCShortAcknowledgeRandomLine()
    local line = math.random(#(CyberNPC.NPCShortAcknowledge))
    return CyberNPC.NPCShortAcknowledge[line]
end

CyberNPC.NPCMeetCall = {
    'Hey V! Where are you? I\'m at',
    'V! I\'m at',
    'Look who\'s calling! I\'m in the middle of something. Be at',
    'Look who\'s calling! I\'m in the middle of something. Meet me at',
    'Sorry V. Can\'t talk. Meet me at',
    'Sorry V. I\'m busy. Meet me at',
    'Meet me at',
    'Can\'t talk right now. I\'m at',
    'Hey V! Come to ',
    'What\'s up choom? Wanna meet? I\'m at',
    'What\'s up V? I\'m at',
    'Hey! I\'m a bit busy. Sending you my cords if you want to meet.',
    'Hey choomba! I\'m a little busy right now. Come to',
    'V! How are you? I\'m here in',
    'Hey V! If you wanna hook up, get your ass to',
    'Hey V! Nice that you call. I\'m in',
    'I was thinking about you, V! Just one thing. I\'m in the middle of something. Come to',
    'My favorite drinking buddy! Come to',
    'I used to be a merc like you, but then I got a bullet in the knee! Come to',
    'Be astat in',
    'No time to talk. Come to',
    'Can\'t talk. Come to',
    'Yo V, location locked. Swing by',
    'Urgent ping, V. Coordinates set at',
    'Netrunner alert! Trace me to',
    'Choom, got a hot lead. Rendezvous at',
    'Corpo intel incoming. Meetup at',
    'Quick job, V. Hit me up at',
    'Cyberware upgrade complete. Find me at',
    'Ripper\'s done. Waiting at',
    'Scored some rare tech. Come to',
    'Shit just got real. Get to',
    'Danger zone activated. Converge at',
    'Netspace is hot. Sync at',
    'Major score brewing. Assemble at',
    'Incoming threat. Rally point',
    'Backup needed. Coordinates',
    'Mission critical. Locate at',
    'Data breach imminent. Intercept at',
    'Deck\'s hot. Rendezvous',
    'Shadowrun opportunity. Converge',
    'Corpo leak confirmed. Meet at',
    'Tactical regroup. Location',
    'Emergency protocol. Coordinates',
    'Stealth mode engaged. Ping',
    'High-risk contract. Assemble',
    'Cryptic message: Incoming at'
}

function CyberNPC.NPCMeetCallRandomLine(locationName, districtName)
    local line = math.random(#(CyberNPC.NPCMeetCall))
    return CyberNPC.NPCMeetCall[line] .. " in " .. locationName .. "," .. districtName .. ". Gotta go. Bye"
end

CyberNPC.NPCMaleNames = {
    "Raymond",
    "Dennis",
    "Tyler",
    "Aaron",
    "Jerry",
    "Jose",
    "Nathan",
    "Adam",
    "Henry",
    "Zachary",
    "Douglas",
    "Peter",
    "Noah",
    "Kyle",
    "Ethan",
    "Christian",
    "Jeremy",
    "Keith",
    "Austin",
    "Sean",
    "Roger",
    "Terry",
    "Walter",
    "Dylan",
    "Gerald",
    "Carl",
    "Jordan",
    "Bryan",
    "Gabriel",
    "Jesse",
    "Harold",
    "Lawrence",
    "Logan",
    "Arthur",
    "Bruce",
    "Billy",
    "Elijah",
    "Joe",
    "Alan",
    "Juan",
    "Liam",
    "Willie",
    "Mason",
    "Albert",
    "Randy",
    "Wayne",
    "Vincent",
    "Lucas",
    "Caleb",
    "Luke",
    "Bobby",
    "Isaac",
    "Bradley",
}
function CyberNPC.NPCRandomMaleName()
    local v = math.random(#(CyberNPC.NPCMaleNames))
    return CyberNPC.NPCMaleNames[v]
end

CyberNPC.NPCFemaleNames = {
    "Janet",
    "Heather",
    "Diane",
    "Catherine",
    "Julie",
    "Victoria",
    "Helen",
    "Joyce",
    "Lauren",
    "Kelly",
    "Christina",
    "Joan",
    "Judith",
    "Ruth",
    "Hannah",
    "Evelyn",
    "Andrea",
    "Virginia",
    "Megan",
    "Cheryl",
    "Jacqueline",
    "Madison",
    "Sophia",
    "Abigail",
    "Teresa",
    "Isabella",
    "Sara",
    "Janice",
    "Martha",
    "Gloria",
    "Kathryn",
    "Ann",
    "Charlotte",
    -- "Judy",
    "Amber",
    "Julia",
    "Grace",
    "Denise",
    "Danielle",
    "Natalie",
    "Alice",
    "Marilyn",
    "Diana",
    "Beverly",
    "Jean",
    "Brittany",
    "Theresa",
    "Frances",
    "Kayla",
    "Alexis",
    "Tiffany",
    "Lori",
    "Kathy",
}
function CyberNPC.NPCRandomFemaleName()
    local v = math.random(#(CyberNPC.NPCFemaleNames))
    return CyberNPC.NPCFemaleNames[v]
end


CyberNPC.NPCMaleNicknames = {
    "Flint",
    "Jet",
    "Nova",
    "Talon",
    "Shadow",
    "Fenix",
    "Cipher",
    "Raze",
    "Knight",
    "Stryke",
    "Voss",
    "Kade",
    "Draven",
    "Rourke",
    "Nyx",
    "Striker",
    "Crowe",
    "Jax",
    "Blaze",
    "Vex",
    "Zephyr",
    "Rogue",
    "Reaper",
    "Hunter",
    "Quill",
    "Rex",
    "Thorne",
    "Nexus",
    "Drake",
    "Sable",
    "Razor",
    "Glitch",
    "Neon",
    "Circuit",
    "Pulse",
    "Oxide",
    "Spike",
    "Static",
    "Chrome",
    "Flux",
    "Byte",
    "Wraith",
    "Surge",
    "Phantom",
    "Codec",
    "Axel",
    "Breach",
    "Cypher",
    "Datum",
    "Echo",
    "Frag",
    "Ghost",
    "Hex",
    "Impulse",
    "Jolt",
    "Kernel",
    "Logic",
    "Mesh",
    "Nexus",
    "Orbit",
    "Pixel",
    "Quantum",
    "Rift",
    "Synapse",
    "Trace",
    "Vector",
    "Wire",
    "Xenon",
    "Yield",
    "Zero",
    "Analog",
    "Blaze",
    "Cascade",
    "Derail",
    "Enigma",
    "Fracture",
    "Giga",
    "Havoc",
    "Interrupt",
    "Jacker",
    "Kinetic",
    "Lumen",
    "Megabit",
    "Neutron",
    "Overload",
    "Protocol",
    "Quark",
    "Reactor",
    "Strobe",
    "Turbo",
    "Uplink",
    "Voltage",
    "Warp",
    "Xenith",
    "Zeta",
    "Cipher",
    "Drift",
    "Embed",
    "Flare",
    "Grid",
    "Hacker",
    "Invert",
    "Jolt",
    "Kode",
    "Leak",
    "Modem",
    "Nuke",
    "Omega",
    "Proxy",
    "Quantum",
    "Reboot",
    "Splice",
    "Trigger",
    "Upload",
    "Void",
    "Wipe",
    "Xray",
    "Yield",
    "Zone",
    "Apex",
    "Bolt",
    "Crackle",
    "Drone",
    "Ether",
    "Flicker",
    "Glare",
    "Holo",
    "Ignite",
    "Junk",
    "Kinra",
    "Latch",
    "Mecha",
    "Nerve",
    "Optic",
    "Pulse",
    "Quantum",
    "Rez",
    "Spark",
    "Tether",
    "Urge",
    "Volt",
    "Whisper",
    "Xenon",
    "Zip",
    "Arc",
    "Blip",
    "Core",
    "Drift",
    "Edge",
    "Flux",
    "Glitch",
    "Hack",
    "Impulse",
    "Jam",
    "Kick",
    "Loop",
    "Mute",
    "Noise",
    "Orbit",
    "Ping",
    "Quick",
    "Rift",
    "Static",
    "Trim",
    "Urgent",
    "Vector",
    "Wire",
    "Xfer",
    "Zap",
}
function CyberNPC.NPCRandomMaleNickname()
    local v = math.random(#(CyberNPC.NPCMaleNicknames))
    return CyberNPC.NPCMaleNicknames[v]
end
CyberNPC.NPCFemaleNicknames = {
    "Seraph",
    "Moon",
    "Wren",
    "Lune",
    "Thorne",
    "Vale",
    "Echo",
    "Skye",
    "Ember",
    "Lyric",
    "Amber",
    "Blade",
    "Crystal",
    "Deacon",
    "Eclipse",
    "Fuse",
    "Gamma",
    "Horizon",
    "Iris",
    "Jade",
    "Karma",
    "Luna",
    "Mirage",
    "Nova",
    "Onyx",
    "Prism",
    "Quill",
    "Raven",
    "Siren",
    "Terra",
    "Umbra",
    "Vortex",
    "Wavelength",
    "Xenith",
    "Yield",
    "Apex",
    "Blink",
    "Cascade",
    "Delta",
    "Ember",
    "Fusion",
    "Gravity",
    "Helix",
    "Insight",
    "Juno",
    "Kinesis",
    "Lithium",
    "Meridian",
    "Neutron",
    "Oracle",
    "Plasma",
    "Quantum",
    "Rift",
    "Surge",
    "Titan",
    "Unity",
    "Vertex",
    "Wasp",
    "Xcode",
    "Zenith",
    "Alloy",
    "Banshee",
    "Cortex",
    "Dagger",
    "Enigma",
    "Fractal",
    "Gemini",
    "Harmony",
    "Infinity",
    "Joule",
    "Kinara",
    "Lyric",
    "Magma",
    "Nebula",
    "Omega",
    "Phantom",
    "Quantum",
    "Radiance",
    "Synapse",
    "Tempest",
    "Umbral",
    "Valence",
    "Whiskey",
    "Xenara",
    "Zion",
    "Apex",
    "Blaze",
    "Cipher",
    "Drone",
    "Echo",
    "Flux",
    "Gravity",
    "Halo",
    "Impulse",
    "Jasper",
    "Kinetic",
    "Lithium",
    "Motive",
    "Nimbus",
    "Orbit",
    "Pulse",
    "Quasar",
    "Reactor",
    "Spectrum",
    "Trance",
    "Uplink",
    "Vortex",
    "Wavelength",
    "Xena",
    "Zeta",
    "Astral",
    "Beacon",
    "Catalyst",
    "Dynamo",
    "Ethereal",
    "Fable",
    "Gossamer",
    "Halcyon",
    "Indigo",
    "Jigsaw",
    "Kaleidoscope",
    "Luminous",
    "Meridian",
    "Nimbus",
    "Oasis",
    "Parallax",
    "Quill",
    "Resonance",
    "Solstice",
    "Theorem",
    "Umbra",
    "Verge",
    "Whisper",
    "Xenon",
    "Zephyr",
    "Anchor",
    "Breach",
    "Circuit",
    "Drift",
    "Enigma",
    "Fracture",
    "Gradient",
    "Horizon",
    "Impulse",
    "Juno",
    "Kinesis",
    "Lithic",
    "Momentum",
    "Nexus",
    "Opaque",
    "Prism",
    "Quantum",
    "Ripple",
    "Serenity",
    "Tether",
    "Unbound",
    "Vertex",
    "Wildfire",
}

function CyberNPC.NPCRandomFemaleNickname()
    local v = math.random(#(CyberNPC.NPCFemaleNicknames))
    return CyberNPC.NPCFemaleNicknames[v]
end

function CyberNPC.NPCRandomName()
    local dbNames = sqlite:open("names.db")
    local sql = [[
        select
        (select * from random_male_name) as first,
        (select * from random_surname) as last
    ]]
    local first = ''
    local last = ''
    for row in dbNames:nrows(sql) do
        first = row.first
        last = row.last
    end
    dbNames:close()
    return first .. " " .. last
end


function CyberNPC.NPCRandomNickName(appearance)
    print("NPCRandomNickName")
    print("appearance:" .. appearance)
    local usePrefix = Chance50()
    local useThe = Chance50()
    local newDisplayName = ''
    local isFemale = string.match(appearance, '_wa') or string.match(appearance, 'wa_') or string.match(appearance, 'female_') or string.match(appearance, '_female')
    local isMale = string.match(appearance, '_ma') or string.match(appearance, 'ma_')  or string.match(appearance, 'male_') or string.match(appearance, '_male')
    local middleFiller = ' '
    if useThe then
        middleFiller = ' the '
    end

    if isFemale then
        -- female
        if usePrefix then
            newDisplayName = CyberNPC.NPCRandomFemaleNickname() .. middleFiller .. CyberNPC.NPCRandomFemaleName()
        else
            newDisplayName = CyberNPC.NPCRandomFemaleName() .. middleFiller .. CyberNPC.NPCRandomFemaleNickname()
        end            
    elseif isMale then
        -- male
        
        if usePrefix then
            newDisplayName = CyberNPC.NPCRandomMaleNickname() .. middleFiller .. CyberNPC.NPCRandomMaleName()
        else
            newDisplayName = CyberNPC.NPCRandomMaleName() .. middleFiller .. CyberNPC.NPCRandomMaleNickname()
        end
    else
        -- something else. just a nick name
        -- use prefix for either using female or male nickname
        local useDoubleNickname = math.random(10) > 5
        if usePrefix then
            newDisplayName = CyberNPC.NPCRandomMaleNickname()
            if useDoubleNickname then
                newDisplayName = newDisplayName .. middleFiller .. CyberNPC.NPCRandomMaleNickname()
            end
        else
            newDisplayName = CyberNPC.NPCRandomFemaleNickname()
            if useDoubleNickname then
                newDisplayName = newDisplayName .. middleFiller .. CyberNPC.NPCRandomFemaleNickname()
            end
        end
    end
    print(newDisplayName)
    return newDisplayName
end

function CyberNPC.NPCSync(thenFn)
    CyberNPC.backend.NPCSync(
    CyberV.GetPlayerInfoForServer(),
    CyberV.cyberNPC.GetLastNPCTargetForServer(),
    function(response)
        if thenFn then
            thenFn()
        end
    end)
end
function CyberNPC.NPCSpeakExtended(textContent, npcId, npcName, npcData, additionalArgs, spawnDialogLine)
    print("CyberNPC.NPCSpeakExtended!!!")
    if not textContent or #textContent == 0 then
        print("CyberNPC.NPCSpeakExtended Empty")
        return
      end
    CyberNPC.backend.Tts(
        textContent,
        npcId, 
        '',
        'piper',
        additionalArgs or {},
        CyberV.GetPlayerInfoForServer(),
        npcData or CyberV.cyberNPC.GetLastNPCTargetForServer(),
        function(response)
            -- local content = CyberNPC.backend.GetJsonResponse(response)
            
        end)
    if spawnDialogLine == nil or spawnDialogLine == true then
        if npcName ~= nil then
            if #npcName > 0 then
                print("CyberNPC.NPCSpeak: Got a name here")
                local p = Game.GetPlayer()            
                CyberNPC.subtitlesControl.SpawnDialogLine(textContent, npcName, p)
                CyberNPC.FakeTalk(textContent)
            else
                print("CyberNPC.NPCSpeak: npcName len == 0")
            end
        else
            print("CyberNPC.NPCSpeak: no npcName")
        end
    end
end

function CyberNPC.NPCSpeak(textContent, npcId, npcName, additionalArgs)
    print("CyberNPC.NPCSpeak!!!")
    if not textContent or #textContent == 0 then
        print("CyberNPC.NPCSpeak Empty")
        return
    end
    CyberNPC.NPCLookAtPlayer()
    CyberNPC.backend.Tts(
        textContent,
        npcId, 
        '',
        'piper',
        additionalArgs or {},
        CyberV.GetPlayerInfoForServer(),
        CyberV.cyberNPC.GetLastNPCTargetForServer(),
        function(response)
            -- local content = CyberNPC.backend.GetJsonResponse(response)
            
        end)
    if npcName ~= nil then
        if #npcName > 0 then
            print("CyberNPC.NPCSpeak: Got a name here")
            local p = Game.GetPlayer()          
            CyberNPC.subtitlesControl.SpawnDialogLine(textContent, npcName, p)
            CyberNPC.FakeTalk(textContent)
        else
            print("CyberNPC.NPCSpeak: npcName len == 0")
        end
    else
        print("CyberNPC.NPCSpeak: no npcName")
    end
end

-- takes the voice of the last npc for speaking
function CyberNPC.NPCSpeakLast(textContent)     
    return CyberNPC.NPCSpeak(textContent, CyberNPC.LastNPCTarget.id_hash, CyberNPC.LastNPCTarget.display_name)
end

CyberNPC.NeedsCheckLoopInSeconds = 60
CyberNPC.MoodUpdateMaxPercentage = 5
-- checks for needs and deteriorates state
function CyberNPC.NeedsCheckLoop()
    if GameSession.IsDead() or GameSession.IsPaused() or GameSession.IsBlurred() or not GameSession.IsLoaded() then
        return
    end

    -- we allow one follower for now. need to extend in the future
    if not AIControl.HasFollowers() then return end
    
    -- lets just have a global one for now (1-5%)
    local maxPercentage = CyberNPC.MoodUpdateMaxPercentage
    local deteriorationPercentageFood = math.random(0,maxPercentage) / 100
    local deteriorationPercentageHydration = math.random(0,maxPercentage) / 100
    local deteriorationPercentageFun = math.random(0,maxPercentage) / 100
    -- local deteriorationPercentageRelationship = math.random(0,maxPercentage) / 100
    
    local food = CyberNPC.LLamaNPCFood - (CyberNPC.LLamaNPCFood * deteriorationPercentageFood)
    local hydration = CyberNPC.LLamaNPCHydration - (CyberNPC.LLamaNPCHydration * deteriorationPercentageHydration)
    local fun = CyberNPC.LLamaNPCFun - (CyberNPC.LLamaNPCFun * deteriorationPercentageFun)
    -- local relationship = CyberNPC.LLamaNPCRelationship - (CyberNPC.LLamaNPCRelationship * deteriorationPercentageRelationship)

    if(food < 0) then
        print("skipping food. value is below 0")
    else
        if(food > 100) then
            food = 100
        else
            CyberNPC.LLamaNPCFood = food
        end
    end

    if(hydration < 0) then
        print("skipping hydration. value is below 0")
    else
        if(hydration > 100) then
            hydration = 100
        else
            CyberNPC.LLamaNPCHydration = hydration
        end
    end

    if(fun < 0) then
        print("skipping fun. value is below 0")
    else
        if(fun > 100) then
            fun = 100
        else
            CyberNPC.LLamaNPCFun = fun
        end
    end

    -- if(relationship < 0) then
    --     print("skipping relationship. value is below 0")
    -- else
    --     if(relationship > 120) then
    --         relationship = 120
    --     else
    --         CyberNPC.LLamaNPCRelationship = relationship
    --     end
    -- end
    
    CyberNPC.backend.Revlookup(
        GameSession.GetKey(),
        CyberV.GetPlayerInfoForServer(),
        CyberNPC.GetLastNPCTargetForServer(),
        function(res)
            
        end)
end

function CyberNPC.NeedsInCriticalThreshold()
    -- lets just follow Maslow for a bit
    if CyberNPC.LLamaNPCHydration <= CyberNPC.LLamaNPCNeedsCriticalThreshold then
        print("Cannot AddRelationshipMaybe, since hydration is below critical threshold")
        return true
    end
    if CyberNPC.LLamaNPCFood <= CyberNPC.LLamaNPCNeedsCriticalThreshold then
        print("Cannot AddRelationshipMaybe, since food is below critical threshold")
        return true
    end
end

function CyberNPC.AddFunMaybe(maxPercentage)
    if not AIControl.HasFollowers() then return end
    if CyberNPC.NeedsInCriticalThreshold() then return end

    local percentage = CyberNPC.MoodUpdateMaxPercentage
    if not maxPercentage then
        percentage = maxPercentage
    end
    local augPercentage = math.random(0,percentage) / 100   
    local val = CyberNPC.LLamaNPCFun + (CyberNPC.LLamaNPCFun * augPercentage)
    if val > 100 then
        CyberNPC.LLamaNPCFun = 100
    else
        CyberNPC.LLamaNPCFun = val
    end
end

function CyberNPC.AddRelationshipMaybe(maxPercentage)
    if not AIControl.HasFollowers() then return end
    if CyberNPC.NeedsInCriticalThreshold() then return end

    local percentage = CyberNPC.MoodUpdateMaxPercentage
    if not maxPercentage then
        percentage = maxPercentage
    end    
    local augPercentage = math.random(0,percentage) / 100
    local val = CyberNPC.LLamaNPCRelationship + (CyberNPC.LLamaNPCRelationship * augPercentage)
    if val > 100 then
        CyberNPC.LLamaNPCRelationship = 100
    else
        CyberNPC.LLamaNPCRelationship = val
    end
end


CyberNPC.NPCAnimationDanceReactions = {
    "stand__dance__02__dancing__01",
    "stand__dance__02__dancing__03",
    "stand__dance__02__dancing__07",
    "stand__dance__03__dancing__01",
    "stand__dance__03__dancing__03",
    "stand__dance__03__dancing__04",
}
function CyberNPC.NPCRandomDanceStandAnimation()
    return CyberNPC.NPCAnimationDanceReactions[math.random(#(CyberNPC.NPCAnimationDanceReactions))]
end


CyberNPC.NPCAnimationStandReactions = {
    "stand__arms_crossed_front__01__tap__01",
    "stand__arms_crossed_front__01__what__neutral__03",
    "stand__arms_crossed_front__01__what__neutral__01",
    "stand__arms_crossed_front__01",
    "stand__arms_crossed_front__01__rub_eyes__01",
    "stand__arms_crossed_front__01__rub_forehead__01",    
    "stand__arms_crossed_front__01__shuffle__04",
    "stand__arms_crossed_front__01__shuffle__09",
    "stand__arms_crossed_front__01__shuffle__03",
    "stand__2h_on_sides__01__rub_hands__02",
    "stand__2h_on_sides__01__rub_hands__01",
    "stand__2h_on_sides__01__rub_hands__03",
    "stand__2h_on_sides__ow__01__scratch_neck__01",
}
function CyberNPC.NPCAnimationStandRandomAnimation()
    return CyberNPC.NPCAnimationStandReactions[math.random(#(CyberNPC.NPCAnimationStandReactions))]
end

CyberNPC.NPCAnimationTalkStandReactions = {
    "stand__2h_on_hip__01__talk__neutral__01",
    "stand__2h_on_hip__01__talk__neutral__02",
    "stand__2h_on_hip__01__talk__neutral__03",
    "stand__2h_on_hip__01__talk__neutral__04",
    "stand__2h_on_hip__01__talk__neutral__05",
    "stand__2h_on_hip__01__talk__neutral__06",
    "stand__2h_on_hip__01__talk__neutral__07",
    "stand__2h_on_sides__01__talk__neutral__01",
    "stand__2h_on_sides__01__talk__neutral__02",
    "stand__2h_on_sides__01__talk__neutral__03",
    "stand__2h_on_sides__01__talk__neutral__04",
    "stand__2h_on_sides__01__talk__neutral__05",
    "stand__2h_on_sides__01__talk__neutral__06",
    "stand__2h_on_sides__01__talk__neutral__07",
    "stand__2h_on_sides__01__talk__neutral__08",
    "stand__2h_on_sides__01__talk__neutral__09",
    "stand__arms_crossed_front__01__talk__neutral__01",
    "stand__arms_crossed_front__01__talk__neutral__02",
    "stand__arms_crossed_front__01__talk__neutral__03",
    "stand__arms_crossed_front__01__talk__neutral__04",
    "stand__arms_crossed_front__01__talk__neutral__05",
    "stand__arms_crossed_front__01__talk__neutral__06",
    "stand__arms_crossed_front__01__talk__neutral__07",
    "stand__arms_crossed_front__01__talk__neutral__08",
    "stand__arms_crossed_front__01__talk__neutral__09",
    "stand__arms_crossed_front__01__talk__neutral__10",                                            
}
function CyberNPC.NPCRandomTalkStandAnimation()
    return CyberNPC.NPCAnimationTalkStandReactions[math.random(#(CyberNPC.NPCAnimationTalkStandReactions))]
end

CyberNPC.NPCAnimationSmokeReactions = {
    "stand_smoke_cigarette_stop",
    "synced__stand_joint__smoke_together__01__npc2",
    "synced__stand_joint__smoke_together__01__shuffle__02__npc2",
    "synced__stand_joint__smoke_together__01__shuffle__02__npc1",
    "synced__stand_joint__smoke_together__01__shuffle__03__npc2",
    "synced__stand_joint__smoke_together__01__shuffle__03__npc1",
    "synced__stand_joint__smoke_together__01__talk__01__npc2",
    "synced__stand_joint__smoke_together__01__talk__01__npc1",
    "synced__stand_joint__smoke_together__01__talk__02__npc2",
    "synced__stand_joint__smoke_together__01__talk__02__npc1",
    "synced__stand_joint__smoke_together__01__smoke__01__npc2",
    "synced__stand_joint__smoke_together__01__smoke__01__npc1",
    "synced__stand_joint__smoke_together__01__smoke__02__npc2",
    "synced__stand_joint__smoke_together__01__smoke__02__npc1",
    "synced__stand_joint__smoke_together__01__exit__npc1",
    "synced__stand_joint__smoke_together__01__exit__npc2",
    "synced__stand_joint__smoke_together__01__enter__npc2",
    "synced__stand_joint__smoke_together__01__enter__npc1",
    "synced__stand_joint__smoke_together__01__shuffle__01__npc2",
    "synced__stand_joint__smoke_together__01__shuffle__01__npc1",
    "synced__stand_joint__smoke_together__01__laugh__01__npc2",
    "synced__stand_joint__smoke_together__01__laugh__01__npc1",
    "dirt__stand__rh_cigarette__01__smoke__01",
    "dirt__stand__rh_cigarette__01__smoke__02",
    "dirt__stand__rh_cigarette__01__smoke__03",
    "dirt__stand__rh_cigarette__01__smoke__04",
    "dirt__stand__rh_cigarette__ow__01__smoke__02",
    "dirt__stand__rh_cigarette__ow__01__smoke__03",
    "dirt__stand__rh_cigarette__ow__01__smoke__04",
    "stand__rh_cane_lh_cigar__01__smoke__01",
    "stand__rh_cane_lh_cigar__01__smoke__02",
    "stand__rh_cigarette_lh_crossed__01__smoke__01",
    "stand__rh_cigarette_lh_crossed__01__smoke__02",
    "stand__rh_cigarette_lh_crossed__01__smoke_long__01",
    "stand__rh_cigarette__01__smoke__nervous__02",
    "stand__rh_cigarette__01__talk_smoke__02",
    "stand__rh_cigarette__01__smoke__01",
    "stand__rh_cigarette__01__smoke__nervous__01",
    "stand__rh_cigarette__01__smoke__02",
    "stand__rh_cigarette__01__talk_smoke__01",
    "stand__rh_cigarette__ow__01__smoke__01",
    "stand__rh_cigarette__ow__01__smoke__02",
    "stand__rh_cigar__weight_right__01__smoke__01",
    "stand__rh_cigar__weight_right__01__smoke__03",
    "stand__rh_cigar__weight_right__01__smoke__02",
    "stand__rh_cigar__weight_right__01__smoke__flirt__01",    
}

function CyberNPC.NPCRandomSmokeReactionAnimation()
    return CyberNPC.NPCAnimationSmokeReactions[math.random(#(CyberNPC.NPCAnimationSmokeReactions))]
end

function CyberNPC.NPCLookAtPlayer(howLong)    
    pcall(function()
        CyberNPC.aiControl.NPCLookAt(CyberNPC.LastNPCTarget.obj, Game.GetPlayer(), howLong)
    end)
end

function CyberNPC.NPCRotateToPlayer()
    local player = Game.GetPlayer()
    local playerPos = player:GetWorldPosition()
    AIControl.RotateTo(CyberNPC.LastNPCTarget.obj, playerPos)
end

function CyberNPC.MoveToPlayer()
    if CyberNPC.InACar() then
        return
    end
    local player = Game.GetPlayer()
    local playerPos = player:GetWorldPosition()
    AIControl.MoveTo(player, playerPos, 10, moveMovementType.Walk)
end

function CyberNPC.IsTalkable()
    local player = Game.GetPlayer()
    return AIControl.InTalkDistance(player, CyberNPC.GetLastTarget())
end

function CyberNPC.IsAFriend()
    return CyberNPC.LLamaNPCRelationship >= CyberNPC.LLamaNPCFriendThreshold
end
function CyberNPC.IsRomanceable()
    return CyberNPC.LLamaNPCRelationship >= CyberNPC.LLamaNPCRomanticThreshold
end

function CyberNPC.IsThirsty()
    return CyberNPC.LLamaNPCFood < 50
end
function CyberNPC.IsHungry()
    return CyberNPC.LLamaNPCHydration < 50
end
function CyberNPC.IsBored()
    return CyberNPC.LLamaNPCFun < 50
end

CyberNPC.AnimationRef = {
    obj = nil,
    obj_id = nil,
    hash = nil,
    target = nil
}
CyberNPC.animationSpawnTimer = nil
CyberNPC.animationStopTimer = nil

function CyberNPC.NPCStopAnimation()
    if CyberNPC.AnimationsEnabled == false then
        return
    end
    if CyberNPC.AnimationRef.target then
        Game.GetWorkspotSystem():StopInDevice(CyberNPC.AnimationRef.target)
    end

  
    print("NPCStopAnimation")
    if not CyberNPC.AnimationRef.obj then
        if CyberNPC.AnimationRef.obj_id then
            CyberNPC.AnimationRef.obj = Game.FindEntityByID(CyberNPC.AnimationRef.obj_id)
        end
        if not CyberNPC.AnimationRef.obj then
            print("NPCStopAnimation: CyberNPC.AnimationRef.obj is nil")
            return
        else
            exEntitySpawner.Despawn(CyberNPC.AnimationRef.obj)
            CyberNPC.AnimationRef.obj:Dispose()
            CyberNPC.AnimationRef.obj = nil
        end
    end
    -- if CyberNPC.AnimationRef.target and Game.GetWorkspotSystem():IsActorInWorkspot(CyberNPC.AnimationRef.target) then
    --     print("NPCStopAnimation: IsActorInWorkspot CyberNPC.AnimationRef.target")
    --     local wInfo = Game.GetWorkspotSystem():ExtendedWorkspotInfo(CyberNPC.AnimationRef.target)
    --     print("ExtendedWorkspotInfo.isActive")
    --     print(wInfo.isActive)
    --     print("ExtendedWorkspotInfo.entering")
    --     print(wInfo.entering)
    --     print("ExtendedWorkspotInfo.exiting")
    --     print(wInfo.exiting)
    --     print("ExtendedWorkspotInfo.playingSyncAnim")
    --     print(wInfo.playingSyncAnim)
    --     print("ExtendedWorkspotInfo.inReaction")
    --     print(wInfo.inReaction)
    --     print("ExtendedWorkspotInfo.inMotion")
    --     print(wInfo.inMotion)
    -- end

    print("NPCStopAnimation: StopInDevice")
    Game.GetWorkspotSystem():StopInDevice(CyberNPC.AnimationRef.obj)
    print("NPCStopAnimation: StopNpcInWorkspot")
    Game.GetWorkspotSystem():StopNpcInWorkspot(CyberNPC.AnimationRef.target)

    if CyberNPC.AnimationRef.obj then
        Game.GetWorkspotSystem():SendJumpToAnimEnt(CyberNPC.AnimationRef.target,
                nil,
                true)

        print("NPCStopAnimation: Despawn")
        exEntitySpawner.Despawn(CyberNPC.AnimationRef.obj)
        print("NPCStopAnimation: Dispose")
        CyberNPC.AnimationRef.obj:Dispose()
        
        
        CyberNPC.cron.After(2, function()
            local player = Game.GetPlayer()            
            AIControl.RotateTo(CyberNPC.LastNPCTarget.obj, player:GetWorldPosition())
            print("RotateTo")
            AIControl.MoveTo(CyberNPC.LastNPCTarget.obj, CyberNPC.LastNPCTarget.obj:GetWorldPosition())
            print("MoveTo")
        end, {})
    else
        print("NPCStopAnimation: CyberNPC.AnimationRef.obj is nil")

    end
end

function CyberNPC.NPCStartAnimation(targetPuppet, animationName, durationInSeconds)
    if CyberNPC.AnimationsEnabled == false then
        return
    end
    print("NPCStartAnimation")
    print(animationName)
    CyberNPC.NPCStopAnimation()
    if animationName == nil then
        print("No animation name")
        return
    end
    if not targetPuppet then
        print("No npc set yet")
        return
    end
    local pos = Game.GetPlayer():GetWorldPosition()
    print(pos)
    local npcPos = targetPuppet:GetWorldPosition()
    print(npcPos)

    AIControl.RotateTo(targetPuppet, pos)
    CyberNPC.MakeEyesGlowGold(targetPuppet)  
    local spawnTransform = targetPuppet:GetWorldTransform()
    local npcPosTest = Vector4:new(npcPos.x, npcPos.y, npcPos.z, 1)

    spawnTransform:SetPosition(npcPosTest)
    local playerAngle = Game.GetPlayer():GetWorldOrientation():ToEulerAngles()
    local angles = targetPuppet:GetWorldOrientation():ToEulerAngles()
    angles.yaw = playerAngle.yaw 
        -- + 180

    spawnTransform:SetOrientationEuler(EulerAngles.new(0, 0, angles.yaw))
    local entityID = exEntitySpawner.Spawn("base\\amm_workspots\\entity\\workspot_anim.ent", spawnTransform, '')
    if CyberNPC.animationStopTimer == nil then
        CyberNPC.animationStopTimer = CyberNPC.cron.After(durationInSeconds, function()        
        CyberNPC.StopMakeEyesGlowGold(targetPuppet)
        CyberNPC.NPCStopAnimation()
        end, {})
    end

    CyberNPC.animationSpawnTimer = CyberNPC.cron.Every(0.1, function(timer)
            print("TestAnimationSpawnTimer")
            timer.tick = timer.tick + 1
            
            if timer.tick > 10 then
                CyberNPC.cron.Halt(CyberNPC.animationSpawnTimer)
            end

            local ent = Game.FindEntityByID(entityID)
            if ent then
                CyberNPC.AnimationRef.obj_id = entityID
                CyberNPC.AnimationRef.obj = ent
                -- TestAnimationHandle.target = CyberNPC.LastNPCTarget.obj

                print("AnimationHandle.obj created")
                print(CyberNPC.AnimationRef.obj)
                Game.GetWorkspotSystem():PlayInDeviceSimple(
                    CyberNPC.AnimationRef.obj, 
                    targetPuppet, 
                    false, 
                    'amm_workspot_base',
                    CName.new('CLLAMA_WORKSPOT'),
                    nil, 
                    0, 
                    1, 
                    nil)
                
                    -- "synced__panam_on_bike_kisses_player__01",
                Game.GetWorkspotSystem():SendJumpToAnimEnt(targetPuppet,
                    animationName,
                    true)                
                CyberNPC.cron.Halt(timer)
            end
        end, {tick = 1})

    end

return CyberNPC