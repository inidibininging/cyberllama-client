LLAMA_MAIN_MENU=0
LLAMA_NC_RESIDENT_MENU=0
LLAMA_EXPAND_MENU=1
LLAMA_VLINES_MENU=2
-- local InteractionUI = require('interactionUI')

local MenuWrapper = {
    state = LLAMA_MAIN_MENU,
    menus = {},
    callbacks = {},
    startMessage = 'What is it?',
    interactionUI = nil,
    subtitlesControl = nil,
}
function MenuWrapper.Init(interactionUIMod, subtitlesControl)
    MenuWrapper.interactionUI = interactionUIMod
    MenuWrapper.subtitlesControl = subtitlesControl
end
function MenuWrapper.SetMenu(menuName, menu)
    local conv = {}
    local i = 1
    if menu == nil then
        print("Error in SetMenu. Menu given is nil")
        MenuWrapper.menus[menuName] = {}
        return
    end
    for v in pairs(menu) do
        conv[i] = v
        i = i + 1
    end
    MenuWrapper.menus[menuName] = {
        dialogOptionsIndexed = conv,
        dialogOptions = menu
    }
end 

function MenuWrapper.OnMenuItemClicked(menuName, textContent, callbackFn)
    local found = false

    if MenuWrapper.callbacks[menuName] == nil then
        MenuWrapper.callbacks[menuName] = {}
    end
    local found = false
    for i = 1, #MenuWrapper.callbacks[menuName] do
        if MenuWrapper.callbacks[menuName][i].text == textContent then
            MenuWrapper.callbacks[menuName][i].callback = callbackFn
            found = true
        end
    end
    if found == false then
        table.insert(MenuWrapper.callbacks[menuName], {
            text = textContent,
            callback = callbackFn,
        })
    end
end

function MenuWrapper.ActivateMenu(menuName, spawnDialogLineOnActivation)
    MenuWrapper.interactionUI.create(
        MenuWrapper.startMessage,
        MenuWrapper.menus[menuName].dialogOptions,
        function(index)
            local idx = 0
                for i, menuItem in pairs(MenuWrapper.menus[menuName].dialogOptions) do
                    if (idx == index) then
                        local textContent = menuItem.text
                        if textContent and #textContent > 0 then
                            MenuWrapper.interactionUI.hideHub()                      
                            for objIdx, obj in ipairs(MenuWrapper.callbacks[menuName]) do
                                if obj.text == textContent then
                                    obj.callback(menuName, obj.text)
                                end
                            end
                                -- this should be a continous feed back and forth between client and backend
                                -- need to break down the subttitles
                                -- so backend should hold the subtitles and just give the next one
                                -- then let the player speak etc...
                                -- now it is noooooot. you're breaking my heart, judy
                            if spawnDialogLineOnActivation then
                                MenuWrapper.subtitlesControl.SpawnDialogLine(textContent, 'V', Game.GetPlayer())
                            end
                        else
                            print("cannot invoke. text is empty or nil")
                        end
                        break
                    end
                    idx = idx + 1
                end
        end
    )
end

function MenuWrapper.HideDialogMenu()
    MenuWrapper.interactionUI.hideHub()
end

return MenuWrapper