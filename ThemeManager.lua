local HttpService = game:GetService("HttpService")
local ThemeManager = {}

ThemeManager.Folder = "LinoriaThemeFolder"
ThemeManager.Library = nil
ThemeManager.BuiltInThemes = {
    ["Default"] 		= { 1, HttpService:JSONDecode('{"FontColor":"cccccc","MainColor":"191919","AccentColor":"ffffff","BackgroundColor":"1c1c1c","OutlineColor":"3c3c3c"}') },
    ["Dracula"] 		= { 2, HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232533","AccentColor":"6271a5","BackgroundColor":"1b1c27","OutlineColor":"7c82a7"}') },
    ["Bitch Bot"] 		= { 3, HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
    ["Kiriot Hub"] 		= { 4, HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"30333b","AccentColor":"ffaa00","BackgroundColor":"1a1c20","OutlineColor":"141414"}') },
    ["Fatality"] 		= { 5, HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
    ["Green"] 			= { 6, HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"141414","AccentColor":"00ff8b","BackgroundColor":"1c1c1c","OutlineColor":"3c3c3c"}') },
    ["Jester"] 			= { 7, HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
    ["Mint"] 			= { 8, HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
    ["Tokyo Night"] 	= { 9, HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
    ["Ubuntu"] 			= { 10, HttpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
}

function ThemeManager:ApplyTheme(Theme)
    local CustomThemeData = self:GetCustomTheme(Theme)
    local Data = CustomThemeData or self.BuiltInThemes[Theme]

    if not Data then return end

    local Scheme = Data[2]

    for Index, Color in next, CustomThemeData or Scheme do
        self.Library[Index] = Color3.fromHex(Color)
        
        if Options[Index] then
            Options[Index]:SetValueRGB(Color3.fromHex(Color))
        end
    end

    self:ThemeUpdate()
end

function ThemeManager:ThemeUpdate()
    self.Library.FontColor = Options.FontColor.Value
    self.Library.MainColor = Options.MainColor.Value
    self.Library.AccentColor = Options.AccentColor.Value
    self.Library.BackgroundColor = Options.BackgroundColor.Value
    self.Library.OutlineColor = Options.OutlineColor.Value

    self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
    self.Library:UpdateColorsUsingRegistry()
end

function ThemeManager:LoadDefault()		
    local Theme = "Default"
    local Content = isfile(self.Folder .. "/Themes/DefaultTheme.txt") and readfile(self.Folder .. "/Themes/DefaultTheme.txt")

    local IsDefault = true

    if Content then
        if self.BuiltInThemes[Content] then
            Theme = Content
        elseif self:GetCustomTheme(Content) then
            Theme = Content
            IsDefault = false
        end
    elseif self.BuiltInThemes[self.DefaultTheme] then
        Theme = self.DefaultTheme
    end

    if IsDefault then
        Options.ThemeManager_ThemeList:SetValue(Theme)
    else
        self:ApplyTheme(Theme)
    end
end

function ThemeManager:SaveDefault(Theme)
    writefile(self.Folder .. "/Themes/DefaultTheme.txt", Theme)
end

function ThemeManager:CreateThemeManager(GroupBox)
    GroupBox:AddLabel("Background color"):AddColorPicker("BackgroundColor", { Default = self.Library.BackgroundColor })
    GroupBox:AddLabel("Main color")	:AddColorPicker("MainColor", { Default = self.Library.MainColor })
    GroupBox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = self.Library.AccentColor })
    GroupBox:AddLabel("Outline color"):AddColorPicker("OutlineColor", { Default = self.Library.OutlineColor })
    GroupBox:AddLabel("Font color")	:AddColorPicker("FontColor", { Default = self.Library.FontColor })

    local ThemesArray = {}

    for Name, Theme in next, self.BuiltInThemes do
        table.insert(ThemesArray, Name)
    end

    table.sort(ThemesArray, function(A, B) return self.BuiltInThemes[A][1] < self.BuiltInThemes[B][1] end)

    GroupBox:AddDivider()
    GroupBox:AddDropdown("ThemeManager_ThemeList", { Text = "Theme list", Values = ThemesArray, Default = 1 })

    GroupBox:AddButton("Set as default", function()
        self:SaveDefault(Options.ThemeManager_ThemeList.Value)
        self.Library:Notify(string.format("[Fondra]: Set default theme to %q", Options.ThemeManager_ThemeList.Value))
    end)

    Options.ThemeManager_ThemeList:OnChanged(function()
        self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
    end)

    GroupBox:AddDivider()

    GroupBox:AddDropdown("ThemeManager_CustomThemeList", { Text = "Custom themes", Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
    GroupBox:AddInput("ThemeManager_CustomThemeName", { Text = "Custom theme name" })

    GroupBox:AddButton("Load custom theme", function() 
        self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value) 
    end)

    GroupBox:AddButton("Save custom theme", function() 
        self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)

        Options.ThemeManager_CustomThemeList.Values = self:ReloadCustomThemes()
        Options.ThemeManager_CustomThemeList:SetValues()
        Options.ThemeManager_CustomThemeList:SetValue(nil)
    end)

    GroupBox:AddButton("Refresh list", function()
        Options.ThemeManager_CustomThemeList.Values = self:ReloadCustomThemes()
        Options.ThemeManager_CustomThemeList:SetValues()
        Options.ThemeManager_CustomThemeList:SetValue(nil)
    end)

    GroupBox:AddButton("Set as default", function()
        if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= "" then
            self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
            self.Library:Notify(string.format("[Fondra]: Set default theme to %q", Options.ThemeManager_CustomThemeList.Value))
        end
    end)

    ThemeManager:LoadDefault()

    local function UpdateTheme()
        self:ThemeUpdate()
    end

    Options.BackgroundColor:OnChanged(UpdateTheme)
    Options.MainColor:OnChanged(UpdateTheme)
    Options.AccentColor:OnChanged(UpdateTheme)
    Options.OutlineColor:OnChanged(UpdateTheme)
    Options.FontColor:OnChanged(UpdateTheme)
end

function ThemeManager:GetCustomTheme(File)
    local Path = self.Folder .. "/Themes/" .. File

    if not isfile(Path) then
        return nil
    end

    local Data = readfile(Path)
    local Success, Decoded = pcall(HttpService.JSONDecode, HttpService, data)
    
    if not Success then
        return nil
    end

    return Decoded
end

function ThemeManager:SaveCustomTheme(File)
    if File:gsub(" ", "") == "" then
        return self.Library:Notify("[Fondra]: Invalid file name for theme [Empty]", 3)
    end

    local Theme = {}
    local Fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

    for _, Field in next, Fields do
        Theme[Field] = Options[Field].Value:ToHex()
    end

    writefile(self.Folder .. "/Themes/" .. File .. ".json", HttpService:JSONEncode(Theme))
end

function ThemeManager:ReloadCustomThemes()
    local List = listfiles(self.Folder .. "/Themes")
    local Out = {}

    for i = 1, #List do
        local File = List[i]
        
        if File:sub(-5) == ".json" then
            local Pos = File:find(".json", 1, true)
            local Char = File:sub(Pos, Pos)

            while Char ~= "/" and Char ~= "\\" and Char ~= "" do
                Pos = Pos - 1
                Char = File:sub(Pos, Pos)
            end

            if Char == "/" or Char == "\\" then
                table.insert(Out, File:sub(Pos + 1))
            end
        end
    end

    return Out
end

function ThemeManager:SetLibrary(Lib)
    self.Library = Lib
end

function ThemeManager:BuildFolderTree()
    local Paths = {}
    local Parts = self.Folder:split("/")

    for Index = 1, #Parts do
        Paths[#Paths + 1] = table.concat(Parts, "/", 1, Index)
    end

    table.insert(Paths, self.Folder .. "/Themes")
    table.insert(Paths, self.Folder .. "/Settings")

    for i = 1, #Paths do
        local String = Paths[i]
        
        if not isfolder(String) then
            makefolder(String)
        end
    end
end

function ThemeManager:SetFolder(Folder)
    self.Folder = Folder
    self:BuildFolderTree()
end

function ThemeManager:CreateGroupBox(Tab)
    assert(self.Library, "Must set ThemeManager.Library first!")
    return Tab:AddLeftGroupbox("Themes")
end

function ThemeManager:ApplyToTab(Tab)
    assert(self.Library, "Must set ThemeManager.Library first!")
    local GroupBox = self:CreateGroupBox(Tab)
    self:CreateThemeManager(GroupBox)
end

function ThemeManager:ApplyToGroupbox(GroupBox)
    assert(self.Library, "Must set ThemeManager.Library first!")
    self:CreateThemeManager(GroupBox)
end

ThemeManager:BuildFolderTree()

return ThemeManager
