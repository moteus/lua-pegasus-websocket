local copas         = require "copas"
local socket        = require "socket"
local Handler       = require "pegasus.handler"
local WebSocketBase = require "pegasus.plugins.websocket"
local WebSocketSync = require "websocket.client_sync"

-- Create new plugin to return `websocket.client_sync` socket
local WebSocket = setmetatable({}, WebSocketBase) do
WebSocket.__index = WebSocket

local function WrapSocket(client)
  local ws = WebSocketSync()
  ws.sock = client
  ws.state = 'OPEN'
  ws.is_server = true
  client:settimeout(-1)
  return ws
end

function WebSocket:processUpgrade(request, response)
  local protocol, client, extensions = WebSocketBase.processUpgrade(self, request, response)
  assert('websocket' == protocol)
  assert(nil == extensions, 'Extensions does not supported')
  return protocol, WrapSocket(client)
end

end

local function echo(client)
  while true do
    local frame, opcode, was_clean, code, reason = client:receive()
    if not frame then
      print('--- STOP:', was_clean, code, reason)
      break
    end
    print(client, 'RECV:', frame, opcode)
    client:send(frame, opcode)
  end
  client:close()
end

local handler = Handler:new(function(request, response)
  request:headers()
  request:receiveBody()

  if request:is_upgrade() then
    local protocol, client = response:upgrade()
    if client then
      print("Upgrade to:", protocol)
      print(' - Socket:', client)
      if protocol == 'websocket' then
        protocol = response.headers['Sec-WebSocket-Protocol']
        print(" - WebSocket protocol:", protocol or "*")
        return echo(client)
      end
      return client:close()
    end
    print('Can not do upgrade')
    response:sendOnlyHeaders()
  end
end, nil, {  WebSocket:new({protocols = {'echo'}}) })

-- Create http server
local server = assert(socket.bind('*', 8881))
local ip, port = server:getsockname()

copas.addserver(server, copas.handler(function(skt)
  handler:processRequest(8881, skt)
end))

print('Pegasus is up on ' .. ip .. ":".. port)

-- Start
copas.loop()