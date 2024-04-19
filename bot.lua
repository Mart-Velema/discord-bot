--Starting the bot
--Declaring all the global variables with their function
Discordia = require('discordia')
Json = require('json')
Http = require('coro-http')
SQLite = require('sqlite3')
Client = Discordia.Client()

--Checking if a file exist
function FileExist(filepath)
    local file = io.open(filepath, 'r')
    if file then
        file:close()
        return true
    else
        return false
    end
end

--Read the .json settings
local settingsFile = io.open("discord-bot/settings.json", "r")
if settingsFile then
    local content = settingsFile:read("*a")
    settingsFile:close()
    Settings = Json.decode(content)
    print("Found the settings file!")
else
    print("Failed to find settings file, shutdown")
    os.exit()
end

--Read the .db file
if FileExist('discord-bot/database.db') then
    print("Found the database file!")
    if FileExist('discord-bot/story.json') then
        print('Found the stories file!')
        Database = SQLite.open('discord-bot/database.db')
        IsStoriesEnabled = true
    else
        print('Failed to find the stories file')
        IsStoriesEnabled = false
    end
else
    print('Failed to find database file, disabling story commands')
    IsStoriesEnabled = false
end

--Print a message saying that the bot is alive
Client:on('ready', function ()
    print('Logged in as: '  .. Client.user.username)
    --Get the roles of the servers this bot is connected to
    getRoles()

    --Set the activity of the bot
    Client:setActivity
    {
        name = 'Custom Status',
        state = 'At your service, with !help',
        type = 4,
    }
end)

Client:on('guildCreate', function()
    getRoles()
end)

Client:on('roleCreate', function(role)
    GuildRoleTable[role.guild.name][role.name] = role
end)

Client:on('roleUpdate', function(role)
    for k,v in pairs(role) do
        if v == role then
            GuildRoleTable[role.guild.name][k] = nil
        end
    end
    GuildRoleTable[role.guild.name][role.name] = role
end)

--Main loop that will execute the commands
Client:on('messageCreate', function(message)
    --Detect if message is form a bot, don't do anything else if so
    if message.author.bot then
        return
    end

    --Checking cooldown of server
    if GuildRoleTable[message.guild.name]['shortDelay'] <= os.time() then
        --Check if the first char is an !
        if string.sub(message.content, 1, 1) == "!" then
            --Decodes the commands based on a space in the message
            local commands = {}
            for command in message.content:gmatch("%S+") do
                table.insert(commands, command)
            end
            --Get the command out of the table
            local commandFunction = CommandTable[commands[1]]

            --Execute the command of the table
            if commandFunction then
                GuildRoleTable[message.guild.name]['shortDelay'] = os.time() + 5
                commandFunction(message)
            else
                --Else, print help message
                message.channel:send('Unknown command')
                Help(message)
            end
        end
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
    --Reply with a list of available services
    ['!list'] = function(message)
        GetList(message)
    end,
    --Reply with the status of a specified available services
    ['!status'] = function(message)
        GetStatus(message)
    end,
    --Reply with ToS, or adds user to a service
    ['!join'] = function(message)
        Join(message)
    end,
    --Reply with a leave message and leaves a user from a service
    ['!leave'] = function (message)
        Leave(message)
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
    --Reloads the database, rate limited to once an hour
    ['!reload'] = function (message)
        Reload(message)
    end,
    --Story command that will iterate the VS storyline
    ['!story'] = function(message)
        Story(message)
    end,
    --Have you mooed today?
    ['!moo'] = function(message)
        Cow(message)
    end,
    --Have you mooed today?
    ['!cow'] = function(message)
        Cow(message)
    end,
    --When life gives you lemons
    ['!lemons'] = function (message)
        Lemons(message)
    end
}

