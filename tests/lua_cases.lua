-- Chạy bằng Neovim -u NONE; không nạp plugin hoặc gọi tmux thật.
vim.opt.rtp:prepend(vim.fn.getcwd())
local case = assert(arg[1], "missing test case")
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")

local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
end

local function project(name)
  local root = temp .. "/" .. name
  write(root .. "/pom.xml", { "<project/>" })
  return { root = root, module = root, maven = true }
end

local function select_project(p)
  vim.cmd.enew()
  vim.api.nvim_buf_set_name(0, p.module .. "/App.java")
end

local cases = {}

function cases.syntax()
  for _, path in ipairs(vim.fn.globpath(vim.fn.getcwd(), "**/*.lua", false, true)) do
    assert(loadfile(path))
  end
end

function cases.java_home()
  local java = require("util.java")
  local home, other = temp .. "/custom jdk", temp .. "/other-jdk"
  for _, dir in ipairs({ home, other }) do
    write(dir .. "/release", { 'JAVA_VERSION="21.0.5"' })
    write(dir .. "/bin/java", { "#!/bin/sh", "exit 0" })
    vim.fn.setfperm(dir .. "/bin/java", "rwxr-xr-x")
  end
  vim.env.JAVA_HOME = home .. "/"
  vim.fn.glob = function() return { other } end
  equal(home, java.jdks()[21])
  local p = project("java-project")
  write(p.root .. "/pom.xml", { "<project><properties><java.version>21</java.version></properties></project>" })
  equal(home, java.project_home(p.root))
  equal({ { name = "JavaSE-21", path = home, default = true } }, java.runtimes(p.root))

  -- JAVA_HOME hỏng không được che khuất JDK hợp lệ tìm thấy trên máy.
  java._jdks = nil
  vim.fn.delete(home .. "/bin/java")
  equal(other, java.jdks()[21])
end

function cases.java_special_files()
  local java = require("util.java")
  for _, name in ipairs({ "package-info.java", "module-info.java" }) do
    equal(nil, java.skeleton(temp .. "/src/main/java/com/example/" .. name))
  end
  equal({ "package com.example;", "", "public class App {", "", "}" },
    java.skeleton(temp .. "/src/main/java/com/example/App.java"))
  assert(table.concat(java.skeleton(temp .. "/src/main/java/com/example/AppService.java"), "\n"):find("@Service", 1, true))
end

