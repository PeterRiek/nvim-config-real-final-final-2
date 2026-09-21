local M = {}

M.spec = {
  "lewis6991/gitsigns.nvim"
}

-- Gitsigns diffthis only opens a diff split; it won't close one, so close the
-- throwaway base window ourselves. Two hazards to avoid: closing the real file
-- window strands you in the base buffer, and closing the base window while a
-- float (stale LSP hover, etc.) lingers makes neo-tree's close_if_last_window
-- miscount and quit nvim -- so drop floats first, keep the real file window.
function M.toggle_diffthis()
  if not vim.wo.diff then
    vim.cmd("Gitsigns diffthis")
    return
  end
  local file_win, scratch = nil, {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      pcall(vim.api.nvim_win_close, win, false) -- stray float (hover/signature)
    elseif vim.wo[win].diff then
      if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "" then
        file_win = win
      else
        scratch[#scratch + 1] = win
      end
    end
  end
  if file_win then vim.api.nvim_set_current_win(file_win) end
  -- Leave diff mode first: closing a window while it is still in diff mode
  -- segfaults Neovim 0.12.x. Defer the actual close to a safe event-loop tick
  -- (closing synchronously inside this keymap callback is what triggers it).
  vim.cmd("diffoff!")
  vim.schedule(function()
    for _, win in ipairs(scratch) do
      if vim.api.nvim_win_is_valid(win) and #vim.api.nvim_tabpage_list_wins(0) > 1 then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end)
end

return M
