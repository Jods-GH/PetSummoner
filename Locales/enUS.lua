local appName, private = ...
local AceLocale = LibStub ('AceLocale-3.0')
local L = AceLocale:NewLocale(appName, "enUS", true)

if L then
    L["AccessOptionsMessage"] = "Access the options via /ps"
    L["selectPetDescription"] = "Selects the pet %s to be automatically summoned."
    L["addonOptions"] = "Pet Summoner"
    L["petOptions"] = "Pet Options"
    L["searchPets"] = "Search Pets"
    L["searchPetsDescription"] = "Type part of a pet's name to filter the list."
    L["useFavorites"] = "Use Favorite Pets"
    L["useFavoritesDescription"] = "If enabled, only favorite pets will be considered for summoning. Disables selection of individual pets below."
    L["noPetsSelected"] = "No pets selected in options."
    L["explainOptions"] = "Select which pets should be automatically summoned. If multiple are selected a random pet out of the selected ones will be chosen."
    L["findOptions"] = "Find the options for specific pets within their type group. All other options are in the Pet Summoner Category."
    private.localisation = L
end