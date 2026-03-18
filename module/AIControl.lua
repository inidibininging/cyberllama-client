local TargetHelper = require('TargetHelper')

local AIControl = {
	followers = {}
}

local followTimer = 0.0
local followInterval = 5.0

local queues = {}
local queueTimer = 0.0
local queueInterval = 0.02

AIControl.TalkingDistance = 20
AIControl.TalkingDistanceFar = 40

function AIControl.GetFollowers()
	return AIControl.followers
end

function AIControl.HasFollowers()	
    if AIControl.followers and #(AIControl.followers) > 0 then
        return true
    end
	return false
end

function AIControl.ActivateFacialExpression(target, face)
	Tools.activatedFace = true

	local stimComp = target.obj:FindComponentByName("ReactionManager")
	local animComp = target.obj:FindComponentByName("AnimationControllerComponent")

	if stimComp and animComp then
		stimComp:ResetFacial(0)

		Cron.After(0.5, function()
		local animFeat = NewObject("handle:AnimFeature_FacialReaction")
		animFeat.category = face.category
		animFeat.idle = face.idle
		animComp:ApplyFeature(CName.new("FacialReaction"), animFeat)
		end, {})
	end
end

---@param targetPosition Vector4
---@return AIPositionSpec
local function ToPositionSpec(targetPosition)
	local worldPosition = WorldPosition.new()
	worldPosition:SetVector4(targetPosition)

	local positionSpec = AIPositionSpec.new()
	positionSpec:SetWorldPosition(worldPosition)

	return positionSpec
end

function AIControl.FindByHash(npcHash, distance)
    local searchQuery = Game["TSQ_NPC;"]()
    searchQuery.maxDistance = distance + 40

    local success, parts = Game.GetTargetingSystem():GetTargetParts(Game.GetPlayer(), searchQuery)
    if success ~= true then
        return
    end
    print('looking for ' .. npcHash)
    for i, v in ipairs(parts) do
        local entity = v:GetComponent(v):GetEntity()
        print(entity:GetEntityID():GetHash())
        if npcHash == entity:GetEntityID():GetHash() then
            return entity
        end
    end
end

-- thanks to the dude that helped in the discord
---@param targetPuppet ScriptedPuppet
---@param aggroPuppet ScriptedPuppet
function AIControl.MakeAggro(targetPuppet, aggroPuppet)
    local role = AIRole.new()
    local AIC = targetPuppet:GetAIControllerComponent()
	local oldNpc = targetPuppet:GetAIControllerComponent():GetAIRole()
	if oldNpc then
		oldNpc:OnRoleCleared(targetPuppet)
	end
    -- if AIC:GetCurrentRole() then		
    --   	AIC:GetCurrentRole():OnRoleCleared()
    -- end
    AIC:SetAIRole(role)
    AIC:OnAttach()
    role:OnRoleSet(entity)
    senseComponent.RequestMainPresetChange(targetPuppet, 'Combat')
    targetPuppet.movePolicies:Toggle(true)
    local reactionComp = targetPuppet.reactionComponent
    reactionComp:SetReactionPreset(TweakDBInterface.GetReactionPresetRecord("ReactionPresets.Ganger_Aggressive"))
    targetPuppet:GetAttitudeAgent():SetAttitudeTowards(aggroPuppet:GetAttitudeAgent(), EAIAttitude.AIA_Hostile)
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param aggroPuppet ScriptedPuppet | entEntity
function AIControl.Attack(targetPuppet, aggroPuppet)
	AIControl.MakeAggro(targetPuppet, aggroPuppet)

	local sensePreset = TweakDBInterface.GetReactionPresetRecord(TweakDBID.new("ReactionPresets.Ganger_Aggressive"))
	targetPuppet.reactionComponent:SetReactionPreset(sensePreset)
	targetPuppet.reactionComponent:TriggerCombat(aggroPuppet)
end

