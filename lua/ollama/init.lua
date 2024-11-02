local utils = require('ollama.utils')
local spinner = require('ollama.spinner').spinner
local converter = require('ollama.converter')

local M = {}

---@class Config
---@field chat {model:string, url:string}
---@field save_path string
local default_config = {
  chat = {
    model = 'codegemma',
    url = 'http://localhost:11434/api/chat',
  },
  save_path = vim.fn.stdpath('state') .. '/ollama.nvim/state.json',
}

---@type Config
---@diagnostic disable-next-line
local global_internal_config = {}

---@class State
---@field winid number
local global_state = {
  winid = -1,
  help = {
    init = false,
    bufnr = -1,
    winid = -1,
  },
}

local help = {
  init = false,
  bufnr = -1,
  winid = -1,
  helps = {
    'mode -> key binding -> action',
    'i -> <c-s> -> submit',
    'n -> <c-s> -> submit',
    'i -> <c-l> -> clear session',
    'n -> <c-l> -> clear session',
    'i -> <c-n> -> new session',
    'n -> <c-n> -> new session',
    'n -> ? -> toggle help',
  },
}
function help.toggle(self)
  if not self.init then
    self.bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('filetype', 'markdown', { buf = self.bufnr })
    vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, self.helps)
    self.init = true
  end
  if vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_win_hide(self.winid)
  else
    self.winid = vim.api.nvim_open_win(self.bufnr, false, {
      style = 'minimal',
      relative = 'cursor',
      row = 1,
      col = 1,
      width = 30,
      height = #self.helps,
      border = 'single',
    })
  end
end

local function write_buffer(bufnr, user_header, llm_header, messages)
  for i, msg in ipairs(messages) do
    if msg.role == 'user' then
      vim.api.nvim_buf_set_lines(bufnr, i == 1 and 0 or -1, -1, true, { user_header })
    else
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { llm_header })
    end
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, vim.split(msg.content or '', '\n'))
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, true, { '' })
  end
  vim.api.nvim_buf_set_lines(bufnr, #messages == 0 and 0 or -1, -1, true, { user_header, '' })
end

---@class Message
---@field role 'user'|'assistant'|'system'
---@field content string

---@class Session
---@field id string
---@field is_empty boolean
---@field bufnr number
---@field last_line_num number
---@field messages table<Message>

local session = {}
---@params opts {id:string, messages:table<Message>}
function session.new(opts)
  opts = opts or {}
  ---@class Session
  local obj = {
    id = opts.id or utils.make_id(),
    is_empty = true,
    bufnr = utils.create_buffer(),
    last_line_num = -1, -- 1-index
    messages = opts.messages or {},
    tmp_assistant_message = {},
    config = opts.config or {
      model = global_internal_config.chat.model,
    },
    win_opts = {
      split = 'left',
      width = math.floor(vim.o.columns * 0.3),
    },
  }

  obj._user_header = function(self)
    return '# User'
  end

  obj._llm_header = function(self)
    return '# LLM (' .. self.config.model .. ')'
  end

  obj._write_buffer = function(self)
    write_buffer(self.bufnr, self:_user_header(), self:_llm_header(), self.messages)
    self:_update_last_line_num()
    self.is_empty = false
  end

  obj._update_last_line_num = function(self)
    self.last_line_num = vim.api.nvim_buf_line_count(self.bufnr)
  end

  obj.clear = function(self)
    if vim.api.nvim_win_is_valid(global_state.winid) then
      vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { '' })
      self.is_empty = true
      self.messages = {}
      self.tmp_assistant_message = {}
      self:_update_last_line_num()
      self:open_window()
    end
  end

  obj.remove = function(self)
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end

  obj.toggle_window = function(self)
    if vim.api.nvim_win_is_valid(global_state.winid) then
      vim.api.nvim_win_close(global_state.winid, false)
      global_state.winid = -1
    else
      self:open_window()
    end
  end

  obj.open_window = function(self)
    if obj.is_empty then
      vim.api.nvim_buf_set_lines(obj.bufnr, 0, -1, false, { self:_user_header(), '' })
      self:_update_last_line_num()
      obj.is_empty = false
    end
    if vim.api.nvim_win_is_valid(global_state.winid) then
      vim.api.nvim_win_set_buf(global_state.winid, self.bufnr)
    else
      global_state.winid = vim.api.nvim_open_win(self.bufnr, true, self.win_opts)
    end
  end

  obj.print = function(self)
    vim.print(self)
  end

  local send_to_buffer = function(chunk)
    if chunk then
      local res = converter.to_response(chunk)
      vim.schedule(function()
        local content = res.message.content
        table.insert(obj.tmp_assistant_message, content)
        vim.api.nvim_buf_set_text(obj.bufnr, -1, -1, -1, -1, vim.split(content, '\n'))
        if res.done then
          vim.api.nvim_buf_set_lines(obj.bufnr, -1, -1, false, { '', obj:_user_header(), '' })
          obj:_update_last_line_num()
          table.insert(obj.messages, {
            role = 'assistant',
            content = vim.fn.join(obj.tmp_assistant_message, ''),
          })
          obj.tmp_assistant_message = {}
        end
        utils.move_bottom(global_state.winid, obj.bufnr)
      end)
    end
  end

  vim.keymap.set({ 'i', 'n' }, '<c-s>', '', {
    silent = true,
    buffer = obj.bufnr,
    callback = function()
      local user_input = vim.api.nvim_buf_get_lines(obj.bufnr, obj.last_line_num - 1, -1, false)
      local user_text = vim.fn.join(user_input, '\n')
      vim.api.nvim_buf_set_lines(obj.bufnr, -1, -1, false, { '', obj:_llm_header(), '' })

      local timer = spinner.new():start(obj.bufnr)
      local timer_processing = true
      utils.move_bottom(global_state.winid, obj.bufnr)

      table.insert(obj.messages, { role = 'user', content = user_text })
      vim.fn.jobstart(
        vim.fn.flatten({
          'curl',
          '--no-buffer',
          global_internal_config.chat.url,
          '-d',
          converter.to_chat_request(obj.config, obj.messages),
        }),
        {
          on_stdout = function(_, chunk, _)
            if timer_processing then
              vim.uv.timer_stop(timer)
              vim.api.nvim_buf_set_lines(obj.bufnr, -2, -1, false, { '' })
              timer_processing = false
            end
            for _, v in ipairs(chunk) do
              if v ~= '' then
                send_to_buffer(v)
              end
            end
          end,
          stdout_buffered = false,
        }
      )
    end,
  })

  vim.keymap.set({ 'n', 'i' }, '<c-l>', '', {
    buffer = obj.bufnr,
    silent = true,
    callback = function()
      obj:clear()
    end,
  })

  vim.keymap.set({ 'n' }, '?', '', {
    buffer = obj.bufnr,
    silent = true,
    callback = function()
      help:toggle()
    end,
  })

  vim.keymap.set({ 'n', 'i' }, '<c-n>', '', {
    buffer = obj.bufnr,
    silent = true,
    callback = function()
      M.new_session()
    end,
  })

  return obj
