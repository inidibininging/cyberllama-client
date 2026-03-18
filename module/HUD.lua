local HUD = {}

function HUD.QuestMessage(text, time, isWarning)
	if text == nil or text == "" then return end

	local message = SimpleScreenMessage.new()
	message.message = text
	message.isShown = true
	message.duration = time and time or 5.00 -- warning type won't disappear at all without duration provided

	local blackboardDefs = Game.GetAllBlackboardDefs()
	local blackboardUI = Game.GetBlackboardSystem():Get(blackboardDefs.UI_Notifications)
	local type = isWarning and blackboardDefs.UI_Notifications.WarningMessage or blackboardDefs.UI_Notifications.OnscreenMessage
	blackboardUI:SetVariant(type, ToVariant(message), true)
	GetPlayer():PlaySoundEvent("ui_menu_hover")
end

function HUD.Warning(text, time)
	HUD.QuestMessage(text, time, true)
end

function HUD.GenerateShard(shardTitle, shardMessage)
	local shard = NotifyShardRead.new(
	{
		title = shardTitle,
		text = shardMessage
	})
	Game.GetUISystem():QueueEvent(shard)
end

return HUD