---@return ScriptedPuppet|GameObject|nil
function AIControl.GetLookAtTarget(searchFilter)
	local player = Game.GetPlayer()
  
	local searchQuery = TargetSearchQuery.new()
	searchQuery.searchFilter = searchFilter or Game['TSF_NPC;']()
	searchQuery.maxDistance = SNameplateRangesData.GetDisplayRange()
	if not player or player == nil then
	  return nil
	end
	local target = Game.GetTargetingSystem():GetObjectClosestToCrosshair(player, searchQuery)
	return target
  end
  
  ---@param targetPuppet ScriptedPuppet | entEntity
  ---@param lookAtPuppet ScriptedPuppet | entEntity
  ---@param duration number|nil
function AIControl.NPCLookAt(targetPuppet, lookAtPuppet, duration)
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

---@param targetPuppet ScriptedPuppet | entEntity
---@param friendPuppet ScriptedPuppet | entEntity
function AIControl.MakeFriendly(targetPuppet, friendPuppet)
	if not friendPuppet then
		friendPuppet = Game.GetPlayer()
	end

	-- Set NPC attitude to friendly
	targetPuppet:GetAttitudeAgent():SetAttitudeGroup(friendPuppet:GetAttitudeAgent():GetAttitudeGroup())
	targetPuppet:GetAttitudeAgent():SetAttitudeTowards(friendPuppet:GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
end

---@param targetPuppet ScriptedPuppet
---@param friendPuppet ScriptedPuppet
function AIControl.MakeNeutral(targetPuppet, friendPuppet)
	if not friendPuppet then
		friendPuppet = Game.GetPlayer()
	end

	-- Restore NPC original group
	targetPuppet:GetAttitudeAgent():SetAttitudeGroup(targetPuppet:GetRecord():BaseAttitudeGroup())
	targetPuppet:GetAttitudeAgent():SetAttitudeTowards(friendPuppet:GetAttitudeAgent(), EAIAttitude.AIA_Neutral)
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param friendPuppet ScriptedPuppet | nil
function AIControl.MakePsycho(targetPuppet, friendPuppet)
	
	targetPuppet:GetAttitudeAgent():SetAttitudeGroup('HostileToEveryone')
	if friendPuppet then
		-- friendPuppet = Game.GetPlayer()
		targetPuppet:GetAttitudeAgent():SetAttitudeTowards(friendPuppet:GetAttitudeAgent(), EAIAttitude.AIA_Neutral)
	end
end

---@param targetPuppet ScriptedPuppet | entEntity
---@return boolean
function AIControl.IsFollower(targetPuppet)
	local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

	return currentRole and currentRole:IsA('AIFollowerRole')
end

function AIControl.InDistance(targetA, targetB, distance)
	if not targetA or not targetB then
		return false
	end
	local a = targetA:GetWorldPosition()
	local b = targetB:GetWorldPosition()
	local distanceObj = Vector4.Distance(a, b)
	print("distance to check")
	print(distance)

	print("distance between obj")
	print(distanceObj)	

	return distanceObj <= distance
end

function AIControl.InTalkDistance(targetA, targetB)
	return AIControl.InDistance(targetA, targetB, AIControl.TalkingDistance)
end

---@param targetPuppet ScriptedPuppet | entEntity
function AIControl.DeleteTarget(targetPuppet)
	local oldNpc = targetPuppet:GetAIControllerComponent():GetAIRole()
	if oldNpc then
	  oldNpc:OnRoleCleared(targetPuppet)
	end
	targetPuppet:Dispose()
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param movementType moveMovementType
---@return boolean
function AIControl.MakeFollower(targetPuppet, movementType)
	if not targetPuppet:IsAttached() then
		return false
	end

	local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

	if currentRole then
		if targetPuppet:IsCrowd() and currentRole:IsA('AIFollowerRole') then
			return true
		end

		currentRole:OnRoleCleared(targetPuppet)
	end

	local followerRole = AIFollowerRole.new()
	followerRole.followerRef = Game.CreateEntityReference('#player', {})

	targetPuppet:GetAIControllerComponent():SetAIRole(followerRole)
	targetPuppet:GetAIControllerComponent():OnAttach()

	targetPuppet:GetMovePolicesComponent():ChangeMovementType(movementType or moveMovementType.Sprint)

	AIControl.MakeFriendly(targetPuppet)

	for _, followerPuppet in pairs(AIControl.followers) do
		followerPuppet:GetAttitudeAgent():SetAttitudeTowards(targetPuppet:GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
	end

	targetPuppet.isPlayerCompanionCachedTimeStamp = 0

	AIControl.followers[tostring(targetPuppet:GetEntityID().hash) or ''] = targetPuppet

	return true
end

---@param targetPuppet ScriptedPuppet | entEntity
---@return boolean
function AIControl.FreeFollower(targetPuppet, skipIsCrowd)
	if not targetPuppet then return end
	if targetPuppet:IsAttached() then
		local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

		if currentRole and currentRole:IsA('AIFollowerRole') then
			if targetPuppet:IsCrowd() then
				-- targetPuppet:Dispose() -- Can't change roles more than once on crowd npc
				-- local AMM = GetMod("AppearanceMenuMod")
				-- if not skipIsCrowd then
				-- 	AMM.Spawn:Respawn(targetPuppet, true)
				-- end
			else
				currentRole:OnRoleCleared(targetPuppet)

				local noRole = AINoRole.new()

				targetPuppet:GetAIControllerComponent():SetAIRole(noRole)
				targetPuppet:GetAIControllerComponent():OnAttach()

				AIControl.MakeNeutral(targetPuppet)

				-- Restore sense preset
				local sensePreset = targetPuppet:GetRecord():SensePreset():GetID()
				SenseComponent.RequestPresetChange(targetPuppet, sensePreset, true)
			end
		end
	end

	AIControl.followers[tostring(targetPuppet:GetEntityID().hash) or ''] = nil

	return true
end

function AIControl.FreeFollowers()
	for _, follower in pairs(AIControl.followers) do
		AIControl.FreeFollower(AIControl.follower, true)
	end
end

---@param targetPuppet ScriptedPuppet | entEntity
function AIControl.InterruptCombat(targetPuppet)
	-- Clear threats in case NPC is aggroed
	targetPuppet:GetTargetTrackerComponent():ClearThreats()

	-- Reset NPC state to relaxed
	NPCPuppet.ChangeHighLevelState(targetPuppet, gamedataNPCHighLevelState.Relaxed)
	NPCPuppet.ChangeDefenseModeState(targetPuppet, gamedataDefenseMode.NoDefend)
	NPCPuppet.ChangeUpperBodyState(targetPuppet, gamedataNPCUpperBodyState.Normal)
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param lookAtPuppet ScriptedPuppet | entEntity
---@param duration number |nil
function AIControl.LookAt(targetPuppet, lookAtPuppet, duration)
	if not lookAtPuppet then
		lookAtPuppet = Game.GetPlayer()
	end

	targetPuppet:GetStimReactionComponent():ActivateReactionLookAt(lookAtPuppet, duration and true or false, false, duration, true)
end

---@param targetPuppet ScriptedPuppet | entEntity
function AIControl.StopLookAt(targetPuppet)
	targetPuppet:GetStimReactionComponent():DeactiveLookAt(false)
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param targetPosition Vector4
---@return AIRotateToCommand
function AIControl.RotateTo(targetPuppet, targetPosition)
	local positionSpec = ToPositionSpec(targetPosition)

	local rotateCmd = AIRotateToCommand.new()
	rotateCmd.target = positionSpec
	rotateCmd.angleTolerance = 5.0 -- If zero then command will never finish
	rotateCmd.angleOffset = 0.0
	rotateCmd.speed = 1.0

	targetPuppet:GetAIControllerComponent():SendCommand(rotateCmd)

	return rotateCmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param targetPosition Vector4
---@param targetRotation Float
---@return AITeleportCommand
function AIControl.TeleportTo(targetPuppet, targetPosition, targetRotation)
	if not targetRotation then
		targetRotation = targetPuppet:GetWorldYaw()
	end

	local teleportCmd = AITeleportCommand.new()
	teleportCmd.position = targetPosition
	teleportCmd.rotation = targetRotation
	teleportCmd.doNavTest = false

	targetPuppet:GetAIControllerComponent():SendCommand(teleportCmd)

	return teleportCmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param targetPosition Vector4
---@param targetDistance Float
---@param movementType moveMovementType
---@return AIMoveToCommand | nil
function AIControl.MoveTo(targetPuppet, targetPosition, targetDistance, movementType)
	if not targetPuppet then
		return nil
	end
	if not targetPosition then
		targetPosition = Game.GetPlayer():GetWorldPosition()
	end

	if not targetDistance then
		targetDistance = 1.0
	end

	if not movementType then
		movementType = moveMovementType.Run
	end

	local positionSpec = ToPositionSpec(targetPosition)

	local moveCmd = AIMoveToCommand.new()
	moveCmd.movementTarget = positionSpec
	moveCmd.movementType = movementType
	moveCmd.desiredDistanceFromTarget = targetDistance
	moveCmd.finishWhenDestinationReached = true
	-- this was set to true
	moveCmd.ignoreNavigation = false
	-- moveCmd.useStart = true
	-- moveCmd.useStop = false

	targetPuppet:GetAIControllerComponent():SendCommand(moveCmd)
	local policy = MovePolicies.new()
			
	policy:SetDestinationPosition(Vector4.new(targetPosition.x, targetPosition.y, targetPosition.z, 1))
	-- policy:SetDestinationOrientation(v2.quat)
	policy:SetMovementType(movementType)
	policy:SetIgnoreNavigation(true)
	policy:SetStopOnObstacle(true)	
	policy:SetIgnoreNavigation(true)
	
	targetPuppet:GetMovePolicesComponent():AddPolicies(policy)

	return moveCmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param duration number|nil
---@return AIHoldPositionCommand
function AIControl.HoldFor(targetPuppet, duration)
	local holdCmd = AIHoldPositionCommand.new()
	holdCmd.duration = duration or 1.0
	holdCmd.ignoreInCombat = false
	holdCmd.removeAfterCombat = false
	holdCmd.alwaysUseStealth = false

	targetPuppet:GetAIControllerComponent():SendCommand(holdCmd)

	return holdCmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param followPuppet ScriptedPuppet | entEntity
---@param movementType moveMovementType
---@return AIFollowTargetCommand
function AIControl.FollowTarget(targetPuppet, followPuppet, movementType)
	if not followPuppet then
		---@type AIFollowerRole
		local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

		if currentRole and currentRole:IsA('AIFollowerRole') then
			followPuppet = currentRole.followTarget
		else
			followPuppet = Game.GetPlayer()
		end
	end

	if not movementType then
		movementType = moveMovementType.Sprint
	end

	local followCmd = AIFollowTargetCommand.new()
	followCmd.target = followPuppet
	followCmd.lookAtTarget = followPuppet
	followCmd.desiredDistance = 1.0
	followCmd.tolerance = 0.5
	followCmd.movementType = movementType
	followCmd.matchSpeed = true
	followCmd.teleport = true
	followCmd.stopWhenDestinationReached = false
	followCmd.ignoreInCombat = false
	followCmd.removeAfterCombat = false
	followCmd.alwaysUseStealth = false

	targetPuppet:GetAIControllerComponent():SendCommand(followCmd)

	return followCmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet | entEntity
---@return AITeleportCommand
function AIControl.InterruptBehavior(targetPuppet)
	return AIControl.TeleportTo(targetPuppet, targetPuppet:GetWorldPosition())
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param commandInstance AICommand
---@return boolean
function AIControl.IsCommandActive(targetPuppet, commandInstance)
	return AIbehaviorUniqueActiveCommandList.IsActionCommandById(
		targetPuppet:GetAIControllerComponent().activeCommands,
		commandInstance.id
	)
end

---@param targetPuppet ScriptedPuppet | entEntity
function AIControl.EquipWeapon(targetPuppet)
	local cmd = NewObject("handle:AISwitchToPrimaryWeaponCommand")
	cmd.unEquip = false
	cmd = cmd:Copy()
  
	targetPuppet:GetAIControllerComponent():SendCommand(cmd)
  
	return cmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet | entEntity
---@return boolean
function AIControl.HasQueue(targetPuppet)
	return queues[TargetHelper.GetTargetId(targetPuppet)] ~= nil
end

---@param targetPuppet ScriptedPuppet | entEntity
---@param commandTask function Task function must return a command instance
function AIControl.QueueTask(targetPuppet, commandTask)
	local targetId = TargetHelper.GetTargetId(targetPuppet)

	local queue = queues[targetId]

	if not queue then
		queue = {
			target = targetPuppet,
			tasks = {},
			wait = nil,
		}

		queues[targetId] = queue
	end

	if not queue.wait then
		queue.wait = commandTask()
	else
		table.insert(queue.tasks, commandTask)
	end
end

---@param targetPuppet ScriptedPuppet | entEntity
---@vararg function
function AIControl.QueueTasks(targetPuppet, ...)
	for i = 1, select('#', ...) do
		AIControl.QueueTask(targetPuppet, (select(i, ...)))
	end
end

---@param targetPuppet ScriptedPuppet | entEntity
function AIControl.ClearQueue(targetPuppet)
	local targetId = TargetHelper.GetTargetId(targetPuppet)
	local queue = queues[targetId]

	if queue then
		if queue.target:IsAttached() then
			queue.target:GetAIControllerComponent():CancelCommand(queue.wait)
			queue.target:GetStimReactionComponent():DeactiveLookAt(false)
		end

		queues[targetId] = nil
	end
end

function AIControl.ClearQueues()
	for targetId, queue in pairs(queues) do
		if queue.target:IsAttached() then
			queue.target:GetAIControllerComponent():CancelCommand(queue.wait)
			queue.target:GetStimReactionComponent():DeactiveLookAt(false)
		end

		queues[targetId] = nil
	end
end

---@param delta number
function AIControl.UpdateTasks(delta)
	followTimer = followTimer + delta

	if followTimer >= followInterval then
		-- This forces the NPC to follow the player a further outside the NPC's area
		for _, follower in pairs(AIControl.followers) do
			if TargetHelper.IsActive(AIControl.follower) then
				AIControl.FollowTarget(AIControl.follower)
			else
				AIControl.FreeFollower(AIControl.follower)
			end
		end

		followTimer = followTimer - followInterval
	end

	queueTimer = queueTimer + delta

	if queueTimer >= queueInterval then
		for key, queue in pairs(queues) do
			if not AIControl.IsCommandActive(queue.target, queue.wait) then
				repeat
					local task = queue.tasks[1]
					local command = task()

					table.remove(queue.tasks, 1)

					if command and command:IsA('AICommand') then
						queue.wait = command
						break
					end
				until #queue.tasks == 0

				if #queue.tasks == 0 then
					queues[key] = nil
				end
			end
		end

		queueTimer = queueTimer - queueInterval
	end
end

function AIControl.Dispose(hard)
	print("AIControl.Dispose")
	if hard then
		AIControl.followers = {}
	else
		AIControl.FreeFollowers()
	end
	AIControl.ClearQueues()
	
end

return AIControl
