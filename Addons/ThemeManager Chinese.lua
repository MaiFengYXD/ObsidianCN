--// 上次翻译：2025-02-26 | Copyright (c) 2025 deividcomsono

local cloneref = (cloneref or clonereference or function(instance: any) return instance end)
local httpService = cloneref(game:GetService("HttpService"))
local httprequest = (syn and syn.request) or request or http_request or (http and http.request)
local getassetfunc = getcustomasset or getsynasset
local isfolder, isfile, listfiles = isfolder, isfile, listfiles

if typeof(copyfunction) == "function" then
    -- 修复is_____函数用于解决问题，这些函数不应出错，只应返回布尔值。

    local
        isfolder_copy,
        isfile_copy,
        listfiles_copy = copyfunction(isfolder), copyfunction(isfile), copyfunction(listfiles)

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local ThemeManager = {} do
    ThemeManager.Folder = "ObsidianLibSettings"
    -- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

    ThemeManager.Library = nil
    ThemeManager.BuiltInThemes = {
        ["默认"] = { 1, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"191919","AccentColor":"7d55ff","BackgroundColor":"0f0f0f","OutlineColor":"282828"}]]) },
        ["BBot"] = { 2, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}]]) },
        ["死亡"] = { 3, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}]]) },
        ["小丑"] = { 4, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}]]) },
        ["薄荷"] = { 5, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}]]) },
        ["东京之夜"] = { 6, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}]]) },
        ["乌班图"] = { 7, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}]]) },
        ["石英"] = { 8, httpService:JSONDecode([[{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}]]) },
    }

    function ThemeManager:SetLibrary(library)
        self.Library = library
    end

    --// 文件夹相关 \\--
    function ThemeManager:GetPaths()
        local paths = {}

        local parts = self.Folder:split("/")
        for idx = 1, #parts do
            paths[#paths + 1] = table.concat(parts, "/", 1, idx)
        end

        paths[#paths + 1] = self.Folder .. "/themes"
        
        return paths
    end

    function ThemeManager:BuildFolderTree()
        local paths = self:GetPaths()

        for i = 1, #paths do
            local str = paths[i]
            if isfolder(str) then continue end
            makefolder(str)
        end
    end

    function ThemeManager:CheckFolderTree()
        if isfolder(self.Folder) then return end
        self:BuildFolderTree()

        task.wait(0.1)
    end

    function ThemeManager:SetFolder(folder)
        self.Folder = folder
        self:BuildFolderTree()
    end
    
    --// 应用和更新主题 \\--
    function ThemeManager:ApplyTheme(theme)
        local customThemeData = self:GetCustomTheme(theme)
        local data = customThemeData or self.BuiltInThemes[theme]

        if not data then return end
        
        local scheme = data[2]
        for idx, val in pairs(customThemeData or scheme) do
            if idx == "VideoLink" then
                continue
            elseif idx == "FontFace" then
                self.Library:SetFont(Enum.Font[val])

                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValue(val)
                end
            else
                self.Library.Scheme[idx] = Color3.fromHex(val)
            
                if self.Library.Options[idx] then
                    self.Library.Options[idx]:SetValueRGB(Color3.fromHex(val))
                end
            end
        end

        self:ThemeUpdate()
    end

    function ThemeManager:ThemeUpdate()
        local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
        for i, field in pairs(options) do
            if self.Library.Options and self.Library.Options[field] then
                self.Library.Scheme[field] = self.Library.Options[field].Value
            end
        end

        self.Library:UpdateColorsUsingRegistry()
    end

    --// 获取、加载、保存、删除、刷新 \\--
    function ThemeManager:GetCustomTheme(file)
        local path = self.Folder .. "/themes/" .. file .. ".json"
        if not isfile(path) then
            return nil
        end

        local data = readfile(path)
        local success, decoded = pcall(httpService.JSONDecode, httpService, data)
        
        if not success then
            return nil
        end

        return decoded
    end

    function ThemeManager:LoadDefault()
        local theme = "默认"
        local content = isfile(self.Folder .. "/themes/default.txt") and readfile(self.Folder .. "/themes/default.txt")

        local isDefault = true
        if content then
            if self.BuiltInThemes[content] then
                theme = content
            elseif self:GetCustomTheme(content) then
                theme = content
                isDefault = false
            end
        elseif self.BuiltInThemes[self.DefaultTheme] then
            theme = self.DefaultTheme
        end

        if isDefault then
            self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
        else
            self:ApplyTheme(theme)
        end
    end

    function ThemeManager:SaveDefault(theme)
        writefile(self.Folder .. "/themes/default.txt", theme)
    end

    function ThemeManager:SaveCustomTheme(file)
        if file:gsub(" ", "") == "" then
            return self.Library:Notify("无效的主题文件名（空）", 3)
        end

        local theme = {}
        local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

        for _, field in pairs(fields) do
            theme[field] = self.Library.Options[field].Value:ToHex()
        end
        theme["FontFace"] = self.Library.Options["FontFace"].Value

        writefile(self.Folder .. "/themes/" .. file .. ".json", httpService:JSONEncode(theme))
    end

    function ThemeManager:Delete(name)
        if (not name) then
            return false, "没有选择配置文件"
        end

        local file = self.Folder .. "/themes/" .. name .. ".json"
        if not isfile(file) then return false, "无效文件" end

        local success = pcall(delfile, file)
        if not success then return false, "删除文件错误" end
        
        return true
    end
    
    function ThemeManager:ReloadCustomThemes()
        local list = listfiles(self.Folder .. "/themes")

        local out = {}
        for i = 1, #list do
            local file = list[i]
            if file:sub(-5) == ".json" then
                -- 不喜欢这样做，但不得不这么做 ...

                local pos = file:find(".json", 1, true)
                local start = pos

                local char = file:sub(pos, pos)
                while char ~= "/" and char ~= "\\" and char ~= "" do
                    pos = pos - 1
                    char = file:sub(pos, pos)
                end

                if char == "/" or char == "\\" then
                    table.insert(out, file:sub(pos + 1, start - 1))
                end
            end
        end

        return out
    end

    --// GUI \\--
    function ThemeManager:CreateThemeManager(groupbox)
        groupbox:AddLabel("背景颜色"):AddColorPicker("BackgroundColor", { Default = self.Library.Scheme.BackgroundColor })
        groupbox:AddLabel("主色调"):AddColorPicker("MainColor", { Default = self.Library.Scheme.MainColor })
        groupbox:AddLabel("强调色"):AddColorPicker("AccentColor", { Default = self.Library.Scheme.AccentColor })
        groupbox:AddLabel("轮廓颜色"):AddColorPicker("OutlineColor", { Default = self.Library.Scheme.OutlineColor })
        groupbox:AddLabel("字体颜色"):AddColorPicker("FontColor", { Default = self.Library.Scheme.FontColor })
        groupbox:AddDropdown("FontFace", {
            Text = "字体",
            Default = "Code",
            Values = {"BuilderSans", "Code", "Fantasy", "Gotham", "Jura", "Roboto", "RobotoMono", "SourceSans"}
        })

        local ThemesArray = {}
        for Name, Theme in pairs(self.BuiltInThemes) do
            table.insert(ThemesArray, Name)
        end

        table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

        groupbox:AddDivider()

        groupbox:AddDropdown("ThemeManager_ThemeList", { Text = "主题列表", Values = ThemesArray, Default = 1 })
        groupbox:AddButton("设置为默认", function()
            self:SaveDefault(self.Library.Options.ThemeManager_ThemeList.Value)
            self.Library:Notify(string.format("默认主题设置为 %q", self.Library.Options.ThemeManager_ThemeList.Value))
        end)

        self.Library.Options.ThemeManager_ThemeList:OnChanged(function()
            self:ApplyTheme(self.Library.Options.ThemeManager_ThemeList.Value)
        end)

        groupbox:AddDivider()

        groupbox:AddInput("ThemeManager_CustomThemeName", { Text = "自定义主题名称" })
        groupbox:AddButton("创建主题", function() 
            self:SaveCustomTheme(self.Library.Options.ThemeManager_CustomThemeName.Value)

            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)

        groupbox:AddDivider()

        groupbox:AddDropdown("ThemeManager_CustomThemeList", { Text = "自定义主题", Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
        groupbox:AddButton("加载主题", function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value

            self:ApplyTheme(name)
            self.Library:Notify(string.format("加载主题 %q", name))
        end)
        groupbox:AddButton("覆盖主题", function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value

            self:SaveCustomTheme(name)
            self.Library:Notify(string.format("覆盖配置 %q", name))
        end)
        groupbox:AddButton("删除主题", function()
            local name = self.Library.Options.ThemeManager_CustomThemeList.Value

            local success, err = self:Delete(name)
            if not success then
                return self.Library:Notify("失败删除主题: " .. err)
            end

            self.Library:Notify(string.format("删除主题 %q", name))
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        groupbox:AddButton("刷新列表", function()
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)
        groupbox:AddButton("设置为默认", function()
            if self.Library.Options.ThemeManager_CustomThemeList.Value ~= nil and self.Library.Options.ThemeManager_CustomThemeList.Value ~= "" then
                self:SaveDefault(self.Library.Options.ThemeManager_CustomThemeList.Value)
                self.Library:Notify(string.format("默认主题设置为 %q", self.Library.Options.ThemeManager_CustomThemeList.Value))
            end
        end)
        groupbox:AddButton("重置默认", function()
            local success = pcall(delfile, self.Folder .. "/themes/default.txt")
            if not success then 
                return self.Library:Notify("失败重置默认: 删除文件错误")
            end
                
            self.Library:Notify("默认主题设置为空")
            self.Library.Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            self.Library.Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)

        self:LoadDefault()

        local function UpdateTheme() self:ThemeUpdate() end
        self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
        self.Library.Options.MainColor:OnChanged(UpdateTheme)
        self.Library.Options.AccentColor:OnChanged(UpdateTheme)
        self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
        self.Library.Options.FontColor:OnChanged(UpdateTheme)
        self.Library.Options.FontFace:OnChanged(function(Value)
            self.Library:SetFont(Enum.Font[Value])
            self.Library:UpdateColorsUsingRegistry()
        end)
    end

    function ThemeManager:CreateGroupBox(tab)
        assert(self.Library, "必须先设置 ThemeManager.Library!")
        return tab:AddLeftGroupbox("主题")
    end

    function ThemeManager:ApplyToTab(tab)
        assert(self.Library, "必须先设置 ThemeManager.Library!")
        local groupbox = self:CreateGroupBox(tab)
        self:CreateThemeManager(groupbox)
    end

    function ThemeManager:ApplyToGroupbox(groupbox)
        assert(self.Library, "必须先设置 ThemeManager.Library!")
        self:CreateThemeManager(groupbox)
    end

    ThemeManager:BuildFolderTree()
end

getgenv().ObsidianThemeManager = ThemeManager
return ThemeManager
