local appName, private = ...
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
---@class MyAddon : AceAddon-3.0, AceConsole-3.0, AceConfig-3.0, AceGUI-3.0, AceConfigDialog-3.0
local Addon = LibStub("AceAddon-3.0"):NewAddon("PetSummoner", "AceConsole-3.0", "AceEvent-3.0")

function Addon:OnInitialize()
    -- Called when the addon is loaded
    Addon:Print(private.getLocalisation("AccessOptionsMessage"))
    Addon:RegisterEvent("PLAYER_ENTERING_WORLD")
    Addon:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
    private.db = LibStub("AceDB-3.0"):New("PetSummoner", private.OptionDefaults, true) -- Generates Saved Variables with default Values (if they don't already exist)
    private.setupOptions()
    local OptionTable = {
        type = "group",
        args = {
            profile = AceDBOptions:GetOptionsTable(private.db),
            rest = private.options
        }
    }
    AceConfig:RegisterOptionsTable(appName, OptionTable) --
    AceConfigDialog:AddToBlizOptions(appName, appName)
    self:RegisterChatCommand("ps", "SlashCommand")
    self:RegisterChatCommand("PS", "SlashCommand")
end

function Addon:OnEnable()
end

function Addon:OnDisable()
end

function PetSummoner_AddonCompartmentFunction()
    Addon:SlashCommand("AddonCompartmentFrame")
end

function Addon:SlashCommand(msg) -- called when slash command is used
    AceConfigDialog:Open(appName)
end

---returns a list of petIDs that are selected in the options
---@return table<number> List of selected petIDs
local function findSelectedPets()
    local selectedPets = {}
    for speciesName, petID in pairs(private.db.profile.petOptions) do
        if petID then
            table.insert(selectedPets, petID)
        end
    end
    return selectedPets
end

---returns a list of petIDs marked as favorites
---@return table<number> List of favorite petIDs
local function findFavoritePets()
    if not C_PetJournal.HasFavoritePets() then
        return {}
    end
    local ownedPetIDs = C_PetJournal.GetOwnedPetIDs()
    local favoritePets = {}
    for _, petID in ipairs(ownedPetIDs) do
        if C_PetJournal.PetIsFavorite(petID) then
            table.insert(favoritePets, petID)
        end
    end
    return favoritePets
end
---returns a list of petIDs that should be considered for summoning
---@return table<number> List of petIDs
local function findPets()
    if private.db.profile.useFavorites then
        return findFavoritePets()
    else
        return findSelectedPets()
    end
end
---ensures no pet is currently summoned
local ensureNoPet = function()
    local current_pet_guid = C_PetJournal.GetSummonedPetGUID()
    if current_pet_guid then
        C_PetJournal.DismissSummonedPet(current_pet_guid)
    end
end
---ensures a pet is currently summoned, if not summons a random one
private.assurePetIsActive = function()
    local selectedPets = findPets()
    if #selectedPets == 0 then
        ensureNoPet()
        return
    end
    local randPet = random(1, #selectedPets)
    if not selectedPets[randPet] then
        ensureNoPet()
        return
    end
    local pet_guid = C_PetJournal.GetPetInfoByPetID(selectedPets[randPet]) and selectedPets[randPet]
    if pet_guid then
        local current_pet_guid = C_PetJournal.GetSummonedPetGUID()
        if not current_pet_guid or current_pet_guid ~= pet_guid then
            C_PetJournal.SummonPetByGUID(pet_guid)
        end
    else
        ensureNoPet()
    end
end

function Addon:PLAYER_ENTERING_WORLD(event, eventInfo, initialState)
    private.assurePetIsActive()
end

function Addon:PET_JOURNAL_LIST_UPDATE()
    private.assurePetIsActive()
end
