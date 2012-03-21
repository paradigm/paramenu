function! ParaMenu(items)
	" a:items is a list of items the calling function wants the user to choose
	" from.  Each item in the list is a list containing:
	"
	" [what to display, non-selectable content prefix, highlighting color,
	" binary setting whether item should beselectable]

	" store 'more' so we can reset when done
	let l:initial_more = &more
	" set nomore to avoid "Press ENTER to continue" dialogues
	set nomore

	" add indexes to items
	" this allows us to just pass around l:items elements and still retain
	" index so that we can return the proper index value later
	let l:items = []
	let l:index = 0
	for l:item in a:items
		let l:item += [l:index]
		let l:items += [l:item]
		let l:index += 1
	endfor

	" get/set l:selection_keys and l:selection_keys_display
	" l:selection_keys is a list of keys the user can use to select an item
	" irrelevant of the item's content. e.g.:
	"   00 foo
	"   01 bar
	"   10 baz
	" pressing '00' will select 'foo'.  Here, '0' and '1' are the selection
	" keys.
	"
	" l:selection_keys_display determines what characters wil be displayed for
	" each of the l:selection_keys.  This is needed to allow keys which don't
	" echo well.  For example, <bs>.
	if exists("g:ParaMenuSelectionKeys")
		let l:selection_keys = g:ParaMenuSelectionKeys
		if exists("g:ParaMenuSelectionKeysDisplay")
			let l:selection_keys_display = g:ParaMenuSelectionKeysDisplay
		else
			let l:selection_keys_display = l:selection_keys
		endif
	else
		let l:selection_keys = ["0","1","2","3","4","5","6","7","8","9"]
		let l:selection_keys_display = l:selection_keys
		"let l:selection_keys = ["\<c-a>","\<c-s>","\<c-d>","\<c-f>","\<c-g>","\<c-h>","\<c-j>","\<c-k>","\<c-l>"]
		"let l:selection_keys_display = ["A","S","D","F","G","H","J","K","L"]
	endif

	" get/set special keys
	" these are keys which will do something other than select items
	" for example, <esc> to abort
	if exists("g:ParaMenuSpecialKeys")
		let l:special_keys = g:ParaMenuSpecialKeys
	else
		let l:special_keys = ["\<esc>","\<cr>","\<tab>"]
	endif

	" get/set selection direction
	" This determines the order/direction multi-element selection_key series
	" are presented.  e.g.:
	"   00 foo
	"   01 bar
	"   10 baz
	" is l:selection_direction = 0, and
	"   00 foo
	"   10 bar
	"   01 baz
	" is l:selection_direction = 1
	if exists("g:ParaMenuSelectionDirection")
		let l:selection_direction = g:ParaMenuSelectionDirection
	else
		let l:selection_direction = 0
	endif
	
	" get/set whether the filter is case sensitive
	if exists("g:ParaMenuFilterCaseInsensitive")
		let l:filter_case_insensitive = g:ParaMenuFilterCaseInsensitive
	else
		let l:filter_case_insensitive = 1
	endif

	" get/set whether to use regex in filter
	if exists("g:ParaMenuFilterRegex")
		let l:filter_regex = g:ParaMenuFilterRegex
	else
		let l:filter_regex = 0
	endif

	" get/set whether to fuzz input
	" note this currently requires regex
	if exists("g:ParaMenuFilterFuzz")
		let l:filter_fuzz = g:ParaMenuFilterFuzz
		if l:filter_fuzz
			let l:filter_regex = 1
		endif
	else
		let l:filter_fuzz = 0
	endif

	" l:filtered_items is list of items currently in consideration which match
	" the input the user has given thus far
	let l:filtered_items = l:items
	" this is all of the input the user has given, used to filter l:items
	let l:total_input = ""
	" this is the selection section of the user's input e.g.:
	" 00 foo
	" 01 bar
	let l:selection_input = []
	" this is what is displayed for the selection section
	let l:selection_input_display = ""

	" loop until we havea unique item or a special key is pressed
	while 1
		" determine number of selectable items after filtering
		let l:number_of_items = 0
		for l:item in l:filtered_items
			if l:item[3] != 0
				let l:number_of_items += 1
			endif
		endfor
		" if we only have one item, return that item
		if l:number_of_items == 1
			for item in filtered_items
				if item[3] != 0
					let &more = l:initial_more
					redraw
					return l:item[4]
				endif
			endfor
		endif
		" prepare selection key counter (ie, key_counters)
		" this is used to track
		"   00
		"   01
		"   10
		" etc
		let l:select_input_length = 0
		while l:number_of_items > float2nr(pow(len(l:selection_keys),l:select_input_length))
			let l:select_input_length += 1
		endwhile
		let l:key_counters = []
		for l:key in range(1,l:select_input_length)
			let l:key_counters += [0]
		endfor

		" generate output

		" don't want to display more items then there are lines
		" since slower terminals may take a while to draw
		let l:cropped_filtered_items = l:filtered_items[0:&lines-3]
		" clear previous output
		redraw
		" iterate over filtered items, displaying each
		for l:item in l:cropped_filtered_items
			" print selection keys
			if l:item[2] == ""
				echohl Identifier
			else
				execute "echohl ".l:item[2]
			endif
			let l:selection_key_output = ""
			if l:item[3] == 0
				" not selectable so just display spaces instead of selection
				" keys
				for l:index in range(0,len(l:key_counters)-1)
					let l:selection_key_output .= " "
				endfor
			else
				" print selection keys (in proper direction)
				for l:index in range(0,len(l:key_counters)-1)
					if l:selection_direction
						let l:selection_key_output .= l:selection_keys_display[l:key_counters[l:index]]
					else
						let l:selection_key_output = l:selection_keys_display[l:key_counters[l:index]] . l:selection_key_output
					endif
				endfor
				" calculate next selection key counter value
				let l:key_counters[0] += 1
				for l:index in range(0,len(l:key_counters)-1)
					if l:key_counters[l:index] == len(l:selection_keys)
						let l:key_counters[l:index] = 0
						if l:index + 1 < len(l:key_counters)
							let l:key_counters[l:index+1] += 1
						endif
					endif
				endfor
			endif
			echon l:selection_key_output . " "
			" print non-selectable prefix
			echon l:item[1] . " "
			" print actual item text
			if l:item[2] == ""
				echohl Normal
			endif
			echon l:item[0]
			echon "\n"
		endfor
		if len(l:cropped_filtered_items) < len(l:filtered_items)
			echo "..."
		endif

		" print user's input
		echohl Normal
		echo "[".l:selection_input_display."] ".l:total_input

		" get input
		let l:input = getchar()

		" parse input
		if index(l:special_keys,nr2char(l:input)) != -1
			" input is in special keys, so we're returning it immediately
			redraw
			let &more = l:initial_more
			return (index(l:special_keys,nr2char(l:input)) + 1) * -1
		elseif index(l:selection_keys,nr2char(l:input)) != -1
			" input is in selection keys
			" add new key to current list of selection keys and displayed list
			let l:selection_input_display .= l:selection_keys_display[index(l:selection_keys,nr2char(l:input))]
			let l:selection_input += [index(l:selection_keys,nr2char(l:input))]
			" if the length of selection keys thus far is the same as the
			" length needed, check to see if we found a unique item
			if len(l:selection_input) == l:select_input_length
				" calculate index from input
				let l:selected_item = 0
				if l:selection_direction
					let l:index = 0
				else
					let l:index = len(l:selection_input) - 1
				end
				for l:input in l:selection_input
					let l:selected_item += float2nr((l:input)*pow(len(l:selection_keys),(l:index)))
					if l:selection_direction
						let l:index += 1
					else
						let l:index -= 1
					endif
				endfor
				" iterate over items to find one of the appropriate index
				let l:index = -1
				for l:item in l:filtered_items
					if l:item[3] != 0
						let l:index += 1
						if l:index == l:selected_item
							" found it, return value
							redraw
							let &more = l:initial_more
							return l:item[4]
						endif
					endif
				endfor
			endif
			" check for request to clear (part of) previous input
		elseif l:input == 21 " ctrl-u, clear all input
			let l:total_input = ""
		elseif (l:input == 8 || l:input == "\<bs>") && (l:total_input != "" || l:selection_input != []) " backspace or ctrl-h
			if len(l:selection_input) == 0
				let l:total_input = l:total_input[:-2]
			else
				let l:selection_input = l:selection_input[:-2]
				let l:selection_input_display = l:selection_input_display[:-2]
			endif
		else
			" just a normal key, add it to input
			let l:total_input .= nr2char(l:input)
		endif

		" filter based on input
		let l:filtered_items = []
		if l:filter_fuzz
			" build fuzz'd filter
			let l:filter = ""
			for l:index in range(0,len(l:total_input))
				let l:filter .= ".*" . l:total_input[l:index]
			endfor
		else
			let l:filter = l:total_input
		endif

		" iterate over items, adding them to filtered list if they match
		for l:item in l:items
			if l:item[3] == 0 " unselectable
				let l:filtered_items += [l:item]
			else
				if l:filter_case_insensitive
					if l:filter_regex && tolower(l:item[0]) =~ tolower(l:total_input)
						let l:filtered_items += [l:item]
					elseif stridx(tolower(l:item[0]),tolower(l:total_input)) != -1
						let l:filtered_items += [l:item]
					endif
				else
					if l:filter_regex && l:item[0] =~ l:total_input
						let l:filtered_items += [l:item]
					elseif stridx(l:item[0],l:total_input) != -1
						let l:filtered_items += [l:item]
					endif
				endif
			endif
		endfor
	endwhile
