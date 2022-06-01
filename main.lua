local json = require('json')
local ws_client = require('websocket.client_sync')
local tools = require('websocket.tools')
local handshake = require('websocket.handshake')
local frame = require('websocket.frame')
require('utils')
require('statemachine')

-- AP connection config
HOST_ADDRESS = "127.0.0.1"
HOST_PORT = "38281"
SLOT_NAME = "Cyb3R"

AP = class()

AP.GAME_NAME = "The Binding of Isaac Rebirth"
-- State names for stateMachine
AP.STATE_CONNECTING = "connecting"
AP.STATE_HANDSHAKE = "handshake"
AP.STATE_DATAPACKAGE = "datapackage"
AP.STATE_CONNECTED = "connected"
AP.STATE_EXIT = "exit"

AP.ITEM_IMPLS = {
    [78000] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_TREASURE)
    end,
    [78001] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_SHOP)
    end,
    [78002] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_BOSS)
    end,
    [78003] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_DEVIL)
    end,
    [78004] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_ANGEL)
    end,
    [78005] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_SECRET)
    end,
    [78006] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_LIBRARY)
    end,
    [78007] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_CURSE)
    end,
    [78008] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_PLANETARIUM)
    end,
    [78009] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_SHELL_GAME)
    end,
    [78010] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_GOLDEN_CHEST)
    end,
    [78011] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_RED_CHEST)
    end,
    [78012] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_BEGGAR)
    end,
    [78013] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_DEMON_BEGGAR)
    end,
    [78014] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_KEY_MASTER)
    end,
    [78015] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_BATTERY_BUM)
    end,
    [78016] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_MOMS_CHEST)
    end,
    [78017] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_TREASURE)
    end,
    [78018] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_BOSS)
    end,
    [78019] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_SHOP)
    end,
    [78020] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_DEVIL)
    end,
    [78021] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_ANGEL)
    end,
    [78022] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_CURSE)
    end,
    [78023] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_SECRET)
    end,
    [78024] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_CRANE_GAME)
    end,
    [78025] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_ULTRA_SECRET)
    end,
    [78026] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_BOMB_BUM)
    end,
    [78027] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_OLD_CHEST)
    end,
    [78028] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_BABY_SHOP)
    end,
    [78029] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_WOODEN_CHEST)
    end,
    [78030] = function()
        spawnRandomCollectibleFromPool(ItemPoolType.POOL_ROTTEN_BEGGAR)
    end,
    [78031] = function()
        spawnRandomPickup()
    end,
    [78032] = function()
        spawnRandomPickupByType(PickupVariant.PICKUP_HEART)
    end,
    [78033] = function()
        spawnRandomPickupByType(PickupVariant.PICKUP_COIN)
    end,
    [78034] = function()
        spawnRandomPickupByType(PickupVariant.PICKUP_BOMB)
    end,
    [78035] = function()
        spawnRandomPickupByType(PickupVariant.PICKUP_KEY)
    end,
    [78036] = function()
        spawnRandomPickupByType(PickupVariant.PICKUP_TAROTCARD)
    end,
    [78037] = function()
        spawnRandomPickupByType(PickupVariant.PICKUP_PILL)
    end,
    [78038] = function()
        spawnRandomChest()
    end,
    [78039] = function()
        spawnRandomPickupByType(PickupVariant.PICKUP_TRINKET)
    end
}

