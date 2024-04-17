# discord-bot
A discord bot made in Lua using Discordia

# Dependencies
- [Luvit](https://luvit.io/install.html)
- [Discordia](https://github.com/SinisterRectus/Discordia)
- [coro-http](https://bilal2453.github.io/coro-docs/docs/coro-http.html)


# installation
## Install the dependencies:
Luvit:
```
curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh
```
Make sure to enter the directory where you isntalled Luvit to before continiueing

Discordia:
```
./lit install SinisterRectus/discordia
```
Coro-HTTP:
```
./lit install creationix/coro-http
```

## Cloning the repo
Clone this repo into the same directory
```
git clone https://github.com/Mart-Velema/discord-bot.git
```

## setting up SQLite
SQLite is not a requirement for the bot to execute API calls, but is required to use the minigames functionality

Installing SQLite on Debian:
```
sudo apt update -y
sudo apt install sqlite3 libsqlite3-dev -y
```

SQLite Luvit dependency:
```
./lit install SinisterRectus/sqlite3
```

Rename the `format.db` to `database.db`
```
mv format.db database.db
```

## Running the bot
Tweak the contents of the bot.lua to your likings. Once you're done, run the bot by:
```
./luvit discord-bot/bot.lua
```
