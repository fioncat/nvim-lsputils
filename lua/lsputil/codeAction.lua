local popfix = require'popfix'
local util = require'lsputil.util'
local actionModule = require'lsputil.actions'

-- default keymaps provided by nvim-lsputils
local function createKeymaps()
    return {
	i = {
	    ['<C-n>'] = actionModule.codeaction_next,
	    ['<C-p>'] = actionModule.codeaction_prev,
	    ['<CR>'] = actionModule.codeaction_fix,
	    ['<Down>'] = actionModule.select_next,
	    ['<Up>'] = actionModule.select_prev,
	},
	n = {
	    ['<CR>'] = actionModule.codeaction_fix,
	    ['<Esc>'] = actionModule.codeaction_cancel,
	    ['q'] = actionModule.codeaction_cancel,
	    ['j'] = actionModule.codeaction_next,
	    ['k'] = actionModule.codeaction_prev,
	    ['<Down>'] = actionModule.select_next,
	    ['<Up>'] = actionModule.select_prev,
	}
    }
end

-- opts required for popfix
local opts = {
    mode = 'cursor',
    close_on_bufleave = true,
    list = {
	numbering = true,
	border = true,
    },
    callbacks = {
	close = actionModule.codeaction_cancel_handler
    },
}
util.handleGlobalVariable(vim.g.lsp_utils_codeaction_opts, opts)

-- codeAction event callback handler
local code_action_handler = function(_,_,actions, _, _, _, customSelectionHandler)
    if actions == nil or vim.tbl_isempty(actions) then
	print("No code actions available")
	return
    end
    if actionModule.popup then
	print 'Busy in other LSP popup'
	return
    end
    actionModule.actionBuffer = actions
    local data = {}
    for i, action in ipairs (actions) do
	local title = action.title:gsub('\r\n', '\\r\\n')
	title = title:gsub('\n','\\n')
	data[i] = title
    end
    local width = 0
    for _, str in ipairs(data) do
	if #str > width then
	    width = #str
	end
    end
    local keymaps = createKeymaps()
    if not opts.prompt then
	for k,_ in ipairs(data) do
	    keymaps.n[tostring(k)] = k..'G<CR>'
	end
    end
    util.setCustomActionMappings(keymaps, customSelectionHandler)
    opts.keymaps = keymaps
    opts.width = width + 5
    opts.height = opts.height or #data
    opts.data = data
    actionModule.popup = popfix:new(opts)
    if not actionModule.popup then
	actionModule.actionBuffer = nil
    end
    util.setFiletype(actionModule.popup.list.buffer, 'lsputil_codeaction_list')
    if actionModule.popup.prompt then
	util.setFiletype(actionModule.popup.prompt.buffer, 'lsputil_codeaction_prompt')
    end
    opts.data = nil
end

return{
    code_action_handler = code_action_handler,
}