function AP:init(host_address, host_port, slot_name, password)
    print("called AP:init", 1, host_address, host_port, slot_name, password)
    -- AP client / Mod version 
    self.MAJOR_VERSION = "0"
    self.MINOR_VERSION = "1"
    self.BUILD_VERSION = "6"
    -- AP Connection info
    self.HOST_ADDRESS = host_address
    self.HOST_PORT = host_port
    self.SLOT_NAME = slot_name
    self.PASSWORD = password
    -- socket
    self.STATE_MACHINE = SimpleStateMachine()
    -- statemachine callbacks
    function self.onEnter_Connecting()
        self.LAST_RECEIVED_ITEM_INDEX = -1
    end
    function self.onTick_Connecting()
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
                print('Failed to open socket:', err)
                self.socket:sock_close()
                self.socket = nil
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
    self.STATE_MACHINE:register(AP.STATE_DATAPACKAGE, self.onEnter_Datapackage, self.onTick_Connected, nil)
    self.STATE_MACHINE:register(AP.STATE_CONNECTED, self.onEnter_Connected, self.onTick_Connected, self.onExit_Connected)
    self.STATE_MACHINE:register(AP.STATE_EXIT, self.onEnter_Exit, nil, nil)
    self.RECONNECT_INTERVAL = 3
    self.socket = nil
    self.rxBuf = ''
    self.currTime = 0
    self.lastTime = 0
    print("called AP:init", 2, self.STATE_MACHINE, self.socket)
    -- Isaac mod ref
    self.MOD_REF = RegisterMod("AP", 1)
    -- mod callbacks
    function self.onPostGameStarted(mod, isContinued)
        print("AP:onPostGameStarted", dump_table(self))
        self.IS_CONTINUED = isContinued
        self.STATE_MACHINE:set_state(AP.STATE_CONNECTING)
    end
    function self.onPostRender(mod)
        self.STATE_MACHINE:tick()
        self:showPermanentMessage()
        self:showMessages()
        self:proceedPickupTimer()
    end
    function self.onPreGameExit(mod, shouldSave)
        if shouldSave then
            local seed = ""
            if self.CONNECTION_INFO and self.CONNECTION_INFO.slot_data then
                seed = self.CONNECTION_INFO.slot_data["seed"]
            end
            mod:SaveData(json.encode({
                SAVED_ITEM_INDEX = self.LAST_RECEIVED_ITEM_INDEX,
                SAVED_SEED = seed
            }))
        end
        self:shutdown()
    end
    function self.onPrePickupCollision(mod, pickup, collider, low)
        local totalLocations = self.CONNECTION_INFO.slot_data["totalLocations"]
        local checkedLocations = #self.CHECKED_LOCATIONS
        local hash = GetPtrHash(pickup)
        if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE or collider.Type ~= EntityType.ENTITY_PLAYER or
            checkedLocations >= totalLocations -- used to not make AP spawned item collectable until rerolled
        or pickup.Touched -- check for special items: polaroid/negative or key/knife pieces or dad's note
        or pickup.SubType == CollectibleType.COLLECTIBLE_POLAROID or pickup.SubType ==
            CollectibleType.COLLECTIBLE_NEGATIVE or pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_1 or
            pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_2 or pickup.SubType ==
            CollectibleType.COLLECTIBLE_DADS_NOTE or pickup.SubType == CollectibleType.COLLECTIBLE_KNIFE_PIECE_1 or
            pickup.SubType == CollectibleType.COLLECTIBLE_KNIFE_PIECE_2 -- might get called when bumping in a already collected collectable
        or pickup.SubType == CollectibleType.COLLECTIBLE_NULL then
            return
        end
        -- check timer
        if self.PICKUP_TIMER[hash] and self.PICKUP_TIMER[hash] > 0 then
            return false
        end
        local player = collider:ToPlayer()
        -- check if we can buy this, if shop item
        if pickup:IsShopItem() then
            if pickup.Price > 0 then
                if pickup.Price > collider:ToPlayer():GetNumCoins() then
                    return
                end
                -- 1 or 2 hearts deal
            elseif pickup.Price > -3 then
                if pickup.Price * -2 > player:GetMaxHearts() then
                    return
                end
                -- 3 soul hearts deal
            elseif pickup.Price == -3 then
                if pickup.Price * -2 > player:GetSoulHearts() then
                    return
                end
                -- 1 heart/2 soul hearts deal
            elseif pickup.Price == -4 then
                if player:GetMaxHearts() < 2 or player:GetSoulHearts() < 4 then
                    return
                end
            end
        end
        local room = Game():GetRoom()
        -- check for boss rush 1st item, since we can't seem to start the boss rush otherwise
        if room:GetType() == RoomType.ROOM_BOSSRUSH and not room:IsAmbushDone() then
            return
        end
        mod:RemoveCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, self.onPrePickupCollision)
        local item_step = self.CONNECTION_INFO.slot_data["itemPickupStep"]
        self.CUR_ITEM_STEP_VAL = self.CUR_ITEM_STEP_VAL + 1
        -- print('item is potential AP item', item_step, self.CUR_ITEM_STEP_VAL, #self.MISSING_LOCATIONS, pickup.SubType)
        if self.CUR_ITEM_STEP_VAL == item_step then
            local id = self.MISSING_LOCATIONS[1]
            self:sendBlocks({self:getLocationCollectedCommand({id})})
            table.remove(self.MISSING_LOCATIONS, 1)
            table.insert(self.CHECKED_LOCATIONS, id)
            -- check for linked items and remove the other items on pickup
            if pickup.OptionsPickupIndex ~= 0 then
                local entities = room:GetEntities()
                for i = 0, #entities - 1 do
                    local entity = entities:Get(i)
                    if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and
                        entity:ToPickup().OptionsPickupIndex == pickup.OptionsPickupIndex then
                        entity:Remove()
                    end
                end
            end
            -- Shop/Devil Deal items
            if pickup:IsShopItem() then
                -- print("IsShopItem price", pickup.Price)
                if pickup.Price > 0 then
                    player:AddCoins(-1 * pickup.Price)
                    -- 1 or 2 hearts devil deal
                elseif pickup.Price > -3 then
                    player:AddMaxHearts(pickup.Price * 2)
                    -- 3 soul hearts devil deal
                elseif pickup.Price == -3 then
                    player:AddSoulHearts(pickup.Price * 2)
                    -- 1 heart/2 soul hearts devil deal
                elseif pickup.Price == -4 then
                    player:AddSoulHearts(-4)
                    player:AddMaxHearts(-2)
                end
            end
            local hasRestock = player:HasCollectible(CollectibleType.COLLECTIBLE_RESTOCK)
            -- ToDo: validate
            -- shop item handling overrides restock... looks like we need to completely rewrite that ourself :(
            if pickup:IsShopItem() and hasRestock and pickup.Price > 0 then
                local seed = Game():GetSeeds():GetStartSeed()
                local pool = Game():GetItemPool():GetPoolForRoom(room:GetType(), seed)
                local item = Game():GetItemPool():GetCollectible(pool, true)
                pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item, true)
                if not self.REROLL_COUNTS[hash] then
                    self.REROLL_COUNTS[hash] = 0
                end
                pickup.AutoUpdatePrice = false
                pickup.Price = pickup.Price + 2 + (2 * self.REROLL_COUNTS[hash])
                if pickup.Price > 99 then
                    pickup.Price = 99
                end
                self.REROLL_COUNTS[hash] = self.REROLL_COUNTS[hash] + 1
                self.PICKUP_TIMER[hash] = 200
            else
                pickup:Remove()
            end
            self.CUR_ITEM_STEP_VAL = 0
            mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, self.onPrePickupCollision)
            return false
        end
        mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, self.onPrePickupCollision)
    end
    function self.onPreSpawnClearAward(mod)
        local room = Game():GetRoom()
        local goal = tonumber(self.CONNECTION_INFO.slot_data["goal"])
        -- check for boss rush
        if room:GetType() == RoomType.ROOM_BOSSRUSH and goal == 9 and room:IsAmbushDone() and room:IsClear() then
            self:sendGoalReached()
        end
    end
    function self.onPostEntityKill(mod, entity)
        local goal = tonumber(self.CONNECTION_INFO.slot_data["goal"])
        local required_locations = tonumber(self.CONNECTION_INFO.slot_data["requiredLocations"])
        local type = entity.Type
        print('called entityKill', 1, entity, type, entity.Variant, goal, required_locations, #self.CHECKED_LOCATIONS)
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
        elseif type == EntityType.ENTITY_THE_LAMB then
            if entity.Variant == 10 then
                self.LAMB_BODY_KILL = true
            else
                self.LAMB_KILL = true
            end
            if self.LAMB_KILL and self.LAMB_BODY_KILL then
                self:sendGoalReached()
                return
            end
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
        elseif type == EntityType.ENTITY_MOTHER  then
            if  entity.Variant == 10 then
                self:sendGoalReached()                
            end
            return
        else
            self:sendGoalReached()
            return
        end
    end
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, self.onPostGameStarted)
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_RENDER, self.onPostRender)
    self.MOD_REF:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, self.onPreGameExit)
    self.MOD_REF:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, self.onPrePickupCollision)
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, self.onPostEntityKill)
    self.MOD_REF:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, self.onPreSpawnClearAward)
    print("called AP:init", 3, self.MOD_REF)
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
    -- -- restock fix related
    self.REROLL_COUNTS = {}
    self.PICKUP_TIMER = {}
    -- global AP info
    self.LAST_RECEIVED_ITEM_INDEX = -1
    self.CUR_ITEM_STEP_VAL = 0
    self.MISSING_LOCATIONS = {}
    self.CHECKED_LOCATIONS = {}
    self.GAME_DATA = nil
    self.CONNECTION_INFO = nil
    self.ROOM_INFO = nil -- unused currently as RoomInfo package is not received
    self.MESSAGE_QUEUE = {}
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
        cmd = "GetDataPackage"
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
-- AP END Commands

