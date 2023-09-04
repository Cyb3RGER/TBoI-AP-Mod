AP.CONN_SETTINGS_HEADER = "Server"
AP.OTHER_SETTINGS_HEADER = "Settings"

function AP:initMCM()
    if ModConfigMenu == nil then
        return
    end
    print("called AP:initMCM", 1)
    self.UNLOCK_TYPING = false
    self.TYPING_TARGET = nil
    self.CURRENT_TYPING_STRING = ""
    self.PRESSED_BUTTONS = {}
    self.PREV_PRESSED_BUTTONS = {}
    self.WAIT_TYPING_ENTER_EXIT = 0
    self.SPECIAL_KEY_MAPPING = {
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
    self.SPECIAL_KEY_MAPPING_UPPER = {
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
    self.TOGGLE_LOWERCASE = false
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.OTHER_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return nil
        end,
        Display = function()
            return "Connect"
        end,
        OnChange = function(v)
            self:connectAP()
        end,
        Info = {"Click this to reconnect to the AP Server"}
    })
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.OTHER_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return nil
        end,
        Display = function()
            return "List Hints"
        end,
        OnChange = function(v)            
            self:sendHintCommand(false, nil)
        end,
        Info = {"Click this to list hints for your world"}
    })
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.OTHER_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return nil
        end,
        Display = function()
            return "Get a Hint"
        end,
        OnChange = function(v)            
            self:sendHintCommand(false, "Any Progression")
        end,
        Info = {"Click this to a hint for any progression item from your world"}
    })
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.OTHER_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return nil
        end,
        Display = function()
            return "Collect"
        end,
        OnChange = function(v)            
            self:collectSlot()
        end,
        Info = {"Click this to collect all checks for this world"}
    })
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.OTHER_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return self.SHOULD_AUTO_CONNECT
        end,
        Display = function()
            local str = "Off"
            if self.SHOULD_AUTO_CONNECT then
                str = "On"
            end
            return "Auto-Connect: "..str
        end,
        OnChange = function(v)            
            self.SHOULD_AUTO_CONNECT = not self.SHOULD_AUTO_CONNECT
            self:saveSettings()
        end,
        Info = {"Should AP Auto-Connect on run start?"}
    })
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.OTHER_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return nil
        end,
        Display = function()
            return "Release"
        end,
        OnChange = function(v)            
            self:releaseSlot()
        end,
        Info = {"Click this to release all checks from this world"}
    })
    self.TextScales = {0.25, 0.5, 1, 1.1, 1.2, 1.5}
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.OTHER_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return tbl_find_index(self.TextScales, self.INFO_TEXT_SCALE)
        end,
        Minimum = 1,
        Maximum = #self.TextScales,
        Display = function()
            return "Text Scale: " .. self.INFO_TEXT_SCALE
        end,
        OnChange = function(v)
            self.INFO_TEXT_SCALE = self.TextScales[v]
            self:saveSettings()
        end,
        Info = {"Adjust the Text Size of the AP mod"}
    })
    self.HudOffsets = {0, 5, 10, 15, 20, 25, 30}
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.OTHER_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return tbl_find_index(self.HudOffsets, self.HUD_OFFSET)
        end,
        Minimum = 1,
        Maximum = #self.HudOffsets,
        Display = function()
            return "HUD Offset: " .. self.HUD_OFFSET
        end,
        OnChange = function(v)
            self.HUD_OFFSET = self.HudOffsets[v]
            self:saveSettings()
        end,
        Info = {"Adjust where the AP Text is placed on the HUD"}
    })
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.OTHER_SETTINGS_HEADER, {
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
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.CONN_SETTINGS_HEADER, {
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
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.CONN_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return nil
        end,
        Display = function()
            local text = "Change AP Host Address"
            if self.UNLOCK_TYPING and self.TYPING_TARGET == "HOST_ADDRESS" then
                text = "Typing: " .. self.CURRENT_TYPING_STRING
            end
            return text
        end,
        OnChange = function(v)
            if self.WAIT_TYPING_ENTER_EXIT > 0 then
                return
            end
            self.CURRENT_TYPING_STRING = self.HOST_ADDRESS
            self.TYPING_TARGET = "HOST_ADDRESS"
            self.PREV_PRESSED_BUTTONS = {}
            self.WAIT_TYPING_ENTER_EXIT = 30
            self.UNLOCK_TYPING = true
        end,
        Info = {"ENTER = quit & save, ESC = quit,$newline$newlineSHIFT = toggle case"}
    })
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.CONN_SETTINGS_HEADER, {
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
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.CONN_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return nil
        end,
        Display = function()
            local text = "Change AP Host Port"
            if self.UNLOCK_TYPING and self.TYPING_TARGET == "HOST_PORT" then
                text = "Typing: " .. self.CURRENT_TYPING_STRING
            end
            return text
        end,
        OnChange = function(v)
            if self.WAIT_TYPING_ENTER_EXIT > 0 then
                return
            end
            self.CURRENT_TYPING_STRING = self.HOST_PORT
            self.TYPING_TARGET = "HOST_PORT"
            self.PREV_PRESSED_BUTTONS = {}
            self.WAIT_TYPING_ENTER_EXIT = 30
            self.UNLOCK_TYPING = true
        end,
        Info = {"ENTER = quit & save, ESC = quit,$newline$newlineSHIFT = toggle case"}
    })
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.CONN_SETTINGS_HEADER, {
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
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.CONN_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return nil
        end,
        Display = function()
            local text = "Change AP Slot Name"
            if self.UNLOCK_TYPING and self.TYPING_TARGET == "SLOT_NAME" then
                text = "Typing: " .. self.CURRENT_TYPING_STRING
            end
            return text
        end,
        OnChange = function(v)
            if self.WAIT_TYPING_ENTER_EXIT > 0 then
                return
            end
            self.CURRENT_TYPING_STRING = self.SLOT_NAME
            self.TYPING_TARGET = "SLOT_NAME"
            self.PREV_PRESSED_BUTTONS = {}
            self.WAIT_TYPING_ENTER_EXIT = 30
            self.UNLOCK_TYPING = true
        end,
        Info = {"ENTER = quit & save, ESC = quit,$newline$newlineSHIFT = toggle case"}
    })
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.CONN_SETTINGS_HEADER, {
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
    ModConfigMenu.AddSetting(self.MOD_NAME, AP.CONN_SETTINGS_HEADER, {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function()
            return nil
        end,
        Display = function()
            local text = "Change AP Password"
            if self.UNLOCK_TYPING and self.TYPING_TARGET == "PASSWORD" then
                text = "Typing: " .. self.CURRENT_TYPING_STRING
            end
            return text
        end,
        OnChange = function(v)
            if self.WAIT_TYPING_ENTER_EXIT > 0 then
                return
            end
            self.CURRENT_TYPING_STRING = self.PASSWORD
            self.TYPING_TARGET = "PASSWORD"
            self.PREV_PRESSED_BUTTONS = {}
            self.WAIT_TYPING_ENTER_EXIT = 30
            self.UNLOCK_TYPING = true
        end,
        Info = {"ENTER = quit & save, ESC = quit,$newline$newlineSHIFT = toggle case"}
    })
    function self.onInputAction()
        self:trackTypingInput()
    end    
    function self.onPostRender()
        if self.WAIT_TYPING_ENTER_EXIT > 0 then
            self.WAIT_TYPING_ENTER_EXIT = self.WAIT_TYPING_ENTER_EXIT - 1
        end
    end
    self.MOD_REF:AddCallback(ModCallbacks.MC_INPUT_ACTION, self.onInputAction)
    self.MOD_REF:AddCallback(ModCallbacks.MC_POST_RENDER, self.onPostRender)
end
function AP:trackTypingInput()
    --print("self.trackTypingInput",0.1, InputHelper, ModConfigMenu)
    if not InputHelper or not ModConfigMenu then
        return
    end
    --print("self.trackTypingInput",0.2, self.UNLOCK_TYPING)   
    if not self.UNLOCK_TYPING then
        ModConfigMenu.ControlsEnabled = true
        return
    end
    --print("self.trackTypingInput",0.3, ModConfigMenu.IsVisible)
    if not ModConfigMenu.IsVisible then
        self.UNLOCK_TYPING = false
        return
    end
    ModConfigMenu.ControlsEnabled = false
    local receivedInput = false
    local endTyping = false
    --print("self.trackTypingInput",0.5, ModConfigMenu.ControlsEnabled)
    -- capture input
    self.PRESSED_BUTTONS = {}
    for i = 0, 4 do
        self.PRESSED_BUTTONS[i] = {}
        for j = 32, 400 do
            self.PRESSED_BUTTONS[i][j] = (InputHelper.KeyboardPressed(j, i) and 1 or 0)
            if self.PRESSED_BUTTONS[i][j] and self.PRESSED_BUTTONS[i][j] > 0 and not receivedInput then
                receivedInput = true
            end
        end
    end
    -- type input
    --print("self.trackTypingInput",1,receivedInput)
    if receivedInput then
        for i = 0, 4 do
            if self.PRESSED_BUTTONS[i] then
                for j = 32, 400 do
                    if self.PRESSED_BUTTONS[i][j] and self.PRESSED_BUTTONS[i][j] > 0 then
                        print("self.trackTypingInput",2,self.PRESSED_BUTTONS[i][j],self.PREV_PRESSED_BUTTONS[i][j])                                       
                    end
                    if self.PRESSED_BUTTONS[i][j] and self.PRESSED_BUTTONS[i][j] > 0 and
                        not (self.PREV_PRESSED_BUTTONS and self.PREV_PRESSED_BUTTONS[i] and self.PREV_PRESSED_BUTTONS[i][j] and
                            self.PREV_PRESSED_BUTTONS[i][j] > 0 and
                            (self.PREV_PRESSED_BUTTONS[i][j] < 900 or self.PREV_PRESSED_BUTTONS[i][j] % 100 ~= 0)) then
                        endTyping = self:typeKey(j)
                    end
                end
            end
        end
    end
    -- copy over captured input
    if not self.PREV_PRESSED_BUTTONS then
        self.PREV_PRESSED_BUTTONS = self.PRESSED_BUTTONS
    else
        for i = 0, 4 do
            if self.PRESSED_BUTTONS[i] then
                if not self.PREV_PRESSED_BUTTONS[i] then
                    self.PREV_PRESSED_BUTTONS[i] = self.PRESSED_BUTTONS[i]
                else
                    for j = 32, 400 do
                        if self.PRESSED_BUTTONS[i][j] > 0 then
                            if not self.PREV_PRESSED_BUTTONS[i][j] then
                                self.PREV_PRESSED_BUTTONS[i][j] = self.PRESSED_BUTTONS[i][j]
                            else
                                self.PREV_PRESSED_BUTTONS[i][j] = self.PREV_PRESSED_BUTTONS[i][j] + self.PRESSED_BUTTONS[i][j]
                            end
                        else
                            self.PREV_PRESSED_BUTTONS[i][j] = 0
                        end
                    end
                end
            end
        end
    end
    -- end typing
    if endTyping and self.WAIT_TYPING_ENTER_EXIT <= 0 then
        if self.TYPING_TARGET == "HOST_ADDRESS" then
            self.HOST_ADDRESS = self.CURRENT_TYPING_STRING
        elseif self.TYPING_TARGET == "HOST_PORT" then
            self.HOST_PORT = self.CURRENT_TYPING_STRING
        elseif self.TYPING_TARGET == "SLOT_NAME" then
            self.SLOT_NAME = self.CURRENT_TYPING_STRING
        elseif self.TYPING_TARGET == "PASSWORD" then            
            self.PASSWORD = self.CURRENT_TYPING_STRING
        end
        self.CURRENT_TYPING_STRING = ""
        self.TYPING_TARGET = nil
        self.UNLOCK_TYPING = false
        self.WAIT_TYPING_ENTER_EXIT = 30
        self:saveConnectionInfo()
    end
    return
end
function AP:typeKey(key)
    local keyName = InputHelper.KeyboardToString[key] or "Unknown"
    --print("self.typeKey", 1, key, keyName)
    if #keyName == 1 then
        if not self.TOGGLE_LOWERCASE then
            keyName = string.lower(keyName)
        end
        self.CURRENT_TYPING_STRING = self.CURRENT_TYPING_STRING .. keyName
    elseif self.TOGGLE_LOWERCASE and self.SPECIAL_KEY_MAPPING_UPPER[keyName] then
        self.CURRENT_TYPING_STRING = self.CURRENT_TYPING_STRING .. self.SPECIAL_KEY_MAPPING_UPPER[keyName]
    elseif self.SPECIAL_KEY_MAPPING[keyName] then
        self.CURRENT_TYPING_STRING = self.CURRENT_TYPING_STRING .. self.SPECIAL_KEY_MAPPING[keyName]
    elseif keyName == "BACKSPACE" then
        self.CURRENT_TYPING_STRING = self.CURRENT_TYPING_STRING:sub(1, #self.CURRENT_TYPING_STRING - 1)
    elseif keyName == "LEFT SHIFT" or keyName == "RIGHT SHIFT" or keyName == "CAPS LOCK" then
        self.TOGGLE_LOWERCASE = not self.TOGGLE_LOWERCASE
    elseif keyName == "ENTER" or keyName == "ESCAPE" or keyName == "TAB" or keyName == "END" then
        return true
    end
    return false
end




