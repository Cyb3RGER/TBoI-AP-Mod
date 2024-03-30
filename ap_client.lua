

local lua_dir = 'lua533r-clang32-dynamic'
if IS_REPENTOGON then
    lua_dir = 'lua54-clang32-static'
end
local luaapclient_dir = script_path() .. 'lib' .. DIR_SEP .. lua_dir .. DIR_SEP .. 'lua-apclientpp.dll'
---@type APClient
local APClient = package.loadlib(luaapclient_dir, 'luaopen_apclientpp')()
local json = require('json')

-- AP client / Mod version
AP.VERSION = { 0, 3, 0 }
AP.GAME_NAME = "The Binding of Isaac Repentance"
AP.ITEM_HANDLING = 7 -- fully remote
AP.TAGS = { "Lua-APClientPP" }
AP.STATES = {
    [0] = "Disconnected",
    [1] = "Socket connecting",
    [2] = "Socket connected",
    [3] = "Room Info",
    [4] = "Slot Connected"
}

function AP:initAPClient()
    function self.on_socket_connected()
        dbg_log("Socket connected")
    end

    function self.on_socket_error(msg)
        dbg_log("Socket error: " .. msg)
    end

    function self.on_socket_disconnected()
        dbg_log("Socket disconnected")
        self.CONNECTION_INFO = nil
        self.ROOM_INFO = nil
        self.LAMB_KILL = false
        self.LAMB_BODY_KILL = false
        self.HAS_SEND_GOAL_MSG = false
    end

    function self.on_room_info()
        dbg_log("Room info")
        self.AP_CLIENT:ConnectSlot(self.SLOT_NAME, self.PASSWORD, AP.ITEM_HANDLING, AP.TAGS, AP.VERSION)
    end

    function self.on_slot_connected(slot_data)
        dbg_log("Slot connected")
        self.CONNECTION_INFO = {
            team = self.AP_CLIENT:get_team_number(),
            slot = self.AP_CLIENT:get_player_number()
        }
        self.SLOT_DATA = slot_data
        dbg_log("Connected 1" .. dump_table(self.CONNECTION_INFO))
        if self.SLOT_DATA.deathLink and self.SLOT_DATA.deathLink == 1 then
            local tags = { table.unpack(AP.TAGS), "DeathLink" }
            self.AP_CLIENT:ConnectUpdate(nil, tags)
        end
        self.HAS_SEND_GOAL_MSG = false
        self.LAMB_KILL = false
        self.LAMB_BODY_KILL = false
        self.SATAN_KILL = false
        self.ITEM_QUEUE = {}
        self.ITEM_QUEUE_COUNTER = 0
        self.ITEM_QUEUE_CURRENT_MAX = 0
        self.ITEM_QUEUE_MAX_PER_FLOOR = 0
        self.FURTHEST_FLOOR = 1
        self.LAST_FLOOR = 1
        self.JUST_STARTED = true
        self.JUST_STARTED_TIMER = 100
        self:setPersistentInfoFurthestFloor("default")
        if self.SLOT_DATA.splitStartItems and self.SLOT_DATA.splitStartItems == 2 then
            self:getPersistentInfoFurthestFloor()
        end
        self.TRAP_QUEUE = {}
        self.TRAP_QUEUE_TIMER = 150
        dbg_log("Connected 3 loadOtherData")
        local required_locations = tonumber(self.SLOT_DATA.requiredLocations)
        local goal = tonumber(self.SLOT_DATA.goal)
        if required_locations and goal and #self.AP_CLIENT.checked_locations >= required_locations then
            if not self.HAS_SEND_GOAL_MSG then
                self:addMessage({
                    parts = { {
                        msg = "You have collected enough items to beat the game. Goal: " .. self:goalIdToName(goal),
                        color = COLORS.GREEN
                    } }
                })
                self.HAS_SEND_GOAL_MSG = true
            end
            if goal == 15 then
                self:sendGoalReached()
            end
            if goal == 16 or goal == 17 then
                self:checkNoteInfo()
            end
        end
        if goal == 16 or goal == 17 then
            self:setupLocalNoteInfo()
            self:setupPersistentNoteInfo()
        end
        dbg_log("Connected 3.5 loadOtherData")
        if self.IS_CONTINUED then
            dbg_log("Connected 3.75 loadOtherData")
            if not self:loadOtherData(self.SLOT_DATA.seed) then
                self.AP_CLIENT = nil
                self:addMessage({
                    parts = { {
                        msg =
                        "You are continuing a run of a different slot/game. You have beeen disconnected from the AP server. Please start a new run.",
                        color = COLORS.RED
                    } }
                })
                return
            end
            dbg_log("Connected 4 loadOtherData")
        else
            self.LAST_RECEIVED_ITEM_INDEX = -1
            self.CUR_ITEM_STEP_VAL = 0
            self:saveOtherData("")
        end
        dbg_log("Connected end")
    end

    function self.on_slot_refused(reasons)
        dbg_log("Slot refused: " .. table.concat(reasons, ", "))
        local errsMsgs = ""
        if reasons then
            errsMsgs = " Reason(s): " .. table.concat(reasons, ", ")
            -- for i, v in ipairs(reasons) do
            --     errsMsgs = errsMsgs .. v
            --     if i ~= #reasons then
            --         errsMsgs = errsMsgs .. ", "
            --     end
            -- end
        end
        self:addMessage({
            parts = { {
                msg = "Connection refused by AP Server." .. errsMsgs,
                color = COLORS.RED
            } }
        })
        self.CONNECTION_INFO = nil
        self.ROOM_INFO = nil
        self.LAMB_KILL = false
        self.LAMB_BODY_KILL = false
        self.HAS_SEND_GOAL_MSG = false
        -- self.RECONNECT_TRIES = self.RECONNECT_TRIES + 1
        -- self:reconnect()
    end

    function self.on_items_received(items)
        dbg_log("Items received:")
        for _, item in ipairs(items) do
            dbg_log(tostring(item.item) .. " " .. self.LAST_RECEIVED_ITEM_INDEX)
            if item.index > self.LAST_RECEIVED_ITEM_INDEX then
                self:collectItem(item)
                self.LAST_RECEIVED_ITEM_INDEX = item.index
            else
                dbg_log("ignored item based on index")
            end
        end

        self.JUST_STARTED = false
        if self.SLOT_DATA.splitStartItems and self.SLOT_DATA.splitStartItems == 1 then
            self.ITEM_QUEUE_MAX_PER_FLOOR = math.ceil(#self.ITEM_QUEUE / 6)
            self.ITEM_QUEUE_CURRENT_MAX = self:getStageNum() * self.ITEM_QUEUE_MAX_PER_FLOOR
        end
    end

    function self.on_location_info(items)
        dbg_log("Locations scouted:")
        for _, item in ipairs(items) do
            dbg_log(item.item)
        end
    end

    function self.on_location_checked(locations)
        dbg_log("Locations checked:")
        for _, id in ipairs(locations) do
            dbg_log(id)
        end
        local required_locations = tonumber(self.SLOT_DATA.requiredLocations)
        local goal = tonumber(self.SLOT_DATA.goal)
        if required_locations and goal and #self.AP_CLIENT.checked_locations >= required_locations then
            if not self.HAS_SEND_GOAL_MSG then
                self:addMessage({
                    parts = { {
                        msg = "You have collected enough items to beat the game. Goal: " .. self:goalIdToName(goal),
                        color = COLORS.GREEN
                    } }
                })
                self.HAS_SEND_GOAL_MSG = true
            end
            if goal == 15 then
                self:sendGoalReached()
            end
            if goal == 16 or goal == 17 then
                self:checkNoteInfo()
            end
        end
    end

    function self.on_data_package_changed(data_package)
        -- dbg_log("Data package changed:")
        -- dbg_log(data_package)
    end

    function self.on_print(data)
        -- dbg_log(data)
        self:addMessage(data)
    end

    function self.on_print_json(data, extra)
        dbg_log("on_print_json")
        local msg = {
            parts = {}
        }
        -- ignore own chat messages
        if not extra.type or extra.type ~= "Chat" or not extra.slot or not self.CONNECTION_INFO or extra.slot ~=
            self.CONNECTION_INFO.slot then
            for _, v in ipairs(data) do
                dbg_log(dump_table(v))
                local text = v.text
                local color = COLORS.WHITE
                if not v.type or v.type == "text" then
                    -- nothing to do
                elseif v.type == "player_id" then
                    text = self:resolveIdToName(v.type, v.text)
                    color = COLORS.BLUE
                elseif v.type == "player_name" then
                    color = COLORS.BLUE
                elseif v.type == "item_id" then
                    text = self:resolveIdToName(v.type, v.text, v.player)
                    if v.flags & 4 == 4 then
                        color = COLORS.RED
                    elseif v.flags & 2 == 2 or v.flags & 1 == 1 then
                        color = COLORS.GREEN
                    else
                        color = COLORS.YELLOW
                    end
                elseif v.type == "item_name" then
                    if v.flags | 4 == 4 then
                        color = COLORS.RED
                    elseif v.flags | 2 == 2 or v.flags | 1 == 1 then
                        color = COLORS.YELLOW
                    else
                        color = COLORS.GREEN
                    end
                elseif v.type == "location_id" then
                    text = self:resolveIdToName(v.type, v.text, v.player)
                    color = COLORS.MAGENTA
                elseif v.type == "location_name" then
                    color = COLORS.MAGENTA
                elseif v.type == "entrance_name" then
                    color = COLORS.CYAN
                elseif v.type == "color" then
                    if v.color == "black" then
                        color = COLORS.BLACK
                    elseif v.color == "white" then
                        color = COLORS.WHITE
                    elseif v.color == "red" then
                        color = COLORS.RED
                    elseif v.color == "green" then
                        color = COLORS.GREEN
                    elseif v.color == "blue" then
                        color = COLORS.BLUE
                    elseif v.color == "magenta" then
                        color = COLORS.MAGENTA
                    elseif v.color == "cyan" then
                        color = COLORS.CYAN
                    end
                end
                if not text then
                    text = ""
                end
                local part = {
                    msg = text,
                    color = color,
                    width = Isaac.GetTextWidth(text)
                }
                table.insert(msg.parts, part)
            end
            self:addMessage(msg)
        end
    end

    function self.on_bounced(bounce)
        -- dbg_log("Bounced:"..dump_table(bounce))
        if bounce.tags and tbl_contains(bounce.tags, "DeathLink") and bounce.data then
            -- print(self.LAST_DEATH_LINK_TIME, block.data.time)
            if self.LAST_DEATH_LINK_TIME ~= nil and tostring(self.LAST_DEATH_LINK_TIME) == tostring(bounce.data.time) then
                -- our own package -> Do nothing
            else
                local player = Game():GetNearestPlayer(Isaac.GetRandomPosition())
                player:Die()
                local cause = bounce.data.cause or "unknown"
                local source = bounce.data.source or "unknown"
                self:addMessage({
                    parts = { {
                        msg = "[DeathLink] Killed by " .. source .. ". Reason: " .. cause,
                        color = COLORS.RED
                    } }
                })
                self.LAST_DEATH_LINK_RECV = bounce.data.time
            end
        end
    end

    function self.on_retrieved(map)
        -- todo: look at map
        dbg_log("Retrieved: " .. dump_table(map))
        self:syncNoteInfoFromDict(map)
        self:syncFurthestFloor(map)
    end

    function self.on_set_reply(message)
        dbg_log("Set Reply:" .. dump_table(message))
        local splitResult = split(message.key, "_")
        -- print("! got SetReply !", 2, dump_table(splitResult),#splitResult,self.CONNECTION_INFO.team,self.CONNECTION_INFO.slot)
        if #splitResult >= 4 then
            -- print("! got SetReply !", 3)
            if splitResult[1] == "tobir" and tonumber(splitResult[2]) == self.CONNECTION_INFO.team and
                tonumber(splitResult[3]) == self.CONNECTION_INFO.slot then
                if splitResult[4] == "floor" then
                    -- print("! got SetReply !", 4)
                    self.FURTHEST_FLOOR = message.value
                    if self.SLOT_DATA.splitStartItems and self.SLOT_DATA.splitStartItems == 2 then
                        self.ITEM_QUEUE_COUNTER = 0
                        self.ITEM_QUEUE_MAX_PER_FLOOR = math.ceil(#self.ITEM_QUEUE / self.FURTHEST_FLOOR)
                        self.ITEM_QUEUE_CURRENT_MAX = self:getStageNum() * self.ITEM_QUEUE_MAX_PER_FLOOR
                    end
                end
                local goal = tonumber(self.SLOT_DATA.goal)
                -- print("! got SetReply !", 4, goal)
                if (goal == 16 or goal == 17) and splitResult[4] == "note" and #splitResult >= 6 then
                    -- print("! got SetReply !", 5)
                    local note_type = tonumber(splitResult[5])
                    local note_char = tonumber(splitResult[6])
                    if not self.NOTE_INFO[note_char] then
                        self.NOTE_INFO[note_char] = {}
                    end
                    self.NOTE_INFO[note_char][note_type] = (message.value == 1)
                    self:checkNoteInfo()
                end
            end
        end
    end
end

function AP:resolveIdToName(typeStr, id, slot)
    --dbg_log("AP:resolveIdToName " .. typeStr .. " " .. tostring(id))
    if string.find(typeStr, "location") then
        if type(id) == "string" then
            id = tonumber(id)
        end
        local game = self.AP_CLIENT:get_player_game(slot)
        return self.AP_CLIENT:get_location_name(id, game)
    elseif string.find(typeStr, "item") then
        if type(id) == "string" then
            id = tonumber(id)
        end
        local game = self.AP_CLIENT:get_player_game(slot)
        return self.AP_CLIENT:get_item_name(id, game)
    elseif string.find(typeStr, "player") then
        if type(id) == "string" then
            id = tonumber(id)
        end
        --dbg_log("AP:resolveIdToName player " .. tostring(id))
        return self.AP_CLIENT:get_player_alias(id)
    else
        dbg_log('!!! can to resolve Id to Name of unknown type ' .. typeStr .. ' !!!')
        return id
    end
end

function AP:sendLocationsCleared(ids)
    self.AP_CLIENT:LocationChecks(ids)
end

function AP:sendDeathLinkBounce(cause, source)
    cause = cause or AP.GAME_NAME
    source = source or self.AP_CLIENT:get_player_alias(self.CONNECTION_INFO.slot)
    local time = self.AP_CLIENT:get_server_time()
    self.LAST_DEATH_LINK_TIME = time
    dbg_log("AP:sendDeathLinkBounce " .. tostring(time) .. " " .. cause .. " " .. source)
    local res = self.AP_CLIENT:Bounce({
        time = time,
        cause = cause,
        source = source
    }, {}, {}, { "DeathLink" })
    dbg_log("AP:sendDeathLinkBounce " .. tostring(self.AP_CLIENT))
    dbg_log("AP:sendDeathLinkBounce " .. tostring(res))
end

function AP:collectSlot()
    if self.AP_CLIENT:get_state() ~= APClient.State.SLOT_CONNECTED then
        self:addMessage({
            parts = { {
                msg = "You can not collect when you are not connected",
                color = COLORS.RED
            } }
        })
        return
    end
    self.AP_CLIENT:Say("!collect")
end

function AP:releaseSlot()
    if self.AP_CLIENT:get_state() ~= APClient.State.SLOT_CONNECTED then
        self:addMessage({
            parts = { {
                msg = "You can not release! (not connected or no permission)",
                color = COLORS.RED
            } }
        })
    end
    self.AP_CLIENT:Say("!release")
end

function AP:sendHintCommand(isLocation, name)
    local text = "!hint"
    if isLocation then
        text = text .. "_location"
    end
    if name then
        text = text .. " " .. name
    end
    self.AP_CLIENT:Say(text)
end

function AP:sendGoalReached()
    dbg_log('sendGoalReached')
    self.AP_CLIENT:StatusUpdate(30)
end

function AP:connectAP()
    self.LAST_RECEIVED_ITEM_INDEX = -1
    local uuid = ""
    print("AP:connect_ap", uuid, AP.GAME_NAME, self.HOST_ADDRESS .. ":" .. self.HOST_PORT)
    ---@type APClient
    self.AP_CLIENT = APClient(uuid, AP.GAME_NAME, self.HOST_ADDRESS .. ":" .. self.HOST_PORT)

    self.AP_CLIENT:set_socket_connected_handler(self.on_socket_connected)
    self.AP_CLIENT:set_socket_error_handler(self.on_socket_error)
    self.AP_CLIENT:set_socket_disconnected_handler(self.on_socket_disconnected)
    self.AP_CLIENT:set_room_info_handler(self.on_room_info)
    self.AP_CLIENT:set_slot_connected_handler(self.on_slot_connected)
    self.AP_CLIENT:set_slot_refused_handler(self.on_slot_refused)
    self.AP_CLIENT:set_items_received_handler(self.on_items_received)
    self.AP_CLIENT:set_location_info_handler(self.on_location_info)
    self.AP_CLIENT:set_location_checked_handler(self.on_location_checked)
    self.AP_CLIENT:set_data_package_changed_handler(self.on_data_package_changed)
    self.AP_CLIENT:set_print_handler(self.on_print)
    self.AP_CLIENT:set_print_json_handler(self.on_print_json)
    self.AP_CLIENT:set_bounced_handler(self.on_bounced)
    self.AP_CLIENT:set_retrieved_handler(self.on_retrieved)
    self.AP_CLIENT:set_set_reply_handler(self.on_set_reply)
end

function AP:reconnectAP()
    self:connectAP()
end

function AP:getAPState()
    if not self.AP_CLIENT then
        return AP.STATES[0]
    end
    local val = self.AP_CLIENT:get_state()
    if val > 4 or val < 0 then
        return nil
    end
    return AP.STATES[val]
end
