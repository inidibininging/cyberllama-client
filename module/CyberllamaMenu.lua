local Wrapper = {
    menu = nil
}

Wrapper.DIALOG_MAIN='Main'
Wrapper.DIALOG_FRIEND='Friend'
Wrapper.DIALOG_FOLLOWER='Follower'
Wrapper.DIALOG_FIXER='Fixer'
Wrapper.DIALOG_FIXER_ASK_BACKUP='FixerAskBackup'
Wrapper.DIALOG_NPC_INTRO='NPCIntro'
Wrapper.DIALOG_VLINES='VLines'
Wrapper.DIALOG_FIXER_QUEST='FixerQuest'
Wrapper.DIALOG_EXPAND='Expand'
Wrapper.DIALOG_FOLLOWER_SUB_MAIN='FollowerSubMain'
Wrapper.DIALOG_FOLLOWER_SUB_NEEDS='FollowerSubNeeds'
Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL='FollowerSubSocial'
Wrapper.DIALOG_FOLLOWER_SUB_JOB='FollowerSubJob'

DialogAutoHideCooldown = 100

Wrapper.AudioOn = false



-- Wrapper.lastVLines = {}
Wrapper.backend = nil

function Wrapper.HasVLines()
    return Menu.lastVLines ~= nil and #(Menu.lastVLines) > 0
end

function Wrapper.InitBackend(backendMod)
    Wrapper.backend = backendMod
end

---@param lines table|nil
function Wrapper.InjectVLines(lines, CyberNPC, CyberV)
    if (lines == nil) then
        print("v lines injected are nil")
        return
    end
    Wrapper.lastVLines = lines
    if lines ~= nil and (Wrapper.lastVLines == nil or #(Wrapper.lastVLines) > 0) then
        -- convert lines of string to objects
        local linesAsObj = {}
        
        local target = CyberNPC.GetLastTarget()
        if target then
            local player = Game.GetPlayer()

            if not AIControl.InTalkDistance(player, target) then
                table.insert(linesAsObj, {
                    text = "Nevermind",
                    icon = Wrapper.interactionUI.ON_OFF_ICON
                })
                Wrapper.interactionUI.hideHub()
                Wrapper.v.VSpeak(Wrapper.v.VNotCloseToNPCRandomLine())                
                return
            else
                Wrapper.AIControl.NPCLookAt(target, player, 30)
            end
        end
        for lidx = 1, #lines do
            table.insert(linesAsObj, {
                text = lines[lidx],
                icon = Wrapper.interactionUI.PHONE_CALL_ICON
            })
        end
        table.insert(linesAsObj, {
            text = "Nevermind",
            icon = Wrapper.interactionUI.ON_OFF_ICON
        })
        Wrapper.menu.SetMenu(Wrapper.DIALOG_VLINES, linesAsObj, false)

        for lidx = 1, #linesAsObj do
            if linesAsObj[lidx] == nil then
                print("provided a nil line in InjectVLines")
            else
                print(linesAsObj[lidx].text)
                local isNevermind = false
                -- the #lines is nevermind, since #lines doesnt count nevermind as the last line
                if lidx == #linesAsObj then
                    isNevermind = true
                    Wrapper.menu.OnMenuItemClicked(
                        Wrapper.DIALOG_VLINES,
                        "Nevermind",
                        function()
                            Wrapper.lastVLines = {}
                            print("Nevermind - CyberNPC.NPCStopAnimation")
                            CyberNPC.NPCStopAnimation()
                            Wrapper.interactionUI.hideHub()
                        end
                    )
                else
                    local text = linesAsObj[lidx].text
                    Wrapper.menu.OnMenuItemClicked(
                        Wrapper.DIALOG_VLINES,
                        text,
                        function()
                            local target = CyberNPC.GetLastTarget()
                            if target == nil then
                                print("InjectVLines: target is nil")
                            else
                                local player = Game.GetPlayer()                
                                Wrapper.AIControl.NPCLookAt(target, player, 20)
                            end
                            Wrapper.backend.PromptClientContinue(
                                text,
                                'PROMPT_TTS_PLAYER_FEED',
                                Wrapper.getPlayerInfo(),
                                Wrapper.getNpcDataInfo(),
                                function(response)
                                    if (response == nil) then
                                        print("response is nil")
                                    else
                                        print(response)
                                    end
                                    print("promptcontinue")
                                    
                                    Wrapper.OnResponse(response, Wrapper.DIALOG_VLINES, text)
                                end
                            )
                        end
                    )
                end
                
            end
        end
    end
end

-- DefaultMenuLines = {
--     "(Vision)",
--     -- "(Quest)",
--     "(Food)",
--     "(Drink)",
--     "(Insult)",
--     "(Brag)",
--     "(Joke)",
--     "(Flirt)",
--     "(Talk)",
--     "(Background story)",
--     "(Audio)",
--     "(Move here)",
--     "(Add Contact)",
-- }

function Wrapper.MainMenuAddEvents()
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Vision)', function()
        Wrapper.Vision(Wrapper.DIALOG_MAIN, '(Vision)')
    end)
    -- Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Quest)', Wrapper.Quest)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Food)', function()
        Wrapper.Food(Wrapper.DIALOG_MAIN, '(Food)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Drink)', function()
        Wrapper.Drink(Wrapper.DIALOG_MAIN, '(Drink)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Insult)', function()
        Wrapper.Insult(Wrapper.DIALOG_MAIN, '(Insult)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Brag)', function()
        Wrapper.Brag(Wrapper.DIALOG_MAIN, '(Brag)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Joke)', function()
        Wrapper.Joke(Wrapper.DIALOG_MAIN, '(Joke)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Flirt)', function()
        Wrapper.Flirt(Wrapper.DIALOG_MAIN, '(Flirt)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Talk)', function()
        Wrapper.Talk(Wrapper.DIALOG_MAIN, '(Talk)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Background story)', function()
        Wrapper.BackgroundStory(Wrapper.DIALOG_MAIN, '(Background story)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_MAIN, '(Audio)', function()
        Wrapper.Audio(Wrapper.DIALOG_MAIN, '(Audio)')
    end)
end

function Wrapper.MainMenuFriendEvents()
    -- Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Vision)', function()
    --     Wrapper.Vision(Wrapper.DIALOG_FRIEND, '(Vision)')
    -- end)
    -- Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Quest)', function()
    --     Wrapper.Quest(Wrapper.DIALOG_FRIEND, '(Quest)')
    -- end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Food)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Food(Wrapper.DIALOG_FRIEND, '(Food)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Drink)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Drink(Wrapper.DIALOG_FRIEND, '(Drink)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Insult)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Insult(Wrapper.DIALOG_FRIEND, '(Insult)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Brag)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Brag(Wrapper.DIALOG_FRIEND, '(Brag)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Joke)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Joke(Wrapper.DIALOG_FRIEND, '(Joke)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Flirt)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Flirt(Wrapper.DIALOG_FRIEND, '(Flirt)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Talk)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Talk(Wrapper.DIALOG_FRIEND, '(Talk)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Background story)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.BackgroundStory(Wrapper.DIALOG_FRIEND, '(Background story)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Audio)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Audio(Wrapper.DIALOG_FRIEND, '(Audio)')
    end)
    -- Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Move here)', function()
    --     Wrapper.MoveHere(Wrapper.DIALOG_FRIEND, '(Move here)')
    -- end)
    
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FRIEND, '(Add Contact)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        if #Wrapper.quest.questLocations > 0 then
            Wrapper.hud.Warning("FINISH OR CANCEL QUEST FIRST")
            return
        end
        Wrapper.AddContact(Wrapper.DIALOG_FRIEND, '(Add Contact)')
    end)
