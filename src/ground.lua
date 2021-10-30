do
    local function makeTarget(point)
        local tempData = mist.utils.deepCopy(
            mist.getGroupData("AI_RED_GND_TARGET")
        )
        local unitData = tempData.units[1]
        unitData.x = point.x
        unitData.y = point.z
        unitData.heading = mist.utils.toRadian(180)
        tempData.clone = true
        local grpData = mist.dynAdd(tempData)
        local grpObj = Group.getByName(grpData.name)
        local grpCtrl = grpObj:getController()
        grpCtrl:setCommand(
            {
                id = "SetInvisible",
                params = {
                    value = true
                }
            }
        )
        grpCtrl:setCommand(
            {
                id = "SetImmortal",
                params = {
                    value = true
                }
            }
        )
        grpCtrl:setOnOff(true)
        local grpPos = grpObj:getUnit(1):getPoint()
        timer.scheduleFunction(
            function(...)
                trigger.action.smoke(grpPos, 1)
                return arg[2] + 300
            end, nil, timer.getTime() + 1
        )
    end

    local zoneData = trigger.misc.getZone("WYPT02")
    makeTarget(zoneData.point)
end