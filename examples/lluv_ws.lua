-- Deflate extension: https://github.com/moteus/lua-websockets-permessage-deflate

local uv            = require "lluv"
local Pegasus       = require "lluv.pegasus"
local WebSocketBase = require "pegasus.plugins.websocket"
local WebSocketSync = require "lluv.websocket"
local Deflate       = require "websocket.extensions.permessage-deflate"

-- Create new plugin to return `lluv.websocket` socket
local WebSocket = setmetatable({}, WebSocketBase) do
WebSocket.__index = WebSocket

local function unpack_lluv_socket(client)
  local socket = client:socket()
  socket:stop_read()
  local buffer = client._buf:read_all()
  return socket, buffer
end

local function WrapSocket(client, extensions)
  local socket, buffer = unpack_lluv_socket(client)
  local s = WebSocketSync.new(socket)
  s._extensions = extensions
  s:ready(false, buffer)
  return s
end

function WebSocket:processUpgrade(request, response)
  local protocol, client, extensions = WebSocketBase.processUpgrade(self, request, response)
  assert('websocket' == protocol)
  return protocol, WrapSocket(client, extensions)
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

local server = Pegasus:new{port = 8881, plugins={
  WebSocket:new{
    protocols  = { 'echo'  };
    extensions = { Deflate };
  }
}}

local function echo(ws)
  ws:start_read(function(cli, err, frame, opcode)
    if err then 
      print('--- STOP:', cli, err)
      return cli:close()
    end
    print(cli, 'RECV:', frame, opcode)
    cli:write(frame, opcode)
  end)
end

server:start(function(request, response)
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
  end
end)

uv.run()
