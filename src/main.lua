MISSION = {}

function printData(data, indent)
    if indent == nil then
        indent = ""
    end
    for k, v in pairs(data) do
        if type(v) == "table" then
            printData(v, indent .. "\t")
        else
            env.info("[" .. k .. "] " .. type(v) .. ": " .. v)
        end
    end
end

function getUnitData(unitName)
    local unitObject = Unit.getByName(unitName)
    local unitDesc = unitObject:getDesc()
    return {
        id          = unitObject:getID(),
        unitName    = unitName,
        unitObject  = unitObject,
        tankerType  = unitDesc.tankerType,
        typeName    = unitDesc.typeName,
        displayName = unitDesc.displayName
    }
end

function transPos(pos, rng, rad, alt)
    if alt then
        return {
            x = (rng * math.cos(rad)) + pos.x,
            z = (rng * math.sin(rad)) + pos.z,
            y = alt
        }
    else
        return {
            x = (rng * math.cos(rad)) + pos.x,
            z = (rng * math.sin(rad)) + pos.z,
            y = pos.y
        }
    end
end

function getSpeed(Object)
    local v = Object:getVelocity()
    return (
        ((v.x^2) + (v.y^2) + (v.z^2)) ^ 0.5
    )
end

function getTacan(Ch, Mode)
    local a = 1151
    local b = 64
    if Ch < 64 then
        b = 1
    end
    if Mode == "Y" then
        a = 1025
        if Ch < 64 then
            a = 1088
        end
    else
        if Ch < 64 then
            a = 962
        end
    end
    return (a + Ch - b) * 1000000
end

function outMsg(id, str, snd)
    trigger.action.outTextForGroup(
        id, str, 5, true
    )
    if snd ~= nil then
        trigger.action.outSoundForGroup(
            id, snd .. ".ogg"
        )
    end
end