function GetGameTime()
    local timeDay = Game.GetTimeSystem():GetGameTime():Days()
    local timeHours = Game.GetTimeSystem():GetGameTime():Hours()
    local timeMinutes = Game.GetTimeSystem():GetGameTime():Minutes()
    local timeSeconds = Game.GetTimeSystem():GetGameTime():Seconds()
    return {
        td = timeDay,
        th = timeHours,
        tm = timeMinutes,
        ts = timeSeconds
    }
end

function DiffGameTimeInSeconds(a, b)
    local currentTimeInSeconds = os.time()
    currentTimeInSeconds = currentTimeInSeconds +
        (a.td * 24 * 3600) +
        (a.th * 3600) +
        (a.tm * 60) +
        a.ts

    local lastTimeInSeconds = os.time()
    lastTimeInSeconds = lastTimeInSeconds +
        (b.td * 24 * 3600) +
        (b.th * 3600) +
        (b.tm * 60) +
        b.ts
    return os.difftime(currentTimeInSeconds, lastTimeInSeconds)
end

function SecondsToGameTime(seconds)
    -- not sure if right. spent few minutes on this
    local days = math.floor(seconds / (24 * 3600))
    local currentSeconds = math.fmod(seconds, 24 * 3600)
    local hours = math.floor(currentSeconds / 3600)
    local minutes = math.floor(math.fmod(currentSeconds, 3600) / 60)
    local secs = math.fmod(currentSeconds, 60)
    return {
        td = days,
        th = hours,
        tm = minutes,
        ts = secs
    }
end
