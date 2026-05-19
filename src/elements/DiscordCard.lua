local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local HttpService = cloneref(game:GetService("HttpService"))

local Element = {}

local function extractInviteCode(link)
	if type(link) ~= "string" then
		return nil
	end
	return link:match("discord%.gg/([%w%-_]+)") or link:match("discord%.com/invite/([%w%-_]+)")
end

local function fetchInviteData(link)
	local requestFn = request or http_request or syn and syn.request
	local code = extractInviteCode(link)
	if not (requestFn and code) then
		return nil
	end

	local ok, response = pcall(function()
		return requestFn({
			Url = "https://discord.com/api/v9/invites/" .. code .. "?with_counts=true&with_expiration=true",
			Method = "GET",
		})
	end)
	if not ok or not response or not response.Body then
		return nil
	end

	local decodeOk, data = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not decodeOk or type(data) ~= "table" then
		return nil
	end

	local guild = data.guild or {}
	local inviter = data.inviter or {}
	local channel = data.channel or {}
	local icon = guild.icon and ("https://cdn.discordapp.com/icons/" .. tostring(guild.id) .. "/" .. tostring(guild.icon) .. ".png")
		or nil

	return {
		Title = guild.name or "Discord Server",
		Description = guild.description or ("Join #" .. tostring(channel.name or "general")),
		Thumbnail = icon,
		Footer = inviter.username and ("Invited by @" .. inviter.username) or nil,
	}
end

function Element:New(Config)
	local Card = {
		__type = "DiscordCard",
		Link = Config.Link or Config.Url or "",
		Title = Config.Title or "Discord",
		Desc = Config.Desc or "Open Discord link",
		Thumbnail = Config.Thumbnail or "https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f4ac.png",
	}

	local ElementFrame = require("../components/window/Element")(table.clone(Config))
	Card.DiscordCardFrame = ElementFrame

	local inviteData = fetchInviteData(Card.Link)
	if inviteData then
		Card.Title = inviteData.Title or Card.Title
		Card.Desc = inviteData.Description or Card.Desc
		Card.Thumbnail = inviteData.Thumbnail or Card.Thumbnail
	end

	ElementFrame:SetTitle(Card.Title)
	ElementFrame:SetDesc((Card.Desc or "") .. "\n" .. tostring(Card.Link or ""))
	ElementFrame:SetThumbnail(Card.Thumbnail, UDim2.new(0, 26, 0, 26))

	return Card.__type, Card
end

return Element
