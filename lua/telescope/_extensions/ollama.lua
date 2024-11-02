local ok, _ = pcall(require, 'ollama')
if not ok then
  return
end

local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local conf = require('telescope.config').values
local transform_mod = require('telescope.actions.mt').transform_mod

local function make_finder()
  return finders.new_table({
    results = (function()
      local chat = require('ollama').chat
      if chat ~= nil then
        return chat:list_sessions()
      else
        return {}
      end
    end)(),
    entry_maker = function(entry)
      return {
        value = entry,
        display = entry.id .. ' ' .. (entry.messages[1] or { content = '' }).content,
        ordinal = entry.id,
      }
    end,
  })
end

local function delete_session(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  require('ollama').chat:remove_session(entry.value.id)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:refresh(make_finder())
end

local ollama_actions = transform_mod({
  delete_selected = delete_session,
})

local function list_sessions(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      -- prompt_title = 'session',
      finder = make_finder(),
      previewer = previewers.new_buffer_previewer({
        define_preview = function(self, entry)
          local session = entry.value
          for _, msg in ipairs(session.messages) do
            if msg.role == 'user' then
              vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, true, { '# User' })
            else
              vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, true, { '# LLM' })
            end
            vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, true, vim.split(msg.content or '', '\n'))
            vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, true, { '' })
          end
          vim.api.nvim_set_option_value('filetype', 'markdown', { buf = self.state.bufnr })
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          require('ollama').chat:open_session(selection.value.id)
        end)

        map('n', '<c-x>', ollama_actions.delete_selected)
        map('i', '<c-x>', ollama_actions.delete_selected)

        return true
      end,
    })
    :find()
end

return require('telescope').register_extension({
  exports = {
    list = list_sessions,
    actions = ollama_actions,
  },
})
