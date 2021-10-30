do -- REJECTED
    local function makeCircle(point, radius, angle)
        for deg = 0, 359, angle do
            local trans = transPos(
                point, radius, mist.utils.toRadian(deg)
            )
            coalition.addStaticObject(
                country.id.CJTF_RED,
                {
                    ["category"] = "Fortifications",
                    ["shape_name"] = "H-tyre_B",
                    ["type"] = "Black_Tyre",
                    ["dead"] = true,
                    ["x"] = trans.x,
                    ["y"] = trans.z,
                    ["heading"] = 0,
                    ["name"] = "BLACK_TYRE"
                }
            )
        end
    end

    local function makeTarget(point)
        local tempData = mist.utils.deepCopy(
            mist.getGroupData("AI_RED_GND_TRUCK")
        )
        local unitData = tempData.units[1]
        unitData.x = point.x
        unitData.y = point.z
        unitData.heading = mist.utils.toRadian(
            math.random(0, 359)
        )
        tempData.clone = true
        env.info(mist.utils.tableShow(unitData))
        local grpData = mist.dynAdd(tempData)
        return Group.getByName(grpData.name)
    end

    local function setOption(grp)
        local control = grp:getController()
        control:setCommand(
            {
                id = "SetInvisible",
                params = {
                    value = true
                }
            }
        )
        control:setCommand(
            {
                id = "SetImmortal",
                params = {
                    value = true
                }
            }
        )
        control:setOnOff(false)
    end

    local function popSmoke(grp)
        timer.scheduleFunction(
            function(...)
                local unit = grp:getUnit(1)
                trigger.action.smoke(unit:getPoint(), 1)
                return arg[2] + 300
            end, nil, timer.getTime() + 1
        )
    end

    for zoneName, zoneData in pairs(mist.DBs.zonesByName) do
        if string.find(zoneName, "CIRCLE") ~= nil then
            local point = zoneData.point
            local grp = makeTarget(point)
            makeCircle(point, 75.00, 2)
            makeCircle(point, 37.50, 4)
            makeCircle(point, 18.75, 8)
            setOption(grp)
            popSmoke(grp)
        end
    end
end