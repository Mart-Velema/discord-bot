--Starting the bot
--Declaring all the global variables with their function
Discordia = require('discordia')
Json = require('json')
Http = require('coro-http')
Client = Discordia.Client()

--Read the .json settings
local file = io.open("discord-bot/settings.json", "r")
if file then
    local content = file:read("*a")
    file:close()
    Settings = Json.decode(content)
else
    print("Failed to find settings file, shutdown")
    os.exit()
end

--Print a message saying that the bot is alive
Client:on('ready', function ()
    print('Logged in as' .. Client.user.username)
    Time = os.time()
end)

--Main loop that will execute the commands
Client:on('messageCreate', function(message)
    --Detect if message is form a bot, don't do anything else if so
    if message.author.bot then
        return
    end

    --Decodes the commands based on a space in the message
    local commands = {}
    for command in message.content:gmatch("%S+") do
        table.insert(commands, command)
    end

    --Get the command out of the table
    local commandFunction = CommandTable[commands[1]]

    --Execute the command of the table
    if commandFunction then
        commandFunction(message)
    end
end)

--Table that contains all the commands
CommandTable =
{
    --Ping pong!
    ['!ping'] = function (message)
        message.channel:send('Pong!') return
    end,
    --Reply with a random fox image when someone says !foxpic
    ['!foxpic'] = function(message)
        message.channel:send(GetRandomImage('https://randomfox.ca/floof/')['image'])
    end,
    --Reply with a random dog image when someone says !dogpic
    ['!dogpic'] = function(message)
        message.channel:send(GetRandomImage('https://dog.ceo/api/breeds/image/random')['message'])
    end,
    --Reply with a random cat image when someone says !catpic
    ['!catpic'] = function(message)
        message.channel:send(GetRandomImage('https://api.thecatapi.com/v1/images/search')[1]['url'])
    end,
    --Reply with a list of services
    ['!list'] = function(message)
        GetList(message)
    end,
    --Reply with ToS, or adds user to a service
    ['!join'] = function(message)
        Join(message)
    end,
    --Reply with a list of available commands and their description/ usage
    ['!help'] = function (message)
        Help(message)
    end,
    --Ban an user from all services
    ['!ban'] = function(message)
        Ban(message)
    end,
    --Unban an user from all services
    ['!unban'] = function(message)
        Unban(message)
    end,
    --Also unban an user from all services
    ['!pardon'] = function(message)
        Unban(message)
    end,
    --Have you mooed today?
    ['!moo'] = function(message)
        Cow(message)
    end,
    --Have you mooed today?
    ['!cow'] = function(message)
        Cow(message)
    end,
    --Reloads the database, rate limited to once an hour
    ['!reload'] = function (message)
        Reload(message)
    end
}
--Functions that correspond to a Discord command
--Gets a list of all available services
--!list
function GetList(message)
    message.channel:send('Getting list of available services...')
    local content =
    {
        REQUEST = 'LIST_SERVICES'
    }
    local responce = Api(content)
    if type(responce) == 'table' then
        for serviceId, serviceName in ipairs(responce) do
            if  serviceId >= 5 then
                message.channel:send(serviceName)
            end
        end
        message.channel:send("use `!join <service name>:<username of service>` to join a specific service")
    else
        message.channel:send(responce)
    end
end

--Allows the user to join a service or list the agreement of using the services
--!join !; returns the user agreement
--!join <service Name>:<service Username>; adds the username to the database
function Join(message)
    local service = message.content:sub(6)
    if string.find(service, "!") then
        message.channel:send(
            'When you join a service, you agree to have your Discord ID logged on the AeternaServer network.\n' ..
            'Furthermore, you will agree to have your service username linked to your Discord ID.\n' ..
            'If you wish to get the logged information, or have it removed, contact an administrator.'
        ) return
    elseif not string.find(service, ":") then
        message.channel:send(
            'To join a service, type `!join <serviceName>:<serviceAccountName>`\n' ..
            'For the list of agreements, type `!join !`') return
    end

    --substring replacement
    local serviceTable = {}
    for substring in string.gmatch(service, "[^:]+") do
        table.insert(serviceTable, substring)
    end

    print(message.author.id)

    local content =
    {
        REQUEST = 'UPDATE_SERVICE',
        USER_ID = message.author.id,
        ACCOUNT_NAME = serviceTable[2],
        SERVICE = serviceTable[1]
    }
    message.channel:send('Trying to add ' .. content['ACCOUNT_NAME'] .. ' to the ' .. content['SERVICE'] .. ' service')
    message.channel:send(Api(content))
end