end

local Chat = {}
function Chat.new()
  local obj = {
    current_session_key = '',
    sessions = {},
    config = global_internal_config,
  }

  obj.get_current_session = function(self)
    return self.sessions[self.current_session_key]
  end

  obj.new_session = function(self, opts)
    local sess = session.new(opts)
    self.sessions[sess.id] = sess

    return sess.id
  end

  obj.open_session = function(self, session_key)
    self.current_session_key = session_key
    self.sessions[session_key]:open_window()
  end

  obj.open = function(self)
    if next(self.sessions) == nil then
      self.current_session_key = self:new_session()
    end
    self:open_session(self.current_session_key)
  end

  obj.toggle = function(self)
    local sess = self:get_current_session()
    if sess ~= nil then
      sess:toggle_window()
    end
  end

  obj.list_sessions = function(self)
    local ls = {}
    for _, sess in pairs(self.sessions) do
      table.insert(ls, sess)
    end
    return ls
  end

  obj.remove_session = function(self, key)
    local sess = self.sessions[key]
    sess:remove()
    if self.current_session_key == key then
      self.current_session_key = ''
    end
    self.sessions[key] = nil
  end

  obj.print = function(self)
    vim.print(self)
  end

  obj.restore = function(self)
    local file = io.open(self.config.save_path, 'r')
    if file then
      local raw = file:read('*a')
      file:close()

      local contents = vim.json.decode(raw)
      for _, content in ipairs(contents) do
        self:new_session({
          id = content.key,
          messages = content.messages,
          config = content.config,
        })
        self.current_session_key = content.key
      end

      for _, sess in pairs(self.sessions) do
        sess:_write_buffer()
      end
    end
  end

  obj.save = function(self)
    local file_path = self.config.save_path
    local dir_path = vim.fn.fnamemodify(file_path, ':h') -- get directory name
    vim.fn.mkdir(dir_path, 'p')
    local file = io.open(file_path, 'w')
    if file then
      local data = {}
      for key, sess in pairs(self.sessions) do
        table.insert(data, { key = key, config = sess.config, messages = sess.messages })
      end
      file:write(vim.json.encode(data))
      file:close()
    end
  end

  return obj
end

M.chat = nil
function M.open_chat()
  M.chat:open()
end

function M.new_session()
  local key = M.chat:new_session()
  M.chat:open_session(key)
end

function M.clear_session()
  M.chat:clear_session()
end

function M.change_default_chat_model(model)
  global_internal_config.chat.model = model
end

function M.show_config()
  vim.print(global_internal_config)
end

function M.setup(opts)
  global_internal_config = vim.tbl_extend('force', default_config, opts or {})
  M.chat = Chat.new()

  M.chat:restore()

  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      M.chat:save()
    end,
  })
end

vim.api.nvim_create_user_command('OllamaChat', function()
  M.open_chat()
end, {})

return M
