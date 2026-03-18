local FastTravelMarks = {
    data = {},
    custom = {},
}
FastTravelMarks.LocationGeneratorLoopInSeconds = 3600
function FastTravelMarks.Init(districts, backend, cyberNpc, cyberV, tryDecodeJson)
    FastTravelMarks.data = {}
    FastTravelMarks.backend = backend
    local districtsLen = #districts
    for didx = 1, districtsLen do
        local dName = districts[didx].Name
        local f = assert(io.open("./districts/" .. dName .. ".json"))
        local lines = ''
        lines = f:read("*a")
        local tableDis = {}
        tableDis = tryDecodeJson(lines, f, dName .. ".json")
        print('InitFastTravelMarks ' .. dName)
        table.insert(FastTravelMarks.data, { Name = dName, TravelPoints = tableDis })
        print(#(FastTravelMarks.data))
    end
    FastTravelMarks.cyberNpc = cyberNpc
    FastTravelMarks.cyberV = cyberV
    FastTravelMarks.InitCustom()
end

function FastTravelMarks.GetRandomLocations(count)
    if count < 1 then return {} end
    local data = {}
    for i=1, #count do
        local d = FastTravelMarks.GetRandomDistrict()
        local p = FastTravelMarks.GetRandomLocationOfDistrict(d)
        table.insert(data, {
            district = d,
            location = p
        })
    end
    return data
end

function FastTravelMarks.GetRandomDistrict()
    local randomDistrictIdx = math.random(#(FastTravelMarks.data))
    return FastTravelMarks.data[randomDistrictIdx]
end

local function replaceStreet(input)
    -- Replace 'St.' with 'street'
    local output = string.gsub(input, "St%.$", "Street")
    local output = string.gsub(input, "st%.$", "street")
    -- Replace 'St' with 'street'
    output = string.gsub(output, "St$", "Street")
    output = string.gsub(output, "st$", "street")
    return output
end

function FastTravelMarks.GetRandomLocationOfDistrict(district)    
    local randomLocationIdx = math.random(#(district.TravelPoints))
    local location = district.TravelPoints[randomLocationIdx]
    location.name = replaceStreet(location.name)
    return location
end

function FastTravelMarks.GetRandomLocationInRandomDistrict()
    local randomDistrict = FastTravelMarks.GetRandomDistrict()
    local randomLocationPoint = FastTravelMarks.GetRandomLocationOfDistrict(randomDistrict)
    return {
        district = randomDistrict,
        location = randomLocationPoint,
        asVector4 = Vector4:new(
            randomLocationPoint.x,
            randomLocationPoint.y,
            randomLocationPoint.z,
            1.0)
    }
end

function FastTravelMarks.GenerateCustom()
    local info = FastTravelMarks.cyberV.GetPlayerInfoForServer()
    FastTravelMarks.backend.MakeTitle(
      '',
      '',
      info,
      FastTravelMarks.cyberNpc.GetLastNPCTargetForServer(),
      function(response)
        local responseJson = FastTravelMarks.backend.GetJsonResponse(response) or {
          title = "Marked location"
        }        
  
        table.insert(FastTravelMarks.custom, {
          markerref = '#marked_location',
          name = responseJson.title,
          x = info.p_location.x,
          y = info.p_location.y,
          z = info.p_location.z,
          district_main = info.p_district.main,
          district_sub = info.p_district.sub or ''
        })        
        for i = 1, #FastTravelMarks.data do
            if FastTravelMarks.data[i].Name == info.p_district.main then
                HUD.QuestMessage("New Location: " .. responseJson.title .. " near " .. info.p_district.main)
                local inDistance = false
                for j = 1, #FastTravelMarks.data[i].TravelPoints do
                    if TargetHelper.InDistance(
                        FastTravelMarks.data[i].TravelPoints[j],
                        info.p_location,
                        150
                    ) then
                        inDistance = true
                    end
                end
                if not inDistance then
                    table.insert(FastTravelMarks.data[i].TravelPoints, {
                        markerref = '#marked_location',
                        name = responseJson.title,
                        x = info.p_location.x,
                        y = info.p_location.y,
                        z = info.p_location.z,
                        district_main = info.p_district.main,
                        district_sub = info.p_district.sub or ''
                    })
                end
            end
        end
    end)
end

function FastTravelMarks.DumpCustom()
    local output = json.encode(FastTravelMarks.custom)
    local fo = io.open("./custom-locations.json", "w+")
    if fo then
        fo:write(output)
        fo:close()
    end
end

function FastTravelMarks.InitCustom()
    local f = io.open("./custom-locations.json", "r")
    local lines = '[]'
    if not f then
        return
    end
    lines = f:read("*a")
    print(lines)
    f:close()
    local customLocations = json.decode(lines)
    FastTravelMarks.custom = {}
    for i = 1, #customLocations do
        table.insert(FastTravelMarks.custom, customLocations[i])
        for j = 1, #FastTravelMarks.data do
            if FastTravelMarks.data[j].Name == customLocations.district_main then
                table.insert(FastTravelMarks.data[j].TravelPoints, customLocations[i])
            end
        end
    end
end

return FastTravelMarks