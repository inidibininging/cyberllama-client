local Quest = {
    enemies = {},
    type = '',
    location = '',
    locationActive = false,
    questLocations = {},
    questLocationsCheckInterval = 30,
    questDesiredDistance = 120,
    questLocationActive = false,
    questLocationIdx = 0,
    questKillPercentageDead = 0,
    questEndDays = 0,
    spawns = 0,
    done = true,
    reallyDone = false,
    journalNotificationQueue = nil,
    defaultQuestName = "cyberllama_quest",
    onQuestDone = nil,
    questSuccessPercentageThreshold = 80,
}

QuestTypes = {
  Kill = 1,
  Drive = 2,
  Rescue = 3,
  Hack = 4,
}
function QuestTypes.TypeToString(type)
  if type == QuestTypes.Kill then
    return 'Kill Job'
  elseif type == QuestTypes.Drive then
    return 'Drive Job'
  elseif type == QuestTypes.Rescue then
    return 'Rescue Job'
  elseif type == QuestTypes.Drive then
    return 'Hack Job'
  end
end

function Quest.Init(
    fastTravelMarks,
    locations,
    targetHelper,
    targetMarker,
    gangs,
    hud,
    cron,
    v,
    npc,
    aiControl,
    phoneControl
  )
  Quest.fastTravelMarks = fastTravelMarks
  Quest.locations = locations
  Quest.targetHelper = targetHelper
  Quest.targetMarker = targetMarker
  Quest.gangs = gangs
  Quest.hud = hud
  Quest.cron = cron
  Quest.v = v
  Quest.npc = npc
  Quest.aiControl = aiControl
  Quest.phoneControl = phoneControl
  Quest.QuestTypes = QuestTypes

  ObserveAfter('JournalNotificationQueue','OnMenuUpdate', function(self)
    Quest.journalNotificationQueue = self
  end)
 
  ObserveAfter('JournalNotificationQueue','OnInitialize', function(self)
    Quest.journalNotificationQueue = self
  end)

  Observe('NPCPuppet', 'SendAfterDeathOrDefeatEvent', function(target)      
    Quest.TrackOnKill(target)
  end)
end

-- borrowed from cyberscript
-- again. dont kill me please. 
-- i have no other source available on how to do this properly
function Quest.SpawnEnemy(entity, x, y, z)
    local chara = entity.entity_tweak
    local range = 5
    local appearance = nil
    local rotation = nil
    local despawntimer = 300
    local _persistState = false
    local _persistSpawn = false -- true before.. its just testing
    local _alwaysSpawned = false
    if 'string' ~= type(chara) then
        print("SpawnEnemy: entity_tweak for entity info provided is not a string")
        return nil
    end
    local player = Game.GetPlayer()
    local worldpos = player:GetWorldTransform()
    if despawntimer == nil then despawntimer = 0 end
    if appearance == "none" then appearance = "random" end
    
    local twk = TweakDBID.new(chara)
    local postp = Vector4.new( x, y, z, 1)

    worldpos:SetPosition(worldpos, postp)
    if(rotation == nil) then
    local rotAng = math.random(0, 360)
        rotation =  EulerAngles.new(0,0,rotAng)
    end
    ---@diagnostic disable-next-line: undefined-global
    local npcSpec =  DynamicEntitySpec.new()
    npcSpec.recordID = twk
    npcSpec.appearanceName = appearance or ""
    npcSpec.position = postp
    npcSpec.orientation = GetSingleton('EulerAngles'):ToQuat(rotation)
    npcSpec.persistState = _persistState or false
    npcSpec.persistSpawn = _persistSpawn or false
    npcSpec.alwaysSpawned = _alwaysSpawned or false
    npcSpec.spawnInView =  true    
    local npcId = Game.GetDynamicEntitySystem():CreateEntity(npcSpec)

    if npcId == nil then
        print("SpawnEnemy: npc id is nil and could not be created: " .. chara)
        return
    end
    print(npcId)
    
    local tick = 1    
    local spawnEnemyCron = nil
    spawnEnemyCron = Quest.cron.Every(
    0.2,
    function()
      tick = tick + 1

      if tick > 30 then
        Quest.cron.Halt(spawnEnemyCron)  
      end

      local entity = Game.FindEntityByID(npcId)
      if entity then
        
        pcall(function() 
          AIControl.MoveTo(entity, CyberV.GetPosition(5, 0))
          AIControl.MakeAggro(entity, Game.GetPlayer())       
        end)
        
        table.insert(Quest.enemies, entity)
        Quest.cron.Halt(spawnEnemyCron)
      end
    end, {})

    return true
