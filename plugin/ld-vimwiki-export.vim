" File: plugin/ld-vimwiki-export.vim

" Prevent multiple loading
if exists("g:loaded_ld_vimwiki_export")
    finish
endif
let g:loaded_ld_vimwiki_export = 1

" --- HELPER FUNCTIONS ---

" Sanitizes text for web-safe URLs (Clean URLs)
function! SanitizeForUrl(text)
    let l:clean = a:text
    " Replace spaces, tabs, and underscores with hyphens
    let l:clean = substitute(l:clean, '[ \t_]\+', '-', 'g')
    " Remove all non-alphanumeric characters except dots, slashes, hyphens, and Polish letters
    let l:clean = substitute(l:clean, '[^a-zA-Z0-9\.\/\-ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]', '', 'g')
    " Collapse multiple hyphens into a single one
    let l:clean = substitute(l:clean, '\-\+', '-', 'g')
    " Convert to lowercase
    let l:clean = tolower(l:clean)
    " Remove leading and trailing hyphens
    let l:clean = substitute(l:clean, '^-\|-+$', '', 'g')
    return l:clean
endfunction

" Parses [[wikilinks]] into standard Markdown links in memory
function! ProcessMarkdownContent(filepath)
    let l:lines = readfile(a:filepath)
    let l:newlines = []
    for l:line in l:lines
        let l:processed_line = substitute(l:line, '\[\[\([^]]\+\)\]\]', '\=printf("[%s](%s.html)", submatch(1), SanitizeForUrl(submatch(1)))', 'g')
        call add(l:newlines, l:processed_line)
    endfor
    return join(l:newlines, "\n")
endfunction


" --- CORE EXPORT FUNCTIONS ---

" Exports the currently open Markdown file to HTML
function! LdWiki2HTML()
    " Check if lowdown is installed
    if !executable('lowdown')
        echoerr "ld-vimwiki-export: 'lowdown' is not installed or not in PATH."
        return
    endif

    let l:infile = expand('%:p')
    let l:indir = expand('~/vimwiki') . '/'
    let l:outdir = expand('~/vimwiki_html') . '/'
    
    let l:relpath = substitute(l:infile, '^' . escape(l:indir, '\/'), '', '')
    let l:clean_filename = SanitizeForUrl(fnamemodify(l:relpath, ':r'))
    let l:rel_dir = fnamemodify(l:relpath, ':h')
    
    " Calculate relative paths for CSS/JS based on folder depth
    if l:rel_dir != '.'
        let l:outfile = l:outdir . SanitizeForUrl(l:rel_dir) . '/' . l:clean_filename . '.html'
        let l:depth = len(split(l:rel_dir, '/'))
        let l:root_path = repeat('../', l:depth)
    else
        let l:outfile = l:outdir . l:clean_filename . '.html'
        let l:root_path = './'
    endif
    
    " Create output directory if it doesn't exist
    let l:outsubdir = fnamemodify(l:outfile, ':h')
    if !isdirectory(l:outsubdir) | call mkdir(l:outsubdir, "p") | endif
    
    " Process markdown and pass to lowdown
    let l:markdown_content = ProcessMarkdownContent(l:infile)
    let l:html_output = system('lowdown -s', l:markdown_content)
    
    " Inject CSS and JS before closing </head>
    let l:injections = '<link rel="stylesheet" href="' . l:root_path . 'style.css">' . "\n"
    let l:injections .= '<script src="' . l:root_path . 'script.js" defer></script>' . "\n"
    let l:html_output = substitute(l:html_output, '</head>', l:injections . '</head>', '')
    
    " Write final HTML to disk
    call writefile(split(l:html_output, "\n", 1), l:outfile)
    redraw!
    echom "Saved HTML with CSS/JS injected: " . l:outfile
endfunction

" Exports all Markdown files in the wiki directory to HTML
function! LdWikiAll2HTML()
    " Check if lowdown is installed
    if !executable('lowdown')
        echoerr "ld-vimwiki-export: 'lowdown' is not installed or not in PATH."
        return
    endif

    let l:indir = expand('~/vimwiki') . '/'
    let l:outdir = expand('~/vimwiki_html') . '/'
    echom "Starting full wiki conversion (CSS/JS enabled)..."
    
    let l:files = globpath(l:indir, '**/*.md', 0, 1)
    let l:count = 0
    
    for l:infile in l:files
        let l:relpath = substitute(l:infile, '^' . escape(l:indir, '\/'), '', '')
        let l:clean_filename = SanitizeForUrl(fnamemodify(l:relpath, ':r'))
        let l:rel_dir = fnamemodify(l:relpath, ':h')
        
        if l:rel_dir != '.'
            let l:outfile = l:outdir . SanitizeForUrl(l:rel_dir) . '/' . l:clean_filename . '.html'
            let l:depth = len(split(l:rel_dir, '/'))
            let l:root_path = repeat('../', l:depth)
        else
            let l:outfile = l:outdir . l:clean_filename . '.html'
            let l:root_path = './'
        endif
        
        let l:outsubdir = fnamemodify(l:outfile, ':h')
        if !isdirectory(l:outsubdir) | call mkdir(l:outsubdir, "p") | endif
        
        let l:markdown_content = ProcessMarkdownContent(l:infile)
        let l:html_output = system('lowdown -s', l:markdown_content)
        
        let l:injections = '<link rel="stylesheet" href="' . l:root_path . 'style.css">' . "\n"
        let l:injections .= '<script src="' . l:root_path . 'script.js" defer></script>' . "\n"
        let l:html_output = substitute(l:html_output, '</head>', l:injections . '</head>', '')
        
        call writefile(split(l:html_output, "\n", 1), l:outfile)
        let l:count += 1
    endfor
    
    redraw!
    echom "Done! Generated " . l:count . " files."
endfunction

" --- KEY MAPPINGS ---
" Overrides Vimwiki default mappings, active only in vimwiki buffers
autocmd FileType vimwiki nnoremap <buffer> <Leader>wh :call LdWiki2HTML()<CR>
autocmd FileType vimwiki nnoremap <buffer> <Leader>whh :call LdWikiAll2HTML()<CR>
