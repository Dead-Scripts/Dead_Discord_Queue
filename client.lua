Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(100)
        if NetworkIsSessionStarted() then 
            TriggerServerEvent('DiscordQueue:Activated')
            return 
        end
    end
end)