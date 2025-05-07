local asserts = require("test_helper.asserts")
local ui = require("test_helper.ui")

return vim.tbl_extend("error", ui, asserts)
