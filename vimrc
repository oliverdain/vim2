"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General configuration

" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" Temporary workaround to suppress warning a about vim calling
" deprecated Python features. See https://github.com/vim/vim/issues/3117
if has('python3')
  silent! python3 1
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle setup. All Vundle things have to be in this section
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()


Plugin 'VundleVim/Vundle.vim'
Plugin 'Valloric/YouCompleteMe'
Plugin 'SirVer/ultisnips'
Plugin 'nvie/vim-flake8'
Plugin 'tpope/vim-fugitive.git'
Plugin 'tpope/vim-rhubarb.git'
Plugin 'mileszs/ack.vim'
Plugin 'scrooloose/nerdtree'

call vundle#end()
filetype plugin indent on

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" End of Vundle setup.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! SmallFont :set guifont=Monaco:h10
command! Bigfont :set guifont=Menlo:h11

" Nerdtree shortcuts
map <C-n> :NERDTree %:p:h<CR>
map <C-p> :NERDTree<CR>

" To use ag/Silver Searcher (https://github.com/ggreer/the_silver_searcher)
" with the Ack plugin
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" Make backspace back up a tabstop. Especailly handy for editing Python
set smarttab

" Ultisnips defaults to <tab> but that conflicts with YouCompleteMe
let g:UltiSnipsExpandTrigger = '<C-j>'

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
autocmd BufReadPost *
 \ if line("'\"") > 0 && line("'\"") <= line("$") |
 \   exe "normal g`\"" |
 \ endif

" When we open a git commit message jump to the top and enter insert mode.
au BufNewFile,BufRead *.git/COMMIT_EDITMSG :1 | :start

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" don't show warning messages if a .swp file already exists
set shortmess+=A

set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set noshowcmd		" display incomplete commands
set incsearch		" do incremental searching
set ignorecase          " case insensitive searching
set hidden		" allow hidden buffers
"in normal mode wrap lines and break at work boundries
set wrap
set linebreak

" Sets tab stops and indenting. Note that in some cases this is done in
" ~/.vim/indent files and some is overridden below in the language specific
" sections.
set ts=3 sw=3 et        "tab stops and shift width == 3 and expand tabs to spaces

set showmatch           "show matching brackets
"
"Make <Tab> complete work like bash command line completion
set wildmode=longest,list

" Turn on a fancy status line
set statusline=%m\ [File:\ %f]\ [Type:\ %Y]\ [ASCII:\ %03.3b]\ [Col:\ %03v]\ [Line:\ %04l\ of\ %L]
set laststatus=2 " always show the status line

" Turn off swap files. Gets rid of annoying warnings that the file is open in
" two windows and keeps dirs from getting cluttered with .swp files but at the
" cost of greater risk of losing work.
set updatecount=0

" this combination of options causes a backup file to be written before a write
" begins but that file is deleted as soon as the write succeeds so we don't get
" a bunch of files ending with "~" cluttering things up.
set writebackup
set nobackup

" Enable file type detection.
" Also load indent files, to automatically do language-dependent indenting.
filetype plugin indent on
filetype plugin on

" Vimdiff highlighting
if ! has("gui_running")
  " Make vimdiff colors not suck
  highlight DiffAdd cterm=none ctermfg=Black ctermbg=Green
  highlight DiffDelete cterm=none ctermfg=Black ctermbg=Red
  highlight DiffChange cterm=none ctermfg=Black ctermbg=Yellow
  highlight DiffText cterm=none ctermfg=Black ctermbg=Magenta
endif

if has("gui_running")
   set background=light
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General commands/keyboard shortcuts for all files

"commands for easily adding a blank line above or below the current line
map <leader>o o<esc>
map <leader>O O<esc>

" emacs like key bindings in insert mode
imap <C-e> <esc>$a
imap <C-a> <esc>0i
imap <C-u> <esc>ld0i
imap <C-k> <esc>ld$a

" C-s to save in insert and normal mode
imap <C-s> <esc>:w<cr>a
nmap <C-s> :w<cr>

"map killws to a command to remove trailing whitespace
command! Killws :% s/\s\+$//g

" Close the current buffer but leave the window open
" on the previous buffer (if you just close the current buffer it also
" closes the window. b# goes to previous buffer, and then bd# deletes the
" one you were just on)
command! Bc :b#|:bd#

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
endif

" A command to call :make and then open the error window at the bottom of the
" screen.
command! Mk :make|:copen|:winc J

