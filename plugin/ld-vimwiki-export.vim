" Plik: plugin/ld-vimwiki-export.vim

" Zabezpieczenie przed podwójnym ładowaniem
if exists("g:loaded_ld_vimwiki_export")
    finish
endif
let g:loaded_ld_vimwiki_export = 1

" --- TWOJE FUNKCJE ---
function! SanitizeForUrl(text)
    let l:clean = a:text
    let l:clean = substitute(l:clean, '[ \t_]\+', '-', 'g')
    let l:clean = substitute(l:clean, '[^a-zA-Z0-9\.\/\-ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]', '', 'g')
    let l:clean = substitute(l:clean, '\-\+', '-', 'g')
    let l:clean = tolower(l:clean)
    let l:clean = substitute(l:clean, '^-\|-+$', '', 'g')
    return l:clean
endfunction

function! ProcessMarkdownContent(filepath)
    let l:lines = readfile(a:filepath)
    let l:newlines = []
    for l:line in l:lines
        let l:processed_line = substitute(l:line, '\[\[\([^]]\+\)\]\]', '\=printf("[%s](%s.html)", submatch(1), SanitizeForUrl(submatch(1)))', 'g')
        call add(l:newlines, l:processed_line)
    endfor
    return join(l:newlines, "\n")
endfunction

function! LdWiki2HTML()
    let l:infile = expand('%:p')
    let l:indir = expand('~/vimwiki') . '/'
    let l:outdir = expand('~/vimwiki_html') . '/'
    
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
    redraw!
    echom "Zapisano HTML z podpiętym CSS/JS: " . l:outfile
endfunction

function! LdWikiAll2HTML()
    let l:indir = expand('~/vimwiki') . '/'
    let l:outdir = expand('~/vimwiki_html') . '/'
    echom "Rozpoczynam konwersję całej wiki (CSS/JS włączone)..."
    
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
    echom "Gotowe! Wygenerowano " . l:count . " plików."
endfunction

" --- MAPOWANIE KLAWISZY ---
autocmd FileType vimwiki nnoremap <buffer> <Leader>wh :call LdWiki2HTML()<CR>
autocmd FileType vimwiki nnoremap <buffer> <Leader>whh :call LdWikiAll2HTML()<CR>
