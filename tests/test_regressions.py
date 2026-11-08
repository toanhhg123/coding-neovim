"""Offline regression suite: python3 -m unittest discover -s tests -v."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import uuid

REPO = Path(__file__).resolve().parents[1]
NVIM = shutil.which("nvim")


class NeovimTests(unittest.TestCase):
    def run_case(self, script, case):
        self.assertIsNotNone(NVIM, "Neovim >= 0.12 is required")
        return subprocess.run(
            [NVIM, "--headless", "-u", "NONE", "-i", "NONE", "-n", "-l", str(REPO / "tests" / script), case],
            cwd=REPO, capture_output=True, text=True, timeout=15,
        )

    def test_syntax(self):
        result = self.run_case("lua_cases.lua", "syntax")
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        for script in ("install.sh", "tmux/scripts/tmux-sessionizer"):
            subprocess.run(["bash", "-n", script], cwd=REPO, check=True)

    def test_java_and_spring(self):
        for case in ("java_home", "java_special_files", "java_autocmd", "spring_tmux", "spring_terminal", "spring_debug_runner"):
            with self.subTest(case=case):
                result = self.run_case("lua_cases.lua", case)
                self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_intellij_shortcuts(self):
        for case in ("modes", "duplicate", "recent", "search_and_line", "lsp_and_actions", "workflow_shortcuts", "profile"):
            with self.subTest(case=case):
                result = self.run_case("intellij_cases.lua", case)
                self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_vim_defaults(self):
        for case in ("startup", "editing", "navigation", "recent", "lsp", "workflow", "optional_cmd", "conflicts"):
            with self.subTest(case=case):
                result = self.run_case("vim_cases.lua", case)
                self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_keymap_help(self):
        for case in ("entries", "reference", "buffer_override", "modes", "windows", "stale_origin", "entry_points"):
            with self.subTest(case=case):
                result = self.run_case("keymaps_cases.lua", case)
                self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_keymap_picker_integration(self):
        data = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
        plugin_dir = data / os.environ.get("NVIM_APPNAME", "nvim") / "lazy"
        if not all((plugin_dir / name).is_dir() for name in ("telescope.nvim", "plenary.nvim")):
            self.skipTest("Telescope/plenary are not installed; unit cases still run offline")
        for case in ("picker", "picker_split", "picker_guide"):
            with self.subTest(case=case):
                result = self.run_case("keymaps_cases.lua", case)
                self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_debug_workflow(self):
        for case in ("ready_tmux", "ready_term", "timeout", "cancel_wait", "cancel_profile", "stop_dap", "guards", "narrow_terminal"):
            with self.subTest(case=case):
                result = self.run_case("debug_cases.lua", case)
                self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_setup_success(self):
        result = self.run_case("setup_case.lua", "success")
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertIn("INSTALL: jdtls", result.stderr)
        self.assertIn("INSTALL: lua-language-server", result.stderr)

    def test_setup_already_installed(self):
        result = self.run_case("setup_case.lua", "already-installed")
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertNotIn("INSTALL:", result.stderr)

    def test_setup_failures(self):
        for case in ("parser-failure", "parser-exception", "registry-failure", "registry-timeout", "mason-failure", "mason-timeout"):
            with self.subTest(case=case):
                result = self.run_case("setup_case.lua", case)
                self.assertEqual(1, result.returncode, result.stdout + result.stderr)
                self.assertIn("Lỗi:", result.stdout)
                if case.startswith("registry-"):
                    self.assertNotIn("INSTALL:", result.stderr)


# Mỗi tool nguy hiểm là một executable giả. Chỉ mkdir/ln/cp/... thật chạy trong HOME tạm.
TOOL_STUB = r'''
import json, os, pathlib, sys
tool = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["TEST_LOG"], "a") as log:
    log.write(json.dumps([tool] + args) + "\n")
version_file = pathlib.Path(os.environ["TEST_VERSION_FILE"])
if tool == "uname":
    print(os.environ["TEST_PLATFORM"] if args == ["-s"] else "x86_64")
elif tool == "id":
    print("0")
elif tool == "nvim" and args == ["--version"]:
    print("NVIM v0.12.4")
elif tool == "node":
    print("24")
elif tool == "tree-sitter":
    local_bin = pathlib.Path(os.environ["HOME"]) / ".local" / "bin"
    version = "0.26.1" if pathlib.Path(sys.argv[0]).parent == local_bin else version_file.read_text().strip()
    if version == "broken": sys.exit(1)
    print("tree-sitter " + version)
elif tool == "brew" and args[:2] == ["upgrade", "tree-sitter-cli"]:
    version_file.write_text("0.26.1")
elif tool == "unzip":
    dest = pathlib.Path(args[args.index("-d") + 1])
    dest.mkdir(parents=True, exist_ok=True)
    (dest / "tree-sitter").write_text(pathlib.Path(sys.argv[0]).read_text())
elif tool == "curl":
    print("mock archive")
'''


class InstallerTests(unittest.TestCase):
    def run_installer(self, platform, version, skip_deps=False, install_profile=False):
        with tempfile.TemporaryDirectory(prefix="coding-neovim-test-") as temp:
            temp = Path(temp)
            bin_dir, home, repo = temp / "bin", temp / "home", temp / "repo"
            for path in (bin_dir, home, repo / ".git", repo / "tmux"):
                path.mkdir(parents=True, exist_ok=True)
            (repo / "tmux" / "tmux.conf").write_text("")
            (repo / "iterm").mkdir()
            shutil.copy(REPO / "iterm" / "coding-neovim.json", repo / "iterm")
            log, version_file = temp / "commands.jsonl", temp / "version"
            version_file.write_text(version)
            for tool in ("uname", "id", "nvim", "node", "tree-sitter", "brew", "apt-get", "curl", "unzip", "git", "xcode-select"):
                path = bin_dir / tool
                path.write_text("#!" + sys.executable + "\n" + TOOL_STUB)
                path.chmod(0o755)
            for tool in ("bash", "date", "head", "sed", "dirname", "mktemp", "mkdir", "chmod", "rm", "ln", "readlink", "mv", "cp", "grep"):
                executable = shutil.which(tool)
                self.assertIsNotNone(executable, "missing test dependency: " + tool)
                (bin_dir / tool).symlink_to(executable)
            env = dict(os.environ, HOME=str(home), TMPDIR=str(temp), PATH=str(bin_dir), CODING_NVIM_DIR=str(repo),
                       TEST_PLATFORM=platform, TEST_VERSION_FILE=str(version_file), TEST_LOG=str(log),
                       SKIP_JAVA="1", SKIP_DEPS="1" if skip_deps else "0",
                       INSTALL_ITERM_PROFILE="1" if install_profile else "0")
            result = subprocess.run([str(bin_dir / "bash"), str(REPO / "install.sh")],
                                    env=env, capture_output=True, text=True, timeout=20)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            profile = home / "Library/Application Support/iTerm2/DynamicProfiles/coding-neovim.json"
            if not install_profile:
                self.assertFalse(profile.exists(), "default install must not install a Cmd keyboard profile")
            elif platform == "Darwin" and Path("/Applications/iTerm.app").is_dir():
                self.assertEqual((REPO / "iterm/coding-neovim.json").read_bytes(), profile.read_bytes())
            return result, calls

    def test_iterm_profile_is_opt_in(self):
        result, _ = self.run_installer("Darwin", "0.26.1", install_profile=True)
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)

    def test_old_tree_sitter_is_upgraded(self):
        for platform in ("Darwin", "Linux"):
            with self.subTest(platform=platform):
                result, calls = self.run_installer(platform, "0.25.10")
                self.assertEqual(0, result.returncode, result.stdout + result.stderr)
                if platform == "Darwin":
                    self.assertIn(["brew", "upgrade", "tree-sitter-cli"], calls)
                else:
                    self.assertTrue(any(call[0] == "curl" and "tree-sitter-cli-linux-x64.zip" in call[-1] for call in calls))

    def test_supported_tree_sitter_is_kept(self):
        for platform, version in (("Darwin", "0.26.1"), ("Linux", "0.27.2")):
            with self.subTest(platform=platform):
                result, calls = self.run_installer(platform, version)
                self.assertEqual(0, result.returncode, result.stdout + result.stderr)
                self.assertNotIn(["brew", "upgrade", "tree-sitter-cli"], calls)
                self.assertFalse(any(call[0] == "curl" for call in calls))

    def test_skip_deps_rejects_old_or_broken_tree_sitter(self):
        for version in ("0.25.10", "broken", "unparseable"):
            with self.subTest(version=version):
                result, calls = self.run_installer("Linux", version, skip_deps=True)
                self.assertNotEqual(0, result.returncode, result.stdout + result.stderr)
                self.assertIn("tree-sitter-cli >= 0.26.1", result.stderr)
                self.assertFalse(any(call[0] == "git" for call in calls))


class TmuxTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which("tmux"), "tmux is not installed")
    def test_ctrl_f_returns_to_vim(self):
        with tempfile.TemporaryDirectory(prefix="coding-neovim-tmux-") as temp:
            temp = Path(temp)
            tpm = temp / ".config/tmux/plugins/tpm/tpm"
            tpm.parent.mkdir(parents=True)
            tpm.write_text("#!/bin/sh\nexit 0\n")
            tpm.chmod(0o755)
            env = dict(os.environ, HOME=str(temp), TMUX="")
            command = [shutil.which("tmux"), "-L", "cnv-test-" + uuid.uuid4().hex[:12]]
            def run(*args, check=True):
                return subprocess.run(command + list(args), env=env, capture_output=True, text=True, timeout=10, check=check)
            try:
                run("-f", "/dev/null", "new-session", "-d", "-s", "test", "sleep 30")
                run("bind-key", "-n", "C-f", "display-message", "old sessionizer shortcut")
                run("source-file", str(REPO / "tmux/tmux.conf"))
                self.assertNotEqual(0, run("list-keys", "-T", "root", "C-f", check=False).returncode)
                self.assertIn("tmux-sessionizer", run("list-keys", "-T", "prefix", "f").stdout)
            finally:
                run("kill-server", check=False)


if __name__ == "__main__":
    unittest.main()
