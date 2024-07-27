AP.BASE_ID = 7880000

AP.ITEM_IMPLS = {
    [AP.BASE_ID + 000] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_TREASURE)
    end,
    [AP.BASE_ID + 001] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_SHOP)
    end,
    [AP.BASE_ID + 002] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_BOSS)
    end,
    [AP.BASE_ID + 003] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_DEVIL)
    end,
    [AP.BASE_ID + 004] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_ANGEL)
    end,
    [AP.BASE_ID + 005] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_SECRET)
    end,
    [AP.BASE_ID + 006] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_LIBRARY)
    end,
    [AP.BASE_ID + 007] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_CURSE)
    end,
    [AP.BASE_ID + 008] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_PLANETARIUM)
    end,
    [AP.BASE_ID + 009] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_SHELL_GAME)
    end,
    [AP.BASE_ID + 010] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GOLDEN_CHEST)
    end,
    [AP.BASE_ID + 011] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_RED_CHEST)
    end,
    [AP.BASE_ID + 012] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_BEGGAR)
    end,
    [AP.BASE_ID + 013] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_DEMON_BEGGAR)
    end,
    [AP.BASE_ID + 014] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_KEY_MASTER)
    end,
    [AP.BASE_ID + 015] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_BATTERY_BUM)
    end,
    [AP.BASE_ID + 016] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_MOMS_CHEST)
    end,
    [AP.BASE_ID + 017] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_TREASURE)
    end,
    [AP.BASE_ID + 018] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_BOSS)
    end,
    [AP.BASE_ID + 019] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_SHOP)
    end,
    [AP.BASE_ID + 020] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_DEVIL)
    end,
    [AP.BASE_ID + 021] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_ANGEL)
    end,
    [AP.BASE_ID + 022] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_CURSE)
    end,
    [AP.BASE_ID + 023] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_GREED_SECRET)
    end,
    [AP.BASE_ID + 024] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_CRANE_GAME)
    end,
    [AP.BASE_ID + 025] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_ULTRA_SECRET)
    end,
    [AP.BASE_ID + 026] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_BOMB_BUM)
    end,
    [AP.BASE_ID + 027] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_OLD_CHEST)
    end,
    [AP.BASE_ID + 028] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_BABY_SHOP)
    end,
    [AP.BASE_ID + 029] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_WOODEN_CHEST)
    end,
    [AP.BASE_ID + 030] = function(ap)
        ap:spawnRandomCollectibleFromPool(ItemPoolType.POOL_ROTTEN_BEGGAR)
    end,
    [AP.BASE_ID + 031] = function(ap)
        ap:spawnRandomPickup()
    end,
    [AP.BASE_ID + 032] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_HEART)
    end,
    [AP.BASE_ID + 033] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_COIN)
    end,
    [AP.BASE_ID + 034] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_BOMB)
    end,
    [AP.BASE_ID + 035] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_KEY)
    end,
    [AP.BASE_ID + 036] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_TAROTCARD)
    end,
    [AP.BASE_ID + 037] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_PILL)
    end,
    [AP.BASE_ID + 038] = function(ap)
        ap:spawnRandomChest()
    end,
    [AP.BASE_ID + 039] = function(ap)
        ap:spawnRandomPickupByType(PickupVariant.PICKUP_TRINKET)
    end,
    -- AP.BASE_ID + 040 - AP.BASE_ID + 771 are generated by AP:generateCollectableItemImpls
    [AP.BASE_ID + 772] = function(ap)
        ap:addToTrapQueue(AP.BASE_ID + 772)
    end,
    [AP.BASE_ID + 773] = function(ap)
        ap:addToTrapQueue(AP.BASE_ID + 773, 120)
    end,
    [AP.BASE_ID + 774] = function(ap)
        ap:addToTrapQueue(AP.BASE_ID + 774)
    end,
    [AP.BASE_ID + 775] = function(ap)
        ap:addToTrapQueue(AP.BASE_ID + 775)
    end,
    [AP.BASE_ID + 776] = function(ap)
        ap:addToTrapQueue(AP.BASE_ID + 776, 120)
    end,
    [AP.BASE_ID + 777] = function(ap)
        ap:addToTrapQueue(AP.BASE_ID + 777)
    end,
    [AP.BASE_ID + 778] = function(ap)
        ap:unlockProgressiveStage()
    end,
    [AP.BASE_ID + 779] = function(ap)
        ap:unlockProgressiveAltStage()
    end,
    [AP.BASE_ID + 780] = function(ap)
        ap:unlockStage(LevelStage.STAGE1_1)
    end,
    [AP.BASE_ID + 781] = function(ap)
        ap:unlockStage(LevelStage.STAGE1_2)
    end,
    [AP.BASE_ID + 782] = function(ap)
        ap:unlockStage(LevelStage.STAGE2_1)
    end,
    [AP.BASE_ID + 783] = function(ap)
        ap:unlockStage(LevelStage.STAGE2_2)
    end,
    [AP.BASE_ID + 784] = function(ap)
        ap:unlockStage(LevelStage.STAGE3_1)
    end,
    [AP.BASE_ID + 785] = function(ap)
        ap:unlockStage(LevelStage.STAGE3_2)
    end,
    [AP.BASE_ID + 786] = function(ap)
        ap:unlockStage(LevelStage.STAGE4_1)
    end,
    [AP.BASE_ID + 787] = function(ap)
        ap:unlockStage(LevelStage.STAGE4_2)
    end,
    [AP.BASE_ID + 788] = function(ap)
        ap:unlockStage(LevelStage.STAGE4_3)
        ap:unlockStage(LevelStage.STAGE5)
    end,
    [AP.BASE_ID + 789] = function(ap)
        ap:unlockStage(LevelStage.STAGE6)
    end,
    [AP.BASE_ID + 790] = function(ap)
        ap:unlockStage(LevelStage.STAGE7)
    end,
    [AP.BASE_ID + 791] = function(ap)
        ap:unlockStage(LevelStage.STAGE8)
    end,
    [AP.BASE_ID + 792] = function(ap)
        ap:unlockAltStage(AP.ALT_STAGES.DOWNPOUR_1)
    end,
    [AP.BASE_ID + 793] = function(ap)
        ap:unlockAltStage(AP.ALT_STAGES.DOWNPOUR_2)
    end,
    [AP.BASE_ID + 794] = function(ap)
        ap:unlockAltStage(AP.ALT_STAGES.MINES_1)
    end,
    [AP.BASE_ID + 795] = function(ap)
        ap:unlockAltStage(AP.ALT_STAGES.MINES_2)
    end,
    [AP.BASE_ID + 796] = function(ap)
        ap:unlockAltStage(AP.ALT_STAGES.MAUSOLEUM_1)
    end,
    [AP.BASE_ID + 797] = function(ap)
        ap:unlockAltStage(AP.ALT_STAGES.MAUSOLEUM_2)
    end,
    [AP.BASE_ID + 798] = function(ap)
        ap:unlockAltStage(AP.ALT_STAGES.CORPSE_1)
    end,
    [AP.BASE_ID + 799] = function(ap)
        ap:unlockAltStage(AP.ALT_STAGES.CORPSE_2)
    end,
}
AP.TRAP_IMPLS = {
    [AP.BASE_ID + 772] = function(ap)
        for i = 0, 5 do
            ap:addToSpawnQueue(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, BombSubType.BOMB_TROLL, 5)
        end
    end,
    [AP.BASE_ID + 773] = function(ap)
        local level = Game():GetLevel()
        if (level:GetCurrentRoomDesc().Flags & RoomDescriptor.FLAG_CURSED_MIST) ~= RoomDescriptor.FLAG_CURSED_MIST then
            Game():StartRoomTransition(level:GetRandomRoomIndex(ap.SLOT_DATA.teleportTrapCanError, ap.RNG:Next()), -1,
                RoomTransitionAnim.TELEPORT)
        end
    end,
    [AP.BASE_ID + 774] = function(ap)
        Game():AddPixelation(300)
    end,
    [AP.BASE_ID + 775] = function(ap)
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
        ap:addToTrapQueue(AP.BASE_ID + 775)
    end,
    [AP.BASE_ID + 776] = function(ap)
        local player = Game():GetNearestPlayer(Isaac.GetRandomPosition())
        if player:HasCollectible(ap.AP_ITEM_TRAP_PARALISYS) then
            ap:addToTrapQueue(AP.BASE_ID + 776, 120)
        else
            player:AddCollectible(ap.AP_ITEM_TRAP_PARALISYS)
        end
    end,
    [AP.BASE_ID + 777] = function(ap)
        local player = Game():GetNearestPlayer(Isaac.GetRandomPosition())
        player:UseActiveItem(CollectibleType.COLLECTIBLE_WAVY_CAP)
    end
}