function cases.java_autocmd()
  require("config.autocmds")
  for _, name in ipairs({ "package-info.java", "module-info.java" }) do
    local path = temp .. "/src/main/java/com/example/" .. name
    vim.cmd.edit(vim.fn.fnameescape(path))
    equal({ "" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    equal(false, vim.bo.modified)
    -- neo-tree tạo file trên đĩa trước khi mở: đi qua BufReadPost.
    vim.cmd.bwipeout({ bang = true })
    write(path, {})
    vim.cmd.edit(vim.fn.fnameescape(path))
    equal({ "" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    equal(false, vim.bo.modified)
  end
  vim.cmd.edit(vim.fn.fnameescape(temp .. "/src/main/java/com/example/App.java"))
  equal("public class App {", vim.api.nvim_buf_get_lines(0, 2, 3, false)[1])
end

function cases.spring_tmux()
  local spring = require("util.spring")
  require("util.java")._jdks = {}
  vim.env.TMUX, vim.env.TMUX_PANE = "fake-server", "%1"
  vim.notify = function() end
  local calls, alive, next_id = {}, {}, 10
  vim.system = function(args)
    table.insert(calls, args)
    local out = ""
    if args[2] == "split-window" then
      next_id = next_id + 1
      out = "%" .. next_id
      table.insert(alive, out)
    elseif args[2] == "list-panes" then
      out = table.concat(alive, "\n")
    end
    return { wait = function() return { code = 0, stdout = out } end }
  end
  local function interrupts()
    local ids = {}
    for _, args in ipairs(calls) do
      if args[2] == "send-keys" and args[5] == "C-c" then table.insert(ids, args[4]) end
    end
    return ids
  end
  local a, b = project("a"), project("b")
  spring.exec("app", a, "echo A") -- %11
  spring.exec("app", b, "echo B") -- %12
  equal({}, interrupts())
  spring.exec("task", a, "echo test") -- %13: app A vẫn chạy
  equal({}, interrupts())
  spring.exec("app", a, "echo restart")
  equal({ "%11" }, interrupts())
  select_project(b)
  spring.stop()
  equal({ "%11", "%12" }, interrupts())
  -- Hai module chung wrapper cũng phải có app riêng.
  local child = { root = a.root, module = a.root .. "/child", maven = true }
  write(child.module .. "/pom.xml", { "<project/>" })
  spring.exec("app", child, "echo child")
  equal({ "%11", "%12" }, interrupts())
  select_project(child)
  spring.stop()
  equal({ "%11", "%12", "%14" }, interrupts())
  select_project(project("not-running"))
  spring.stop()
  equal({ "%11", "%12", "%14" }, interrupts())
end

function cases.spring_terminal()
  local spring = require("util.spring")
  require("util.java")._jdks = {}
  vim.env.TMUX = nil
  vim.notify = function() end
  local jobs, stopped = {}, {}
  vim.fn.jobstart = function(_, opts)
    table.insert(jobs, { cwd = opts.cwd, buf = vim.api.nvim_get_current_buf() })
    return #jobs
  end
  vim.fn.jobstop = function(id) table.insert(stopped, id) end
  local a, b = project("a"), project("b")
  spring.exec("app", a, "echo A")
  spring.exec("app", b, "echo B")
  spring.exec("task", a, "echo test")
  equal({}, stopped)
  assert(vim.api.nvim_buf_is_valid(jobs[1].buf))
  spring.exec("app", a, "echo restart")
  equal({ 1 }, stopped)
  assert(not vim.api.nvim_buf_is_valid(jobs[1].buf))
  assert(vim.api.nvim_buf_is_valid(jobs[2].buf))
  select_project(b)
  spring.stop()
  equal({ 1, 2 }, stopped)
  select_project(project("not-running"))
  spring.stop()
  equal({ 1, 2 }, stopped)
end

function cases.spring_debug_runner()
  local spring = require("util.spring")
  local p = project("debug-project")
  write(p.root .. "/pom.xml", { "<project><java.version>21</java.version></project>" })
  require("util.java")._jdks = { [21] = temp .. "/custom jdk" }
  vim.env.TMUX = nil
  vim.notify = function() end
  local command, job_opts
  vim.fn.jobstart = function(shell, opts) command, job_opts = shell[#shell], opts; return 1 end
  spring._profiles[p.module] = false
  select_project(p)
  local started
  spring.run_debug({ marker = "test-ready-marker", on_started = function(_, handle) started = handle end })
  assert(command:find("printf '%s\\n' 'test-ready-marker' && JAVA_HOME=", 1, true), command)
  assert(command:find("suspend=y,address=*:5005", 1, true), command)
  assert(job_opts.on_stdout and started.kind == "term")
  job_opts.on_stdout(1, { "partial", "out" })
  job_opts.on_stdout(1, { "put", "" })
  equal("partial\noutput\n", started.output)
  -- Stop trong lúc menu profile mở phải chặn callback cũ chạy app về sau.
  spring._profiles[p.module] = nil
  local choose, allowed = nil, true
  vim.ui.select = function(_, _, callback) choose = callback end
  command = nil
  spring.run_debug({ can_start = function() return allowed end })
  allowed = false
  choose("(không profile)")
  equal(nil, command)
end

function cases.markdown_image()
  local spec
  for _, plugin in ipairs(dofile(vim.fn.getcwd() .. "/lua/plugins/markdown.lua")) do
    if plugin[1] == "HakonHarnes/img-clip.nvim" then spec = plugin end
  end
  assert(spec, "img-clip chưa được khai báo")
  -- Nạp cùng file markdown để kéo-thả ảnh hoạt động, không chỉ khi bấm phím
  equal({ "markdown" }, spec.ft)
  local key = spec.keys[1]
  equal({ "<leader>mi", "<cmd>PasteImage<CR>", "markdown" }, { key[1], key[2], key.ft })
  local opts = spec.opts.default
  equal("assets", opts.dir_path)
  equal(true, opts.relative_to_current_file)
  equal(true, opts.copy_images)
end

local ok, err = xpcall(assert(cases[case], "unknown case: " .. case), debug.traceback)
vim.fn.delete(temp, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
print("PASS: " .. case)