end

function Wrapper.MainMenuFollowerEvents()
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Vision)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Vision(Wrapper.DIALOG_FOLLOWER, '(Vision)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Quest)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Quest(Wrapper.DIALOG_FOLLOWER, '(Quest)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Food)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Food(Wrapper.DIALOG_FOLLOWER, '(Food)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Drink)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Drink(Wrapper.DIALOG_FOLLOWER, '(Drink)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Insult)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Insult(Wrapper.DIALOG_FOLLOWER, '(Insult)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Brag)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Brag(Wrapper.DIALOG_FOLLOWER, '(Brag)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Joke)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Joke(Wrapper.DIALOG_FOLLOWER, '(Joke)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Flirt)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Flirt(Wrapper.DIALOG_FOLLOWER, '(Flirt)')
    end)

    
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Talk)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Talk(Wrapper.DIALOG_FOLLOWER, '(Talk)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Background story)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.BackgroundStory(Wrapper.DIALOG_FOLLOWER, '(Background story)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Audio)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Audio(Wrapper.DIALOG_FOLLOWER, '(Audio)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Move here)', function()
        Wrapper.MoveHere(Wrapper.DIALOG_FOLLOWER, '(Move here)')
    end)
    -- Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Add Contact)', function()
    --     Wrapper.AddContact(Wrapper.DIALOG_FOLLOWER, '(Add Contact)')
    -- end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER, '(Dismiss)', function()
        if Wrapper.merc.IsAMerc(CyberNPC.LastNPCTarget) then
            return
        end
        if not Wrapper.npc.VIsNotInCombat() then
            return
        end
        if not Wrapper.AIControl.IsFollower(Wrapper.npc.LastNPCTarget.obj) then
            return
        end
        if not Wrapper.v.InACar() then
            return
        end  

        if not Wrapper.quest.done or #Wrapper.quest.questLocations > 0 then
            Wrapper.hud.Warning("FINISH OR CANCEL QUEST FIRST")
            return
        end
        Wrapper.Dismiss(Wrapper.DIALOG_FOLLOWER, '(Dismiss)')
    end)
end

function Wrapper.FollowerSubMenuEvents()    
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_MAIN, '(Basic Needs)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FOLLOWER_SUB_NEEDS)
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_MAIN, '(Social)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL)
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_MAIN, '(Job)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FOLLOWER_SUB_JOB)
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_MAIN, '(Move Here)', function()
        Wrapper.MoveHere(Wrapper.DIALOG_FOLLOWER_SUB_MAIN, '(Move Here)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_MAIN, '(Add Contact)', function()
        if #Wrapper.quest.questLocations > 0 then
            Wrapper.hud.Warning("FINISH OR CANCEL QUEST FIRST")
            return
        end
            
        Wrapper.AddContact(Wrapper.DIALOG_FOLLOWER_SUB_MAIN, '(Add Contact)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_MAIN, '(Dismiss)', function()
        if Wrapper.merc.IsAMerc(CyberNPC.LastNPCTarget) then
            return
        end
        if not Wrapper.npc.VIsNotInCombat() then
            return
        end
        if not Wrapper.AIControl.IsFollower(Wrapper.npc.LastNPCTarget.obj) then
            return
        end
        if not Wrapper.quest.done or #Wrapper.quest.questLocations > 0 then
            Wrapper.hud.Warning("FINISH OR CANCEL QUEST FIRST")
            return
        end
        Wrapper.Dismiss(Wrapper.DIALOG_FOLLOWER_SUB_MAIN, '(Dismiss)')
    end)
end

function Wrapper.FollowerSubNeedsEvents()
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_NEEDS, "(Try Give Food)", function()
        -- TODO: redscript inventory UI management for npc
        -- TODO: check inventory for food, substract that
        if Wrapper.npc.LLamaNPCFoodCooldown == 0 then
            Wrapper.npc.LLamaNPCFoodCooldown = Wrapper.npc.LLamaNPCFoodCooldownSecs
            Wrapper.cron.After(Wrapper.npc.LLamaNPCFoodCooldownSecs, function()
                Wrapper.npc.LLamaNPCFoodCooldown = 0
            end)
            -- TODO: add animation here (give food)
            -- TODO: play eating sound
            Wrapper.npc.LLamaNPCFood = Wrapper.npc.LLamaNPCFood + math.random(1,5)
            Wrapper.sound.PlayRandomEatingSounds()
            Wrapper.v.BlinkSlow()
            Wrapper.npc.NPCLookAtPlayer()
            local msg = Wrapper.npc.NPCThankYouLinesRandomLines()
            Wrapper.npc.NPCSpeak(
                msg,
                Wrapper.npc.LastNPCTarget.id_hash,
                Wrapper.npc.LastNPCTarget.display_name
            )
            Wrapper.npc.NPCDisplayMood()
        else
            return
        end
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_NEEDS, "(Try Give Drink)", function()
        -- TODO: redscript inventory UI management for npc
        -- TODO: check inventory for hydration, substract that
        if Wrapper.npc.LLamaNPCHydrationCooldown == 0 then
            Wrapper.npc.LLamaNPCHydrationCooldown = Wrapper.npc.LLamaNPCHydrationCooldownSecs
            Wrapper.cron.After(Wrapper.npc.LLamaNPCHydrationCooldownSecs, function()
                Wrapper.npc.LLamaNPCHydrationCooldown = 0
            end)
            -- TODO: add animation here (give drink)
            -- TODO: play eating sound
            Wrapper.npc.LLamaNPCHydration = Wrapper.npc.LLamaNPCHydration + math.random(1,5)
            Wrapper.sound.PlayRandomDrinkingSounds()
            Wrapper.v.BlinkSlow()
            Wrapper.npc.NPCLookAtPlayer()
            local msg = Wrapper.npc.NPCThankYouLinesRandomLines()
            Wrapper.npc.NPCSpeak(
                msg,
                Wrapper.npc.LastNPCTarget.id_hash,
                Wrapper.npc.LastNPCTarget.display_name
            )
            Wrapper.npc.NPCDisplayMood()
        else
            return
        end
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_NEEDS, "(Ask About Food)", function()
        local vMsg = Wrapper.v.VAskFoodLinesRandomLine()
        local vMsgWaitTime = Wrapper.subtitles.CalcTimeOfString(
            vMsg
        )+2
        Wrapper.npc.NPCLookAtPlayer(vMsgWaitTime)
        Wrapper.v.VSpeak(vMsg)
        
        Wrapper.cron.After(vMsgWaitTime, function()
            local msg = ''
            if Wrapper.npc.LLamaNPCFood > 50 then
                msg = Wrapper.npc.NPCFoodOkLinesRandomLines()
            else
                msg = Wrapper.npc.NPCFoodNotOkLinesRandomLines()
            end            
            Wrapper.npc.NPCSpeak(
                msg,
                Wrapper.npc.LastNPCTarget.id_hash,
                Wrapper.npc.LastNPCTarget.display_name
            )
        end)
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_NEEDS, "(Ask About Drinking)", function()
        local vMsg = Wrapper.v.VAskHydrationLinesRandomLine()
        local vMsgWaitTime = Wrapper.subtitles.CalcTimeOfString(
            vMsg
        )+2
        Wrapper.npc.NPCLookAtPlayer(vMsgWaitTime)
        Wrapper.v.VSpeak(vMsg)
        Wrapper.cron.After(vMsgWaitTime, function()
            local msg = ''
            if Wrapper.npc.LLamaNPCFood > 50 then
                msg = Wrapper.npc.NPCHydrationOkLinesRandomLines()
            else
                msg = Wrapper.npc.NPCHydrationNotOkLinesRandomLines()
            end
            Wrapper.npc.NPCSpeak(
                msg,
                Wrapper.npc.LastNPCTarget.id_hash,
                Wrapper.npc.LastNPCTarget.display_name
            )
        end)
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_NEEDS, "(Display Stats)", function()
        Wrapper.npc.NPCDisplayMood()
    end)
