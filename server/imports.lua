local ServerCallbacks = {}

function RegisterServerCallback(name, cb)
	ServerCallbacks[name] = cb
end

function TriggerServerCallback(name, requestId, source, cb, ...)
	if ServerCallbacks[name] then
		ServerCallbacks[name](source, cb, ...)
	else
		print(('[^3WARNING^7] Server callback ^5"%s"^0 does not exist. ^1Please Check The Server File for Errors!'):format(name))
	end
end

RegisterServerEvent('azakit_heneggcollecting:triggerServerCallback')
AddEventHandler('azakit_heneggcollecting:triggerServerCallback', function(name, requestId, ...)
	local playerId = source

	TriggerServerCallback(name, requestId, playerId, function(...)
		TriggerClientEvent('azakit_heneggcollecting:serverCallback', playerId, requestId, ...)
	end, ...)
end)