function AP:unlockProgressiveStage()
    local len = #self.UNLOCKED_STAGES + 1
    table.insert(self.UNLOCKED_STAGES, len)
    if len == LevelStage.STAGE4_2 then
        table.insert(self.UNLOCKED_STAGES, len + 1)
    end
end

function AP:unlockProgressiveAltStage()
    local len = #self.UNLOCKED_ALT_STAGES + 1
    table.insert(self.UNLOCKED_ALT_STAGES, len)
end
function AP:unlockStage(stage)
    if not tbl_contains(self.UNLOCKED_STAGES, stage) then
        table.insert(self.UNLOCKED_STAGES, stage)
    end
end
function AP:unlockAltStage(stage)
    if not tbl_contains(self.UNLOCKED_ALT_STAGES, stage) then
        table.insert(self.UNLOCKED_ALT_STAGES, stage)
    end
end


function AP:generateCollectableItemImpls(startIdx)
    for i = 0, CollectibleType.NUM_COLLECTIBLES - 2 do
        AP.ITEM_IMPLS[startIdx + i] = function(ap)
            ap:spawnCollectible(i + 1, true)
        end
    end
end

-- AP item impl helpers
function AP:spawnCollectible(item, forceItem)
    local playerNum = Game():GetNumPlayers()
    local randomIndex = self.RNG:RandomInt(playerNum)
    -- dbg_log("AP:spawnCollectible "..tostring(randomIndex).." ".. tostring(playerNum))
    local player = Game():GetPlayer(randomIndex)
    -- Found Soul fix
    while player.Variant == 1 and player.SubType == 59 do
        -- dbg_log("AP:spawnCollectible rerolling player from "..tostring(player:GetName()))
        randomIndex = self.RNG:RandomInt(playerNum)
        player = Game():GetPlayer(randomIndex)
    end
    -- dbg_log("AP:spawnCollectible "..tostring(player:GetName()))
    local item_config = Isaac:GetItemConfig():GetCollectible(item)
    -- dbg_log("AP:spawnCollectible "..tostring(item_config))
    -- print("AP:spawnCollectible", splayer:GetCollectibleCount())
    if (item_config.Type ~= ItemType.ITEM_ACTIVE or player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == 0) and
        not (player:GetPlayerType() == PlayerType.PLAYER_ISAAC_B and player:GetCollectibleCount() > 8) and item ~=
        CollectibleType.COLLECTIBLE_TMTRAINER then
        -- FixMe: transformations cause graphical glitches sometimes
        -- player:QueueItem(item_config)        
        -- player:FlushQueueItem()
        -- dbg_log("AP:spawnCollectible AddCollectible")
        player:AddCollectible(item)
    else
        -- dbg_log("AP:spawnCollectible Spawning")
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
        local pickup = entity:ToPickup()
        if forceItem then
            -- make sure the item does not change into anything else
            pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, item, true, true, true)
        end
        -- used to not make AP spawned item collectable until rerolled
        pickup.Touched = true
    end
end
function AP:spawnRandomCollectibleFromPool(pool)
    local item = Game():GetItemPool():GetCollectible(pool, true)
    self:spawnCollectible(item)
end
function AP:spawnRandomPickup()
    self:spawnRandomPickupByType(PICKUP_TYPES[self.RNG:RandomInt(#PICKUP_TYPES) + 1])
end
function AP:spawnRandomChest()
    self:spawnRandomPickupByType(CHEST_TYPES[self.RNG:RandomInt(#CHEST_TYPES) + 1])
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