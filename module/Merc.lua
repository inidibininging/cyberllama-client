Merc = {
    data = {},
    NPCMercCheckSpawnLoopSeconds = 20,
    maxMercs = 2,
    -- mercs dont surive that long
    MercArmorPercentage = 90,
    MercDamagePercentage = 200,
}
function Merc.Init(cyberV, cyberNPC, gangs, fastTravelMarks, targetHelper, targetMarker, hud, cron)
    Merc.cyberV = cyberV
    Merc.cyberNPC = cyberNPC
    Merc.gangs = gangs
    Merc.fastTravelMarks = fastTravelMarks
    Merc.targetHelper = targetHelper
    Merc.targetMarker = targetMarker    
    Merc.hud= hud
    Merc.cron = cron
    Override('ScannerNPCHeaderGameController', 'OnNameChanged', function(this, value, wrappedMethod)
        Merc.OnNameChanged(this, value, wrappedMethod)
	end)
    Observe('NPCPuppet', 'SendAfterDeathOrDefeatEvent', function(target)
        Merc.TrackOnKill(target)
    end)
    Observe('DamageSystem', 'ProcessRagdollHit', function(this, gameHitEvent)
        -- Merc.OnHit(this, gameHitEvent)
    end)
    Merc.timer = nil
end

function Merc.Dispose()
    Merc.data = {}
    Merc.DeactivateTimer()
end

function Merc.DeactivateTimer()
    if not Merc.timer then return end
    Merc.cron.Halt(Merc.timer)
    Merc.timer = nil
end
function Merc.ActivateTimer()
    if Merc.timer then
        print("Merc.timer already set")
        return
    end
    Merc.timer = Merc.cron.Every(Merc.NPCMercCheckSpawnLoopSeconds, Merc.NPCMercCheckSpawnLoop)
end

function Merc.AnyMercDied()
    for i = 1, #Merc.data do
        if Merc.data[i].died then
            return true
        end
    end
    return false
end

function Merc.OnHit(damageSystem, gameHitEvent)
    local instigator = gameHitEvent.attackData:GetInstigator()
    if not instigator then return end
    if instigator.IsPlayerCompanion and instigator:IsPlayerCompanion() then
        gameHitEvent.attackComputed:MultAttackValue(Merc.MercDamagePercentage / 100)
    end
	if gameHitEvent.target then
        local targetInfo = Merc.cyberNPC.PeekTargetInfo(gameHitEvent.target)
        if Merc.IsAMerc(targetInfo) then  
            gameHitEvent.attackComputed:MultAttackValue((100 - Merc.MercArmorPercentage) / 100)
            return
        end
	end
end

function Merc.IsAMerc(targetInfo)
    print(targetInfo)
    if not targetInfo.record_id_hash then
        print("Cant check. target has no record_id_hash property")
        return false
    end
    for i = 1, #Merc.data do
        if Merc.data[i].mercEntity then
            if Merc.data[i].mercEntity.record_id_hash == targetInfo.record_id_hash then
                return true
            end
        end
    end
    return false
end

function Merc.GetMercsAvailable()
    local mercsAvailable = {}
    for i = 1, #Merc.data do
        if Merc.data[i].spawned and not Merc.data[i].dided then
            table.insert(mercsAvailable, Merc.data[i].mercEntity)
        end
    end
    return mercsAvailable
end
function Merc.CleanUpDeadMercs()
    local newMercData = {}
    for i = 1, #Merc.data do
        if Merc.data[i].died then
            Merc.data[i] = nil
        else
            table.insert(newMercData, Merc.data[i])
        end
    end
    if #newMercData > 0 then
        Merc.data = newMercData
    else
        Merc.data = {}
    end
end

