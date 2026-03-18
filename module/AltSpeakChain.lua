AltSpeakChain = {}
AltSpeakChain.__index = AltSpeakChain

-- Constructor for AltSpeakChain
function AltSpeakChain:new(cron, subtitles, fn1, fn2)
    local instance = setmetatable({}, AltSpeakChain)
    instance.One = fn1
    instance.Other = fn2
    instance.conversation = {}
    instance.successful = false
    instance.cron = cron
    instance.subtitles = subtitles
    return instance
end

-- Method to add a piece of conversation from "one"
function AltSpeakChain:AddOne(text)
    table.insert(self.conversation, {
        who = "one",
        txt = text,
        secs = self.subtitles.CalcTimeOfString(text),
    })
    return self
end

-- Method to add a piece of conversation from "other"
function AltSpeakChain:AddOther(text)
    table.insert(self.conversation, {
        who = "other",
        txt = text,
        secs = self.subtitles.CalcTimeOfString(text),
    })
    return self
end

-- Method to add a pause
function AltSpeakChain:AddPause(seconds)
    table.insert(self.conversation, {
        who = "pause",
        secs = seconds,
    })
    return self
end

-- Method to run a specific conversation at a given index
function AltSpeakChain:RunAt(idx)
    local j = self.conversation[idx]
    if j.who == 'one' then
        self.One(j.txt)
    elseif j.who == 'other' then
        self.Other(j.txt)
    end
end

-- Method to run the full conversation
function AltSpeakChain:Run()
    local lastWaitTime = 0
    local fConvLen = #self.conversation
    self.successful = false

    for i = 1, fConvLen do
        local sub = self.conversation[i]
        local waitTime = 0

        if sub.who == 'pause' then
            waitTime = sub.secs
        else
            waitTime = self.subtitles.CalcTimeOfString(sub.txt)
        end

        if i == 1 then
            waitTime = 0
        end

        lastWaitTime = lastWaitTime + waitTime
        self.cron.After(lastWaitTime, function()
            self:RunAt(i)
        end)
    end
    
    self.successful = true
    return self
end

-- Method to chain another AltSpeakChain
function AltSpeakChain:Then()
    return AltSpeakChain:new(self.cron, self.subtitles, self.One, self.Other)
end

return AltSpeakChain
