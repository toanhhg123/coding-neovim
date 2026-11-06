-- lua/util/java.lua — dò JDK trên máy + version Java của project (không hardcode đường dẫn)
-- Dùng được trên macOS/Linux/Windows: sdkman, JVM hệ thống, JAVA_HOME.

local M = {}

local exe = vim.fn.has("win32") == 1 and "java.exe" or "java"

local function java_bin(home)
  return vim.fs.joinpath(home, "bin", exe)
end

local function major_from_name(name)
  local legacy = name:match("^1%.(%d+)") -- vd 1.8.0_392, phải neo đầu chuỗi để không khớp 21.0.5
  if legacy then return tonumber(legacy) end
  return tonumber(name:match("^(%d+)") or name:match("jdk%-?(%d+)") or name:match("java%-(%d+)") or name:match("temurin%-(%d+)"))
end

--- Mọi JDK tìm được, mỗi major một bản: { [21] = "/path/home", ... }
function M.jdks()
  if M._jdks then return M._jdks end
  local found = {}
  local function add(home, name)
    local major = major_from_name(name or vim.fs.basename(home))
    if major and not found[major] and vim.fn.executable(java_bin(home)) == 1 then
      found[major] = home
    end
  end
  local patterns = {
    vim.fs.normalize("~/.sdkman/candidates/java") .. "/*",
    "/Library/Java/JavaVirtualMachines/*/Contents/Home",
    "/usr/lib/jvm/*",
    "C:/Program Files/Java/*",
    "C:/Program Files/Eclipse Adoptium/*",
  }
  for _, pattern in ipairs(patterns) do
    for _, home in ipairs(vim.fn.glob(pattern, true, true)) do
      local name = home:match("Contents/Home$") and vim.fs.basename(vim.fs.dirname(vim.fs.dirname(home)))
        or vim.fs.basename(home)
      if name ~= "current" then add(home, name) end
    end
  end
  M._jdks = found
  return found
end

--- Java để CHẠY jdtls: bản mới nhất >= 25 (jdtls 1.63 không khởi động được trên Java 21).
--- Project vẫn biên dịch đúng version của nó qua M.runtimes().
function M.jdtls_java()
  local jdks = M.jdks()
  local newest = 0
  for major in pairs(jdks) do
    newest = math.max(newest, major)
  end
  return newest >= 25 and java_bin(jdks[newest]) or M.tool_java()
end

--- Java để CHẠY Spring LS: ưu tiên 21 (ổn định nhất), rồi bản >= 21 thấp nhất.
function M.tool_java()
  local jdks = M.jdks()
  if jdks[21] then return java_bin(jdks[21]) end
  local majors = vim.tbl_keys(jdks)
  table.sort(majors)
  for _, major in ipairs(majors) do
    if major > 21 then return java_bin(jdks[major]) end
  end
  return "java"
end

--- Version Java mà project yêu cầu (đọc pom.xml / build.gradle), không có thì nil.
function M.project_major(root)
  local function read(name)
    local path = vim.fs.joinpath(root, name)
    if vim.fn.filereadable(path) == 0 then return nil end
    return table.concat(vim.fn.readfile(path), "\n")
  end
  local pom = read("pom.xml")
  if pom then
    for _, tag in ipairs({ "java.version", "maven.compiler.release", "maven.compiler.source" }) do
      local value = pom:match("<" .. tag:gsub("%.", "%%.") .. ">%s*([%d%.]+)%s*</")
      if value then return major_from_name(value) end
    end
  end
  local gradle = read("build.gradle") or read("build.gradle.kts")
  if gradle then
    local value = gradle:match("JavaLanguageVersion%.of%((%d+)%)")
      or gradle:match("sourceCompatibility%s*=%s*['\"]?([%d%.]+)")
      or gradle:match("VERSION_(%d+)")
    if value then return major_from_name(value) end
  end
end

--- JAVA_HOME phù hợp với project (nil nếu không xác định hoặc máy chưa có bản đó).
function M.project_home(root)
  local major = M.project_major(root)
  return major and M.jdks()[major] or nil
end

--- Danh sách runtime cho jdtls; đánh dấu default theo version project.
function M.runtimes(root)
  local project = M.project_major(root)
  local runtimes = {}
  for major, home in pairs(M.jdks()) do
    table.insert(runtimes, {
      name = major <= 8 and ("JavaSE-1." .. major) or ("JavaSE-" .. major),
      path = home,
      default = major == project or nil,
    })
  end
  table.sort(runtimes, function(a, b) return a.name < b.name end)
  return runtimes
end

--- Thư mục config của jdtls theo OS + kiến trúc CPU.
function M.jdtls_config_dir(mason_jdtls)
  local uname = vim.uv.os_uname()
  local os_name = vim.fn.has("win32") == 1 and "win" or (uname.sysname == "Darwin" and "mac" or "linux")
  local arm = uname.machine == "arm64" or uname.machine == "aarch64"
  return vim.fs.joinpath(mason_jdtls, "config_" .. os_name .. ((arm and os_name ~= "win") and "_arm" or ""))
end

--- Cài các package Mason còn thiếu (chạy nền, xong thì báo).
function M.ensure_mason(names, on_done)
  local ok, registry = pcall(require, "mason-registry")
  if not ok then return end
  registry.refresh(function()
    local missing = vim.tbl_filter(function(name)
      return registry.has_package(name) and not registry.get_package(name):is_installed()
    end, names)
    if #missing == 0 then return end
    vim.schedule(function()
      vim.notify("Mason đang cài: " .. table.concat(missing, ", "), vim.log.levels.INFO, { title = "Java" })
    end)
    local pending = #missing
    for _, name in ipairs(missing) do
      registry.get_package(name):install({}, function()
        pending = pending - 1
        if pending == 0 and on_done then vim.schedule(on_done) end
      end)
    end
  end)
end

return M
