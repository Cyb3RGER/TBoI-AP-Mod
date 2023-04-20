local APClient = require('lua-apclientpp')
local json = require('json')

-- AP client / Mod version 
AP.VERSION = {0, 3, 0}
AP.GAME_NAME = "The Binding of Isaac Repentance"
AP.ITEM_HANDLING = 7 --fully remote
AP.TAGS = {"Lua-APClientPP"}

function AP:init_ap_client()
    function self.on_socket_connected()
        Isaac.DebugString("Socket connected")
        
    end

    function self.on_socket_error(msg)
        Isaac.DebugString("Socket error: " .. msg)
    end

    function self.on_socket_disconnected()
        Isaac.DebugString("Socket disconnected")
    end

    function self.on_room_info()
        Isaac.DebugString("Room info")
        -- print('!!! got RoomInfo !!!')
        -- self.ROOM_INFO = block
        -- local games = self.ROOM_INFO.games
        -- table.insert(games, "Archipelago")
        -- self.OUTDATED_GAMES = deepcopy(games)
        -- print("Room info", 2)
        -- for _, v in pairs(games) do
        --     if self.GAME_DATA and self.GAME_DATA.games and self.GAME_DATA.games[v] and
        --         self.GAME_DATA.games[v].version then
        --         if self.GAME_DATA.games[v].version == self.ROOM_INFO.datapackage_versions[v] then
        --             table.remove(self.OUTDATED_GAMES, findIndex(self.OUTDATED_GAMES, v))
        --         end
        --     end
        -- end
        --if #self.OUTDATED_GAMES > 0 then
        --    self.STATE_MACHINE:set_state(AP.STATE_DATAPACKAGE)
        --else
        --    self.STATE_MACHINE:set_state(AP.STATE_CONNECTED)
        --end
                
        self.AP_CLIENT:ConnectSlot(self.SLOT_NAME, self.PASSWORD, AP.ITEM_HANDLING, AP.TAGS, AP.VERSION)
    end

    function self.on_slot_connected(slot_data)
        Isaac.DebugString("Slot connected")
        self.CONNECTION_INFO = {
            -- ToDo: 
            --team = self.AP_CLIENT:get_team_number(),
            --slot = self.AP_CLIENT:get_slot_number()
        }
        self.SLOT_DATA = slot_data
        print("Connected", 1, dump_table(slot_data))        
        Isaac.DebugString(dump_table(slot_data))
        if self.SLOT_DATA.deathLink and self.SLOT_DATA.deathLink == 1 then
            table.insert(AP.TAGS, "DeathLink")
            self.AP_CLIENT:ConnectUpdate(nil, AP.TAGS)            
        end
        print("Connected", 2, dump_table(AP.TAGS))
        -- ToDo: 
        --self.MISSING_LOCATIONS = block.missing_locations
        --self.CHECKED_LOCATIONS = block.checked_locations
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
        print("Connected", 3)
        -- ToDo: 
        -- self:setPersistentInfoFurthestFloor("default")
        -- if self.SLOT_DATA.splitStartItems and self.SLOT_DATA.splitStartItems == 2 then
        --     self:getPersistentInfoFurthestFloor()
        -- end
        print("Connected", 4)
        self.TRAP_QUEUE = {}
        self.TRAP_QUEUE_TIMER = 150
        --local required_locations = tonumber(self.SLOT_DATA.requiredLocations)
        --local goal = tonumber(self.SLOT_DATA.goal)
        --if required_locations and goal and #self.CHECKED_LOCATIONS >= required_locations then
        --    if not self.HAS_SEND_GOAL_MSG then
        --        self:addMessage({
        --            parts = {{
        --                msg = "You have collected enough items to beat the game. Goal: " .. self:goalIdToName(goal),
        --                color = COLORS.GREEN
        --            }}
        --        })
        --        self.HAS_SEND_GOAL_MSG = true
        --    end
        --    if goal == 15 then
        --        self:sendGoalReached()
        --    end
        --    if goal == 16 or goal == 17 then
        --        self:checkNoteInfo()
        --    end
        --end
        --if goal == 16 or goal == 17 then
        --    self:setupLocalNoteInfo()
        --    self:setupPersistentNoteInfo()
        --end
        if self.IS_CONTINUED then
            if not self:loadOtherData(self.CONNECTION_INFO.slot_data.seed) then
                self:shutdown()
                self:addMessage({
                    parts = {{
                        msg = "You are continuing a run of a different slot/game. You have beeen disconnected from the AP server. Please start a new run.",
                        color = COLORS.RED
                    }}
                })
                return
            end
        else
            self.LAST_RECEIVED_ITEM_INDEX = -1
            self.CUR_ITEM_STEP_VAL = 0
            self:saveOtherData("")
        end
        print("Connected", "end")
    end


    function self.on_slot_refused(reasons)
        Isaac.DebugString("Slot refused: " .. table.concat(reasons, ", "))
    end

    function self.on_items_received(items)
        Isaac.DebugString("Items received:")
        for _, item in ipairs(items) do
            Isaac.DebugString(item.item)
        end
    end

    function self.on_location_info(items)
        Isaac.DebugString("Locations scouted:")
        for _, item in ipairs(items) do
            Isaac.DebugString(item.item)
        end
    end

    function self.on_location_checked(locations)
        Isaac.DebugString("Locations checked:")
        for _, id in ipairs(locations) do
            Isaac.DebugString(id)
        end
    end

    function self.on_data_package_changed(data_package)
        Isaac.DebugString("Data package changed:")
        Isaac.DebugString(data_package)
    end

    function self.on_print(msg)
        Isaac.DebugString(msg)
    end

    function self.on_print_json(msg)
        Isaac.DebugString("on_print_json")
        Isaac.DebugString(dump_table(msg))
    end

    function self.on_bounced(bounce)
        Isaac.DebugString("Bounced:")
        Isaac.DebugString(bounce)
    end

    function self.on_retrieved(map)
        Isaac.DebugString("Retrieved:")
        for key, value in pairs(map) do
            Isaac.DebugString("  " .. key .. ": " .. tostring(value))
        end
    end

    function self.on_set_reply(message)
        Isaac.DebugString("Set Reply:")
        for key, value in pairs(message) do
            Isaac.DebugString("  " .. key .. ": " .. tostring(value))
        end
    end
