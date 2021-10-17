do
    if lfs and io then
        local function exportData()
            local path = lfs.writedir() .. "/Missions/missionWaypoint.lua"
            local file = io.open(path, "w")
            file:write(mist.utils.serialize("test", env.mission))
            file:close()
        end
        
        exportData()
    end
end