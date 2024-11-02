# ollama.nvim

`ollama.nvim` is a Neovim plugin that provides a chat-based interface within Neovim, allowing users to communicate with an AI model running on a local or remote server.

## Features

- **Multiple Sessions**: Create and manage multiple chat sessions.
- **Save/Restore State**: Automatically saves session state, including message history, to a JSON file on exit and restores it on startup.

## Installation

Install with your preferred plugin manager, for example, using `lazy.nvim`:

```lua
{
  'goropikari/ollama.nvim',
  dependencies = {
    -- 'nvim-telescope/telescope.nvim' -- for telescope integration
  },
  opts = {
    -- default config
    chat = {
      model = 'codegemma',
      url = 'http://localhost:11434/api/chat',
    },
    save_path = vim.fn.stdpath('state') .. '/ollama.nvim/state.json',
  },
}
```

The `chat` configuration specifies the model and API URL of your backend service.

## Usage

### Key Bindings

In `ollama.nvim`, you can interact with the chat interface using the following key mappings:

- **Submit Message**:
  - Insert Mode: `<C-s>`
  - Normal Mode: `<C-s>`
- **Clear Session**:
  - Insert Mode: `<C-l>`
  - Normal Mode: `<C-l>`
- **Toggle Help**:
  - Normal Mode: `?`

### API

The main API functions in `ollama.nvim` are:

- `require('ollama').open_chat()`: Opens the chat window for the current session.
- `require('ollama').new_session()`: Starts a new session and opens the chat window.
- `require('ollama').clear_session()`: Clears the current chat session.

### Saving and Restoring Sessions

Sessions are automatically saved upon Neovim exit and restored on startup. The `save_path` option specifies the path where session data is stored.


## Telescope integration

### Commands

#### List Sessions

```vim
:Telescope ollama list
```

This command opens a Telescope picker with a list of all active sessions. Each entry shows the session ID and the first message content.

#### Session Actions

- **Open a Session**: Select a session to open it in the Ollama chat window.
- **Delete a Session**: Press `<C-x>` in Normal or Insert mode to delete the selected session.

### Key Mappings

Inside the session picker:

- **`<Enter>`**: Opens the selected session.
- **`<C-x>`**: Deletes the selected session.

## API

### `list_sessions`

`list_sessions` is the main function used to list chat sessions. It can be invoked directly:

```lua
require('telescope').extensions.ollama.list()
```

## License

This extension is released under the MIT License.
