-- AP message printing
function AP:showPermanentInfo()
    local state = self:getAPState()
    if state == nil then
        state = "! UNKNOWN STATE !"
    end
    local text = "AP: " .. state
    if state == AP.STATES[0] then
        Isaac.RenderScaledText(text, self.HUD_OFFSET, 260 - 10 * 5 * self.INFO_TEXT_SCALE - self.HUD_OFFSET,
            self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    elseif state == AP.STATES[4] then
        Isaac.RenderScaledText(text, self.HUD_OFFSET, 260 - 10 * 5 * self.INFO_TEXT_SCALE - self.HUD_OFFSET,
            self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 0, 255, 0, 1)
        if self.CONNECTION_INFO and self.SLOT_DATA then
            local goal = self.SLOT_DATA.goal
            local text2 = string.format("%s/%s checked (need %s); next check: %s/%s; goal: %s",
                #self.AP_CLIENT.checked_locations, self.SLOT_DATA.totalLocations, self.SLOT_DATA.requiredLocations,
                self.CUR_ITEM_STEP_VAL, self.SLOT_DATA.itemPickupStep, self:goalIdToName(goal))
            local player = Isaac.GetPlayer()
            local playerType = player:GetPlayerType()
            local playerName = player:GetName()
            if goal == 16 then
                local reqNoteAmount = tonumber(self.SLOT_DATA.fullNoteAmount)
                text2 = text2 .. " (" .. self.COMPLETED_NOTES .. "/" .. reqNoteAmount .. ";" .. playerName .. ":" ..
                            self:countNoteMarksForPlayerType(playerType) .. "/" .. tablelength(self.NOTE_TYPES) .. ")"
            elseif goal == 17 then
                local reqNoteMarks = tonumber(self.SLOT_DATA.noteMarksAmount)
                text2 = text2 .. " (" .. self.COMPLETED_NOTE_MARKS .. "/" .. reqNoteMarks .. ";" .. playerName .. ":" ..
                            self:countNoteMarksForPlayerType(playerType) .. "/" .. tablelength(self.NOTE_TYPES) .. ")"
            end
            Isaac.RenderScaledText(text2, self.HUD_OFFSET, 260 - 10 * 4 * self.INFO_TEXT_SCALE - self.HUD_OFFSET,
                self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 255, 255, 1)
        end
    else
        Isaac.RenderScaledText(text, self.HUD_OFFSET, 260 - 10 * 5 * self.INFO_TEXT_SCALE - self.HUD_OFFSET,
            self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 255, 0, 1)
    end
end
function AP:addMessage(msg)
    dbg_log("AP:addMessage")
    if not msg then
        return
    end
    if type(msg) == "string" then
        msg = {
            parts = {{
                msg = msg,
                color = {
                    A = 1,
                    R = 255,
                    G = 255,
                    B = 255
                },
                width = Isaac.GetTextWidth(msg)
            }}
        }
    end
    if type(msg) ~= "table" then
        return
    end
    msg.timer = 250
    table.insert(self.MESSAGE_QUEUE, msg)
end
function AP:proceedMessageQueue()
    for i = 1, 3 do
        if self.MESSAGE_QUEUE[1] and self.MESSAGE_QUEUE[1].timer <= 0 then
            table.remove(self.MESSAGE_QUEUE, 1)
        end
    end
end
function AP:showMessages(pos, color)
    if not pos then
        pos = Vector(self.HUD_OFFSET, 260 - self.HUD_OFFSET)
    end
    for i = 1, 3 do
        if self.MESSAGE_QUEUE[i] and self.MESSAGE_QUEUE[i].timer > 0 then
            local posX = pos.X
            for _, v in ipairs(self.MESSAGE_QUEUE[i].parts) do
                if not v.width then
                    v.width = Isaac.GetTextWidth(v.msg)
                end
                Isaac.RenderScaledText(v.msg, posX, pos.Y - 10 * (4 - i) * self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE,
                    self.INFO_TEXT_SCALE, v.color.R, v.color.G, v.color.B, v.color.A)
                posX = posX + v.width * self.INFO_TEXT_SCALE
            end
            self.MESSAGE_QUEUE[i].timer = self.MESSAGE_QUEUE[i].timer - 1
        end
    end
    self:proceedMessageQueue()
end
function AP:showDebugInfo()
    local lineHeight = 10 * self.INFO_TEXT_SCALE;
    Isaac.RenderScaledText("CURRENT_TYPING_STRING: " .. self.CURRENT_TYPING_STRING, 100, 0, self.INFO_TEXT_SCALE,
        self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    local unlocktext = "false"
    if self.UNLOCK_TYPING then
        unlocktext = "true"
    end
    Isaac.RenderScaledText("UNLOCK_TYPING: " .. unlocktext, 100, lineHeight, self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE,
        255, 0, 0, 1)
    local toggletext = "false"
    if self.TOGGLE_LOWERCASE then
        toggletext = "true"
    end
    Isaac.RenderScaledText("TOGGLE_LOWERCASE: " .. toggletext, 100, lineHeight * 2, self.INFO_TEXT_SCALE,
        self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    Isaac.RenderScaledText("WAIT_TYPING_ENTER_EXIT: " .. self.WAIT_TYPING_ENTER_EXIT, 100, lineHeight * 3,
        self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    Isaac.RenderScaledText("RECONNECT_TRIES: " .. self.RECONNECT_TRIES, 100, lineHeight * 4, self.INFO_TEXT_SCALE,
        self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    Isaac.RenderScaledText("#TRAP_QUEUE: " .. #self.TRAP_QUEUE, 100, lineHeight * 5, self.INFO_TEXT_SCALE,
        self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    Isaac.RenderScaledText("TRAP_QUEUE_TIMER: " .. self.TRAP_QUEUE_TIMER, 100, lineHeight * 6, self.INFO_TEXT_SCALE,
        self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    Isaac.RenderScaledText("PICKUP_TIMER: " .. self.PICKUP_TIMER, 100, lineHeight * 7, self.INFO_TEXT_SCALE,
        self.INFO_TEXT_SCALE, 255, 0, 0, 1)
end