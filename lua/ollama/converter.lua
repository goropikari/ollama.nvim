local M = {}

function M.to_chat_request(config, messages)
  return vim.json.encode({
    model = config.chat.model,
    messages = messages,
  })
end

function M.to_response(chunk)
  local res = vim.json.decode(chunk)
  return res
end

return M