end

function Quest.Dispose()
  print("Quest.Dispose")
  -- for idx = 1, #(Quest.enemies) do
  --     Quest.enemies[idx] = nil
  -- end
  Quest.enemies = {}  
  Quest.questLocations = {}
  Quest.locationActive = false
  Quest.done = false
  Quest.reallyDone = false
end

-- Should be injected in the observer function
---@param targetPuppet ScriptedPuppet
function Quest.TrackOnKill(targetPuppet)
    print("TrackOnKill")
    if Quest.done then return end
    print(targetPuppet:GetRecordID())
    for idx = 1, #(Quest.enemies) do
      if Quest.enemies[idx] then
        print(Quest.enemies[idx])
      end
      if not Quest.done and Quest.enemies and Quest.enemies[idx] and targetPuppet then
        if Quest.enemies[idx]:GetRecordID() == targetPuppet:GetRecordID() then
            print("found dead entity. removing")
            Quest.enemies[idx] = nil
            Quest.questKillPercentageDead = Quest.GetPercentageDead()
            if Quest.questKillPercentageDead > 0 and Quest.questKillPercentageDead <= 100 then
              if Quest.questKillPercentageDead > Quest.questSuccessPercentageThreshold then
                Quest.done = true
              end
              
              HUD.QuestMessage(tostring(Quest.GetPercentageDead()) .. " % dead")
            end
        end
      end
    end
end

function Quest.GetEnemyCount()
  if #Quest.enemies == 0 then return 0 end
  local counter = 0
  for i = 1, #Quest.enemies do
    if Quest.enemies[i] ~= nil then
      counter = counter + 1
    end
  end
  return counter
end

function Quest.IsPercentageDead(deadPercentage)
  local enemyCount = #(Quest.enemies)
  if enemyCount == 0 then
    return true
  end
  local deadCount = 0

  for idx = 1, #(Quest.enemies) do
    if Quest.enemies[idx] == nil then
      deadCount = deadCount + 1
    end
  end
  return (deadCount / enemyCount) * 100 >= deadPercentage
end

function Quest.GetPercentageDead()
  local enemyCount = Quest.GetEnemyCount()
  
  if enemyCount == 0 and Quest.done == false then
    return 0
  end
  local deadCount = 0

  for idx = 1, #(Quest.enemies) do
    if Quest.enemies[idx] == nil then
      deadCount = deadCount + 1
    end
  end
  return math.ceil(((deadCount / enemyCount) * 100) - 0.5)
end

function Quest.AreAllDead() 
    for idx = 1, #(Quest.enemies) do
        if Quest.enemies[idx] ~= nil then
            return false
        end
    end
    print("NPC's are all dead")
    
    return true
end

function Quest.GenerateShard(shardTitle, shardMessage)
  local shard = NotifyShardRead.new(
  {
    title = shardTitle,
    text = shardMessage
  })
  Game.GetUISystem():QueueEvent(shard)
end

function Quest.GetKillJobBaseReward(gangersCount)
  -- leveling : increase base amount (just a little) + increase enemy count
  local baseReward = math.random(1, 500)
  local multiplicator = GameUtils.GetLevel(Game.GetPlayer()).streetCred or 1
  local reward = ((gangersCount * (baseReward + multiplicator)))
  return reward
end

function Quest.GetDriverJobBaseReward(stops)
  local baseReward = math.random(1, 500)
  local multiplicator = GameUtils.GetLevel(Game.GetPlayer()).streetCred or 1
  local reward = ((stops * (100 + multiplicator)) + baseReward)
  return reward
end

function Quest.MarkJobPosition(position)  
  Quest.targetMarker.UnmarkAll()

  local posTrans = Vector4:new(
    position.x,
    position.y,
    position.z,
    1.0
  )
  Quest.targetMarker.Mark(
    posTrans,
    Enum.new('gamedataMappinVariant', "ExclamationMarkVariant"),
    "quest"
  )

  Quest.targetMarker.UnmarkLastByTag("quest")
  Quest.targetMarker.Mark(
    position,
    nil,
    "quest",
    true
  )
end

function Quest.GenerateHackJob()

