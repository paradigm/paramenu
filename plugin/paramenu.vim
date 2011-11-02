
function! ParaMenu()
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get some information we may need to reset later
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	let l:initial_cmdheight = &cmdheight
	let l:initial_lazyredraw = &lazyredraw
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
		let l:navigation_keys = {"\<c-y>": "ScrollUp", "\<c-e>": "ScrollDown", "\<c-f>": "PageDown", "\<c-b>": "PageUp", "\<c-d>": "HalfPageDown", "\<c-u>": "HalfPageUp", "/": "Search", "?": "BackwardSearch", "\<c-r>": "Filter", "\<c-n>": "SearchNext", "\<c-p>": "SearchPrevious", "\<c-l>": "ClearSearch"}
	endif
	" get/set navigation key dictionary
	if exists("g:ParaMenuSpecialKeys")
		let l:special_keys = g:ParaMenuNavigationKeys
	else
		let l:special_keys = ["\<esc>","\<space>"]
	endif
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Generate test output
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	let l:output = ""
	for line_num in range(97,122)
		let l:output .= "\n" . nr2char(line_num)
	endfor
	for line_num in range(97,122)
		let l:output .= "\n" . nr2char(line_num) . nr2char(line_num)
	endfor
	for line_num in range(97,122)
		let l:output .= "\n" . nr2char(line_num) . nr2char(line_num) . nr2char(line_num)
	endfor
	for line_num in range(97,122)
		let l:output .= "\n" . nr2char(line_num) . nr2char(line_num) . nr2char(line_num) . nr2char(line_num)
	endfor
	let l:original_output = l:output
	let l:first_line=0
	let l:input=""
	let l:search_pattern = "^^"
	let l:search_direction = ""
	exe "set cmdheight=".&lines
	while l:input!=l:special_keys[0]
		redraw!
		"set nolazyredraw
		for l:line in split(l:output,"\n")[l:first_line : l:first_line+&lines-3]
			if l:line =~ l:search_pattern
			endif
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
			elseif l:navigation_keys[l:input] == "HalfPageDown"
				let l:first_line += float2nr((&lines-2)/2)
			elseif l:navigation_keys[l:input] == "HalfPageUp"
				let l:first_line -= float2nr((&lines-2)/2)
			elseif l:navigation_keys[l:input] == "Search"
				let l:search_pattern = input("/")
				let l:search_direction = 1
			elseif l:navigation_keys[l:input] == "BackwardSearch"
				let l:search_pattern = input("?")
				let l:search_direction = -1
			elseif l:navigation_keys[l:input] == "RegexFilter"
				let l:filter_pattern = input("Filter:")
			endif
			if l:navigation_keys[l:input] == "SearchNext" || l:navigation_keys[l:input] == "SearchPrevious" || l:navigation_keys[l:input] == "Search" || l:navigation_keys[l:input] == "BackwardSearch"
				if ((l:navigation_keys[l:input] == "SearchNext" || l:navigation_keys[l:input] == "Search") && l:search_direction == 1) || ((l:navigation_keys[l:input] == "SearchPrevious" || l:navigation_keys[l:input] == "BackwardSearch" ) && l:search_direction == -1)
					let l:actual_search_direction = 1
					let l:search_contents = split(l:output,"\n")[l:first_line + 1 : ] + split(l:output,"\n")[0 : l:first_line - 1]
				else
					let l:actual_search_direction = -1
					let l:search_contents = reverse(split(l:output,"\n")[l:first_line + 1 : ] + split(l:output,"\n")[0 : l:first_line - 1])
				endif
				let l:search_success = 0
				let l:searched_lines = 0
				for l:line in l:search_contents
					let l:searched_lines += l:actual_search_direction
					if l:line =~ l:search_pattern && l:search_success == 0
						let l:search_success = 1
						let l:first_line += l:searched_lines
						if l:first_line > len(split(l:output,"\n")) - 1 || l:first_line < 0
							let l:first_line -= len(split(l:output,"\n"))*l:actual_search_direction
						endif
					endif
				endfor
				if l:search_success == 0
					redraw!
					echo "Pattern not found: " . l:search_pattern
					echo "(press any key to continue)"
					call getchar()
				endif
			endif
			if l:first_line > len(split(l:output,"\n"))
				let l:first_line = len(split(l:output,"\n")) - 1
			elseif l:first_line < 1
				let first_line = 0
			endif
		endif
	endwhile
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Reset values we've tinkered with
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	exe "set cmdheight=".l:initial_cmdheight
	"exe "set lazyredraw=".l:initial_lazyredraw
	redraw!
endfunction
