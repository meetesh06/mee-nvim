-- deepblue: Neovim's classic `darkblue`, reworked for readability.
--
-- Single source of truth for the editor AND terminal colours. Edit this file,
-- then regenerate both outputs:
--
--   nvim -l scripts/gen-theme.lua            -> colors/deepblue.lua + extras/ghostty/deepblue
--   nvim -l scripts/gen-theme.lua --install  -> also copies the ghostty theme into
--                                               ~/.config/ghostty/themes/
--
-- What changed from darkblue: the syntax colours are the same, but the "chrome"
-- is toned down. Diffs use dark tinted backgrounds (instead of white text on
-- bright fills) so code stays syntax-highlighted and readable; the cursor line,
-- selection, popup menu and line numbers no longer shout.

local c = {
  -- base
  bg = "#000040", -- darkblue's navy
  bg_dark = "#00002a", -- floats, statusline, sidebars
  bg_hl = "#0a0a5c", -- cursor line
  bg_visual = "#233a8c",
  bg_popup = "#0b1660",
  bg_popup_sel = "#2848b0",
  border = "#3a4a8a",
  fg = "#c0c0c0",
  fg_bright = "#ffffff",
  fg_dim = "#8088b0",
  fg_gutter = "#4a5a8a",

  -- syntax (straight from darkblue)
  comment = "#80a0ff",
  constant = "#ffa0a0",
  identifier = "#90fff0",
  statement = "#ffff60",
  type = "#90f020",
  preproc = "#ff80ff",
  special = "#ffa500",
  directory = "#5fd7d7",

  -- signals
  red = "#ff6b6b",
  orange = "#ffa500",
  yellow = "#ffff60",
  green = "#90f020",
  cyan = "#5fd7d7",
  blue = "#80a0ff",
  magenta = "#ff80ff",

  -- diff backgrounds: as bright as they can go while every syntax colour
  -- (the light-blue comments are the limit) stays readable on them (>= 3.5:1).
  -- Changed lines use violet, not blue, so they don't blend into the navy.
  diff_add = "#0f5535",
  diff_change = "#46398c",
  diff_text = "#4b6af0", -- the exact changed characters; white bold text on it
  diff_delete = "#8a1840",
}

