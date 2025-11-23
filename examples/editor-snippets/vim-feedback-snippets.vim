" Vim Snippets for Inline Code Feedback
"
" Installation Options:
"
" Option 1: UltiSnips (Recommended)
" 1. Install UltiSnips: https://github.com/SirVer/ultisnips
" 2. Copy UltiSnips section below to: ~/.vim/UltiSnips/all.snippets
" 3. Use: Type trigger and press Tab
"
" Option 2: Native Vim Abbreviations
" 1. Add abbreviations section below to: ~/.vimrc
" 2. Use: Type trigger and press Space
"
" Option 3: SnipMate
" 1. Install SnipMate: https://github.com/garbas/vim-snipmate
" 2. Use similar syntax to UltiSnips

" ============================================================================
" UltiSnips Snippets (~/.vim/UltiSnips/all.snippets or python.snippets, etc.)
" ============================================================================

" Python/Shell/Ruby Feedback
snippet fb "Feedback block" b
# FEEDBACK(@${1:username}, ${2:`date +%Y-%m-%d`}):
# ${3:Your feedback here}
# /FEEDBACK
$0
endsnippet

snippet fbr "Response to feedback" b
# RESPONSE(@${1:username}, ${2:`date +%Y-%m-%d`}):
# ${3:Your response here}
# /RESPONSE
$0
endsnippet

snippet fbx "Resolve feedback" b
# RESOLVED(@${1:username}, ${2:`date +%Y-%m-%d`}):
# ${3:Resolution explanation}
# /RESOLVED
$0
endsnippet

snippet fbs "Simple feedback (no metadata)" b
# FEEDBACK:
# ${1:Your feedback here}
# /FEEDBACK
$0
endsnippet

" JavaScript/TypeScript/C/C++/Go/Java/Rust Feedback
snippet fbjs "Feedback block (JS/C style)" b
// FEEDBACK(@${1:username}, ${2:`date +%Y-%m-%d`}):
// ${3:Your feedback here}
// /FEEDBACK
$0
endsnippet

snippet fbrjs "Response (JS/C style)" b
// RESPONSE(@${1:username}, ${2:`date +%Y-%m-%d`}):
// ${3:Your response here}
// /RESPONSE
$0
endsnippet

snippet fbxjs "Resolve (JS/C style)" b
// RESOLVED(@${1:username}, ${2:`date +%Y-%m-%d`}):
// ${3:Resolution explanation}
// /RESOLVED
$0
endsnippet

" Markdown/HTML Feedback
snippet fbmd "Feedback block (HTML comment)" b
<!-- FEEDBACK(@${1:username}, ${2:`date +%Y-%m-%d`}):
${3:Your feedback here}
/FEEDBACK -->
$0
endsnippet

snippet fbrmd "Response (HTML comment)" b
<!-- RESPONSE(@${1:username}, ${2:`date +%Y-%m-%d`}):
${3:Your response here}
/RESPONSE -->
$0
endsnippet

snippet fbxmd "Resolve (HTML comment)" b
<!-- RESOLVED(@${1:username}, ${2:`date +%Y-%m-%d`}):
${3:Resolution explanation}
/RESOLVED -->
$0
endsnippet

" ============================================================================
" Native Vim Abbreviations (add to ~/.vimrc)
" ============================================================================
"
" These work without plugins but are less sophisticated
" Usage: Type trigger word and press Space

" Python/Shell feedback abbreviations
autocmd FileType python,sh,ruby,yaml iabbrev <buffer> fb# #<Space>FEEDBACK(@username,<Space><C-R>=strftime("%Y-%m-%d")<CR>):<CR>#<Space><CR>#<Space>/FEEDBACK<Esc>kki
autocmd FileType python,sh,ruby,yaml iabbrev <buffer> fbr# #<Space>RESPONSE(@username,<Space><C-R>=strftime("%Y-%m-%d")<CR>):<CR>#<Space><CR>#<Space>/RESPONSE<Esc>kki
autocmd FileType python,sh,ruby,yaml iabbrev <buffer> fbx# #<Space>RESOLVED(@username,<Space><C-R>=strftime("%Y-%m-%d")<CR>):<CR>#<Space><CR>#<Space>/RESOLVED<Esc>kki

