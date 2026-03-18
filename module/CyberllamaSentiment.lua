local Menu = require('CyberllamaMenu')

CyberNPC.LLamaNPCRelationship = 40
CyberNPC.LLamaNPCFood = 50
CyberNPC.LLamaNPCHydration = 50
CyberNPC.LLamaNPCFun = 50
CyberNPC.LLamaNPCFriendThreshold = 40

CyberNPC.LLamaNPCLastAction = ''
CyberNPC.LLamaNPCLastMoodValue = ''
CyberNPC.LLamaNPCLastMoodExpression = ''
CyberNPC.LLamaNPCMoodExplanation = ''
CyberNPC.LLamaNPCVFollowIntent = false

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

CyberNPC.LLamaVIsKill = false
CyberNPC.LLamaVIsHide = false
CyberNPC.LLamaVIsMove = false
CyberNPC.LLamaVIsHold = false
CyberNPC.LLamaVIsFollow = false
CyberNPC.LLamaVIsGet = false
CyberNPC.LLamaVIsGetUp = false
CyberNPC.LLamaVIsQuest = false
CyberNPC.LLamaVIsMoney = false

CyberNPC.LastNPCTarget = {
    id = nil,
    record_id = nil,
    obj = nil,
    id_hash = '',
    record_id_hash = '',
    class_name = '',
    display_name = '',
    tweaks_name = '',
    appearance = ''
}


---@param targetPuppet ScriptedPuppet
function StopLookAt(targetPuppet)
  targetPuppet:GetStimReactionComponent():DeactiveLookAt(false)
end
  
---@param targetPuppet ScriptedPuppet
---@param lookAtPuppet ScriptedPuppet
---@param duration Float|nil
function NPCLookAt(targetPuppet, lookAtPuppet, duration)
  if not lookAtPuppet then
    lookAtPuppet = Game.GetPlayer()
  end
  if targetPuppet then
  --   Target:GetStimReactionComponent():ActivateReactionLookAt(lookAtPuppet, duration and true or false, false, duration,
  --     true)
  -- else
    targetPuppet:GetStimReactionComponent():ActivateReactionLookAt(lookAtPuppet, duration and true or false, false,
      duration, true)
  end
end
  
local Sentiment = {

}

return Sentiment