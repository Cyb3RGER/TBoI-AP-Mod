local json = require('json')
local ws_client = require('websocket.client_sync')
local tools = require('websocket.tools')
local handshake = require('websocket.handshake')
local frame = require('websocket.frame')
local socket = require('socket')
require('utils')
require('statemachine')
-- IS_WINDOWS = package.config:sub(1, 1) == "\\" or package.config:sub(1, 1) == "\\\\"
LAST_TYPED_CHAR = "None"
UNLOCK_TYPING = false
TYPING_TARGET = nil
CURRENT_TYPING_STRING = ""
PRESSED_BUTTONS = {}
PREV_PRESSED_BUTTONS = {}
WAIT_TYPING_ENTER_EXIT = 0
LAST_PRESSED = {
    action = -1,
    controller = -1
}
SPECIAL_KEY_MAPPING = {
    ["SPACE"] = " ",
    ["APOSTROPHE"] = "\'",
    ["COMMA"] = ",",
    ["MINUS"] = "-",
    ["PERIOD"] = ".",
    ["SLASH"] = "/",
    ["SEMICOLON"] = ";",
    ["EQUAL"] = "=",
    ["LEFT BRACKET"] = "[",
    ["RIGHT BRACKET"] = "]",
    ["GRAVE ACCENT"] = "`",
    ["KP_0"] = "0",
    ["KP_1"] = "1",
    ["KP_2"] = "2",
    ["KP_3"] = "3",
    ["KP_4"] = "4",
    ["KP_5"] = "5",
    ["KP_6"] = "6",
    ["KP_7"] = "7",
    ["KP_8"] = "8",
    ["KP_9"] = "9"
}
SPECIAL_KEY_MAPPING_UPPER = {
    ["SPACE"] = " ",
    ["APOSTROPHE"] = "\"",
    ["COMMA"] = "<",
    ["MINUS"] = "_",
    ["PERIOD"] = ">",
    ["SLASH"] = "?",
    ["SEMICOLON"] = ":",
    ["EQUAL"] = "+",
    ["LEFT BRACKET"] = "{",
    ["RIGHT BRACKET"] = "}",
    ["GRAVE ACCENT"] = "~",
    ["KP_0"] = "0",
    ["KP_1"] = "1",
    ["KP_2"] = "2",
    ["KP_3"] = "3",
    ["KP_4"] = "4",
    ["KP_5"] = "5",
    ["KP_6"] = "6",
    ["KP_7"] = "7",
    ["KP_8"] = "8",
    ["KP_9"] = "9"
}
TOGGLE_LOWERCASE = false

AP = class()

AP.INSTANCE = nil

AP.GAME_NAME = "The Binding of Isaac Repentance"
-- State names for stateMachine
AP.STATE_CONNECTING = "connecting"
AP.STATE_HANDSHAKE = "handshake"
AP.STATE_ROOMINFO = "room info"
AP.STATE_DATAPACKAGE = "datapackage"
AP.STATE_CONNECTED = "connected"
AP.STATE_EXIT = "disconnected"
AP.USE_ITEM_QUEUE = false

AP.ITEM_IMPLS = {
    [78000] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_TREASURE)
    end,
    [78001] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_SHOP)
    end,
    [78002] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_BOSS)
    end,
    [78003] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_DEVIL)
    end,
    [78004] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_ANGEL)
    end,
    [78005] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_SECRET)
    end,
    [78006] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_LIBRARY)
    end,
    [78007] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_CURSE)
    end,
    [78008] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_PLANETARIUM)
    end,
    [78009] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_SHELL_GAME)
    end,
    [78010] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GOLDEN_CHEST)
    end,
    [78011] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_RED_CHEST)
    end,
    [78012] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_BEGGAR)
    end,
    [78013] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_DEMON_BEGGAR)
    end,
    [78014] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_KEY_MASTER)
    end,
    [78015] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_BATTERY_BUM)
    end,
    [78016] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_MOMS_CHEST)
    end,
    [78017] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_TREASURE)
    end,
    [78018] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_BOSS)
    end,
    [78019] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_SHOP)
    end,
    [78020] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_DEVIL)
    end,
    [78021] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_ANGEL)
    end,
    [78022] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_CURSE)
    end,
    [78023] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_SECRET)
    end,
    [78024] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_CRANE_GAME)
    end,
    [78025] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_ULTRA_SECRET)
    end,
    [78026] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_BOMB_BUM)
    end,
    [78027] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_OLD_CHEST)
    end,
    [78028] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_BABY_SHOP)
    end,
    [78029] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_WOODEN_CHEST)
    end,
    [78030] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_ROTTEN_BEGGAR)
    end,
    [78031] = function(ap)
        ap:spawnRandomPickup()
    end,
    [78032] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_HEART)
    end,
    [78033] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_COIN)
    end,
    [78034] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_BOMB)
    end,
    [78035] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_KEY)
    end,
    [78036] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_TAROTCARD)
    end,
    [78037] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_PILL)
    end,
    [78038] = function(ap)
        ap:spawnRandomChest()
    end,
    [78039] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_TRINKET)
    end,
    -- 78040 - 78771 are generated by AP:generateCollectableItemImpls
    [78772] = function(ap)
        ap:addToTrapQueue(78772)
    end,
    [78773] = function(ap)
        ap:addToTrapQueue(78773)
    end,
    [78774] = function(ap)
        ap:addToTrapQueue(78774)
    end,
    [78775] = function(ap)
        ap:addToTrapQueue(78775)
    end,
    [78776] = function(ap)
        ap:addToTrapQueue(78776)
    end,
    [78777] = function(ap)
        ap:addToTrapQueue(78777)
    end
}

