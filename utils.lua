DIR_SEP = package.config:sub(1,1)
IS_WINDOWS = DIR_SEP == '\\'
IS_REPENTOGON = _VERSION ~= "Lua 5.3"

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
    --print("checkPos", 1,  playerPos.X, clampedPos.X, playerPos.Y, clampedPos.Y, collision, girdEntity)
    if (playerPos.X == clampedPos.X and playerPos.Y == clampedPos.Y) or collision ~= GridCollisionClass.COLLISION_NONE or girdEntity ~= nil then
        return false
    end
    --print("checkPos", 2)
    local entities = Isaac.GetRoomEntities()
    for _, v in pairs(entities) do
        if v.Type == EntityType.ENTITY_PICKUP then
            local clampedEntityPos = room:GetGridPosition(room:GetGridIndex(v.Position))
            if clampedEntityPos.X == clampedPos.X and clampedEntityPos.Y == clampedPos.Y then
                --print("checkPos", 3)
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
        local tabs = ('  '):rep(depth)
        local tabs2 = ('  '):rep(depth + 1)
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

function tbl_contains(list, value)
    for _, v in pairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

function tbl_find_index(list, value)
    for k, v in pairs(list) do
        if v == value then
            print("tbl_find_index", dump_table(list), value, k)
            return k
        end
    end
    return nil
end

function math.round(num, decimalPlaces)
    return tonumber(string.format("%." .. (decimalPlaces or 0) .. "f", num))
end

function getKeysSortedByValue(tbl, sortFunction)
    local keys = {}
    for key in pairs(tbl) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
        return sortFunction(tbl[a], tbl[b])
    end)    
    return keys
end

-- used to dump collectables for AP item list
function dump_collectables(id_offset)
    local temp = CollectibleType
    -- remove unneeded keys
    temp.COLLECTIBLE_NULL = nil
    temp.NUM_COLLECTIBLES = nil
    -- sort
    local sortedKeys = getKeysSortedByValue(temp, function(a, b)
        return a < b
    end)    
    -- output
    local ids = {}
    require('io')
    local file = io.open("collectables.txt", "w+")
    for _, k in pairs(sortedKeys) do
        local id = temp[k] + id_offset - 1
        local name = string.sub(k, 13)
        name = string.lower(name)
        name = string.gsub(name, "_", " ")
        name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
        local i = 0
        while true do
            i = string.find(name, " ", i + 1)
            if i == nil then
                break
            end
            name = string.sub(name, 1, i) .. string.upper(string.sub(name, i + 1, i + 1)) .. string.sub(name, i + 2)
        end
        if contains(ids, id) then
            file:write(string.format("# %s need alias %s\n", id, name))
            print('add alias notice', name, id)
        else
            file:write(string.format("\"%s\": %s,\n", name, id))
            print(name, id)
            table.insert(ids, id)
        end
    end
    file:close()
end

function dump_table_to_file(table, filename)
    require('io')
    local file = io.open(filename, "w+")
    file:write(dump_table(table))
    file:close()
end

function get_simple_game_data(game_data)
    if not game_data then
        return nil
    end
    local result = {}
    result.version = game_data.version  
    result.games = {}  
    --print(dump_table_to_file(game_data, "gamedata.txt"))
    for k, v in pairs(game_data.games) do 
        if v.version ~= 0 then    
            result.games[k] = {}
            result.games[k].item_name_to_id = v.item_name_to_id
            result.games[k].location_name_to_id = v.location_name_to_id
            result.games[k].version = v.version
        end
    end
    return result
end

function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function dbg_log(str)
    print("[AP] "..tostring(str))
    Isaac.DebugString("[AP] "..tostring(str))
end

function split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do
       table.insert(result, each)
    end
    return result
 end

function debugPlayers()
    local players = {}
    
    for i=0, 8, 1 do
        local player = Game():GetPlayer(i)
        local found = false
        for _, v in ipairs(players) do
            if player.Index == v.Index then
                found = true
                break
            end
        end
        if found then
            break
        end
        players[i+1] = player
    end
    print("-------------------------------------------------")
    for i,v in pairs(players) do
        print(i-1, players[i].Index, players[i].Type, players[i].Variant, players[i].SubType, players[i]:GetPlayerType(),
         players[i]:GetName(), players[i]:GetMainTwin().Index, players[i]:GetOtherTwin(), players[i]:GetSubPlayer(),
         players[i]:IsCoopGhost(), players[i]:IsSubPlayer(), players[i]:GetEntityFlags(), players[i].Child, players[i].Parent)
        if players[i].Parent then
            print(players[i].Parent.Index)
        end
        print("-------------------------------------------------")
    end
end

function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end 