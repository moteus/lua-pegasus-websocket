# lua-pegasus-router
Router plugin for [Pegasus](http://evandrolg.github.io/pegasus.lua) server based on [router](https://github.com/APItools/router.lua) library

### Limitations

This plugin just do upgrade and returns raw socket. So user have to use
some other library to handle actuall WebSocket protocol.

### Usage

```Lua
local Pegasus = require "pegasus"
local WebSocket = require "pegasus.plugins.websocket"

local server = Pegasus:new{ plugins = { 
  WebSocket:new{
    protocols = { 'echo' }
  }
} }

server:start(function(request, response)
  -- have to receive full request
  request:receiveBody()

  if request:is_upgrade() then
    local protocol, client = response:upgrade()
    if client then
      -- because we have only one plugin its can be only websocket
      assert(protocol == 'websocket')
      -- detect choosen sub protocol
      protocol = response.headers['Sec-WebSocket-Protocol']
      print("Upgrade to websocket:", protocol)
      print(' - Socket:', client)
      -- here we need wrap `client` to new WebSocket socket
      ....
      return
    end
    print('Can not do upgrade')
  end

end)
```