AP.TRAP_IMPLS = {
    [78772] = function(ap)
        for i = 0, 5 do
            ap:addToSpawnQueue(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, BombSubType.BOMB_TROLL, 5)
        end
    end,
    [78773] = function(ap)
        local level = Game():GetLevel()
        if (level:GetCurrentRoomDesc().Flags & RoomDescriptor.FLAG_CURSED_MIST) ~= RoomDescriptor.FLAG_CURSED_MIST then
            Game():StartRoomTransition(level:GetRandomRoomIndex(ap.CONNECTION_INFO.slot_data.teleportTrapCanError,
                ap.RNG:Next()), -1, RoomTransitionAnim.TELEPORT)
        end
    end,
    [78774] = function(ap)
        Game():AddPixelation(300)
    end,
    [78775] = function(ap)
        local level = Game():GetLevel()
        local currentCurses = level:GetCurses()
        local curses = {LevelCurse.CURSE_OF_DARKNESS, LevelCurse.CURSE_OF_THE_LOST, LevelCurse.CURSE_OF_THE_UNKNOWN,
                        LevelCurse.CURSE_OF_MAZE, LevelCurse.CURSE_OF_BLIND}
        while #curses > 0 do
            local idx = ap.RNG:RandomInt(#curses - 1) + 1
            local curse = curses[idx]
            if currentCurses & curse == curse then
                table.remove(curses, idx)
            else
                level:AddCurse(curse, false)
                return
            end
        end
    end,
    [78776] = function(ap)
        -- local player =  Game():GetNearestPlayer(Isaac.GetRandomPosition())        
        -- player:UsePill(PillEffect.PILLEFFECT_PARALYSIS, 0) -- crashes
    end,
    [78777] = function(ap)
        local player = Game():GetNearestPlayer(Isaac.GetRandomPosition())
        player:UseActiveItem(CollectibleType.COLLECTIBLE_WAVY_CAP)
    end
}

function AP:init()
    AP.INSTANCE = self
    print("called AP:init", 1)
    self:generateCollectableItemImpls(78040)
    self.RNG = RNG()
    self.RNG:SetSeed(Random(), 35)
    self.DEBUG_MODE = false
    self.INFO_TEXT_SCALE = 1
    self.HUD_OFFSET = 25
    -- AP client / Mod version 
    self.MAJOR_VERSION = "0"
    self.MINOR_VERSION = "2"
    self.BUILD_VERSION = "0"
    -- AP Connection info
    self.HOST_ADDRESS = "localhost"
    self.HOST_PORT = "38281"
    self.PASSWORD = ""
    self.SLOT_NAME = "Player1"
    -- print("called AP:init", 1.5, self.HOST_ADDRESS, self.HOST_PORT, self.SLOT_NAME, self.PASSWORD)
    function self.typeKey(this, key)
        local keyName = InputHelper.KeyboardToString[key] or "Unknown"
        -- print("self.typeKey", 1, key, keyName)
        if #keyName == 1 then
            if not TOGGLE_LOWERCASE then
                keyName = string.lower(keyName)
            end
            CURRENT_TYPING_STRING = CURRENT_TYPING_STRING .. keyName
        elseif TOGGLE_LOWERCASE and SPECIAL_KEY_MAPPING_UPPER[keyName] then
            CURRENT_TYPING_STRING = CURRENT_TYPING_STRING .. SPECIAL_KEY_MAPPING_UPPER[keyName]
        elseif SPECIAL_KEY_MAPPING[keyName] then
            CURRENT_TYPING_STRING = CURRENT_TYPING_STRING .. SPECIAL_KEY_MAPPING[keyName]
        elseif keyName == "BACKSPACE" then
            CURRENT_TYPING_STRING = CURRENT_TYPING_STRING:sub(1, #CURRENT_TYPING_STRING - 1)
        elseif keyName == "LEFT SHIFT" or keyName == "RIGHT SHIFT" or keyName == "CAPS LOCK" then
            TOGGLE_LOWERCASE = not TOGGLE_LOWERCASE
        elseif keyName == "ENTER" or keyName == "ESCAPE" or keyName == "TAB" or keyName == "END" then
            return true
        end
        return false
    end
    function self.trackTypingInput()
        if not InputHelper or not ModConfigMenu then
            return
        end
        if not UNLOCK_TYPING then
            ModConfigMenu.ControlsEnabled = true
            return
        end
        if not ModConfigMenu.IsVisible then
            UNLOCK_TYPING = false
            return
        end

        ModConfigMenu.ControlsEnabled = false
        local receivedInput = false
        local endTyping = false
        -- capture input
        PRESSED_BUTTONS = {}
        for i = 0, 4 do
            PRESSED_BUTTONS[i] = {}
            for j = 32, 400 do
                PRESSED_BUTTONS[i][j] = (InputHelper.KeyboardPressed(j, i) and 1 or 0)
                if PRESSED_BUTTONS[i][j] and PRESSED_BUTTONS[i][j] > 0 and not receivedInput then
                    receivedInput = true
                end
            end
        end
        -- type input
        -- print("self.trackTypingInput",1,receivedInput)
        if receivedInput then
            for i = 0, 4 do
                if PRESSED_BUTTONS[i] then
                    for j = 32, 400 do
                        -- if PRESSED_BUTTONS[i][j] and PRESSED_BUTTONS[i][j] > 0 then
                        --     print("self.trackTypingInput",2,PRESSED_BUTTONS[i][j],PREV_PRESSED_BUTTONS[i][j])                                       
                        -- end
                        if PRESSED_BUTTONS[i][j] and PRESSED_BUTTONS[i][j] > 0 and
                            not (PREV_PRESSED_BUTTONS and PREV_PRESSED_BUTTONS[i] and PREV_PRESSED_BUTTONS[i][j] and
                                PREV_PRESSED_BUTTONS[i][j] > 0 and
                                (PREV_PRESSED_BUTTONS[i][j] < 900 or PREV_PRESSED_BUTTONS[i][j] % 100 ~= 0)) then
                            endTyping = self:typeKey(j)
                        end
                    end
                end
            end
        end
        -- copy over captured input
        if not PREV_PRESSED_BUTTONS then
            PREV_PRESSED_BUTTONS = PRESSED_BUTTONS
        else
            for i = 0, 4 do
                if PRESSED_BUTTONS[i] then
                    if not PREV_PRESSED_BUTTONS[i] then
                        PREV_PRESSED_BUTTONS[i] = PRESSED_BUTTONS[i]
                    else
                        for j = 32, 400 do
                            if PRESSED_BUTTONS[i][j] > 0 then
                                if not PREV_PRESSED_BUTTONS[i][j] then
                                    PREV_PRESSED_BUTTONS[i][j] = PRESSED_BUTTONS[i][j]
                                else
                                    PREV_PRESSED_BUTTONS[i][j] = PREV_PRESSED_BUTTONS[i][j] + PRESSED_BUTTONS[i][j]
                                end
                            else
                                PREV_PRESSED_BUTTONS[i][j] = 0
                            end
                        end
                    end
                end
            end
        end
        -- end typing
        if endTyping and WAIT_TYPING_ENTER_EXIT <= 0 then
            if TYPING_TARGET == "HOST_ADDRESS" then
                self.HOST_ADDRESS = CURRENT_TYPING_STRING
            elseif TYPING_TARGET == "HOST_PORT" then
                self.HOST_PORT = CURRENT_TYPING_STRING
            elseif TYPING_TARGET == "SLOT_NAME" then
                self.SLOT_NAME = CURRENT_TYPING_STRING
            elseif TYPING_TARGET == "PASSWORD" then
                Isaac.DebugString("set PASSWORD to " .. CURRENT_TYPING_STRING)
                self.PASSWORD = CURRENT_TYPING_STRING
            end
            CURRENT_TYPING_STRING = ""
            TYPING_TARGET = nil
            UNLOCK_TYPING = false
            WAIT_TYPING_ENTER_EXIT = 30
            self:saveConnectionInfo()
        end
        return
    end
    function self.modConfigMenuInit()
        if ModConfigMenu == nil then
            return
        end
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.TEXT,
            CurrentSetting = function()
                return self.HOST_ADDRESS
            end,
            Display = function()
                return "AP Host Address: " .. (self.HOST_ADDRESS or "")
            end,
            OnChange = function(v)

            end,
            Info = {"This the IP address of the AP Host Server"}
        })
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return nil
            end,
            Display = function()
                local text = "Change AP Host Address"
                if UNLOCK_TYPING and TYPING_TARGET == "HOST_ADDRESS" then
                    text = "Typing: " .. CURRENT_TYPING_STRING
                end
                return text
            end,
            OnChange = function(v)
                if WAIT_TYPING_ENTER_EXIT > 0 then
                    return
                end
                CURRENT_TYPING_STRING = self.HOST_ADDRESS
                TYPING_TARGET = "HOST_ADDRESS"
                PREV_PRESSED_BUTTONS = {}
                WAIT_TYPING_ENTER_EXIT = 30
                UNLOCK_TYPING = true
            end,
            Info = {"ENTER = quit & save, ESC = quit,$newline$newlineSHIFT = toggle case"}
        })
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.TEXT,
            CurrentSetting = function()
                return self.HOST_PORT
            end,
            Display = function()
                return "AP Host Port: " .. (self.HOST_PORT or "")
            end,
            OnChange = function(v)

            end,
            Info = {"This the port of the AP Host Server"}
        })
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return nil
            end,
            Display = function()
                local text = "Change AP Host Port"
                if UNLOCK_TYPING and TYPING_TARGET == "HOST_PORT" then
                    text = "Typing: " .. CURRENT_TYPING_STRING
                end
                return text
            end,
            OnChange = function(v)
                if WAIT_TYPING_ENTER_EXIT > 0 then
                    return
                end
                CURRENT_TYPING_STRING = self.HOST_PORT
                TYPING_TARGET = "HOST_PORT"
                PREV_PRESSED_BUTTONS = {}
                WAIT_TYPING_ENTER_EXIT = 30
                UNLOCK_TYPING = true
            end,
            Info = {"ENTER = quit & save, ESC = quit,$newline$newlineSHIFT = toggle case"}
        })
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.TEXT,
            CurrentSetting = function()
                return self.SLOT_NAME
            end,
            Display = function()
                return "AP Slot Name: " .. (self.SLOT_NAME or "")
            end,
            OnChange = function(v)

            end,
            Info = {"This is the slot name of the slot you want to connect to in the AP Room"}
        })
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return nil
            end,
            Display = function()
                local text = "Change AP Slot Name"
                if UNLOCK_TYPING and TYPING_TARGET == "SLOT_NAME" then
                    text = "Typing: " .. CURRENT_TYPING_STRING
                end
                return text
            end,
            OnChange = function(v)
                if WAIT_TYPING_ENTER_EXIT > 0 then
                    return
                end
                CURRENT_TYPING_STRING = self.SLOT_NAME
                TYPING_TARGET = "SLOT_NAME"
                PREV_PRESSED_BUTTONS = {}
                WAIT_TYPING_ENTER_EXIT = 30
                UNLOCK_TYPING = true
            end,
            Info = {"ENTER = quit & save, ESC = quit,$newline$newlineSHIFT = toggle case"}
        })
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.TEXT,
            CurrentSetting = function()
                return self.PASSWORD
            end,
            Display = function()
                local displayVal = "none"
                if self.PASSWORD then
                    displayVal = ""
                    for i = 1, #self.PASSWORD do
                        displayVal = displayVal .. "*"
                    end
                end
                return "AP Password: " .. displayVal
            end,
            OnChange = function(v)

            end,
            Info = {"This the password of the AP Room. This is optional."}
        })
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return nil
            end,
            Display = function()
                local text = "Change AP Password"
                if UNLOCK_TYPING and TYPING_TARGET == "PASSWORD" then
                    text = "Typing: " .. CURRENT_TYPING_STRING
                end
                return text
            end,
            OnChange = function(v)
                if WAIT_TYPING_ENTER_EXIT > 0 then
                    return
                end
                CURRENT_TYPING_STRING = self.PASSWORD
                TYPING_TARGET = "PASSWORD"
                PREV_PRESSED_BUTTONS = {}
                WAIT_TYPING_ENTER_EXIT = 30
                UNLOCK_TYPING = true
            end,
            Info = {"ENTER = quit & save, ESC = quit,$newline$newlineSHIFT = toggle case"}
        })
        -- ModConfigMenu.AddSetting("AP Integration", nil, {
        --    Type = ModConfigMenu.OptionType.BOOLEAN,
        --    CurrentSetting = function()
        --        return nil
        --    end,
        --    Display = function()
        --        return "Change"
        --    end,
        --    OnChange = function(v)
        --        if OPEN_INPUT_COOLDOWN > 0 then
        --            return
        --        end
        --        local cmd = "\"mods/ap/input.sh\""
        --        if IS_WINDOWS then
        --            cmd = "start call \"mods/ap/input.bat\""
        --        end
        --        print(cmd)
        --        print(os.execute(cmd))
        --        OPEN_INPUT_COOLDOWN = 100
        --        if package.loaded.connection_info then
        --            package.loaded.connection_info = nil
        --        end
        --        local status, temp = pcall(include, 'connection_info')
        --        print(status, temp)
        --        if status then
        --            AP_CONNECTION_INFO = temp
        --            self:loadConnectionInfo()
        --        end
        --    end,
        --    Info = {"Click this to change the AP Settings"}
        -- })
        -- ModConfigMenu.AddSetting("AP Integration", nil, {
        --    Type = ModConfigMenu.OptionType.BOOLEAN,
        --    CurrentSetting = function()
        --        return nil
        --    end,
        --    Display = function()
        --        return "Reload"
        --    end,
        --    OnChange = function(v)
        --        if package.loaded.connection_info then
        --            package.loaded.connection_info = nil
        --        end
        --        local status, temp = pcall(include, 'connection_info')
        --        if status then
        --            AP_CONNECTION_INFO = temp
        --            self:loadConnectionInfo()
        --        end
        --    end,
        --    Info = {"Click this to change the AP Settings"}
        -- })
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return nil
            end,
            Display = function()
                return "Reconnect"
            end,
            OnChange = function(v)
                self.RECONNECT_TRIES = 0
                self:reconnect()
            end,
            Info = {"Click this to reconnect to the AP Server"}
        })
        local textScales = {0.25, 0.5, 1, 1.1, 1.2, 1.5}
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return findIndex(textScales, self.INFO_TEXT_SCALE)
            end,
            Minimum = 1,
            Maximum = #textScales,
            Display = function()
                return "Text Scale: " .. self.INFO_TEXT_SCALE
            end,
            OnChange = function(v)
                self.INFO_TEXT_SCALE = textScales[v]
                self:saveSettings()
            end,
            Info = {"Adjust the Text Size of the AP mod"}
        })
        local hudOffsets = {0, 5, 10, 15, 20, 25, 30}
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return findIndex(hudOffsets, self.HUD_OFFSET)
            end,
            Minimum = 1,
            Maximum = #hudOffsets,
            Display = function()
                return "HUD Offset: " .. self.HUD_OFFSET
            end,
            OnChange = function(v)
                self.HUD_OFFSET = hudOffsets[v]
                self:saveSettings()
            end,
            Info = {"Adjust where the AP Text is placed on the HUD"}
        })
        ModConfigMenu.AddSetting("AP Integration", nil, {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return self.DEBUG_MODE
            end,
            Display = function()
                local str = "Off"
                if self.DEBUG_MODE then
                    str = "On"
                end
                return "Debug Mode: " .. str
            end,
            OnChange = function(v)
                self.DEBUG_MODE = not self.DEBUG_MODE
                self:saveSettings()
            end,
            Info = {"For debugging"}
        })

    end
    -- socket / statemachine
    self.STATE_MACHINE = SimpleStateMachine()
    -- statemachine callbacks
    function self.onEnter_Connecting()
        self.LAST_RECEIVED_ITEM_INDEX = -1
    end
    function self.onTick_Connecting()
        if self.RECONNECT_TRIES >= self.MAX_RECONNECT_TRIES then
            self:shutdown()
            return
        end
        self.currTime = os.time()
        if self.lastTime + self.RECONNECT_INTERVAL <= self.currTime then
            self.lastTime = self.currTime
            self.socket = ws_client()
            local ret, err = self.socket:sock_connect(self.HOST_ADDRESS, self.HOST_PORT)
            if ret == 1 then
                print('Connection established')
                self.socket:set_timeout(0)
                local key = tools.generate_key()
                local req = handshake.upgrade_request {
                    key = key,
                    host = self.HOST_ADDRESS,
                    port = self.HOST_PORT,
                    protocols = {'ws'},
                    origin = '',
                    uri = 'ws://' .. self.HOST_ADDRESS .. ':' .. self.HOST_PORT
                }
                self.socket:sock_send(req)
                self.STATE_MACHINE:set_state(AP.STATE_HANDSHAKE)
            else
                print('Failed to open socket:', err) -- ToDo: show as message
                self.socket:sock_close()
                self.socket = nil
                self.RECONNECT_TRIES = self.RECONNECT_TRIES + 1
            end
        end
    end
    function self.onTick_Handshake()
        self:receiveHandshake()
    end
    function self.onTick_Connected()
        self:receive()
    end
    function self.onEnter_Connected()
        self:sendBlocks({self:getConnectCommand()})
    end
    function self.onEnter_Datapackage()
        self:sendBlocks({self:getDataPackageCommand()})
    end
    function self.onExit_Connected()
        self:disconnect()
    end
    function self.onEnter_Exit()
        self:disconnect()
    end
    -- END statemachine callbacks
    self.STATE_MACHINE:register(AP.STATE_CONNECTING, self.onEnter_Connecting, self.onTick_Connecting, nil)
    self.STATE_MACHINE:register(AP.STATE_HANDSHAKE, nil, self.onTick_Handshake, nil)
    self.STATE_MACHINE:register(AP.STATE_ROOMINFO, nil, self.onTick_Connected, nil)
    self.STATE_MACHINE:register(AP.STATE_DATAPACKAGE, self.onEnter_Datapackage, self.onTick_Connected, nil)
    self.STATE_MACHINE:register(AP.STATE_CONNECTED, self.onEnter_Connected, self.onTick_Connected, self.onExit_Connected)
    self.STATE_MACHINE:register(AP.STATE_EXIT, self.onEnter_Exit, nil, nil)
    self.RECONNECT_INTERVAL = 5
    self.MAX_RECONNECT_TRIES = 1
    self.RECONNECT_TRIES = 0
    self.socket = nil
    self.rxBuf = ''
    self.currTime = 0
    self.lastTime = 0
    print("called AP:init", 2)
    -- Isaac mod ref
    self.MOD_REF = RegisterMod("AP", 1)
    self.AP_ITEM_ID = Isaac.GetItemIdByName("AP Item")
    self.modConfigMenuInit()
    self:loadConnectionInfo()
    self:loadSettings()
    -- mod callbacks
    function self.onPostGameStarted(mod, isContinued)
        print('self.onPostGameStarted')
        self.IS_CONTINUED = isContinued
        self.RECONNECT_TRIES = 0
        self.TRAP_QUEUE = {}
        self.TRAP_QUEUE_TIMER = 150
        self.STATE_MACHINE:set_state(AP.STATE_CONNECTING)
    end
    function self.onPostRender(mod)
        self.STATE_MACHINE:tick()
        self:showPermanentMessage()
        self:showMessages()
        if self.DEBUG_MODE then
            self:showDebugInfo()
        end
        self:proceedPickupTimer()
        self:advanceItemQueue()
        self:advanceTrapQueue()
        self:advanceSpawnQueue()
        if WAIT_TYPING_ENTER_EXIT > 0 then
            WAIT_TYPING_ENTER_EXIT = WAIT_TYPING_ENTER_EXIT - 1
        end
    end
    function self.onPreGameExit(mod, shouldSave)
        self.ITEM_QUEUE = {}
        self.TRAP_QUEUE = {}
        self.SPAWN_QUEUE = {}
        if shouldSave then
            local seed = ""
            if self.CONNECTION_INFO and self.CONNECTION_INFO.slot_data then
                seed = self.CONNECTION_INFO.slot_data.seed
            end
            self:saveOtherData(seed)
        end
        self:shutdown()
    end
    function self.onPrePickupCollision(mod, pickup, collider, low)
        local totalLocations = self.CONNECTION_INFO.slot_data["totalLocations"]
        local checkedLocations = #self.CHECKED_LOCATIONS
        local collectableIndex = getCollectableIndex(pickup)
        if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE or collider.Type ~= EntityType.ENTITY_PLAYER or
            checkedLocations >= totalLocations or pickup.Touched -- used to not make AP spawned item collectable until rerolled
        or pickup.SubType == CollectibleType.COLLECTIBLE_POLAROID or pickup.SubType ==
            CollectibleType.COLLECTIBLE_NEGATIVE or pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_1 or
            pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_2 or pickup.SubType ==
            CollectibleType.COLLECTIBLE_DADS_NOTE or pickup.SubType == CollectibleType.COLLECTIBLE_KNIFE_PIECE_1 or
            pickup.SubType == CollectibleType.COLLECTIBLE_KNIFE_PIECE_2 -- check for special items: polaroid/negative or key/knife pieces or dad's note
        or pickup.SubType == CollectibleType.COLLECTIBLE_NULL -- might get called when bumping in a already collected collectable
        then
            return
        end
        -- check timer
        if self.PICKUP_TIMER and self.PICKUP_TIMER > 0 then
            return false
        end
        local player = collider:ToPlayer()        
        local room = Game():GetRoom()
         -- check if we can buy this, if shop item
         if pickup:IsShopItem() then
            if pickup.Price > 0 then
                if pickup.Price > collider:ToPlayer():GetNumCoins() then
                    return
                end
                -- 1 or 2 hearts deal
            elseif pickup.Price > -3 then
                if pickup.Price * -2 > player:GetMaxHearts() and not player:WillPlayerRevive() then
                    return
                end
                -- 3 soul hearts deal
            elseif pickup.Price == -3 then
                if pickup.Price * -2 > player:GetSoulHearts() and not player:WillPlayerRevive() then
                    return
                end
                -- 1 heart/2 soul hearts deal
            elseif pickup.Price == -4 then
                if (player:GetMaxHearts() < 2 or player:GetSoulHearts() < 4) and not player:WillPlayerRevive() then
                    return
                end
            end
        end
        -- check for boss rush 1st item, since we can't seem to start the boss rush otherwise
        --if room:GetType() == RoomType.ROOM_BOSSRUSH and not room:IsAmbushDone() then
            --return
        --end
        -- mod:RemoveCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, self.onPrePickupCollision)
        self.PICKUP_TIMER = 90
        if player:CanPickupItem() and pickup.Wait <= 0 and pickup.SubType ~= self.AP_ITEM_ID then
            -- print("onPrePickupCollision", pickup.Wait, pickup.State)
            local item_step = self.CONNECTION_INFO.slot_data["itemPickupStep"]
            self.CUR_ITEM_STEP_VAL = self.CUR_ITEM_STEP_VAL + 1            
            print('item is potential AP item', item_step, self.CUR_ITEM_STEP_VAL, #self.MISSING_LOCATIONS,
                pickup.SubType, pickup.State)
            if self.CUR_ITEM_STEP_VAL == item_step then
                -- self:clearLocations(1)                
                self.CUR_ITEM_STEP_VAL = 0
                print("onPrePickupCollision", self.AP_ITEM_ID)
                local itemConfig = Isaac.GetItemConfig():GetCollectible(pickup.SubType)                                
                -- pickup.SubType = self.AP_ITEM_ID
                pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, self.AP_ITEM_ID, true, true,
                    true)                
                if itemConfig and itemConfig.Quality > 1 then
                    player:AnimateSad()
                else
                    player:AnimateHappy()
                end                
                -- mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, self.onPrePickupCollision)
                return false
            end
        end
        -- mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, self.onPrePickupCollision)
    end
    function self.onPostPEffectUpdate(mod, player)
        if player:HasCollectible(self.AP_ITEM_ID) then
            self:clearLocations(1)          
            player:RemoveCollectible(self.AP_ITEM_ID)
        end
    end
    function self.onPreSpawnClearAward(mod)
        local room = Game():GetRoom()
        local goal = tonumber(self.CONNECTION_INFO.slot_data["goal"])
        -- check for boss rush
        if room:GetType() == RoomType.ROOM_BOSSRUSH and room:IsAmbushDone() and room:IsClear() then
            self:clearLocations(2)
            if goal == 9 then
                self:sendGoalReached()
            end
        end
    end
    function self.onPostEntityKill(mod, entity)
        local player = entity:ToPlayer()
        --ToDo: make send DeathLink on revive a option?
        if player and self.CONNECTION_INFO.slot_data.deathLink and not player:WillPlayerRevive() then
            self:sendBlocks({self:getDeathLinkBounceCommand()})
            self:addMessage({
                parts = {{
                    msg = "[DeathLink] Sent DeathLink",
                    color = COLORS.RED
                }}
            })
        end
        local goal = tonumber(self.CONNECTION_INFO.slot_data.goal)
        local required_locations = tonumber(self.CONNECTION_INFO.slot_data.requiredLocations)
        local type = entity.Type
        -- print('called entityKill', 1, entity, type, entity.Variant, goal, required_locations, #self.CHECKED_LOCATIONS)
        local isGoalBoss = false
        for _, v in pairs(self.GOAL_BOSSES) do
            if contains(v, type) then
                isGoalBoss = true
                break
            end
        end
        if not isGoalBoss then
            return
        end
        local level = Game():GetLevel()
        -- don't send out rewards/goal for other goal bosses in The Void
        if type ~= EntityType.ENTITY_DELIRIUM and level:GetStage() == LevelStage.STAGE7 then
            return
        end
        -- lamb special handling
        if type == EntityType.ENTITY_THE_LAMB then
            if entity.Variant == 10 then
                self.LAMB_BODY_KILL = true
            else
                self.LAMB_KILL = true
            end
            if self.LAMB_BODY_KILL and self.LAMB_KILL then
                table.insert(self.KILLED_BOSSES, type)
            end
        end
        if isGoalBoss and self.CONNECTION_INFO.slot_data.additionalBossRewards then
            self:sendBossClearReward(entity)
        end
        -- we can only win if we check enough locations
        if #self.CHECKED_LOCATIONS < required_locations then
            return
        end
        local bosses = self.GOAL_BOSSES[goal]
        -- print('called entityKill', 2, dump_table(bosses), type)
        if not contains(bosses, type) then
            return
        end
        -- print('called entityKill', 3, "is goal boss", type, entity.Variant)    
        -- blue baby uses a SubType of Isaac => requries special handling
        if type == EntityType.ENTITY_ISAAC then
            if (goal == 2 or goal == 3) and entity.Variant == 0 then
                self:sendGoalReached()
            elseif (goal == 5 or goal == 6) and entity.Variant == 1 then
                self:sendGoalReached()
            end
            return
            -- phase 2 is Variant 10 and ending phase 1 counts as killing Variant 0 sometimes => requries special handling
        elseif type == EntityType.ENTITY_SATAN then
            if entity.Variant == 10 then
                self:sendGoalReached()
            end
            return
            -- the lamb uses two entities The Lamb itself + the body => requries special handling
        elseif self.LAMB_KILL and self.LAMB_BODY_KILL then
            self:sendGoalReached()
            return
            -- Dogma uses Variant == 2 for the 2nd phase
        elseif type == EntityType.ENTITY_DOGMA then
            if entity.Variant == 2 then
                self:sendGoalReached()
            end
            return
            -- Variant 0 is the final kill
        elseif type == EntityType.ENTITY_BEAST then
            if entity.Variant == 0 then
                self:sendGoalReached()
            end
            return
            -- Mother uses Variant == 10 for the 2nd phase
        elseif type == EntityType.ENTITY_MOTHER then
            if entity.Variant == 10 then
                self:sendGoalReached()
            end
            return
        else
            self:sendGoalReached()
            return
        end
    end
    --function self.onPostPickupUpdate(mod, pickup)
        ---- blame isaac devs for this
        -- if not pickup:IsShopItem() then
        --    return
        -- end
        ---- adjust prices for steam sale     
        -- local steamSaleCount = 0
        -- local playerNum = Game():GetNumPlayers()
        -- for i = 0, playerNum - 1 do
        --    local player = Game():GetPlayer(i)
        --    if player:HasCollectible(CollectibleType.COLLECTIBLE_STEAM_SALE) then
        --        steamSaleCount = steamSaleCount + player:GetCollectibleNum(CollectibleType.COLLECTIBLE_STEAM_SALE)
        --    end
        -- end
        -- if steamSaleCount ~= self.HAD_STEAM_SALE_COUNT then
        --    for k, v in pairs(self.PRICE_TABLE) do
        --        self.PRICE_TABLE[k] = v * (self.HAD_STEAM_SALE_COUNT + 1) / (steamSaleCount + 1)
        --    end
        --    self.HAD_STEAM_SALE_COUNT = steamSaleCount
        -- end
        ---- blame isaac devs for this
        -- local collectableIndex = getCollectableIndex(pickup)
        -- print("onPostPickupUpdate", 1, collectableIndex, pickup.Price)
        -- if self.PRICE_TABLE[collectableIndex] then
        --    pickup.AutoUpdatePrice = false
        --    pickup.Price = math.round(self.PRICE_TABLE[collectableIndex])
        -- end
    --end
    function self.onEntityTakeDmg(mod, entity, amount, flags, source, dmgCountdown)
        local player = entity:ToPlayer()
        if not player or flags & 1 == 1 or flags & 2097152 == 2097152 then
            return
        end
        print("onEntityTakeDmg", player.Type, player.Variant, player.SubType, player:GetPlayerType(),
            player:GetOtherTwin(), player:GetSubPlayer(), player:IsSubPlayer())
        local health = player:GetHearts() + player:GetSoulHearts()
        if health - amount <= 0 then

        end
    end
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, self.onPostGameStarted)
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_RENDER, self.onPostRender)
    self.MOD_REF:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, self.onPreGameExit)
    self.MOD_REF:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, self.onPrePickupCollision)
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, self.onPostPEffectUpdate)
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, self.onPostEntityKill)
    self.MOD_REF:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, self.onPreSpawnClearAward)
    -- self.MOD_REF:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, self.onPostPickupUpdate)
    self.MOD_REF:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, self.onEntityTakeDmg)
    self.MOD_REF:AddCallback(ModCallbacks.MC_INPUT_ACTION, self.trackTypingInput)
    print("called AP:init", 3)
    -- global Isaac info
    self.IS_CONTINUED = false
    self.HAS_SEND_GOAL_MSG = false
    -- -- goal related
    self.GOAL_BOSSES = {
        [0] = {EntityType.ENTITY_MOM}, -- TESTED (alt mom still to be tested)
        [1] = {EntityType.ENTITY_MOMS_HEART}, -- TESTED
        [2] = {EntityType.ENTITY_ISAAC, EntityType.ENTITY_SATAN}, -- TESTED
        [3] = {EntityType.ENTITY_ISAAC}, -- TESTED
        [4] = {EntityType.ENTITY_SATAN}, -- TESTED
        [5] = {EntityType.ENTITY_ISAAC, EntityType.ENTITY_THE_LAMB}, -- blue baby uses a SubType of Isaac => requries special handling
        [6] = {EntityType.ENTITY_ISAAC}, -- blue baby uses a SubType of Isaac => requries special handling; TESTED
        [7] = {EntityType.ENTITY_THE_LAMB}, -- the lamb uses two entities The Lamb itself + the body => requries special handling -- TESTED
        [8] = {EntityType.ENTITY_MEGA_SATAN_2},
        -- [9] = {}, --boss rush requries special handling -- TESTED
        [10] = {EntityType.ENTITY_HUSH}, -- TESTED
        [11] = {EntityType.ENTITY_DOGMA}, -- TESTED
        [12] = {EntityType.ENTITY_BEAST}, -- TESTED
        [13] = {EntityType.ENTITY_MOTHER}, -- TESTED
        [14] = {EntityType.ENTITY_DELIRIUM}, -- TESTED
        [15] = {}
    }
    self.GOAL_NAMES = {
        [0] = "Mom",
        [1] = "Mom's Heart",
        [2] = "Isaac/Satan",
        [3] = "Isaac",
        [4] = "Satan",
        [5] = "???/The Lamb",
        [6] = "???",
        [7] = "The Lamb",
        [8] = "Mega Satan",
        [9] = "Boss Rush",
        [10] = "Hush",
        [11] = "Dogma",
        [12] = "The Beast",
        [13] = "Mother",
        [14] = "Delirium",
        [15] = "Required locations"
    }
    self.LAMB_KILL = false
    self.LAMB_BODY_KILL = false
    self.KILLED_BOSSES = {}
    -- -- restock fix related
    self.REROLL_COUNTS = {}
    self.PICKUP_TIMER = 0
    self.PRICE_TABLE = {}
    self.HAD_STEAM_SALE_COUNT = 0
    -- global AP info
    self.LAST_RECEIVED_ITEM_INDEX = -1
    self.CUR_ITEM_STEP_VAL = 0
    self.MISSING_LOCATIONS = {}
    self.CHECKED_LOCATIONS = {}
    self.GAME_DATA = nil
    self:loadGameData()
    self.CONNECTION_INFO = nil
    self.ROOM_INFO = nil
    self.MESSAGE_QUEUE = {}
    self.ITEM_QUEUE = {}
    self.ITEM_QUEUE_TIMER = 0
    self.TRAP_QUEUE = {}
    self.TRAP_QUEUE_TIMER = 0
    self.SPAWN_QUEUE = {}
    self.SPAWN_QUEUE_TIMER = 0
    self.DEATH_CAUSE = "unknown"
    self.LAST_DEATH_LINK_TIME = nil
    self.LAST_DEATH_LINK_RECV = nil -- ToDo: Implement?
    print("called AP:init", 4, "end")
