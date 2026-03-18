Cron = require('Cron')


local BUTTON_HOLD_COMPLETE = "BUTTON_HOLD_COMPLETE"
local BUTTON_RELEASED = "BUTTON_RELEASED"
local TELEPHONE_NO = "PhoneReject"
local TELEPHONE_YES = "one_click_confirm"
local CONTACT_MENU = "contact"
local MESSAGES_MENU = "messages"
CONTACT_CONTACT= 0
CONTACT_GROUP= 1
CONTACT_THREAD= 2

local PhoneControl = {
    newHudPhoneGameController = nil,
    incomingCallController = nil,
    phoneDialerLogicController = nil,
    messengerDialogViewController = nil,
    onCallTaken = nil,
    onCallRejected = nil,
    onContactCall = nil,
    onContactArgs = nil,
    selectedContactId = nil,
    selectedContactLocalizedName = nil,
    contacts = {},
    messages = {},
    cachedSelectedContactIdx = 0,
    customOnCallTaken = {},
    selectedMenu = nil,
    
}



function PhoneControl.Init(JSON)
    PhoneControl.JSON = JSON
    Observe('PlayerPuppet', 'OnAction',function(_,action)               
        PhoneControl.OnAction(action)
    end)
    Observe("NewHudPhoneGameController", "OnInitialize", function(ctrl) 
		PhoneControl.newHudPhoneGameController = ctrl
	end)
    Observe("NewHudPhoneGameController", "OnMenuUpdate", function(ctrl) 
		PhoneControl.newHudPhoneGameController = ctrl
	end)
	Observe("NewHudPhoneGameController", "OnPlayerAttach", function(ctrl) 
		PhoneControl.newHudPhoneGameController = ctrl
	end)
    ObserveAfter('NewHudPhoneGameController','CallSelectedContact', function(ctrl, contactData)
		PhoneControl.OnContactSelectionChanged(ctrl, contactData)
	end)
    ObserveAfter('NewHudPhoneGameController','OnContactSelectionChanged', function(ctrl, contactData)
        PhoneControl.newHudPhoneGameController = ctrl
        PhoneControl.OnContactSelectionChanged(ctrl, contactData)
    end)
    ObserveAfter('IncomingCallGameController', 'OnInitialize', function(ctrl)
        PhoneControl.incomingCallController = ctrl
    end)
    ObserveAfter("PhoneDialerLogicController", "PopulateListData", function(ctrl, contactData, selectIndex, itemHash)
        PhoneControl.phoneDialerLogicController = ctrl
		PhoneControl.PopulateListData(ctrl, contactData, selectIndex, itemHash)
	end)
    ObserveAfter('JournalNotificationQueue','OnMenuUpdate', function(ctrl)
        PhoneControl.journalNotificationQueue = ctrl
    end)
    ObserveAfter('JournalNotificationQueue','OnInitialize', function(ctrl)
        PhoneControl.journalNotificationQueue = ctrl
    end)
    ObserveAfter('MessengerDialogViewController','OnInitialize', function(ctrl)
		PhoneControl.messengerDialogViewController = ctrl
	end)
    
    -- triggered if plyer opens the sms menu
	ObserveAfter('MessengerDialogViewController','SetVisited', function(ctrl, records)
        print('MessengerDialogViewController.SetVisited')
        local messages = ctrl.messages

        PhoneControl.DebugMessages()
        local cId = PhoneControl.selectedContactId
        print("MessengerDialogViewController.SetVisited - " .. cId)
        local contactIdAndMessages = PhoneControl.GetContactIdAndMessagesByContactId(cId)
        if not contactIdAndMessages then            
            print("MessengerDialogViewController.SetVisited - No messages")
            return
        end
        print("clear")
        ctrl.messagesListController:Clear()
        if not contactIdAndMessages.messages then
            return
        end
        local msgs = contactIdAndMessages.messages
        print("Messages count:")
        print(#msgs)

        for i = 1, #msgs do
            local cachedMsg = msgs[i]
            print(cachedMsg.id)
            print(cachedMsg.text)
            local msg = JournalPhoneMessage.new()
            msg.id = cachedMsg.id
            msg.sender = cachedMsg.sender
            msg.delay = cachedMsg.delay
            -- msg.text = cachedMsg.text
            table.insert(messages, msg)
        end
        print("done")
		ctrl.messagesListController:PushEntries(messages)
	end)
	ObserveAfter('MessengerDialogViewController','AttachJournalManager', function(ctrl, journalManager)
        print('MessengerDialogViewController.AttachJournalManager')
        PhoneControl.messengerDialogViewController = ctrl
	end)

	ObserveAfter('MessengerDialogViewController', 'UpdateData;BoolBool', function(ctrl, animateLastMessage, setVisited)
        -- lookup later
        -- print("MessengerDialogViewController.UpdateData")
        if not ctrl.parentEntry then
            -- print("?????????")
            return
        end
        print("!!!!!!!!!")
        print(ctrl.parentEntry.id)
        
	end)
	-- Observe('MessangerItemRenderer', 'GetData', function(ctrl)
    --     print("MessengerDialogViewController.GetData")
    --     print(ctrl)
	-- end)
	Override('MessangerItemRenderer', 'OnJournalEntryUpdated', function(ctrl, entry, extra, wrappedMethod)
        print('OVERRIDE: MessangerItemRenderer.OnJournalEntryUpdated')
        wrappedMethod(entry, extra)
        local contact = PhoneControl.GetSelectedContactData()
        if contact == nil then           
            return
        end        
        PhoneControl.DebugMessages()
        PhoneControl.RenderMessages(ctrl, entry, contact)
	end)
	Observe('MessangerReplyItemRenderer', 'OnJournalEntryUpdated', function(ctrl, entry, extraData)		
        print('OBSERVE: MessangerReplyItemRenderer.OnJournalEntryUpdated')   
	end)
	Observe('MessengerDialogViewController', 'ActivateReply', function(ctrl, target)		
        print('MessangerReplyItemRenderer.ActivateReply')
	end)
end

function PhoneControl.Dispose()
    PhoneControl.selectedContactId = nil
    PhoneControl.contacts = {}
    PhoneControl.cachedSelectedContactIdx = 0
    PhoneControl.customOnCallTaken = {}
end

function PhoneControl.RenderMessages(ctrl, entry, contact)
    print("PhoneControl.RenderMessages")
    local cId = contact.id
    -- put this in here after adding normal npc messages
    if cId == nil then
        cId = PHONE_CONTROL_PREFIX .. contact.display_name
    end
    local contactIdAndMessages = PhoneControl.GetContactIdAndMessagesByContactId(cId)
    print("-----------")
    if not contactIdAndMessages or not contactIdAndMessages.messages then
        print(cId)
        print("No rendering. No messages available")
        return
    end
    print("PhoneControl.RenderMessages - contact messages:")
    for i = 1, #contactIdAndMessages.messages do
        local msg = contactIdAndMessages.messages[i]
        if msg.id == entry.id then
            if not msg.text then
                return
            end
            if msg.sender == 0 then
                ctrl:SetMessageView(msg.text, MessageViewType.Received, contact.display_name)
            else
                ctrl:SetMessageView(msg.text, MessageViewType.Sent, contact.display_name)
            end
        end
    end
end

function PhoneControl.OnContactSelectionChanged(ctrl, selectionChangedEvent)
    -- print("OnContactSelectionChanged")
    if selectionChangedEvent and selectionChangedEvent.ContactData then        
        PhoneControl.selectedContactId = selectionChangedEvent.ContactData.id
        PhoneControl.selectedContactLocalizedName = selectionChangedEvent.ContactData.localizedName    
    end
end

function PhoneControl.PopulateListData(ctrl, contactDataArr, selectIndex, itemHash)    
    -- print("PhoneControl.PopulateListData")
    if not PhoneControl.newHudPhoneGameController then
        return
    end
    if PhoneControl.newHudPhoneGameController.screenType == PhoneScreenType.Contacts then
        PhoneControl.selectedMenu = CONTACT_MENU
        -- print("Contacts")
        for i = 1, #PhoneControl.contacts do
            local foundContact = false
            for k,v in ipairs(contactDataArr) do
                if(v.id == PhoneControl.contacts[i].id) then
                    foundContact = true
                end
            end
            if foundContact == false then
                -- id String
                -- hash Int32
                -- localizedName String
                -- avatarID TweakDBID
                -- questRelated Bool
                -- hasMessages Bool
                -- unreadMessegeCount Int32
                -- unreadMessages Int32[]
                -- playerCanReply Bool
                -- playerIsLastSender Bool
                -- lastMesssagePreview String
                -- activeDataSync MessengerContactSyncData
                -- threadsCount Int32
                -- timeStamp GameTime

                local contact = ContactData.new()
                contact.id = PhoneControl.contacts[i].id
                contact.hash = PhoneControl.contacts[i].hash
                contact.localizedName = PhoneControl.contacts[i].localizedName
                contact.avatarID = PhoneControl.contacts[i].avatarID
                contact.questRelated = PhoneControl.contacts[i].questRelated
                contact.hasMessages = PhoneControl.contacts[i].hasMessages
                contact.isCallable = PhoneControl.contacts[i].isCallable
                contact.unreadMessegeCount = PhoneControl.contacts[i].unreadMessegeCount
                contact.unreadMessages = PhoneControl.contacts[i].unreadMessages
                contact.playerCanReply = PhoneControl.contacts[i].playerCanReply
                contact.playerIsLastSender = PhoneControl.contacts[i].playerIsLastSender
                contact.lastMesssagePreview = PhoneControl.contacts[i].lastMesssagePreview
                contact.threadsCount = PhoneControl.contacts[i].threadsCount
                contact.timeStamp = PhoneControl.contacts[i].timeStamp
                table.insert(contactDataArr, contact)
            end
        end
    elseif PhoneControl.newHudPhoneGameController.screenType == PhoneScreenType.Unread then
        -- print("Messages")
        PhoneControl.selectedMenu = MESSAGES_MENU
        local foundContact = false
        local messages = MessengerUtils.GetSimpleContactDataArray(ctrl.journalMgr, true, true, ctrl.isShowingAllMessages);
        for i = 1, #PhoneControl.contacts do
            local foundContact = false
            for k,v in ipairs(contactDataArr) do
                -- print(v)
                -- print(v.id)
                if(v.id == PhoneControl.contacts[i].id) then
                    foundContact = true
                end
            end
            if foundContact == false then
                local contact = ContactData.new()
                contact.id = PhoneControl.contacts[i].id
                contact.hash = PhoneControl.contacts[i].hash
                contact.conversationHash = "1338"..math.random(1000)
                contact.type = MessengerContactType.MultiThread
                contact.localizedName = PhoneControl.contacts[i].localizedName
                contact.questRelated = PhoneControl.contacts[i].questRelated                
                contact.hasMessages = PhoneControl.contacts[i].hasMessages
                contact.avatarID = PhoneControl.contacts[i].avatarID
                contact.unreadMessegeCount = PhoneControl.contacts[i].unreadMessegeCount
                contact.unreadMessages = PhoneControl.contacts[i].unreadMessages
                contact.isCallable = PhoneControl.contacts[i].isCallable
                contact.playerCanReply = PhoneControl.contacts[i].playerCanReply
                contact.playerIsLastSender = PhoneControl.contacts[i].playerIsLastSender
                contact.threadsCount = PhoneControl.contacts[i].threadsCount                
                contact.timeStamp = PhoneControl.contacts[i].timeStamp
                contact.lastMesssagePreview = PhoneControl.contacts[i].lastMesssagePreview
                table.insert(contactDataArr, contact)
            end
        end
    end
    
    ctrl.dataView:EnableSorting();
    ctrl.dataSource:Reset(contactDataArr);
    ctrl.dataView:DisableSorting();
end


function PhoneControl.GetContactsNPCDataById(contactId)
    for i = 1, #PhoneControl.contacts do
        if PhoneControl.contacts[i].id == contactId then
            return PhoneControl.contacts[i].contact
        end
    end
end

function PhoneControl.GetContactsNPCDataByDisplayName(displayName)
    for i = 1, #PhoneControl.contacts do
        if PhoneControl.contacts[i].contact.display_name == displayName then
            return PhoneControl.contacts[i].contact
        end
    end
end

function PhoneControl.GetOnCallTakenByDisplayName(displayName)
    for i = 1, #PhoneControl.customOnCallTaken do
        print(PhoneControl.customOnCallTaken[i].name .. " vs " .. displayName)
        if PhoneControl.customOnCallTaken[i].name == displayName then
            print("found it")
            print(type(PhoneControl.customOnCallTaken[i].fn))
            return (PhoneControl.customOnCallTaken[i].fn)
        end
    end
end

function PhoneControl.HasContactWithDisplayName(displayName)
    for i = 1, #PhoneControl.contacts do
        if PhoneControl.contacts[i].contact.display_name == displayName then
            return true
        end
    end
    return false
end

function PhoneControl.HasContactWithRecordId(recordId)
    for i = 1, #PhoneControl.contacts do
        
        if
            -- PhoneControl.contacts[i].contact.record_id == recordId or
            (PhoneControl.contacts[i].contact.record_id_to_scan and PhoneControl.contacts[i].contact.record_id_to_scan == recordId) then
            return true
        end
    end
    return false
end

function PhoneControl.PrintTable(t, indent)
    print(PhoneControl.JSON:encode(t))
    -- -- Set default indent if none is provided
    -- indent = indent or 0
    -- local indentStr = string.rep("    ", indent)  -- Create indentation string

    -- for key, value in pairs(t) do
    --     if type(value) == "table" then
    --         print(indentStr .. tostring(key) .. ":")
    --         PhoneControl.PrintTable(value, indent + 1)  -- Recursive call with increased indent
    --     else
    --         print(indentStr .. tostring(key) .. ": " .. tostring(value))
    --     end
    -- end
    
end

-- adds the npc as a contact. copies the npc data into a cache table
function PhoneControl.AddContact(contact, imagePath, addContactLocation)
    print("PhoneControl.AddContact")
    print('cyberllama_' .. contact.display_name)
    if not contact.display_name then        
        CyberV.VSpeak('No name, no number.')
        return false
    end

    -- local contactId = 'cyberllama_' .. contact.display_name
    local contactId = contact.id
    if type(contactId) ~= "string" then
        contactId = PHONE_CONTROL_PREFIX .. contact.display_name
        print("AddContact: id was not a string. yay! contactId now is " .. contactId)
    else
        print("AddContact: id is a string. yay!")
    end
    if PhoneControl.HasContactWithDisplayName(contact.display_name) or
        PhoneControl.HasContactWithRecordId(contact.record_id) then
        return
    end

    local contactObj = {
        id = nil,
        contactId = nil,
        localizedName = nil,
        localizedPreview = nil,
        avatarID = nil,
        questRelated = nil,
        hasQuestImportantReply = nil,
        hasMessages = nil,
        isCallable = true,
        unreadMessegeCount = nil,
        unreadMessages = nil,
        playerCanReply = nil,
        playerIsLastSender = nil,
        lastMesssagePreview = nil,
        threadsCount = nil,
        hash = nil,
        type = nil,
        timeStamp = nil,
        contact = contact
    }
    contactObj.id =  contactId
    -- contact.contactId = contactId
    contactObj.localizedName  = contact.display_name
    -- contact.localizedPreview  =  contactName
    if imagePath == nil then
        contactObj.avatarID = TweakDBID.new("PhoneAvatars.Avatar_Unknown")
    else
        contactObj.avatarID = TweakDBID.new(imagePath)
    end
    contactObj.questRelated               = false
    contactObj.hasMessages                = true
    contactObj.isCallable                 = true
    contactObj.unreadMessegeCount         = 0
    contactObj.unreadMessages             = 0
    contactObj.playerCanReply             = false
    contactObj.playerIsLastSender         = false
    contactObj.lastMesssagePreview        = addContactLocation or contact.display_name
    contactObj.threadsCount               = 0
    
    -- contact.type = MessengerContactType.Contact
    contactObj.timeStamp = Game.GetTimeSystem():GetGameTime()
    -- since this is borrowed from cyberscript... what does 1308 is for? random?
    contactObj.hash = 0 - tonumber("1337"..math.random(1,999))
    table.insert(PhoneControl.contacts, contactObj)
    return true
end


function PhoneControl.GetSelectedContactData()
    if not PhoneControl.selectedContactId then
        print("No contact selected")
        return nil
    end
    -- this is for the new weird case of not giving me the id... wtf
    if #PhoneControl.selectedContactId == 0 then
        for i=1, #PhoneControl.contacts do
            -- print(PhoneControl.contacts[i].id)
            if PhoneControl.contacts[i].localizedName == PhoneControl.selectedContactLocalizedName then
                PhoneControl.cachedSelectedContactIdx = i
                return PhoneControl.contacts[i].contact
            end
        end
    end
    print(PhoneControl.selectedContactId)
    -- TODO: change contacts to a map, by contactId`
    for i=1, #PhoneControl.contacts do
        -- print(PhoneControl.contacts[i].id)
        if PhoneControl.contacts[i].id == PhoneControl.selectedContactId then
            PhoneControl.cachedSelectedContactIdx = i
            return PhoneControl.contacts[i].contact
        end
    end
    return nil
end

function PhoneControl.OnAction(action)
    if not PhoneControl.selectedContactId then
        return
    end
    -- if not GameSession.IsPaused() then
    --     return
    -- end
    local actionName = Game.NameToString(action:GetName(action))
	local actionType = action:GetType(action).value
	local actionValue = action:GetValue(action)
    
    if actionName == TELEPHONE_YES and actionType == BUTTON_RELEASED and PhoneControl.selectedContactId and PhoneControl.selectedMenu == CONTACT_MENU then
        -- StatusEffectHelper.RemoveStatusEffect(Game.GetPlayer(), "GameplayRestriction.NoCombat")
        print(TELEPHONE_YES .. " engaged ")
        if PhoneControl.onCallTaken then
            local audioEvent = SoundPlayEvent.new()
            audioEvent.soundName = "ui_phone_incoming_call_positive"
			Game.GetPlayer():QueueEvent(audioEvent)
            print("PhoneControl.selectedContactId:" .. PhoneControl.selectedContactId)
            local contact = PhoneControl.GetSelectedContactData()
            if not contact then
                print("NO CONTACT DATA")
                return
            end
            local displayName = contact.display_name
            if displayName then
                print("display name: " .. displayName)
                local customOnCall = PhoneControl.GetOnCallTakenByDisplayName(displayName)
                if customOnCall then
                    print("PhoneControl.OnAction: (CUSTOM) onCallTaken")
                    customOnCall()
                else
                    print("PhoneControl.OnAction: onCallTaken")
                    PhoneControl.onCallTaken()
                end
        
            end
            
            print("disengaged call")
            PhoneControl.selectedContactId = nil
        end
        return
    end
    if actionName == TELEPHONE_NO and actionType == BUTTON_HOLD_COMPLETE then
        StatusEffectHelper.RemoveStatusEffect(Game.GetPlayer(), "GameplayRestriction.NoCombat")
        print(TELEPHONE_NO .. " engaged ")
        if PhoneControl.onCallRejected then            
            PhoneControl.onCallRejected()
        end
        return
    end
end
function PhoneControl.SetOnCallTaken(onCallTaken, displayName)
    if onCallTaken and type(onCallTaken) == 'function' then
        if displayName then
            print("PhoneControl: (CUSTOM) SetOnCallTaken for " .. displayName)
            table.insert(
                PhoneControl.customOnCallTaken,
            {
                name = displayName,
                fn = onCallTaken
            })
        else
            print("PhoneControl: SetOnCallTaken")
            PhoneControl.onCallTaken = onCallTaken
        end
    end
end

function PhoneControl.SetOnCallRejected(onCallRejected)
    if onCallRejected and type(onCallRejected) == 'function' then
        PhoneControl.onCallRejected = onCallRejected
    end
end

function PhoneControl.MakeCall(callerName, imagePath, canReject)
    StatusEffectHelper.RemoveStatusEffect(Game.GetPlayer(), "GameplayRestriction.NoCombat")
    if PhoneControl.newHudPhoneGameController ~= nil then
        
        -- and PhoneControl.controller:IsPhoneActive() then        
        PhoneControl.newHudPhoneGameController.incomingCallElement.request = PhoneControl.newHudPhoneGameController:AsyncSpawnFromLocal(
            inkWidgetRef.Get(PhoneControl.newHudPhoneGameController.incomingCallElement.slot),
            PhoneControl.newHudPhoneGameController.incomingCallElement.libraryID,
            PhoneControl.newHudPhoneGameController, "OnIncommingCallSpawned"
        );
        PhoneControl.newHudPhoneGameController:HandleCall()
        
        local audioEvent = SoundPlayEvent.new()
        audioEvent.soundName = "ui_phone_incoming_call"
        local canRejectNew = false
        if canReject ~= nil then
            canRejectNew = canReject
        else 
            canRejectNew = true
        end
        Game.GetPlayer():QueueEvent(audioEvent)    
        PhoneControl.newHudPhoneGameController:SetPhoneFunction(EHudPhoneFunction.IncomingCall)
        Cron.After(0.2, function()							
            local controller = PhoneControl.newHudPhoneGameController.incomingCallElement.widget:GetController()            
            PhoneControl.newHudPhoneGameController.holoAudioCallLogicController.AvatarController.SignalRangeIcon:SetVisible(false);
            PhoneControl.newHudPhoneGameController.holoAudioCallLogicController.AvatarController.WaveformPlaceholder:SetVisible(false);
            PhoneControl.newHudPhoneGameController.holoAudioCallLogicController.AvatarController.HolocallHolder:SetVisible(true);           
            controller.contactNameWidget:SetText(callerName)
            InkImageUtils.RequestSetImage(controller, controller.avatar, "PhoneAvatars."..imagePath)
            inkWidgetRef.SetVisible(controller.buttonHint, canRejectNew)
        end, {}) 

        Cron.After(4, function()
            local audioEvent = SoundStopEvent.new()
            audioEvent.soundName = "ui_phone_incoming_call"
            Game.GetPlayer():QueueEvent(audioEvent)
        end, {})
    end
end



function PhoneControl.SendMessageNotification(contactId, phoneTitle, phoneMessage)
    print("PhoneControl.SendMessage")
    if not PhoneControl.newHudPhoneGameController then 
        print("PhoneControl.SendMessage newHudPhoneGameController is nil")
        return
    end
    -- local openAction = OpenMessengerNotificationAction.new()
    -- openAction.eventDispatcher = PhoneControl.journalNotificationQueue
    -- local userData = PhoneMessageNotificationViewData.new()

    local genNotificationData = gameuiGenericNotificationData.new()
    local openAction = OpenPhoneMessageAction.new()
    openAction.phoneSystem = Game.GetScriptableSystemsContainer():Get("PhoneSystem")
    local contact = JournalContact.new()
    contact.id = 'cyberllama_' .. contactId
    openAction.journalEntry = contact

    local userData = PhoneMessageNotificationViewData.new()
    userData.title = phoneTitle
    userData.SMSText = phoneMessage
    userData.action = openAction
    userData.animation = CName("notification_phone_MSG")
    userData.soundEvent = CName("PhoneSmsPopup")
    userData.soundAction = CName("OnOpen")

    genNotificationData.time = 4
    genNotificationData.widgetLibraryItemName = CName("notification_message")
    genNotificationData.notificationData = userData

    PhoneControl.newHudPhoneGameController:AddNewNotificationData(genNotificationData)
end


function PhoneControl.ContactMessagesExist(contactId)
    for k,v in pairs(PhoneControl.messages) do
        if v.id == contactId then
            return true
        end
    end
    return false
end

function PhoneControl.CreateContactMessages(contactId)
    table.insert(PhoneControl.messages, {
        id = contactId,
        messages = {}
    })
end

function PhoneControl.GetContactIdAndMessagesByContactId(contactId)
    print("GetContactIdAndMessagesByContactId")
    print("LOOKING FOR contactId:" .. contactId)
    for i = 1, #PhoneControl.messages do
        local contactAndMessage = PhoneControl.messages[i]
        if contactAndMessage.id == contactId then
            print("GetContactIdAndMessagesByContactId - FOUND IT")
            return contactAndMessage
        end
    end
    print("FOUND NAHT!!")
    return nil
end

function PhoneControl.AddMessageByContactId(contactId, message)
    
    print(contactId)
    for i = 1, #PhoneControl.messages do
        local contactAndMessages = PhoneControl.messages[i]
        if contactAndMessages.id == contactId then
            print("!!!! ADDING message for " .. contactId)
            table.insert(contactAndMessages.messages, message)            
            -- PhoneControl.DebugMessages()
            return true
        end
    end

    return false
end

function PhoneControl.DebugMessages()
    print("----- START PhoneControl.DebugMessages ")
    for k,v in pairs(PhoneControl.messages) do
        print("<<<<<<<<<<<<")
        print("contactId:")
        print(v.id)
        print("messages:")
        print(v.messages)
        print("messages count:")
        print(#v.messages)
        print("MESSAGES:")
        for kk, vv in pairs(v.messages) do
            print("--------")
            print("id:")
            print(vv.id)
            print("text:")
            print(vv.text)
            print("sender:")
            print(vv.sender)
        end
    end
    print("----- END PhoneControl.DebugMessages -----")
end
function PhoneControl.DebugContacts()
    
end

function PhoneControl._addMessageGeneric(contactId, message, who)
    local cId = contactId -- PhoneControl.ToContactMessageThreadId(contactId)
    if not PhoneControl.ContactMessagesExist(cId) then
        print("_addMessageGeneric: no contact messages exist. creating new one")
        PhoneControl.CreateContactMessages(cId)
    end
    -- local msg = {JournalPhoneMessage.new()}
    local msg = {}
    if who == 'v' then
        msg.sender = 1
    else
        msg.sender = 0
    end
    msg.text = message
    msg.delay = -9999
    msg.id = "1339" .. tostring(math.random(999))
    
    if not PhoneControl.AddMessageByContactId(cId, msg) then
        print("WROOOOOOONG . something broke")
    end
end

function PhoneControl.AddVMessage(contactId, message)
    PhoneControl._addMessageGeneric(contactId, message, 'v')
end
function PhoneControl.AddContactMessage(contactId, message)
    print("PhoneControl.AddContactMessage")
    PhoneControl._addMessageGeneric(contactId, message, contactId)
end
function PhoneControl.ToContactMessageThreadId(contactId)
    return string.gsub(contactId, " ", "_")
end
return PhoneControl