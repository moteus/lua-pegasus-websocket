package = 'pegasus-websocket'
version = 'scm-0'

source = {
  url = "https://github.com/moteus/lua-pegasus-websocket/archive/master.zip",
  dir = "lua-pegasus-websocket-master",
}

description = {
  summary = 'WebSocket plugin for Pegasus http server',
  homepage = 'https://github.com/moteus/lua-pegasus-websocket',
  license = 'MIT'
}

dependencies = {
  "lua >= 5.1, < 5.4",
  "pegasus",
  -- "lua-websockets-extensions",
}

build = {
  type = "builtin",
  modules = {
    ['pegasus.plugins.websocket'      ] = 'src/pegasus/plugins/websocket.lua',
    ['pegasus.plugins.websocket.bit'  ] = 'src/pegasus/plugins/websocket/bit.lua',
    ['pegasus.plugins.websocket.tools'] = 'src/pegasus/plugins/websocket/tools.lua',
  }
}