endfunction

command! ParaBuffers call ParaBuffers()
function! ParaBuffers()
	" get/set mapping between special key codes from user and functionality
	if exists("g:ParaBuffersSpecialKeyMap")
		let l:special_keys_map = g:ParaBuffersSpecialKeyMap
	else
		let l:special_keys_map = {-1: "Abort", -2: "AlternateBuffer", -3: "UnlistBuffer"}
	endif
	" build list of buffer information
	let l:buffer_numbers = []
	let l:buffers = []
	for l:buffer_number in range(1,bufnr("$"))
		if buflisted(l:buffer_number)
			let l:buffer_numbers += [l:buffer_number]
			let l:buffer = [bufname(l:buffer_number)]
			if l:buffer == [""]
				let l:buffer = ["[No Name]"]
			endif
			if getbufvar(l:buffer_number,"&mod")
				let l:buffer += ["+"]
				let l:buffer += ["WarningMsg"]
			elseif l:buffer_number == bufnr("%")
				let l:buffer += ["%"]
				let l:buffer += ["Statement"]
			elseif l:buffer_number == bufnr("#")
				let l:buffer += ["#"]
				let l:buffer += ["Constant"]
			else
				let l:buffer += [" "]
				let l:buffer += ["Normal"]
			endif
			let l:buffer +=[1]
			let l:buffers += [l:buffer]
		endif
	endfor
	" send buffers to ParaMenu() and get response
	let l:input = ParaMenu(l:buffers)
	" parse input
	if has_key(l:special_keys_map,l:input) && l:special_keys_map[l:input] == "Abort"
		" abort
		return 0
	elseif has_key(l:special_keys_map,l:input) && l:special_keys_map[l:input] == "AlternateBuffer"
		" switch to alt buffer
		b #
	elseif l:input == -3
		" requested to unlist buffer
		" determine which buffer to unlist
		let l:input = ParaMenu(l:buffers)
		if has_key(l:special_keys_map,l:input) && l:special_keys_map[l:input] == "Abort"
			" abort
			return 0
		elseif has_key(l:special_keys_map,l:input) && l:special_keys_map[l:input] == "AlternateBuffer"
			" unlist alternate buffer
			bd! #
		elseif has_key(l:special_keys_map,l:input) && l:special_keys_map[l:input] == "UnlistBuffer"
			" unlist current buffer
			bd!
		else
			" unlist selected buffer
			exec "bd! " . l:buffer_numbers[l:input]
		endif
	else
		" switch to selected buffer
		exec "b " . l:buffer_numbers[l:input]
	endif
	return 0
