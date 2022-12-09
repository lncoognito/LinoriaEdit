local HttpService = game:GetService("HttpService")
local SaveManager = {}

SaveManager.Folder = "LinoriaSaveFolder"
SaveManager.Ignore = {}
SaveManager.Parser = {
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
    }
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
    local FullPath = self.Folder .. "/settings/" .. Name .. ".json"

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
    local File = self.Folder .. "/settings/" .. Name .. ".json"

    if not isfile(File) then return false, "Invalid file." end

    local Success, Decoded = pcall(HttpService.JSONDecode, HttpService, readfile(File))

    if not Success then return false, "Decode error." end

    for i, Option in next, Decoded.objects do
        if self.Parser[Option.type] then
            self.Parser[Option.type].Load(Option.idx, Option)
        end
    end

    return true
end

function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({ "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", "ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName", })
end

function SaveManager:BuildFolderTree()
    local Paths = {
        self.Folder,
        self.Folder .. "/Themes",
        self.Folder .. "/Settings"
    }

    for i = 1, #Paths do
        local String = Paths[i]

        if not isfolder(String) then
            makefolder(String)
        end
    end
end

function SaveManager:RefreshConfigList()
    local List = listfiles(self.Folder .. "/Settings")
    local Out = {}

    for i = 1, #List do
        local File = List[i]

        if File:sub(-5) == ".json" then
            local Pos = File:find(".json", 1, true)
            local Start = Pos
            local Char = File:sub(Pos, Pos)

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

function SaveManager:SetLibrary(Library)
    self.Library = Library
end

function SaveManager:LoadAutoloadConfig()
    if isfile(self.Folder .. "/Settings/AutoLoad.txt") then
        local Name = readfile(self.Folder .. "/Settings/AutoLoad.txt")
        local Success, Error = self:Load(Name)

        if not Success then
            return self.Library:Notify(string.format("Failed to load autoload config. [%s]", Error))
        end

        self.Library:Notify(string.format("Auto loaded config %q", Name))
    end
end

function SaveManager:BuildConfigSection(Tab)
    assert(self.Library, "Must set SaveManager.Library")

    local Section = Tab:AddRightGroupbox("Configuration")

    Section:AddDropdown("SaveManager_ConfigList", { Text = "Config list", Values = self:RefreshConfigList(), AllowNull = true })
    Section:AddInput("SaveManager_ConfigName", { Text = "Config name" })

    section:AddDivider()

    Section:AddButton("Create config", function()
        local Name = Options.SaveManager_ConfigName.Value

        if Name:gsub(" ", "") == "" then 
            return self.Library:Notify("Invalid config name. [Empty]", 2)
        end

        local Success, Error = self:Save(Name)

        if not Success then
            return self.Library:Notify("Failed to save config: " .. Error)
        end

        self.Library:Notify(string.format("Created config %q", Name))

        Options.SaveManager_ConfigList.Values = self:RefreshConfigList()
        Options.SaveManager_ConfigList:SetValues()
        Options.SaveManager_ConfigList:SetValue(nil)
    end):AddButton("Load config", function()
        local Name = Options.SaveManager_ConfigList.Value
        local Success, Error = self:Load(Name)

        if not Success then
            return self.Library:Notify("Failed to load config: " .. Error)
        end

        self.Library:Notify(string.format("Loaded config %q", Name))
    end)

    Section:AddButton("Overwrite config", function()
        local Name = Options.SaveManager_ConfigList.Value
        local Success, Error = self:Save(Name)

        if not Success then
            return self.Library:Notify("Failed to overwrite config: " .. Error)
        end

        self.Library:Notify(string.format("Overwrote config %q", Name))
    end)
    
    Section:AddButton("Autoload config", function()
        local Name = Options.SaveManager_ConfigList.Value
        writefile(self.Folder .. "/Settings/AutoLoad.txt", Name)
        SaveManager.AutoloadLabel:SetText("Current autoload config: " .. Name)
        self.Library:Notify(string.format("Set %q to auto load", Name))
    end)

    Section:AddButton("Refresh config list", function()
        Options.SaveManager_ConfigList.Values = self:RefreshConfigList()
        Options.SaveManager_ConfigList:SetValues()
        Options.SaveManager_ConfigList:SetValue(nil)
    end)

    SaveManager.AutoloadLabel = Section:AddLabel("Current autoload config: None", true)

    if isfile(self.Folder .. "/Settings/AutoLoad.txt") then
        local Name = readfile(self.Folder .. "/Settings/AutoLoad.txt")
        SaveManager.AutoloadLabel:SetText("Current AutoLoad config: " .. Name)
    end

    SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
end

SaveManager:BuildFolderTree()

return SaveManager
