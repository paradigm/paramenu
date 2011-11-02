function! ParaMenu()
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get relevant key lists/dicts
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" get/set selection key list
	if exists("g:ParaMenuSelectionKeys")
		let l:selection_keys = g:ParaMenuSelectionKeys
	else
		"let sel_list = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
		let l:selection_keys = ["a","b","c"]
	endif
	" get/set navigation key dictionary
	if exists("g:ParaMenuNavigationKeys")
		let l:navigation_keys = g:ParaMenuNavigationKeys
	else
		let l:navigation_keys = {"\<c-y>": "ScrollUp", "\<c-e>": "ScrollDown", "\<c-f>": "PageDown", "\<c-b>": "PageUp"}
	endif
	" get/set navigation key dictionary
	if exists("g:ParaMenuSpecialKeys")
		let l:special_keys = g:ParaMenuNavigationKeys
	else
		let l:special_keys = ["\<esc>","\<space>"]
	endif
	let l:output = ""
	for line_num in range(0,99)
		let l:output .= "\n" . string(line_num)
	endfor
	let l:initial_cmdheight=&cmdheight
	let l:first_line=0
	let l:input=""
	exe "set cmdheight=".&lines
	echo "\n"
	while l:input!=l:special_keys[0]
		exe "set cmdheight=".&lines
		set nolazyredraw
		for l:line in split(l:output,"\n")[l:first_line : l:first_line+&lines-3]
			echo l:line
		endfor
		let l:input=nr2char(getchar())
		if has_key(l:navigation_keys,l:input)
			if l:navigation_keys[l:input] == "ScrollDown"
				let l:first_line += 1
			elseif l:navigation_keys[l:input] == "ScrollUp"
				let l:first_line -= 1
			elseif l:navigation_keys[l:input] == "PageDown"
				let l:first_line += &lines-2
			elseif l:navigation_keys[l:input] == "PageUp"
				let l:first_line -= &lines-2
			endif
			if l:first_line > len(split(l:output,"\n"))
				let l:first_line = len(split(l:output,"\n")) - 1
			elseif l:first_line < 1
				let first_line = 0
			endif
		endif
		exe "set cmdheight=".l:initial_cmdheight
	endwhile
	exe "set cmdheight=".l:initial_cmdheight
endfunction