-- AP util funcs
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
    local name = self:resolveIdToName("item", id)
    local item_impl = AP.ITEM_IMPLS[id]
    if item_impl == nil or type(item_impl) ~= 'function' then
        print("!!! received unknown item id  !!!", id)
        return
    end
    item_impl()
    if not name then
        name = "Unknown (" .. id .. ")"
    end
end
-- END AP util funcs

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
                LAST_RECEIVED_ITEM_INDEX = block.index
                for _, item in ipairs(block.items) do
                    self:collectItem(item)
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
                parts ={{
                    msg = "Connection refused by AP Server." .. errsMsgs,
                    color = COLORS.RED
                }}
            })
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
                    if v.flags | 4 == 4 then
                        color = COLORS.RED
                    elseif v.flags | 2 == 2 or v.flags | 1 == 1 then
                        color = COLORS.YELLOW
                    else
                        color = COLORS.GREEN
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
            self.HAS_SEND_GOAL_MSG = false
            self.LAMB_KILL = false
            self.LAMB_BODY_KILL = false
            Isaac.DebugString("Connected", 1, dump_table(block))
            self.CONNECTION_INFO = block
            Isaac.DebugString("Connected", 2, dump_table(self.CONNECTION_INFO))
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
                if self.MOD_REF:HasData() then
                    local modData = json.decode(self.MOD_REF:LoadData())
                    if modData and modData.SAVED_SEED and modData.SAVED_ITEM_INDEX and
                        self.CONNECTION_INFO.slot_data["seed"] == modData.SAVED_SEED then
                        self.LAST_RECEIVED_ITEM_INDEX = modData.SAVED_ITEM_INDEX
                    else
                        self:shutdown()
                        self:addMessage({
                            parts = {{
                                msg = "You are continuing a run of a different slot/game. You have beeen disconnected from the AP server. Please start a new run.",
                                color = COLORS.RED
                            }}
                        })
                        return
                    end
                end
            else
                self.LAST_RECEIVED_ITEM_INDEX = -1
                self.MOD_REF:SaveData(json.encode({
                    SAVED_ITEM_INDEX = -1,
                    SAVED_SEED = ""
                }))
            end
        elseif cmd == "RoomInfo" then -- is never received
            print('!!! got RoomInfo !!!')
            self.ROOM_INFO = block
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
            self.GAME_DATA = {}
            self.GAME_DATA.item_id_to_name = {}
            self.GAME_DATA.location_id_to_name = {}
            for k, v in pairs(block.data.games) do
                self.GAME_DATA[k] = v
                self.GAME_DATA[k].item_id_to_name = {}
                for k2, v2 in pairs(self.GAME_DATA[k].item_name_to_id) do
                    self.GAME_DATA[k].item_id_to_name[v2] = k2
                    self.GAME_DATA.item_id_to_name[v2] = k2
                end
                self.GAME_DATA[k].location_id_to_name = {}
                for k2, v2 in pairs(self.GAME_DATA[k].location_name_to_id) do
                    self.GAME_DATA[k].location_id_to_name[v2] = k2
                    self.GAME_DATA.location_id_to_name[v2] = k2
                end
            end
            self.STATE_MACHINE:set_state(AP.STATE_CONNECTED)
        else
            print("! dropping packet: unhandled cmd " .. cmd .. " !")
        end
    end
