local SubtitlesControl = {
    controller = nil,
    cron = nil,
}
local timeForEveryLetter = 0.1

function SubtitlesControl.Init(cron)
    ObserveAfter('SubtitlesGameController','OnInitialize', function(this)
        SubtitlesControl.controller = this
	end)
    ObserveAfter('SubtitlesGameController','OnUninitialize', function(this)
        SubtitlesControl.controller = nil
	end)
    SubtitlesControl.cron = cron
end

---@param letterCount number | nil
---@param letterTime number | nil
---@return number
function SubtitlesControl.CalcTimeByLetter(letterCount, letterTime)
    if letterTime then
        return letterCount * letterTime
    end
    return letterCount * timeForEveryLetter
end

---@param text string
---@param letterTime number | nil
---@return number
function SubtitlesControl.CalcTimeOfString(text, letterTime)
    if letterTime then
        return SubtitlesControl.CountLetters(text) * letterTime
    end
    return SubtitlesControl.CountLetters(text) * timeForEveryLetter
end

function SubtitlesControl.CountLetters(phrase)
    if not phrase then
        return 0
    end
    return string.gsub(phrase, "%s+", ""):len()
end

-- todo: add duration by sending the time duration of the tts to the client
function SubtitlesControl.SpawnDialogLine(text, characterName, characterPuppet, thenFn)
    if SubtitlesControl.controller ~= nil then
        local line = scnDialogLineData.new()
        local id = math.random(1,9999)
        -- line.type = 1
        line.id = CRUID(id)
        line.isPersistent = false
        line.speaker = characterPuppet
        line.speakerName = characterName
        line.text = text
        
        local duration = SubtitlesControl.CalcTimeByLetter(SubtitlesControl.CountLetters(text))
        line.duration = math.ceil(duration)
                                
        SubtitlesControl.controller:SpawnDialogLine(line)
    
        SubtitlesControl.cron.After(line.duration, function()
            
            SubtitlesControl.Cleanup()
            if thenFn then
                thenFn()
            end
        end, {})
    else
        print("SubtitlesControl.controller is nil")
    end
end

function SubtitlesControl.Cleanup()
    if SubtitlesControl.controller ~= nil then        
        SubtitlesControl.controller:Cleanup()
    else
        print("SubtitlesControl is nil")
    end
end

return SubtitlesControl