end

-- AP Commands
function AP:getConnectCommand()
    return {
        cmd = "Connect",
        game = self.GAME_NAME,
        name = self.SLOT_NAME,
        password = self.PASSWORD,
        uuid = "1",
        version = {
            major = self.MAJOR_VERSION,
            minor = self.MINOR_VERSION,
            build = self.BUILD_VERSION,
            class = "Version"
        },
        items_handling = 7, -- gimme all the items
        tags = {}
    }
end
function AP:getDataPackageCommand()
    return {
        cmd = "GetDataPackage",
        games = self.OUTDATED_GAMES
    }
end
function AP:getGoalReachedCommand()
    return {
        cmd = "StatusUpdate",
        status = 30 -- CLIENT_GOAL
    }
end
function AP:getLocationCollectedCommand(ids)
    return {
        cmd = "LocationChecks",
        locations = ids
    }
end
function AP:getDeathLinkBounceCommand(cause, source)
    cause = cause or AP.GAME_NAME
    source = source or self.SLOT_NAME -- ToDo: append player number
    local time = socket.gettime()
    self.LAST_DEATH_LINK_TIME = time
    -- print("AP:getDeathLinkBounceCommand", time, self.LAST_DEATH_LINK_TIME)
    return {
        cmd = "Bounce",
        tags = {"DeathLink"},
        data = {
            time = time,
            cause = cause,
            source = source
        }
    }
