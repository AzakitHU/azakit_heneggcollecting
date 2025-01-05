local spawnedhen = {}
local count = 0
local cooldowns = {} -- Cooldowns
local Interact = false -- Interaction flag
local spawnedhen = {}

---@param hash number
---@return number? hash
local function requestModel(hash)
    if not tonumber(hash) then return end
    if not IsModelValid(hash) then return end
    if HasModelLoaded(hash) then return hash end

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(50)
    end
    return hash
end

---@param coords vector3
---@return boolean
local function isHenAtCoords(coords)
    for _, hen in pairs(spawnedhen) do
        local henCoords = GetEntityCoords(hen)
        if #(henCoords - vector3(coords.x, coords.y, coords.z)) < 1.0 then
            return true
        end
    end
    return false
end

---@param resourceName string
---@return string? count
local function deleteAll(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    for k, v in pairs(spawnedhen) do
        DeletePed(v)
        count = count + 1
    end

    return
end

local function isOnCooldown(playerId, henId)
    local currentTime = GetGameTimer() / 1000

    if cooldowns[playerId] and cooldowns[playerId][henId] then
        local timeSinceLastInteract = currentTime - cooldowns[playerId][henId]
        if timeSinceLastInteract < COOLDOWN then
            return true, COOLDOWN - timeSinceLastInteract
        end
    end

    return false
end

local function setCooldown(playerId, henId)
    local currentTime = GetGameTimer() / 1000
    if not cooldowns[playerId] then
        cooldowns[playerId] = {}
    end
    cooldowns[playerId][henId] = currentTime
end

RegisterNetEvent('azakit_heneggcollecting:syncHens')
AddEventHandler('azakit_heneggcollecting:syncHens', function(hens)
    for i, henData in ipairs(hens) do
        if not spawnedhen[i] and not isHenAtCoords(henData.coords) then
            requestModel(`a_c_hen`)

            -- Create hen at the coordinates specified in the config
            local createdhen = CreatePed('hen', `a_c_hen`, henData.coords.x, henData.coords.y, henData.coords.z, henData.coords.w, false, false)

            -- Apply the settings specified in the config
            local settings = Hen[i].hensettings or {}
            FreezeEntityPosition(createdhen, settings.Freezehen or false)
            SetEntityInvincible(createdhen, settings.Invincible or false)
            SetBlockingOfNonTemporaryEvents(createdhen, settings.BlockingOfNonTemporaryEvents or false)
            SetPedDiesWhenInjured(createdhen, not (settings.Invincible or false))
            SetPedCanPlayAmbientAnims(createdhen, settings.Invincible or false)
            SetPedCanRagdollFromPlayerImpact(createdhen, not (settings.Invincible or false))

            -- Start the hen pecking animation
            TaskStartScenarioInPlace(createdhen, 'WORLD_HEN_PECKING', -1, true)

            -- Register the hen in the spawned list
            spawnedhen[i] = createdhen

            -- Notify the server that the hen has been spawned
            TriggerServerEvent('azakit_heneggcollecting:markHenSpawned', i)

            -- Add interaction using ox_target or qb-target
            if InteractionType == "ox_target" then
                exports.ox_target:addLocalEntity(createdhen, {
                    label = _("start_hen"),
                    name = 'hen',
                    icon = 'fa-solid fa-eye',
                    distance = 1.7,
                    onSelect = function()
                        handleInteraction(i)
                    end
                })
            elseif InteractionType == "qb-target" then
                exports['qb-target']:AddTargetEntity(createdhen, {
                    options = {
                        {
                            type = "client",
                            event = "azakit_heneggcollecting:interactHen",
                            icon = "fa-solid fa-eye",
                            label = _("start_hen"),
                            henId = i
                        },
                    },
                    distance = 1.7
                })
            else
                print("^1ERROR: Unknown InteractionType! Only 'ox_target' or 'qb-target' are supported.^0")
            end
        end
    end
end)

-- Request hen states from the server when the player spawns
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('azakit_heneggcollecting:requestHens')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        TriggerServerEvent('azakit_heneggcollecting:requestHens')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, hen in pairs(spawnedhen) do
            DeleteEntity(hen)
        end
        spawnedhen = {}
    end
end)

AddEventHandler("azakit_heneggcollecting:interactHen", function(data)
    handleInteraction(data.henId)
end)

function handleInteraction(index)
    local playerId = GetPlayerServerId(PlayerId())
    local isCoolingDown, timeLeft = isOnCooldown(playerId, index)
    if isCoolingDown then
        lib.notify({
            position = 'top',
            title = _("cooldown"),
            type = 'error'
        })
    else
        InteractHen(index)
    end
end

function ExchangeRequest(index)
    TriggerServerCallback("azakit_heneggcollecting:exchangeProcess", function(result)
        if result then
            lib.notify({
                position = 'top',
                title = _("reward"),
                type = 'success'
            })
        else
            lib.notify({
                position = 'top',
                title = _("noitem"),
                type = 'error'
            })
        end
    end, index)
end

function InteractHen(index)
    if Interact then return end
    Interact = true
    local ped = PlayerPedId()
    RequestAnimDict('amb@medic@standing@kneel@base')
    while not HasAnimDictLoaded('amb@medic@standing@kneel@base') do
        Wait(500)
    end

    TaskPlayAnim(PlayerPedId(), "amb@medic@standing@kneel@base", "base", 8.0, -8.0, -1, 0, 0, false, false, false)
    TaskPlayAnim(PlayerPedId(), "anim@gangops@facility@servers@bodysearch@" ,"player_search", 8.0, -8.0, -1, 48, 0, false, false, false)

    if Check.EnableSkillCheck then
        local success = lib.skillCheck(SkillCheckDifficulty, SkillCheckKeys)
        if success then 
            local playerId = GetPlayerServerId(PlayerId())
            setCooldown(playerId, index)
            ExchangeRequest(index)
        else
            lib.notify({
                position = 'top',
                title = _("failed"),
                type = 'error'
            })
        end
    else
        Wait(1000 * Check.ProcessTime)
        lib.progressCircle({
            duration = Duration,
            label = _("process"),
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
            },
            anim = {
                dict = 'amb@medic@standing@kneel@base',
                clip = 'base'
            },
        })
        local playerId = GetPlayerServerId(PlayerId())
        setCooldown(playerId, index)
        ExchangeRequest(index)
    end

    ClearPedTasks(ped)
    Interact = false
end

