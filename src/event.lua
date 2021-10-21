do MISSION.EVT = {}; local MASTER = MISSION.EVT
    local function declareDead(unitObject)
        local time = timer.getTime()
        timer.scheduleFunction(
            function(...)
                if arg[1] < arg[2] then
                    return nil
                end
                trigger.action.signalFlare(
                    unitObject:getPoint(),
                    1,
                    mist.utils.toDegree(
                        mist.getHeading(unitObject)
                    )
                )
                return arg[2] + 0.1
            end, time + 1.6, time + 0.1
        )
        printMsg(unitObject:getID(), "You're Dead", "dead")
    end

    do MASTER.AAM = {}; local AAM = MASTER.AAM
        AAM["MAIN"] = function(eventData)
            local weaponObject = eventData.weapon
            local weaponDesc = weaponObject:getDesc()
            if weaponDesc.missileCategory == 1 or 2 then
                local weaponPos = nil
                timer.scheduleFunction(
                    function(...)
                        local ran, _ = pcall(
                            function()
                                weaponPos = weaponObject:getPoint()
                            end
                        )
                        if ran == true then
                            return arg[2] + 0.01
                        end
                        for _, mistData in pairs(mist.DBs.humansById) do
                            local unit = Unit.getByName(mistData.unitName)
                            if unit ~= nil and unit:inAir() == true and mist.utils.get3DDist(weaponPos, unit:getPoint()) < 100 then
                                declareDead(unit)
                                break
                            end
                        end
                    end, nil, timer.getTime() + 1
                )
            end
        end
    end

    do MASTER.HIT = {}; local HIT = MASTER.HIT
        HIT["MAIN"] = function(eventData)
            local targetObject = eventData.target
            local targetDesc = targetObject:getDesc()
            if targetObject:getCoalition() == 1 then
                local id = eventData.initiator:getID()
                if targetDesc.category == 2 then
                    printMsg(id, "Hit", "bell")
                end
            end
        end
    end

    function MASTER:onEvent(eventData)
        local id = eventData.id
        if id == 1 then
            MASTER.AAM["MAIN"](eventData)
        elseif id == 2 then
            MASTER.HIT["MAIN"](eventData)
        elseif id == 33 then -- Discard Chair After Ejection
            eventData.initiator:destroy()
            eventData.target:destroy()
        end
    end

    world.addEventHandler(MASTER)
end