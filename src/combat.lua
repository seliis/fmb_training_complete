do MISSION.AIR = {}; local MASTER = MISSION.AIR
    MASTER.DB = {}

    local function getSpawnPos(unitPos, spawnDistance, unitHeading, spawnHeading)
        return transPos(
            unitPos,
            spawnDistance,
            unitHeading + spawnHeading,
            4572
        )
    end

    local function getAdversary(spawnPos, tempName, spawnAmount, unitHeading, unitPos)
        local tempGroup = mist.utils.deepCopy(
            mist.getGroupData(tempName)
        )
        for advsNum = 1, spawnAmount do
            local advsData = mist.utils.deepCopy(
                tempGroup.units[1]
            )
            local advsPos = transPos(
                spawnPos,
                advsNum * 100,
                unitHeading - mist.utils.toRadian(45),
                spawnPos.y
            )
            advsData.x = advsPos.x
            advsData.y = advsPos.z
            advsData.alt = 4572
            advsData.speed = 200
            advsData.payload.flare = 999
            advsData.payload.chaff = 999
            advsData.onboard_num = string.format("%03d", advsNum)
            tempGroup.units[advsNum] = advsData
        end
        tempGroup.clone = true
        tempGroup.route = {
            points = {
                [1] = mist.fixedWing.buildWP(
                    spawnPos, nil, 999, spawnPos.y, "Baro"
                ),
                [2] = mist.fixedWing.buildWP(
                    unitPos, nil, 999, unitPos.y, "Baro"
                )
            }
        }
        local grpData = mist.dynAdd(tempGroup)
        return Group.getByName(grpData.name)
    end

    local function getFriend(unitPos)
        local arr = {}
        world.searchObjects(
            Object.Category.UNIT,
            {
                id = world.VolumeType.SPHERE,
                params = {
                    point = unitPos,
                    radius = 18520
                }
            },
            function(found)
                if found:getCoalition() == 2 and found:inAir() then
                    arr[#arr+1] = found
                end
            end
        )
        return arr
    end

    local function setIntercept(unitsAdvs, unitsFrnd, weaponFlag)
        timer.scheduleFunction(
            function(...)
                for _, advs in ipairs(unitsAdvs) do
                    local cntr = advs:getController()
                    for _, frnd in ipairs(unitsFrnd) do
                        cntr:pushTask({
                            id = "AttackGroup",
                            params = {
                                groupId = frnd:getGroup():getID(),
                                weaponType = weaponFlag
                            }
                        })
                        cntr:setOption(0, 2)     -- ROE: Open Fire
                        cntr:setOption(1, 3)     -- ROT: Bypass and Escape
                        cntr:setOption(3, 1)     -- Radar: Attack Only
                        cntr:setOption(4, 3)     -- Flare: Using Near Enemy
                        cntr:setOption(5, 1)     -- Formation: Line Abreast
                        cntr:setOption(6, false) -- Do Not RTB in Bingo
                        cntr:setOption(13, 0)    -- Do Not Using ECM
                        cntr:setOption(15, true) -- Do Not Jettison
                        cntr:setOption(16, true) -- Do Not Using AB
                        cntr:setOption(18, 3)    -- Weapon Fire in Estimate
                    end
                end
            end, nil, timer.getTime() +  1
        )
    end

    local function setMonitoring(arrIndex, arrFrnd, arrAdvs)
        timer.scheduleFunction(
            function(...)
                for _, advs in ipairs(arrAdvs) do
                    if advs:isExist() == true and advs:inAir() == true then
                        return arg[2] + 10
                    end
                end
                for _, frnd in ipairs(arrFrnd) do
                    local id = frnd:getID()
                    printMsg(id, "Airspace has been Sanitized", "bell")
                end
                MASTER.DB[arrIndex] = nil
            end, nil, timer.getTime() + 1
        )
    end

    local function checkUnit(unitId, unitName)
        local unit = Unit.getByName(unitName)

        if unit:inAir() ~= true then
            printMsg(unitId, "You're Not in the Air", "dead")
            return false
        end

        for _, data in ipairs(MASTER.DB) do
            for _, elem in ipairs(data.arrFrnd) do
                if elem == unit then
                    printMsg(unitId, "You're Have One", "dead")
                    return false
                end
            end
        end

        return true
    end

    MASTER["MAIN"] = function(unitId, unitName, tempData)
        if checkUnit(unitId, unitName) ~= true then
            return nil
        end

        local unitData = getUnitData(unitName)
        local unitHdg = mist.getHeading(unitData.unitObject)
        local unitPos = unitData.unitObject:getPoint()
        local spawnPos = getSpawnPos(
            unitPos,
            tempData.spawnDistance,
            unitHdg,
            tempData.spawnHeading
        )
        local grpAdvs = getAdversary(
            spawnPos, tempData.tempName, tempData.spawnAmount, unitHdg, unitPos
        )
        local arrFrnd = getFriend(unitPos)
        local arrAdvs = grpAdvs:getUnits()
        setIntercept(arrAdvs, arrFrnd, tempData.weaponFlag)
        local arrIndex = #MASTER.DB + 1
        MASTER.DB[arrIndex] = {
            arrFrnd = arrFrnd,
            grpAdvs = grpAdvs
        }
        setMonitoring(arrIndex, arrFrnd, arrAdvs)
        trigger.action.outText(
            string.format("%s: %s-Ship %s Spawned", tempData.tempType, tempData.spawnAmount, tempData.tempDesc), 10, false
        )
        trigger.action.outSound("beep.ogg")
    end

    MASTER["SANITIZE"] = function(unitId, unitName)
        local function isAdvs()
            for _, elem in ipairs(MASTER.DB) do
                if elem ~= nil then
                    return true
                end
            end
            return false
        end

        local function checkArr(arr, unit)
            for _, elem in ipairs(arr) do
                if elem == unit then
                    return true
                end
            end
            printMsg(unitId, "Nothing Yours", "dead")
            return false
        end

        if isAdvs() == false then
            trigger.action.outTextForGroup(unitId, "No Adversaries", 5, false)
            trigger.action.outSoundForGroup(unitId, "dead.ogg")
            return nil
        end

        local unit = Unit.getByName(unitName)
        
        for i, arr in ipairs(MASTER.DB) do
            if checkArr(arr.arrFrnd, unit) == true then
                if arr.grpAdvs ~= nil and arr.grpAdvs:isExist() == true then
                    arr.grpAdvs:destroy()
                end
                MASTER.DB[i] = nil
                trigger.action.outTextForGroup(unitId, "Sanitized", 5, false)
                trigger.action.outSoundForGroup(unitId, "beep.ogg")
                break
            end
        end
    end
end