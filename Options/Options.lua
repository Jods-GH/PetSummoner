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
        private.db.profile.searchPets = val
      end,     --Sets value of SavedVariables depending on toggles
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

private.setupOptions = function()
  local ownedPetIDs = C_PetJournal.GetOwnedPetIDs()
  for _, petID in pairs(ownedPetIDs) do
    local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable =
        C_PetJournal.GetPetInfoByPetID(petID)
    local nameToUse = customName or name or "Unknown"
    local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID =
        C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    print(PET_TYPE_SUFFIX[petType])
    print(type(PET_TYPE_SUFFIX[petType]))
    if not private.options.args.petOptions.args[PET_TYPE_SUFFIX[petType]] then
      private.PET_LIST[petType] = {}
      private.options.args.petOptions.args[PET_TYPE_SUFFIX[petType]] = {
        name = _G["BATTLE_PET_NAME_" .. petType] or PET_TYPE_SUFFIX[petType], -- this is stupid but blizzard
        type = "group",
        args = {},
        order = petType,
        hidden = function()
          local isHidden = true
          for petID, pet in pairs(private.PET_LIST[petType]) do
            if string.find(pet.name, private.db.profile.searchPets) then
              isHidden = false
              break
            end
          end
          return isHidden
        end
      }
    end
    private.PET_LIST[petType][petID] = {
      name = nameToUse,
    }
    private.options.args.petOptions.args[PET_TYPE_SUFFIX[petType]].args[speciesName] = {
      name = nameToUse,
      desc = string.format(private.getLocalisation("selectPetDescription"), nameToUse),
      order = creatureID,
      width = "full",
      type = "toggle",
      image = icon,
      hidden = function() return string.find(nameToUse, private.db.profile.searchPets) == nil end,
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
end
