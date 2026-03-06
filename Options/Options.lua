local appName, private = ...
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

---@type AceConfigOptionsTable
private.options = {
  name = private.getLocalisation("addonOptions"),
  type = "group",
  args = {
    useFavorites = {
      name = private.getLocalisation("useFavorites"),
      desc = private.getLocalisation("useFavoritesDescription"),
      order = 1,
      width = "full",
      type = "toggle",
      set = function(info, val)
        private.db.profile.useFavorites = val
        private.assurePetIsActive()
      end,
      get = function(info)
        return private.db.profile.useFavorites
      end
    },
    disableInitialMessage = {
      name = private.getLocalisation("disableInitialMessage"),
      desc = private.getLocalisation("disableInitialMessageDescription"),
      order = 2,
      width = "full",
      type = "toggle",
      set = function(info, val)
        private.db.profile.disableInitialMessage = val
      end,
      get = function(info)
        return private.db.profile.disableInitialMessage
      end
    },
    alwaysForceResummon = {
      name = private.getLocalisation("alwaysForceResummon"),
      desc = private.getLocalisation("alwaysForceResummonDescription"),
      order = 3,
      width = "full",
      type = "toggle",
      confirm = true,
      confirmText = private.getLocalisation("alwaysForceResummonWarning"),
      set = function(info, val)
        private.db.profile.alwaysForceResummon = val
      end,
      get = function(info)
        return private.db.profile.alwaysForceResummon
      end
    },
    openPetSelector = {
      name = private.getLocalisation("openPetSelector"),
      desc = private.getLocalisation("openPetSelectorDescription"),
      order = 5,
      width = "full",
      type = "execute",
      disabled = function() return private.db.profile.useFavorites end,
      func = function()
        private.openPetSelector()
      end,
    },
  }
}

local petSelectorFrame = nil
local petData = {}       -- sorted list of { speciesName, name, icon, petType }
local petDataReady = false

private.setupOptions = function()
  petData = {}
  petDataReady = false
  local seen = {}
  local ownedPetIDs = C_PetJournal.GetOwnedPetIDs()
  for _, petID in pairs(ownedPetIDs) do
    local speciesID = C_PetJournal.GetPetInfoByPetID(petID)
    if not speciesID then return end -- data not loaded yet
    local speciesName, speciesIcon, petType = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    if speciesName and not seen[speciesName] then
      seen[speciesName] = true
      table.insert(petData, {
        speciesName = speciesName,
        name = speciesName,
        icon = speciesIcon,
        petType = petType,
        petID = petID,
      })
    end
  end
  table.sort(petData, function(a, b) return a.name < b.name end)
  petDataReady = true
end

local function matchesSearch(entry, search)
  if not search or search == "" then return true end
  return string.find(string.lower(entry.name), search, 1, true) ~= nil
end

local function populatePetList(scrollFrame, search, updateCount)
  scrollFrame:ReleaseChildren()
  if not petDataReady then return end

  local useFavorites = private.db.profile.useFavorites
  for _, entry in ipairs(petData) do
    if matchesSearch(entry, search) then
      local cb = AceGUI:Create("CheckBox")
      cb:SetLabel(entry.name)
      cb:SetImage(entry.icon)
      cb:SetFullWidth(true)
      cb:SetDisabled(useFavorites)

      local selected = private.db.profile.petOptions[entry.speciesName] and true or false
      cb:SetValue(selected)

      cb:SetCallback("OnValueChanged", function(widget, event, val)
        if val then
          private.db.profile.petOptions[entry.speciesName] = entry.petID
        else
          private.db.profile.petOptions[entry.speciesName] = false
        end
        private.assurePetIsActive()
        updateCount()
      end)

      scrollFrame:AddChild(cb)
    end
  end
end

private.openPetSelector = function()
  if petSelectorFrame then
    petSelectorFrame:Release()
    petSelectorFrame = nil
  end

  AceConfigDialog:Close(appName)

  local frame = AceGUI:Create("Frame")
  frame:SetTitle(private.getLocalisation("petSelectorTitle"))
  frame:SetLayout("List")
  frame:SetWidth(420)
  frame:SetHeight(550)
  frame:SetCallback("OnClose", function(widget)
    petSelectorFrame = nil
    AceGUI:Release(widget)
    AceConfigDialog:Open(appName)
  end)
  petSelectorFrame = frame

  local description = AceGUI:Create("Label")
  description:SetText(private.getLocalisation("explainOptions"))
  description:SetFullWidth(true)
  frame:AddChild(description)

  local searchBox = AceGUI:Create("EditBox")
  searchBox:SetLabel(private.getLocalisation("searchPets"))
  searchBox:SetFullWidth(true)
  searchBox:DisableButton(true)
  frame:AddChild(searchBox)

  local countLabel = AceGUI:Create("Label")
  countLabel:SetFullWidth(true)
  countLabel:SetFontObject(GameFontNormalSmall)
  frame:AddChild(countLabel)

  local function updateCount()
    local count = 0
    for _, v in pairs(private.db.profile.petOptions) do
      if v then count = count + 1 end
    end
    countLabel:SetText(string.format(private.getLocalisation("selectedCount"), count))
  end

  local scrollFrame = AceGUI:Create("ScrollFrame")
  scrollFrame:SetLayout("List")
  scrollFrame:SetFullWidth(true)
  scrollFrame:SetFullHeight(true)
  frame:AddChild(scrollFrame)

  local currentSearch = ""

  local function refresh()
    populatePetList(scrollFrame, currentSearch, updateCount)
    updateCount()
  end

  searchBox:SetCallback("OnTextChanged", function(widget, event, text)
    currentSearch = string.lower(text or "")
    refresh()
  end)

  refresh()
end
