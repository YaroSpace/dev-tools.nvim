return {
  "yarospace/dev-tools.nvim",
  lazy = true,
  event = "BufEnter",
  dependencies = {
    "folke/snacks.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  specs = {
    {
      "folke/snacks.nvim",
      opts = { picker = { enabled = true } },
    },
  },
  opts = {},
}
