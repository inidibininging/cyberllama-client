
CALL_THRESHOLD_IN_SEC=30

local CyberllamaBackendAPI = {
    baseHost = "https://127.0.0.1:8089/",

    endpointComment = "comment",
    endpointExpand = "expand",
    endpointAify = "aify",
    endpointPrompt = "prompt",
    endpointPromptContinue = "promptcontinue",
    endpointPromptClientContinue = "promptclient",
    endpointMakeTitle = "maketitle",
    endpointTts = "tts",
    endpointRevlookup = "revlookup",
    endpointNPCSync = "npcsync",
    endpointReset = "reset",
    endpointRecstart = "recstart",
    endpointRecstop = "recstop",
    endpointSavesession = "savesession",
    endpointForgetConversation = "forgetconversations",
    fakeAsync = nil,
    lockComment = false,
    lockExpand = false,
    lockAify = false,
    lockPrompt = false,
    lockPromptContinue = false,
    lockPromptClientContinue = false,
    lockTts = false,
    lockTtsRequests = 0,
    -- used in order to snap out of it
    unlockRequestCount = 2,
    -- lockVSpeak = false,
    -- lockNPCSpeak = false,
    lockRevlookup = false,
    lockNPCSync = false,
    lockReset = false,
    lockRecstart = false,
    lockRecstop = false,
    lockSavesession = false,
    lockMakeTitle = false,
    lockForgetConversation = false,
    requestTime = 0,
    asyncRequests = {},
    promptContinueRoundTripInSec = 2,
    listener = {},
    combatState = nil,
}


function CyberllamaBackendAPI.Init(fakeAsync)
    CyberllamaBackendAPI.fakeAsync = fakeAsync
end

function CyberllamaBackendAPI.PostRequest(endpoint, data, thenFn)
    CyberllamaBackendAPI.requestTime = os.time()
    local proxyObj = {
        post = {
            args = { "handle:HttpResponse" },
            callback = function(response) thenFn(response, endpoint) end
        }
    }


---@diagnostic disable-next-line: undefined-global
    CyberllamaBackendAPI.listener = NewProxy(proxyObj)
---@diagnostic disable-next-line: undefined-global
    local callback = HttpCallback.Create(CyberllamaBackendAPI.listener:Target(), CyberllamaBackendAPI.listener:Function("post"))
---@diagnostic disable-next-line: undefined-global
    AsyncHttpClient.Post(callback, CyberllamaBackendAPI.baseHost .. "/" .. endpoint, data)
end

function CyberllamaBackendAPI.GetJsonResponse(response)
    print("CyberllamaBackendAPI.GetJsonResponse")
    if response == nil then
        print("CyberllamaBackendAPI.GetJsonResponse: response is nil")
        return nil
    end
    if response:GetStatusCode() ~= 200 then
        print("CyberllamaBackendAPI.GetJsonResponse: " .. response:GetText())
        return nil
    end
    local contentType = response:GetHeader("Content-Type")
    -- if contentType ~= "application/json; charset=utf-8" then
    if contentType ~= "application/json" then
        print("CyberllamaBackendAPI.GetJsonResponse: Request failed, Json expected instead of '" .. contentType .. "'.")
        return nil
    end
    local res = response:GetText()
    print(res)
    local content = json.decode(res)
    return content
end

function CyberllamaBackendAPI.Prompt(content, args, playerData, npcData, thenFn)
    if CyberllamaBackendAPI.lockPrompt then
        return
    end
    if CyberllamaBackendAPI.combatState == 1 then
        return
    end
    CyberllamaBackendAPI.lockPrompt = true
    local data = json.encode({
        prompt = content,
        prompt_args = args,
        stats = playerData,
        npc = npcData
    })
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointPrompt,
        data,
        function(response)
            CyberllamaBackendAPI.lockPrompt = false
            thenFn(response)
        end
    )
end

function CyberllamaBackendAPI.MakeTitle(content, args, playerData, npcData, thenFn)
    -- if CyberllamaBackendAPI.lockPromptContinue then
    --     print("promptcontinue is locked")
    --     return
    -- end
    if CyberllamaBackendAPI.combatState == 1 then
        return
    end
    CyberllamaBackendAPI.lockMakeTitle = true
    local data = json.encode({
        prompt = content,
        prompt_args = args,
        stats = playerData,
        npc = npcData
    })
    print("Backend.MakeTitle - POST")
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointMakeTitle,
        data,
        function(response)            
            print("Backend.MakeTitle - DONE")
            CyberllamaBackendAPI.lockMakeTitle = false
            if thenFn then
                thenFn(response)
            end
        end
    )
end


function CyberllamaBackendAPI.ForgetConversations(content, args, playerData, npcData, thenFn)
    -- if CyberllamaBackendAPI.lockPromptContinue then
    --     print("promptcontinue is locked")
    --     return
    -- end
    if CyberllamaBackendAPI.combatState == 1 then
        return
    end
    CyberllamaBackendAPI.lockForgetConversation = true
    local data = json.encode({
        prompt = content,
        prompt_args = args,
        stats = playerData,
        npc = npcData
    })
    print("Backend.ForgetConversations - POST")
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointForgetConversation,
        data,
        function(response)            
            print("Backend.ForgetConversations - DONE")
            CyberllamaBackendAPI.endpointForgetConversation = false
            if thenFn then
                thenFn(response)
            end
        end
    )
