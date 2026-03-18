local Listener = require('module/Listener')
local Locations = {
    data = {},
    custom = {},
    -- for you peeps out there
    locationChangedObservers = nil,
    locationTimeObservers = nil,
    initialized = false,
    lastLocation = '',
    lastLocationTime = 0,
    LastLocationTimeInMinutes = 0,
    LocationMakeAComment = true,
    LastLocationCommentTimes = 0,
    MakeCommentCronInSeconds = 120,
    UpdateLocationChangedInSeconds = 60,
    MakeCommentCooldownTimes = 1,
    LastLocationMaxCommentTimes = 30,
    lastLocationThresholdDistance = 20,
}

function Locations.Init()
    if Locations.initialized then
        return
    end
    Locations.initialized = true
    table.insert(Locations.data, {
        name = "Apartment",
        pos = Vector4.new(
        -1391.8707275391,
        1271.6887207031,
        123.08239746094,
        0)
    })
    table.insert(Locations.data, {
        name = "Clouds",
        pos = Vector4.new(
        -625.404235839844,
        794.564392089844,
        132.252227783203,
        0)
    })
    table.insert(Locations.data, {
        name = "Lizzie's Bar",
        pos = Vector4.new(
        -1188.91625976563,
        1566.19299316406,
        22.9151153564453,
        0)
    })
    table.insert(Locations.data, {
        name = "The After life",
        pos = Vector4.new(
        -1453.0498046875,
        1016.65893554687,
        16.4999923706055,
        0)
    })
    table.insert(Locations.data, {
        name = "Totentanz Club",
        pos = Vector4.new(
        -1715.64599609375,
        2224.13891601563,
        86.1999969482422,
        0)
    })
    table.insert(Locations.data, {
        name = "Riot Club",
        pos = Vector4.new(
        -1638.72961425781,
        1035.25854492188,
        26.6514053344727,
        0)
    })
    table.insert(Locations.data, {
        name = "Junkyard",
        pos = Vector4.new(
        1374.85852050781,
        -1674.91772460938,
        49.2958679199219,
        0),
    })
    table.insert(Locations.data, {
        name = "Empathy Club",
        pos = Vector4.new(
        -1632.23010253906,
        384.749877929688,
        7.69498443603516,
        0),
    })
    table.insert(Locations.data, {
        name = "JigJig Street",
        pos = Vector4.new(
        -652.916015625,
        842.565612792969,
        19.2743988037109,
        0),
    })
    table.insert(Locations.data, {
        name = "Drive-In Theater",
        pos = Vector4.new(
        -81.2294616699219,
        1963.30944824219,
        100.682434082031,
        0)
    })
    table.insert(Locations.data, {
        name = "Night City Dam Site (over Night City)",
        pos = Vector4.new(
        -664.632141113281,
        -1201.55615234375,
        272.189727783203,
        0)
    })
    Locations.locationChangedObservers = Listener:new()
    Locations.locationTimeObservers = Listener:new()
end

function Locations.Dispose()
    Locations.ResetLastLocation()
    if Locations.locationChangedObservers then
        Locations.locationChangedObservers:Dispose()
    end
    if Locations.locationTimeObservers then
        Locations.locationTimeObservers:Dispose()
    end
end


function Locations.ResetLastLocation()
    Locations.lastLocation = ''
    Locations.lastLocationTime = 0
    Locations.LastLocationTimeInMinutes = 0
    Locations.LocationMakeAComment = true
    Locations.LastLocationCommentTimes = 0
    Locations.MakeCommentCooldownTimes = 1
end


function Locations.UpdateLocationChanged()
  Locations.LocationMakeAComment = false
  for i = 1, #(Locations.data) do
    if Locations.NearLocation(Locations.data[i].pos) then
      local isSameLocation = Locations.data[i].name == Locations.lastLocation     
      if isSameLocation then
        print('is same location')
        
        local gt = GetGameTime()
        Locations.LastLocationTimeInMinutes = DiffGameTimeInSeconds(gt, Locations.lastLocationTime) / 60
        Locations.locationTimeObservers:Notify(Locations.LastLocationTimeInMinutes)
        
        return
      else
        Locations.ResetLastLocation()
        print('known location changed')
        print(Locations.lastLocation)
        Locations.lastLocation = Locations.data[i].name
        Locations.lastLocationTime = GetGameTime()
        Locations.locationChangedObservers:Notify({
            location = Locations.lastLocation,
            time = Locations.lastLocationTime
        })
      end
      -- MakeCommentCooldown = MakeCommentCooldown + 60
      return
    end
  end
end


function Locations.NearLocation(targetPuppet, locationPos)
    if not locationPos then
        return false
    end
    -- local player = Game.GetPlayer()
    if not targetPuppet then
        return false
    end
    local targetPos = targetPuppet:GetWorldPosition()
    local dist = Vector4.Distance2D(locationPos, targetPos)
    return dist <= Locations.lastLocationThresholdDistance
end


return Locations