end
function AP:getUpdateConnectionTagsCommand(tags)
    tags = tags or {}
    return {
        cmd = "ConnectUpdate",
        tags = tags
    }
end
-- AP END Commands

-- AP util funcs
function AP:generateCollectableItemImpls(startIdx)
    for i = 0, CollectibleType.NUM_COLLECTIBLES - 2 do
        AP.ITEM_IMPLS[startIdx + i] = function(ap)
            ap:spawnCollectible(i + 1)
            -- print(i + 1)
        end
    end
end
function AP:clearLocations(amount)
    amount = amount or 1
    local i = 0
    local ids = {}
    print("clearLocations", 1, i, amount, #self.MISSING_LOCATIONS)
    while i < amount and #self.MISSING_LOCATIONS > 0 do
        local id = self.MISSING_LOCATIONS[1]
        table.insert(ids, id)
        table.remove(self.MISSING_LOCATIONS, 1)
        table.insert(self.CHECKED_LOCATIONS, id)
        i = i + 1
    end
    self:sendBlocks({self:getLocationCollectedCommand(ids)})
end
function AP:sendBossClearReward(entity)
    local type = entity.Type
    local variant = entity.Variant

    if type == EntityType.ENTITY_MOM and variant == 10 then
        self:clearLocations(1)
    elseif type == EntityType.ENTITY_MOMS_HEART and variant == 10 then
        -- boss rush is handled via onPreSpawnClearAward
        self:clearLocations(2)
    elseif (type == EntityType.ENTITY_ISAAC and variant == 0) or
        (type == EntityType.ENTITY_SATAN and variant == 10 and not self.SATAN_KILL) or type == EntityType.ENTITY_HUSH then
        self:clearLocations(3)
        if type == EntityType.ENTITY_SATAN then
            self.SATAN_KILL = true -- dies twice
        end
    elseif (type == EntityType.ENTITY_ISAAC and variant == 1) or
        (type == EntityType.ENTITY_THE_LAMB and self.LAMB_KILL and self.LAMB_BODY_KILL) then
        self:clearLocations(4)
    elseif type == EntityType.ENTITY_MEGA_SATAN_2 or type == EntityType.ENTITY_DELIRIUM or
        (type == EntityType.ENTITY_MOTHER and variant == 10) or (type == EntityType.ENTITY_BEAST and variant == 0) then
        self:clearLocations(5)
    elseif type == EntityType.ENTITY_DOGMA then
        -- do nothing   
    else
        print("!!! tried to send clear reward for unknown goal boss !!!")
    end
end
function AP:resolveIdToName(typeStr, id)
    if string.find(typeStr, "location") then
        if type(id) == "string" then
            id = tonumber(id)
        end
        return self.GAME_DATA.location_id_to_name[id]
    elseif string.find(typeStr, "item") then
        if type(id) == "string" then
            id = tonumber(id)
        end
        return self.GAME_DATA.item_id_to_name[id]
    elseif string.find(typeStr, "player") then
        return self.CONNECTION_INFO.slot_info[id].name -- ToDo: alias via players?
    else
        print('!!! can to resolve Id to Name of unknown type !!!', typeStr)
        return id
    end
end
function AP:collectItem(item)
    local id = item.item
    local roomDesc = Game():GetLevel():GetCurrentRoomDesc().Data
    if roomDesc.Name == "Beast Room" then -- dont receive item in the beast room
        return
    end
    if AP.USE_ITEM_QUEUE then
        self:addToItemQueue(id)
    else
        local item_impl = AP.ITEM_IMPLS[id]
        if item_impl == nil or type(item_impl) ~= 'function' then
            print("!!! received unknown item id  !!!", id)
            return
        end
        item_impl(self)
    end
end
function AP:addToSpawnQueue(type, variant, subType, timeToNextSpawn)
    table.insert(self.SPAWN_QUEUE, {
        type = type,
        variant = variant,
        subType = subType,
        timeToNextSpawn = timeToNextSpawn
    })
end
function AP:addToTrapQueue(trapId)
    self.TRAP_QUEUE_TIMER = 30
    table.insert(self.TRAP_QUEUE, trapId)
end
function AP:advanceSpawnQueue()
    if self.SPAWN_QUEUE_TIMER > 0 then
        self.SPAWN_QUEUE_TIMER = self.SPAWN_QUEUE_TIMER - 1
        return
    end
    if #self.SPAWN_QUEUE < 1 then
        return
    end
    local item = self.SPAWN_QUEUE[1]
    table.remove(self.SPAWN_QUEUE, 1)
    self.SPAWN_QUEUE_TIMER = item.timeToNextSpawn
    local room = Game():GetRoom()
    local pos = room:FindFreeTilePosition(room:GetRandomPosition(1), 5)
    Isaac.Spawn(item.type, item.variant, item.subType, pos, Vector(0, 0), nil)
end
function AP:advanceItemQueue()
    if self.ITEM_QUEUE_TIMER > 0 then
        self.ITEM_QUEUE_TIMER = self.ITEM_QUEUE_TIMER - 1
        return
    end
    if #self.ITEM_QUEUE < 1 then
        return
    end
    local id = self.ITEM_QUEUE[1]
    table.remove(self.ITEM_QUEUE, 1)
    self.ITEM_QUEUE_TIMER = 10
    local item_impl = AP.ITEM_IMPLS[id]
    if item_impl == nil or type(item_impl) ~= 'function' then
        print("!!! received unknown item id  !!!", id)
        return
    end
    item_impl(self)
end
function AP:addToItemQueue(item, pos)
    pos = pos or #self.ITEM_QUEUE + 1
    table.insert(self.ITEM_QUEUE, pos, item)
end
function AP:advanceTrapQueue()
    if self.TRAP_QUEUE_TIMER > 0 then
        self.TRAP_QUEUE_TIMER = self.TRAP_QUEUE_TIMER - 1
        return
    end
    if #self.TRAP_QUEUE < 1 then
        return
    end
    local id = self.TRAP_QUEUE[1]
    table.remove(self.TRAP_QUEUE, 1)
    self.TRAP_QUEUE_TIMER = 30
    local trap_impl = AP.TRAP_IMPLS[id]
    if trap_impl == nil or type(trap_impl) ~= 'function' then
        print("!!! received unknown trap id  !!!", id)
        return
    end
    trap_impl(self)
end
function AP:spawnCollectible(item)
    local player = Game():GetNearestPlayer(Isaac.GetRandomPosition())
    local item_config = Isaac:GetItemConfig():GetCollectible(item)
    if item_config.Type ~= ItemType.ITEM_ACTIVE or player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == 0 then
        player:QueueItem(item_config) -- FixMe: transformations cause graphical glitches sometimes
        player:FlushQueueItem()
    else
        local room = Game():GetRoom()
        local num = 1
        local startPos = room:GetClampedPosition(Vector(player.Position.X, player.Position.Y - 1), 0)
        local pos = room:FindFreePickupSpawnPosition(startPos, num, true, false)
        -- print("AP:spawnCollectible", "before loop", pos, num, item)
        while not checkPos(pos, player) and num < 500 do
            num = num + 1
            pos = room:FindFreePickupSpawnPosition(startPos, num, true, false)
            -- print("AP:spawnCollectible", "in loop", pos, num)
        end
        -- print("AP:spawnCollectible", "after loop", pos, num)
        local entity = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item, pos, Vector(0, 0),
            nil)
        -- used to not make AP spawned item collectable until rerolled
        entity:ToPickup().Touched = true
    end