end

-- function CyberllamaBackendAPI.PostRequestAsync(endpoint, data, thenFn)
--     CyberllamaBackendAPI.requestTime = os.time()
--     CyberllamaBackendAPI.asyncRequests[CyberllamaBackendAPI.requestTime] = CyberllamaBackendAPI.fakeAsync.Create(
--     function(this)
--         this.continueExecution = false
--         local proxyObj = {
--             post = {
--                 args = { "handle:HttpResponse" },
--                 callback = function(response)
--                     this.responseJson = CyberllamaBackendAPI.GetJsonResponse(response)
--                     thenFn(response, endpoint)
--                     this.continueExecution = true
--                 end
--             }
--         }
    
--     ---@diagnostic disable-next-line: undefined-global
--         CyberllamaBackendAPI.listener = NewProxy(proxyObj)
--     ---@diagnostic disable-next-line: undefined-global
--         local callback = HttpCallback.Create(CyberllamaBackendAPI.listener:Target(), CyberllamaBackendAPI.listener:Function("post"))
--     ---@diagnostic disable-next-line: undefined-global
--         AsyncHttpClient.Post(callback, CyberllamaBackendAPI.baseHost .. "/" .. endpoint, data)
--         Cron.Every(1, function()
            
--         end)
--     end)    
-- end

-- prompt continue cannot have a lock since the response function needs to call the promptcontinue endpoint
function CyberllamaBackendAPI.PromptContinue(content, args, playerData, npcData, thenFn)
    -- if CyberllamaBackendAPI.lockPromptContinue then
    --     print("CyberllamaBackendAPI.PromptContinue: LOCKED Can't do TTS.")
    --     return
    -- end
    if CyberllamaBackendAPI.combatState == 1 then
        return
    end
    CyberllamaBackendAPI.lockPromptContinue = true
    local data = json.encode({
        prompt = content,
        prompt_args = args,
        stats = playerData,
        npc = npcData
    })
    print("Backend.PromptContinue - POST")
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointPromptContinue,
        data,
        function(response)
            CyberllamaBackendAPI.promptContinueRoundTripInSec = os.difftime(os.time(), CyberllamaBackendAPI.requestTime)            
            print("Backend.PromptContinue - DONE")
            CyberllamaBackendAPI.lockPromptContinue = false
            if thenFn then
                thenFn(response)
            end
        end
    )
end

function CyberllamaBackendAPI.PromptClientContinue(content, args, playerData, npcData, thenFn)
    if CyberllamaBackendAPI.lockPromptClientContinue then
        print("CyberllamaBackendAPI.PromptClientContinue: LOCKED Can't do TTS.")
        return
    end
    if CyberllamaBackendAPI.combatState == 1 then
        return
    end
    CyberllamaBackendAPI.lockPromptClientContinue = true
    local data = json.encode({
        prompt = content,
        prompt_args = args,
        stats = playerData,
        npc = npcData
    })
    print("Backend.PromptClientContinue - POST")
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointPromptClientContinue,
        data,
        function(response)
            CyberllamaBackendAPI.promptContinueRoundTripInSec = os.difftime(os.time(), CyberllamaBackendAPI.requestTime)            
            print("Backend.PromptClientContinue - DONE")
            CyberllamaBackendAPI.lockPromptClientContinue = false
            if thenFn then
                thenFn(response)
            end
        end
    )
end

function CyberllamaBackendAPI.IsPossibleTimeout()
    local lastCallInSeconds = os.difftime(os.time(), CyberllamaBackendAPI.requestTime)
    return lastCallInSeconds > CALL_THRESHOLD_IN_SEC
end

function CyberllamaBackendAPI.Aify(topic, args, playerData, npcData, thenFn)
    if CyberllamaBackendAPI.lockAify and CyberllamaBackendAPI.IsPossibleTimeout() == false then
        return
    end
    CyberllamaBackendAPI.lockAify = true
    local data = json.encode({
        prompt = topic,
        prompt_args = args,
        stats = playerData,
        npc = npcData
    })
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointAify,
        data,
        function(response)
            CyberllamaBackendAPI.lockAify = false
            thenFn(response)
        end
    )
end


