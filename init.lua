GameSession = require('module/GameSession')
GameUtils = require('module/GameUtils')
InteractionUI = require('module/interactionUI')
FaceExpression = require('module/FaceExpression')
-- CyberllamaSentiment = require('module/CyberllamaSentiment')
Subtitles = require('module/SubtitlesControl')
PhoneControl = require('module/PhoneControl')
MenuBase = require('module/MenuWrapper')
Menu = require('module/CyberllamaMenu')
Backend = require('module/CyberllamaBackendAPI')
CyberNPC = require('module/CyberNPC')
CyberV = require('module/CyberV')
AIControl = require('module/AIControl')
TryDecodeJson = require('module/TryDecodeJson')
TargetHelper = require('module/TargetHelper')
TargetMarker = require('module/TargetMarker')
Scanner = require('module/Scanner')
local Gangs = require('module/Gangs')
local Corpos = require('module/Corpos')
Locations = require('module/Locations')
local Quest = require('module/Quests')
HUD = require('module/HUD')
Cron = require('module/Cron')
local FastTravelMarks = require('module/FastTravelMarks')
local Districts = require('module/Districts')
FAsync  = require('module/FakeAsync')
Merc = require('module/Merc')
Sound = require('module/Sound')
Listener = require('module/Listener')
GameTimeUtils = require('module/GameTimeUtils')

-- JSON = (loadfile "module/JSON.lua")()
-- AMM = GetMod("AppearanceMenuMod")
Listener = {}

-- local cyberllama_running = false
STATE_KEY_OFF = 0
STATE_KEY_ON = 1
STATE_TALK_HTTP_LISTEN = 2
STATE_TALK_HTTP_LISTEN_DONE = 3
STATE_PROMPT_TALK_OFF = 0
STATE_PROMPT_TALK_ON = 5

REQ_STATE_OFF=0
REQ_STATE_ON=1

AI_MENU_OFF = 0
AI_MENU_ON = 6

REMEMBER_LOCATION_OFF=0
REMEMBER_LOCATION_ON=1
REMEMBER_LOCATION_STATE=REMEMBER_LOCATION_OFF
-- tracks wether the server is in use or not
-- good for checking async / syncs + if an npc is busy
CyberllamaServer = REQ_STATE_OFF

SpawnAnimus = {
  Neutral = 1,
  Friendly = 2,
  Enemy = 3,
  Psycho = 4,
}

-- Default
-- InCombat
-- OutOfCombat
-- Stealth
CCombatState = {
  Default = 0,
  InCombat = 1,
  OutOfCombat = 2,
  Stealth = 3
}

-- tracks the overall state. this was used before 
-- for tracking if the cyberllama server should be listening (whisper) or not
CyberllamaState = STATE_KEY_OFF

-- @type GameObject|ScriptedPuppet|nil
TargetId = 0

-- BORROWED FROM AMM => TODO: link as plugin to AMM such as the other NPCLookAt etc.
-- Write a thanks to all modders / dev involved (if you are reading this thx !! <3 )

STATE_DIALOG_LEVEL_MAIN = 0
STATE_DIALOG_LEVEL_EXPAND = 1
STATE_DIALOG_LEVEL_AWAIT_VLINES = 2
DialogState = STATE_DIALOG_LEVEL_MAIN
LLAMA_COMMENT_TOPICS = {"stats", "health", "location", "district", "smell"}


function MergeTables(table1, table2)
  local merged = {}

  for k, v in pairs(table1) do
      merged[k] = v
  end

  for k, v in pairs(table2) do
      merged[k] = v
  end

  return merged
end

-- register input
registerInput('ai_rec_on', 'AI Record Voice', function(keypress)
  -- input pressed
  -- if keypress and cyberllama_running == false then
  
  if keypress and CyberllamaState == STATE_KEY_OFF then
    CyberllamaState = STATE_KEY_ON   -- switch on    
    InteractionUI.hideHub()

    local target = AIControl.GetLookAtTarget()
    local player = Game.GetPlayer()    
    if target ~= nil and target and target:IsNPC() then
      CyberNPC.UpdateTargetInfo(target)
      print("move to for npc")
      local playerPos = player:GetWorldPosition()
      
      -- dont allow to talk to gangs... for now
      if CyberNPC.IsLastNPCGanger({'mox', 'aldecaldo'}) then
        CyberllamaState = AI_MENU_OFF
        local line = CyberV.VNotAllowedSpeakRandomLine()
        CyberV.VSpeak(line)
        return
      end

      -- since these npcs are sitting, there is no reason to take them out of their default position
      -- TODO: see the default prompt. handle this in a function
      CyberNPC.MakeEyesGlowGold(target)
      if CyberNPC.IsFixer() ~= true then
        AIControl.MoveTo(target, playerPos, 15, moveMovementType.Walk)
      end      
      Backend.Recstart(CyberV.GetPlayerInfoForServer(), CyberNPC.GetLastNPCTargetForServer(), CyberllamaResponse)
    end
  end
end)

registerInput('ai_rec_off', 'AI Record Stop', function(keypress)  
  -- input pressed
  -- if keypress and cyberllama_running == false then
  -- if keypress and CyberllamaState == STATE_TALK_HTTP_LISTEN_DONE then
  -- CyberllamaState = STATE_KEY_OFF -- switch on
  local pre_mood = { name = "Smile", idle = 6, category = 3 }
  
  FaceExpression.ActivateFacialExpression(CyberNPC.GetLastTarget(), pre_mood)
  Backend.Recstop(CyberV.GetPlayerInfoForServer(), CyberNPC.GetLastNPCTargetForServer(), 
  function(response)
    local content = Backend.GetJsonResponse(response)
    ResponseMain(content)
  end)
  -- CyberllamaRequestPrompt("recstop")
  -- end
end)

