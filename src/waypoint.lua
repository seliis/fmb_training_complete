do local make = true -- if false, ignore below scirpts
    if make and lfs and io then local blue = env.mission.coalition.blue
        local function getWaypoints()
            local arr = {}
            for _, zone in ipairs(mist.DBs.zonesByNum) do
                if string.find(zone.name, "WYPT") ~= nil then
                    local num = string.sub(zone.name, 5, 6)
                    arr[tonumber(num)] = zone.point
                end    
            end
            return arr
        end

        local function insertData()
            local waypoints = getWaypoints()
            local function makeWaypoint(points)
                for index, waypoint in ipairs(waypoints) do
                    points[index+1] = mist.fixedWing.buildWP(
                        waypoint, "Turning Point", 0, 0, "Baro"
                    )
                end
            end
            for _, countries in ipairs(blue.country) do
                for _, group in ipairs(countries.plane.group) do
                    if group.units[1].skill == "Client" then
                        makeWaypoint(group.route.points)
                    end
                end
            end
        end

        local function exportData()
            local path = lfs.writedir() .. "/Missions/missionWaypoint.lua"
            local file = io.open(path, "w")
            file:write(mist.utils.serialize("missionWaypoint", blue.country))
            file:close()
        end
        
        insertData()
        exportData()
    end
end