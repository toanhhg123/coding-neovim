-- lua/util/spring.lua — thao tác Spring Boot KHÔNG cần LSP: chạy app, test, Maven/Gradle,
-- tìm endpoint/bean, nhảy class <-> test. Lệnh chạy ở tmux pane bên dưới Neovim
-- (ngoài tmux thì dùng terminal split).

local java = require("util.java")

local M = {}

M.debug_port = 5005

M._panes = {}      -- [module] = { app = "%12", task = "%13" }
M._terms = {}      -- ngoài tmux: [module] = { app = { buf, job } }
M._profiles = {}   -- profile đã chọn theo từng project

-- ===== Xác định project =====

local function start_path()
  local name = vim.api.nvim_buf_get_name(0)
  return name ~= "" and not name:match("^%a+://") and vim.fs.dirname(name) or vim.fn.getcwd()
end

--- Thư mục gốc (có wrapper/.git, ưu tiên hơn pom con) và module gần nhất.
function M.project()
  local from = start_path()
  local build_files = { "pom.xml", "build.gradle", "build.gradle.kts" }
  local module = vim.fs.root(from, build_files)
  if not module then return nil end
  local root = vim.fs.root(from, { "mvnw", "gradlew" }) or module
  local maven = vim.fn.filereadable(vim.fs.joinpath(module, "pom.xml")) == 1
  return { root = root, module = module, maven = maven }
end

local function require_project()
  local project = M.project()
  if not project then
    vim.notify("Không tìm thấy pom.xml / build.gradle", vim.log.levels.WARN, { title = "Spring" })
  end
  return project
end

--- Lệnh build: wrapper của project nếu có, không thì mvn/gradle hệ thống.
local function build_cmd(project)
  local win = vim.fn.has("win32") == 1
  if project.maven then
    local wrapper = win and "mvnw.cmd" or "./mvnw"
    local has = vim.fn.filereadable(vim.fs.joinpath(project.root, win and "mvnw.cmd" or "mvnw")) == 1
    local cmd = has and wrapper or "mvn"
    if project.module ~= project.root then
      local rel = vim.fs.relpath(project.root, project.module)
      cmd = cmd .. " -f " .. vim.fn.shellescape(vim.fs.joinpath(rel, "pom.xml"))
    end
    return cmd
  end
  local wrapper = win and "gradlew.bat" or "./gradlew"
  local has = vim.fn.filereadable(vim.fs.joinpath(project.root, win and "gradlew.bat" or "gradlew")) == 1
  local cmd = has and wrapper or "gradle"
  if project.module ~= project.root then
    cmd = cmd .. " -p " .. vim.fn.shellescape(vim.fs.relpath(project.root, project.module))
  end
  return cmd
end

--- Thêm JAVA_HOME đúng version project (vd máy mặc định 25, project cần 21).
local function with_jdk(project, cmd)
  local home = java.project_home(project.module) or java.project_home(project.root)
  if home and vim.fn.has("win32") == 0 then
    return "JAVA_HOME=" .. vim.fn.shellescape(home) .. " " .. cmd
  end
  return cmd
end

-- ===== Chạy lệnh trong tmux pane / terminal =====

-- Module riêng có thể chạy app riêng dù dùng chung wrapper ở project.root.
local function project_key(project)
  return vim.uv.fs_realpath(project.module) or vim.fs.normalize(project.module)
end

local function tmux(args)
  local result = vim.system(vim.list_extend({ "tmux" }, args), { text = true }):wait()
  return result.code == 0, vim.trim(result.stdout or "")
end

local function pane_alive(id)
  if not id then return false end
  local ok, panes = tmux({ "list-panes", "-a", "-F", "#{pane_id}" })
  return ok and vim.tbl_contains(vim.split(panes, "\n"), id)
end