-- function Merc.GetRandomArsenal()
--     return Math.random()
-- end
function Merc.GetRandomWeapon()
    local r = {
        Merc.GetMeleeWeapon,
        Merc.GetAssaultWeapon,
        Merc.GetShotgunnerWeapon,
        Merc.GetSniperWeapon,
    }
    return r[math.random(#r)]()
end
function Merc.GetMeleeWeapon()
    local weapon = {
        "Character.nok_arasaka_ninja_fmelee3_mantis_ma_elite",
        "Character.spr_valentinos_grunt4_hmelee2_knife_mb_rare",
        "Character.q115_arasaka_atrium_melee_knife",
        "Character.sa_ep1_courier_loop_enemies_animals_melee1_baseball_mb",
        "Character.hil_arasaka_ninja_fmelee3_katana_wa_elite",
        "Character.spr_ncpd_police_melee2_baton_ma",
        "Character.sa_ep1_courier_loop_enemies_animals_melee2_machete_mb"
    }
    return weapon[math.random(#weapon)]
end

function Merc.GetAssaultWeapon()
    local weapon = {
        "Character.sa_ep1_courier_loop_enemies_animals_ranged1_nova_mb",
        "Character.spr_ncpd_police_ranged2_copperhead_ma",
        "Character.sa_ep1_courier_loop_enemies_militech_ranged2_ajax_ma",
        "Character.q115_arasaka_atrium_lmg_rare",
        "Character.arasaka_bodyguard_ranged3_masamune_mb_rare",
        "Character.dtn_animals_bouncer1_ranged1_omaha_mb",
        "Character.arasaka_cyborg_franged3_shingen_ma_elite",
    }
    return weapon[math.random(#weapon)]
end

function Merc.GetSniperWeapon()
    local weapon = {
        "Character.hil_arasaka_sniper_sniper3_ashura_ma_elite",
        "Character.aldecaldos_grunt2_sniper2_sor22_wa_elite",
        "Character.cvi_scavenger_elite3_sniper2_grad_ma",
    }
    return weapon[math.random(#weapon)]
end

function Merc.GetShotgunnerWeapon()
    local weapon = {
        "Character.animals_elite2_shotgun3_carnage_wba_elite",
        "Character.spr_ncpd_police_ranged2_saratoga_wa",
        "Character.animals_elite2_ranged3_burya_mba_rare",
        "Character.arasaka_cyborg_fshotgun3_zhuo_ma_elite",
        "Character.spr_valentinos_shotgun3_shotgun3_testera_ma_elite",
    }
    return weapon[math.random(#weapon)]
end

function Merc.GenerateSalary(weaponName)
    local salaryBase = math.random(500,1000) 
    -- TODO: get if player uses custom max level.
    -- this SHOULD BE MADE consistant with the reward in quest\
    -- be great to recommend this with stuff that makes your life miserable and a constant grind (immersion mods)
    return math.floor(((GameUtils.GetLevel(Game.GetPlayer()).level / 60) * salaryBase) - 0.5)
end

-- for every day passed draw the salary
function Merc.DrawSalary()
    
    local transactionSystem = getTransactionSystem()
    if not transactionSystem then return end
    local player = Game.GetPlayer()
    if not player then return end
    local moneyId = nil
    if gameItemID and gameItemID.FromTDBID then
        moneyId = gameItemID.FromTDBID(TweakDBID.new("Items.money"))
    else
        moneyId = ItemID.new(TweakDBID.new("Items.money"))
    end
    if not transactionSystem.GetItemQuantity then return end

    for i = 1, #Merc.data do
        local merc = Merc.data[i]
        local amount = transactionSystem:GetItemQuantity(player, moneyId)
        if not amount then return end
        if amount - merc.salary > 0 then
            transactionSystem:RemoveItem(player, moneyId, amount - merc.salary)
        else

        end
    end
    
end

function Merc.GenerateRandomMeetingData(weaponName)
    local districtAndLocation = Merc.fastTravelMarks.GetRandomLocationInRandomDistrict()
    local randomCyberpunk = Merc.gangs.RandomCyberpunkInfo()
    local mercData = {
        mercLocation = districtAndLocation.location,
        mercDistrict = districtAndLocation.district,
        mercInfo = randomCyberpunk,
        mercEntity = nil,
        died = false,
        spawned = false,
        nameScanned = nil,
        kia = nil,
        weapon = weaponName,
        -- can be used later on if the npc is spawned as a friend (relationship < threshold)
        salary = Merc.GenerateSalary(weaponName),
        lastDaySalary = 0,
        armor = 100,
    }
    table.insert(Merc.data, mercData)
    Merc.ActivateTimer()
    Merc.targetMarker.Mark(
        Vector4:new(            
            districtAndLocation.location.x,
            districtAndLocation.location.y,
            districtAndLocation.location.z,
            1),
        Enum.new('gamedataMappinVariant', 'Mappins.DefaultStaticMappin'),
        "merc",
        true
    )
    return mercData
end

function Merc.OnNameChanged(scan, value, wrappedMethod)
    local objLook = TargetHelper.GetLookAtTarget()
    if not objLook then
        return wrappedMethod(value)
    end
    if #Merc.data == 0 then
        return wrappedMethod(value)
    end
    local done = false
    for i = 1, #Merc.data do
        -- just in case it respawns / despawns entity
        if Merc.data[i].spawned and Merc.data[i].record_id == objLook:GetRecordID() then
            -- deactivate timer here?
            done = true
            if Merc.data[i].mercEntity.nameScanned then
                Merc.data[i].mercEntity.nameScanned = true
                Merc.data[i].mercEntity.display_name = tostring(objLook:GetDisplayName())
            end
            inkTextRef.SetText(scan.nameText, Merc.data[i].mercEntity.display_name)
            scan.isValidName = true
            scan:UpdateGlobalVisibility()
        end
    end
    if not done then
        wrappedMethod(value)
    end
end

function Merc.NPCMercInternalCheckSpawn(entry)    
    print("NPCMercInternalCheckSpawn")
    if Merc.died then return end
    if Merc.targetHelper.InDistance(Merc.cyberV.GetPlayerPos(), entry.mercLocation, Merc.cyberNPC.SpawnNearDistance) then
        Merc.cyberV.TimePasses()
        local doOnlyOnce = false
        local fren = Merc.cyberNPC.SpawnNPC(
            entry.mercLocation,
            entry.mercInfo.entity_tweak,
            nil,
            SpawnAnimus.Friendly,
            entry.weapon,
            function(entity)
                if doOnlyOnce then return end
                doOnlyOnce = true
                entry.mercEntity = Merc.cyberNPC.PeekTargetInfo(entity)
                entry.spawned = true
                Merc.cyberV.VSpeak(Merc.cyberV.VGreetingsRandomLine('Merc'))
                Merc.cyberV.StopCloseEyes()
                Merc.cyberV.BlinkFast()
                
                -- do this every x days
                -- Game.AddToInventory("Items.money", entry.salary * -1)

                -- set in the menu events part
                Merc.targetMarker.UnmarkLastByTag("merc")
            end
        )
    else
        -- not needed . it is stored in the phone (fixer)
        -- Merc.hud.QuestMessage("Meet the merc in " .. entry.mercLocation.name .. ', ' .. entry.mercDistrict.Name)
    end
end


function Merc.NPCMercCheckSpawnLoop()
    if #Merc.data == 0 then
        Merc.DeactivateTimer()
    end
    for i = 1, #Merc.data do
        if not Merc.data[i].spawned then
            Merc.NPCMercInternalCheckSpawn(Merc.data[i])
        end
    end
end

function Merc.TrackOnKill(targetPuppet)
    print("Merc - TrackOnKill")
    if #Merc.data == 0 then return end
    if not targetPuppet then return end
    print(targetPuppet:GetRecordID())
    for idx = 1, #(Merc.data) do
        local mercData = Merc.data[idx]
        print(mercData)
        if not mercData.mercEntity then
            print("No mercData.mercEntity")
        end
        if mercData and mercData.mercEntity then
            if mercData.mercEntity.obj:GetRecordID() == targetPuppet:GetRecordID() then
                Merc.hud.Warning(mercData.mercEntity.display_name .. " - KIA")
                Merc.data[idx].died = true
            end
        end
    end
end

function Merc.RewardFun(mercData)
    print("Merc.RewardFun for " .. mercData.mercEntity.display_name)
    if mercData.spawned then
        local cachedData = Merc.cyberNPC.GetCachedNPCTargetByRecordIdHash(mercData.mercEntity.record_id_hash)
        if not cachedData then
            print("Merc.RewardFun didnt work. no cached npc")
            return
        end
        if Merc.cyberNPC.LastNPCTarget.record_id_hash == mercData.mercEntity.record_id_hash then
            print("Merc.RewardFun - Using LastNPCTarget")
            Merc.cyberNPC.NPCUpdateFun(cachedData, Merc.cyberNPC.LastNPCTarget.LLamaNPCFun + 2)
            Merc.cyberNPC.NPCUpdateFun(Merc.cyberNPC.LastNPCTarget.LLamaNPCFun + 2)
            return
        else
            print("Merc.RewardFun - Using cached data")
            Merc.cyberNPC.NPCUpdateFun(cachedData, cachedData.LLamaNPCFun + 2)
        end
    end
end

function Merc.OnSameLocationTimeChanged(minutesPassed)
    if minutesPassed < 15 then 
        print("< 15 minutes")
        return
    end
    for i = 1, #Merc.data do
        local mercData = Merc.data[i]
        Merc.RewardFun(mercData)
    end
end

function Merc.OnLocationChanged(locationAndTime)
    -- pass the mercs
    for i = 1, #Merc.data do
        if Merc.data[i].spawned then
            Merc.data[i].lastLocationAndTime = locationAndTime
        end
    end
end

return Merc