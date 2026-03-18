local FakeAsync = {
    data = {},
    cron = nil
}

function FakeAsync.Init(cron)
    FakeAsync.cron = cron
end

function FakeAsync.Create(fn)
    local n = tostring(math.random(99999))
    if FakeAsync.data[n] then
        n = n .. "_" .. tostring(math.random(999))
    end
    FakeAsync.data[n] = {
        Run = function()
            FakeAsync.cron.NextTick(function()
                fn(FakeAsync.data[n])
                if FakeAsync.data[n].afterFns then
                    for i = 1, #(FakeAsync.data[n].afterFns) do
                        FakeAsync.data[n].afterFns[i](FakeAsync.data[n])
                    end
                end
                FakeAsync.data[n] = nil
            end, {})
        end,
        done = false,
        afterFns = {},
        Dispose = function()            
            FakeAsync.data[n] = nil
        end,
        AndThen = function(afterFn)
            table.insert(FakeAsync.data[n].afterFns, afterFn)
            return FakeAsync.data[n]
        end
    }
    return FakeAsync.data[n]
end




return FakeAsync

