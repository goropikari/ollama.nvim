local M = {}

function M.create_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('filetype', 'markdown', { buf = bufnr })

  return bufnr
end

function M.make_id()
  return tostring(os.date('%Y%m%d-%H%M%S'))
end

---@param bufnr number
---@param winid number
function M.move_bottom(winid, bufnr)
  if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
    local last_num = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_win_set_cursor(winid, { last_num, 0 })
  end
end

function M.build_window_opts(win_opts)
  local layout = win_opts.layout
  local width = math.floor(vim.o.columns * win_opts.width)
  local height = math.floor(vim.o.lines * win_opts.height)
  if layout == 'float' then
    return {
      relative = 'editor',
      width = width,
      height = height,
      col = math.floor((vim.o.columns - width) / 2),
      row = math.floor(vim.o.lines * 0.1),
      border = win_opts.border,
      style = 'minimal',
      title = win_opts.title,
      title_pos = 'center',
    }
  end

  return {
    split = layout,
    width = math.floor(vim.o.columns * win_opts.width),
    height = math.floor(vim.o.lines * win_opts.height),
  }
end

return M
