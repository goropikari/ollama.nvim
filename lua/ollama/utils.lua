local M = {}

function M.create_buffer()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('filetype', 'ollama-chat', { buf = bufnr })
  vim.api.nvim_set_option_value('syntax', 'markdown', { buf = bufnr })

  return bufnr
end

function M.make_id()
  return tostring(os.date('%Y%m%d-%H%M%S'))
end

---@param bufnr number
---@param winid number
function M.move_bottom(winid, bufnr)
  if vim.api.nvim_win_is_valid(winid) then
    local last_num = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_win_set_cursor(winid, { last_num, 0 })
  end
end

function M.write_buffer(bufnr, messages)
  for i, msg in ipairs(messages) do
    if msg.role == 'user' then
      vim.api.nvim_buf_set_lines(bufnr, i == 1 and 0 or -1, -1, true, { '# User' })
    else
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { '# LLM' })
    end
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, vim.split(msg.content or '', '\n'))
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { '' })
  end
  vim.api.nvim_buf_set_lines(bufnr, #messages == 0 and 0 or -1, -1, true, { '# User', '' })
end

return M
