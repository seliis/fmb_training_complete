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

    MASTER["MAIN"] = function(unitName, tempData)
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
        setIntercept(grpAdvs:getUnits(), arrFrnd, tempData.weaponFlag)
        MASTER.DB[#MASTER.DB+1] = grpAdvs
        trigger.action.outText(
            string.format("%s: %s-Ship %s Spawned", tempData.tempType, tempData.spawnAmount, tempData.tempDesc), 10, false
        )
        trigger.action.outSound("beep.ogg")
    end

    MASTER["SANITIZE"] = function()
        for i, grpAdvs in ipairs(MASTER.DB) do
            if grpAdvs ~= nil and grpAdvs:isExist() == true then
                grpAdvs:destroy()
            end
            MASTER.DB[i] = nil
        end
        trigger.action.outText("Sanitized", 10, false)
        trigger.action.outSound("beep.ogg")
    end
end