registerInput('store_location', 'Store location', function(keypress)
  -- PhoneControl.AddMessageByContactId("cyberllama_" .. FIXER_DISPLAY_NAME, "This is a test")
  PhoneControl.DebugMessages()
  if 1 == 1 then
    return
  end
  PhoneControl.SendMessageNotification(FIXER_CONTACT_ID, "THIS IS JUST DUMB", "THIS Is JUST A TEST LOL.")
  if 1 == 1 then return end
  if REMEMBER_LOCATION_STATE == REMEMBER_LOCATION_ON then
    return
  end
  REMEMBER_LOCATION_STATE = REMEMBER_LOCATION_ON
  
  local f = io.open("./custom-locations.json", "r")
	local lines = '[]'
  if f then
    lines = f:read("*a")
    print(lines)
    f:close()
  end
  local info = CyberV.GetPlayerInfoForServer()
  CyberV.VSpeak("Hmm. Gotta remember this place.")
  Backend.MakeTitle(
    '',
    '',
    info,
    CyberNPC.GetLastNPCTargetForServer(),
    function(response)
      local responseJson = Backend.GetJsonResponse(response) or {
        title = "Marked location"
      }
      local tableDis = json.decode(lines)

      table.insert(tableDis, {
        markerref = '#marked_location',
        name = responseJson.title,
        x = info.p_location.x,
        y = info.p_location.y,
        z = info.p_location.z,
        district_main = info.p_district.main,
        district_sub = info.p_district.sub or ''
      })

      CyberV.VSpeak("I'll just call it, uh ..." .. responseJson.title)
      HUD.QuestMessage("New Location: " .. responseJson.title .. " near " .. info.p_district.main)
      REMEMBER_LOCATION_STATE = REMEMBER_LOCATION_OFF
      local output = json.encode(tableDis)
      local fo = io.open("./custom-locations.json", "w+")
      if fo then
        fo:write(output)
        fo:close()
      end
    end
  )

end)



function StateIsIdle()
  return (CyberllamaState == STATE_PROMPT_TALK_OFF 
  or CyberllamaState == STATE_KEY_OFF 
  or CyberllamaState == AI_MENU_OFF)
end



registerInput('ai_menu_two', 'AI Menu Two', function(keypress)

  if keypress and StateIsIdle()
  and (CyberNPC.VIsNotInCombat()) then

    local target = AIControl.GetLookAtTarget()
    

    if target ~= nil and target and target:IsNPC() then
      
      if Menu.HasVLines() 
        and target
        and target == CyberNPC.GetLastTarget() then
        Menu.menu.ActivateMenu(Menu.DIALOG_VLINES)
        return
      end

      if not target then
        return
      end

      if not CyberNPC.IsTalkable(target)
        return
      end

      CyberNPC.UpdateTargetInfo(target)
      

      if not CyberNPC.IsTalkable() then
        InteractionUI.hideHub()
        CyberV.VSpeak(CyberV.VNotCloseToNPCRandomLine())
        return
      end
      
      MenuBase.startMessage = CyberNPC.LastNPCTarget.display_name

      if CyberNPC.LLamaNPCLastMoodExpression then
        FaceExpression.ActivateFacialExpression(CyberNPC.LastNPCTarget.obj, CyberNPC.LLamaNPCLastMoodExpression)
      else
        FaceExpression.Neutral(target)
      end
      CyberNPC.NPCStopAnimation()
      

      CyberllamaState = AI_MENU_ON
      print('AI_MENU_ON')
      DialogUseIntro = false
 
      if CyberNPC.IsCop() then
        Menu.menu.ActivateMenu(Menu.DIALOG_FIXER)
        CyberllamaState = AI_MENU_OFF
        return
      end

      -- dont allow talking to vendors... for now
      if CyberNPC.IsVendor() then
        CyberllamaState = AI_MENU_OFF
        HideDialogMenu(target)
        return
      end

      if CyberNPC.IsNotTargetable() then
        CyberllamaState = AI_MENU_OFF
        HideDialogMenu(target)
        return
      end

      -- dont allow talking to gangs... for now
      if CyberNPC.IsLastNPCGanger({'mox', 'aldecaldo', 'cyberpunk' }) then
        CyberllamaState = AI_MENU_OFF
        CyberV.VSpeak(CyberV.VNotAllowedSpeakRandomLine())
        -- added this line below. wasnt there before. needs testing
        HideDialogMenu(target)
        return
      end
 
      -- since these npcs are sitting, there is no reason to take them out of their default position
      -- it'd be nice to expand this by getting the current npc pose (wether its sitting etc.)
      if CyberNPC.IsFixer() then
        Menu.menu.ActivateMenu(Menu.DIALOG_FIXER)
        CyberV.VSpeak(CyberV.VConversationStartingLinesRandomLine())
        CyberllamaState = AI_MENU_OFF
        return
      else
        CyberNPC.NPCLookAtPlayer(60)
        -- AIControl.MoveTo(target, playerPos, 15, moveMovementType.Walk)
      end

      if CyberNPC.IsAFriend() then
        if CyberNPC.IsResident() then
          DialogUseIntro = true
        else
          CyberNPC.NPCLookAtPlayer(60)
          if AIControl.IsFollower(target) then
            Menu.menu.ActivateMenu(Menu.DIALOG_FOLLOWER_SUB_MAIN)            
            CyberV.VSpeak(CyberV.VConversationStartingLinesRandomLine())
          else
            Menu.menu.ActivateMenu(Menu.DIALOG_FRIEND)
            CyberV.VSpeak(CyberV.VConversationStartingLinesRandomLine())
          end
          CyberllamaState = AI_MENU_OFF
          return
        end
      end
      
      -- nc residents (without a name) have different dialogue lines
      if CyberNPC.IsResident() then
        DialogUseIntro = true
      end
      
      target:EnableInteraction('GenericTalk', false)
      -- AIControl.NPCLookAt(target, player, 60)
      
      local line = CyberV.VConversationStartingLinesRandomLine()
      local yesNo = math.random(100) + CyberV.RollChanceBenefitsBasedOnLifePath(100)
      local lineWaitTime = Subtitles.CalcTimeOfString(line)+3
      CyberNPC.NPCLookAtPlayer(lineWaitTime)
      CyberV.VSpeak(line)
      
      if yesNo > 60 then
        Cron.After(lineWaitTime, function()
          local yesLine = CyberNPC.NPCReplyIntroAffirmativeLinesRandomLines()
          local yesLineWaitTime = Subtitles.CalcTimeOfString(line)
          CyberNPC.NPCSpeakLast(yesLine)
          
          Cron.After(yesLineWaitTime, function()
            CyberNPC.NPCStartAnimation(CyberNPC.NPCAnimationStandRandomAnimation())
          end)
          if DialogUseIntro then    
            Menu.menu.ActivateMenu(Menu.DIALOG_NPC_INTRO)
            CyberllamaState = AI_MENU_OFF
          else
            Menu.menu.ActivateMenu(Menu.DIALOG_MAIN)
            CyberllamaState = AI_MENU_OFF
          end
        end)
      else
        Cron.After(lineWaitTime, function()
          local lifepath = GameUtils.GetLifePath(Game.GetPlayer())
          CyberNPC.NPCSpeakLast(CyberNPC.NPCReplyIntroNegativeLinesRandomLines(lifepath))
          CyberllamaState = AI_MENU_OFF
        end)
      end
    end
  end
end)


