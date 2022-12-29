local HttpService       = game:GetService("HttpService")
local SaveManager       = {}

SaveManager.Folder      = "LinoriaLibSave"
SaveManager.Ignore      = {}
SaveManager.Parser      = {
	Toggle = {
		Save = function(Index, Object) 
			return { type = "Toggle", idx = Index, value = Object.Value } 
		end,

		Load = function(Index, Data)
			if Toggles[Index] then 
				Toggles[Index]:SetValue(Data.value)
			end
		end
	},

	Slider = {
		Save = function(Index, Object)
			return { type = "Slider", idx = Index, value = tostring(Object.Value) }
		end,

		Load = function(Index, Data)
			if Options[Index] then 
				Options[Index]:SetValue(Data.value)
			end
		end
	},

	Dropdown = {
		Save = function(Index, Object)
			return { type = "Dropdown", idx = Index, value = Object.Value, mutli = Object.Multi }
		end,

		Load = function(Index, Data)
			if Options[Index] then 
				Options[Index]:SetValue(Data.value)
			end
		end
	},
	ColorPicker = {
		Save = function(Index, Object)
			return { type = "ColorPicker", idx = Index, value = Object.Value:ToHex() }
		end,

		Load = function(Index, Data)
			if Options[Index] then 
				Options[Index]:SetValueRGB(Color3.fromHex(Data.value))
			end
		end
	},

	KeyPicker = {
		Save = function(Index, Object)
			return { type = "KeyPicker", idx = Index, mode = Object.Mode, key = Object.Value }
		end,

		Load = function(Index, Data)
			if Options[Index] then 
				Options[Index]:SetValue({ Data.key, Data.mode })
			end
		end
	},

	Input = {
		Save = function(Index, Object)
			return { type = "Input", idx = Index, text = Object.Value }
		end,

		Load = function(Index, Data)
			if Options[Index] and type(Data.text) == "string" then
				Options[Index]:SetValue(Data.text)
			end
		end
	},
}

function SaveManager:SetIgnoreIndexes(List)
	for i, Key in next, List do
		self.Ignore[Key] = true
	end
end

function SaveManager:SetFolder(Folder)
	self.Folder = Folder
	self:BuildFolderTree()
end

function SaveManager:Save(Name)
	local FullPath 	= self.Folder .. "/Settings/" .. Name .. ".json"

	local Data = {
		Objects = {}
	}

	for Index, Toggle in next, Toggles do
		if self.Ignore[Index] then continue end

		table.insert(Data.Objects, self.Parser[Toggle.Type].Save(Index, Toggle))
	end

	for Index, Option in next, Options do
		if not self.Parser[Option.Type] then continue end
		if self.Ignore[Index] then continue end

		table.insert(Data.Objects, self.Parser[Option.Type].Save(Index, Option))
	end	

	local Success, Encoded = pcall(HttpService.JSONEncode, HttpService, Data)

	if not Success then
		return false, "Failed to encode data."
	end

	writefile(FullPath, Encoded)

	return true
end

function SaveManager:Load(Name)
	local File 	= self.Folder .. "/Settings/" .. Name .. ".json"
	if not isfile(File) then return false, "Invalid file." end

	local Success, Decoded = pcall(HttpService.JSONDecode, HttpService, readfile(File))

	if not Success then return false, "Decode error." end

	for Index, Option in next, Decoded.Objects do
		if self.Parser[Option.type] then
			self.Parser[Option.type].Load(Option.idx, Option)
		end
	end

	return true
end

function SaveManager:IgnoreThemeSettings()
	self:SetIgnoreIndexes({ 
		"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
		"ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName",
	})
end

function SaveManager:BuildFolderTree()
	local Paths = {
		self.Folder,
		self.Folder .. "/Themes",
		self.Folder .. "/Settings"
	}

	for i = 1, #Paths do
		local String	= Paths[i]

		if not isfolder(String) then
			makefolder(String)
		end
	end
end

function SaveManager:RefreshConfigList()
    local List  = listfiles(self.Folder .. "/Settings")
    local Out   = {}

    for i = 1, #List do
        local File = List[i]

        if File:sub(-5) == ".json" then
            local Pos   = File:find(".json", 1, true)
            local Start = Pos
            local Char  = File:sub(Pos, Pos)

            while Char ~= "/" and Char ~= "\\" and Char ~= "" do
                Pos = Pos - 1
                Char = File:sub(Pos, Pos)
            end

            if Char == "/" or Char == "\\" then
                table.insert(Out, File:sub(Pos + 1, Start - 1))
            end
        end
    end
        
    return Out
end

function SaveManager:SetLibrary(Lib)
    self.Library = Lib
end

function SaveManager:LoadAutoloadConfig()
    if isfile(self.Folder .. "/Settings/AutoLoad.txt") then
        local Name = readfile(self.Folder .. "/Settings/AutoLoad.txt")
        local Success, Error = self:Load(Name)

        if not Success then
            return self.Library:Notify("[Fondra]: Failed to load autoload config: " .. Error)
        end

        self.Library:Notify(string.format("[Fondra]: Auto loaded config %q", Name))
    end
end