end
function Quest.GenerateRescueJob()

end

function Quest.GenerateDriveJob()
  -- itd be nice if its something like (exterior location, interior location, exterior location)
  -- or any other combination of a sort (for this, I need nr1, a classification of places)
  -- also need to spawn a vehicle + enemies for chasing down the player
  -- the contractor can be sent to a certawain place (a door), despawn... wait a bit .. play a "break-in / alarm sound"...spawn again, make follower ... wait a bit ...  add wanted level
  -- itd be nice for generating like a bank robbery or any assault
  Quest.done = false
  
  local stopsCount = math.random(1,3)
  local stopLocations = Quest.fastTravelMarks.GetRandomLocations(stopsCount)
  local reward = Quest.GetDriverJobBaseReward(stopsCount)
  
  table.insert(Quest.questLocations, {
    location = stopLocations[1],
    stops = stopLocations,
    active = false,
    contractorSpawned = false,
    contractorDied = false,
    questType = QuestTypes.Drive,
    questReward = reward,
    districtName = stopLocations[1].district.Name
  })
  
  local questContent = 'Fetch the client at ' .. stopLocations[1].location.name .. ' in ' .. stopLocations[1].district.Name
  Quest.DisplayNewQuest(Quest.defaultQuestName, 'Driver Job', questContent)
  HUD.QuestMessage(questContent)
end

