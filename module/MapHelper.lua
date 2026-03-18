local MapHelper = {}

MapHelper.lastLocation = {}

-- mark on map
function MapHelper.MarkOnMap(x, y, z, variant, topic)
  local mappinData = MappinData.new()
  mappinData.mappinType = 'Mappins.DefaultStaticMappin'
  mappinData.variant = variant or gamedataMappinVariant.BountyHuntVariant
  mappinData.visibleThroughWalls = true
  local position = Vector4.new(x, y, z, 0)
  
  MapHelper.lastLocation[topic] = Game.GetMappinSystem():RegisterMappin(mappinData, position)  
  Game.GetMappinSystem():SetMappinActive(MapHelper.lastLocation[topic], true)
end

function MapHelper.UnmarkLastLocation(topic)
    print("UnmarkLastLocation:" .. topic)
    if not MapHelper.lastLocation or not MapHelper.lastLocation[topic] then
        print("No last location or not last location for topic")
        return
    end
    Game.GetMappinSystem():SetMappinActive(MapHelper.lastLocation[topic], false)
    pcall(function() Game.GetMappinSystem():UnregisterMappin(MapHelper.lastLocation[topic].mappinData) end)
    MapHelper.lastLocation[topic] = nil
end

return MapHelper