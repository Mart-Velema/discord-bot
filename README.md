# discord-bot
A discord bot made in Lua using Discordia

# Dependencies
- [Luvit](https://luvit.io/install.html)
- [Discordia](https://github.com/SinisterRectus/Discordia)
- [coro-http](https://bilal2453.github.io/coro-docs/docs/coro-http.html)


# installation
Install the dependencies by:
Luvit:
```
curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh
```
Make sure to enter the directory where you isntalled Luvit to before continiueing

Discordia:
```
lit install SinisterRectus/discordia
```
coro-http:
```
lit install creationix/coro-http
```

Then clone this repo into the same directory
```
git clone https://github.com/Mart-Velema/discord-bot.git
```

Tweak the contents of the bot.lua to your likings. Once you're done, run the bot by:
```
luvit discord-bot/bot.lua
```