local function run_in_tmux(kind, project, cmd)
  local key, root = project_key(project), project.root
  local panes = M._panes[key] or {}
  M._panes[key] = panes
  local id = panes[kind]
  if pane_alive(id) then
    tmux({ "send-keys", "-t", id, "C-c" })
  else
    local other = panes[kind == "app" and "task" or "app"]
    local args = pane_alive(other)
        and { "split-window", "-h", "-d", "-t", other, "-c", root, "-P", "-F", "#{pane_id}" }
      or { "split-window", "-v", "-d", "-l", "30%", "-t", vim.env.TMUX_PANE, "-c", root, "-P", "-F", "#{pane_id}" }
    local ok
    ok, id = tmux(args)
    if not ok then
      vim.notify("Không mở được tmux pane: " .. id, vim.log.levels.ERROR, { title = "Spring" })
      return
    end
    panes[kind] = id
  end
  tmux({ "send-keys", "-t", id, "-l", "cd " .. vim.fn.shellescape(root) .. " && " .. cmd })
  tmux({ "send-keys", "-t", id, "Enter" })
end

local function run_in_term(kind, project, cmd)
  local key = project_key(project)
  local terms = M._terms[key] or {}
  M._terms[key] = terms
  local term = terms[kind]
  if term and vim.api.nvim_buf_is_valid(term.buf) then
    pcall(vim.fn.jobstop, term.job)
    pcall(vim.api.nvim_buf_delete, term.buf, { force = true })
  end
  local current = vim.api.nvim_get_current_win()
  vim.cmd("botright 15new")
  local buf = vim.api.nvim_get_current_buf()
  local shell = vim.fn.has("win32") == 1 and { "cmd", "/c", cmd } or { vim.o.shell, "-c", cmd }
  local job = vim.fn.jobstart(shell, { term = true, cwd = project.root })
  terms[kind] = { buf = buf, job = job }
  vim.api.nvim_set_current_win(current)
end

--- kind = "app" (app đang chạy) | "task" (test/build), để chạy test không giết app.
function M.exec(kind, project, cmd)
  local full = with_jdk(project, cmd)
  if vim.env.TMUX then
    run_in_tmux(kind, project, full)
  else
    run_in_term(kind, project, full)
  end
  -- redraw + cắt ngắn: sau menu chọn hoặc thông báo dài, Neovim sẽ hiện "Press ENTER" và nuốt phím kế tiếp
  vim.cmd.redraw()
  vim.notify(vim.fn.strcharpart(cmd, 0, vim.o.columns - 20), vim.log.levels.INFO, { title = "Spring" })
end

--- Dừng app của module hiện tại.
function M.stop()
  local project = require_project()
  if not project then return end
  local key = project_key(project)
  local panes, terms = M._panes[key] or {}, M._terms[key] or {}
  if vim.env.TMUX and pane_alive(panes.app) then
    tmux({ "send-keys", "-t", panes.app, "C-c" })
  elseif terms.app then
    pcall(vim.fn.jobstop, terms.app.job)
  else
    vim.notify("Chưa có app nào đang chạy", vim.log.levels.INFO, { title = "Spring" })
  end
end

-- ===== Chạy app =====

local function run_cmd(project, profile, debug)
  local cmd = build_cmd(project)
  if project.maven then
    cmd = cmd .. " spring-boot:run"
    if profile then cmd = cmd .. " -Dspring-boot.run.profiles=" .. vim.fn.shellescape(profile) end
    if debug then
      cmd = cmd
        .. " -Dspring-boot.run.jvmArguments="
        .. vim.fn.shellescape("-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:" .. M.debug_port)
    end
    return cmd
  end
  cmd = cmd .. " bootRun"
  if profile then cmd = cmd .. " --args=" .. vim.fn.shellescape("--spring.profiles.active=" .. profile) end
  if debug then cmd = cmd .. " --debug-jvm" end -- Gradle: chờ debugger attach ở cổng 5005
  return cmd
end

--- Profile lấy từ application-<profile>.(yml|yaml|properties) trong resources.
function M.profiles(project)
  local names, seen = {}, {}
  local pattern = vim.fs.joinpath(project.module, "src/main/resources/application-*")
  for _, path in ipairs(vim.fn.glob(pattern, true, true)) do
    local name = vim.fs.basename(path):match("^application%-(.+)%.%a+$")
    if name and not seen[name] then
      seen[name] = true
      table.insert(names, name)
    end
  end
  table.sort(names)
  return names
