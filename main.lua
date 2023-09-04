require('utils')
require('class')

AP = class()

AP.INSTANCE = nil
AP.MOD_NAME = "AP Integration"

require('ap_messages')
require('ap_mcm')
require('ap_client')
require('ap_item_impls')
require('ap_settings')
require('ap_data_storage')

function AP:init()
    AP.INSTANCE = self
    dbg_log("called AP:init 1")
    self:generateCollectableItemImpls(78040)
    self.RNG = RNG()
    self.RNG:SetSeed(Random(), 35)
    self.DEBUG_MODE = false
    self.INFO_TEXT_SCALE = 0.5
    self.HUD_OFFSET = 5
    -- AP Connection info (initial values)
    self.HOST_ADDRESS = "localhost"
    self.HOST_PORT = "38281"
    self.PASSWORD = ""
    self.SLOT_NAME = "Player1"
    -- print("called AP:init", 1.5, self.HOST_ADDRESS, self.HOST_PORT, self.SLOT_NAME, self.PASSWORD)    
    -- ap client / statemachine
    self:initAPClient()

    self.RECONNECT_INTERVAL = 5
    self.MAX_RECONNECT_TRIES = 1
    self.RECONNECT_TRIES = 0
    self.SHOULD_AUTO_CONNECT = false
    dbg_log("called AP:init 2")
    -- Isaac mod ref
    self.MOD_REF = RegisterMod(self.MOD_NAME, 1)
    self.AP_ITEM_ID = Isaac.GetItemIdByName("AP Item")
    self.AP_ITEM_ID_CHEAP = Isaac.GetItemIdByName("AP Item (10 coins)")
    self.AP_ITEM_TRAP_PARALISYS = Isaac.GetItemIdByName("AP Trap (Paralysis)")
    self.COLLECTABLE_IMPLS = {
        [self.AP_ITEM_ID] = function(ap, player)
            ap:clearLocations(1)
        end,
        [self.AP_ITEM_ID_CHEAP] = function(ap, player)
            ap:clearLocations(1)
        end,
        [self.AP_ITEM_TRAP_PARALISYS] = function(ap, player)
            player:UsePill(PillEffect.PILLEFFECT_PARALYSIS, PillColor.PILL_NULL)
        end
    }
    self:initMCM()
    self:loadConnectionInfo()
    self:loadSettings()
    -- mod callbacks
    function self.onPostGameStarted(mod, isContinued)
        dbg_log('self.onPostGameStarted')
        if not isContinued then
            self.JUST_STARTED = true
            self.JUST_STARTED_TIMER = 100
        end
        self.IS_CONTINUED = isContinued
        self.RECONNECT_TRIES = 0
        self.TRAP_QUEUE = {}
        self.TRAP_QUEUE_TIMER = 150
        self.RECEIVED_QUEUE = {}
        self.killed_bosses = {}
        if self.SHOULD_AUTO_CONNECT then
            self:connectAP()
        end
    end
    function self.onPostRender(mod)
        -- dbg_log("onPostRender")`
        if self.AP_CLIENT then
            self.AP_CLIENT:poll()
        end
        self:showPermanentInfo()
        self:showMessages()
        if self.DEBUG_MODE then
            self:showDebugInfo()
        end
        self:runPickupTimer()
        self:runJustStartedTimer()
        self:advanceItemQueue()
        self:advanceTrapQueue()
        self:advanceSpawnQueue()
    end
    function self.onPreGameExit(mod, shouldSave)
        if self.AP_CLIENT and self.AP_CLIENT:get_state() == 4 then
            self:setPersistentInfoFurthestFloor()
        end
        self.ITEM_QUEUE = {}
        self.TRAP_QUEUE = {}
        self.SPAWN_QUEUE = {}
        if shouldSave then
            local seed = ""
            if self.CONNECTION_INFO and self.SLOT_DATA then
                seed = self.SLOT_DATA.seed
            end
            self:saveOtherData(seed)
        end
        self.AP_CLIENT = nil
    end
    function self.onPrePickupCollision(mod, pickup, collider, low)
        local totalLocations = self.SLOT_DATA.totalLocations
        local checkedLocations = #self.AP_CLIENT.checked_locations
        local collectableIndex = getCollectableIndex(pickup)
        if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE or collider.Type ~= EntityType.ENTITY_PLAYER or
            checkedLocations >= totalLocations or (pickup.Touched and pickup.SubType ~= self.AP_ITEM_ID) -- used to not make AP spawned item collectable until rerolled
        or pickup.SubType == CollectibleType.COLLECTIBLE_NULL -- might get called when bumping in a already collected collectable
        then
            return
        end
        local itemConfig = Isaac.GetItemConfig():GetCollectible(pickup.SubType)
        -- check for special items like polaroid/negative, key/knife pieces or dad's note
        if itemConfig:HasTags(ItemConfig.TAG_QUEST) then
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
        -- mod:RemoveCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, self.onPrePickupCollision)
        self.PICKUP_TIMER = 90
        if player:CanPickupItem() and pickup.Wait <= 0 and pickup.SubType ~= self.AP_ITEM_ID then
            -- print("onPrePickupCollision", pickup.Wait, pickup.State)
            local item_step = self.SLOT_DATA.itemPickupStep
            self.CUR_ITEM_STEP_VAL = self.CUR_ITEM_STEP_VAL + 1
            print('item is potential AP item', item_step, self.CUR_ITEM_STEP_VAL, #self.AP_CLIENT.missing_locations,
                pickup.SubType, pickup.State)
            if self.CUR_ITEM_STEP_VAL == item_step then
                -- self:clearLocations(1)                
                self.CUR_ITEM_STEP_VAL = 0
                local itemConfig = Isaac.GetItemConfig():GetCollectible(pickup.SubType)
                print("onPrePickupCollision", self.AP_ITEM_ID)
                if (itemConfig.ShopPrice == 10) then
                    pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, self.AP_ITEM_ID_CHEAP,
                        true, true, true)
                else
                    pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, self.AP_ITEM_ID, true,
                        true, true)
                end
                pickup.Touched = true -- ToDo: Test with boss rush/challenge rooms
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
        for id, impl in pairs(self.COLLECTABLE_IMPLS) do
            if type(impl) == "function" and player:HasCollectible(id) then
                -- Found Soul fix
                if player.Variant ~= 1 or player.SubType ~= 59 then
                    impl(self, player)
                end
                player:RemoveCollectible(id)
            end
        end
    end
    function self.onPreSpawnClearAward(mod)
        local room = Game():GetRoom()
        -- print("self.onPreSpawnClearAward", room, goal)
        -- check for boss rush
        if room:GetType() == RoomType.ROOM_BOSSRUSH and room:IsAmbushDone() and room:IsClear() then
          self:sendBossClearReward(self.bosses.BOSS_RUSH)
        end
    end
    function self.onPostEntityKill(mod, entity)
        local player = entity:ToPlayer()
        -- ToDo: make send DeathLink on revive a option?
        if player and self.SLOT_DATA.deathLink and self.SLOT_DATA.deathLink == 1 and not player:WillPlayerRevive() then
            self:sendDeathLinkBounce()
            self:addMessage({
                parts = {{
                    msg = "[DeathLink] Sent DeathLink",
                    color = COLORS.RED
                }}
            })
        end
        local type = entity.Type
        -- print('called entityKill', 1, entity, type, entity.Variant, goal, required_locations, #self.CHECKED_LOCATIONS)
        local isGoalBoss = false
        for _, v in pairs(self.GOAL_BOSSES) do
            if tbl_contains(v, type) then
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
            dbg_log("Lamb Kill info changed: LAMB_BODY_KILL: "..tostring(self.LAMB_BODY_KILL).." LAMB_KILL: "..tostring(self.LAMB_KILL))
        end
        print('called entityKill', 3, "is goal boss", type, entity.Variant)  
        local playerType = Isaac.GetPlayer():GetPlayerType()
        local isHardMode = self:isHardMode()
        -- blue baby uses a SubType of Isaac => requries special handling
        if type == EntityType.ENTITY_ISAAC then
            if entity.Variant == 0 then
              self:sendBossClearReward(self.bosses.ISAAC)
            elseif entity.Variant == 1 then
              self:sendBossClearReward(self.bosses.BLUE_BABY)
            end
            return
            -- phase 2 is Variant 10 and ending phase 1 counts as killing Variant 0 sometimes => requries special handling
        elseif type == EntityType.ENTITY_SATAN then
            if entity.Variant == 10 then
                self:sendBossClearReward(self.bosses.SATAN)
                self.SATAN_KILL = true
            end
            return
            -- the lamb uses two entities The Lamb itself + the body => requries special handling
        elseif type == EntityType.ENTITY_THE_LAMB then
            if self.LAMB_KILL and self.LAMB_BODY_KILL then
                self:sendBossClearReward(self.bosses.LAMB)
            end
            return
            -- Dogma uses Variant == 2 for the 2nd phase
        elseif type == EntityType.ENTITY_DOGMA then
            if goal == 11 and entity.Variant == 2 then
                self:sendBossClearReward(self.bosses.DOGMA)
            end
            return
            -- Variant 0 is the final kill
        elseif type == EntityType.ENTITY_BEAST then
            if entity.Variant == 0 then
                self:sendBossClearReward(self.bosses.BEAST)
            end
            return
        elseif type == EntityType.ENTITY_MOTHER then
            if entity.Variant == 10 then
                self:sendBossClearReward(self.bosses.MOTHER)
            end
            return
        else
            if type == EntityType.ENTITY_MOMS_HEART then
                self:sendBossClearReward(self.bosses.MOMS_HEART)
            elseif type == EntityType.ENTITY_MEGA_SATAN_2 then
                self:sendBossClearReward(self.bosses.MEGA_SATAN)
            elseif type == EntityType.ENTITY_HUSH then
                self:sendBossClearReward(self.bosses.HUSH)
            elseif type == EntityType.ENTITY_ULTRA_GREED then
                self:sendBossClearReward(self.bosses.ULTRA_GREED)
            elseif type == EntityType.ENTITY_DELIRIUM then
                self:sendBossClearReward(self.bosses.DELIRIUM)
            elseif type == EntityType.ENTITY_MOM then
                self:sendBossClearReward(self.bosses.MOM)
            end
            return
        end
    end
    function self.onPostNewLevel()
        local stage = self:getStageNum()
        if self.FURTHEST_FLOOR < stage then
            self.FURTHEST_FLOOR = stage
            self:setPersistentInfoFurthestFloor()
        end
        if self.LAST_FLOOR ~= stage then
            self.LAST_FLOOR = stage
            self.ITEM_QUEUE_CURRENT_MAX = stage * self.ITEM_QUEUE_MAX_PER_FLOOR
        end
    end
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, self.onPostGameStarted)
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_RENDER, self.onPostRender)
    self.MOD_REF:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, self.onPreGameExit)
    self.MOD_REF:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, self.onPrePickupCollision)
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, self.onPostPEffectUpdate)
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, self.onPostEntityKill)
    self.MOD_REF:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, self.onPreSpawnClearAward)
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, self.onPostNewLevel)
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
        [15] = {},
        [16] = {EntityType.ENTITY_MOMS_HEART, EntityType.ENTITY_ISAAC, EntityType.ENTITY_SATAN,
                EntityType.ENTITY_THE_LAMB, EntityType.ENTITY_MEGA_SATAN_2, EntityType.ENTITY_HUSH,
                EntityType.ENTITY_DOGMA, EntityType.ENTITY_BEAST, EntityType.ENTITY_MOTHER, EntityType.ENTITY_DELIRIUM},
        [17] = {EntityType.ENTITY_MOMS_HEART, EntityType.ENTITY_ISAAC, EntityType.ENTITY_SATAN,
                EntityType.ENTITY_THE_LAMB, EntityType.ENTITY_MEGA_SATAN_2, EntityType.ENTITY_HUSH,
                EntityType.ENTITY_DOGMA, EntityType.ENTITY_BEAST, EntityType.ENTITY_MOTHER, EntityType.ENTITY_DELIRIUM}
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
        [15] = "Required locations",
        [16] = "Full Notes",
        [17] = "Note Marks"
    }
    self.NOTE_TYPES = {
        HEART = 0,
        CROSS = 1,
        POLAROID = 2,
        INVERTED_CROSS = 3,
        NEGATIVE = 4,
        BRIMSTONE = 5,
        STAR = 6,
        HUSHS_FACE = 7,
        -- CENT_SIGN = 8,
        WRINKLED_PAPER = 9,
        KNIFE = 10,
        DADS_NOTE = 11
    }
    self.NOTE_CHARS = {
        [0] = {PlayerType.PLAYER_ISAAC},
        [1] = {PlayerType.PLAYER_MAGDALENE},
        [2] = {PlayerType.PLAYER_CAIN},
        [3] = {PlayerType.PLAYER_JUDAS, PlayerType.PLAYER_BLACKJUDAS},
        [4] = {PlayerType.PLAYER_BLUEBABY},
        [5] = {PlayerType.PLAYER_EVE},
        [6] = {PlayerType.PLAYER_SAMSON},
        [7] = {PlayerType.PLAYER_AZAZEL},
        [8] = {PlayerType.PLAYER_LAZARUS, PlayerType.PLAYER_LAZARUS2},
        [9] = {PlayerType.PLAYER_EDEN},
        [10] = {PlayerType.PLAYER_THELOST},
        [11] = {PlayerType.PLAYER_LILITH},
        [12] = {PlayerType.PLAYER_KEEPER},
        [13] = {PlayerType.PLAYER_APOLLYON},
        [14] = {PlayerType.PLAYER_THEFORGOTTEN, PlayerType.PLAYER_THESOUL},
        [15] = {PlayerType.PLAYER_BETHANY},
        [16] = {PlayerType.PLAYER_JACOB, PlayerType.PLAYER_ESAU},
        [17] = {PlayerType.PLAYER_ISAAC_B},
        [18] = {PlayerType.PLAYER_MAGDALENE_B},
        [19] = {PlayerType.PLAYER_CAIN_B},
        [20] = {PlayerType.PLAYER_JUDAS_B},
        [21] = {PlayerType.PLAYER_BLUEBABY_B},
        [22] = {PlayerType.PLAYER_EVE_B},
        [23] = {PlayerType.PLAYER_SAMSON_B},
        [24] = {PlayerType.PLAYER_AZAZEL_B},
        [25] = {PlayerType.PLAYER_LAZARUS_B, PlayerType.PLAYER_LAZARUS2_B},
        [26] = {PlayerType.PLAYER_EDEN_B},
        [27] = {PlayerType.PLAYER_THELOST_B},
        [28] = {PlayerType.PLAYER_LILITH_B},
        [29] = {PlayerType.PLAYER_KEEPER_B},
        [30] = {PlayerType.PLAYER_APOLLYON_B},
        [31] = {PlayerType.PLAYER_THEFORGOTTEN_B, PlayerType.PLAYER_THESOUL_B},
        [32] = {PlayerType.PLAYER_BETHANY_B},
        [33] = {PlayerType.PLAYER_JACOB_B, PlayerType.PLAYER_JACOB2_B}
    }

    self.bosses = {
      MOM = 0,
      MOMS_HEART = 1,
      ISAAC = 3,
      SATAN = 4,
      BLUE_BABY = 6,
      LAMB = 7,
      MEGA_SATAN = 8,
      BOSS_RUSH = 9,
      HUSH = 10,
      DOGMA = 11,
      BEAST = 12,
      MOTHER = 13,
      DELIRIUM = 14,
      ULTRA_GREED = -1
    }

    self.killed_bosses = {}

    self.bossRewardAmounts = { -- Name = {{Direct Goals}, Amount of items to send}, 
        [self.bosses.MOM] = 1,
        [self.bosses.BOSS_RUSH] = 2,
        [self.bosses.MOMS_HEART] = 2,
        [self.bosses.ISAAC] = 3,
        [self.bosses.SATAN] = 3,
        [self.bosses.HUSH] = 3,
        [self.bosses.BLUE_BABY] = 4,
        [self.bosses.LAMB] = 5,
        [self.bosses.MEGA_SATAN] = 5,
        [self.bosses.DELIRIUM] = 5,
        [self.bosses.MOTHER] = 5
    }

    self.bossToNoteType = {
        [self.bosses.BOSS_RUSH] = self.NOTE_TYPES.STAR,
        [self.bosses.ISAAC] = self.NOTE_TYPES.CROSS,
        [self.bosses.BLUE_BABY] = self.NOTE_TYPES.POLAROID,
        [self.bosses.SATAN] = self.NOTE_TYPES.INVERTED_CROSS,
        [self.bosses.BEAST] = self.NOTE_TYPES.DADS_NOTE,
        [self.bosses.MOTHER] = self.NOTE_TYPES.KNIFE,
        [self.bosses.LAMB] = self.NOTE_TYPES.NEGATIVE,
        [self.bosses.MOMS_HEART] = self.NOTE_TYPES.HEART,
        [self.bosses.MEGA_SATAN] = self.NOTE_TYPES.BRIMSTONE,
        [self.bosses.HUSH] = self.NOTE_TYPES.HUSHS_FACE,
        [self.bosses.ULTRA_GREED] = self.NOTE_TYPES.CENT_SIGN,
        [self.bosses.DELIRIUM] = self.NOTE_TYPES.WRINKLED_PAPER
    }
    
    self.LAMB_KILL = false
    self.LAMB_BODY_KILL = false
    -- double pickup fix related
    self.PICKUP_TIMER = 0
    -- global AP info
    self.LAST_RECEIVED_ITEM_INDEX = -1
    self.CUR_ITEM_STEP_VAL = 0
    self.CONNECTION_INFO = nil
    self.ROOM_INFO = nil
    self.MESSAGE_QUEUE = {}
    self.ITEM_QUEUE = {}
    self.ITEM_QUEUE_COUNTER = 0
    self.ITEM_QUEUE_CURRENT_MAX = 0
    self.ITEM_QUEUE_MAX_PER_FLOOR = 0
    self.FURTHEST_FLOOR = 1
    self.LAST_FLOOR = 1
    self.JUST_STARTED = false
    self.JUST_STARTED_TIMER = 0
    self.TRAP_QUEUE = {}
    self.TRAP_QUEUE_TIMER = 0
    self.SPAWN_QUEUE = {}
    self.SPAWN_QUEUE_TIMER = 0
    self.DEATH_CAUSE = "unknown"
    self.LAST_DEATH_LINK_TIME = nil
    self.LAST_DEATH_LINK_RECV = nil -- ToDo: Implement?
    self.NOTE_INFO = {}
    self.COMPLETED_NOTES = 0
    self.COMPLETED_NOTE_MARKS = 0
    print("called AP:init", 4, "end")
end

-- AP util funcs
function AP:collectItem(item)
    local id = item.item
    local roomDesc = Game():GetLevel():GetCurrentRoomDesc().Data
    if roomDesc.Name == "Beast Room" then -- dont receive items in the beast room
        return
    end
    if self.JUST_STARTED and self.SLOT_DATA.splitStartItems and self.SLOT_DATA.splitStartItems > 0 then
        self:addToItemQueue(id)
        return
    end
    local item_impl = AP.ITEM_IMPLS[id]
    if item_impl == nil or type(item_impl) ~= 'function' then
        print("!!! received unknown item id  !!!", id)
        return
    end
    item_impl(self)
end
function AP:clearLocations(amount)
    amount = amount or 1
    if amount > #self.AP_CLIENT.missing_locations then
        amount = #self.AP_CLIENT.missing_locations
    end
    local ids = {}
    table.move(self.AP_CLIENT.missing_locations, 1, amount, 1, ids)
    dbg_log("clearLocations" .. dump_table(ids) .. " " .. tostring(amount) .. " " ..
                tostring(#self.AP_CLIENT.missing_locations))
    self:sendLocationsCleared(ids)
end

function AP:attemptSendGoalReached()
    local goal = tonumber(self.SLOT_DATA.goal)
    if #self.AP_CLIENT.checked_locations >= tonumber(self.SLOT_DATA.requiredLocations) then
        self:sendGoalReached()
    elseif goal == 16 or goal == 17 then
        self:addMessage({
            parts = {{
                msg = "You have enough note marks to beat the game but are still missing required locations.",
                color = COLORS.GREEN
            }}
        })
    end
end

function AP:sendBossClearReward(boss)
    -- dbg_log("AP:sendBossClearReward"..tostring(boss)..tostring(self.killed_bosses[boss]))
    if self.killed_bosses[boss] then -- certain bosses "die" multiple times. This is stopped by keeping track of them in a list.
        return
    end
    
    self.killed_bosses[boss] = true

    local goal = tonumber(self.SLOT_DATA.goal)
    -- dbg_log("AP:sendBossClearReward"..tostring(goal))
    if goal == 16 or goal == 17 then
        if self.bossToNoteType[boss] ~= nil then
          -- dbg_log("AP:sendBossClearReward noteinfo "..tostring(self.bossToNoteType[boss]))
          self:setPersistentNoteInfo(self.bossToNoteType[boss], Isaac.GetPlayer():GetPlayerType(), self:isHardMode())
        end
    else
      if boss == goal then -- The boss enum has been set up in such a way that the values of bosses match up with their goals
          self:attemptSendGoalReached()
      elseif goal == 2 and (boss == self.bosses.ISAAC or boss == self.bosses.SATAN) then
          self:attemptSendGoalReached()
      elseif goal == 5 and (boss == self.bosses.BLUE_BABY or boss == self.bosses.LAMB) then
          self:attemptSendGoalReached()
      end
    end

    if self.bossRewardAmounts[boss] ~= nil and self.SLOT_DATA.additionalBossRewards then
        -- dbg_log("AP:sendBossClearReward boss rewards")
        self:clearLocations(self.bossRewardAmounts[boss])
    end
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
function AP:isHardMode()
    -- print("AP:isHardMode")
    local diff = Game().Difficulty
    return diff == 1 or diff == 3
end
-- Note info
function AP:setupLocalNoteInfo()
    -- print("AP:setupLocalNoteInfo")
    self.NOTE_INFO = {}
    for k, v in pairs(self.NOTE_CHARS) do
        self.NOTE_INFO[k] = {}
        for k2, v2 in pairs(self.NOTE_TYPES) do
            self.NOTE_INFO[k][v2] = false
        end
    end
    -- print("AP:setupLocalNoteInfo",2, dump_table(self.NOTE_INFO))
end
function AP:syncNoteInfoFromDict(dict)
    -- print("AP:syncNoteInfoFromDict", dump_table(dict), dump_table(self.NOTE_INFO))
    local goal = tonumber(self.SLOT_DATA.goal)
    if goal ~= 16 and goal ~= 17 then
        return
    end
    for k, v in pairs(dict) do
        if self:getTypeFromDataStorageKey(k) == "note" then
            local splitResult = split(k, "_")
            if #splitResult >= 6 then
                local note_type = tonumber(splitResult[5])
                local note_char = tonumber(splitResult[6])
                self.NOTE_INFO[note_char][note_type] = (v == 1)
            end
        end
    end
    self:checkNoteInfo()
end
function AP:countNoteMarksForPlayerType(player_type)
    local char = -1
    for k, v in pairs(self.NOTE_CHARS) do
        if tbl_contains(v, player_type) then
            char = k
            break
        end
    end
    if char == -1 then
        return
    end
    -- print("AP:countNoteMarksForPlayerType", char, dump_table(self.NOTE_INFO))
    if not self.NOTE_INFO[char] then
        return 0
    end
    local count = 0
    for _, v in pairs(self.NOTE_TYPES) do
        if self.NOTE_INFO[char][v] then
            count = count + 1
        end
    end
    return count
end
function AP:checkNoteInfo()
    -- print("AP:checkNoteInfo", 1, dump_table(self.NOTE_INFO))
    local reqNoteAmount = tonumber(self.SLOT_DATA.fullNoteAmount)
    local reqNoteMarksAmount = tonumber(self.SLOT_DATA.noteMarksAmount)
    local goal = tonumber(self.SLOT_DATA.goal)
    if goal ~= 16 and goal ~= 17 then
        return
    end
    local count = 0
    local countMarks = 0
    for k, v in pairs(self.NOTE_CHARS) do
        if self.NOTE_INFO[k] then
            local complete = true
            for k2, v2 in pairs(self.NOTE_TYPES) do
                if not self.NOTE_INFO[k][v2] and goal == 16 then
                    complete = false
                    break
                elseif self.NOTE_INFO[k][v2] and goal == 17 then
                    countMarks = countMarks + 1
                end
            end
            if complete then
                count = count + 1
                if count >= reqNoteAmount and goal == 16 then
                    break
                end
            end
        end
    end
    self.COMPLETED_NOTES = count
    self.COMPLETED_NOTE_MARKS = countMarks
    if ((count >= reqNoteAmount and goal == 16) or (countMarks >= reqNoteMarksAmount and goal == 17)) then
        self:attemptSendGoalReached()
    end
end

-- Furthest floor
function AP:getStageNum()
    local stage = Game():GetLevel():GetStage()
    -- we hard limit stage num at 12 so home and the void will always receive all items
    if stage == LevelStage.STAGE8 then
        stage = 12
    end
    return stage
end
function AP:syncFurthestFloor(dict)
    local team = tonumber(self.CONNECTION_INFO.team)
    local slot = tonumber(self.CONNECTION_INFO.slot)
    local key = "tobir_" .. team .. "_" .. slot .. "_floor"
    -- print("AP:syncFurthestFloor", dump_table(dict))
    if dict[key] == nil then
        return
    end
    self.FURTHEST_FLOOR = dict[key]
    self.ITEM_QUEUE_COUNTER = 0
    self.ITEM_QUEUE_MAX_PER_FLOOR = math.ceil(#self.ITEM_QUEUE / self.FURTHEST_FLOOR)
    self.ITEM_QUEUE_CURRENT_MAX = self:getStageNum() * self.ITEM_QUEUE_MAX_PER_FLOOR
    -- print("AP:syncFurthestFloor", self.FURTHEST_FLOOR, self.ITEM_QUEUE_MAX_PER_FLOOR, #self.ITEM_QUEUE)
end

-- Queues
function AP:addToSpawnQueue(type, variant, subType, timeToNextSpawn)
    table.insert(self.SPAWN_QUEUE, {
        type = type,
        variant = variant,
        subType = subType,
        timeToNextSpawn = timeToNextSpawn
    })
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
function AP:addToTrapQueue(trapId, dur)
    if not dur then
        dur = 30
    end
    table.insert(self.TRAP_QUEUE, {
        id = trapId,
        dur = dur
    })
end
function AP:advanceTrapQueue()
    if self.TRAP_QUEUE_TIMER > 0 then
        self.TRAP_QUEUE_TIMER = self.TRAP_QUEUE_TIMER - 1
        return
    end
    if #self.TRAP_QUEUE < 1 then
        return
    end
    local trap = self.TRAP_QUEUE[1]
    table.remove(self.TRAP_QUEUE, 1)
    self.TRAP_QUEUE_TIMER = trap.dur
    local trap_impl = AP.TRAP_IMPLS[trap.id]
    if trap_impl == nil or type(trap_impl) ~= 'function' then
        print("!!! received unknown trap id  !!!", id)
        return
    end
    trap_impl(self)
end
function AP:addToItemQueue(item, pos)
    pos = pos or #self.ITEM_QUEUE + 1
    table.insert(self.ITEM_QUEUE, pos, item)
end
function AP:advanceItemQueue()
    if #self.ITEM_QUEUE < 1 then
        return
    end
    if self.ITEM_QUEUE_COUNTER >= self.ITEM_QUEUE_CURRENT_MAX then
        return
    end
    print("AP:advanceItemQueue", self.FURTHEST_FLOOR, self.ITEM_QUEUE_COUNTER, self.ITEM_QUEUE_MAX_PER_FLOOR,
        self.ITEM_QUEUE_CURRENT_MAX, #self.ITEM_QUEUE)
    local randIndex = self.RNG:RandomInt(#self.ITEM_QUEUE) + 1
    local id = self.ITEM_QUEUE[randIndex]
    table.remove(self.ITEM_QUEUE, randIndex)
    local item_impl = AP.ITEM_IMPLS[id]
    if item_impl == nil or type(item_impl) ~= 'function' then
        print("!!! received unknown item id  !!!", id)
        return
    end
    item_impl(self)
    self.ITEM_QUEUE_COUNTER = self.ITEM_QUEUE_COUNTER + 1
end
-- Timers
function AP:runJustStartedTimer()
    if not self.JUST_STARTED then
        return
    end
    if self.JUST_STARTED_TIMER <= 0 then
        self.JUST_STARTED = false
        return
    end
    self.JUST_STARTED_TIMER = self.JUST_STARTED_TIMER - 1
end
function AP:runPickupTimer()
    if self.PICKUP_TIMER > 0 then
        self.PICKUP_TIMER = self.PICKUP_TIMER - 1
    end
end

AP()