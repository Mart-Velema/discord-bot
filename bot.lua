Discordia = require('discordia')
Json = require('json')
Http = require('coro-http')
Client = Discordia.Client()

local file = io.open("discord-bot/settings.json", "r")
if file then
    local content = file:read("*a")
    file:close()
    Settings = Json.decode(content)
else
    print("Failed to find settings file, shutdown")
    os.exit()
end

Client:on('ready', function ()
    print('Logged in as' .. Client.user.username)
    Time = os.time()
end)

Client:on('messageCreate', function(message)
    --Detect if message is form a bot, don't do anything else if so
    if message.author.bot then
        return
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
            REQUEST = 'LIST_SERVICES'
        }
        local responce = Api(content)
        if type(responce) == 'table' then
            for serviceId, serviceName in ipairs(responce) do
                if  serviceId >= 5 then
                    message.channel:send(serviceName)
                end
            end
            message.channel:send("use `!join <service name>:<username of service>` to join that service")
        else
            message.channel:send(responce)
        end
    end

    --Add a user to the services database
    --format - !join service:serviceAccountName
    if message.content:sub(1, 5) == '!join' then
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
            '!reload: Reloads all the bans and whitelists from the database. Can only be used once an hour\n' ..
            '!list: prints a list of all the available services\n' ..
            '!join: Allows you to join any of the available services\n```'
        )
    end

    if message.content == '!linux' then
        message.channel:send(
            "I'd just like to interject for a moment. What you're refering to as Linux, is in fact, GNU/Linux, or as I've recently taken to calling it, GNU plus Linux. Linux is not an operating system unto itself, but rather another free component of a fully functioning GNU system made useful by the GNU corelibs, shell utilities and vital system components comprising a full OS as defined by POSIX.\n\n" ..
            "Many computer users run a modified version of the GNU system every day, without realizing it. Through a peculiar turn of events, the version of GNU which is widely used today is often called Linux, and many of its users are not aware that it is basically the GNU system, developed by the GNU Project.\n\n"..
            "There really is a Linux, and these people are using it, but it is just a part of the system they use. Linux is the kernel: the program in the system that allocates the machine's resources to the other programs that you run. The kernel is an essential part of an operating system, but useless by itself; it can only function in the context of a complete operating system. Linux is normally used in combination with the GNU operating system: the whole system is basically GNU with Linux added, or GNU/Linux. All the so-called Linux distributions are really distributions of GNU/Linux!"
        )
    end

    if message.content == '!windows' then
        message.channel:send('https://tenor.com/view/mad200-heavy-tf2-percentage-rage-gif-16820921')
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

    --Unban command
    if message.content:sub(1, 6) == '!unban' or message.content:sub(1, 7) == '!pardon' then
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
    if message.content == '!moo' then
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

    --reload command
    if message.content == '!reload' then
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

    --Kill command :3
    if message.content == '!fuck-off!' then
        if not message.member:hasPermission("banMembers") then
            message.channel:reply("You cannot stop me! :3") return
        end
        message.channel:send("Fucking off...")
        os.exit()
    end
end)

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
    local body = Json.encode(content)
    local headers ={{'Content-Type', 'application/json'}}

    local ok, res, body = pcall(Http.request, "POST", url, headers, body, 5000)

    if not ok or res.code < 200 or res.code >= 300 then
        print("Failed to connect to api: ".. res.reason) return
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