function CyberllamaBackendAPI.Tts(textContent, npcId, voiceUsed, ttsEngine, additionalArgs, playerData, npcData, thenFn)
    if 
        CyberllamaBackendAPI.lockTts and 
        CyberllamaBackendAPI.IsPossibleTimeout() == false then        
        print("CyberllamaBackendAPI.lockTtsRequests")
        print(CyberllamaBackendAPI.lockTtsRequests)
        if CyberllamaBackendAPI.lockTtsRequests > CyberllamaBackendAPI.unlockRequestCount then
            -- reset the counter
            print("CyberllamaBackendAPI.Tts: LOCK RESET.")
            CyberllamaBackendAPI.lockTtsRequests = 0
        else
            CyberllamaBackendAPI.lockTtsRequests = CyberllamaBackendAPI.lockTtsRequests + 1
            print("CyberllamaBackendAPI.Tts: LOCKED Can't do TTS.")
            return
        end
    end
    print("TTS!!!!!")
    CyberllamaBackendAPI.lockTts = true
    local args = additionalArgs or {}
    -- for key, value in pairs(additionalArgs) do
    --     args[key] = additionalArgs[value]
    -- end
    args.text = textContent
    args.npc_id = npcId
    args.voice = voiceUsed
    args.tts = ttsEngine

    local data = json.encode({
        prompt = '',
        prompt_args = args,
        stats = playerData,
        npc = npcData,
    })    
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointTts,
        data,
        function(response)
            CyberllamaBackendAPI.lockTts = false
            thenFn(response)
        end
    )
end



function CyberllamaBackendAPI.Revlookup(sessionKey, playerData, npcData, thenFn)
    if CyberllamaBackendAPI.lockRevlookup and CyberllamaBackendAPI.IsPossibleTimeout() == false then
        return
    end
    CyberllamaBackendAPI.lockRevlookup = true
    local data = json.encode({
        prompt = '',
        session = sessionKey,
        stats = playerData,
        npc = npcData
    })
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointRevlookup,
        data,
        function(response)
            CyberllamaBackendAPI.lockRevlookup = false
            thenFn(response)
        end
    )
end


function CyberllamaBackendAPI.NPCSync(playerData, npcData, thenFn)
    if CyberllamaBackendAPI.lockNPCSync and CyberllamaBackendAPI.IsPossibleTimeout() == false then
        return
    end
    CyberllamaBackendAPI.lockNPCSync = true
    local data = json.encode({
        prompt = '',        
        stats = playerData,
        npc = npcData
    })
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointNPCSync,
        data,
        function(response)
            CyberllamaBackendAPI.lockNPCSync = false
            thenFn(response)
        end
    )
end

function CyberllamaBackendAPI.Savesession(key, thenFn)
    if CyberllamaBackendAPI.lockSavesession and CyberllamaBackendAPI.IsPossibleTimeout() == false then
        return
    end
    CyberllamaBackendAPI.lockReset = true
    local data = key
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointReset,
        data,
        function(response)
            CyberllamaBackendAPI.lockReset = false
            thenFn(response)
        end
    )
end

function CyberllamaBackendAPI.Reset(playerData, npcData, thenFn)
    if CyberllamaBackendAPI.lockReset and CyberllamaBackendAPI.IsPossibleTimeout() == false then
        return
    end
    CyberllamaBackendAPI.lockReset = true
    local data = json.encode({
        prompt = '',
        prompt_args = '',
        stats = playerData,
        npc = npcData
    })
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointReset,
        data,
        function(response)
            CyberllamaBackendAPI.lockReset = false
            thenFn(response)
        end
    )
end

function CyberllamaBackendAPI.Recstart(playerData, npcData, thenFn)
    if CyberllamaBackendAPI.lockRecstart and CyberllamaBackendAPI.IsPossibleTimeout() == false then
        return
    end
    CyberllamaBackendAPI.lockRecstart = true
    local data = json.encode({
        prompt = '',
        prompt_args = '',
        stats = playerData,
        npc = npcData
    })
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointRecstart,
        data,
        function(response)
            CyberllamaBackendAPI.lockRecstart = false
            thenFn(response)
        end
    )
end


function CyberllamaBackendAPI.Recstop(playerData, npcData, thenFn)
    if CyberllamaBackendAPI.lockRecstop and CyberllamaBackendAPI.IsPossibleTimeout() == false then
        return
    end
    CyberllamaBackendAPI.lockRecstop = true
    local data = json.encode({
        prompt = '',
        prompt_args = '',
        stats = playerData,
        npc = npcData
    })
    print("Backend.Recstop - POST")
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointRecstop,
        data,
        function(response)
            print("Backend.Recstop - DONE")
            CyberllamaBackendAPI.lockRecstop = false
            thenFn(response)
        end
    )
end

function CyberllamaBackendAPI.Comment(onWhat, what, playerData, npcData, thenFn)
    if CyberllamaBackendAPI.lockComment and CyberllamaBackendAPI.IsPossibleTimeout() == false then
        return
    end
    CyberllamaBackendAPI.lockComment = true
    print("commenting on " .. onWhat)
    local data = json.encode({
        prompt = onWhat,
        prompt_args = what,
        stats = playerData,
        npc = npcData
    })
    CyberllamaBackendAPI.PostRequest(
        CyberllamaBackendAPI.endpointComment,
        data,
        function(response)
            CyberllamaBackendAPI.lockComment = false
            thenFn(response)
        end
    )
end

return CyberllamaBackendAPI