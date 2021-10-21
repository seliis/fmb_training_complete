do
    local function makeAir(unitId, unitName)
        local combatType = {
            [1] = {
                desc = "BFM",
                flag = 536870912,
                dist = mist.utils.NMToMeters(20),
                temp = {
                    [1] = {
                        desc = "MiG-23",
                        name = "AI_RED_AIR_M23_BFM"
                    }
                }
            },
            [2] = {
                desc = "ACM",
                --[[ flag = 4194304, This Flag is SRAAM ]]
                flag = 33554432, -- IRAAM
                dist = mist.utils.NMToMeters(40),
                temp = {
                    [1] = {
                        desc = "MiG-23",
                        name = "AI_RED_AIR_M23_ACM"
                    }
                }
            },
            [3] = {
                desc = "BVR",
                flag = nil,
                dist = mist.utils.NMToMeters(80),
                temp = {
                    [1] = {
                        desc = "MiG-23",
                        name = "AI_RED_AIR_M23_BVR"
                    }
                }
            }
        }

        local dirType = {
            [1] = {
                desc = "Front",
                head = mist.utils.toRadian(0)
            },
            [2] = {
                desc = "Left",
                head = mist.utils.toRadian(270)
            },
            [3] = {
                desc = "Right",
                head = mist.utils.toRadian(90)
            },
            [4] = {
                desc = "Behind",
                head = mist.utils.toRadian(180)
            }
        }

        local mainStrt = missionCommands.addSubMenuForGroup(
            unitId, "Air to Air", nil
        )

        missionCommands.addCommandForGroup(
            unitId, "Sanitize", mainStrt, MISSION.AIR["SANITIZE"]
        )

        for _, combatData in ipairs(combatType) do
            local combatStrt = missionCommands.addSubMenuForGroup(
                unitId, combatData.desc, mainStrt
            )
            for _, aircraftData in ipairs(combatData.temp) do
                local aircraftStrt = missionCommands.addSubMenuForGroup(
                    unitId, aircraftData.desc, combatStrt
                )
                for _, dirData in ipairs(dirType) do
                    local dirStrt = missionCommands.addSubMenuForGroup(
                        unitId, dirData.desc, aircraftStrt
                    )
                    for i = 1, 4 do
                        missionCommands.addCommandForGroup(
                            unitId, i .. "-Ship", dirStrt, MISSION.AIR["MAIN"], unitName,
                            {
                                spawnAmount   = i,
                                weaponFlag    = combatData.flag,
                                tempType      = combatData.desc,
                                tempDesc      = aircraftData.desc,
                                tempName      = aircraftData.name,
                                spawnHeading  = dirData.head,
                                spawnDistance = combatData.dist
                            }
                        )
                    end
                end
            end 
        end
    end

    local function makeRefuel(unitId, unitName)
        missionCommands.addCommandForGroup(
            unitId, "Refueller", nil, MISSION.REFUEL["MAIN"], unitName
        )
    end

    for unitId, unitData in pairs(mist.DBs.humansById) do
        makeAir(unitId, unitData.unitName)
        makeRefuel(unitId, unitData.unitName)
    end
end