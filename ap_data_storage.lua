-- AP data storage releated
function AP:getTypeFromDataStorageKey(k)
    -- print("AP:getTypeFromDataStorageKey")
    local type = "invalid"
    local splitResult = split(k, "_")
    if #splitResult >= 4 then
        if splitResult[1] == "tobir" and tonumber(splitResult[2]) == self.CONNECTION_INFO.team and
            tonumber(splitResult[3]) == self.CONNECTION_INFO.slot then
            type = splitResult[4]
        end
    end
    return type
end
-- notes
function AP:setPersistentNoteInfo(note_type, player_type, isHardMode)
    print("AP:setPersistentNoteInfo", note_type, player_type, isHardMode)
    local goal = tonumber(self.SLOT_DATA.goal)
    if goal ~= 16 and goal ~= 17 then
        return
    end
    local noteMarkRequireHardMode = self.SLOT_DATA.noteMarkRequireHardMode
    -- print("AP:setPersistentNoteInfo", 2, noteMarkRequireHardMode)
    if noteMarkRequireHardMode == 1 and not isHardMode then
        return
    end
    local char = -1
    for k, v in pairs(self.NOTE_CHARS) do
        -- print("AP:setPersistentNoteInfo", 3, player_type, dump_table(v))
        if tbl_contains(v, player_type) then
            char = k
            break
        end
    end
    if char == -1 then
        return
    end
    local key = self:getNoteInfoKey(note_type, char)
    self.AP_CLIENT:Set(key, 0, true, {{"replace", 1}})
end
function AP:setupPersistentNoteInfo()
    --print("AP:setupPersistentNoteInfo")
    local keys = {}
    for k, v in pairs(self.NOTE_TYPES) do
        for k2, v2 in pairs(self.NOTE_CHARS) do
            table.insert(keys, self:getNoteInfoKey(v, k2))
        end
    end
    self.AP_CLIENT:Get(keys)
    self.AP_CLIENT:SetNotify(keys)
end
function AP:getNoteInfoKey(note_type, char)
    -- print("AP:getNoteInfoKey", note_type, char)
    local team = tonumber(self.CONNECTION_INFO.team)
    local slot = tonumber(self.CONNECTION_INFO.slot)
    return "tobir_" .. team .. "_" .. slot .. "_note_" .. note_type .. "_" .. char
end

-- floors
function AP:getPersistentInfoFurthestFloor()
    -- print("AP:getPersistentInfoFurthestFloor")
    local team = tonumber(self.CONNECTION_INFO.team)
    local slot = tonumber(self.CONNECTION_INFO.slot)
    local key = "tobir_" .. team .. "_" .. slot .. "_floor"
    self.AP_CLIENT:Get({key})
end
function AP:setPersistentInfoFurthestFloor(op)
    if not op then
        op = "max"
    end
    local team = tonumber(self.CONNECTION_INFO.team)
    local slot = tonumber(self.CONNECTION_INFO.slot)
    local key = "tobir_" .. team .. "_" .. slot .. "_floor"
    self.AP_CLIENT:Set(key, 1, true, {{op, self.FURTHEST_FLOOR}})
end