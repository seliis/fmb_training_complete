do MISSION.REFUEL = {}; local MASTER = MISSION.REFUEL
    MASTER.DB = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0
    }

    local function getTankerIndex()
        local r = nil
        for k, v in ipairs(MASTER.DB) do
            if v == 0 then
                r = k
                break
            end
        end
        return r
    end

    local function getTempName(tankerType, typeName)
        if tankerType == 0 then
            return "AI_BLU_AIR_K135"
        else
            if typeName ~= "Su-33" then
                return "AI_BLU_AIR_MPRS"
            else
                return "AI_BLU_AIR_IL78"
            end
        end
    end

    local function getTanker(tankerIndex, tempName, unitObject)
        local unitPos = unitObject:getPoint()
        local unitHdg = mist.getHeading(unitObject)
        local tempSpd = 200
        local tempAlt = 4572
        local tempPos = transPos(
            unitPos, 2778, unitHdg, tempAlt
        )
        local tempData = mist.utils.deepCopy(
            mist.getGroupData(tempName)
        )
        local tempUnit = tempData.units[1]
        tempUnit.x = tempPos.x
        tempUnit.y = tempPos.z
        tempUnit.alt = tempAlt
        tempUnit.speed = tempSpd
        tempUnit.payload.flare = 0
        tempUnit.payload.chaff = 0
        tempUnit.onboard_num = string.format("%03d", tankerIndex)
        tempData.clone = true
        tempData.route = {
            points = {
                [1] = mist.fixedWing.buildWP(
                    tempPos, nil, tempSpd, tempAlt, "Baro"
                ),
                [2] = mist.fixedWing.buildWP(
                    transPos(
                        tempPos, 2778, unitHdg, tempAlt
                    ), nil, tempSpd, tempAlt, "Baro"
                )
            }
        }
        local grpData = mist.dynAdd(tempData)
        return Group.getByName(grpData.name)
    end

    local function setMonitoring(tankerUnit, tankerIndex)
        timer.scheduleFunction(
            function(...)
                local fuel = math.floor(
                    tankerUnit:getFuel() * 100
                )
                local passed = false
                world.searchObjects(
                    Object.Category.UNIT,
                    {
                        id = world.VolumeType.SPHERE,
                        params = {
                            point = tankerUnit:getPoint(),
                            radius = 5556
                        }
                    },
                    function(found)
                        local foundName = found:getPlayerName()
                        if foundName ~= nil and passed ~= true and fuel > 10 then
                            passed = true
                        end
                        if foundName ~= nil and found:inAir() == true then
                            trigger.action.outTextForGroup(
                                found:getGroup():getID(),
                                "Refueller Fuel: " .. (fuel - 10) .. "%",
                                9, false
                            )
                        end
                    end
                )
                if passed == true then
                    return timer.getTime() + 10
                else
                    trigger.action.outText(
                        string.format("TX%02d Dismissed", tankerIndex), 5, false
                    )
                    trigger.action.outSound("beep.ogg")
                    MASTER.DB[tankerIndex]:destroy()
                    MASTER.DB[tankerIndex] = 0
                end
            end, nil, timer.getTime() + 1
        )
    end

    local function setMission(tankerGrp, tankerUnit, tankerIndex)
        local tankerCtr = tankerGrp:getController()
        local tankerPos = tankerUnit:getPoint()
        local anchorPos = transPos(
            tankerPos,
            2778,
            mist.getHeading(tankerUnit) - mist.utils.toRadian(45),
            tankerPos.y
        )
        tankerCtr:setCommand(
            {
                id = "SetInvisible",
                params = {
                    value = true
                }
            }
        )
        tankerCtr:setCommand(
            {
                id = "SetImmortal",
                params = {
                    value = true
                }
            }
        )
        tankerCtr:setCommand(
            {
                id = "SetFrequency",
                params = {
                    frequency = tonumber("315." .. tankerIndex) * 1000000,
                    modulation = 0
                }
            }
        )
        tankerCtr:setCommand(
            {
                id = "SetCallsign",
                params = {
                    callname = 1,
                    number = tankerIndex
                }
            }
        )
        local tcnName = tostring("TX" .. tankerIndex)
        local tcnFreq = tonumber("09" .. tankerIndex)
        tankerCtr:setCommand(
            {
                id = "ActivateBeacon",
                params = {
                    type = 4,
                    system = 4,
                    name = tcnName,
                    callsign = tcnName,
                    frequency = getTacan(tcnFreq, "Y")
                }
            }
        )
        tankerCtr:setOption(1, 0)     -- ROT: Ignore
        tankerCtr:setOption(6, false) -- Do Not RTB in Bingo
        tankerCtr:setOption(7, true)  -- Silence
        timer.scheduleFunction(
            function()
                tankerCtr:setTask(
                    {
                        id = "Orbit",
                        params = {
                            pattern = "Circle",
                            point = {anchorPos.x, anchorPos.z},
                            speed = getSpeed(tankerUnit),
                            altitude = tankerPos.y
                        }
                    }
                )
                tankerCtr:pushTask(
                    {
                        id = "Tanker",
                        params = {}
                    }
                )
            end, nil, timer.getTime() + 1
        )
    end

    local function checkState(unitId, tankerIndex, unitObject, tankerType)
        if tankerIndex == nil then
            outMsg(unitId, "No More Tanker", "dead")
            return false
        end

        if tankerType == nil then
            outMsg(unitId, "This Aircraft Can't Be", "dead")
            return false
        end

        if unitObject:inAir() ~= true then
            outMsg(unitId, "You're Not in the Air", "dead")
            return false
        end

        return true
    end

    MASTER["MAIN"] = function(unitName)
        local unitData = getUnitData(unitName)
        local tankerIndex = getTankerIndex()
        if checkState(unitData.id, tankerIndex, unitData.unitObject, unitData.tankerType) == true then
            local tempName = getTempName(
                unitData.tankerType, unitData.typeName
            )
            local tankerGrp = getTanker(
                tankerIndex, tempName, unitData.unitObject
            )
            local tankerUnit = tankerGrp:getUnit(1)
            MASTER.DB[tankerIndex] = tankerGrp
            setMonitoring(tankerUnit, tankerIndex)
            setMission(tankerGrp, tankerUnit, tankerIndex)
            trigger.action.outText(
                string.format("TX%02d: 9%sY A/A TCN, UHF 315.%s00 Mhz", tankerIndex, tankerIndex, tankerIndex), 5, true
            )
            trigger.action.outSound("beep.ogg")
        end
    end
end