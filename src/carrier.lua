do
    local arrGrp = {}; for grpName, _ in pairs(mist.DBs.MEgroupsByName) do
        if string.find(grpName, "AI_BLU_CV") ~= nil then
            local grpObj = Group.getByName(grpName)
            local grpPos = grpObj:getUnit(1):getPoint()
            arrGrp[#arrGrp+1] = {
                [1] = grpObj,
                [2] = grpPos,
                [3] = transPos(
                    grpPos,
                    50000,
                    mist.utils.toRadian(0),
                    0
                ),
                [4] = false
            }
        end
    end

    timer.scheduleFunction(
        function(...)
            for _, arr in ipairs(arrGrp) do
                local point = nil
                if arr[4] == true then
                    point = arr[2]
                    arr[4] = false
                else
                    point = arr[3]
                    arr[4] = true
                end
                mist.groupToPoint(
                    arr[1], point, nil, nil, 50, false
                )
            end
            return arg[2] + 3600
        end, nil, timer.getTime() + 1
    )
end