NPCOnCallTimer = nil

-- this one is for waiting for a friend
function NPCFriendCheckSpawn(lastContact, districtAndLocation)
  print("NPCOnCallTimer")
  if not lastContact then
    print("NPCOnCallTimer: last contact is nil")
  end
  if CyberV.IsInCombat() then
    return
  end
  if lastContact.dismissed then
    print("NPCOnCallTimer: last contact was dismissed")
    TargetMarker.UnmarkLastByTag(
      "friend"
    )
    Cron.Halt(NPCOnCallTimer)
    NPCOnCallTimer = nil
    return
  end
  if (lastContact.spawned and 
    lastContact.display_name_changed == Scanner.NPCOnCallState.NPCScanned) then
    Cron.Halt(NPCOnCallTimer)
    -- NPCOnCallTimer = nil
  end
  if CyberV.hasFollower == true then
    print("V has a follower already")
    return
  end
  -- this is set through the scanner     
  if lastContact.display_name_changed == Scanner.NPCOnCallState.NPCNeedsScan then
    HUD.QuestMessage("Scan " .. lastContact.display_name)
    return
  end

  if TargetHelper.InDistance(
    CyberV.GetPlayerPos(),
    districtAndLocation.location,
    CyberNPC.SpawnNearDistance) then
    CyberV.TimePasses()
    local yourFriend = CyberNPC.SpawnNPC(
      districtAndLocation.location,
      CyberNPC.LastNPCTarget.tweaks_db_name,
      lastContact.appearance,
      SpawnAnimus.Friendly,
      Merc.GetRandomWeapon()
    )
    lastContact.spawned = yourFriend
    CyberV.hasFollower = true
    if lastContact.spawned then
      lastContact.display_name_changed = Scanner.NPCOnCallState.NPCNeedsScan
      lastContact.record_id_to_scan = CyberNPC.LastNPCTarget.record_id_hash 
      CyberV.VSpeak(CyberV.VGreetingsRandomLine(lastContact.display_name:match("^%S+")))
      
    end
    CyberV.StopCloseEyes()
    CyberV.BlinkFast()
    -- THIS IS NEW AND UNTESTED. GET RID OF THIS IF SOMETHING HORRIBLE HAPPENS
    Cron.Halt(NPCOnCallTimer)
    NPCOnCallTimer = nil
    

    TargetMarker.UnmarkLastByTag("friend")
  else
    HUD.QuestMessage("Meet " .. lastContact.display_name .. " in " .. districtAndLocation.location.name)
  end
end