end

local NO_PROFILE, OTHER = "(không profile)", "Nhập tay..."

local function pick_profile(project, callback)
  local items = M.profiles(project)
  table.insert(items, 1, NO_PROFILE)
  table.insert(items, OTHER)
  vim.ui.select(items, { prompt = "Spring profile" }, function(choice)
    if not choice then return end
    if choice == OTHER then
      vim.ui.input({ prompt = "Profile: " }, function(value)
        if value and value ~= "" then callback(value) end
      end)
    else
      callback(choice ~= NO_PROFILE and choice or false)
    end
  end)
end

local function start(debug, ask)
  local project = require_project()
  if not project then return end
  local function go(profile)
    M._profiles[project.module] = profile
    M.exec("app", project, run_cmd(project, profile or nil, debug))
  end
  local known = M._profiles[project.module]
  if known ~= nil and not ask then
    go(known)
  else
    pick_profile(project, go)
  end
end

function M.run() start(false, false) end
function M.run_pick_profile() start(false, true) end
function M.run_debug() start(true, false) end

-- ===== Test =====

--- Class test tương ứng: file trong src/main thì lấy <Class>Test / Tests / IT nếu có.
local function test_class_name()
  local path = vim.api.nvim_buf_get_name(0)
  if vim.fn.fnamemodify(path, ":e") ~= "java" then return nil end
  if path:find("/src/main/java/", 1, true) then
    local counterpart = M.counterpart(path)
    return counterpart and vim.fn.fnamemodify(counterpart, ":t:r") or nil
  end
  return vim.fn.fnamemodify(path, ":t:r")
end

local function test_filter(project, class, method)
  local cmd = build_cmd(project)
  if project.maven then
    local filter = method and (class .. "#" .. method) or class
    return cmd .. " test -Dtest=" .. vim.fn.shellescape(filter) .. " -Dsurefire.failIfNoSpecifiedTests=false"
  end
  local filter = method and ("*" .. class .. "." .. method) or ("*" .. class)
  return cmd .. " test --tests " .. vim.fn.shellescape(filter)
end

function M.test_class()
  local project = require_project()
  if not project then return end
  local class = test_class_name()
  if not class then
    return vim.notify("File này không có test tương ứng", vim.log.levels.WARN, { title = "Spring" })
  end
  M.exec("task", project, test_filter(project, class))
end

--- Tên method đang đứng trong, dựa trên treesitter.
function M.current_method()
  local ok, node = pcall(vim.treesitter.get_node)
  while ok and node do
    if node:type() == "method_declaration" then
      local name = node:field("name")[1]
      return name and vim.treesitter.get_node_text(name, 0) or nil
    end
    node = node:parent()
  end
end

function M.test_method()
  local project = require_project()
  if not project then return end
  local method = M.current_method()
  if not method or vim.api.nvim_buf_get_name(0):find("/src/main/java/", 1, true) then
    return vim.notify("Đặt con trỏ trong một method của file test", vim.log.levels.WARN, { title = "Spring" })
  end
  M.exec("task", project, test_filter(project, vim.fn.expand("%:t:r"), method))
end

function M.test_all()
  local project = require_project()
  if project then M.exec("task", project, build_cmd(project) .. " test") end
end

-- ===== Lệnh Maven/Gradle =====

local GOALS = {
  maven = {
    "clean verify",
    "package -DskipTests",
    "test",
    "dependency:tree",
    "dependency:analyze",
    "versions:display-dependency-updates",
    "flyway:info",
    "flyway:validate",
    "flyway:migrate",
    "spring-boot:build-image",
  },
  gradle = { "clean build", "bootJar", "test", "dependencies", "bootBuildImage", "flywayInfo", "flywayValidate", "flywayMigrate" },
}

