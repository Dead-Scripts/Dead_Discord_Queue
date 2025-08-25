Config = {
	Default_Prio = 500000, -- Default priority if no Discord role found
	AllowedPerTick = 1, -- How many players to allow per connection tick
	CheckForGhostUsers = 40, -- Seconds between ghost user checks
	HostDisplayQueue = true,
	onlyActiveWhenFull = false,

	Requirements = { -- Required identifiers
		Discord = true,
		Steam = true
	},

	WhitelistRequired = false, -- Require a whitelisted role to join
	Debug = true,
	Webhook = 'https://your.webhook.url/here', -- Provide your webhook URL!

	Displays = {
		Prefix = '[DeadDiscordQueue]', -- Updated branding!
		
		ConnectingLoop = {
    		'🌿🌟🌿🌟🌿🌟',
    		'🌟🌿🌟🌿🌟🌿',
    		'🌿🌟🌿🌟🌿✨',
    		'🌟🌿🌟🌿✨🌿',
    		'🌿🌟🌿✨🌿✨',
    		'🌟🌿✨🌿✨🌿',
    		'🌿✨🌿✨🌿✨',
    		'✨🌿✨🌿✨🌿',
    		'🌿✨🌿✨🌿🌟',
    		'✨🌿✨🌿🌟🌿',
    		'🌿✨🌿🌟🌿🌟',
    		'✨🌿🌟🌿🌟🌿',
		}

		Messages = {
			MSG_CONNECTING = 'You are being connected [{QUEUE_NUM}/{QUEUE_MAX}]:',
			MSG_CONNECTED = 'You are up! You are being connected now :)',
			MSG_DISCORD_REQUIRED = 'Your Discord was not detected... You are required to have Discord to play on this server...',
			MSG_STEAM_REQUIRED = 'Your Steam was not detected... You are required to have Steam to play on this server...',
			MSG_NOT_WHITELISTED = 'You do not have a Discord role whitelisted for this server... You are not whitelisted.',
		},
	},
}

Config.Rankings = {
	-- Replace 'ROLE_ID' with actual numeric Discord Role IDs as strings for better accuracy
	['778070857964716033'] = {500, "You are being connected (Member Queue) [{QUEUE_NUM}/{QUEUE_MAX}]:"},
	['778074943824592916'] = {100, "You are being connected (Staff Queue) [{QUEUE_NUM}/{QUEUE_MAX}]:"},
	['778075273065136149'] = {50, "You are being connected (Admin Queue) [{QUEUE_NUM}/{QUEUE_MAX}]:"},
	['778076976345907250'] = {1, "You are being connected (Founder Queue) [{QUEUE_NUM}/{QUEUE_MAX}]:"},
}