endfunction

command! ParaTags call ParaTags()
function! ParaTags()
	" get/set mapping between special key codes from user and functionality
	if exists("g:ParaTagsSpecialKeyMap")
		let l:special_keys_map = g:ParaTagsSpecialKeyMap
	else
		let l:special_keys_map = {-1: "Abort", -2: "NextTag", -3: "PreviousTag"}
	endif
	" auto-create tags
	" creates tags based on listed buffrs
	" future version may auto-save temp copy and build tags from that so you
	" don't have to save first
	if exists("g:ParaTagsAutoCreate") && g:ParaTagsAutoCreate == 1
		let l:buffer_filetypes = []
		let l:buffers = []
		" get/set temp directory
		if exists("g:ParaTagsTempDir")
			let l:tagfile = g:ParaTagsTempDir . "/.vim-" . getpid() . "-tags"
		else
			let l:tagfile = "/tmp/.vim-" . getpid() . "-tags"
		endif
		" iterate over buffers, getting name and filetype
		" don't want ful filename path - to long, awkward output
		for l:buffer_number in range(1,bufnr("$"))
			if buflisted(l:buffer_number)
				let l:buffer_filetypes += [ParaTagsCtagsFiletype(getbufvar(l:buffer_number,"&filetype"))]
				let l:new_buffer = bufname(l:buffer_number)
				if l:new_buffer[0] != "/"
					let l:new_buffer = getcwd() ."/". l:new_buffer
				endif
				let l:buffers += [l:new_buffer]
			endif
		endfor
		" generate tags for buffers
		for l:index in range(0,len(l:buffers)-1)
			if l:index == 0
				" create new tag file
				if l:buffer_filetypes[l:index] != ""
					call system("ctags --fields=nk --language-force=".l:buffer_filetypes[l:index]." -f ".l:tagfile." ".l:buffers[l:index])
				else
					call system("ctags --fields=nk -f ".l:tagfile." ".l:buffers[l:index])
				endif
			else
				" append to just-created tag file
				if l:buffer_filetypes[l:index] != ""
					call system("ctags -a --fields=nk --language-force=".l:buffer_filetypes[l:index]." -f ".l:tagfile." ".l:buffers[l:index])
				else
					call system("ctags -a --fields=nk -f ".l:tagfile." ".l:buffers[l:index])
				endif
			endif
		endfor
		" create a autocommand to clean up temp tag file when vim closes
		if ! exists("g:ParaTagsCreated")
			let g:ParaTagsCreated = 1
			exec "set tags+=" . l:tagfile
			exec "au VimLeave * call system(\"rm " . l:tagfile . "\")"
		endif
	endif
	" generate tag list
	let l:tag_list = []
	for l:tag in taglist(".")
		let l:tag_filename = tag["filename"]
		if getbufvar(bufnr(l:tag_filename),"&mod")
			let l:tag_highlight = "WarningMsg"
		elseif l:tag_filename == expand("%:p")
			let l:tag_highlight = "Statement"
		elseif l:tag_filename == expand("#:p")
			let l:tag_highlight = "Constant"
		else
			let l:tag_highlight = "Normal"
		endif
		let l:tag_list += [[tag["name"],l:tag_filename." (".tag["kind"]."):",l:tag_highlight,1]]
	endfor
	" send buffers to ParaMenu() and get response
	let l:input = ParaMenu(l:tag_list)
	" parse input
	if has_key(l:special_keys_map,l:input) && l:special_keys_map[l:input] == "Abort"
		return 0
	elseif has_key(l:special_keys_map,l:input) && l:special_keys_map[l:input] == "NextTag"
		tn
	elseif has_key(l:special_keys_map,l:input) && l:special_keys_map[l:input] == "PreviousTag"
		tp
	elseif l:input >= 0
		exec "tag " . taglist(".")[l:input]["name"]
	endif
