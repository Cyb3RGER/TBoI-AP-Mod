GAME_NAME = "The Binding of Isaac Rebirth"
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

function spawnRandomPickup()
    spawnRandomPickupByType(PICKUP_TYPES[math.random(#PICKUP_TYPES)])
end

function spawnRandomChest()
    spawnRandomPickupByType(CHEST_TYPES[math.random(#CHEST_TYPES)])
end

function spawnRandomPickupByType(type, subtype)
    if not subtype then
        subtype = 0
    end
    local player = Game():GetNearestPlayer(Isaac.GetRandomPosition())
    local room = Game():GetRoom()
    local pos = room:FindFreePickupSpawnPosition(player.Position, 2, true, false)
    Game():Spawn(EntityType.ENTITY_PICKUP, type, pos, Vector(0, 0), nil, subtype, Game():GetRoom():GetSpawnSeed())
end

function spawnRandomCollectibleFromPool(pool)
    local player = Game():GetNearestPlayer(Isaac.GetRandomPosition())
    local item = Game():GetItemPool():GetCollectible(pool, true)
    local item_config = Isaac:GetItemConfig():GetCollectible(item)
    if item_config.Type ~= ItemType.ITEM_ACTIVE or player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == 0 then
        player:AddCollectible(item)
    else
        local room = Game():GetRoom()
        local pos = room:FindFreePickupSpawnPosition(player.Position, 2, true, false)
        local entity = Game():Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pos, Vector(0, 0), nil, item,
            Game():GetRoom():GetSpawnSeed())
        entity:ToPickup().Touched = true
    end
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