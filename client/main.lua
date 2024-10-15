local spawnedhen = {}
local count = 0
local cooldowns = {}  -- Cooldowns

---@param resourceName string
---@return string? count
local function deleteAll(resourceName)
    if GetCurrentResourceName() ~= resourceName then        
        return
    end

    for k, v in pairs(spawnedhen) do  -- Itt is tyúkra cserélve
        DeletePed(v)
        count = count + 1
    end

    return -- print(('Delete Hens'):format(count))  -- Szöveg frissítése
end

---@param hash number
---@return number? hash
local function requestModel(hash)
    if not tonumber(hash) then
        return -- print(('That value: %s its not number/hash. ``'):format(hash))
    end

    if not IsModelValid(hash) then
        return -- print(('Attempted to load invalid model %s'):format(hash))
    end

    if HasModelLoaded(hash) then
        return hash
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(50)
    end

    return hash
end

---@param animDict string
---@return string? animDict
local function requestAnimDict(animDict)
    if type(animDict) ~= 'string' then
        return -- print(('Expected animDict to have type string (received %s)'):format(type(animDict)))
    end

    if not DoesAnimDictExist(animDict) then
        return -- print(('Attempted to load invalid animDict %s'):format(animDict))
    end

    if HasAnimDictLoaded(animDict) then 
        return animDict 
    end

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(50)
    end

    return animDict
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


---Spawn hen (tyúk)
local function spawnhen()
    
    for i = 1, #Hen, 1 do
        local hen = Hen[i]

        requestModel(`a_c_hen`)

        local createdhen = CreatePed('hen', `a_c_hen`, hen.henCoords.x, hen.henCoords.y, hen.henCoords.z, hen.henCoords.w, false, false)

        FreezeEntityPosition(createdhen, hen.hensettings.Freezehen)

        SetEntityInvincible(createdhen, hen.hensettings.Invincible)
        SetPedDiesWhenInjured(createdhen, not hen.hensettings.Invincible)
        SetPedCanPlayAmbientAnims(createdhen, hen.hensettings.Invincible)
        SetPedCanRagdollFromPlayerImpact(createdhen, not hen.hensettings.Invincible)

        SetBlockingOfNonTemporaryEvents(createdhen, hen.hensettings.BlockingOfNonTemporaryEvents)

        SetEntityAsMissionEntity(createdhen, true, true)
        SetModelAsNoLongerNeeded(`a_c_hen`)

        TaskStartScenarioInPlace(createdhen, 'WORLD_HEN_PECKING', -1, true)

        spawnedhen[i] = createdhen
        exports.ox_target:addLocalEntity(createdhen, {
            label = _("start_hen"),
            name = 'hen',
            icon = 'fa-solid fa-eye',
            distance = 1.7,
           onSelect = function()
               local playerId = GetPlayerServerId(PlayerId())
               local isCoolingDown, timeLeft = isOnCooldown(playerId, i)
               if isCoolingDown then
                   lib.notify({
                        position = 'top',
                        title = _("cooldown"),
                        type = 'error'
                   })
               else
                InteractHen(i)
               end
           end
        })
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
        local success = lib.skillCheck({'easy', 'easy', 'easy', 'easy'}, { 'w', 'a', 's', 'd' })
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

---@param resourceName string
---@return function? spawnhen
local function spawnhenOnStart(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    return spawnhen()
end

AddEventHandler('playerSpawned', spawnhen)
AddEventHandler('onResourceStart', spawnhenOnStart)
AddEventHandler('onResourceStop', deleteAll)