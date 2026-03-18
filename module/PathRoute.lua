local PathRoute = {
    routes = {},
    subjectRoutes = {},
    markedRemoval = {}
}

function PathRoute.Init(aiControl, targetHelper)
    PathRoute.aiControl = aiControl
    PathRoute.targetHelper = targetHelper
end

function PathRoute.CreateReplaceRoute(name, points)
    PathRoute.routes[name] = points
end

function PathRoute.AddPointsToRoute(name, point)
    if not PathRoute.routes[name] then
        PathRoute.routes[name] = {}
    end
    table.insert(PathRoute.routes[name], point)
end

function PathRoute.AddTargetToRoute(routeName, target, onLocationReached, loopList)
    table.insert(PathRoute.subjectRoutes, {
        entity = target,
        onLocationReachedFn = onLocationReached,
        routeName = routeName,
        currentIndex = 1, -- Start the index at 1 for better Lua compatibility
        engaged = false,
        reachedCurrentIndex = false,
        loopEnabled = loopList or false,
        reachedLastIndex = false
    })
end

function PathRoute.MarkTargetForRouteRemoval(routeNameToRemove, target)
    table.insert(PathRoute.markedRemoval, {
        routeName = routeNameToRemove,
        entity = target
    })
end

function PathRoute.RouteRemoval()
    if #PathRoute.markedRemoval ~= 0 then
        for i = 1, #PathRoute.markedRemoval do
            for j = 1, #PathRoute.subjectRoutes do
                if PathRoute.subjectRoutes[j].routeName == PathRoute.markedRemoval[i].routeName and
                    PathRoute.subjectRoutes[j].entity:GetRecordID() == PathRoute.markedRemoval[i].entity:GetRecordID() then
                    table.remove(PathRoute.subjectRoutes, j) -- Use table.remove to maintain array integrity
                    break
                end
            end
        end
        PathRoute.markedRemoval = {}
    end
end

function PathRoute.UpdateCheckLoop()
    PathRoute.RouteRemoval()

    for i = 1, #PathRoute.subjectRoutes do
        local subjectRoute = PathRoute.subjectRoutes[i]
        if subjectRoute and subjectRoute.entity then
            if not subjectRoute.onLocationReachedFn then
                print("do nothing here")
            else
                local routePoints = PathRoute.routes[subjectRoute.routeName]
                if not routePoints then
                    print("no route points")
                    return
                end

                if subjectRoute.currentIndex > #routePoints then
                    subjectRoute.currentIndex = 1 -- Reset to start if it exceeds
                end

                -- Check if reached current index
                subjectRoute.reachedCurrentIndex = PathRoute.targetHelper.InDistance(subjectRoute.entity, routePoints[subjectRoute.currentIndex], 10)

                if subjectRoute.reachedCurrentIndex then
                    print("reached position")
                    subjectRoute.reachedCurrentIndex = false
                    subjectRoute.engaged = false

                    -- Move to the next index
                    subjectRoute.currentIndex = subjectRoute.currentIndex + 1
                    if subjectRoute.currentIndex > #routePoints then
                        if subjectRoute.loopEnabled then
                            print("loopEnabled set, wrapping around")
                            subjectRoute.currentIndex = 1 -- Looping around
                        else
                            subjectRoute.currentIndex = #routePoints -- Don't go beyond the last index
                        end
                    end

                    if not subjectRoute.engaged then
                        print("engaged. moving")
                        subjectRoute.engaged = true
                        pcall(function()
                            subjectRoute.onLocationReachedFn(subjectRoute.entity, routePoints[subjectRoute.currentIndex])
                        end)
                    end
                end
            end
        end
    end
end
