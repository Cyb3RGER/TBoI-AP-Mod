local json = require('json')
-- settings util funcs
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
    modData.SHOULD_AUTO_CONNECT = self.SHOULD_AUTO_CONNECT
    self.MOD_REF:SaveData(json.encode(modData))
end
function AP:loadSettings()
    if self.MOD_REF:HasData() then
        local modData = json.decode(self.MOD_REF:LoadData())
        if modData ~= nil then
            if modData.DEBUG_MODE ~= nil then
                self.DEBUG_MODE = modData.DEBUG_MODE
            end
            if modData.INFO_TEXT_SCALE ~= nil then
                self.INFO_TEXT_SCALE = modData.INFO_TEXT_SCALE
            end
            if modData.HUD_OFFSET ~= nil then
                self.HUD_OFFSET = modData.HUD_OFFSET
            end
            if modData.SHOULD_AUTO_CONNECT ~= nil then
                self.SHOULD_AUTO_CONNECT = modData.SHOULD_AUTO_CONNECT
            end
        end
    end
end
function AP:loadOtherData(seed)
    if self.MOD_REF:HasData() then
        local modData = json.decode(self.MOD_REF:LoadData())
        dbg_log("loaded seed: " .. tostring(modData.SAVED_SEED))
        if modData ~= nil and modData.SAVED_SEED ~= nil and modData.SAVED_ITEM_INDEX ~= nil and
            modData.CUR_ITEM_STEP_VAL ~= nil and seed == modData.SAVED_SEED then
            self.LAST_RECEIVED_ITEM_INDEX = modData.SAVED_ITEM_INDEX
            self.CUR_ITEM_STEP_VAL = modData.CUR_ITEM_STEP_VAL
        else
            return false
        end
    end
    return true
end
function AP:saveOtherData(seed)
    dbg_log("saving seed: " .. tostring(seed))
    local modData = {}
    if self.MOD_REF:HasData() then
        modData = json.decode(self.MOD_REF:LoadData())
    end
    modData.SAVED_ITEM_INDEX = self.LAST_RECEIVED_ITEM_INDEX
    modData.SAVED_SEED = seed
    modData.CUR_ITEM_STEP_VAL = self.CUR_ITEM_STEP_VAL
    self.MOD_REF:SaveData(json.encode(modData))
end