function Quest.GenerateKillJob()
  -- TODO: chain the quest to be more than "one stop"
  Quest.done = false
  local district = Quest.fastTravelMarks.GetRandomDistrict()
  local questLocation = Quest.fastTravelMarks.GetRandomLocationOfDistrict(district)

  local gang = ''
  local gangIndex = 0
  local gangersCount = math.random(2, 15)
  local reward = Quest.GetKillJobBaseReward(gangersCount)
  -- local baseReward = math.random(1, 500)
  -- this should be the player level or street cred???
  
  -- create and take random generated gang
  local gangInfo = Quest.gangs.GenerateGangWithRandomName({district.Name})
  gangIndex = #(Quest.gangs)
  gang = gangInfo.name
  
  local questContent = 'Target: ' .. gang .. ' in ' .. questLocation.name .. ', ' .. district.Name
  Quest.DisplayNewQuest(Quest.defaultQuestName, 'Kill Job', questContent)
  HUD.QuestMessage(questContent)
  
  -- remember quest location
  local points = Quest.targetHelper.GetRandomPointOnCircle(
    questLocation.x, 
    questLocation.y, 
    questLocation.z, 
    math.random(5, 10))
    
  table.insert(Quest.questLocations, {
    location = questLocation,
    gangName = gang,
    gangIndex = gangIndex,
    gangersCount = gangersCount,
    active = false,
    points = points,
    enemiesSpawned = false,
    questType = QuestTypes.Kill,
    districtName = district.Name,
    questReward = reward,
  })
  if #(Quest.questLocations) == nil then 
    print("Quest.Generate: Error adding quest location")
  else
    print("Quest.Generate: Quest location added")
  end
  Quest.targetMarker.UnmarkAll()
  local locationPosition = {
    x = points[1].x,
    y = points[1].y,
    z = questLocation.z,
  }
  Quest.MarkJobPosition(locationPosition)
  return Quest.questLocations[#Quest.questLocations]
end

function Quest.GetCurrentQuest()
  return Quest.questLocations[#Quest.questLocations]
end

function Quest.GetObjectiveDescription(questInfo)
  local jobType = QuestTypes.TypeToString(questInfo.questType)
  if jobType == QuestTypes.Kill then
    return 'Your mission is to eliminate ' .. tostring(questInfo.gangersCount) .. ' members of the gang ' .. Quest.gangs.data[questInfo.gangIndex].name .. ' in ' .. questInfo.questLocation.name .. ', ' .. questInfo.districtName
  elseif jobType == QuestTypes.Drive then
    return 'Your mission is to drive a client to this location:' .. questInfo.questLocation.name .. ' in ' .. questInfo.districtName
  elseif jobType == QuestTypes.Rescue then
    return 'Your mission is to rescue this person in ' .. questInfo.questLocation.name .. ' in ' .. questInfo.districtName
  elseif jobType == QuestTypes.Hack then
    return 'Your mission is to hacking the marked device in ' .. questInfo.questLocation.name .. ' in ' .. questInfo.districtName
  end
end

function Quest.GetActiveQuestForServer()
  local questInfo = Quest.GetCurrentQuest()
  if not questInfo then return nil end
  if not questInfo.active then return end
  local questName = QuestTypes.TypeToString(questInfo.questType)
  return {
    name = questName,
    objective = Quest.GetObjectiveDescription(questInfo)
  }
end

function Quest.OnLocationReachedKillJob()

end

function Quest.InitQuestLocationCheck()
  if GameSession.IsPaused() or GameSession.IsDead() or not GameSession.IsLoaded() then
    return
  end

  if Quest.done == true then
    if not Quest.reallyDone then
      Quest.reallyDone = true
      Quest.v.VSpeak("Job's done")
      Quest.DisplayDone()
    end
    return
  end

  local p = Quest.v.GetWorldPostion()
  if not p then return end
  -- local plyr = Game.GetPlayer()
  -- if not plyr then return end
  -- local p = plyr:GetWorldPosition()
  -- if not p then return end
  

  if Quest.questLocationIdx > 0 then
    local loc = Quest.questLocations[Quest.questLocationIdx].location
    local reachedLocation = Quest.targetHelper.InDistance(loc, p, Quest.questDesiredDistance)
    Quest.questLocationActive = reachedLocation
    loc.active = reachedLocation
    if not reachedLocation then
      Quest.questLocationIdx = 0
    end
  else
    local questMaxIdx = #(Quest.questLocations)
    -- check all quest distances
    if questMaxIdx == 0 then
      return
    end

    local questIdx = 1
    local questInfo = Quest.questLocations[questIdx]
    local questInfoLocation = questInfo.location
    local reachedLocation = Quest.targetHelper.InDistance(questInfoLocation, p, Quest.questDesiredDistance)

    

    -- print('dist' .. dist .. ' name: ' .. questInfoLocation.name)
    if reachedLocation then
      print('in distance')
      Quest.questLocationActive = true
      Quest.questLocationIdx = questIdx
      if questInfo.questType == QuestTypes.Kill then
        if not questInfoLocation.enemiesSpawned then
          questInfoLocation.enemiesSpawned = true
  
          -- REMOVE THIS IF MORE THAN 1 QUEST IS ACTIVE
          Quest.questLocations = {}
          Quest.questLocationActive = false
          Quest.questLocationIdx = 0
  
          local pIdx = #(questInfo.points)
          local gangInfo = Quest.gangs.GetRandomGang({'mox', 'aldecaldo'})
          
          Quest.MakeGangComment(gangInfo)
  
          local gangers = gangInfo.entities
          Quest.spawns = 0 
          for eIdx = 1, pIdx do
            -- track enemies in QuestEnemies
            -- if dead, reset and set quest location as tbr -> to be removed 
            local gangerNr = math.random(2, 10)
            while Quest.spawns < gangerNr do
              local ganger = gangers[math.random(1, #gangers)]
              if not Quest.SpawnEnemy(
                  ganger,             
                  questInfo.points[eIdx].x,
                  questInfo.points[eIdx].y,
                  questInfo.location.z
                ) then
                print('spawning didnt work')
              else
                Quest.spawns = Quest.spawns + 1
              end
            end
          end
        end
  
        Quest.MakeCompanionsAttackRandomEnemy()
      elseif questInfo.questType == QuestTypes.Drive then
        if not questInfoLocation.contractorSpawned then
          questInfoLocation.contractorSpawned = true
          
          -- REMOVE THIS IF MORE THAN 1 QUEST IS ACTIVE
          -- Quest.questLocations = {}
          -- Quest.questLocationActive = false
          -- Quest.questLocationIdx = 0

        end
      end
      
    else
      HUD.QuestMessage('Go to ' .. questInfoLocation.name .. ' in ' .. questInfo.districtName)
      questInfoLocation.active = false
    end
  end
end

function Quest.MakeGangComment(gangInfo)
  local gangerLine = math.random(0, 100)
  if gangerLine > 50 then
    local line = CyberV.VQuestRandomGangLine(gangInfo)  
    CyberV.VSpeak(line)
  else
    local line = CyberV.VQuestStartingRandomLine()
    CyberV.VSpeak(line)
  end
end

function Quest.MakeCompanionsAttackRandomEnemy()
  -- make companion attack enemies
  if CyberV.hasFollower and Quest.spawns > 1 then
    local randomTargetIdx = math.random(#Quest.enemies)
    local followers = Quest.aiControl.GetFollowers()
    for fidx = 1, #followers do
      if followers[fidx] then
        AIControl.MakeAggro(followers[fidx], Quest.enemies[randomTargetIdx])
      end
    end
  else
    print("Quest: cannot make companion aggro")
  end
end

function Quest.SetOnQuestDone(fn)
  if not fn or type(fn) ~= 'function' then
    print("Quest.SetOnQuestDone: Cannot set fn. fn is nil or not a function")
    return
  end
  Quest.onQuestDone = fn
end



function Quest.DisplayDone()
  if not Quest.journalNotificationQueue then
    print("No Quest.journalNotificationQueue found")
    return
  end
  local userData = QuestUpdateNotificationViewData.new()
  userData.text = 'Kill Job Completed'
  userData.title = "UI-Notifications-QuestCompleted"
  userData.canBeMerged = false
  userData.soundEvent = CName("QuestSuccessPopup")
  userData.soundAction = CName("OnOpen")
  userData.animation = CName("notification_quest_completed")
  userData.dontRemoveOnRequest = false
  
  
  local notificationData = gameuiGenericNotificationData.new()
  notificationData.time = 6.7
  notificationData.widgetLibraryItemName = CName('notification_quest_completed')
  notificationData.notificationData = userData
  Quest.journalNotificationQueue:AddNewNotificationData(notificationData)
	
end

function Quest.DisplayFail()
  if not Quest.journalNotificationQueue then
    print("No Quest.journalNotificationQueue found")
    return
  end
  local userData = QuestUpdateNotificationViewData.new()
  userData.text = 'Kill Job Failed'
  userData.title = "LocKey#27566"
  userData.canBeMerged = false
  userData.soundEvent = CName("QuestFailedPopup")
  userData.soundAction = CName("OnOpen")
  userData.animation = CName("notification_quest_failed")
  userData.dontRemoveOnRequest = false
  
  
  local notificationData = gameuiGenericNotificationData.new()
  notificationData.time = 6.7
  notificationData.widgetLibraryItemName = CName('notification_quest_failed')
  notificationData.notificationData = userData
  Quest.journalNotificationQueue:AddNewNotificationData(notificationData)
	
end

function Quest.DisplayNewQuest(questId, questTitle, questContent)
  if not Quest.journalNotificationQueue then
    print("No Quest.journalNotificationQueue found")
    return
  end
  
  local userData = QuestUpdateNotificationViewData.new()
  local newQuest = gameJournalQuest.new()
  
  newQuest.id = questId
  local questAction = TrackQuestNotificationAction.new()
  questAction.questEntry = questContent  
  questAction.eventDispatcher = Quest.journalNotificationQueue
  
  userData.title = questTitle
  userData.canBeMerged = false;
  userData.action = questAction
  userData.soundEvent = CName("QuestNewPopup")
  userData.soundAction = CName("OnOpen")
  userData.animation = CName("notification_new_quest_added")
  
  local notificationData = gameuiGenericNotificationData.new()
  notificationData.time = 6.7
  notificationData.widgetLibraryItemName = CName('notification_new_quest_added')
  notificationData.notificationData = userData
  Quest.journalNotificationQueue:AddNewNotificationData(notificationData)
end

function Quest.UpdateQuest(questId, questTitle, questContent)
  if not Quest.journalNotificationQueue then
    print("No Quest.journalNotificationQueue found")
    return
  end
  
  local userData = QuestUpdateNotificationViewData.new()
  local newQuest = gameJournalQuest.new()
  
  newQuest.id = questId
  local questAction = TrackQuestNotificationAction.new()
  questAction.questEntry = questContent  
  questAction.eventDispatcher = Quest.journalNotificationQueue
  
  userData.title = questTitle
  userData.canBeMerged = false;
  userData.action = questAction
  userData.soundEvent = CName("QuestNewPopup")
  userData.soundAction = CName("OnOpen")
  userData.animation = CName("notification_quest_updated")
  
  local notificationData = gameuiGenericNotificationData.new()
  notificationData.time = 8
  notificationData.widgetLibraryItemName = CName('notification_new_quest_added')
  notificationData.notificationData = userData
  Quest.journalNotificationQueue:AddNewNotificationData(notificationData)  
end
return Quest