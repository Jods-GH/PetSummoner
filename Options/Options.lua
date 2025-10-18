local appName, private = ...
---@type AceConfigOptionsTable
private.options = {
  name = private.getLocalisation("addonOptions"),
  type = "group",
  args = {
    useFavorites = {
      name = private.getLocalisation("useFavorites"),
      desc = private.getLocalisation("useFavoritesDescription"),
      order = 0,
      width = "full",
      type = "toggle",
      set = function(info, val)
        private.db.profile.useFavorites = val
        private.assurePetIsActive()
      end, --Sets value of SavedVariables depending on toggles
      get = function(info)
        return private.db.profile
            .useFavorites --Sets value of toggles depending on SavedVariables
      end
    },
    disableInitialMessage = {
      name = private.getLocalisation("disableInitialMessage"),
      desc = private.getLocalisation("disableInitialMessageDescription"),
      order = 0,
      width = "full",
      type = "toggle",
      set = function(info, val)
        private.db.profile.disableInitialMessage = val
      end, --Sets value of SavedVariables depending on toggles
      get = function(info)
        return private.db.profile
            .disableInitialMessage --Sets value of toggles depending on SavedVariables
      end
    },
    alwaysForceResummon = {
      name = private.getLocalisation("alwaysForceResummon"),
      desc = private.getLocalisation("alwaysForceResummonDescription"),
      order = 0,
      width = "full",
      type = "toggle",
      confirm = true,
      confirmText = private.getLocalisation("alwaysForceResummonWarning"),

      set = function(info, val)
        private.db.profile.alwaysForceResummon = val
      end, --Sets value of SavedVariables depending on toggles
      get = function(info)
        return private.db.profile
            .alwaysForceResummon --Sets value of toggles depending on SavedVariables
      end
    },
    explainOptions = {
      name = private.getLocalisation("explainOptions"),
      type = "description",
      order = 0,
      fontSize = "medium",
    },
    searchPets = {
      name = private.getLocalisation("searchPets"),
      desc = private.getLocalisation("searchPetsDescription"),
      order = 1,
      width = "full",
      type = "input",
      set = function(info, val)
        private.db.profile.searchPets = string.lower(val)
      end, --Sets value of SavedVariables depending on toggles
      get = function(info)
        return private.db.profile
            .searchPets --Sets value of toggles depending on SavedVariables
      end
    },
    petOptions = {
      name = private.getLocalisation("petOptions"),
      type = "group",
      args = {
        explainOptions = {
          name = private.getLocalisation("findOptions"),
          type = "description",
          order = 0,
          fontSize = "medium",
        },
      },
    },

  }
}
private.PET_LIST = {}
---checks if a pet matches the search terms
---@param pet any
---@return boolean
local checkPet = function(pet)
  if string.find(string.lower(pet.name), private.db.profile.searchPets)
      or string.find(pet.speciesName, private.db.profile.searchPets)
      or string.find(pet.customName, private.db.profile.searchPets) then
    return true
  end
  return false
end
---create a pet toggle 
---@param petType number
---@param speciesName string
---@param petID string
---@param customName string
---@param name string
---@param icon number
---@param creatureID string
---@param nameToUse string
local createPetToggle = function(petType, speciesName, petID, customName, name, icon, creatureID, nameToUse)
  local currentPetList = private.PET_LIST[PET_TYPE_SUFFIX[petType]][speciesName] or {}
  currentPetList[petID] = {
    customName = string.lower(customName or ""),
    name = string.lower(name or ""),
    speciesName = string.lower(speciesName or "")
  }
  private.PET_LIST[PET_TYPE_SUFFIX[petType]][speciesName] = currentPetList


  private.options.args.petOptions.args[PET_TYPE_SUFFIX[petType]].args[speciesName] = {
    name = nameToUse,
    desc = string.format(private.getLocalisation("selectPetDescription"), nameToUse),
    order = creatureID,
    width = "full",
    type = "toggle",
    image = icon,
    hidden = function() return not checkPet(private.PET_LIST[PET_TYPE_SUFFIX[petType]][speciesName][petID]) end,
    disabled = function() return private.db.profile.useFavorites end,
    set = function(info, val)
      if val then
        private.db.profile.petOptions[speciesName] = petID
      else
        private.db.profile.petOptions[speciesName] = false
      end
      private.assurePetIsActive()
    end, --Sets value of SavedVariables depending on toggles
    get = function(info)
      return private.db.profile.petOptions
          [speciesName] --Sets value of toggles depending on SavedVariables
    end,
  }
end
---create all the options for pet selection
private.setupOptions = function()
  local ownedPetIDs = C_PetJournal.GetOwnedPetIDs()
  for _, petID in pairs(ownedPetIDs) do
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable =
        C_PetJournal.GetPetInfoByPetID(petID)
    local nameToUse = customName or name or "Unknown"
    local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID =
        C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    if not private.options.args.petOptions.args[PET_TYPE_SUFFIX[petType]] then
      private.PET_LIST[PET_TYPE_SUFFIX[petType]] = {}
      private.options.args.petOptions.args[PET_TYPE_SUFFIX[petType]] = {
        name = _G["BATTLE_PET_NAME_" .. petType] or PET_TYPE_SUFFIX[petType], -- this is stupid but blizzard
        type = "group",
        args = {},
        order = petType,
        hidden = function()
          if string.trim(private.db.profile.searchPets) == "" then
            return false
          end
          local isHidden = true
          for species in pairs(private.PET_LIST[PET_TYPE_SUFFIX[petType]]) do
            for petID, pet in pairs(private.PET_LIST[PET_TYPE_SUFFIX[petType]][species]) do
              if checkPet(pet) then
                isHidden = false
                break
              end
            end
          end
          return isHidden
        end,
        disabled = function() return private.db.profile.useFavorites end,
      }
    end
    if private.PET_LIST[PET_TYPE_SUFFIX[petType]] and private.PET_LIST[PET_TYPE_SUFFIX[petType]][speciesName] then
     
      if customName and customName ~= "" then
        createPetToggle(petType, speciesName, petID, customName, name, icon, creatureID, nameToUse)
      end
    else
      private.PET_LIST[PET_TYPE_SUFFIX[petType]][speciesName] = {}
      createPetToggle(petType, speciesName, petID, customName, name, icon, creatureID, nameToUse)
    end
  end
end