end

function Wrapper.FollowerSubSocialEvents()
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Vision)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Vision(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Vision)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Audio)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Audio(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Audio)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Insult)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Insult(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Insult)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Brag)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Brag(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Brag)')
    end)

    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Dance)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        print("TODO:(Dance)")
    end)

    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Smoke Together)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        print("TODO:(Smoke Together)")
    end)

    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Joke)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Joke(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Joke)')
    end)

    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Kiss)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        if Wrapper.npc.LLamaNPCRelationship < Wrapper.npc.LLamaNPCRomanticThreshold then
            Wrapper.hud.Warning("NOT A ROMANTIC PARTNER")
            return
        end
        Wrapper.v.BlinkSlow()
        if Chance50() then
            Wrapper.sound.PlayKissingSoundsMaleRandom()
        else
            Wrapper.sound.PlayKissingSoundsFemaleRandom()
        end
        Wrapper.cron.After(6, function()
            local msg = Wrapper.npc.NPCAffectionateLinesRandomLine()
            Wrapper.npc.NPCSpeak(
                msg,
                Wrapper.npc.LastNPCTarget.id_hash,
                Wrapper.npc.LastNPCTarget.display_name
            )
        end)        
    end)

    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Flirt)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Flirt(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Flirt)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Talk)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Talk(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Talk)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Background Story)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.BackgroundStory(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Background Story)')
    end)

    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Forget Conversations)', function()
        Wrapper.ForgetConversation(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, '(Forget Conversations)')
    end)
end

function Wrapper.FollowerSubJobEvents()    
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_JOB, '(Quest Together)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        if #Wrapper.quest.questLocations > 0 then
            Wrapper.hud.Warning("A QUEST IS ACTIVE")
            return
        end
        Wrapper.Quest(Wrapper.DIALOG_FOLLOWER_SUB_JOB, '(Quest Together)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_JOB, '(Send To Quest)', function()
        print("TODO:(Send To Quest)")
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FOLLOWER_SUB_JOB, '(Send Home)', function()

        Wrapper.Dismiss(Wrapper.DIALOG_FOLLOWER_SUB_JOB, '(Send Home)')
    end)
end

function Wrapper.FixerMenuAddEvents()
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER, '(Quest)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Quest(Wrapper.DIALOG_FIXER, '(Quest)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER, '(Brag)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Brag(Wrapper.DIALOG_FIXER, '(Brag)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER, '(Joke)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.Joke(Wrapper.DIALOG_FIXER, '(Joke)')
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER, '(Background story)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        Wrapper.BackgroundStory(Wrapper.DIALOG_FIXER, '(Background story)')
    end)
    -- Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER, '(Add Contact)', function()
    --     Wrapper.AddContact(Wrapper.DIALOG_FIXER, '(Add Contact)')
    -- end)
end

