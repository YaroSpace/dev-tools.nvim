return {
  "yarospace/dev-tools.nvim",
  lazy = true,
  event = "BufEnter",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  specs = {
    {
      "folke/snacks.nvim",
      opts = {
        picker = { enabled = true },
        terminal = { enabled = true },
      },
    },
    {
      "ThePrimeagen/refactoring.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
  },
  opts = {},
}