end
function AP:processHandshake(data)
    print('processHandshake: ', data)
    self.STATE_MACHINE:set_state(AP.STATE_DATAPACKAGE)
end
function AP:sendBlocks(blocks)
    local data = json.encode(blocks) .. "\r\n"
    print('send', data)
    local encoded = frame.encode(data, frame.TEXT, true)

    local ret, err = self.socket:sock_send(encoded)
    if err ~= nil and err ~= 'timeout' then
        print('Connection lost:', err)
        self:reconnect()
    end
end
function AP:receiveHandshake()
    print('receiveHandshake')
    local data = ''
    while true do
        local part, err = self.socket:sock_receive()
        if err ~= nil and err ~= 'timeout' then
            print('Connection lost:', err)
            self:reconnect()
        end
        if part == nil then
            break
        end
        data = data .. part
    end
    if data ~= nil then
        print('recv', data)
        self:processHandshake(data)
    end
end
function AP:receiveBlock()
    local n = 1
    while true do
        local data, err = self.socket:sock_receive(n)
        if err ~= nil and err ~= 'timeout' then
            print('Connection lost:', err)
            self:reconnect()
        end
        if data == nil then
            return nil
        end
        self.rxBuf = self.rxBuf .. data
        local decoded, fin, opcode, rest, mask = frame.decode(self.rxBuf)
        if decoded ~= nil then
            print('received data')
            self.rxBuf = ''
            return decoded
        else
            n = fin
        end
    end