end
function AP:spawnRandomCollectibleFromPool(pool)
    local item = Game():GetItemPool():GetCollectible(pool, true)
    self:spawnCollectible(item)
end
function AP:spawnRandomPickup()
    self:spawnRandomPickupByType(PICKUP_TYPES[self.RNG:RandomInt(#PICKUP_TYPES - 1) + 1])
end
function AP:spawnRandomChest()
    self:spawnRandomPickupByType(CHEST_TYPES[self.RNG:RandomInt(#CHEST_TYPES - 1) + 1])
end
function AP:spawnRandomPickupByType(type, subtype)
    if not subtype then
        subtype = 0
    end
    local player = Game():GetNearestPlayer(Isaac.GetRandomPosition())
    local room = Game():GetRoom()
    local num = 1
    local pos = room:FindFreePickupSpawnPosition(player.Position, num, true, false)
    -- print("AP:spawnRandomPickupByType", "before loop", pos, num, subtype)
    while not checkPos(pos, player) and num < 100 do
        num = num + 1
        pos = room:FindFreePickupSpawnPosition(player.Position, num, true, false)
        -- print("AP:spawnRandomPickupByType", "in loop", pos, num, subtype)
    end
    -- print("AP:spawnRandomPickupByType", "after loop", pos, num, subtype)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, type, subtype, pos, Vector(0, 0), nil)
end
-- END AP util funcs

function AP:DebugString(...)
    local string = ""
    for i, v in ipairs(arg) do
        string = string .. tostring(v)
        if i ~= #arg then
            string = string .. '\t'
        end
    end
    Isaac.DebugString(string)
end

-- AP connection handling
function AP:processBlock(data)
    local blocks = json.decode(data)
    if blocks == nil then
        print("!!!! invalid CONTENT @ processBlock !!!!", data)
        return
    end
    -- print("processBlock: ", dump_table(blocks))
    for _, block in ipairs(blocks) do
        local cmd = block.cmd
        print('processing block', cmd)
        if cmd == "ReceivedItems" then
            if block.index > self.LAST_RECEIVED_ITEM_INDEX then
                self.LAST_RECEIVED_ITEM_INDEX = block.index
                for _, item in ipairs(block.items) do
                    self:collectItem(item)
                end
            end
        elseif cmd == "Bounced" then
            -- print(dump_table(block))
            if block.tags and contains(block.tags, "DeathLink") and block.data then
                -- print(self.LAST_DEATH_LINK_TIME, block.data.time)
                if self.LAST_DEATH_LINK_TIME ~= nil and tostring(self.LAST_DEATH_LINK_TIME) == tostring(block.data.time) then
                    -- our own package -> Do nothing
                else
                    local player = Game():GetNearestPlayer(Isaac.GetRandomPosition())
                    player:Die()
                    local cause = block.data.cause or "unknown"
                    local source = block.data.source or "unknown"
                    self:addMessage({
                        parts = {{
                            msg = "[DeathLink] Killed by " .. source .. ". Reason: " .. cause,
                            color = COLORS.RED
                        }}
                    })
                    self.LAST_DEATH_LINK_RECV = block.data.time
                end
            end
        elseif cmd == "ConnectionRefused" then
            local errsMsgs = ""
            if block.errors then
                errsMsgs = " Reason(s): "
                for i, v in ipairs(block.errors) do
                    errsMsgs = errsMsgs .. v
                    if i ~= #block.errors then
                        errsMsgs = errsMsgs .. ", "
                    end
                end
            end
            print("Connection refused by AP Server." .. errsMsgs)
            self:addMessage({
                parts = {{
                    msg = "Connection refused by AP Server." .. errsMsgs,
                    color = COLORS.RED
                }}
            })
            self.RECONNECT_TRIES = self.RECONNECT_TRIES + 1
            self:reconnect()
        elseif cmd == "PrintJSON" then
            local msg = {
                parts = {}
            }
            for _, v in ipairs(block.data) do
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
                    text = self:resolveIdToName(v.type, v.text)
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
                    text = self:resolveIdToName(v.type, v.text)
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
        elseif cmd == "Print" then
            self:addMessage(block.text)
        elseif cmd == "Connected" then
            self.RECONNECT_TRIES = 0
            self.HAS_SEND_GOAL_MSG = false
            self.LAMB_KILL = false
            self.LAMB_BODY_KILL = false
            self.SATAN_KILL = false
            self.ITEM_QUEUE = {}
            self.TRAP_QUEUE = {}
            self.TRAP_QUEUE_TIMER = 150
            -- print("Connected", 1, dump_table(block))
            self.CONNECTION_INFO = block
            -- print("Connected", 2, dump_table(self.CONNECTION_INFO))
            if self.CONNECTION_INFO.slot_data.deathLink then
                self:sendBlocks({self:getUpdateConnectionTagsCommand({"DeathLink"})})
            end
            self.MISSING_LOCATIONS = block.missing_locations
            self.CHECKED_LOCATIONS = block.checked_locations
            local required_locations = tonumber(self.CONNECTION_INFO.slot_data["requiredLocations"])
            local goal = tonumber(self.CONNECTION_INFO.slot_data["goal"])
            if required_locations and goal and #self.CHECKED_LOCATIONS >= required_locations then
                if not self.HAS_SEND_GOAL_MSG then
                    self:addMessage({
                        parts = {{
                            msg = "You have collected enough items to beat the game. Goal: " .. self:goalIdToName(goal),
                            color = COLORS.GREEN
                        }}
                    })
                    self.HAS_SEND_GOAL_MSG = true
                end
                if goal == 15 then
                    self:sendGoalReached()
                end
            end
            if self.IS_CONTINUED then
                if not self:loadOtherData(self.CONNECTION_INFO.slot_data["seed"]) then
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
                self.PRICE_TABLE = {}
                self.REROLL_COUNTS = {}
                self.HAD_STEAM_SALE_COUNT = 0
                self:saveOtherData("")
            end
        elseif cmd == "RoomInfo" then
            -- print('!!! got RoomInfo !!!')
            self.ROOM_INFO = block
            local games = self.ROOM_INFO.games
            table.insert(games, "Archipelago")
            self.OUTDATED_GAMES = deepcopy(games)
            for _, v in pairs(games) do
                if self.GAME_DATA and self.GAME_DATA.games and self.GAME_DATA.games[v] and
                    self.GAME_DATA.games[v].version then
                    if self.GAME_DATA.games[v].version == self.ROOM_INFO.datapackage_versions[v] then
                        table.remove(self.OUTDATED_GAMES, findIndex(self.OUTDATED_GAMES, v))
                    end
                end
            end
            if #self.OUTDATED_GAMES > 0 then
                self.STATE_MACHINE:set_state(AP.STATE_DATAPACKAGE)
            else
                self.STATE_MACHINE:set_state(AP.STATE_CONNECTED)
            end
        elseif cmd == "InvalidPacket" then
            print("!!! got InvalidPacket !!!", dump_table(block))
        elseif cmd == "Retrieved" then
            print("!!! got Retrieved !!!", dump_table(block))
        elseif cmd == "RoomUpdate" then
            if block.missing_location then
                for _, v in ipairs(block.missing_location) do
                    if not contains(self.MISSING_LOCATIONS, v) then
                        table.insert(self.MISSING_LOCATIONS, v)
                    end
                    local index = findIndex(self.HECKED_LOCATIONS, v)
                    if index ~= nil then
                        table.remove(self.CHECKED_LOCATIONS, index)
                    end
                end
            end
            if block.checked_locations then
                for _, v in ipairs(block.checked_locations) do
                    if not contains(self.CHECKED_LOCATIONS, v) then
                        table.insert(self.CHECKED_LOCATIONS, v)
                    end
                    local index = findIndex(self.MISSING_LOCATIONS, v)
                    if index ~= nil then
                        table.remove(self.MISSING_LOCATIONS, index)
                    end
                end
                local required_locations = tonumber(self.CONNECTION_INFO.slot_data["requiredLocations"])
                local goal = tonumber(self.CONNECTION_INFO.slot_data["goal"])
                if required_locations and goal and #self.CHECKED_LOCATIONS >= required_locations then
                    if not self.HAS_SEND_GOAL_MSG then
                        self:addMessage({
                            parts = {{
                                msg = "You have collected enough items to beat the game. Goal: " ..
                                    self:goalIdToName(goal),
                                color = COLORS.GREEN
                            }}
                        })
                        self.HAS_SEND_GOAL_MSG = true
                    end
                    if goal == 15 then
                        self:sendGoalReached()
                    end
                end
            end
        elseif cmd == "DataPackage" then
            if self.GAME_DATA == nil then
                self.GAME_DATA = {}
            end
            if self.GAME_DATA.games == nil then
                self.GAME_DATA.games = {}
            end
            for k, v in pairs(block.data.games) do
                self.GAME_DATA.games[k] = block.data.games[k]
            end
            self:adjustGameData()
            self:saveGameData()
            self.STATE_MACHINE:set_state(AP.STATE_CONNECTED)
        else
            print("! dropping packet: unhandled cmd " .. cmd .. " !")
        end
    end
end
function AP:adjustGameData()
    if self.GAME_DATA == nil then
        return
    end
    if self.GAME_DATA.games == nil and tablelength(self.GAME_DATA.games) > 0 then
        return
    end
    self.GAME_DATA.item_id_to_name = {}
    self.GAME_DATA.location_id_to_name = {}
    self.GAME_DATA.item_name_to_id = {}
    self.GAME_DATA.location_name_to_id = {}
    for k, v in pairs(self.GAME_DATA.games) do
        v.item_id_to_name = {}
        v.location_id_to_name = {}
        for k2, v2 in pairs(v.item_name_to_id) do
            self.GAME_DATA.item_name_to_id[k2] = v2
            self.GAME_DATA.item_id_to_name[v2] = k2
            v.item_id_to_name[v2] = k2
        end
        for k2, v2 in pairs(v.location_name_to_id) do
            self.GAME_DATA.location_name_to_id[k2] = v2
            self.GAME_DATA.location_id_to_name[v2] = k2
            v.location_id_to_name[v2] = k2
        end
    end
end
function AP:processHandshake(data)
    -- print('processHandshake: ', data)
    self.STATE_MACHINE:set_state(AP.STATE_ROOMINFO)
end
function AP:sendBlocks(blocks)
    local data = json.encode(blocks) .. "\r\n"
    -- print('send', data)
    local encoded = frame.encode(data, frame.TEXT, true)
    local ret, err = self.socket:sock_send(encoded)
    if err ~= nil and err ~= 'timeout' then
        print('Connection lost:', err)
        self:reconnect()
    end
end
function AP:receiveHandshake()
    local start = socket.gettime()
    local data, err = self.socket:sock_receive(1)
    if data ~= nil then
        self.rxBuf = self.rxBuf .. data
        while true do
            data, err = self.socket:sock_receive(1)
            if err ~= nil and err ~= 'timeout' then
                print('Connection lost:', err)
                self.rxBuf = ''
                self:reconnect()
                return
            end
            if data ~= nil then
                self.rxBuf = self.rxBuf .. data
            end
            -- print('AP:receiveHandshake', self.rxBuf)        
            if #self.rxBuf > 4 and string.sub(self.rxBuf, -4) == "\r\n\r\n" then
                local result = self.rxBuf
                self.rxBuf = ''
                -- print('received data', result)                
                self:processHandshake(result)
                return
            end
        end
    end
end
function AP:receiveBlock()
    local n = self.expected_bytes or 1
    while true do
        local data, err, partial = self.socket:sock_receive(n)
        data = data or partial
        -- print('AP:receiveBlock', 0, data, partial, not partial or #partial, err)
        if err == "timeout" then
            if partial then
                self.rxBuf = self.rxBuf .. partial
                self.expected_bytes = n - #partial
            end
            return nil
        end
        if data == nil then
            self:reconnect()
            self.rxBuf = ''
            self.expected_bytes = 1
            return nil
        end
        self.rxBuf = self.rxBuf .. data
        -- print('AP:receiveBlock', 1, self.rxBuf, #self.rxBuf, n, data == nil, string.byte(data))
        local decoded, fin, opcode, rest, mask = frame.decode(self.rxBuf)
        -- print('AP:receiveBlock', 2, decoded, fin, opcode, rest, mask)
        if decoded ~= nil then
            self.socket:set_timeout(0)
            -- print('received data')
            self.rxBuf = ''
            self.expected_bytes = 1
            return decoded
        else
            -- print('AP:receiveBlock', 3, toint(fin), n)
            n = math.floor(fin)
            self.expected_bytes = n
        end
    end
end
function AP:receive()
    local block = self:receiveBlock()
    if block ~= nil then
        self:processBlock(block)
    end
end
function AP:connect()
    if self.STATE_MACHINE:get_state() ~= AP.STATE_EXIT then
        self:shutdown()
    end
    self:reconnect()
end
function AP:reconnect()
    -- if self.STATE_MACHINE:get_state() ~= AP.STATE_EXIT then
    -- self:loadConnectionInfo()
    -- self.RECONNECT_TRIES = 0
    self.STATE_MACHINE:set_state(AP.STATE_CONNECTING)
    -- end
end
function AP:disconnect()
    self.CONNECTION_INFO = nil
    self.ROOM_INFO = nil
    self.LAMB_KILL = false
    self.LAMB_BODY_KILL = false
    self.HAS_SEND_GOAL_MSG = false
    if self.socket then
        self.socket:sock_close()
        self.socket = nil
    end
end
function AP:shutdown()
    self.STATE_MACHINE:set_state(AP.STATE_EXIT)
end
-- END AP connection handling

-- AP message printing
function AP:addMessage(msg)
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
    local lineHeight = 10*self.INFO_TEXT_SCALE;    
    Isaac.RenderScaledText("CURRENT_TYPING_STRING: " .. CURRENT_TYPING_STRING, 100, 0, self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    local unlocktext = "false"
    if UNLOCK_TYPING then
        unlocktext = "true"
    end
    Isaac.RenderScaledText("UNLOCK_TYPING: " .. unlocktext, 100, lineHeight, self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    Isaac.RenderScaledText("LAST_PRESSED: " .. LAST_PRESSED.controller .. ", " .. LAST_PRESSED.action, 100, lineHeight*2, self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255,
        0, 0, 1)
    local toggletext = "false"
    if TOGGLE_LOWERCASE then
        toggletext = "true"
    end
    Isaac.RenderScaledText("TOGGLE_LOWERCASE: " .. toggletext, 100, lineHeight*3, self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    Isaac.RenderScaledText("RECONNECT_TRIES: " .. self.RECONNECT_TRIES, 100, lineHeight*4, self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    Isaac.RenderScaledText("WAIT_TYPING_ENTER_EXIT: " .. WAIT_TYPING_ENTER_EXIT, 100, lineHeight*5, self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    Isaac.RenderScaledText("#TRAP_QUEUE: " .. #self.TRAP_QUEUE, 100, lineHeight*6, self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    Isaac.RenderScaledText("TRAP_QUEUE_TIMER: " .. self.TRAP_QUEUE_TIMER, 100, lineHeight*7, self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)       
    Isaac.RenderScaledText("PICKUP_TIMER: " .. self.PICKUP_TIMER, 100, lineHeight*9, self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)       
    
   
end
-- END AP message printing

-- mod callback util funcs
function AP:showPermanentMessage()
    local state = self.STATE_MACHINE:get_state()
    if state == nil then
        state = "! UNKNOWN STATE !"
    end
    local text = "AP: " .. state
    if state == AP.STATE_EXIT then
        Isaac.RenderScaledText(text, self.HUD_OFFSET, 260 - 10 * 5 * self.INFO_TEXT_SCALE - self.HUD_OFFSET,
            self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 0, 0, 1)
    elseif state == AP.STATE_CONNECTED then
        Isaac.RenderScaledText(text, self.HUD_OFFSET, 260 - 10 * 5 * self.INFO_TEXT_SCALE - self.HUD_OFFSET,
            self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 0, 255, 0, 1)
        if self.CONNECTION_INFO then
            local text2 = string.format("%s/%s checked (need %s); next check: %s/%s; goal: %s", #self.CHECKED_LOCATIONS,
                self.CONNECTION_INFO.slot_data.totalLocations, self.CONNECTION_INFO.slot_data.requiredLocations,
                self.CUR_ITEM_STEP_VAL, self.CONNECTION_INFO.slot_data.itemPickupStep,
                self:goalIdToName(self.CONNECTION_INFO.slot_data.goal))
            Isaac.RenderScaledText(text2, self.HUD_OFFSET, 260 - 10 * 4 * self.INFO_TEXT_SCALE - self.HUD_OFFSET,
                self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 255, 255, 1)
        end
    else
        Isaac.RenderScaledText(text, self.HUD_OFFSET, 260 - 10 * 5 * self.INFO_TEXT_SCALE - self.HUD_OFFSET,
            self.INFO_TEXT_SCALE, self.INFO_TEXT_SCALE, 255, 255, 255, 1)
    end
end
function AP:proceedPickupTimer()    
    if self.PICKUP_TIMER > 0 then
        self.PICKUP_TIMER = self.PICKUP_TIMER - 1
    end
end
function AP:sendGoalReached()
    self:sendBlocks({self:getGoalReachedCommand()})
end
function AP:goalIdToName(goal)
    return self.GOAL_NAMES[goal]
end
function AP:isGoalBoss(type)
    for _, v in pairs(self.GOAL_BOSSES) do
        for i, v2 in ipairs(v) do
            if v2 == type then
                return true
            end
        end
    end
    return false
end
function AP:saveConnectionInfo()
    local modData = {}
    if self.MOD_REF:HasData() then
        modData = json.decode(self.MOD_REF:LoadData())
    end
    modData.HOST_ADDRESS = self.HOST_ADDRESS
    modData.HOST_PORT = self.HOST_PORT
    modData.SLOT_NAME = self.SLOT_NAME
    modData.PASSWORD = self.PASSWORD
    self.MOD_REF:SaveData(json.encode(modData))
end
function AP:loadConnectionInfo()
    if self.MOD_REF:HasData() then
        local modData = json.decode(self.MOD_REF:LoadData())
        if modData ~= nil and modData.HOST_ADDRESS ~= nil and modData.HOST_PORT ~= nil and modData.PASSWORD ~= nil and
            modData.SLOT_NAME ~= nil then
            self.HOST_ADDRESS = modData.HOST_ADDRESS
            self.HOST_PORT = modData.HOST_PORT
            self.SLOT_NAME = modData.SLOT_NAME
            self.PASSWORD = modData.PASSWORD
        end
    end
end
function AP:saveSettings()
    local modData = {}
    if self.MOD_REF:HasData() then
        modData = json.decode(self.MOD_REF:LoadData())
    end
    modData.DEBUG_MODE = self.DEBUG_MODE
    modData.INFO_TEXT_SCALE = self.INFO_TEXT_SCALE
    modData.HUD_OFFSET = self.HUD_OFFSET
    self.MOD_REF:SaveData(json.encode(modData))
end
function AP:loadSettings()
    if self.MOD_REF:HasData() then
        local modData = json.decode(self.MOD_REF:LoadData())
        if modData ~= nil and modData.DEBUG_MODE ~= nil and modData.INFO_TEXT_SCALE ~= nil then
            self.DEBUG_MODE = modData.DEBUG_MODE
            self.INFO_TEXT_SCALE = modData.INFO_TEXT_SCALE
            self.HUD_OFFSET = modData.HUD_OFFSET
        end
    end
end
function AP:loadOtherData(seed)
    if self.MOD_REF:HasData() then
        local modData = json.decode(self.MOD_REF:LoadData())
        if modData ~= nil and modData.SAVED_SEED ~= nil and modData.SAVED_ITEM_INDEX ~= nil and
            modData.CUR_ITEM_STEP_VAL ~= nil and modData.REROLL_COUNTS ~= nil and modData.PRICE_TABLE ~= nil and
            modData.HAD_STEAM_SALE_COUNT ~= nil and seed == modData.SAVED_SEED then
            self.LAST_RECEIVED_ITEM_INDEX = modData.SAVED_ITEM_INDEX
            self.CUR_ITEM_STEP_VAL = modData.CUR_ITEM_STEP_VAL
            self.REROLL_COUNTS = modData.REROLL_COUNTS
            self.PRICE_TABLE = modData.PRICE_TABLE
            self.HAD_STEAM_SALE_COUNT = modData.HAD_STEAM_SALE_COUNT
        else
            return false
        end
    end
    return true
end
function AP:saveOtherData(seed)
    local modData = {}
    if self.MOD_REF:HasData() then
        modData = json.decode(self.MOD_REF:LoadData())
    end
    modData.SAVED_ITEM_INDEX = self.LAST_RECEIVED_ITEM_INDEX
    modData.SAVED_SEED = seed
    modData.CUR_ITEM_STEP_VAL = self.CUR_ITEM_STEP_VAL
    modData.PRICE_TABLE = self.PRICE_TABLE
    modData.REROLL_COUNTS = self.REROLL_COUNTS
    modData.HAD_STEAM_SALE_COUNT = self.HAD_STEAM_SALE_COUNT
    self.MOD_REF:SaveData(json.encode(modData))
end
-- AP Game data cache saving/loading
function AP:saveGameData(games)
    local file = assert(io.open("data/ap/apcache.dat", "w+"), "Could not write AP cache file")
    local encoded = json.encode(get_simple_game_data(self.GAME_DATA))
    file:write(encoded)
end

function AP:loadGameData()
    local file = assert(io.open("data/ap/apcache.dat", "r"), "Could not read AP cache file")
    local encoded = file:read("*all")
    self.GAME_DATA = json.decode(encoded)
    self:adjustGameData()
end

AP()