" Sorts #include blocks files (or any other block of things with blank lines
" above and below)
map <leader>s {jV}k :!sort<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Templates: My personal templating system
"
" It works like this:
"
" Given a new file like /p1/p2/p3/p4/file.h we look in ~/.vim/templates for
" matching templates. We 1st start by walking backward up the list of dirs so
" we look for a ~/.vim/templates/p4 directory. If there is one and it contains
" a template.h file that is used. If not (either not such dir or there is a
" dir but it doesn't contain a .h template) we go up and look for p3, then p2,
" etc. Suppose we find a ~/.vim/templates/p2. We then go forwards again
" looking for a ~/.vim/templates/p2/p3/template.h, then a
" ~/.vim/templates/p2/p3/p4/template.h, etc. The longest matching path is
" used. If we can't find any matching subdirs we just look for a template.h
" file in ~/.vim/templates and use that.
"
" Template matching rules: template files are of the form template_<suffix> so
" template_.h matches files that end in '.h' while template_SConstruct matches
" files that end with 'SConstruct'.
"
" Once a template is found it is loaded and all the <+KEYWORD+> items are
" replaced as per ExpandPlaceholders() below. This is a very flexible
" mechanism that allows you to easily add new keywords and functions for
" their replacement. Keywords also can accept arguments.
"
" Finally, if the string ~~CURSOR~~ is found the cursor is moved to that
" position and the user is left in insert mode.

" Given directory dir returns the name of a template that matches fname or the
" empty string if not such template could be found.
function! FindTemplateMatch(dir, fname)
   let l:dir = a:dir
   if match(a:dir, '.*/$') == -1
      let l:dir = a:dir . '/'
   endif
   let l:templates = split(glob(l:dir . 'template_*'))
   for l:template_fname in l:templates
      let l:suf_idx = strridx(l:template_fname, 'template_')
      let l:suffix = strpart(l:template_fname, l:suf_idx + 9)
      let l:suf_idx = strridx(a:fname, l:suffix)
      if l:suf_idx >= 0
         if strpart(a:fname, l:suf_idx) == l:suffix
            return l:template_fname
         endif
      endif
   endfor
   return ''
endfunction

" Given a file whose full path is fname see if there is an appropriate
" template for it. If so return the name of that template.
function! FindTemplate(fname)
   let l:templates_dir = fnamemodify('~/.vim/templates', ':p')
   " First see if there's a template that matches any of the directories in
   " the path. If so we use this. If not we just check file extension.

   " Expand to a full path and strip off the file name so we have just the
   " directory name
   let l:fname_abs_dir = fnamemodify(a:fname, ':p:h')
   " Cur path starts out as the full path. Then we remove the ending dir one
   " dir at a time to see if we can find a matching template. For example, if
   " it starts with '/home/odain/this/long/path' we first look for a directory
   " named 'path' in the templates directory. If there isn't one we then
   " update l:cur_path to be '/home/odain/this/long' and look for a dir named
   " 'long', etc.
   let l:cur_path = l:fname_abs_dir
   let l:cur_match_template = ''
   while strlen(l:cur_path) > 1
      let l:cdir = fnamemodify(l:cur_path, ':t')
      let l:match_dir = finddir(l:cdir, l:templates_dir)
      " We found a matching dir but we're not done. We also need to see if
      " there's a matching template. There also might be a more specific
      " matching template (e.g. in a subdirectory) that we should use instead.
      if !empty(l:match_dir)
         let l:cur_match_dir = l:templates_dir . l:cdir
         let l:potential_template = FindTemplateMatch(l:cur_match_dir, a:fname)
         if !empty(l:potential_template) && filereadable(l:potential_template)
            let l:cur_match_template = l:potential_template
         endif
         " Now see if there's a more specific match. To do that we go through
         " the path from the matching dir forward looking for subdirs that
         " also match.
         let l:dir_suffix = strpart(l:fname_abs_dir, strlen(l:cur_path))
         let l:subdirs = split(l:dir_suffix, '/')
         let l:cur_subdir = l:cur_match_dir
         for l:subdir in l:subdirs
            if !empty(finddir(l:subdir, l:cur_subdir))
               let l:cur_subdir = l:cur_subdir . '/' . l:subdir
               let l:potential_template = FindTemplateMatch(l:cur_subdir, a:fname)
               if !empty(l:potential_template) && filereadable(l:potential_template)
                  let l:cur_match_template = l:potential_template
               endif
            else
               break
            endif
         endfor
         " If we've got a template now we're done
         if !empty(l:cur_match_template)
            return l:cur_match_template
         endif
      endif  
      let l:cur_path = fnamemodify(l:cur_path, ':h')
   endwhile
 
   " If we got here we didn't find a template in any of the subdirs so we just
   " look by file extension for a match.
   let l:cur_match_template = FindTemplateMatch(l:templates_dir, a:fname)
   if !empty(l:cur_match_template) && filereadable(l:cur_match_template)
      return l:cur_match_template
   else
      return ''
   endif