--List of all the descriptions and examples of all the commands
CommandDescription =
{
    --Ping pong!
    ['ping'] =
        'The !ping command responds with `pong!`. It does not serve any other purpose\n' ..
        'Syntax: `!ping`',
    --Reply with a random fox image when someone says !foxpic
    ['foxpic'] =
        'The !foxpic command responds with a random picture of a fox\n' ..
        'Syntax: `!foxpic`',
    --Reply with a random dog image when someone says !dogpic
    ['dogpic'] =
        'The !dogpic command responds with a random picture of a dog\n' ..
        'Syntax: `!dogpic`',
    --Reply with a random cat image when someone says !catpic
    ['catpic'] =
        'The !catpic command responds with a random picture of a cat\n' ..
        'Syntax: `!catpic`',
    --Reply with a list of available services
    ['list'] =
        'The !list command responds with a list of available services\n' ..
        'A service is the name for a server. A server can be any kind of supported game server\n' ..
        'Syntax: `!list`',
    --Reply with the status of a specified service
    ['status'] =
    'The status command returns the status of a specified service\n' ..
            'Syntax: `!status <name of service>`',
    --Reply with ToS, or adds user to a service
    ['join'] =
        'The !join command allows a user to join any specific service\n' ..
        'Joining a service, means being added to the whitelist of that service, and getting a corresponding Discord role\n' ..
        'You are required to join in order to use any of the available services\n' ..
        'Syntax: `!join !` > prints the service agreements of using the !join command\n' ..
        'The name of the service is case-insensitive. MineCraft and MINECRAFT are the same service\n' ..
        'The username of a service, however, IS case-sensitive. 1_HELE_EURO and 1_hele_euro are different usernames\n' ..
        'Syntax: `!join <service name>:<your username on this service>` > Will join you on a specified service',
    --Leave the service and revoke role
    ['leave'] =
        'The !leave command allows a user to leave any specific service\n' ..
        'Leaving a service, means being removed from the whitelist of that service, and revoking the corresponding Discord role\n' ..
        'Syntax: `!leave <service name>` Will leave you on a specified service',
    --Reply with a list of available commands and their description/ usage
    ['help'] =
        'The !help command responds with a list of available commands and their function\n' ..
        'Syntax: `!help`' ..
        'If you wish to get more detailed information about a specific command, you can enter the command after the help command\n' ..
        'Syntax: `!help <name of the command>` > Prints a command-specific help text',
    --Ban an user from all services
    ['ban'] =
        'The !ban command bans a Discord user from all services and the Discord server\n' ..
        'To use this command, you are required to have the "BanMembers" privilege\n' ..
        'Syntax: `!ban @username`',
    --Unban an user from all services
    ['unban'] =
        'The !unban or !pardon command unbans a Discord user from all services and the Discord server\n' ..
        'To use this command, you are required to have the "BanMembers" privilege\n' ..
        'Syntax: `!unban @username`',
    --Have you mooed today?
    --Reloads the database, rate limited to once an hour
    ['reload'] =
        'The !reload command reloads all the whitelists and banlists of all services\n' ..
        'This is a time-consuming process, which is why it is rate limited to once an hour\n' ..
        'Syntax: `!reload`',
    ['story'] =
        'The !story command allows you to read the choose-your-own-adventure type of story\n' ..
        'The story command logs your user ID in a local database, together with the page and chapter number\n' ..
        'Syntax: `!story`',
    ['moo'] =
        'Have you mooed today?\n' ..
        'Syntax: `!moo`',
    --Have you mooed today?
    ['cow'] =
        'Have you mooed today?\n' ..
        'Syntax: `!cow`',
    --When life gives you lemons
    ['lemons'] =
        'When life gives you lemons, make lemonade\n' ..
        'Syntax: `!lemons',
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
    --Looping trough all the available services
    local response = Api(content)
    if type(response) == 'table' then
        for serviceId, serviceName in ipairs(response) do
            --First 4 are admin only, dismiss those
            if  serviceId >= 5 then
                message.channel:send(serviceName)
            end
        end
        message.channel:send("use `!join <name of the service>:<your username of that service>` to join a specific service")
    else
        message.channel:send(response)
    end
end

--Gets the status of a specific service
--!service <name of service>
function GetStatus(message)
    local service = message.content:sub(9)
    local content =
    {
        REQUEST = 'STATUS_SERVICE',
        SERVICE = service
    }
    local status = Api(content)
    if status == true then
        status = 'Online'
    elseif status == false then
        status = 'Offline'
    else
        message.channel:send(status) return
    end
        message.channel:send('Service ' .. service .. ' is currently ' .. status   )
end

--Allows the user to join a service or list the agreement of using the services
--!join !; returns the user agreement
--!join <service Name>:<service Username>; adds the username to the database
function Join(message)
    local service = message.content:sub(6)
    local author = message.guild:getMember(message.author.id)

    --Decoding the command that has been send
    if string.find(service, "!") then
        message.channel:send(
            'When you join a service, you agree to have your Discord ID logged on the AeternaServer network.\n' ..
            'Furthermore, you will agree to have your service username linked to your Discord ID.\n' ..
            'If you wish to get the logged information, or have it removed, contact an administrator.'
        ) return
    elseif not string.find(service, ":") then
        message.channel:send(
            'To join a service, type `!join <name of the service>:<your username of that service>`\n' ..
            'For a list of available services, type `!list`\n' ..
            'For the list of agreements, type `!join !`'
        ) return
    end

    --substring replacement
    local serviceTable = {}
    for substring in string.gmatch(service, "[^:]+") do
        table.insert(serviceTable, string.lower(substring))
    end

    local content =
    {
        REQUEST = 'UPDATE_SERVICE',
        USER_ID = message.author.id,
        ACCOUNT_NAME = serviceTable[2],
        SERVICE = serviceTable[1]
    }

    --Assign a role to the user
    local roleToAssign = GuildRoleTable[message.guild.name][string.gsub(serviceTable[1], " ", "")]
    if roleToAssign then
        author:addRole(roleToAssign)
        message.channel:send('Granting you the role of: ' .. serviceTable[1])
    else
        message.channel:send('The role of: ' .. serviceTable[1] .. ' is not available')
    end

    message.channel:send('Trying to add ' .. content['ACCOUNT_NAME'] .. ' to the ' .. content['SERVICE'] .. ' service')
    message.channel:send(Api(content))
end

function Leave(message)
    local service = string.lower(message.content:sub(7))
    local author = message.guild:getMember(message.author.id)

    local content =
    {
        REQUEST = 'UPDATE_SERVICE',
        USER_ID = message.author.id,
        ACCOUNT_NAME = 'leave',
        SERVICE = service
    }

    --Assign a role to the user
    local roleToRemove = (GuildRoleTable[message.guild.name][string.gsub(service, " ", "")])
    if roleToRemove then
        author:removeRole(roleToRemove)
        message.channel:send('Revoking you the role of:' .. service)
    end

    message.channel:send('Trying to leave the ' .. content['SERVICE'] .. ' service')
    message.channel:send(Api(content))
end

--Gets a list of all available commands
--!help
function Help(message)

    --Initiate the helpTable table
    local helpTable ={}
    --Fill it with the arguments supplied to the !help command
    for command in string.gmatch(message.content, "%a+") do
        table.insert(helpTable, command)
    end

    --If it can't find any argument, print the general purpose help command
    if not helpTable[2] then
        message.channel:send(
            '```Available command:\n' ..
            '!help      > Prints this message. Type !help followed by another command for more details\n' ..
            '!foxpic    > Sends a random photo of a fox\n' ..
            '!catpic    > Sends a random photo of a cat \n' ..
            '!dogpic    > Sends a random photo of a dog\n' ..
            '!ping      > Pong!\n' ..
            '!ban       > Bans a specific user from all services and discord server\n' ..
            '!unban     > Removes all bans of specific user\n' ..
            '!pardon    > Does the same as !unban\n' ..
            '!reload    > Reloads all the bans and whitelists from the database\n' ..
            '!list      > Prints a list of all the available services\n' ..
            '!status    > Prints the status of the requested service \n' ..
            '!join      > Allows you to join any of the available services\n' ..
            '!leave     > Allows you to leave any of the available services\n' ..
            '!story     > Follows one of the available stories```'
        ) return
    else
        --Store the description from the CommandDescription table
        local commandFunction = CommandDescription[helpTable[2]]
        --If it can find the command, print it. Else, return error
        if commandFunction then
            message.channel:send(commandFunction)
        else
            message.channel:send('Unknown command')
        end
    end
end

--Bans a user from all services
--!ban @<username>
function Ban(message)
    local author = message.guild:getMember(message.author.id)
    local member = message.mentionedUsers.first

    --Check if the command pings a user
    if not member then
        message:reply(
            'Please mention someone to ban :3\n' ..
            '`!ban @user`'
        ) return
    --Check if the author can ban members
    elseif not author:hasPermission("banMembers") then
        message:reply(
            'You do not have the `banMembers` permissions :3\n' ..
            'https://tenor.com/view/demoman-heavy-scout-medic-tf2-gif-19939221'
        ) return
    end

    local content=
    {
        REQUEST = 'BAN',
        USER_ID = member.id,
        REASON = 'You have been banned by an administrator'
    }
    message.channel:send("Preparing to ban the user: " .. member.mentionString)

    --Ban the user from the server
    for user in message.mentionedUsers:iter() do
        member = message.guild:getMember(user.id)
        --Check if the user has a lower role position than the user that executed the command
        if author.highestRole.position > member.highestRole.position then
            message.channel:send(Api(content))
            member:ban()
            message.channel:send('User banned from discord')
            return
        else
            message.channel:send('The user you are trying to ban has a higher role than you have')
        end
    end
end

--Unbans a user from all services, does not unban from Discord
--!unban @<username>
--!pardon @<username>
function Unban(message)
    local author = message.guild:getMember(message.author.id)
    local member = message.mentionedUsers.first

    --Check if the command pings a user
    if not member then
        message:reply(
            'Please mention someone to unban :3\n' ..
            '`!ban @user`'
        ) return
    --Check if the author can ban members
    elseif not author:hasPermission("banMembers") then
        message:reply(
            'You do not have the `banMembers` permissions :3\n' ..
            'https://tenor.com/view/demoman-heavy-scout-medic-tf2-gif-19939221'
        ) return
    end

    local content=
    {
        REQUEST = 'UNBAN',
        USER_ID = member.id,
    }
    message.channel:send("Preparing to unban the user: " .. member.mentionString)
    message.channel:send(Api(content))
end

--Reloads all the bans/ whitelists of the entire database
--rate limited to once an hour, can be overwritten by administrators
--!reload
function Reload(message)
    --Check if the timer has expired or if the user can ban other users
    if os.time() >= GuildRoleTable[message.guild.name]['longDelay'] or message.guild:getMember(message.author.id):hasPermission('banMembers') then
        --execute the reload API call
        local content =
        {
            REQUEST = 'RELOAD'
        }
        message.channel:send(Api(content))
        GuildRoleTable[message.guild.name]['longDelay']  = os.time() + 3600
    else
        --print cooldown message
        message.channel:send(
            'Cooldown still active, please wait ' ..
            math.floor((GuildRoleTable[message.guild.name]['longDelay'] - os.time()) / 60) ..
            ' minutes before using again'
        ) return
    end
end

--Story function
function Story(message)
    if isStoriesEnabled == true then
        message.channel:send("Hello, World!")
    else
        message.channel:send("Sorry, but stories are unavailable :<")
    end
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

--Cave Johnson lemon quote Portal 2
--!lemons
function Lemons(message)
    message.channel:send(
        "Alright, I've been thinking.\n" ..
        "When life gives you lemons, don't make lemonade - make life take the lemons back!\n" ..
        "Get mad!\n" ..
        "I don't want your damn lemons, what am I supposed to do with these?\n" ..
        "Demand to see life's manager.\n" ..
        "Make life rue the day it thought it could give Cave Johnson lemons.\n" ..
        "Do you know who I am?\n" ..
        "I'm the man who's gonna burn your house down!\n" ..
        "With the lemons.\n" ..
        "I'm going to to get my engineers to invent a combustible lemon that burns your house down!\n" ..
        "― Cave Johnson - Portal 2"
    )
end

--Discord functions that do not have a command tied to them
--gets all the roles of all the servers this bot is connected to
function getRoles()
    --Creating empty table for roles
    GuildRoleTable = {}
    --Looping trough a list of servers that the bot is part off
    for guild in Client.guilds:iter() do
        GuildRoleTable[guild.name] =
        {
            longDelay = os.time(),
            shortDelay = os.time()
        }
        --print(guild.name)
        local roles = Client:getGuild(guild.id).roles
        --Check if the server even has any roles
        if roles then
            --Add the roles to the table one by one, grouped by the server name
            for roleID, role in pairs(roles) do
                local roleName = string.lower(role.name)
                --print(roleName, roleID)
                GuildRoleTable[guild.name][roleName] = roleID
            end
        end
    end
end

--Reusable functions that are not standalone Discord commands
--Function to turn a random api url into an image
function GetRandomImage(url)
    local ok, res, body = pcall(Http.request, "GET", url)
    if not ok or res.code ~= 200 then
        local error
        if res.code then
            error =
            {
                image = 'Failed to connect to API: ' .. res.code,
                message = 'Failed to connect to API: ' .. res.code
            }
        else
            error =
            {
                image = 'Failed to connect to API: API available',
                message = 'Failed to connect to API: API unavailable'
            }
        end
        return error
    end
    return Json.decode(body)
end

--Function to handle API calls
function Api(content)
    if type(content) ~= 'table' then
        print("Input must be type of table, something else has been supplied")
        return "Syntax error, please contact administrator"
    else
        content['PASSWD'] = Settings['PASSWD']
    end

    local url = Settings['APIURL']
    local payload = Json.encode(content)
    local headers =
    {
        ['Content-Type'] = 'application/json'
    }

    print('Attempting to make API request')
    local ok, res, body = pcall(Http.request, "POST", url, headers, payload, 5000)

    if not ok or res.code < 200 or res.code >= 300 then
        if res.code then
            --If OK
            print("Failed to connect to api: ".. res.reason)
            return 'Failed to connect to API: ' .. res.reason
        else
            --If not OK
            print("Failed to connect to api: API unavailable | " .. res)
            return 'Failed to connect to API: API unavailable'
        end
    end

    local response = Json.decode(body)
    if type(response) == 'table' then
        if response['token'] then
            Settings['PASSWD'] = response['token']
            local settings = Json.encode(Settings)
            local file = io.open("discord-bot/settings.json", "w")
            file:write(settings)
            file:close()
            return response["response"]
        else
            print(response['response'])
            return 'received impossible request, please contact administrator: ' .. response['response']
        end
    else
        print('HTTP output: ' .. body)
        return 'Server unreachable, please contact administrator ERROR 2'
    end
end

Client:run('Bot ' .. Settings['BOTTOKEN'])
