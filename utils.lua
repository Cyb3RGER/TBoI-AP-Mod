COLORS = {
    RED = {
        R = 255,
        G = 0,
        B = 0,
        A = 1
    },
    GREEN = {
        R = 0,
        G = 255,
        B = 0,
        A = 1
    },
    BLUE = {
        R = 0,
        G = 0,
        B = 255,
        A = 1
    },
    YELLOW = {
        R = 255,
        G = 255,
        B = 0,
        A = 1
    },
    MAGENTA = {
        R = 255,
        G = 0,
        B = 255,
        A = 1
    },
    CYAN = {
        R = 0,
        G = 255,
        B = 255,
        A = 1
    },
    WHITE = {
        R = 255,
        G = 255,
        B = 255,
        A = 1
    },
    BLACK = {
        R = 0,
        G = 0,
        B = 0,
        A = 1
    }
}

CHEST_TYPES = {PickupVariant.PICKUP_CHEST, PickupVariant.PICKUP_BOMBCHEST, PickupVariant.PICKUP_SPIKEDCHEST,
               PickupVariant.PICKUP_ETERNALCHEST, PickupVariant.PICKUP_MIMICCHEST, PickupVariant.PICKUP_OLDCHEST,
               PickupVariant.PICKUP_MEGACHEST, PickupVariant.PICKUP_HAUNTEDCHEST, PickupVariant.PICKUP_LOCKEDCHEST,
               PickupVariant.PICKUP_REDCHEST, PickupVariant.PICKUP_MOMSCHEST}

PICKUP_TYPES = {PickupVariant.PICKUP_HEART, PickupVariant.PICKUP_COIN, PickupVariant.PICKUP_BOMB,
                PickupVariant.PICKUP_KEY, PickupVariant.PICKUP_TAROTCARD, PickupVariant.PICKUP_PILL,
                PickupVariant.PICKUP_TRINKET}

for _, v in ipairs(CHEST_TYPES) do
    table.insert(PICKUP_TYPES, v)
end

function checkPos(pos, player)   
    local room = Game():GetRoom() 
    local playerPos = room:GetGridPosition(room:GetGridIndex(player.Position))
    local clampedPos = room:GetGridPosition(room:GetGridIndex(pos))
    local collision = room:GetGridCollisionAtPos(pos)
    local girdEntity = room:GetGridEntityFromPos(pos)
    print("checkPos", 1,  playerPos.X, clampedPos.X, playerPos.Y, clampedPos.Y, collision, girdEntity)
    if (playerPos.X == clampedPos.X and playerPos.Y == clampedPos.Y) or collision ~= GridCollisionClass.COLLISION_NONE or girdEntity ~= nil then
        return false
    end
    print("checkPos", 2)
    local entities = Isaac.GetRoomEntities()
    for _, v in pairs(entities) do
        if v.Type == EntityType.ENTITY_PICKUP then
            local clampedEntityPos = room:GetGridPosition(room:GetGridIndex(v.Position))
            if clampedEntityPos.X == clampedPos.X and clampedEntityPos.Y == clampedPos.Y then
                print("checkPos", 3)
                return false
            end
        end
    end
    return true
end

function getCollectableIndex(collectable)    
    local level = Game():GetLevel()
    local room = Game():GetRoom()
    local roomDescriptor = level:GetCurrentRoomDesc()
    local roomListIndex = roomDescriptor.ListIndex
    local gridIndex = room:GetGridIndex(collectable.Position)
    local subType = collectable.SubType
    local initSeed = collectable.InitSeed
    return "("..roomListIndex.."|"..gridIndex.."|"..initSeed..")"
end

-- from https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
function dump_table(o, depth)
    if depth == nil then
        depth = 0
    end
    if type(o) == 'table' then
        local tabs = ('\t'):rep(depth)
        local tabs2 = ('\t'):rep(depth + 1)
        local s = '{\n'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. tabs2 .. '[' .. k .. '] = ' .. dump_table(v, depth + 1) .. ',\n'
        end
        return s .. tabs .. '}'
    else
        return tostring(o)
    end
end

function contains(list, value)
    for _, v in pairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

function findIndex(list, value)
    for k, v in pairs(list) do
        if v == value then
            print("findIndex", dump_table(list), value, k)
            return k
        end
    end
    return nil
end

function math.round(num, decimalPlaces)
    return tonumber(string.format("%." .. (decimalPlaces or 0) .. "f", num))
end