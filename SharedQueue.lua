Queue = {}
Queue.Players = {}
Queue.PlayerInfo = {}
Queue.SortedKeys = {}
Queue.Messages = {}
debugg = true

queueIndex = 0

-- Helper: Extract license and discord ID from player
function ExtractLicenseAndDiscord(user)
    local license, discord = nil, nil
    for _, id in ipairs(GetPlayerIdentifiers(user)) do
        if id:find("license:") then
            license = id:gsub("license:", "")
        elseif id:find("discord:") then
            discord = id:gsub("discord:", "")
        end
    end
    return license, discord
end

-- Helper: Sort table keys by value
function getKeysSortedByValue(tbl, sortFunction)
    local keys = {}
    for key in pairs(tbl) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
        return sortFunction(tbl[a], tbl[b])
    end)
    return keys
end

function Queue:UpdateSortedKeys()
    self.SortedKeys = getKeysSortedByValue(self.Players, function(a, b) return a < b end)
end

function Queue:Contains(license)
    return self.Players[license] ~= nil
end

function Queue:IsWhitelisted(user)
    local license, discordId = ExtractLicenseAndDiscord(user)
    if discordId then
        local roles = exports.Dead_Discord_API:GetDiscordRoles(user)
        if roles then
            for _, role in ipairs(roles) do
                for roleID in pairs(Config.Rankings) do
                    if exports.Dead_Discord_API:CheckEqual(role, roleID) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function Queue:SetupPriority(user)
    local license, discordId = ExtractLicenseAndDiscord(user)
    if not license then return end

    queueIndex = queueIndex + 1
    self.Players[license] = nil

    local theirPrios = {}
    local msg = Config.Displays.Messages.MSG_CONNECTING
    local roleName = ''
    local priority = tonumber(Config.Default_Prio) + queueIndex

    if discordId then
        local roles = exports.Dead_Discord_API:GetDiscordRoles(user)
        local bestPrio = math.huge
        if roles then
            for _, role in ipairs(roles) do
                for roleID, list in pairs(Config.Rankings) do
                    local rolePrio = tonumber(list[1])
                    if exports.Dead_Discord_API:CheckEqual(role, roleID) then
                        table.insert(theirPrios, rolePrio)
                        if rolePrio < bestPrio then
                            bestPrio = rolePrio
                            msg = list[2]
                            -- roleName = list[3] -- Uncomment if you have role names
                        end
                    end
                end
            end
        end
        if #theirPrios > 0 then
            table.sort(theirPrios)
            priority = theirPrios[1] + queueIndex
        end
    end

    self.Players[license] = priority
    self.Messages[license] = msg
    local username = GetPlayerName(user)
    local discordName = discordId and exports.Dead_Discord_API:GetDiscordName(user) or nil
    self.PlayerInfo[license] = discordName and {username, priority, roleName, discordName} or {username, priority, roleName}

    self:UpdateSortedKeys()

    if debugg then
        for _, data in pairs(self.PlayerInfo) do
            print(("[DEBUG] %s has priority of: %s"):format(tostring(data[1]), tostring(data[2])))
        end
    end
end

function GetMessage(user)
    local license = select(1, ExtractLicenseAndDiscord(user))
    return Queue.Messages[license] or Config.Displays.Messages.MSG_CONNECTING
end

function Queue:IsSetUp(user)
    local license = select(1, ExtractLicenseAndDiscord(user))
    return self.Players[license] ~= nil
end

function Queue:CheckQueue(user, currentConnectors, slots)
    local license = select(1, ExtractLicenseAndDiscord(user))
    if not self.SortedKeys[1] then return false end
    if tostring(self.SortedKeys[1]) == tostring(license) then
        return true
    end

    local openSlots = (slots - GetNumPlayerIndices()) - currentConnectors
    for idx, id in ipairs(self.SortedKeys) do
        if id == license and idx <= openSlots then
            return true
        end
    end

    return false
end

function Queue:GetMax()
    local count = 0
    for _ in pairs(self.Players) do
        count = count + 1
    end
    return count
end

function Queue:GetQueueNum(user)
    local license = select(1, ExtractLicenseAndDiscord(user))
    for idx, id in ipairs(self.SortedKeys) do
        if id == license then
            return idx
        end
    end
    return 1
end

function Queue:PopLicense(license)
    self.Messages[license] = nil
    self.Players[license] = nil
    self.PlayerInfo[license] = nil
    self:UpdateSortedKeys()
    if debugg then
        print("[DEBUG] " .. tostring(license) .. " has been POPPED from QUEUE")
    end
end

function Queue:Pop(user)
    local license = select(1, ExtractLicenseAndDiscord(user))
    self:PopLicense(license)
    if debugg then
        print("[DEBUG] " .. GetPlayerName(user) .. " has been POPPED from QUEUE")
        for _, data in pairs(self.PlayerInfo) do
            print(("[DEBUG] %s has priority of: %s"):format(tostring(data[1]), tostring(data[2])))
        end
    end
end

function Queue:GetUserAt(index)
    local license = self.SortedKeys[index]
    local info = license and self.PlayerInfo[license]
    if info then
        if #info == 4 then
            return {info[1], info[3], info[4]}
        else
            return {info[1], info[3]}
        end
    end
    return false
end