" Vim syntax file
" Language: Iridium IR, pretty printed (Forge --dump-forge-passes, *.pp.iri)

if exists("b:current_syntax")
  finish
endif

syn iskeyword @,48-57,_,192-255

" Comments (older dumps used ';' comments)
syn match irippComment ";.*$"

" --- Structure -------------------------------------------------------------

" file [jsmodule]
syn match irippHeaderKind "^file\>"
" async method* name(a, ...r) {entry: BB1, scope: 1, length: 2} [strict ...]
syn match irippHeaderKind "^\%(async \)\=\%(module\|script\|arrow\|function\|derived-ctor\|ctor\|method\|prop-init\|closure\)\*\=\ze[ (]"
" BB3 {scope: 2} [lexical]:
syn match irippBBHeader "^  BB\d\+\>"
" Trailing flag words of a header line: [arguments strict super()]
syn match irippFlags "\s\@<=\[[a-z.() ]\+\]:\=$"
" let / const / var / capture / pool lines of a container
syn match irippDecl "^  \%(let\|const\|var\|capture\|pool\)\>"

" --- Names -----------------------------------------------------------------

" %temporaries
syn match irippTemp "%\w\+"
" <home_object>, <loop-done>, <CONSTRUCTOR : C>
syn match irippInternal "<\h[A-Za-z0-9_: -]*>"
" g:global, m:module
syn match irippBindPrefix "\<[gm]:\ze[A-Za-z_$]"
" x#2 (shadowed name in scope 2), eval#-3
syn match irippScopeSuffix "\%(\w\|>\)\@<=#-\=\d\+\>"
" Function name in a header (after <internal>, so <CONSTRUCTOR : C> is one name)
syn match irippHeaderName "\%(^\%(async \)\=[a-z-]\+\*\= \)\@<=[^(]\+\ze("
" Private names: #x, .#[^brand], .#method[^brand]
syn match irippPrivate "\w\@<!#\%(\h\w*\)\="
syn match irippBrand "\[\zs\^"
" Internal slots: .[[Brands]], .[[Name]]
syn match irippSlot "\[\[\h\w*\]\]"
" Frame context: ctx.this, ctx.home_object, ...
syn match irippCtx "\<ctx\.\h\w*"
" x! : checked read (may throw)
syn match irippCheck "\%(\w\|[)\]>]\)\@<=!"

" --- Lambdas ---------------------------------------------------------------

" λ name@BB5, λ@BB5
syn match irippLambda "λ\%( [^@ ]\+\)\=@BB\d\+"
" method λ f@BB2, get λ x@BB3, set λ x@BB4
syn match irippLambdaKind "\<\%(method\|get\|set\|ctor\)\ze λ"
" Λ : uninitialized
syn match irippUninit "Λ"

" --- Keywords --------------------------------------------------------------

syn match irippStatement "\<\%(goto\|if\|else\|return\|throw\|yield\|nop\)\>\.\@!"
syn match irippStatement "\<\%(return\.async\|throw\.readonly\|try\.push\|try\.pop\|finally\.exit\|finally\.invoke\|finally\.ret\|forof\.start\|forof\.next\|forof\.close\|forin\.start\|forin\.next\|forawait\.start\|forawait\.next\|yield\.initial\|module\.init\|check\.ctor\|ctor\.ret\|this\.init\)\>"
syn match irippKeyword "\<\%(new\|await\|delete\|typeof\|instanceof\|in\|not\|void\|caught\|class\|extends\)\>\.\@!"
syn match irippKeyword "\<eval\ze#"
syn match irippModifier "\<\%(thisinit\|deferred\|noenum\)\>"
syn match irippSelf "\<\%(this\|new\.target\|arguments\|super\)\>"
syn match irippBuiltin "\<\%(topropkey\|getprototypeof\|inc\|dec\|tonumeric\|toobject\|toheap\|copyprops\|append\|decl\|declFun\|taint\|super\)\ze("

" key: value (header meta, named operands, destructuring)
syn match irippKey "\<\h\w*\ze: "

" Block labels (after the keys, so 'entry: BB1' keeps BB1 a label)
syn match irippLabel "\<BB\d\+\>"

" --- Operators -------------------------------------------------------------

" <- init, .= checked write, := define, = write, += append
syn match irippOperator "<-\|\.=\|:=\|+=\|->\|\.\.\.\|\s\@<==\s\@="

" --- Literals --------------------------------------------------------------

syn keyword irippBoolean true false
syn keyword irippNull null
syn keyword irippNumber NaN Infinity
syn match irippNumber "\<\d\+\%(\.\d\+\)\=\%([eE][+-]\=\d\+\)\=n\=\>"
syn match irippNumber "\<0[xXoObB]\x\+n\=\>"
syn match irippEscape "\\\%(x\x\x\|u\x\{4}\|u{\x\+}\|.\)" contained
syn region irippString start=+"+ skip=+\\.+ end=+"+ oneline contains=irippEscape
syn region irippTemplate start=+`+ skip=+\\.+ end=+`+ contains=irippEscape,irippTemplateExpr
syn region irippTemplateExpr matchgroup=irippTemplateBrace start=+\${+ end=+}+ contained contains=TOP
" /re/flags (only where an operand starts, so ' / ' stays division)
syn match irippRegex "\%(\%(<-\|[(,\[]\)\s*\)\@<=/[^/ *]\%(\\.\|[^/\\]\)*/[dgimsuyv]*"

" --- Links -----------------------------------------------------------------

hi def link irippComment       Comment
hi def link irippHeaderKind    Structure
hi def link irippHeaderName    Function
hi def link irippBBHeader      Title
hi def link irippFlags         PreProc
hi def link irippDecl          StorageClass
hi def link irippTemp          Identifier
hi def link irippInternal      Special
hi def link irippBindPrefix    PreProc
hi def link irippScopeSuffix   Comment
hi def link irippPrivate       Special
hi def link irippBrand         Special
hi def link irippSlot          Special
hi def link irippCtx           PreProc
hi def link irippCheck         Delimiter
hi def link irippLambda        Function
hi def link irippLambdaKind    StorageClass
hi def link irippUninit        Constant
hi def link irippStatement     Statement
hi def link irippKeyword       Keyword
hi def link irippModifier      StorageClass
hi def link irippSelf          Special
hi def link irippBuiltin       Function
hi def link irippKey           Type
hi def link irippLabel         Label
hi def link irippOperator      Operator
hi def link irippBoolean       Boolean
hi def link irippNull          Constant
hi def link irippNumber        Number
hi def link irippEscape        SpecialChar
hi def link irippString        String
hi def link irippTemplate      String
hi def link irippTemplateBrace Special
hi def link irippRegex         String

let b:current_syntax = "iripp"