end
function AP:receive()
    local block = self:receiveBlock()
    if block ~= nil then
        self:processBlock(block)
    end
end
function AP:reconnect()
    if self.STATE_MACHINE:get_state() ~= AP.STATE_EXIT then
        self.STATE_MACHINE:set_state(AP.STATE_CONNECTING)
    end
end
function AP:disconnect()
    self.CONNECTION_INFO = nil
    self.ROOM_INFO = nil
    self.GAME_DATA = nil
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
function AP:showMessages(pos, color, scale)
    if not pos then
        pos = Vector(25, 230)
    end
    if not scale then
        scale = Vector(1, 1)
    end
    for i = 1, 3 do
        if self.MESSAGE_QUEUE[i] and self.MESSAGE_QUEUE[i].timer > 0 then
            local posX = pos.X
            for _, v in ipairs(self.MESSAGE_QUEUE[i].parts) do
                if not v.width then
                    v.width = Isaac.GetTextWidth(v.msg)
                end
                Isaac.RenderScaledText(v.msg, posX, pos.Y + 10 * (i - 1), scale.X, scale.Y, v.color.R, v.color.G,
                    v.color.B, v.color.A)
                posX = posX + v.width * scale.X
            end
            self.MESSAGE_QUEUE[i].timer = self.MESSAGE_QUEUE[i].timer - 1
        end
    end
    self:proceedMessageQueue()
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
        Isaac.RenderScaledText(text, 25, 210, 1, 1, 255, 0, 0, 1)
    elseif state == AP.STATE_CONNECTED then
        Isaac.RenderScaledText(text, 25, 210, 1, 1, 0, 255, 0, 1)
        if self.CONNECTION_INFO then            
            local text2 = string.format("%s/%s checked (need %s); next check: %s/%s; goal: %s", #self.CHECKED_LOCATIONS,
            self.CONNECTION_INFO.slot_data.totalLocations, self.CONNECTION_INFO.slot_data.requiredLocations,
            self.CUR_ITEM_STEP_VAL, self.CONNECTION_INFO.slot_data.itemPickupStep, self:goalIdToName(self.CONNECTION_INFO.slot_data.goal))
            Isaac.RenderScaledText(text2, 25, 220, 1, 1, 255, 255, 255, 1)
        end
    else
        Isaac.RenderScaledText(text, 25, 210, 1, 1, 255, 255, 255, 1)
    end
end
function AP:proceedPickupTimer()
    for k, _ in pairs(self.PICKUP_TIMER) do
        if self.PICKUP_TIMER[k] > 0 then
            self.PICKUP_TIMER[k] = self.PICKUP_TIMER[k] - 1
        end
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

MOD_INSTANCE_AP = AP(HOST_ADDRESS, HOST_PORT, SLOT_NAME, "")
