require('utils')
local mod = RegisterMod("AP Test", 1)
local json = require('json')
local ws_client = require('websocket.client_sync')
local tools = require('websocket.tools')
local handshake = require('websocket.handshake')
local frame = require('websocket.frame')

-- AP client version
local MAJOR_VERSION = "0"
local MINOR_VERSION = "1"
local BUILD_VERSION = "6"
-- AP connection config
local HOST_ADDRESS = "127.0.0.1"
local HOST_PORT = "38281"
local SLOT_NAME = "Cyb3R"

local RECONNECT_INTERVAL = 3

local socket = nil
local currTime = 0
local lastTime = 0

local IS_CONTINUED = false

local LAST_RECEIVED_ITEM_INDEX = -1
local SAVED_ITEM_INDEX = -1
local SAVED_SEED = nil
local CUR_ITEM_STEP_VAL = 0
local MISSING_LOCATIONS = {}

local GAME_DATA = nil
local CONNECTION_INFO = nil
local ROOM_INFO = nil
local ITEM_IMPLS = {
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
local CONNECT_COMMAND = {
    cmd = "Connect",
    password = "",
    game = GAME_NAME,
    name = SLOT_NAME,
    uuid = "1",
    version = {
        major = MAJOR_VERSION,
        minor = MINOR_VERSION,
        build = BUILD_VERSION,
        class = "Version"
    },
    items_handling = 7,
    tags = {}
}
local CONNECT_GET_DATA_PACKAGE = {
    cmd = "GetDataPackage"
}

-- setup statemachine
require('statemachine')
local stateMachine = SimpleStateMachine()
-- State names for stateMachine
local STATE_CONNECTING = "connecting"
local STATE_HANDSHAKE = "handshake"
local STATE_DATAPACKAGE = "datapackage"
local STATE_CONNECTED = "connected"
local STATE_EXIT = "exit"
-- END setup statemachine

-- AP util funcs
function resolveIdToName(typeStr, id)
    if string.find(typeStr, "location") then
        if type(id) == "string" then
            id = tonumber(id)
        end
        print("resolveIdToName", typeStr, GAME_DATA.location_id_to_name[id])
        return GAME_DATA.location_id_to_name[id]
    elseif string.find(typeStr, "item") then
        if type(id) == "string" then
            id = tonumber(id)
        end
        print("resolveIdToName", typeStr, GAME_DATA.item_id_to_name[id])
        return GAME_DATA.item_id_to_name[id]
    elseif string.find(typeStr, "player") then
        return CONNECTION_INFO.slot_info[id].name -- ToDo: alias via players?
    else
        print('!!! can to resolve Id to Name of unknown type !!!', typeStr)
        return id
    end
end

function collectItem(item)
    local id = item.item
    local name = resolveIdToName("item", id)
    local item_impl = ITEM_IMPLS[id]
    if item_impl == nil or type(item_impl) ~= 'function' then
        print("!!! received unknown item id  !!!", id)
        return
    end
    item_impl()
    if not name then
        name = "Unknown (" .. id .. ")"
    end
end

function getLocationCollectedCommand(id)
    return {
        cmd = "LocationChecks",
        locations = {id}
    }
end
-- END AP util funcs

-- AP connection handling
function processBlock(data)
    local blocks = json.decode(data)
    if blocks == nil then
        print("!!!! invalid CONTENT @ processBlock !!!!", data)
    end
    -- print("processBlock: ", dump_table(blocks))
    for _, block in ipairs(blocks) do
        local cmd = block.cmd
        if cmd == "ReceivedItems" then
            if block.index > LAST_RECEIVED_ITEM_INDEX then
                LAST_RECEIVED_ITEM_INDEX = block.index
                for _, item in ipairs(block.items) do
                    collectItem(item)
                end
            end
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
                    text = resolveIdToName(v.type, v.text)
                    color = COLORS.BLUE
                elseif v.type == "player_name" then
                    color = COLORS.BLUE
                elseif v.type == "item_id" then
                    text = resolveIdToName(v.type, v.text)
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
                    text = resolveIdToName(v.type, v.text)
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
            addMessage(msg)
        elseif cmd == "Print" then
            addMessage(block.text)
        elseif cmd == "Connected" then
            CONNECTION_INFO = block
            MISSING_LOCATIONS = block.missing_locations
            if IS_CONTINUED then
                LAST_RECEIVED_ITEM_INDEX = SAVED_ITEM_INDEX
            else
                LAST_RECEIVED_ITEM_INDEX = -1
                SAVED_ITEM_INDEX = -1
            end
        elseif cmd == "RoomInfo" then
            ROOM_INFO = block
        elseif cmd == "DataPackage" then
            GAME_DATA = {}
            GAME_DATA.item_id_to_name = {}
            GAME_DATA.location_id_to_name = {}
            for k, v in pairs(block.data.games) do
                GAME_DATA[k] = v
                GAME_DATA[k].item_id_to_name = {}
                for k2, v2 in pairs(GAME_DATA[k].item_name_to_id) do
                    GAME_DATA[k].item_id_to_name[v2] = k2
                    GAME_DATA.item_id_to_name[v2] = k2
                end
                GAME_DATA[k].location_id_to_name = {}
                for k2, v2 in pairs(GAME_DATA[k].location_name_to_id) do
                    GAME_DATA[k].location_id_to_name[v2] = k2
                    GAME_DATA.location_id_to_name[v2] = k2
                end
            end
            stateMachine:set_state(STATE_CONNECTED)
        else
            print("! dropping packet: unhandled cmd " .. cmd .. " !")
        end
    end
end

function processHandshake(data)
    print('processHandshake: ', data)
    stateMachine:set_state(STATE_DATAPACKAGE)
end

function sendBlock(block)
    local data = "[" .. json.encode(block) .. "]\r\n"
    print('send', data)
    local encoded = frame.encode(data, frame.TEXT, true)

    local ret, err = socket:sock_send(encoded)
    if ret == nil then
        print('Failed to send:', err)
    end
end

function receiveHandshake()
    print('receiveHandshake')
    while true do
        local data, err = socket:sock_receive()
        if err ~= nil and err ~= 'timeout' then
            print('Connection lost:', err)
            reconnect()
        end
        if data == nil then
            break
        end
        print('recv', data)
        processHandshake(data)
    end
end

local rxBuf = ''
function receiveBlock()
    local n = 1
    while true do
        local data, err = socket:sock_receive(n)
        if data == nil then
            return nil
        end
        rxBuf = rxBuf .. data
        local decoded, fin, opcode, rest, mask = frame.decode(rxBuf)
        if decoded ~= nil then
            print('received data')
            rxBuf = ''
            return decoded
        else
            n = fin
        end
    end
end

function receive()
    local block = receiveBlock()
    if block ~= nil then
        processBlock(block)
    end
end

function reconnect()
    if stateMachine:get_state() ~= STATE_EXIT then
        stateMachine:set_state(STATE_CONNECTING)
    end
end

function disconnect()
    if socket then
        socket:sock_close()
        socket = nil
    end
end

function shutdown()
    stateMachine:set_state(STATE_EXIT)
end
-- END AP connection handling

-- AP message printing
messageQueue = {}

function addMessage(msg)
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
    table.insert(messageQueue, msg)
end

function proceedMessageQueue()
    for i = 1, 3 do
        if messageQueue[1] and messageQueue[1].timer <= 0 then
            table.remove(messageQueue, 1)
        end
    end
end

function showMessages(pos, color, scale)
    if not pos then
        pos = Vector(25, 220)
    end
    if not scale then
        scale = Vector(1, 1)
    end
    for i = 1, 3 do
        if messageQueue[i] and messageQueue[i].timer > 0 then
            local posX = pos.X
            for _, v in ipairs(messageQueue[i].parts) do
                Isaac.RenderScaledText(v.msg, posX, pos.Y + 10 * (i - 1), scale.X, scale.Y, v.color.R, v.color.G,
                    v.color.B, v.color.A)
                posX = posX + v.width * scale.X
            end
            messageQueue[i].timer = messageQueue[i].timer - 1
        end
    end
    proceedMessageQueue()
end
-- END AP message printing

-- statemachine callbacks
local function onEnter_Connecting()
    LAST_RECEIVED_ITEM_INDEX = -1
end
local function onTick_Connecting()
    currTime = os.time()
    if lastTime + RECONNECT_INTERVAL <= currTime then
        lastTime = currTime
        socket = ws_client()
        local ret, err = socket:sock_connect(HOST_ADDRESS, HOST_PORT)
        if ret == 1 then
            print('Connection established')
            socket:set_timeout(0)
            local key = tools.generate_key()
            local req = handshake.upgrade_request {
                key = key,
                host = HOST_ADDRESS,
                port = HOST_PORT,
                protocols = {'ws'},
                origin = '',
                uri = 'ws://' .. HOST_ADDRESS .. ':' .. HOST_PORT
            }
            socket:sock_send(req)
            stateMachine:set_state(STATE_HANDSHAKE)
        else
            print('Failed to open socket:', err)
            socket:sock_close()
            socket = nil
        end
    end
end
local function onTick_Handshake()
    receiveHandshake()
end
local function onTick_Connected()
    receive()
end
local function onEnter_Connected()
    sendBlock(CONNECT_COMMAND)
end
local function onEnter_Datapackage()
    sendBlock(CONNECT_GET_DATA_PACKAGE)
end
local function onExit_Connected()
    disconnect()
end
local function onEnter_Exit()
    disconnect()
end
stateMachine:register(STATE_CONNECTING, onEnter_Connecting, onTick_Connecting, nil)
stateMachine:register(STATE_HANDSHAKE, nil, onTick_Handshake, nil)
stateMachine:register(STATE_DATAPACKAGE, onEnter_Datapackage, onTick_Connected, nil)
stateMachine:register(STATE_CONNECTED, onEnter_Connected, onTick_Connected, onExit_Connected)
stateMachine:register(STATE_EXIT, onEnter_Exit, nil, nil)
-- END statemachine callbacks

-- mod callbacks
function init(mod, isContinued)
    IS_CONTINUED = isContinued
    stateMachine:set_state(STATE_CONNECTING)
end

function tick(mod)
    stateMachine:tick()
    local state = stateMachine:get_state()
    local text = "AP: " .. state
    if state == STATE_EXIT then
        Isaac.RenderScaledText(text, 25, 210, 1, 1, 255, 0, 0, 1)
    elseif state == STATE_CONNECTED then
        Isaac.RenderScaledText(text, 25, 210, 1, 1, 0, 255, 0, 1)
    else
        Isaac.RenderScaledText(text, 25, 210, 1, 1, 255, 255, 255, 1)
    end
    showMessages()
end

function exit(mod, shouldSave)
    shutdown()
    if shouldSave then
        SAVED_ITEM_INDEX = LAST_RECEIVED_ITEM_INDEX
        -- SAVED_SEED = ROOM_INFO.seed_name
    end
end

function itemGet(mod, pickup, collider, low)
    print('called item get')
    if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE or collider.Type ~= EntityType.ENTITY_PLAYER or
        #MISSING_LOCATIONS < 1 or pickup.Touched -- check for special items: polaroid/negative or key pieces or dad's note
    or pickup.SubType == CollectibleType.COLLECTIBLE_POLAROID or pickup.SubType == CollectibleType.COLLECTIBLE_NEGATIVE or
        pickup.SubType == CollectibleType.COLLECTIBLE_KEY_PIECE_1 or pickup.SubType ==
        CollectibleType.COLLECTIBLE_KEY_PIECE_2 or pickup.SubType == CollectibleType.COLLECTIBLE_DADS_NOTE or
        pickup.SubType == CollectibleType.COLLECTIBLE_NULL then
        return
    end
    local player = collider:ToPlayer()
    -- check if we can buy this, if shop item
    if pickup:IsShopItem() then
        if pickup.Price > 0 then
            if pickup.Price > collider:ToPlayer():GetNumCoins() then
                return
            end
        elseif pickup.Price > -3 then
            if pickup.Price * -2 > player:GetHearts() then
                return
            end
        elseif pickup.Price == -3 then
            if pickup.Price * -2 > player:GetSoulHearts() then
                return
            end
        end
    end
    local room = Game():GetRoom()
    -- check for boss rush
    if room:GetType() == RoomType.ROOM_BOSSRUSH and not room:IsAmbushDone() then
        return
    end
    print('remove callback')
    mod:RemoveCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, itemGet)
    local item_step = CONNECTION_INFO.slot_data["itemPickupStep"]
    CUR_ITEM_STEP_VAL = CUR_ITEM_STEP_VAL + 1
    print('item is potential AP item', item_step, CUR_ITEM_STEP_VAL, #MISSING_LOCATIONS, pickup.SubType)
    if CUR_ITEM_STEP_VAL == item_step then
        local id = MISSING_LOCATIONS[1]
        sendBlock(getLocationCollectedCommand(id))
        table.remove(MISSING_LOCATIONS, 1)
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
            if pickup.Price > 0 then
                player:AddCoins(-1 * pickup.Price)
            elseif pickup.Price > -3 then
                player:AddMaxHearts(pickup.Price * 2)
            elseif pickup.Price == -3 then
                player:AddSoulHearts(pickup.Price * 2)
            end
        end
        pickup:Remove()
        CUR_ITEM_STEP_VAL = 0

        print('add callback')
        mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, itemGet)
        return false
    end
    print('add callback')
    mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, itemGet)
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, init)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, tick)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, exit)
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, itemGet)

