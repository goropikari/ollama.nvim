local M = {}

---@class OllamaChatRequest
---@field model string
---@field messages table<Message>
---@field stream boolean

---@class OllamaChatResponse
---@field model string
---@field messages table<Message>
---@field done boolean
---@field done_reason string

---@param messages table<Message>
---@return string
function M.to_chat_request(config, messages)
  ---@type OllamaChatRequest
  local req = {
    model = config.model,
    messages = messages,
    stream = true,
  }
  return vim.json.encode(req)
end

---@params chunk string
---@return OllamaChatResponse
function M.to_response(chunk)
  local res = vim.json.decode(chunk)
  return res
end

return M
