-- lua/plugins/search-replace.lua — Tìm & Thay thế toàn project (grug-far)
-- Bù đúng khoảng trống: search từ khoá + sửa hàng loạt qua nhiều file (ripgrep).
-- Mở 1 buffer chuyên dụng: gõ Search/Replace/Files-filter -> preview -> apply.

return {
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        desc = "Search & Replace toàn project",
      },
      {
        "<leader>sw",
        function()
          require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "Search & Replace: từ dưới con trỏ",
      },
      {
        "<leader>sf",
        function()
          -- Giới hạn phạm vi trong đúng file hiện tại
          require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
        end,
        desc = "Search & Replace: chỉ file này",
      },
      {
        "<leader>s",
        mode = "v",
        function()
          require("grug-far").with_visual_selection()
        end,
        desc = "Search & Replace: vùng chọn",
      },
    },
    opts = {
      -- Gọn, hợp workflow đọc code: mở dạng split, dùng ripgrep sẵn có
      headerMaxWidth = 80,
    },
  },
}
