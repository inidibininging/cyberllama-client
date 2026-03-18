local TargetHelper = {}

local markers = {}
local pins = {}


function TargetHelper.InDistance(a, b, distance)
	if not a or not b then
		return false
	end
	if not a.x or not a.y then
		return false
	end
	if not b.x or not b.y then
		return false
	end 
	
	return math.sqrt(((a.x - b.x)^2) + ((a.y - b.y)^2) + ((a.z - b.z)^2)) <= distance
end

---@param distance number
---@return Vector4
function TargetHelper.GetLookAtPosition(distance)
	if not distance then
		distance = 100
	end

	local player = Game.GetPlayer()
	local from, forward = Game.GetTargetingSystem():GetCrosshairData(player)
	local to = Vector4.new(
		from.x + forward.x * distance,
		from.y + forward.y * distance,
		from.z + forward.z * distance,
		from.w
	)

	local filters = {
		'Dynamic', -- Movable Objects
		'Vehicle',
		'Static', -- Buildings, Concrete Roads, Crates, etc.
		'Water',
		'Terrain',
		'PlayerBlocker', -- Trees, Billboards, Barriers
	}

	local results = {}

	for _, filter in ipairs(filters) do
		local success, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(from, to, filter, false, false)

		if success then
			table.insert(results, {
				distance = Vector4.Distance(from, ToVector4(result.position)),
				position = ToVector4(result.position),
				normal = result.normal,
				material = result.material,
				collision = CName.new(filter),
				-- filterName = filter,
			})
		end
	end

	if #results == 0 then
		return nil
	end

	local nearest = results[1]

	for i = 2, #results do
		if results[i].distance < nearest.distance then
			nearest = results[i]
		end
	end

	return nearest.position
end



---@param searchFilter gameTargetSearchFilter|nil
---@return gameObject
function TargetHelper.GetLookAtTarget(searchFilter)
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

function TargetHelper.GetRandomPointOnCircle(x, y, radius, numPoints)
	local points = {}
	for i = 1, numPoints do
		local angle = math.random() * 2 * math.pi
		local xP = x + (radius * math.cos(angle))
		local yP = y + (radius * math.sin(angle))
		table.insert(points, {x = xP, y = yP })
	end
	return points
end

---@param searchFilter gameTargetSearchFilter|nil
---@return ScriptedPuppet|GameObject|nil
function TargetHelper.GetLookAtTargets(searchFilter)
	local player = Game.GetPlayer()

	local searchQuery = TargetSearchQuery.new()
	searchQuery.searchFilter = searchFilter or Game['TSF_NPC;']()
	searchQuery.maxDistance = SNameplateRangesData.GetMaxDisplayRange()

	local success, targetParts = Game.GetTargetingSystem():GetTargetParts(player, searchQuery)
	local targets = {}

	if success then
		for _, targetPart in ipairs(targetParts) do
			local component = targetPart:GetComponent()

			local target = component:GetEntity()
			local targetId = tostring(target:GetEntityID().hash)

			targets[targetId] = target
		end
	end

	return targets
end

---@param target gameObject
---@return boolean
function TargetHelper.IsActive(target)
	return target:IsAttached()
		and not target:IsDeadNoStatPool()
		and not target:IsTurnedOffNoStatusEffect()
		and not ScriptedPuppet.IsDefeated(target)
		and not ScriptedPuppet.IsUnconscious(target)
end

---@param target gameObject
---@return string
function TargetHelper.GetTargetId(target)
	return tostring(target:GetEntityID().hash)
end


return TargetHelper