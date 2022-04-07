MegaMacroCachedClass = nil
MegaMacroCachedSpecialization = nil
MegaMacroFullyActive = false
MegaMacroSystemTime = GetTime()

local f = CreateFrame("Frame", "MegaMacro_EventFrame", UIParent)
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LEAVING_WORLD")
if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then 
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
else 
    f:RegisterEvent("CHARACTER_POINTS_CHANGED")
end
f:RegisterEvent("PLAYER_TARGET_CHANGED")

local function OnUpdate(_, elapsed)
    MegaMacroSystemTime = GetTime()
    local elapsedMs = elapsed * 1000
    MegaMacroIconEvaluator.Update(elapsedMs)
    MegaMacroActionBarEngine.OnUpdate(elapsed)
    MegaMacroIconNavigator.OnUpdate()
end

local function GetSpecializationName()
    if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then 
        local specIndex = GetSpecialization()
        if specIndex then
            return select(2, GetSpecializationInfo(specIndex))
        end
    else
        local specIndex = 0
        local maxTalentPoints = 0

        for i=1,GetNumTalentTabs() do
            local talentCount = GetNumTalents(i)
            local points = 0
            for j=1,talentCount do
                local rank = select(5, GetTalentInfo(i,j))
                if rank > 0 then
                    points = points + rank
                end
            end

            if maxTalentPoints < points then
                maxTalentPoints = points
                specIndex = i
            end
        end

        if maxTalentPoints > 0 then
            return select(1, GetTalentTabInfo(specIndex))
        end
    end

    return ""
end

local function Initialize()
    MegaMacro_InitialiseConfig()
    MegaMacroIconNavigator.BeginLoadingIcons()

    SLASH_Mega1 = "/m"
    SLASH_Mega2 = "/macro"
    SlashCmdList["Mega"] = function()
        MegaMacroWindow.Show()

        if not MegaMacroFullyActive then
            ShowMacroFrame()
        end
    end

    MegaMacroCachedSpecialization = GetSpecializationName()
    MegaMacroCachedClass = UnitClass("player")
    MegaMacroCodeInfo.ClearAll()
    MegaMacroIconEvaluator.Initialize()
    MegaMacroActionBarEngine.Initialize()
    MegaMacroEngine.SafeInitialize()
    MegaMacroFullyActive = MegaMacroGlobalData.Activated and MegaMacroCharacterData.Activated
    f:SetScript("OnUpdate", OnUpdate)
end

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        Initialize()
    elseif event == "PLAYER_LEAVING_WORLD" then
        f:SetScript("OnUpdate", nil)
    elseif (event == "PLAYER_SPECIALIZATION_CHANGED" or (event == "CHARACTER_POINTS_CHANGED" and select(1, ...) == -1)) then
        MegaMacroWindow.SaveMacro()

        local oldValue = MegaMacroCachedSpecialization
        MegaMacroCachedSpecialization = select(2, GetSpecializationInfo(GetSpecialization()))

        MegaMacroCodeInfo.ClearAll()
        MegaMacroIconEvaluator.ResetCache()

        if not InCombatLockdown() then -- this event triggers when levelling up too - in combat we don't want it to cause errors
            MegaMacroEngine.OnSpecializationChanged(oldValue, MegaMacroCachedSpecialization)
            MegaMacroWindow.OnSpecializationChanged(oldValue, MegaMacroCachedSpecialization)
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        MegaMacroActionBarEngine.OnTargetChanged()
    end
end)
