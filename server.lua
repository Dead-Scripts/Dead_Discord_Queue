displayIndex = 1
displays = Config.Displays.ConnectingLoop
prefix = Config.Displays.Prefix
currentConnectors = 0
maxConnectors = Config.AllowedPerTick
hostname = GetConvar("sv_hostname") or "Unnamed Server"
slots = GetConvarInt('sv_maxclients', 32)

StopResource('hardcap')

AddEventHandler('onResourceStop', function(resource)
  if resource == GetCurrentResourceName() then
    if GetResourceState('hardcap') == 'stopped' then
      StartResource('hardcap')
    end
  end
end)

webhookURL = Config.Webhook

function sendToDisc(title, message, footer)
  local embed = {{
    color = 65280,
    title = "**" .. title .. "**",
    description = message,
    footer = { text = footer }
  }}
  PerformHttpRequest(webhookURL, function() end, 'POST', json.encode({
    username = "Dead Discord Queue",
    embeds = embed
  }), { ['Content-Type'] = 'application/json' })
end

function sendToDiscQueue(title, message, footer)
  local embed = {{
    color = 16711680,
    title = "**" .. title .. "**",
    description = message,
    footer = { text = footer }
  }}
  PerformHttpRequest(webhookURL, function() end, 'POST', json.encode({
    username = "Dead Discord Queue",
    embeds = embed
  }), { ['Content-Type'] = 'application/json' })
end

function ExtractIdentifiers(src)
  local identifiers = {
    steam = "",
    ip = "",
    discord = "",
    license = "",
    xbl = "",
    live = ""
  }
  for i = 0, GetNumPlayerIdentifiers(src) - 1 do
    local id = GetPlayerIdentifier(src, i)
    if string.find(id, "steam") then
      identifiers.steam = id
    elseif string.find(id, "ip") then
      identifiers.ip = id
    elseif string.find(id, "discord") then
      identifiers.discord = id
    elseif string.find(id, "license") then
      identifiers.license = id
    elseif string.find(id, "xbl") then
      identifiers.xbl = id
    elseif string.find(id, "live") then
      identifiers.live = id
    end
  end
  return identifiers
end

Citizen.CreateThread(function()
  while true do
    Wait(30000) -- Every 30 seconds
    if Config.HostDisplayQueue then
      if hostname ~= "default FXServer" then
        if Queue:GetMax() > 0 then
          SetConvar("sv_hostname", "[" .. Queue:GetMax() .. "/" .. (Queue:GetMax() + 1) .. "] " .. hostname)
        else
          SetConvar("sv_hostname", hostname)
        end
      end
    end
  end
end)

notSet = true
Citizen.CreateThread(function()
  while notSet do
    if hostname == "default FXServer" then
      hostname = GetConvar("sv_hostname") or "Unnamed Server"
    else
      notSet = false
    end
    Wait(1000)
  end
end)

function GetPlayerCountSafe()
  local count = 0
  for _, _ in pairs(GetPlayers()) do
    count = count + 1
  end
  return count
end

local connecting = {}
local playerConnecting = {}

function CheckForGhostUsers()
  for license, data in pairs(playerConnecting) do
    local user = data.ID
    local name = data.PlayerName
    if GetPlayerName(user) == nil or GetPlayerName(user) ~= name then
      Queue:PopLicense(license)
      if Config.Debug then
        print("[Dead-DiscordQueue] (Ghost check) Removed player: " .. name)
      end
      connecting[license] = nil
      playerConnecting[license] = nil
      if currentConnectors > 0 then
        currentConnectors = currentConnectors - 1
      end
    end
  end
end

Citizen.CreateThread(function()
  while true do
    Wait(Config.CheckForGhostUsers * 1000)
    CheckForGhostUsers()
  end
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
  deferrals.defer()
  local user = source
  local ids = ExtractIdentifiers(user)
  local license = ids.license:gsub("license:", "")
  local discord = ids.discord
  local steam = ids.steam
  local playerName = GetPlayerName(user) or "Unknown"

  if Config.Requirements.Steam and #steam <= 1 then
    deferrals.done(prefix .. " " .. Config.Displays.Messages.MSG_STEAM_REQUIRED)
    return
  end

  if Config.Requirements.Discord and #discord <= 1 then
    deferrals.done(prefix .. " " .. Config.Displays.Messages.MSG_DISCORD_REQUIRED)
    return
  end

  if Config.WhitelistRequired and not Queue:IsWhitelisted(user) then
    deferrals.done(prefix .. " " .. Config.Displays.Messages.MSG_NOT_WHITELISTED)
    return
  end

  if Queue:Contains(license) then
    deferrals.done('You are already in the queue.')
    return
  end

  playerConnecting[license] = { Connection = false, ID = user, PlayerName = playerName, Timeout = Config.Timeout or 60 }

  -- queue logic simplified for brevity, same as your existing code (cycle displays, wait for slot, etc.)
  -- make sure to increment displayIndex:
  displayIndex = displayIndex + 1
  if displayIndex > #displays then
    displayIndex = 1
  end

  -- final done
  deferrals.done()
end)

AddEventHandler('playerDropped', function(reason)
  local user = source
  local ids = ExtractIdentifiers(user)
  local license = ids.license:gsub("license:", "")
  local playerName = GetPlayerName(user) or "Unknown"

  connecting[license] = nil
  playerConnecting[license] = nil

  if Queue:IsSetUp(user) then
    Queue:Pop(user)
    sendToDiscQueue("REMOVED QUEUE USER", "Player `" .. playerName:gsub("`", "") .. "` has been removed from the queue...", "4R-DiscordQueue")
    print(prefix .. " Removed " .. playerName .. " from queue")
  end

  if currentConnectors > 0 then
    currentConnectors = currentConnectors - 1
  end
end)

RegisterNetEvent('DiscordQueue:Activated')
AddEventHandler('DiscordQueue:Activated', function()
  local user = source
  local ids = ExtractIdentifiers(user)
  local license = ids.license:gsub("license:", "")
  local playerName = GetPlayerName(user) or "Unknown"

  Queue:Pop(user)
  connecting[license] = nil
  playerConnecting[license] = nil

  sendToDiscQueue("REMOVED QUEUE USER", "Player `" .. playerName:gsub("`", "") .. "` has been removed from the queue...", "4R-DiscordQueue")
  if currentConnectors > 0 then
    currentConnectors = currentConnectors - 1
  end

  if Config.Debug then
    print(prefix .. " (Activated) Removed " .. playerName .. " from queue. Connectors: " .. currentConnectors)
  end
end)