--Gets a list of all available commands
--!help
--TODO !help !<commandname>
function Help(message)
    message.channel:send(
        '```Available command:\n' ..
        '!help: Prints this message. Comming soon: Type !help followed by another command for more details\n' ..
        '!foxpic: Sends a random photo of a fox\n' ..
        '!catpic: Sends a random photo of a cat \n' ..
        '!dogpic: Sends a random photo of a dog\n' ..
        '!ping: Pong!\n' ..
        '!ban: Bans a specific user from all services and discord server\n' ..
        '!unban: Removes all bans of specific user\n' ..
        '!pardon: Does the same as !unban\n' ..
        '!reload: Reloads all the bans and whitelists from the database. Can only be used once an hour\n' ..
        '!list: Prints a list of all the available services\n' ..
        '!join: Allows you to join any of the available services\n```'
    )
end

--Bans a user from all services
--!ban @<username>
function Ban(message)
    local author = message.guild:getMember(message.author.id)
    local member = message.mentionedUsers.first

    if not member then
        message:reply("Please mention someone to ban :3")
        return
    elseif not author:hasPermission("banMembers") then
        message:reply("You do not have the `banMembers` permissions :3")
        message:reply('https://tenor.com/view/demoman-heavy-scout-medic-tf2-gif-19939221')
        return
    end

    local content=
    {
        REQUEST = 'BAN',
        USER_ID = member.id,
        REASON = 'You have been banned by an administrator'
    }
    message.channel:send("PREPARE TO BE BANNED UwU " .. member.mentionString)
    message.channel:send(Api(content))

    for user in message.mentionedUsers:iter() do
        member = message.guild:getMember(user.id)
        if author.highestRole.position > member.highestRole.position then
            member:ban()
        end
    end
    message.channel:send('User banned from discord')
end

--Unbans a user from all services, does not unban from Discord
--!unban @<username>
--!pardon @<username>
function Unban(message)
    local author = message.guild:getMember(message.author.id)
    local member = message.mentionedUsers.first

    if not member then
        message:reply("Please mention someone to unban :3")
        return
    elseif not author:hasPermission("banMembers") then
        message:reply("You do not have the `banMembers` permissions :3")
        message:reply('https://tenor.com/view/demoman-heavy-scout-medic-tf2-gif-19939221')
        return
    end

    local content=
    {
        REQUEST = 'UNBAN',
        USER_ID = member.id,
    }
    message.channel:send("PREPARE TO BE BANNE... Eh... Pardonned I guess?")
    message.channel:send(Api(content))
end

--Have you mooed today?
function Cow(message)
    message.channel:send(
        '```                   (__)        \n' ..
        '                   (oo)        \n' ..
        '             /------\\/         \n' ..
        '           / |    ||           \n' ..
        '          *  /\\---/\\           \n' ..
        '             ~~   ~~           \n' ..
        '..."Have you mooed today?"...  ```'
    )
end

--Reloads all the bans/ whitelists of the entire database
--rate limited to once an hour, can be overwritten by administrators
--!reload
function Reload(message)
    if os.time() >= Time  or message.guild:getMember(message.author.id):hasPermission('banMembers') then
        local content =
        {
            REQUEST = 'RELOAD'
        }
        message.channel:send(Api(content))
        Time = os.time() + 3600
    else
        message.channel:send('Cooldown still active, please wait ' .. math.floor((Time - os.time()) / 60) .. ' minutes before using again')
    end
end

--Reusable functions that are not standalone Discord commands
--Function to turn a random api url into an image
function GetRandomImage(url)
    local ok, res, body = pcall(Http.request, "GET", url)
    if not ok or res.code ~= 200 then
        print("Failed to connect to api: ".. res.reason) return
    end
    return Json.decode(body)
end

--Function to dump an array/ table
function Dump(o)
    if type(o) == 'table' then
        for i,v in ipairs(o) do
            print(i, v)
        end
    end
 end

--Function to handle API calls
function Api(content)
    if not type(content) == 'table' then
        print("Input must be type of table, something else has been supplied")
        return "Syntax error, please contact administrator"
    else
        content['PASSWD'] = Settings['PASSWD']
    end

    local url = Settings['APIURL']
    local payload = Json.encode(content)
    local headers ={{'Content-Type', 'application/json'}}

    print('Attempting to make API request')
    local ok, res, body = pcall(Http.request, "POST", url, headers, payload, 5000)

    if not ok or res.code < 200 or res.code >= 300 then
        if res.code then
            print("Failed to connect to api: ".. res.reason)
            return 'Failed to connect to API: ' .. res.reason
        else
            print("Failed to connect to api: API unavailable")
            return 'Failed to connect to API: API unavailable'
        end
    end

    local responce = Json.decode(body)
    if type(responce) == 'table' then
        return responce['responce']
    else
        print('HTTP output: ' .. body)
        return 'Server unreachable, please contact administrator ERROR 2'
    end
end

Client:run('Bot ' .. Settings['BOTTOKEN'])