function M.goals()
  local project = require_project()
  if not project then return end
  local items = vim.deepcopy(project.maven and GOALS.maven or GOALS.gradle)
  table.insert(items, OTHER)
  vim.ui.select(items, { prompt = project.maven and "Maven" or "Gradle" }, function(choice)
    if not choice then return end
    if choice == OTHER then
      vim.ui.input({ prompt = "Lệnh: " }, function(value)
        if value and value ~= "" then M.exec("task", project, build_cmd(project) .. " " .. value) end
      end)
    else
      M.exec("task", project, build_cmd(project) .. " " .. choice)
    end
  end)
end

-- ===== Tìm nhanh bằng ripgrep (không cần LSP) =====

local function grep(project, title, regex)
  require("telescope.builtin").grep_string({
    prompt_title = title,
    search = regex,
    use_regex = true,
    cwd = project.root,
    glob_pattern = "*.java",
  })
end

function M.endpoints()
  local project = require_project()
  if project then grep(project, "Spring Endpoints", [[@(Get|Post|Put|Delete|Patch|Request)Mapping\b]]) end
end

function M.beans()
  local project = require_project()
  if project then
    grep(project, "Spring Beans", [[@(RestController|Controller|Service|Repository|Component|Configuration|Bean)\b]])
  end
end

function M.resources()
  local project = require_project()
  if project then
    require("telescope.builtin").find_files({
      prompt_title = "Resources (application.yml, migration...)",
      cwd = vim.fs.joinpath(project.module, "src/main/resources"),
    })
  end
end

-- ===== Class <-> Test =====

--- Tìm file tương ứng. Trả về path nếu đã tồn tại, cùng path gợi ý để tạo mới.
function M.counterpart(path)
  if path:find("/src/test/java/", 1, true) then
    local class = vim.fn.fnamemodify(path, ":t:r")
    local base = class:gsub("IT$", ""):gsub("Tests?$", "")
    local main = vim.fs.joinpath(vim.fs.dirname((path:gsub("/src/test/java/", "/src/main/java/", 1))), base .. ".java")
    return vim.fn.filereadable(main) == 1 and main or nil, main
  end
  if path:find("/src/main/java/", 1, true) then
    local dir = vim.fs.dirname((path:gsub("/src/main/java/", "/src/test/java/", 1)))
    local class = vim.fn.fnamemodify(path, ":t:r")
    for _, suffix in ipairs({ "Test", "Tests", "IT" }) do
      local candidate = vim.fs.joinpath(dir, class .. suffix .. ".java")
      if vim.fn.filereadable(candidate) == 1 then return candidate end
    end
    return nil, vim.fs.joinpath(dir, class .. "Test.java")
  end
end

--- Nhảy class <-> test; chưa có test thì mở file mới với khung JUnit 5 (chưa lưu).
function M.toggle_test()
  local path = vim.api.nvim_buf_get_name(0)
  local existing, suggested = M.counterpart(path)
  if existing then return vim.cmd.edit(vim.fn.fnameescape(existing)) end
  if not suggested or path:find("/src/test/java/", 1, true) then
    return vim.notify("Không có file tương ứng", vim.log.levels.WARN, { title = "Spring" })
  end
  vim.fn.mkdir(vim.fs.dirname(suggested), "p")
  vim.cmd.edit(vim.fn.fnameescape(suggested))
  local package_name = suggested:match("/src/test/java/(.+)/[^/]+$")
  local lines = {}
  if package_name then
    vim.list_extend(lines, { "package " .. package_name:gsub("/", ".") .. ";", "" })
  end
  vim.list_extend(lines, {
    "import org.junit.jupiter.api.Test;",
    "",
    "class " .. vim.fn.fnamemodify(suggested, ":t:r") .. " {",
    "",
    "    @Test",
    "    void shouldWork() {",
    "    }",
    "}",
  })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

-- ===== Docker =====

function M.docker()
  if vim.fn.executable("lazydocker") == 0 then
    return vim.notify("Chưa cài lazydocker", vim.log.levels.WARN, { title = "Spring" })
  end
  if vim.env.TMUX then
    tmux({ "display-popup", "-E", "-w", "90%", "-h", "90%", "lazydocker" })
  else
    vim.cmd("tabnew | terminal lazydocker")
    vim.cmd.startinsert()
  end
end

return M