-- Terminal ANSI colours (used for ghostty and Neovim's :terminal).
local ansi = {
  "#000020", "#ff6b6b", "#90f020", "#ffa500", "#5f87ff", "#ff80ff", "#5fd7d7", "#c0c0c0",
  "#4a5a8a", "#ffa0a0", "#b0ff60", "#ffff60", "#80a0ff", "#ffb0ff", "#90fff0", "#ffffff",
}

-- Highlight groups. Keys are group names, values are nvim_set_hl() specs.
-- Treesitter/LSP groups mostly link to these legacy groups by default.
local hl = {
  -- editor
  Normal = { fg = c.fg, bg = c.bg },
  NormalNC = { link = "Normal" },
  NormalFloat = { fg = c.fg, bg = c.bg_dark },
  FloatBorder = { fg = c.border, bg = c.bg_dark },
  FloatTitle = { fg = c.statement, bg = c.bg_dark, bold = true },
  Cursor = { fg = "#000000", bg = c.yellow },
  CursorLine = { bg = c.bg_hl },
  CursorColumn = { bg = c.bg_hl },
  ColorColumn = { bg = c.bg_hl },
  CursorLineNr = { fg = c.yellow, bold = true },
  LineNr = { fg = c.fg_gutter },
  SignColumn = { fg = c.fg_gutter },
  FoldColumn = { fg = c.fg_gutter },
  Folded = { fg = c.fg_dim, bg = c.bg_dark, italic = true },
  NonText = { fg = c.fg_gutter },
  Whitespace = { fg = c.fg_gutter },
  EndOfBuffer = { fg = c.bg },
  SpecialKey = { fg = c.cyan },
  Conceal = { fg = c.fg_dim },
  Visual = { bg = c.bg_visual },
  VisualNOS = { bg = c.bg_visual },
  Search = { fg = "#000000", bg = "#c8b040" },
  CurSearch = { fg = "#000000", bg = c.yellow, bold = true },
  IncSearch = { link = "CurSearch" },
  Substitute = { fg = "#000000", bg = c.magenta },
  MatchParen = { fg = c.yellow, bg = c.bg_visual, bold = true },
  Directory = { fg = c.directory, bold = true },
  Title = { fg = c.magenta, bold = true },
  WinSeparator = { fg = c.border },
  VertSplit = { link = "WinSeparator" },
  StatusLine = { fg = c.fg, bg = c.bg_popup },
  StatusLineNC = { fg = c.fg_dim, bg = c.bg_dark },
  TabLine = { fg = c.fg_dim, bg = c.bg_dark },
  TabLineFill = { bg = c.bg_dark },
  TabLineSel = { fg = c.fg_bright, bg = c.bg_popup_sel, bold = true },
  WinBar = { fg = c.fg, bold = true },
  WinBarNC = { fg = c.fg_dim },
  Pmenu = { fg = c.fg, bg = c.bg_popup },
  PmenuSel = { fg = c.fg_bright, bg = c.bg_popup_sel, bold = true },
  PmenuSbar = { bg = c.bg_popup },
  PmenuThumb = { bg = c.border },
  PmenuMatch = { fg = c.identifier, bold = true },
  PmenuMatchSel = { fg = c.yellow, bold = true },
  PmenuKind = { fg = c.type },
  PmenuExtra = { fg = c.fg_dim },
  WildMenu = { link = "PmenuSel" },
  QuickFixLine = { bg = c.bg_visual, bold = true },
  ModeMsg = { fg = c.identifier, bold = true },
  MoreMsg = { fg = c.green },
  Question = { fg = c.green },
  ErrorMsg = { fg = c.red, bold = true },
  WarningMsg = { fg = c.orange },
  SpellBad = { sp = c.red, undercurl = true },
  SpellCap = { sp = c.yellow, undercurl = true },
  SpellLocal = { sp = c.cyan, undercurl = true },
  SpellRare = { sp = c.magenta, undercurl = true },

  -- syntax
  Comment = { fg = c.comment, italic = true },
  Constant = { fg = c.constant },
  String = { fg = c.constant },
  Character = { fg = c.constant },
  Number = { fg = c.constant },
  Boolean = { fg = c.constant },
  Float = { fg = c.constant },
  Identifier = { fg = c.identifier },
  Function = { fg = c.identifier },
  Statement = { fg = c.statement },
  Operator = { fg = c.fg },
  Keyword = { fg = c.statement },
  Type = { fg = c.type },
  PreProc = { fg = c.preproc },
  Special = { fg = c.special },
  Delimiter = { fg = c.fg },
  Underlined = { fg = c.blue, underline = true },
  Error = { fg = c.red, bold = true },
  Todo = { fg = c.bg, bg = c.yellow, bold = true },
  ["@variable"] = { fg = c.fg },
  ["@variable.member"] = { fg = c.fg },
  ["@property"] = { fg = c.fg },
  ["@module"] = { fg = c.type },
  ["@punctuation.bracket"] = { fg = c.fg },
  ["@punctuation.delimiter"] = { fg = c.fg },
  ["@constructor"] = { fg = c.type },

  -- diffs: tinted backgrounds, no forced foreground, so code keeps its colours.
  -- Side-by-side diffs pair lines: a line edited on both sides is DiffChange
  -- (blue, with the edited characters in DiffText); only lines with no
  -- counterpart are DiffAdd (green, new side) or removed (red, old side).
  -- DiffDelete must not set fg: diffview copies it for removed lines.
  DiffAdd = { bg = c.diff_add },
  DiffChange = { bg = c.diff_change },
  DiffText = { fg = c.fg_bright, bg = c.diff_text, bold = true },
  DiffDelete = { bg = c.diff_delete },
  Added = { fg = c.green },
  Changed = { fg = c.blue },
  Removed = { fg = c.red },
  diffAdded = { link = "Added" },
  diffChanged = { link = "Changed" },
  diffRemoved = { link = "Removed" },
  diffFile = { fg = c.statement, bold = true },
  diffLine = { fg = c.magenta },
  DiffviewFilePanelTitle = { fg = c.statement, bold = true },
  DiffviewDiffDeleteDim = { fg = c.fg_gutter },

  -- git signs in the gutter
  GitSignsAdd = { fg = c.green },
  GitSignsChange = { fg = c.blue },
  GitSignsDelete = { fg = c.red },
  GitSignsCurrentLineBlame = { fg = c.fg_gutter, italic = true },

  -- diagnostics
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.orange },
  DiagnosticInfo = { fg = c.cyan },
  DiagnosticHint = { fg = c.fg_dim },
  DiagnosticOk = { fg = c.green },
  DiagnosticVirtualTextError = { fg = c.red, bg = "#2a0a30" },
  DiagnosticVirtualTextWarn = { fg = c.orange, bg = "#2a1a30" },
  DiagnosticVirtualTextInfo = { fg = c.cyan, bg = "#051a48" },
  DiagnosticVirtualTextHint = { fg = c.fg_dim, bg = "#0a0a50" },
  DiagnosticUnderlineError = { sp = c.red, undercurl = true },
  DiagnosticUnderlineWarn = { sp = c.orange, undercurl = true },
  DiagnosticUnderlineInfo = { sp = c.cyan, undercurl = true },
  DiagnosticUnderlineHint = { sp = c.fg_dim, undercurl = true },
  DiagnosticUnnecessary = { fg = c.fg_dim },
  DiagnosticDeprecated = { strikethrough = true },

  -- LSP
  LspReferenceText = { bg = c.bg_hl },
  LspReferenceRead = { bg = c.bg_hl },
  LspReferenceWrite = { bg = c.bg_hl, underline = true },
  LspInlayHint = { fg = c.fg_gutter, italic = true },
  LspSignatureActiveParameter = { fg = c.yellow, bold = true },

  -- plugins
  WhichKey = { fg = c.statement },
  WhichKeyGroup = { fg = c.magenta },
  WhichKeyDesc = { fg = c.fg },
  WhichKeySeparator = { fg = c.fg_gutter },
  FzfLuaBorder = { link = "FloatBorder" },
  OilDir = { link = "Directory" },
  BlinkCmpMenuBorder = { link = "FloatBorder" },
  BlinkCmpDocBorder = { link = "FloatBorder" },

  -- statusline pieces (lua/core/statusline.lua)
  StlProject = { fg = c.bg, bg = c.statement, bold = true },
  StlBranch = { fg = c.magenta, bg = c.bg_popup },
  StlMuted = { fg = c.fg_dim, bg = c.bg_popup },
  StlLspOk = { fg = c.green, bg = c.bg_popup },
  StlLspBusy = { fg = c.yellow, bg = c.bg_popup },

  -- floating terminal border (lua/core/terminal.lua)
  TermBorderActive = { fg = c.green, bg = c.bg_dark, bold = true },
  TermBorderIdle = { fg = c.fg_gutter, bg = c.bg_dark },
}

return {
  name = "deepblue",
  background = "dark",
  colors = c,
  ansi = ansi,
  hl = hl,
  terminal = {
    background = c.bg,
    foreground = c.fg,
    cursor = c.yellow,
    cursor_text = "#000000",
    selection_bg = c.bg_visual,
    selection_fg = c.fg_bright,
  },
}