function SaveManager:BuildConfigSection(Tab)
    assert(self.Library, "Must set SaveManager.Library")

    local GroupBox = Tab:AddRightGroupbox("Configuration")

    GroupBox:AddDropdown("SaveManager_ConfigList", { Text = "Config list", Values = self:RefreshConfigList(), AllowNull = true })
    GroupBox:AddInput("SaveManager_ConfigName", { Text = "Config name" })

    GroupBox:AddDivider()

    GroupBox:AddButton("Create config", function()
        local Name = Options.SaveManager_ConfigName.Value

        if Name:gsub(" ", "") == "" then 
            return self.Library:Notify("[Fondra]: Invalid config name. [Empty]", 2)
        end

        local Success, Error = self:Save(Name)

        if not Success then
            return self.Library:Notify("[Fondra]: Failed to save config: " .. Error)
        end

        self.Library:Notify(string.format("[Fondra]: Created config %q", Name))

        Options.SaveManager_ConfigList.Values = self:RefreshConfigList()
        Options.SaveManager_ConfigList:SetValues()
        Options.SaveManager_ConfigList:SetValue(nil)
    end):AddButton("Load config", function()
        local Name = Options.SaveManager_ConfigList.Value
        local Success, Error = self:Load(Name)

        if not Success then
            return self.Library:Notify("[Fondra]: Failed to load config: " .. Error)
        end

        self.Library:Notify(string.format("[Fondra]: Loaded config %q", Name))
    end)

    GroupBox:AddButton("Overwrite config", function()
        local Name = Options.SaveManager_ConfigList.Value
        local Success, Error = self:Save(Name)

        if not Success then
            return self.Library:Notify("[Fondra]: Failed to overwrite config: " .. Error)
        end

        self.Library:Notify(string.format("[Fondra]: Overwrote config %q", Name))
    end)
    
    GroupBox:AddButton("Autoload config", function()
        local Name = Options.SaveManager_ConfigList.Value
        writefile(self.Folder .. "/Settings/AutoLoad.txt", Name)
        SaveManager.AutoloadLabel:SetText("Current autoload config: " .. Name)
        self.Library:Notify(string.format("[Fondra]: Set %q to auto load", Name))
    end)

    GroupBox:AddButton("Refresh config list", function()
        Options.SaveManager_ConfigList.Values = self:RefreshConfigList()
        Options.SaveManager_ConfigList:SetValues()
        Options.SaveManager_ConfigList:SetValue(nil)
    end)

    GroupBox:AddDivider()

    SaveManager.AutoloadLabel = GroupBox:AddLabel("Current autoload config: None", true)

    GroupBox:AddDivider()

    GroupBox:AddToggle("ToggleWatermark", {
        Text = "Toggle Watermark",
        Tooltip = "Name is self explanitory.",
        Default = true
    })

    GroupBox:AddToggle("ToggleKeybindsFrame", {
        Text = "Toggle Keybinds Frame",
        Tooltip = "Shows your keybind on a ui.",
        Default = true
    })
    
    GroupBox:AddToggle("ToggleFondraChat", {
        Text = "Fondra Communication",
        Tooltip = "Talk with other fondra users.",
        Default = true
    })

    GroupBox:AddDivider()

    GroupBox:AddDropdown("WatermarkCustomizationDropdown", {
        Text = "Watermark Customizations",
        Tooltip = "Watermark Customizations.",
        Values = { "Time", "Date", "Elapsed", "FPS", "Ping", "User" },
        
        Default = 5,
        Multi = true
    })

    GroupBox:AddDivider()

    GroupBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "LeftAlt", NoUI = false, Text = "Menu keybind" }) 

    Toggles.ToggleWatermark:OnChanged(function()
        self.Library:SetWatermarkVisibility(Toggles.ToggleWatermark.Value)
        self.Library:Notify(string.format("[Fondra]: Watermark %s", Toggles.ToggleWatermark.Value and "Enabled." or "Disabled."))
    end)

    Toggles.ToggleKeybindsFrame:OnChanged(function()
        self.Library.KeybindFrame.Visible = Toggles.ToggleKeybindsFrame.Value
        self.Library:Notify(string.format("[Fondra]: Keybind Frame %s", Toggles.ToggleWatermark.Value and "Enabled." or "Disabled."))
    end)

    Toggles.ToggleFondraChat:OnChanged(function()
        self.Library:Notify(string.format("[Fondra]: Fondra Communication %s", Toggles.ToggleFondraChat.Value and "Enabled." or "Disabled."))
    end)

    Options.WatermarkCustomizationDropdown:OnChanged(function()
        local CurrentString = "<b>Fondra</b>"

        if Options.WatermarkCustomizationDropdown.Value.Time then
            CurrentString = CurrentString.." - {Time}"
        end

        if Options.WatermarkCustomizationDropdown.Value.Date then
            CurrentString = CurrentString.." - {Date}"
        end

        if Options.WatermarkCustomizationDropdown.Value.Elapsed then
            CurrentString = CurrentString.." - {ElapsedTime}"
        end

        if Options.WatermarkCustomizationDropdown.Value.FPS then
            CurrentString = CurrentString.." - {FPS}"
        end

        if Options.WatermarkCustomizationDropdown.Value.Ping then
            CurrentString = CurrentString.." - {Ping}"
        end

        if Options.WatermarkCustomizationDropdown.Value.User then
            CurrentString = CurrentString.." - {Username}"
        end

        self.Library:SetWatermark(CurrentString)
    end)

    if isfile(self.Folder .. "/Settings/AutoLoad.txt") then
        local Name = readfile(self.Folder .. "/Settings/AutoLoad.txt")
        SaveManager.AutoloadLabel:SetText("Current AutoLoad config: " .. Name)
    end
    
    SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })

    self.Library.ToggleKeybind = Options.MenuKeybind
end

SaveManager:BuildFolderTree()

return SaveManager
