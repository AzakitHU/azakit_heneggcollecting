local Hens = {}
local ESX, QBCore = nil, nil

if FrameworkType == "ESX" then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
elseif FrameworkType == "QBCore" then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Initialize hens
for i, hen in ipairs(Hen) do
    Hens[i] = {
        coords = hen.henCoords,
        spawned = false -- Indicates whether the hen has already spawned
    }
end

RegisterNetEvent('azakit_heneggcollecting:requestHens')
AddEventHandler('azakit_heneggcollecting:requestHens', function()
    local src = source
    TriggerClientEvent('azakit_heneggcollecting:syncHens', src, Hens)
end)

RegisterNetEvent('azakit_heneggcollecting:markHenSpawned')
AddEventHandler('azakit_heneggcollecting:markHenSpawned', function(index)
    if Hens[index] then
        Hens[index].spawned = true
    end
end)


RegisterServerCallback("azakit_heneggcollecting:exchangeProcess", function(source, cb, index)
    local src = source

    local xPlayer
    if FrameworkType == "ESX" then
        xPlayer = ESX.GetPlayerFromId(src)
    elseif FrameworkType == "QBCore" then
        xPlayer = QBCore.Functions.GetPlayer(src)
    else
        print("[HenEggCollecting] Invalid FrameworkType in config: " .. FrameworkType)
        cb(false)
        return
    end

    local randomEggCount = math.random(MINEGG, MAXEGG)

    if FrameworkType == "ESX" then
        xPlayer.addInventoryItem(EGG, randomEggCount)
    elseif FrameworkType == "QBCore" then
        xPlayer.Functions.AddItem(EGG, randomEggCount)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[EGG], "add", randomEggCount)
    end

    cb(true)

    local message = "**Steam:** " .. GetPlayerName(src) .. "\n**ID:** " .. src .. "\n**Log:** Player received " .. randomEggCount .. " eggs from a hen!"
    discordLog(message, Webhook)
end)


function discordLog(message, webhook)
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({username = 'AzakitBOT', embeds = {{["description"] = "".. message .."",["footer"] = {["text"] = "Azakit Development - https://discord.com/invite/DmsF6DbCJ9",["icon_url"] = "https://cdn.discordapp.com/attachments/1150477954430816456/1192512440215277688/azakitdevelopmentlogoavatar.png?ex=65a958c1&is=6596e3c1&hm=fc6638bef39209397047b55d8afbec6e8a5d4ca932d8b49aec74cb342e2910dc&",},}}, avatar_url = "https://cdn.discordapp.com/attachments/1150477954430816456/1192512440215277688/azakitdevelopmentlogoavatar.png?ex=65a958c1&is=6596e3c1&hm=fc6638bef39209397047b55d8afbec6e8a5d4ca932d8b49aec74cb342e2910dc&"}), { ['Content-Type'] = 'application/json' })
end
