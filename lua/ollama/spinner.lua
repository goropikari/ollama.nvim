local M = {}

local spinner_symbols = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

local spinner = {}
function spinner.new()
  local obj = {
    idx = 1,
    timer = nil,
  }

  obj.start = function(self, bufnr)
    local timer = vim.uv.new_timer()
    vim.uv.timer_start(timer, 0, 100, function()
      vim.schedule(function()
        vim.api.nvim_buf_set_lines(bufnr, -2, -1, false, { spinner_symbols[self.idx] })
        self.idx = (self.idx % #spinner_symbols) + 1
      end)
    end)
    return timer
  end

  return obj
end

M.spinner = spinner

return M