endfunction

" Function used to expand <+FOO+> place holders in the current buffer. Some
" place holders have a ,ARG suffix like <+FOO,ARG+> in which case ARG is used
" to help us expand FOO. Generally this is called after a macro file is read
" in.
function! ExpandPlaceholders()
   " Map from placeholders to functions that expand them
   let l:placeholders = {'VIM_FILE': function('ExpandVimFile'),
            \            'INCLUDE_GUARD': function('ExpandIncludeGuard'),
            \            'DATE': function('ExpandDate')}
   let l:place_pattern = '<+\([^+,]\+\),\?\([^+]*\)+>'
   let l:line = search(l:place_pattern)
   while l:line > 0
      let l:line_text = getline(l:line)
      let l:place_holder = matchlist(l:line_text, l:place_pattern)
      if !has_key(l:placeholders, l:place_holder[1])
         echoerr "Unknown placeholder '" l:place_holder[1] "'"
         return
      endif
      " Find the replacement function in the dictionary
      let l:Fun = l:placeholders[l:place_holder[1]]
      " Call the function passing anyting after the "," as additional
      " arguments
      if (len(l:place_holder) > 2 && !empty(l:place_holder[2])) 
         let l:replacement = l:Fun(l:place_holder[2])
      else
         let l:replacement = l:Fun()
      endif
      " Unset l:Fun or we get errors when we call :let again. Not sure why as
      " you can usually overwrite a variable but function pointers seem to be
      " special.
      unlet l:Fun
      let l:m_start = match(l:line_text, l:place_holder[0])
      let l:m_end = matchend(l:line_text, l:place_holder[0])
      let l:line_text = strpart(l:line_text, 0, l:m_start) . l:replacement .  strpart(l:line_text, l:m_end)
      :call setline(l:line, l:line_text) 
      let l:line = search(l:place_pattern)
   endwhile
endfunction

" Do fnamemodify on the current file name with the supplied arguments. For
" example, passing ':p' results in the full path, etc.
function! ExpandVimFile(fargs)
   return fnamemodify(expand('%'), a:fargs)
endfunction

" To be used like #ifndef <+INCLUDE_GUARD,spar+> via ExpandPlaceholders. This
" expands the INCLUDE_GUARD to be PATH_TO_FILE_H_ where the path is relative
" to the argument (in the example above it's relative to the directory spar).
function! ExpandIncludeGuard(eargs)
   let l:fname = fnamemodify(expand('%'), ':p')
   let l:end_path_pos = matchend(l:fname, '/' . a:eargs . '/')
   let l:end_path = strpart(l:fname, l:end_path_pos)
   let l:end_path = substitute(l:end_path, '/', '_', 'g')
   let l:end_path = substitute(l:end_path, '-', '_', 'g')
   let l:end_path = substitute(l:end_path, ' ', '_', 'g')
   let l:end_path = substitute(l:end_path, '\.', '_', 'g')
   return toupper(l:end_path) . '_'
endfunction

" Returns a string representing today's date. The argument is a string
" specifying how the date should be formatted in standard strftime notation.
function! ExpandDate(dargs)
  return strftime(a:dargs, localtime()) 
endfunction

function! MoveToCursor()
   " The \V makes the pattern "very non-magic" so its pretty much a literal
   " string match.
   let l:line = search('\V~~CURSOR~~')
   if l:line != 0
      " The string '~~CURSOR~~' is 10 characters long and search leaves us at the
      " beginning of the match so delete the next 10 characters and put us in
      " insert mode.
      normal 10dl
      startinsert
   endif
endfunction