endfunction

command! ParaQuickFix call ParaQuickFix()
function! ParaQuickFix()
	" get qf list
	let l:qf_list = []
	for l:qf in getqflist()
		let l:buffer_number = l:qf["bufnr"]
		if getbufvar(l:buffer_number,"&mod")
			let l:notify ="+"
			let l:highlighting ="WarningMsg"
		elseif l:buffer_number == bufnr("%")
			let l:notify ="%"
			let l:highlighting ="Statement"
		elseif l:buffer_number == bufnr("#")
			let l:notify ="#"
			let l:highlighting ="Constant"
		else
			let l:notify = " "
			let l:highlighting ="Normal"
		endif
		let l:qf_list += [[qf["text"],l:notify,l:highlighting,1]]
	endfor
	" send buffers to ParaMenu() and get response
	let l:input = ParaMenu(l:qf_list)
	" parse input
	if l:input >= 0
		exec "b " . getqflist()[l:input]['bufnr']
		call cursor(getqflist()[l:input]['lnum'],getqflist()[l:input]['col'])
	endif
endfunction

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
"  ParaTagsCtagsFiletype()
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
"
" maps vim's filetype to corresponding ctag's filetype

function! ParaTagsCtagsFiletype(vimfiletype)
	if a:vimfiletype == "asm"
		return("asm")
	elseif a:vimfiletype == "aspperl"
		return("asp")
	elseif a:vimfiletype == "aspvbs"
		return("asp")
	elseif a:vimfiletype == "awk"
		return("awk")
	elseif a:vimfiletype == "beta"
		return("beta")
	elseif a:vimfiletype == "c"
		return("c")
	elseif a:vimfiletype == "cpp"
		return("c++")
	elseif a:vimfiletype == "cs"
		return("c#")
	elseif a:vimfiletype == "cobol"
		return("cobol")
	elseif a:vimfiletype == "eiffel"
		return("eiffel")
	elseif a:vimfiletype == "erlang"
		return("erlang")
	elseif a:vimfiletype == "expect"
		return("tcl")
	elseif a:vimfiletype == "fortran"
		return("fortran")
	elseif a:vimfiletype == "html"
		return("html")
	elseif a:vimfiletype == "java"
		return("java")
	elseif a:vimfiletype == "javascript"
		return("javascript")
	elseif a:vimfiletype == "tex" && g:tex_flavor == "tex"
		return("tex")
		" LaTeX is not supported by default, add to ~/.ctags
	elseif a:vimfiletype == "tex" && g:tex_flavor == "latex"
		return("latex")
	elseif a:vimfiletype == "lisp"
		return("lisp")
	elseif a:vimfiletype == "lua"
		return("lua")
	elseif a:vimfiletype == "make"
		return("make")
	elseif a:vimfiletype == "pascal"
		return("pascal")
	elseif a:vimfiletype == "perl"
		return("perl")
	elseif a:vimfiletype == "php"
		return("php")
	elseif a:vimfiletype == "python"
		return("python")
	elseif a:vimfiletype == "rexx"
		return("rexx")
	elseif a:vimfiletype == "ruby"
		return("ruby")
	elseif a:vimfiletype == "scheme"
		return("scheme")
	elseif a:vimfiletype == "sh"
		return("sh")
	elseif a:vimfiletype == "csh"
		return("sh")
	elseif a:vimfiletype == "zsh"
		return("sh")
	elseif a:vimfiletype == "slang"
		return("slang")
	elseif a:vimfiletype == "sml"
		return("sml")
	elseif a:vimfiletype == "sql"
		return("sql")
	elseif a:vimfiletype == "tcl"
		return("tcl")
	elseif a:vimfiletype == "vera"
		return("vera")
	elseif a:vimfiletype == "verilog"
		return("verilog")
	elseif a:vimfiletype == "vim"
		return("vim")
	elseif a:vimfiletype == "yacc"
		return("yacc")
	else
		return("")
	endif
endfunction
