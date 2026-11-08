vim.opt.rtp:prepend(vim.fn.getcwd())
local case = assert(arg[1])
local original_clients, original_timer = vim.lsp.get_clients, vim.uv.new_timer
local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end
local project = { root = "/fake/a", module = "/fake/a/module", maven = true }
local stopped, configs, warnings, timers, launch_opts = {}, {}, {}, {}, nil
local active
local spring = {
  debug_port = 5005,
  project = function() return project end,
  run_debug = function(opts) launch_opts = opts end,
  stop = function(p) table.insert(stopped, p or "current") end,
}
package.loaded["util.spring"] = spring
local dap = {
  adapters = { java = {} }, session = function() return active end,
  run = function(config) table.insert(configs, config) end,
  terminate = function(opts) assert(opts.disconnect_args.terminateDebuggee); active = nil end,
}
package.loaded.dap = dap
vim.notify = function(message) table.insert(warnings, message) end
vim.lsp.get_clients = function() return { { config = { root_dir = "/fake/a" } } } end
vim.uv.new_timer = function()
  local timer = {}
  function timer:start(_, _, fn) self.tick = fn end
  function timer:stop() self.stopped = true end
  function timer:close() self.closed = true end
  table.insert(timers, timer)
  return timer
end
local function tick()
  timers[#timers].tick()
  vim.wait(10, function() return false end)
end
local debugger = require("util.debug")
local output = ""
vim.system = function(args, _, callback)
  equal("capture-pane", args[2])
  callback({ code = 0, stdout = output })
end
local function launch(kind)
  debugger.start()
  assert(launch_opts and launch_opts.can_start())
  if kind == "term" then
    local buf = vim.api.nvim_create_buf(false, true)
    launch_opts.on_started(project, { kind = "term", buf = buf })
    return buf
  end
  launch_opts.on_started(project, { kind = "tmux", id = "%11" })
end
local cases = {}

function cases.ready_tmux()
  launch()
  output = "Listening for transport dt_socket at address: 5005\n" .. launch_opts.marker .. "\nbuilding"
  tick()
  equal(0, #configs) -- old JVM log must not trigger attach
  output = launch_opts.marker .. "\nListening for transport dt_socket at address: 50050"
  tick()
  equal(0, #configs)
  output = "Listening for transport dt_socket at address: 5005"
  spring.project = function() return { root = "/fake/b", module = "/fake/b" } end
  tick()
  equal(1, #configs)
  equal(project, configs[1]._coding_nvim_project)
  equal("/fake/a", configs[1].cwd)
  equal(5005, configs[1].port)
  assert(debugger.pending == nil and timers[1].closed)
end

function cases.ready_term()
  local buf = launch("term")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { launch_opts.marker, "Listening for transport dt_socket at address: 5005" })
  tick()
  equal(1, #configs)
  assert(timers[1].closed)
end

function cases.timeout()
  debugger.timeout_ms = 0
  launch()
  tick()
  equal(0, #configs)
  assert(debugger.pending == nil and timers[1].closed and #warnings == 1)
end

function cases.cancel_wait()
  launch()
  output = launch_opts.marker .. "\nListening for transport dt_socket at address: 5005"
  debugger.stop()
  tick()
  equal(0, #configs)
  equal({ project }, stopped)
  assert(not launch_opts.can_start() and timers[1].closed)
end

function cases.cancel_profile()
  debugger.start()
  launch_opts.on_cancel()
  assert(debugger.pending == nil)
  debugger.start()
  debugger.stop()
  assert(not launch_opts.can_start())
  equal(0, #timers)
end

function cases.stop_dap()
  active = { config = { request = "launch" } }
  debugger.stop()
  assert(active == nil)
  equal({}, stopped) -- do not stop an unrelated Spring app in the current buffer
  active = { config = { _coding_nvim_project = project } }
  debugger.stop()
  equal({ project }, stopped)
  debugger.stop()
  equal({ project, "current" }, stopped)
end

function cases.guards()
  vim.lsp.get_clients = function() return { { config = { root_dir = "/fake/another-project" } } } end
  debugger.start()
  assert(launch_opts == nil and debugger.pending == nil)
  vim.lsp.get_clients = function() return { { config = { root_dir = "/fake/a" } } } end
  active = { config = {} }
  debugger.start()
  assert(launch_opts == nil)
  active = nil
  dap.adapters.java = nil
  package.loaded.jdtls = { setup_dap = function() end }
  debugger.start()
  assert(launch_opts == nil, "started JVM without Java adapter")
end

function cases.narrow_terminal()
  package.loaded["util.spring"] = nil
  local real_spring = require("util.spring")
  require("util.java")._jdks = {}
  local temp = vim.fn.tempname()
  vim.fn.mkdir(temp, "p")
  local p = { root = temp, module = temp }
  real_spring.project = function() return p end
  vim.lsp.get_clients = function() return { { config = { root_dir = temp } } } end
  vim.env.TMUX, vim.o.columns = nil, 30
  local handle
  real_spring.run_debug = function(opts)
    handle = real_spring.exec("app", p, "printf 'Listening for transport dt_socket at address: 5005\\n'; sleep 2", opts)
    opts.on_started(p, handle)
  end
  debugger.start()
  assert(vim.wait(1000, function() return handle.output:find("5005", 1, true) ~= nil end, 10), "no raw terminal output")
  tick()
  local attached = #configs
  vim.fn.jobstop(handle.job)
  vim.fn.delete(temp, "rf")
  equal(1, attached)
end

local ok, err = xpcall(assert(cases[case], "unknown case"), debug.traceback)
if debugger.pending then debugger.stop() end
vim.lsp.get_clients, vim.uv.new_timer = original_clients, original_timer
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
print("PASS: " .. case)