" JavaScript/C/Go feedback abbreviations
autocmd FileType javascript,typescript,c,cpp,go,java,rust iabbrev <buffer> fb// //<Space>FEEDBACK(@username,<Space><C-R>=strftime("%Y-%m-%d")<CR>):<CR>//<Space><CR>//<Space>/FEEDBACK<Esc>kki
autocmd FileType javascript,typescript,c,cpp,go,java,rust iabbrev <buffer> fbr// //<Space>RESPONSE(@username,<Space><C-R>=strftime("%Y-%m-%d")<CR>):<CR>//<Space><CR>//<Space>/RESPONSE<Esc>kki
autocmd FileType javascript,typescript,c,cpp,go,java,rust iabbrev <buffer> fbx// //<Space>RESOLVED(@username,<Space><C-R>=strftime("%Y-%m-%d")<CR>):<CR>//<Space><CR>//<Space>/RESOLVED<Esc>kki

" Markdown/HTML feedback abbreviations
autocmd FileType markdown,html iabbrev <buffer> fb<! <!--<Space>FEEDBACK(@username,<Space><C-R>=strftime("%Y-%m-%d")<CR>):<CR><CR>/FEEDBACK<Space>--><Esc>kki
autocmd FileType markdown,html iabbrev <buffer> fbr<! <!--<Space>RESPONSE(@username,<Space><C-R>=strftime("%Y-%m-%d")<CR>):<CR><CR>/RESPONSE<Space>--><Esc>kki
autocmd FileType markdown,html iabbrev <buffer> fbx<! <!--<Space>RESOLVED(@username,<Space><C-R>=strftime("%Y-%m-%d")<CR>):<CR><CR>/RESOLVED<Space>--><Esc>kki

" ============================================================================
" Custom Vim Functions (add to ~/.vimrc)
" ============================================================================
"
" Advanced: Custom function to insert feedback with username from git config

function! InsertFeedback(type)
    let l:username = system('git config user.name | tr -d "\n"')
    let l:date = strftime("%Y-%m-%d")
    let l:comment = &commentstring

    " Detect comment style
    if l:comment =~ '#'
        let l:prefix = '# '
    elseif l:comment =~ '//'
        let l:prefix = '// '
    else
        let l:prefix = '<!-- '
        let l:suffix = ' -->'
    endif

    if a:type == 'feedback'
        let l:template = [
            \ l:prefix . 'FEEDBACK(@' . l:username . ', ' . l:date . '):',
            \ l:prefix,
            \ l:prefix . '/FEEDBACK'
        \ ]
    elseif a:type == 'response'
        let l:template = [
            \ l:prefix . 'RESPONSE(@' . l:username . ', ' . l:date . '):',
            \ l:prefix,
            \ l:prefix . '/RESPONSE'
        \ ]
    elseif a:type == 'resolved'
        let l:template = [
            \ l:prefix . 'RESOLVED(@' . l:username . ', ' . l:date . '):',
            \ l:prefix,
            \ l:prefix . '/RESOLVED'
        \ ]
    endif

    call append(line('.'), l:template)
    normal! j$
endfunction

" Map to <leader>fb, <leader>fr, <leader>fx
nnoremap <leader>fb :call InsertFeedback('feedback')<CR>
nnoremap <leader>fr :call InsertFeedback('response')<CR>
nnoremap <leader>fx :call InsertFeedback('resolved')<CR>

" ============================================================================
" Usage Examples
" ============================================================================
"
" UltiSnips:
"   Type: fb<Tab>
"   Edit: username, date, feedback text (Tab between fields)
"   Finish: Tab to jump to next position
"
" Abbreviations:
"   Python: Type "fb#" then Space
"   JavaScript: Type "fb//" then Space
"   Markdown: Type "fb<!" then Space
"
" Custom Functions:
"   Normal mode: <leader>fb (e.g., \fb or Space-fb)
"   Automatically uses your git username
"   Places cursor ready to type feedback
"
" ============================================================================
" Quick Reference
" ============================================================================
"
" Triggers:
"   fb   = Feedback block
"   fbr  = Response block
"   fbx  = Resolved block
"   fbs  = Simple feedback (no metadata)
"
" File-specific (abbreviations):
"   fb#  = Python/Shell feedback
"   fb// = JavaScript/C feedback
"   fb<! = Markdown/HTML feedback