function Wrapper.FixerAskBackupMenuAddEvents()
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER_ASK_BACKUP, '(Melee)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        local vMsg = Wrapper.v.VQuestAskMercMeleeRandomLine()
        local vMsgWaitTime = Wrapper.subtitles.CalcTimeOfString(
            vMsg
        )+2
        local fixerMsg = Wrapper.npc.NPCResponseAskBackupLinesRandomLine() .. ". Remember, from now on, you will be sharing your compensation with the other mercs"
        local vFixerWaitTime = Wrapper.subtitles.CalcTimeOfString(fixerMsg)+5
        Wrapper.v.VSpeak(vMsg)
        Wrapper.cron.After(vFixerWaitTime, function()
            Wrapper.npc.NPCSpeakExtended(fixerMsg, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
        end, {})
        Wrapper.cron.After(
            vMsgWaitTime+vFixerWaitTime,
            function()
                local mercInfo = Wrapper.merc.GenerateRandomMeetingData(Wrapper.merc.GetMeleeWeapon())
                local msg = "Hey V! Here is where you meet your brawler merc:\n" ..
                mercInfo.mercLocation.name.. " in " .. mercInfo.mercDistrict.Name
                Wrapper.phoneControl.SendMessageNotification(
                    PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME,
                    msg,
                    msg
                )
                Wrapper.phoneControl.AddContactMessage(
                    PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME,
                    msg,
                    msg
                )
                 
            end)
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER_ASK_BACKUP, '(Assault)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        local vMsg = Wrapper.v.VQuestAskMercAssaultRandomLine()
        local vMsgWaitTime = Wrapper.subtitles.CalcTimeOfString(
            vMsg
        )+2
        local fixerMsg = Wrapper.npc.NPCResponseAskBackupLinesRandomLine() .. ". Remember, from now on, you will be sharing your compensation with the other mercs"
        local vFixerWaitTime = Wrapper.subtitles.CalcTimeOfString(fixerMsg)+5
        Wrapper.v.VSpeak(vMsg)
        Wrapper.cron.After(vFixerWaitTime, function()
            Wrapper.npc.NPCSpeakExtended(fixerMsg, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
        end, {})
        Wrapper.cron.After(
            vMsgWaitTime+vFixerWaitTime, 
            function()
                local mercInfo = Wrapper.merc.GenerateRandomMeetingData(Wrapper.merc.GetAssaultWeapon())
                local msg = "Hey V! Here is where you meet your assault merc:\n" ..
                mercInfo.mercLocation.name.. " in " .. mercInfo.mercDistrict.Name
                Wrapper.phoneControl.SendMessageNotification(
                    PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME,
                    msg,
                    msg
                )
                Wrapper.phoneControl.AddContactMessage(
                    PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME,
                    msg,
                    msg
                )
            end)
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER_ASK_BACKUP, '(Sniper)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        local vMsg = Wrapper.v.VQuestAskMercSniperRandomLine()
        local vMsgWaitTime = Wrapper.subtitles.CalcTimeOfString(
            vMsg
        )+2
        local fixerMsg = Wrapper.npc.NPCResponseAskBackupLinesRandomLine() .. ". Remember, from now on, you will be sharing your compensation with the other mercs"
        local vFixerWaitTime = Wrapper.subtitles.CalcTimeOfString(fixerMsg)+5
        Wrapper.v.VSpeak(vMsg)
        Wrapper.cron.After(vFixerWaitTime, function()
            Wrapper.npc.NPCSpeakExtended(fixerMsg, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA) 
        end, {})
        Wrapper.cron.After(
            vMsgWaitTime+vFixerWaitTime, 
            function()
                local mercInfo = Wrapper.merc.GenerateRandomMeetingData(Wrapper.merc.GetSniperWeapon())
                local msg = "Hey V! Here is where you meet your sniper merc:\n" ..
                mercInfo.mercLocation.name.. " in " .. mercInfo.mercDistrict.Name
                Wrapper.phoneControl.SendMessageNotification(
                    PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME,
                    msg,
                    msg
                )
                Wrapper.phoneControl.AddContactMessage(
                    PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME,
                    msg,
                    msg
                )
            end)
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER_ASK_BACKUP, '(Shotgunner)', function()
        if not Wrapper.npc.VIsNotInCombat() then
            Wrapper.hud.Warning("UNAVAILABLE IN COMBAT")
            return
        end
        local vMsg = Wrapper.v.VQuestAskMercHeavyOrShotgunRandomLine()
        local vMsgWaitTime = Wrapper.subtitles.CalcTimeOfString(
            vMsg
        )+2
        local fixerMsg = Wrapper.npc.NPCResponseAskBackupLinesRandomLine() .. ". Remember, from now on, you will be sharing your compensation with the other mercs"
        local vFixerWaitTime = Wrapper.subtitles.CalcTimeOfString(fixerMsg)+5
        Wrapper.v.VSpeak(vMsg)
        Wrapper.cron.After(vFixerWaitTime, function()
            Wrapper.npc.NPCSpeakExtended(fixerMsg, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
        end, {})
        Wrapper.cron.After(
            vMsgWaitTime+vFixerWaitTime, 
            function()
                local mercInfo = Wrapper.merc.GenerateRandomMeetingData(Wrapper.merc.GetShotgunnerWeapon())
                local msg = "Hey V! Here is where you meet your shotgunner merc:\n" ..
                mercInfo.mercLocation.name.. " in " .. mercInfo.mercDistrict.Name
                Wrapper.phoneControl.SendMessageNotification(
                    PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME,
                    msg,
                    msg
                )
                Wrapper.phoneControl.AddContactMessage(
                    PHONE_CONTROL_PREFIX .. FIXER_DISPLAY_NAME,
                    msg,
                    msg
                )
            end)
    end)
end

function Wrapper.FixerQuestMenuAddEvents()
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER_QUEST, '(Ask for reward)', function()
        local msg = Wrapper.v.RewardAskLinesRandomLine()
        Wrapper.v.VSpeak(msg)
        local waitTime = Wrapper.subtitles.CalcTimeOfString(
            msg
        )+2
        Wrapper.cron.After(
            waitTime,
            function()
                local locationCount = #Wrapper.quest.questLocations > 0
                if not locationCount then
                    local noContract = Wrapper.npc.NPCQuestNoContractLinesRandomLine()
                    Wrapper.npc.NPCSpeakExtended(noContract, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)

                    local noContractWaitTime = Wrapper.subtitles.CalcTimeOfString(noContract)+2
                    Wrapper.cron.After(noContractWaitTime, function()
                        Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
                    end)
                    return
                end
                if not Wrapper.quest.done then
                    -- local reward = Wrapper.quest.questLocations[#Wrapper.quest.questLocations].reward
                    local reward = " " .. tostring(Wrapper.quest.questLocations[#Wrapper.quest.questLocations].questReward) .. " eddies"
                    Wrapper.npc.NPCSpeakExtended(Wrapper.npc.NPCAskRewardLinesRandomLine(reward), FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
                    Wrapper.cron.After(4, function()
                        Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
                    end, {})
                else
                    local noContract = Wrapper.npc.NPCQuestNoContractLinesRandomLine()
                    Wrapper.npc.NPCSpeakExtended(noContract, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
                end
            end, {}
        )
        
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER_QUEST, '(Ask for backup)', function()                
        local vMsg = Wrapper.v.QuestAskBackupRandomLine()
        Wrapper.merc.CleanUpDeadMercs()
        local followers = AIControl.GetFollowers()
        for i = 1, #followers do
            if not Wrapper.npc.PeekTargetInfo(followers[i]) then
                Wrapper.npc.NPCSpeakExtended("You are not in need of help, since you are not alone. Anything else?", FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
                Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
                return    
            end
        end
        if #Wrapper.merc.data >= Wrapper.merc.maxMercs then            
            Wrapper.npc.NPCSpeakExtended("I think you have enough people for the job. Anything else?", FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
            Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
            return
        end
        local vMsgWaitTime = Wrapper.subtitles.CalcTimeOfString(vMsg)+2
        local fixerMsg = Wrapper.npc.NPCQuestAskSpecialtyLinesRandomLine()
        local vFixerWaitTime = Wrapper.subtitles.CalcTimeOfString(fixerMsg)+4
        
        Wrapper.v.VSpeak(vMsg)
        Wrapper.cron.After(vMsgWaitTime, function()
            local justASecMsg = Wrapper.npc.NPCJustASecLinesRandomLine()
            local justASecMsgWaitTime = Wrapper.subtitles.CalcTimeOfString(justASecMsg)+2
            Wrapper.npc.NPCSpeakExtended(justASecMsg, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
            Wrapper.cron.After(justASecMsgWaitTime, function()
                Wrapper.npc.NPCSpeakExtended(fixerMsg, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
            end)
        end)
        -- the rest happens in a cron.every inside of merc
        Wrapper.cron.After(vMsgWaitTime+vFixerWaitTime, function()
            Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_ASK_BACKUP)
        end)
    end)

    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER_QUEST, '(Ask for quest location)', function()
        local msg = Wrapper.v.VAskJobsLocationRandomLine()
        Wrapper.v.VSpeak(msg)
        local waitTime = Wrapper.subtitles.CalcTimeOfString(msg)+2
        Wrapper.cron.After(waitTime, function()
            local locationCount = #Wrapper.quest.questLocations > 0
            if not locationCount then
                local noContract = Wrapper.npc.NPCQuestNoContractLinesRandomLine()
                Wrapper.npc.NPCSpeakExtended(noContract, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)

                local noContractWaitTime = Wrapper.subtitles.CalcTimeOfString(noContract)+2
                Wrapper.cron.After(noContractWaitTime, function()
                    Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
                end)
                return
            end
            if not Wrapper.quest.done then
                local locationName = Wrapper.quest.questLocations[#Wrapper.quest.questLocations].location.name
                Wrapper.npc.NPCSpeakExtended(Wrapper.npc.NPCQuestLocationLinesRandomLine(locationName), FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
                Wrapper.cron.After(4, function()
                    Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
                end, {})
            else
                local noContract = Wrapper.npc.NPCQuestNoContractLinesRandomLine()
                Wrapper.npc.NPCSpeakExtended(noContract, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
                
                local noContractWaitTime = Wrapper.subtitles.CalcTimeOfString(noContract)+2
                Wrapper.cron.After(noContractWaitTime, function()
                    Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
                end)
            end
        end)
    end)
    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER_QUEST, '(Ask about gang)', function()
        local msg = Wrapper.v.VAskGangNameRandomLine()
        Wrapper.v.VSpeak(msg)
        local waitTime = Wrapper.subtitles.CalcTimeOfString(msg)+2
        Wrapper.cron.After(waitTime, function()
            local locationCount = #Wrapper.quest.questLocations > 0
            if not locationCount then
                local noContract = Wrapper.npc.NPCQuestNoContractLinesRandomLine()
                Wrapper.npc.NPCSpeakExtended(noContract, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)

                local noContractWaitTime = Wrapper.subtitles.CalcTimeOfString(noContract)+2
                Wrapper.cron.After(noContractWaitTime, function()
                    Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
                end)
                return
            end
            if not Wrapper.quest.done then
                local gangName = Wrapper.quest.questLocations[#Wrapper.quest.questLocations].gangName
                Wrapper.npc.NPCSpeakExtended(Wrapper.npc.NPCQuestAskGangLinesRandomLine(gangName), FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
                Wrapper.cron.After(4, function()
                    Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
                end, {})
            else
                local noContract = Wrapper.npc.NPCQuestNoContractLinesRandomLine()
                Wrapper.npc.NPCSpeakExtended(noContract, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)

                local noContractWaitTime = Wrapper.subtitles.CalcTimeOfString(noContract)+2
                Wrapper.cron.After(noContractWaitTime, function()
                    Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
                end)
            end
        end)
    end)

    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER_QUEST, '(Cancel / Finish Contract)', function()
        local msg = 'Need to cancel the contract'
        Wrapper.v.VSpeak(msg)
        local waitTime = Wrapper.subtitles.CalcTimeOfString(msg)+2
        Wrapper.cron.After(waitTime, function()
            local locationCount = #Wrapper.quest.questLocations > 0
            if not locationCount then
                local noContract = Wrapper.npc.NPCQuestNoContractLinesRandomLine()
                Wrapper.npc.NPCSpeakExtended(noContract, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
                return
            end
            if Wrapper.quest.done then
                local msg = Wrapper.npc.NPCSuccessQuestLinesRandomLine() .. ". " .. Wrapper.npc.NPCQuestSendEddiesLinesRandomLine()
                local msgWaitTime = Wrapper.subtitles.CalcTimeOfString(msg)+5
                Wrapper.npc.NPCSpeakExtended(msg, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
                Wrapper.cron.After(msgWaitTime, function()
                    local lifePath = GameUtils.GetLifePath(Game.GetPlayer())
                    if not lifePath then
                        return
                    end                    
                    Wrapper.v.VSpeak(Wrapper.v.QuestDoneSuccessfulByeRandomLine())
                end)
                Wrapper.quest.DisplayDone()
                local reward = math.floor(Wrapper.quest.questLocations[#Wrapper.quest.questLocations].questReward - 0.5)
                print('reward:' .. tostring(reward))
                Game.AddToInventory("Items.money", reward)
            else
                local firstMessage = Chance50()
                local percentageDead = Wrapper.quest.GetPercentageDead()
                local msg = ""
                if percentageDead ~= 0 then
                    msg =  ". Only " .. tostring(Wrapper.quest.GetPercentageDead()) .. " percent dead. Sending you the eddies."
                end
                if firstMessage then
                    msg = Wrapper.npc.NPCCancelQuestLinesRandomLine() .. msg
                else
                    msg = Wrapper.npc.NPCQuestUnfinishedLinesRandomLine() .. msg
                end
                Wrapper.npc.NPCSpeakExtended(msg, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA)
                Wrapper.quest.DisplayFail()
                Wrapper.phoneControl.AddContactMessage( 
                    PHONE_CONTROL_PREFIX .. FIXER_NPC_DATA.display_name,  
                    "Contract canceled",
                    "Contract canceled"
                )
                if percentageDead ~= 0 then                    
                    local reward = math.floor((Wrapper.quest.questLocations[#Wrapper.quest.questLocations].questReward * Wrapper.quest.GetPercentageDead()) - 0.5)
                    print('reward:' .. tostring(reward))
                    Game.AddToInventory("Items.money", reward)
                end
            end
            FIXER_HOTLINE_STATE = FIXER_HOTLINE_JOB_IDLE
            Wrapper.quest.Dispose()
        end)
    end)

    Wrapper.menu.OnMenuItemClicked(Wrapper.DIALOG_FIXER_QUEST, '(Get New Contract)', function()
        local msg = Wrapper.v.VAskNewContractRandomLine()
        Wrapper.v.VSpeak(msg)
        local waitTime = Wrapper.subtitles.CalcTimeOfString(msg)+2
        Wrapper.cron.After(waitTime, function()
            local locationCount = #Wrapper.quest.questLocations > 0  
            if Wrapper.quest.done or not locationCount then
                FIXER_HOTLINE_STATE = FIXER_HOTLINE_JOB_IDLE
                Wrapper.quest.Dispose()
                Wrapper.quest.GenerateKillJob()
                FIXER_HOTLINE_STATE = FIXER_HOTLINE_JOB_STARTED
                
                -- CyberNPC.NPCSpeak('kill job fixer', FIXER_NPC_DATA.id_hash, FIXER_NPC_DATA.display_name, Wrapper.quest.GetCurrentQuest())
                local q = Wrapper.quest.GetCurrentQuest()
                Wrapper.hud.Warning("INCOMING DATA TRANSFER")
                Backend.Aify(
                    'kill job fixer',
                    q,
                    Wrapper.v.GetPlayerInfoForServer(),
                    FIXER_NPC_DATA,
                    function(response)
                        local generatedText = Backend.GetJsonResponse(response)
                        if not generatedText or not generatedText.text then
                            print("no generated text found for kill job")
                        return
                        end
                        Wrapper.phoneControl.SendMessageNotification(
                            "cyberllama_" .. FIXER_NPC_DATA.display_name,
                            '\n' .. 'JOB: ' .. 'KILL' ..
                            '\n' .. 'LOCATION: ' .. q.location.name .. ' in ' .. q.districtName ..
                            '\n' .. 'GANG:' .. q.gangName
                        )
                        Wrapper.phoneControl.AddContactMessage(
                        "cyberllama_" .. FIXER_NPC_DATA.display_name,
                        generatedText.text ..
                            '\n' .. 'JOB: ' .. 'KILL' ..
                            '\n' .. 'LOCATION: ' .. q.location.name .. ' in ' .. q.districtName ..
                            '\n' .. 'GANG:' .. q.gangName
                        )
                        CyberNPC.NPCSpeakExtended(generatedText.text, FIXER_NPC_DATA.id_hash, FIXER_NPC_DATA.display_name, FIXER_NPC_DATA, q)
                    end
                )
            else
                local contractPending = "You have an open contract. Finish the job. Then we can discuss."
                Wrapper.npc.NPCSpeakExtended(contractPending, FIXER_CONTACT_ID, FIXER_DISPLAY_NAME, FIXER_NPC_DATA, FIXER_NPC_DATA)
                Wrapper.cron.After(4, function()
                    Wrapper.menu.ActivateMenu(Wrapper.DIALOG_FIXER_QUEST)
                end, {})
            end
        end)
    end)
end

function Wrapper.NPCIntroAddEvents()
    print("NPCIntroAddEvents")
    for idx = 1, #(Wrapper.DialogOptionsNPCIntro) do
        print(Wrapper.DialogOptionsNPCIntro[idx].text)
        if Wrapper.DialogOptionsNPCIntro[idx].text == 'Nevermind' then
            -- do nothing
            Wrapper.menu.OnMenuItemClicked(
                Wrapper.DIALOG_NPC_INTRO,
                Wrapper.DialogOptionsNPCIntro[idx].text,
                function()
                    -- Backend.Prompt(
                    -- )
                    Wrapper.interactionUI.hideHub()
                end)
        else
            Wrapper.menu.OnMenuItemClicked(
                Wrapper.DIALOG_NPC_INTRO,
                Wrapper.DialogOptionsNPCIntro[idx].text,
                function()
                    print("npc intro - " .. Wrapper.DialogOptionsNPCIntro[idx].text)
                    Wrapper.backend.PromptContinue(
                        Wrapper.DialogOptionsNPCIntro[idx].text,
                        '',
                        Wrapper.getPlayerInfo(),
                        Wrapper.getNpcDataInfo(),
                        function(response)
                            Wrapper.OnResponse(response, Wrapper.DIALOG_NPC_INTRO, Wrapper.DialogOptionsNPCIntro[idx].text)
                        end
                    )
                end)
        end
    end
end

function Wrapper.Error(data, menu, text)
    print('Error')
    print(data)
end

function Wrapper.Success(data, menu, text)
    print('Success')
    print(data)
end


function Wrapper.OnResponse(response, menu, text)
    print("Wrapper.OnResponse")
    if response == nil then
        print("Wrapper.OnResponse: response is nil")
        return
    end
    if response:GetStatusCode() ~= 200 then
        Wrapper.Error({
            error = response:GetText()
        })
        return
    end
    local contentType = response:GetHeader("Content-Type")
    -- if contentType ~= "application/json; charset=utf-8" then
    if contentType ~= "application/json" then        
        Wrapper.Success({
            error = "Request failed, Json expected instead of '" .. contentType .. "'."
        })
        return
    end
    local res = response:GetText()
    print(res)
    local content = json.decode(res)
    print("calling Wrapper.Sucess inside of Wrapper.OnResponse...")
    Wrapper.Success(content, menu, text)
end

function Wrapper.Vision(menu, text)
    Wrapper.backend.Prompt(
        "vision",
        '',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end

function Wrapper.Audio(menu, text)
    if Wrapper.AudioOn == false then
        Wrapper.AudioOn = true
        Wrapper.backend.Recstart(
            Wrapper.getPlayerInfo(),
            Wrapper.getNpcDataInfo(),
            function(response)
                Wrapper.OnResponse(response, menu, text)
            end
        )
    else
        Wrapper.AudioOn = false
        Wrapper.backend.Recstop(
            Wrapper.getPlayerInfo(),
            Wrapper.getNpcDataInfo(),
            function(response)
                Wrapper.OnResponse(response, menu, text)
            end
        )
    end
end

function Wrapper.Quest(menu, text)
    local quest = Wrapper.quest.GenerateKillJob()
    
    Wrapper.backend.PromptContinue(
        'quest',
        quest,
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end

function Wrapper.KillJobFixer(menu, text)
    local quest = Wrapper.quest.GenerateKillJob()
    
    Wrapper.backend.PromptContinue(
        'kill job fixer',
        quest,
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end


function Wrapper.Food(menu, text)
    Wrapper.backend.PromptContinue(
        'food',
        '',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end
function Wrapper.Drink(menu, text)
    Wrapper.backend.PromptContinue(
        'drink',
        '',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end
function Wrapper.Insult(menu, text)
    Wrapper.backend.PromptContinue(
        'insult',
        '',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end
function Wrapper.Brag(menu, text)
    Wrapper.backend.PromptContinue(
        'brag',
        '',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end
function Wrapper.Joke(menu, text)
    Wrapper.backend.PromptContinue(
        'joke',
        '',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end
function Wrapper.Flirt(menu, text)
    Wrapper.backend.PromptContinue(
        'flirt',
        '',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end
function Wrapper.Talk(menu, text)
    Wrapper.backend.PromptClientContinue(
        'talk',
        'PROMPT_TTS_PLAYER_FEED',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end

function Wrapper.MakeTitle(menu, text)
    Wrapper.backend.MakeTitle(
        'maketitle',
        '',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end)
end

function Wrapper.ForgetConversations(menu, text)
    Wrapper.backend.ForgetConversations(
        'forgetconversations',
        '',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end)
end


function Wrapper.MoveHere(menu, text)
    
    Wrapper.v.VSpeak(Wrapper.v.VMoveHereRandomLine())
    
    Wrapper.cron.After(4, function()
        CyberNPC.NPCSpeakLast(CyberNPC.NPCShortAcknowledgeRandomLine())
        
        local pos = Wrapper.v.GetPosition(10, 0)
        AIControl.MoveTo(CyberNPC.LastNPCTarget.obj, pos, 10, moveMovementType.Sprint)

    end, {})
    -- Wrapper.backend.PromptContinue(
    --     'move here',
    --     '',
    --     Wrapper.getPlayerInfo(),
    --     Wrapper.getNpcDataInfo(),
    --     function(response)
    --         Wrapper.OnResponse(response, menu, text)
    --     end
    -- )
end
function Wrapper.BackgroundStory(menu, text)
    Wrapper.backend.PromptContinue(
        'background story',
        '',
        Wrapper.getPlayerInfo(),
        Wrapper.getNpcDataInfo(),
        function(response)
            Wrapper.OnResponse(response, menu, text)
        end
    )
end
function Wrapper.AddContact(menu, text)
    print("Wrapper.AddContact")
    local playerInfo = Wrapper.getPlayerInfo()
    local npcInfo = Wrapper.getNpcDataInfo()
    -- fix npc names inside of afterlife (names are Customer/Patron??)
    if CyberNPC.IsUnnamedNPC(npcInfo) then
        npcInfo.display_name = CyberNPC.NPCRandomNickName(npcInfo.appearance)
    end
    if CyberNPC.IsResident(npcInfo) then
        npcInfo.display_name = CyberNPC.NPCRandomName()
    end

    local addLocation = playerInfo.p_district
    if Wrapper.phoneControl.HasContactWithDisplayName(npcInfo.display_name) or
    Wrapper.phoneControl.HasContactWithRecordId(npcInfo.record_id) then
        CyberNPC.NPCSpeakLast("You got my number already?")
        return
    else
        CyberNPC.NPCSpeakLast(CyberNPC.NPCMyNumberLinesRandomLine())
    end
    if Wrapper.merc.IsAMerc(npcInfo) then
        if not Wrapper.phoneControl.AddContact(npcInfo, "PhoneAvatars.Avatar_Unknown", "Merc") then
            return
        end
    else 
        if not Wrapper.phoneControl.AddContact(npcInfo, "PhoneAvatars.Avatar_Unknown", addLocation.main .. ', ' .. addLocation.sub) then        
            return
        end
    end
    Wrapper.cron.After(2, function()
        if not CyberNPC.LastNPCTarget.obj then
            return
        end
        if CyberNPC.LastNPCTarget.obj.Dispose then
            print("CyberNPC.LastNPCTarget.obj.Dispose found")
            CyberNPC.LastNPCTarget.obj:Dispose()
        end
        if CyberNPC.LastNPCTarget.obj.GetEntity then
            print("CyberNPC.LastNPCTarget.obj.GetEntity found")
            CyberNPC.LastNPCTarget.obj:GetEntity():Destroy()
        end
        
        Wrapper.v.StopCloseEyes()
        Wrapper.v.BlinkFast()
    end, {})
    Wrapper.v.CloseEyes()
    
    GetPlayer():PlaySoundEvent("ui_jingle_quest_update")
    Wrapper.hud.QuestMessage(npcInfo.display_name .. ' added to contacts')
    
end

function Wrapper.Dismiss(menu, text)
    local playerInfo = Wrapper.getPlayerInfo()
    local npcInfo = Wrapper.getNpcDataInfo()
    local addLocation = playerInfo.p_district
    
    CyberNPC.NPCStopAnimation()
    CyberNPC.NPCSpeakLast("Ok V, catch you later")
    CyberNPC.LastNPCTarget.record_id_scanned = nil
    CyberNPC.LastNPCTarget.display_name_scanned = nil
    Wrapper.v.hasFollower = false
    -- CyberNPC.LastNPCTarget.is_follower = false
    
    Wrapper.cron.After(2, function()
        if not CyberNPC.LastNPCTarget.obj then
            return
        end
        if AIControl.IsFollower(CyberNPC.LastNPCTarget.obj) then
            print("Dismiss: AIControl.FreeFollower")
            AIControl.FreeFollower(CyberNPC.LastNPCTarget.obj, true)
            -- let me try this
            if CyberNPC.LastNPCTarget.obj.Dispose then
                print("Dismiss: CyberNPC.LastNPCTarget.obj:Dispose()")
                CyberNPC.LastNPCTarget.obj:Dispose()
            end
            -- get rid of flag telling that the npc is spawned
            
        end
        if Wrapper.phoneControl.HasContactWithDisplayName(npcInfo.display_name) then
            local contact = Wrapper.phoneControl.GetContactsNPCDataByDisplayName(npcInfo.display_name)
            if not contact then
                print("Dismiss: contact with display name: " .. npcInfo.display_name .. " not found")
            else
                -- allows respawning of a new npc or an old one
                print("Dismiss: clear contact spawn flags")
                contact.display_name_changed = 0
                contact.spawned = false
                contact.dismissed = true
            end
            if CyberNPC.LastNPCTarget.obj then
                if CyberNPC.LastNPCTarget.obj.Dispose then
                    print("Dismiss: CyberNPC.LastNPCTarget.obj:Dispose()")
                    CyberNPC.LastNPCTarget.obj:Dispose()
                end
                if CyberNPC.LastNPCTarget.obj.GetEntity then
                    print("Dismiss: CyberNPC.LastNPCTarget.obj:GetEntity():Destroy()")
                    CyberNPC.LastNPCTarget.obj:GetEntity():Destroy()
                end
            end
        else
        end

        Wrapper.v.StopCloseEyes()
        Wrapper.v.BlinkFast()
    end, {})
    Wrapper.v.CloseEyes()
    
    Wrapper.sound.PlayMenuExitSound()
    Wrapper.hud.QuestMessage(npcInfo.display_name .. ' dismissed')
end

function Wrapper.Init(menu, cron, interactionUI, subtitles, AIControl, face, quest, phoneControl, hud, backend, getPlayerDataFn, getNpcDataFn, cyberV, cyberNpc, merc, sound, successFn, errorFn)
    Wrapper.menu = menu
    Wrapper.cron = cron    
    Wrapper.interactionUI = interactionUI
    Wrapper.subtitles = subtitles
    Wrapper.AIControl = AIControl
    Wrapper.face = face
    Wrapper.quest = quest
    Wrapper.phoneControl = phoneControl
    Wrapper.hud = hud
    Wrapper.backend = backend    
    Wrapper.getPlayerInfo = getPlayerDataFn
    Wrapper.getNpcDataInfo = getNpcDataFn
    Wrapper.v = cyberV
    Wrapper.npc = cyberNpc
    Wrapper.merc = merc
    Wrapper.sound = sound
    Wrapper.lastVLines = {}
    if successFn ~= nil then
        Wrapper.Success = successFn
        print('successFn set')
    end
    if errorFn ~= nil then
        Wrapper.Error = errorFn
        print('errorFn set')
    end

    Wrapper.DialogOptionsMain = {
        -- { text = "(Vision)", icon = interactionUI.DISTRACT_ICON },
        { text = "(Audio)", icon = interactionUI.TAKE_CONTROL_ICON },
        -- { text = "(Quest)", icon = interactionUI.COURIER_ICON },
        -- { text = "(Food)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        -- { text = "(Drink)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Insult)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Brag)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Joke)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Flirt)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Talk)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        -- { text = "(Move here)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Background story)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Add Contact)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }

    Wrapper.DialogOptionsFriend = {
        -- { text = "(Vision)", icon = interactionUI.DISTRACT_ICON },
        { text = "(Audio)", icon = interactionUI.TAKE_CONTROL_ICON },
        -- { text = "(Quest)", icon = interactionUI.COURIER_ICON },
        { text = "(Food)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Drink)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Insult)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Brag)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Joke)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Flirt)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Talk)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        -- { text = "(Move here)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Background story)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Add Contact)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }

    Wrapper.DialogOptionsFollower = {
        { text = "(Vision)", icon = interactionUI.DISTRACT_ICON },
        { text = "(Audio)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "(Quest)", icon = interactionUI.COURIER_ICON },
        { text = "(Food)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Drink)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Insult)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Brag)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Joke)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Flirt)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Talk)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Move here)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Background story)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Dismiss)", icon = interactionUI.ON_OFF_ICON },
        { text = "(Add Contact)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }

    -- sub menus for followers
    Wrapper.DialogOptionsSubMenuMainFollower = {
        { text = "(Basic Needs)", icon = interactionUI.DISTRACT_ICON },
        { text = "(Social)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "(Job)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "(Move Here)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Add Contact)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Dismiss)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }

    Wrapper.DialogOptionsBasicNeedsFollower = {
        { text = "(Try Give Food)", icon = interactionUI.DISTRACT_ICON },
        { text = "(Try Give Drink)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "(Ask About Food)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Ask About Drinking)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Display Stats)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }
    
    Wrapper.DialogOptionsSocialFollower = {
        { text = "(Vision)", icon = interactionUI.DISTRACT_ICON },
        { text = "(Audio)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "(Insult)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Brag)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Dance)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "(Smoke Together)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "(Joke)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Flirt)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Kiss)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Talk)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Background Story)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Forget Conversations)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }

    Wrapper.DialogOptionsAskBackupOptions = {
        { text = "(Melee)", icon = interactionUI.DISTRACT_ICON },
        { text = "(Shotgunner)", icon = interactionUI.DISTRACT_ICON },
        { text = "(Assault)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "(Sniper)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "(Random)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }

    Wrapper.DialogOptionsJobFollower = {
        { text = "(Quest Together)", icon = interactionUI.DISTRACT_ICON },
        { text = "(Send To Quest)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "(Send Home)", icon = interactionUI.TAKE_CONTROL_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }

    Wrapper.DialogOptionsFixer = {
        { text = "(Quest)", icon = interactionUI.COURIER_ICON },
        { text = "(Brag)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        { text = "(Joke)", icon = interactionUI.CHANGE_TO_FRIENDLY_ICON },
        -- { text = "(Add Contact)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }

    Wrapper.DialogOptionsFixerQuest = {
        { text = "(Ask for reward)", icon = interactionUI.COURIER_ICON },
        { text = "(Ask for backup)", icon = interactionUI.ON_OFF_ICON },
        { text = "(Ask for quest location)", icon = interactionUI.COURIER_ICON },
        { text = "(Ask about gang)", icon = interactionUI.COURIER_ICON },
        { text = "(Cancel / Finish Contract)", icon = interactionUI.ON_OFF_ICON },
        { text = "(Get New Contract)", icon = interactionUI.ON_OFF_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }
    
    Wrapper.DialogOptionsNPCIntro = {
        { text = "(Introduce yourself)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Ask for nc residents background story)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Ask for a place to eat)", icon = interactionUI.OPEN_VENDOR_ICON },
        { text = "(Ask for a place to drink)", icon = interactionUI.OPEN_VENDOR_ICON },
        { text = "(Ask for a place for buying or selling weapons)", icon = interactionUI.OPEN_VENDOR_ICON },
        { text = "(Ask for a place for buying medicine)", icon = interactionUI.OPEN_VENDOR_ICON },
        { text = "(Ask about about an aspect of nc residents life)", icon = interactionUI.PHONE_CALL_ICON },
        { text = "(Ask about nc residents job)", icon = interactionUI.CLOCK_ICON },
        { text = "Nevermind",  icon = interactionUI.ON_OFF_ICON },
    }

    Wrapper.menu.SetMenu(Wrapper.DIALOG_MAIN, Wrapper.DialogOptionsMain)
    print('DIALOG_MAIN set')
    Wrapper.menu.SetMenu(Wrapper.DIALOG_FRIEND, Wrapper.DialogOptionsFriend)
    print('DIALOG_FRIEND set')
    -- the old follower menu
    Wrapper.menu.SetMenu(Wrapper.DIALOG_FOLLOWER, Wrapper.DialogOptionsFollower)
    print('DIALOG_FOLLOWER set')

    -- follower sub menus
    Wrapper.menu.SetMenu(Wrapper.DIALOG_FOLLOWER_SUB_MAIN, Wrapper.DialogOptionsSubMenuMainFollower)
    print('DIALOG_FOLLOWER_SUB_MAIN set')
    Wrapper.menu.SetMenu(Wrapper.DIALOG_FOLLOWER_SUB_NEEDS, Wrapper.DialogOptionsBasicNeedsFollower)
    print('DIALOG_FOLLOWER_SUB_NEEDS set')
    Wrapper.menu.SetMenu(Wrapper.DIALOG_FOLLOWER_SUB_SOCIAL, Wrapper.DialogOptionsSocialFollower)
    print('DIALOG_FOLLOWER_SUB_SOCIAL set')
    Wrapper.menu.SetMenu(Wrapper.DIALOG_FIXER_ASK_BACKUP, Wrapper.DialogOptionsAskBackupOptions)
    print('DIALOG_FIXER_ASK_BACKUP set')
    Wrapper.menu.SetMenu(Wrapper.DIALOG_FOLLOWER_SUB_JOB, Wrapper.DialogOptionsJobFollower)
    print('DIALOG_FOLLOWER_SUB_JOB set')

    Wrapper.menu.SetMenu(Wrapper.DIALOG_FIXER, Wrapper.DialogOptionsFixer)
    print('DIALOG_FIXER set')    
    Wrapper.menu.SetMenu(Wrapper.DIALOG_FIXER_QUEST, Wrapper.DialogOptionsFixerQuest)
    print('DIALOG_FIXER_QUEST set')

    Wrapper.menu.SetMenu(Wrapper.DIALOG_NPC_INTRO, Wrapper.DialogOptionsNPCIntro)
    print('DIALOG_NPC_INTRO set')
    Wrapper.menu.SetMenu(Wrapper.DIALOG_VLINES, Wrapper.lastVLines)
    print('DIALOG_VLINES set')

    Wrapper.MainMenuAddEvents()
    print('MainMenuAddEvents set')
    Wrapper.MainMenuFriendEvents()
    print('MainMenuFriendEvents set')
    Wrapper.MainMenuFollowerEvents()
    print('MainMenuFollowerEvents set')
    Wrapper.FixerMenuAddEvents()
    print('FixerMenuAddEvents set')
    Wrapper.FixerQuestMenuAddEvents()
    print('FixerQuestMenuAddEvents set')
    Wrapper.FixerAskBackupMenuAddEvents()
    print('FixerAskBackupMenuAddEvents set')
    Wrapper.NPCIntroAddEvents()
    print('NPCIntroAddEvents set')

    -- sub menu events follower
    Wrapper.FollowerSubMenuEvents()    
    print("FollowerSubMenuEvents set")
    Wrapper.FollowerSubNeedsEvents()
    print("FollowerSubNeedsEvents set")
    Wrapper.FollowerSubSocialEvents()
    print("FollowerSubSocialEvents set")
    Wrapper.FollowerSubJobEvents()
    print("FollowerSubJobEvents set")
end


return Wrapper