end

function AP:connect_ap()
    local uuid = ""
    print("AP:connect_ap", uuid, AP.GAME_NAME, self.HOST_ADDRESS..":"..self.HOST_PORT)
    self.AP_CLIENT = APClient(uuid, AP.GAME_NAME, self.HOST_ADDRESS..":"..self.HOST_PORT)

    self.AP_CLIENT:set_socket_connected_handler(self.on_socket_connected)
    self.AP_CLIENT:set_socket_error_handler(self.on_socket_error)
    self.AP_CLIENT:set_socket_disconnected_handler(self.on_socket_disconnected)
    self.AP_CLIENT:set_room_info_handler(self.on_room_info)
    self.AP_CLIENT:set_slot_connected_handler(self.on_slot_connected)
    --self.AP_CLIENT:set_slot_refused_handler(self.on_slot_refused)
    --self.AP_CLIENT:set_items_received_handler(self.on_items_received)
    --self.AP_CLIENT:set_location_info_handler(self.on_location_info)
    --self.AP_CLIENT:set_location_checked_handler(self.on_location_checked)
    --self.AP_CLIENT:set_data_package_changed_handler(self.on_data_package_changed)
    --self.AP_CLIENT:set_print_handler(self.on_print)
    --self.AP_CLIENT:set_print_json_handler(self.on_print_json)
    --self.AP_CLIENT:set_bounced_handler(self.on_bounced)
    --self.AP_CLIENT:set_retrieved_handler(self.on_retrieved)
    --self.AP_CLIENT:set_set_reply_handler(self.on_set_reply)

end

