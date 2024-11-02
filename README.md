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
- **New Session**:
  - Insert Mode: `<C-n>`
  - Normal Mode: `<C-n>`
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

To list and manage chat sessions, use the following command in Neovim:

```vim
:Telescope ollama list
```

It can be invoked directly:

```lua
require('telescope').extensions.ollama.list()
```

##### Available Actions

- **Open Session**: Press `<CR>` to open the selected session.
- **Delete Session**: Press `<C-x>` in normal or insert mode to delete the selected session.



#### List Models

To list available models and set a default model:

```vim
:Telescope ollama models
```

It can be invoked directly:

```lua
require('telescope').extensions.ollama.models()
```

##### Available Actions

- **Set Default Model**: Press `<CR>` to set the selected model as the default for new sessions.


## License

This extension is released under the MIT License.