function! OnNewFile()
   let l:template = FindTemplate(expand('%'))
   if !empty(l:template)
      " move the cursor to be beginning of the file
      normal gg
      " Read in the template
      execute ':r ' . l:template
      " The read command puts the file contents on the line *after*
      " the cursor position so we have a blank line at the top of the
      " file. Delete that.
      normal ggdd
      :call ExpandPlaceholders()
      " If there's a ~~CURSOR~~ marker in the file move to it and start insert
      " mode
      :call MoveToCursor()
   endif
endfunction

au! BufNewFile * :call OnNewFile()

"""""""""""""""""""""""""""" end templates



""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Language specific configs
" Note some of this is also done via ~/.vim/indent, ~/.vim/ftplugin, etc.

""""
" Configs for multiple languages
" highlight characters after column 80
hi TooManyChars guifg=White guibg=Red ctermfg=White ctermbg=Red
autocmd FileType java,cpp,c,python,javascript match TooManyChars /\%>120v.\+/
" Quick command to turn off this highlighting. Handy when editing files that
" don't conform to the char limit.
" TODO: This turns off highlighting globally. Should figure out how to do it
" for just the current buffer.
command! NoHl :hi TooManyChars NONE

"""
" Markdown

autocmd FileType markdown setlocal tw=120 spell

""""
" Python
autocmd FileType python setlocal foldmethod=indent
" set foldlevel really high so that, initially, all folds are open
autocmd FileType python setlocal foldlevel=1000
autocmd FileType python setlocal et ts=4 sw=4 tw=79
autocmd FileType python map <leader>l :call Flake8()<CR>
autocmd FileType python setlocal completeopt=menu,longest,preview
autocmd FileType python nmap <buffer> <C-]> :call g:jedi#goto()<CR>
let g:jedi#popup_on_dot = 0


""""
" C++
" Searches up from the current directory to the directory with a build.gradle
" (e.g. the sub-project root) and then from there down for a file with the
" given name.
function! FindRelToSubProject(fname)
   let l:thisdir = expand('%:p:h')
   let l:buildfile = findfile('build.gradle', l:thisdir . ';')
   let l:builddir = fnamemodify(l:buildfile, ':p:h')
   return findfile(a:fname, l:builddir . '/**')
endfunction

" Find a file with the same name as the current buffer but with a different
" file extension. Specifically find a file with the same name as current file
" but with the extension swapped as per the argument using
" FindRelToSubProject. Then open that file for editing.
function! EditExtension(ext)
   let l:basefile = expand('%:t:r')
   let l:newfile = FindRelToSubProject(l:basefile . a:ext)
   :execute "e" l:newfile
endfunction

" Add ability to switch from .h to .cc quickly
command! Toh :call EditExtension('.h')
command! Toc :call EditExtension('.cpp')

autocmd FileType c,cpp setlocal et ts=2 sw=2 tw=120 
" spell check is smart enough to only check spelling in comments and strings,
" so turn that on for C++ code.
autocmd FileType c,cpp setlocal spell
autocmd FileType c,cpp nmap <buffer> <C-]> :YcmCompleter GoTo<CR>
let g:ycm_min_num_of_chars_for_completion = 0
let g:ycm_confirm_extra_conf = 0

function! CallGradle(...)
 let l:gradle_path = findfile('gradlew', '.;')
 " a:0 == # of args to the command
 if a:0 == 0
    let &makeprg = l:gradle_path . " build"
 else
    let &makeprg = l:gradle_path . " " . join(a:000)
 endif
 :make!
endfunction

command! -narg=* G :call CallGradle(<f-args>)|:copen|:winc J
command! Fix :YcmCompleter FixIt
command! Err :YcmDiags
command! Gt :G buildTestOSXDebug


""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Fileype specific configs for non-programming languages.

" If editing a git commmit file automatically go to the top of the file
" and enter insert mode
au BufNewFile,BufRead *.git/COMMIT_EDITMSG :1
" text files are limited to 120 character lines
autocmd FileType text setlocal textwidth=120

""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin configuration


""""
" LustyExplorer
" Don't print annoying warning if machine doesn't have Ruby support
let g:LustyExplorerSuppressRubyWarning = 1
if has('ruby')
   nmap ,e :LustyFilesystemExplorerFromHere<CR>
   " ,p opens a filesystem explorer from the current working director (p is short
   " for pwd)
   nmap ,p :LustyFilesystemExplorer<CR>
   nmap ,b :LustyBufferExplorer<CR>
endif

" There is apparently a bug in some versions of gvim that cause the cursor to
" be invisible. This strange hack fixes it!
let &guifont=&guifont