function NPCOnCall()
  print("NPCOnCall")
  print(PhoneControl.cachedSelectedContactIdx)  

  if AIControl.HasFollowers() then
    print("Cannot call. Has followers")
    CyberV.VSpeak("Can't do. I'm not alone right now")
    return
  end
  if NPCOnCallTimer then
    CyberV.VSpeak("Can't do. I'm meeting someone")
    return
  end
  if PhoneControl.cachedSelectedContactIdx and 
  PhoneControl.cachedSelectedContactIdx ~= 0 and
    PhoneControl.contacts[PhoneControl.cachedSelectedContactIdx].display_name_changed and
    PhoneControl.contacts[PhoneControl.cachedSelectedContactIdx].display_name_changed == Scanner.NPCOnCallState.NPCScanned then
      -- local contact = CyberNPC.GetCachedNPCTargetByDisplayName(PhoneControl.contacts[PhoneControl.cachedSelectedContactIdx].contact.display_name)
      -- if contact then
      
      CyberV.VSpeak("I got company already.")
      -- end
    return
  end

  -- check if npc is in distance. if so ... do not call and instead make a comment like 'you dont have to call me. im here'
  local lastContact = PhoneControl.GetSelectedContactData()
  if not lastContact then
    return
  end

  if lastContact.spawned then    
    CyberNPC.NPCSpeak("Why are you calling me? I'm here", lastContact.id_hash, lastContact.display_name)
    return
  end

  if lastContact.obj and TargetHelper.InDistance(Game.GetPlayer(), lastContact.obj, 30) then
    CyberNPC.NPCSpeak("No need. I'm here", lastContact.id_hash, lastContact.display_name)
    return
  end

  local districtAndLocation = FastTravelMarks.GetRandomLocationInRandomDistrict()
  local message = CyberNPC.NPCMeetCallRandomLine(districtAndLocation.location.name, tostring(districtAndLocation.district.Name))
  local messageWaitTime = Subtitles.CalcTimeOfString(message)
  CyberNPC.NPCSpeak(message, lastContact.id_hash, lastContact.display_name)
  Cron.After(messageWaitTime, function()
    local imInMsg = "Sorry for hanging up on you! Sent you the address. " .. "I'm in " .. districtAndLocation.location.name .. ' in ' .. tostring(districtAndLocation.district.Name)
    PhoneControl.AddContactMessage(PHONE_CONTROL_PREFIX .. lastContact.display_name, imInMsg)
    PhoneControl.SendMessageNotification(lastContact.display_name, lastContact.display_name, imInMsg)
  end)
  
  lastContact.dismissed = false
  -- v_car_villefort_alvarado_door_close

  if NPCOnCallTimer then
    Cron.Halt(NPCOnCallTimer)
    NPCOnCallTimer = nil    
    
    TargetMarker.UnmarkLastByTag("friend")
  end
  
      
  NPCOnCallTimer = Cron.Every(30, function() 
    NPCFriendCheckSpawn(lastContact, districtAndLocation)
  end, {})
  
  TargetMarker.UnmarkLastByTag("friend")
  TargetMarker.Mark(
    districtAndLocation.asVector4, 
    Enum.new('gamedataMappinVariant', "CustomPositionVariant"),
    "friend",
    true
  )
end


FIXER_HOTLINE_JOB_IDLE = 0
FIXER_HOTLINE_JOB_STARTED = 1
FIXER_HOTLINE_JOB_DONE = 2
FIXER_HOTLINE_JOB_FAILED = 3
FIXER_HOTLINE_STATE = FIXER_HOTLINE_JOB_IDLE
FIXER_DISPLAY_NAME = ''
PHONE_CONTROL_PREFIX = 'cyberllama_'
FIXER_GENDER = ''
FIXER_CONTACT_ID = 'fixer_hotline'

FIXER_NPC_DATA = {
  id_hash = FIXER_CONTACT_ID,
  record_id_hash = FIXER_CONTACT_ID,
  class_name = FIXER_CONTACT_ID,
  display_name = 'Fixer Hotline',
  tweaks_name = 'Fixer',
  appearance = '_nightcity_fixer',
  gender = FIXER_GENDER
}
FIXER_NPC_ENTITY_INFO = nil
-- adds fixer as an npc in cyberllama
function NPCFixerHotlineInit()
  FIXER_NPC_ENTITY_INFO = Gangs.RandomCyberpunkInfo()
  if string.match(FIXER_NPC_ENTITY_INFO.entity_entname, 'woman') then
    FIXER_GENDER = 'wa'
    FIXER_DISPLAY_NAME = CyberNPC.NPCRandomFemaleNickname()
  else
    FIXER_GENDER = 'ma'
    FIXER_DISPLAY_NAME = CyberNPC.NPCRandomMaleNickname()
  end
  FIXER_NPC_DATA.gender = FIXER_GENDER
  FIXER_NPC_DATA.tweaks_name = FIXER_NPC_ENTITY_INFO.entity_tweak

  FIXER_NPC_DATA.appearance = ''
  FIXER_DISPLAY_NAME = 'Fixer ' .. FIXER_DISPLAY_NAME
  FIXER_NPC_DATA.display_name = FIXER_DISPLAY_NAME
  
  print("Add contact")
  PhoneControl.AddContact({
    id = PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME,
    display_name = FIXER_DISPLAY_NAME,
  },
  'PhoneAvatars.Avatar_Unknown',
  'Bounty Fixer')
  PhoneControl.SendMessageNotification(PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME, FIXER_DISPLAY_NAME, 'Hey V, it\'s me. Check your messages')
  PhoneControl.AddContactMessage(PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME, 'Hey V, if you are seeing this: Ring on the holo if you are looking for some juicy jobs')
  PhoneControl.SetOnCallTaken(NPCOnCallFixerHotline, FIXER_DISPLAY_NAME)
end

