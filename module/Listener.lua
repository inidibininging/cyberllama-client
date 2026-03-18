local Listeners = {
   
}
Listeners.__index = Listeners
function Listeners:new()
    local instance = {
        observers = {}
    }
    setmetatable(instance, Listeners)
    return instance
end

function Listeners:Add(observerFn)
    table.insert(self.observers, observerFn)
end
function Listeners:Dispose()
    self.observers = {}
end
function Listeners:Notify(arg)
    for i = 1, #self.observers do
        self.observers[i](arg)
    end
end
return Listeners