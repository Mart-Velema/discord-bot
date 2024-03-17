local discordia = require('discordia')
local json = require('json')
local http = require('coro-http')
local client = discordia.Client()

local file = io.open("discord-bot/settings.json", "r")
if file then
    local content = file:read("*a")
    file:close()
    settings = json.decode(content)
else
    print("Failed to find settings file, shutdown")
    os.exit()
end

client:on('ready', function ()
    print('Logged in as' .. client.user.username)
end)

client:on('messageCreate', function(message)
    --Detect if message is form a bot, don't do anything else if so
    if message.author.bot then
        print('Mesasge was from a bot, ignore') return
    end

    --Random API images
    --Reply with a random fox image when someone says !foxpic
    if message.content == '!foxpic' then
        message.channel:send(GetRandomImage('https://randomfox.ca/floof/')['image'])
    --Reply with a random dog image when someone says !dogpic
    elseif message.content == '!dogpic' then
        message.channel:send(GetRandomImage('https://dog.ceo/api/breeds/image/random')['message'])
    --Reply with a random cat image when someone says !catpic
    elseif message.content == '!catpic' then
        message.channel:send(GetRandomImage('https://api.thecatapi.com/v1/images/search')[1]['url'])
    end

    --Reply !ping with pong
    if message.content == '!ping' then
        message.channel:send('Pong!')   
    end

    --Reply with a Hello, World! from a testing api when the command !helloWorld is ran
    if message.content == '!helloWorld' then
        local content =
        {
            REQUEST = 'DISCORD',
            PAYLOAD = 'Hello, World!'
        }
        message.channel:send(Api(content))
    end

    --list of services, !list
    if message.content == '!list' then
        message.channel:send('Getting list of available services...')
        local content =
        {
            REQUEST = 'LIST_SERVICES',
        }
        Dump(Api(content))
        DumpToDiscord(Api(content))
        print(Api(content)[3])
    end

    --Add a user to the services database
    --format - !join service:serviceAccountName
    if message.content:sub(1, 5) == '!join' then
        local service = message.content:sub(6)
        --substring replacement
        local serviceTable = {}
        for substring in string.gmatch(service, "[^:]+") do
            table.insert(serviceTable, substring)
        end

        local content =
        {
            REQUEST = 'UPDATE_SERVICE',
            USER_ID = message.member.guild.id,
            ACCOUNT_NAME = serviceTable[2],
            SERVICE = serviceTable[1]
        }
        message.channel:send('Trying to add ' .. content['ACCOUNT_NAME'] .. ' to the ' .. content['SERVICE'] .. ' service')
        message.channel:send(Api(content))
    end

    --Help command, !help
    if message.content == '!help' then
        message.channel:send(
            '```Available command:\n' ..
            '!help: prints this message. Type !help followed by another command for more details\n' ..
            '!foxpic: sends a random photo of a fox\n' ..
            '!catpic: sends a random photo of a cat \n' ..
            '!dogpic: sends a random photo of a dog\n' ..
            '!ping: Pong!\n' ..
            '!ban: bans a specific user from all services and discord server\n' ..
            '!pardon: removes all bans of specific user\n' ..
            '!list: prints a list of all the available services\n' ..
            '!join: Allows you to join any of the available services\n```'
        )
    end

    --Ban command
    if message.content:sub(1, 4) == '!ban' then
        local author = message.guild:getMember(message.author.id)
        local member = message.mentionedUsers.first

        if not member then
            message:reply("Please mention someone to ban :3")
            return
        elseif not author:hasPermission("banMembers") then
            message:reply("You do not have the `banMembers` permissions :3")
            return
        end
        message.channel:send("PREPARE TO BE BANNED UwU " .. member.mentionString)
    end

    --Unban command
    if message.content:sub(1, 7) == '!pardon' then
        local author = message.guild:getMember(message.author.id)
        local member = message.mentionedUsers.first

        if not member then
            message:reply("Please mention someone to unban :3")
            return
        elseif not author:hasPermission("banMembers") then
            message:reply("You do not have the `banMembers` permissions :3")
            return
        end
        message.channel:send("PREPARE TO BE BANNE... Eh... Pardonned I guess?")
    end

    --Kill command :3
    if message.content == '!fuck-off!' then
        if not message.member:hasPermission("banMember") then
            message.channel:reply("You cannot stop me! :3") return
        end
        message.channel:send("Fucking off...")
        os.exit()
    end
end)

--Function to turn a random api url into an image
function GetRandomImage(url)
    local ok, res, body = pcall(http.request, "GET", url)
    if not ok or res.code ~= 200 then
        print("Failed to connect to api: ".. res.reason) return
    end
    return json.decode(body)
end

--Function to dump an array/ table
function Dump(o)
    if type(o) == 'table' then
        for i,v in ipairs(o) do
            print(i, v)
        end
    end
 end

 function DumpToDiscord(o)
    if type(o) == '!table' then
        for serviceName in ipairs(o) do
            print(serviceName)
            discordia.message.channel:send('service name: ' .. serviceName)
        end
    end
end

--Function to handle API calls
function Api(content)

    if not type(content) == 'table' then
        print("Input must be type of table, something else has been supplied") 
        return "Failed to add user to database"
    else
        content['PASSWD'] = settings['PASSWD']
    end

    local url = settings['APIURL']
    local body = json.encode(content)
    local headers ={{'Content-Type', 'application/json'}}

    local ok, res, body = pcall(http.request, "POST", url, headers, body, 5000)

    if not ok or res.code < 200 or res.code >= 300 then
        print("Failed to connect to api: ".. res.reason) return
    end

    print(body)
    return json.decode(body)['responce']
end

client:run('Bot ' .. settings['BOTTOKEN'])
