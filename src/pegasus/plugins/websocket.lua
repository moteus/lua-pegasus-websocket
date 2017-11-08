local tools = require "pegasus.plugins.websocket.tools"
local Extensions = tools.prequire "websocket.extensions"

local sha1, base64, split, unquote =
  tools.sha1, tools.base64, tools.split, tools.unquote

local guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

local function sec_websocket_accept(sec_websocket_key)
  local a = sec_websocket_key .. guid
  local sha1 = sha1(a)
  return base64.encode(sha1)
end

local WebSocket = {} do
WebSocket.__index = WebSocket

function WebSocket:new(opt)
  local o = setmetatable({}, self)
  o._protocols = opt and opt.protocols or {}
  if Extensions then
    if opt and opt.extensions and #opt.extensions > 0 then
      o._extensions = Extensions.new()
      for _, ext in ipairs(opt.extensions) do
        assert(o._extensions:reg(ext))
      end
    end
  end
  return o
end

function WebSocket:processUpgrade(request, response)
  local headers = request:headers()

  local Upgrade, Connection, Key, Version, Protocol, Extensions =
    headers['Upgrade'], headers['Connection'],
    headers['Sec-WebSocket-Key'], headers['Sec-WebSocket-Version'],
    headers['Sec-WebSocket-Protocol'], headers['Sec-WebSocket-Extensions']

  if not Upgrade or not Connection or not Key or not Version then
    return
  end

  local accept
  for protocol in split.iter(Upgrade, "%s*,%s*") do
    protocol = string.lower(unquote(protocol))
    accept = (protocol == 'websocket')
    if accept then break end
  end
  if not accept then return end

  accept = false
  for connection in split.iter(Connection, "%s*,%s*") do
    connection = string.lower(unquote(connection))
    accept = (connection == 'upgrade')
    if accept then break end
  end
  if not accept then return end

  accept = unquote(Version) == '13'
  if not accept then return end

  local protocol
  if Protocol and #Protocol > 0 then
    local protocols = self._protocols
    if protocols then
      for proto in split.iter(Protocol, "%s*,%s*") do
        proto = unquote(proto)
        for i = 1, #protocols do
          if protocols[i] == proto then
            protocol = proto
            break
          end
        end
      end
    else -- if we have no protocols then choose first one
      protocol = split.first(Protocol, "%s*,%s*")
      protocol = unquote(protocol)
    end

    -- we do not support required protocol
    if not protocol then
      return
    end
  end

  local accept_key = sec_websocket_accept(Key)

  response:statusCode(101)
  response:addHeader('Connection', 'Upgrade')
  response:addHeader('Upgrade',    'websocket')
  response:addHeader('Sec-WebSocket-Accept', accept_key)
  if protocol then
    response:addHeader('Sec-WebSocket-Protocol', protocol)
  end

  if self._extensions and Extensions and #Extensions > 0 then
    local header, err = self._extensions:response(Extensions)
    if header then
      response:addHeader('Sec-Websocket-Extensions', header)
    elseif err then
      response:statusCode(400, err:msg())
      return
    end
  end

  -- Do upgrade
  response:sendOnlyHeaders()

  -- Now connection is no more HTTP
  local client = request.client
  request.client, response.client = nil

  return 'websocket', client, self._extensions
end

end

return WebSocket