function NPCOnCallFixerHotline()
  print("NPCOnCallFixerHotline")
  if FIXER_HOTLINE_STATE == FIXER_HOTLINE_JOB_DONE then
    print("FIXER_HOTLINE_JOB_DONE")
    FIXER_HOTLINE_STATE = FIXER_HOTLINE_JOB_IDLE
    print("FIXER_HOTLINE_JOB_IDLE")
  end
  if FIXER_HOTLINE_STATE == FIXER_HOTLINE_JOB_IDLE then
    print("FIXER_HOTLINE_JOB_IDLE")
    FIXER_HOTLINE_STATE = FIXER_HOTLINE_JOB_STARTED
  end
  if FIXER_HOTLINE_STATE == FIXER_HOTLINE_JOB_STARTED or FIXER_HOTLINE_STATE == FIXER_HOTLINE_JOB_IDLE then
    print("FIXER_HOTLINE_JOB_STARTED")
    -- #Quest.locations > 0 added for checking if there is a location set for a job
    if Quest.done and #Quest.locations > 0 then
      FIXER_HOTLINE_STATE = FIXER_HOTLINE_JOB_DONE
      print("FIXER_HOTLINE_JOB_DONE")
      CyberV.VSpeak('Hey! The job is done. Send you the details')
      return
    else
      local prefix = ""
      if Merc.AnyMercDied() then
        prefix = CyberNPC.NPCMercDiesQuestLinesRandomLine()
      end
      local line = CyberNPC.NPCQuestGreetingLinesRandomLine()
      CyberNPC.NPCSpeakExtended(prefix .. line, FIXER_NPC_DATA.id_hash, FIXER_NPC_DATA.display_name, FIXER_NPC_DATA)
      local waitTime = Subtitles.CalcTimeByLetter(#line + #prefix, 0.1)
      Cron.After(waitTime , function()
        Menu.menu.ActivateMenu(Menu.DIALOG_FIXER_QUEST)        
      end, {})
    end
  end
  if FIXER_HOTLINE_STATE == FIXER_HOTLINE_JOB_FAILED then
    FIXER_HOTLINE_STATE = FIXER_HOTLINE_JOB_DONE
    CyberV.VSpeak('I\'m sorry. I failed the job')
    return
  end
end


function Quest_OnQuestDone()
  FIXER_HOTLINE_STATE = FIXER_HOTLINE_JOB_DONE
end

function HideDialogMenu(target)
  if target and target:IsNPC() then
    target:EnableInteraction('GenericTalk', false)
  end
  InteractionUI.hideHub()
  Cron.After(DialogAutoHideCooldown, function()
    InteractionUI.hideHub()

    local after_mood = { name = "Neutral", idle = 2, category = 2 }
    if target and target:IsNPC() then
        FaceExpression.ActivateFacialExpression(target, after_mood)
    end
    CyberllamaState = AI_MENU_OFF
  end, {})
end

registerForEvent('onUpdate', function(delta)
  Cron.Update(delta)
  InteractionUI.update()
end)

function ResponseNPCMakeExpression(content)
    if content.expression then
        CyberNPC.LLamaNPCLastMoodExpression = content.expression
        FaceExpression.ActivateFacialExpression(CyberNPC.LastNPCTarget.obj, CyberNPC.LLamaNPCLastMoodExpression)
    else
        CyberNPC.LLamaNPCLastMoodExpression = ''
    end
end

function ResponseNPCMakeMoodIfPossible(content)
    if content.mood then
        CyberNPC.LLamaNPCLastMoodValue = content.mood
        CyberNPC.NPCUpdateMood(content.food, content.hydration, content.fun, content.relationship)  
        CyberNPC.NPCDisplayMood(CyberNPC.LastNPCTarget)
    else
        CyberNPC.LLamaNPCLastMoodValue = '0'
    end
end

function ResponseUpdateIntentions(content)
  CyberV.UpdateIntentions(content)
  CyberNPC.UpdateIntentions(content)
end

function ResponseNPCMakeFollowIfIntention(target)
    if CyberNPC.LLamaNPCIsMove or CyberNPC.LLamaNPCIsFollow then
        -- just for testing
        if CyberNPC.LLamaNPCRelationship > CyberNPC.LLamaNPCFriendThreshold then
            print("attempting to make npc follow")
            if target then
              CyberNPC.UpdateTargetInfo(target)
              local currentRole = target:GetAIControllerComponent():GetAIRole()
              if currentRole and currentRole:IsA('AIFollowerRole') then
                  -- no need to to do anything
              else
                  print(CyberNPC.LastNPCTarget.record_id)
                  print(CyberNPC.LastNPCTarget.appearance)
                  if CyberNPC.IsResident() then
                    local friend = nil
                    if friend then
                        HUD.QuestMessage('Scan the person')
                        AIControl.DeleteTarget(target)
                        target = nil
                        CyberNPC.UpdateTargetInfo(friend)
                        AIControl.MakeFollower(friend, moveMovementType.Sprint)
                        HUD.QuestMessage(CyberNPC.LastNPCTarget.display_name .. ' now follows you')
                    else
                      AIControl.MakeFollower(target, moveMovementType.Sprint)
                      HUD.QuestMessage(CyberNPC.LastNPCTarget.display_name .. ' follows you for a bit')
                    end
                  else
                      AIControl.MakeFollower(target, moveMovementType.Sprint)
                      HUD.QuestMessage(CyberNPC.LastNPCTarget.display_name .. ' now follows you')
                  end
              end
            else
                target = CyberNPC.GetLastTarget()
                if target then
                    AIControl.MakeFollower(target, moveMovementType.Sprint)
                    HUD.QuestMessage(CyberNPC.LastNPCTarget.display_name .. ' now follows you')
                end
            end
        end
    end
end



function PlayerOnCombatStateChanged(combatState)
    print(combatState)

    -- track last combat duration
    local gt = GetGameTime()
    if combatState ~= CCombatState.InCombat and CyberNPC.LastCombatState == CCombatState.InCombat and CyberNPC.LastCombatStateTime then
      CyberNPC.LastActualCombatTime = gt
      CyberNPC.LastActualCombatDuration = SecondsToGameTime(
        DiffGameTimeInSeconds(gt, CyberNPC.LastActualCombatTime)
      )
    else
      if combatState == CCombatState.InCombat then
        CyberV.VSpeak(CyberV.VEnterCombatRandomLine())
      end
    end
    print("Combat state changed")
    CyberNPC.LastCombatState = combatState
    -- used here for not allowing prompt calls if in combat
    Backend.combatState = combatState
    CyberNPC.LastCombatStateTime = gt
end

-- Matches followers in AIControl with CyberNPC CachedLastNPCTargets. Stupid, I know, it should be one map (by id hash or display name)
function GetCyberNPCFollowers()
  local followers = AIControl.GetFollowers()
  local res = {}
  for i = 1, #followers do
    local followerInfo = CyberNPC.PeekTargetInfo(followers[i])
    if followerInfo then
      for j = 1, #CyberNPC.CachedLastNPCTargets do
        if CyberNPC.CachedLastNPCTargets[j].id_hash == followerInfo.id_hash then
          print("FOUND FOLLOWER")
          table.insert(res, CyberNPC.CachedLastNPCTargets[j])
        end
      end
    else
      print("followerInfo not found")
    end

  end
  return res
end

function MakeComment()
  print("MakeComment")
  if GameSession.IsDead() or GameSession.IsPaused() or GameSession.IsBlurred() or not GameSession.IsLoaded() then
    return
  end
  
  -- take the first follower
  local followerInfo = GetCyberNPCFollowers()
  local mercs = Merc.GetMercsAvailable()
  if #followerInfo == 0 and #mercs == 0 then
    print("MakeComment: no followers or mercs")
    return
  end

  if Locations.MakeCommentCooldownTimes > 1 then
      Locations.MakeCommentCooldownTimes = Locations.MakeCommentCooldownTimes - 1
      if Locations.MakeCommentCooldownTimes < 0 then
        Locations.MakeCommentCooldownTimes = 0
      end
      return
  end
  

  local r = math.random(90, 100)
  print("MakeComment chance roll: " .. tostring(r))
  if r > 50 
  and not CyberV.IsInCombat()
  and CyberNPC.IsTalkable() then
  -- and TargetHelper.InDistance(Game.GetPlayer(), CyberNPC.LastNPCTarget.obj, AIControl.TalkingDistance+20)) then
      if CyberNPC.IsThirsty() then
        CyberNPC.NPCSpeakLast(CyberNPC.NPCHydrationNotOkLinesRandomLines())
        return
      end
      if CyberNPC.IsHungry() then
        CyberNPC.NPCSpeakLast(CyberNPC.NPCFoodNotOkLinesRandomLines())
        return
      end

      if CyberV.InACar() and GameUtils.GetVehicleSpeed(CyberV.GetCar()) > 90 then
          CyberNPC.NPCSpeakLast(CyberNPC.NPCTooFastLinesRandomLines())
          return
      end
    
      local topic = LLAMA_COMMENT_TOPICS[math.random(#LLAMA_COMMENT_TOPICS)]
      print("MakeComment topic: " .. topic)
      
      if topic == 'location' then
        if Locations.LocationMakeAComment and #Locations.lastLocation > 0 then
            Locations.MakeCommentCooldownTimes = Locations.MakeCommentCooldownTimes + 1
            Backend.Comment(
              'location',
              Locations.lastLocation, 
              CyberV.GetPlayerInfoForServer(), 
              CyberNPC.GetLastNPCTargetForServer(), 
              function(response)
                print(response)
                local content = Backend.GetJsonResponse(response)
                if content and content.text and #content.text > 0 then
                  CyberNPC.NPCSpeakLast(content.text)
                end
            end)
        end
      elseif topic == 'smell' and CyberNPC.LastNPCTarget.obj then
        CyberNPC.NPCSpeakLast(CyberV.VRandomSmellLine())
      else
        Backend.Comment(
          topic,
          '',
          CyberV.GetPlayerInfoForServer(),
          CyberNPC.GetLastNPCTargetForServer(),
          function(response)
            print(response)
            local content = Backend.GetJsonResponse(response)
            if content and content.text and #content.text > 0 then
              CyberNPC.NPCSpeakLast(content.text)
            end
          end
        )
      end
  else          
  end
end

function InitRoutineCheck()
    Cron.Every(Locations.UpdateLocationChangedInSeconds, Locations.UpdateLocationChanged)
    Cron.Every(Locations.MakeCommentCronInSeconds, MakeComment, {})
    Cron.Every(CyberNPC.NeedsCheckLoopInSeconds, CyberNPC.NeedsCheckLoop, {})
    -- Cron.Every(FastTravelMarks.LocationGeneratorLoopInSeconds, FastTravelMarks.GenerateCustom, {})
end

registerForEvent('onInit', function()

    print("CyberLlama")
    Cron.Dispose()
    FAsync.Init(Cron)
    Backend.Init(FAsync)
    InteractionUI.init()    
    Subtitles.Init(Cron)
    PhoneControl.Init(JSON)
    PhoneControl.SetOnCallTaken(NPCOnCall, nil)
    FaceExpression.Init(Cron)
    CyberNPC.Init(GameUtils, Backend, PhoneControl, HUD, AIControl, Subtitles, FaceExpression, Cron)
    CyberV.Init(GameSession, GameUtils, Backend, Locations, CyberNPC, Subtitles)
    MenuBase.Init(InteractionUI, Subtitles)
    Districts.Init(TryDecodeJson)
    Locations.Dispose()
    Locations.Init()

    
    FastTravelMarks.Init(Districts.data, Backend, CyberNPC, CyberV, TryDecodeJson)
    Gangs.Init(TryDecodeJson)
    Quest.Init(
      FastTravelMarks,
      Locations,
      TargetHelper,
      TargetMarker,
      Gangs,
      HUD,
      Cron,
      CyberV,
      CyberNPC,
      AIControl,
      PhoneControl
    )
    CyberV.InjectGetActiveQuest(Quest.GetActiveQuestForServer)

    Merc.Init(
      CyberV,
      CyberNPC,
      Gangs,
      FastTravelMarks,
      TargetHelper,
      TargetMarker,
      HUD, 
      Cron)
      
    Menu.Init(
      MenuBase,
      Cron,
      InteractionUI,
      Subtitles,
      AIControl,
      FaceExpression,
      Quest,
      PhoneControl,
      HUD,
      Backend,
      CyberV.GetPlayerInfoForServer, 
      CyberNPC.GetLastNPCTargetForServer,
      CyberV,
      CyberNPC,
      Merc,
      Sound,
      CyberllamaResponse,
      function(err)

      end
    )
    Scanner.Init()
    
    Cron.Every(Quest.questLocationsCheckInterval, Quest.InitQuestLocationCheck, nil)

    Backend.Reset(
      CyberV.GetPlayerInfoForServer(), 
      CyberNPC.GetLastNPCTargetForServer(),
      function(response)
        -- CyberllamaResponse(response, 'none', 'reset')
        NPCFixerHotlineInit()
        Backend.NPCSync(
            CyberV.GetPlayerInfoForServer(),
            FIXER_NPC_DATA,
            function(r)
            end
        )
      end
    )
    InitRoutineCheck()

    Observe('PlayerPuppet', 'OnCombatStateChanged', function(self, combatState)
      PlayerOnCombatStateChanged(combatState)
    end)

    Observe("FullscreenVendorGameController", "BuyItem", function(this, item, quantity)
      print(item.value)
      if item.value == "Edible" and CyberV.hasFollower then
        CyberNPC.LLamaNPCFood = CyberNPC.LLamaNPCFood + (CyberNPC.LLamaNPCFood/100 * math.random(quantity))        
        CyberNPC.NPCDisplayMood()

      end
    end)

    GameSession.OnStart(function()
        -- Triggered once the load is complete and the player is in the game
        -- (after the loading screen for "Load Game" or "New Game")
        
        PhoneControl.Dispose()
        Backend.Reset(
          CyberV.GetPlayerInfoForServer(), 
          CyberNPC.GetLastNPCTargetForServer(),
          function(response)
            CyberllamaResponse(response, 'none', 'reset')
            CyberllamaPromptArgs = GameSession.GetKey()
            NPCFixerHotlineInit()
            Backend.NPCSync(
                CyberV.GetPlayerInfoForServer(),
                FIXER_NPC_DATA,
                function(r)
                end
            )
            Subtitles.Init(Cron)
            Merc.Dispose()
            AIControl.Dispose(true)
            Quest.Dispose()
            TargetMarker.UnmarkAll()
            
            Locations.Dispose()
            Locations.locationChangedObservers:Add(Merc.OnLocationChanged)
            Locations.locationTimeObservers:Add(Merc.OnSameLocationTimeChanged)
          end
        )

    end)

    GameSession.OnEnd(function()
        -- Triggered once the current game session has ended
        -- (when "Load Game" or "Exit to Main Menu" selected)        
        TargetMarker.UnmarkAll()
        AIControl.Dispose() 
        Quest.Dispose()
        Merc.Dispose()
        PhoneControl.Dispose()
        print('Game Session Ended')
    end)

end)

function Shutdown(target)
  CyberllamaServer = REQ_STATE_OFF
  CyberllamaState = STATE_KEY_OFF
  if target and target:IsNPC() then
    AIControl.StopLookAt(target)
    GameObjectEffectHelper.StopEffectEvent(target, "eye_glow_gold")  
  end
end

function CyberllamaResponseConvertContent(content)
  content.feedingVLines = content.state == 'PROMPT_TTS_PLAYER_FEED'
  content.feedingNPCLines = content.state == 'PROMPT_TTS_NPC_FEED'
  content.feedingDone = content.state == 'PROMPT_DONE'
  content.noActions = not content.actions or #content.actions == 0
  content.hasVSubtitles = content.v_subtitles ~= nil
  content.hasNPCSubtitles = content.npc_subtitles ~= nil
  content.vLinesWrongState = content.feedingNPCLines and content.hasVSubtitles
  content.npcLinesWrongState = content.feedingVLines and content.hasNPCSubtitles
  content.npcInteractionDuration = 0
  if content.hasNPCSubtitles then
    content.npcInteractionDuration = Subtitles.CalcTimeOfString(content.npc_subtitles)
  end 
  content.vInteractionDuration = 0
  if content.hasVSubtitles then
    content.vInteractionDuration = Subtitles.CalcTimeOfString(content.v_subtitles)
  end
  return content
end

function CyberllamaResponse(content, menu, text)
  content = CyberllamaResponseConvertContent(content)
  ResponseMain(content)
end

function ResponseMakeLoopResponse(playerInfo, npcInfo, content)
    print("ResponseMakeLoopResponse")
    if not CyberNPC.IsTalkable() then
      CyberV.VSpeak(CyberV.VNotCloseToNPCRandomLine())
      InteractionUI.hideHub()
      Backend.PromptContinue(
        'Nevermind',
        '',
        playerInfo,
        npcInfo,
        function(response)
          local content = Backend.GetJsonResponse(response)
          if content then
            CyberllamaResponse(content, '', '')
          else
            print("no content given")
          end
        end
      )
      return
    end

    HUD.QuestMessage("...")
    Backend.PromptContinue(
      '',
      '',
      playerInfo,
      npcInfo,
      function(response)
        local content = Backend.GetJsonResponse(response)
        if content then
          CyberllamaResponse(content, '', '')
        else
          print("no content given")
        end
      end
    )
end

function ResponseNPCMakeDialogAnimation(content)
  local roundTrip = Backend.promptContinueRoundTripInSec
  Cron.After(roundTrip, function()
    if not CyberNPC.InACar() and not Merc.IsAMerc(CyberNPC.LastNPCTarget.obj) then
      local animWait = Subtitles.CalcTimeOfString(content.npc_subtitles)
      if CyberNPC.LastNPCTarget.is_smoker and math.random(10) > 5 then
        CyberNPC.NPCStartAnimation(CyberNPC.LastNPCTarget.obj, CyberNPC.NPCRandomSmokeReactionAnimation(), animWait)
      else
        CyberNPC.NPCStartAnimation(CyberNPC.LastNPCTarget.obj, CyberNPC.NPCAnimationStandRandomAnimation(), animWait)
      end
    end
  end, {})
end


function ResponseMain(content)
  local lastNPCInfo = CyberNPC.GetLastNPCTargetForServer()
  local playerInfo = CyberV.GetPlayerInfoForServer()
  
  if not CyberNPC.IsTalkable() then
    HUD.Warning("Not in talk distance")
    return
  end
  
  ResponseUpdateIntentions(content)
  ResponseNPCMakeFollowIfIntention(CyberNPC.GetLastTarget())
  ResponseNPCMakeMoodIfPossible(content)
  ResponseNPCMakeExpression(content)

  if not CyberNPC.GetLastTarget() then
    print("ResponseMakeVLines: no target or no player")
    return
  end
  
  -- this part is only if a dialog has a continuation
  if not content.state then
    return
  end
  if content.hasNPCSubtitles then
    HUD.QuestMessage(lastNPCInfo.display_name .. " is thinking ...")
  end
  -- print("TTS FEEDING LINES ENGAGED")
  -- print(content.state)
  -- print("v_subtitles")
  -- print(content.v_subtitles)
  -- print("npc_subtitles")
  -- print(content.npc_subtitles)

  if content.hasVSubtitles then
    print(content.v_subtitles)
    CyberV.VSpeak(content.v_subtitles)
  end
  if content.hasNPCSubtitles then
    if content.hasVSubtitles then
      Cron.After(content.vInteractionDuration, function()
        CyberNPC.NPCSpeak(
          content.npc_subtitles,
          lastNPCInfo.id_hash, 
          lastNPCInfo.display_name
        )
      end)
    else
      CyberNPC.NPCSpeak(
        content.npc_subtitles,
        lastNPCInfo.id_hash, 
        lastNPCInfo.display_name
      )
      ResponseNPCMakeDialogAnimation(content.state)
    end
  end
  
  local interactionToUse = 1
  if content.hasNPCSubtitles or content.state == 'PROMPT_TTS_NPC_FEED' then
    interactionToUse = content.npcInteractionDuration
  elseif content.hasVSubtitles then
    interactionToUse = content.vInteractionDuration
  end

  NPCComeNearIfTooFarAway(interactionToUse)
  Cron.After(interactionToUse, function()
    if not content.feedingDone then
      ResponseMakeLoopResponse(playerInfo, lastNPCInfo, content)
    end
    if content.actions and #(content.actions) > 0 then
      if content.hasNPCSubtitles then
        Cron.After(content.npcInteractionDuration, function()
          CyberllamaVLines(content.actions)
        end)
      else
        CyberllamaVLines(content.actions)
      end      
    end
  end)

  if CyberNPC.GetLastTarget() then
    CyberNPC.StopMakeEyesGlowGold(CyberNPC.GetLastTarget())
    Shutdown(CyberNPC.GetLastTarget())
  else
    print('ResponseMakeVLines: StopMakeEyesGlowGold: target is nil')
  end
end



function NPCComeNearIfTooFarAway(lookTime)
  if not CyberNPC.IsTalkable() then
    -- makes the npc stop?
    CyberNPC.MoveToPlayer()
    CyberNPC.NPCLookAtPlayer(lookTime)
    return
  end
end

function CyberllamaVLines(vDialogLines)
  if not vDialogLines or #vDialogLines == 0  then
    return
  end
  Menu.InjectVLines(vDialogLines, CyberNPC, CyberV)
  if CyberNPC.IsTalkable() then    
    Menu.menu.ActivateMenu(Menu.DIALOG_VLINES)
  end
end
-- 
DES = nil
function GetDES()
  if not DES then
    DES = Game.GetDynamicEntitySystem()
  end
  return DES
end

SpawnNPCCron = nil
SpawnNPCTick = 0
