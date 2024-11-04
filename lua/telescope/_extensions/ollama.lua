local ok, _ = pcall(require, 'telescope')
if not ok then
  return
end

local telescope = require('telescope')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local conf = require('telescope.config').values
local transform_mod = require('telescope.actions.mt').transform_mod
local ollama = require('ollama')

local function list_sessions_finder()
  return finders.new_table({
    results = (function()
      local chat = ollama.chat
      if chat ~= nil then
        return chat:list_sessions()
      else
        return {}
      end
    end)(),
    entry_maker = function(entry)
      return {
        value = entry,
        display = entry.id .. ' ' .. vim.split((entry.messages[1] or { content = '' }).content, '\n')[1],
        ordinal = entry.id,
      }
    end,
  })
end

local function delete_session(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  ollama.chat:remove_session(entry.value.id)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:refresh(list_sessions_finder())
end

local ollama_actions = transform_mod({
  delete_selected = delete_session,
})

local function list_sessions(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = 'session',
      finder = list_sessions_finder(),
      previewer = previewers.new_buffer_previewer({
        define_preview = function(self, entry)
          local session = entry.value
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, { 'model: ' .. session.config.model, '' })

          for _, msg in ipairs(session.messages) do
            if msg.role == 'user' then
              vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, true, { '# User' })
            else
              vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, true, { '# LLM (' .. session.config.model .. ')' })
            end
            vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, true, vim.split(msg.content or '', '\n'))
            vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, true, { '' })
          end
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          ollama.chat:open_session(selection.value.id)
        end)

        map('n', '<c-x>', ollama_actions.delete_selected)
        map('i', '<c-x>', ollama_actions.delete_selected)

        return true
      end,
    })
    :find()
end

local function list_models(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = 'model',
      finder = finders.new_table({
        results = ollama._list_models(),
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.model,
            ordinal = entry.model,
          }
        end,
      }),
      previewer = previewers.new_buffer_previewer({
        define_preview = function(self, entry)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, vim.split(vim.inspect(entry.value), '\n'))
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          ollama.change_default_chat_model(selection.value.model)
        end)

        return true
      end,
    })
    :find()
end

return telescope.register_extension({
  exports = {
    list = list_sessions,
    models = list_models,
    actions = ollama_actions,
  },
})
