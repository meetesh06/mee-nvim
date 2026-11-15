-- deepblue: Neovim's classic `darkblue`, reworked for readability.
--
-- Single source of truth for the editor, terminal AND opencode colours. Edit this
-- file, then regenerate all outputs:
--
--   nvim -l scripts/gen-theme.lua            -> colors/deepblue.lua + extras/ghostty/deepblue
--                                               + extras/opencode/deepblue.json
--   nvim -l scripts/gen-theme.lua --install  -> also copies the ghostty theme into
--                                               ~/.config/ghostty/themes/ and the opencode
--                                               theme into ~/.config/opencode/themes/
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

-- opencode theme (https://opencode.ai/v2/docs/cli/theme).
--
-- opencode splits colours into a shared token tree (`tokens`, written as `base`)
-- and per-mode 9-step hue scales (`hues`, written as `dark.hue`) that the tokens
-- reference as "$hue.<hue>.<step>". Dark scales run light -> dark from 100 to 900.
-- Only dark is provided: deepblue is a navy theme, and opencode falls back to the
-- only mode a theme ships, so a light terminal still gets these colours.
local opencode = {
  -- Surfaces, in the navy family (bg, raised panels, hover, selection).
  gray = {
    ["100"] = "#ffffff", -- fg_bright
    ["200"] = "#c0c0c0", -- fg
    ["300"] = "#9098c0",
    ["400"] = "#8088b0", -- fg_dim
    ["500"] = "#4a5a8a", -- fg_gutter
    ["600"] = "#10106a",
    ["700"] = "#0a0a5c", -- bg_hl
    ["800"] = "#000040", -- bg
    ["900"] = "#00002a", -- bg_dark
  },
  red = {
    ["100"] = "#ffd0d0", ["200"] = c.red, ["300"] = "#e85c5c", ["400"] = "#c44a4a",
    ["500"] = "#a03a3a", ["600"] = "#7d2b2b", ["700"] = "#5c1e1e", ["800"] = "#3d1313",
    ["900"] = "#220a0a",
  },
  orange = {
    ["100"] = "#ffe0b0", ["200"] = c.orange, ["300"] = "#e8951f", ["400"] = "#c47c1a",
    ["500"] = "#a06415", ["600"] = "#7d4d10", ["700"] = "#5a370c", ["800"] = "#3a2308",
    ["900"] = "#1f1304",
  },
  yellow = {
    ["100"] = "#ffffb0", ["200"] = c.yellow, ["300"] = "#e6e657", ["400"] = "#c2c24a",
    ["500"] = "#9e9e3d", ["600"] = "#7a7a30", ["700"] = "#585823", ["800"] = "#383816",
    ["900"] = "#1d1d0b",
  },
  green = {
    ["100"] = "#b0ff60", ["200"] = c.green, ["300"] = "#7cd21c", ["400"] = "#66ac17",
    ["500"] = "#508712", ["600"] = "#3b630d", ["700"] = "#294309", ["800"] = "#182805",
    ["900"] = "#0c1402",
  },
  cyan = {
    ["100"] = c.identifier, ["200"] = c.cyan, ["300"] = "#52bcbc", ["400"] = "#449a9a",
    ["500"] = "#367a7a", ["600"] = "#295c5c", ["700"] = "#1d4242", ["800"] = "#122a2a",
    ["900"] = "#091616",
  },
  blue = {
    ["100"] = "#a8c0ff", ["200"] = c.blue, ["300"] = "#6f8de0", ["400"] = "#5c77c0",
    ["500"] = "#4960a0", ["600"] = "#374a80", ["700"] = "#273660", ["800"] = "#182340",
    ["900"] = "#0c1220",
  },
  purple = {
    ["100"] = "#ffb0ff", ["200"] = c.magenta, ["300"] = "#e071e0", ["400"] = "#c061c0",
    ["500"] = "#a051a0", ["600"] = "#804180", ["700"] = "#603160", ["800"] = "#402040",
    ["900"] = "#241224",
  },
  -- Aliases: accent drives titles/headings/keywords (magenta, like nvim's Title),
  -- interactive drives links and functions (identifier cyan), neutral the surfaces.
  accent = "$hue.purple",
  interactive = "$hue.cyan",
  neutral = "$hue.gray",
}

-- The shared token tree. `$hue.x.n` / `$token.path` references are resolved by
-- opencode, so the tokens below follow the scales above.
local opencode_tokens = {
  categorical = { "blue", "purple", "green", "orange", "red" },

  text = {
    base = "$hue.neutral.200",
    muted = "$hue.neutral.400",
    faint = "$hue.neutral.300",
    action = {
      primary = {
        base = "$hue.interactive.200",
        ["$hovered"] = "$hue.interactive.100",
        -- nvim's PmenuSel/WildMenu: bright white on the selection blue.
        ["$focused"] = c.fg_bright,
        ["$selected"] = "$hue.interactive.100",
        ["$disabled"] = "$hue.neutral.400",
      },
      secondary = { base = "$hue.neutral.400", ["$hovered"] = "$hue.neutral.200" },
      destructive = { base = c.red, ["$disabled"] = "$hue.neutral.400" },
    },
    formfield = {
      base = "$hue.neutral.200",
      ["$hovered"] = "$hue.interactive.100",
      ["$focused"] = c.yellow,
      ["$pressed"] = "$hue.interactive.100",
      ["$selected"] = "$hue.interactive.100",
      ["$disabled"] = "$hue.neutral.400",
    },
    feedback = {
      error = { base = c.red },
      warning = { base = c.orange },
      success = { base = c.green },
      info = { base = c.cyan },
    },
  },

  background = {
    base = "$hue.neutral.800", -- #000040: same navy as the editor
    raised = {
      base = "$hue.neutral.700", -- sidebars, panels
      high = "$hue.neutral.600", -- hover
      max = "$hue.neutral.500", -- the most prominent fill
    },
    action = {
      primary = {
        base = "transparent",
        ["$hovered"] = "$hue.neutral.600",
        ["$focused"] = c.bg_popup_sel,
        ["$selected"] = "transparent",
      },
      secondary = { base = "transparent", ["$hovered"] = "$hue.neutral.700" },
      destructive = { base = c.red },
    },
    formfield = {
      base = "$hue.neutral.700",
      ["$hovered"] = "$hue.neutral.600",
      ["$focused"] = "$hue.neutral.600",
      ["$pressed"] = "$hue.neutral.600",
      ["$selected"] = "$hue.neutral.600",
      ["$disabled"] = "$hue.neutral.700",
    },
    feedback = {
      error = { base = "#2a0a30" }, -- nvim's DiagnosticVirtualTextError bg
      warning = { base = "#2a1a30" },
      success = { base = c.diff_add },
      info = { base = "#051a48" },
    },
  },

  border = { base = c.border, ["$focused"] = c.blue },
  scrollbar = { base = c.fg_gutter, ["$hovered"] = c.blue },

  -- Diff colours mirror the nvim groups: tinted backgrounds, brighter fills for
  -- the exact changed characters (diff_text).
  diff = {
    text = { added = c.green, removed = c.red, context = "$hue.neutral.400", hunkHeader = c.blue },
    background = {
      added = c.diff_add,
      removed = c.diff_delete,
      context = "$hue.neutral.700",
    },
    -- highlight is the emphasised text on a changed character (the default theme
    -- uses light green / pink), so it takes the bright ANSI green and red
    -- (ansi is 1-based: ansi[1] is palette 0).
    highlight = { added = ansi[11], removed = ansi[10] },
    lineNumber = {
      text = c.fg_gutter,
      background = { added = "#0b3f28", removed = "#6b1232" },
    },
  },

  -- Straight from the nvim syntax groups.
  syntax = {
    comment = c.comment,
    keyword = c.statement,
    -- `function` is a Lua keyword, so this key needs brackets.
    ["function"] = c.identifier,
    variable = c.fg,
    string = c.constant,
    number = c.constant,
    type = c.type,
    operator = c.fg,
    punctuation = c.fg,
  },

  markdown = {
    text = c.fg,
    heading = c.magenta, -- nvim's Title
    link = "#5f87ff",
    linkText = c.cyan,
    code = c.type,
    blockQuote = c.statement,
    emphasis = c.preproc,
    strong = c.yellow,
    horizontalRule = c.border,
    listItem = c.cyan,
    listEnumeration = c.blue,
    image = c.magenta,
    imageText = c.directory,
    codeBlock = c.fg,
  },

  -- Dialogs, menus, toasts: the popup navy and selection blue of Pmenu/PmenuSel.
  ["@dialog"] = {
    background = {
      base = "#0b1660",
      raised = { base = "#10207a", high = c.bg_popup_sel, max = c.bg_popup_sel },
      action = {
        primary = {
          ["$hovered"] = "#1a2c92",
          ["$focused"] = c.bg_popup_sel,
          ["$selected"] = c.bg_popup_sel,
        },
        secondary = { ["$hovered"] = "#10207a" },
      },
    },
    text = {
      base = c.fg,
      muted = c.fg_dim,
      action = {
        primary = {
          base = c.fg,
          ["$hovered"] = c.fg_bright,
          ["$focused"] = c.fg_bright,
          ["$selected"] = c.fg_bright,
        },
        secondary = { base = c.fg_dim, ["$hovered"] = c.fg },
      },
    },
    border = { base = c.border },
    scrollbar = { base = c.border },
  },
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
  -- Gutter while the buffer has unsaved changes (lua/core/statusline.lua)
  ModifiedLineNr = { fg = "#9a6420" }, -- dimmed orange
  ModifiedCursorLineNr = { fg = c.orange, bold = true },
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
  StatusLine = { fg = c.fg, bg = c.bg }, -- same navy as the editor: no separate strip
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
  -- Plain coloured text on the editor background; the mode colour also tints
  -- the accent bar on the far left.
  StlModeNormal = { fg = c.cyan, bg = c.bg, bold = true },
  StlModeInsert = { fg = c.green, bg = c.bg, bold = true },
  StlModeVisual = { fg = c.magenta, bg = c.bg, bold = true },
  StlModeReplace = { fg = c.red, bg = c.bg, bold = true },
  StlModeCommand = { fg = c.yellow, bg = c.bg, bold = true },
  StlModeTerminal = { fg = c.orange, bg = c.bg, bold = true },
  StlProject = { fg = c.statement, bg = c.bg, bold = true },
  StlBranch = { fg = c.magenta, bg = c.bg },
  StlAdd = { fg = c.green, bg = c.bg },
  StlChange = { fg = c.yellow, bg = c.bg },
  StlDelete = { fg = c.red, bg = c.bg },
  StlDir = { fg = c.fg_dim, bg = c.bg },
  StlFile = { fg = c.fg_bright, bg = c.bg, bold = true },
  StlModified = { fg = c.orange, bg = c.bg, bold = true },
  StlRecording = { fg = c.red, bg = c.bg, bold = true },
  StlMuted = { fg = c.fg_dim, bg = c.bg },
  StlLspOk = { fg = c.green, bg = c.bg },
  StlLspBusy = { fg = c.yellow, bg = c.bg },

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
  opencode = { hues = opencode, tokens = opencode_tokens },
  terminal = {
    background = c.bg,
    foreground = c.fg,
    cursor = c.yellow,
    cursor_text = "#000000",
    selection_bg = c.bg_visual,
    selection_fg = c.fg_bright,
  },
}
