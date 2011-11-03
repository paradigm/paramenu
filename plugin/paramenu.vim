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
		let l:selection_keys = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
		"let l:selection_keys = ["a","b","c"]
	endif
	" get/set navigation key dictionary
	if exists("g:ParaMenuNavigationKeys")
		let l:navigation_keys = g:ParaMenuNavigationKeys
	else
		let l:navigation_keys = {"\<c-y>": "ScrollUp", "\<c-e>": "ScrollDown", "\<c-f>": "PageDown", "\<c-b>": "PageUp", "\<c-d>": "HalfPageDown", "\<c-u>": "HalfPageUp", "/": "Search", "?": "BackwardSearch", "\<c-r>": "Filter", "\<c-n>": "SearchNext", "\<c-p>": "SearchPrevious", "\<c-l>": "ClearSearch", "\<c-g>": "LastFirstLine"}
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
	let l:metadata = []
	for l:line_num in range(97,122)
		let l:output .= "\n" . nr2char(l:line_num)
		if nr2char(l:line_num) == "i"
			let l:metadata += ["\""]
		elseif nr2char(l:line_num) == "a"
			let l:metadata += ["#"]
		elseif nr2char(l:line_num) == "c"
			let l:metadata += ["%"]
		else
			let l:metadata += [" "]
		endif
	endfor
	for l:line_num in range(97,122)
		let l:output .= "\n" . nr2char(l:line_num) . nr2char(l:line_num)
		if nr2char(l:line_num) == "i"
			let l:metadata += ["\""]
		elseif nr2char(l:line_num) == "a"
			let l:metadata += ["#"]
		elseif nr2char(l:line_num) == "c"
			let l:metadata += ["%"]
		else
			let l:metadata += [" "]
		endif
	endfor
	for l:line_num in range(97,122)
		let l:output .= "\n" . nr2char(l:line_num) . nr2char(l:line_num) . nr2char(l:line_num)
		if nr2char(l:line_num) == "i"
			let l:metadata += ["\""]
		elseif nr2char(l:line_num) == "a"
			let l:metadata += ["#"]
		elseif nr2char(l:line_num) == "c"
			let l:metadata += ["%"]
		else
			let l:metadata += [" "]
		endif
	endfor
	for l:line_num in range(97,122)
		let l:output .= "\n" . nr2char(l:line_num) . nr2char(l:line_num) . nr2char(l:line_num) . nr2char(l:line_num)
		if nr2char(l:line_num) == "i"
			let l:metadata += ["\""]
		elseif nr2char(l:line_num) == "a"
			let l:metadata += ["#"]
		elseif nr2char(l:line_num) == "c"
			let l:metadata += ["%"]
		else
			let l:metadata += [" "]
		endif
	endfor
	let l:original_output = l:output
	let l:prefixless_output = l:output
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Prefix selection keys to output
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" determine input_length
	let l:number_of_items = len(l:metadata)
	for l:item in l:metadata
		if l:item == "\""
			let l:number_of_items -= 1
		endif
	endfor
	let l:input_length = 1
	while l:number_of_items > float2nr(pow(len(l:selection_keys),l:input_length))
	    let l:input_length = l:input_length + 1
	endwhile
	" Set up a list of counters for each key entry.
	" This is an easy way to generate which keys go with which item for an
	" aribtrary number of possible item while minimizing the required number
	" of input keys.
	let l:key_counters = []
	for l:key in range(1,l:input_length)
		let l:key_counters = add(l:key_counters,0)
	endfor
	" add key series to each line in output
	let l:output = ""
	let l:line_num = 0
	for l:line in split(l:prefixless_output,"\n")
		let l:key_series = ""
		if l:metadata[l:line_num] == "\""
			for l:key in l:key_counters
				let key_series = key_series . " "
			endfor
		else
			for l:key in l:key_counters
				let key_series = key_series . selection_keys[key]
			endfor
			" increment key_counters for next loop
			let l:key_counters[len(l:key_counters)-1] = l:key_counters[len(l:key_counters)-1] + 1
			for l:index in range(len(l:key_counters)-1,0,-1)
				if l:key_counters[l:index] == len(selection_keys)
					let l:key_counters[l:index] = 0
					let l:key_counters[l:index-1] = l:key_counters[l:index-1] + 1
				endif
			endfor
		endif
		let l:output .= "\n" . l:metadata[l:line_num] . key_series . " " . l:line
		let l:line_num += 1
	endfor
	let l:first_line=0
	let l:input=""
	let l:search_pattern = "^^"
	let l:search_direction = ""
	let l:done = 0
	let l:key_series = ""
	exe "set cmdheight=".&lines
	while l:done == 0
		redraw!
		"set nolazyredraw
		for l:line in split(l:output,"\n")[l:first_line : l:first_line+&lines-3]
			if l:line[0] == "\""
				echohl Comment
				echon l:line . "\n"
			elseif l:line[0] == "#"
				echohl Statement
				echon l:line . "\n"
			elseif l:line[0] == "%"
				echohl MatchParen
				echon l:line . "\n"
			else
				echohl Identifier
				echon l:line[0: l:input_length]
				if l:line[l:input_length+1:] =~ l:search_pattern
					echohl Search
				else
					echohl Normal
				endif
				echon l:line[l:input_length+1:] . "\n"
			end
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
			elseif l:navigation_keys[l:input] == "LastLine"
				let l:first_line = len(split(output,"\n"))-1
			elseif l:navigation_keys[l:input] == "FirstLine"
				let l:first_line = 0
			elseif l:navigation_keys[l:input] == "LastFirstLine"
				if l:first_line == len(split(output,"\n"))-1
					let l:first_line = 0
				else
					let l:first_line = len(split(output,"\n"))-1
				endif
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
					if l:line[l:input_length+1:] =~ l:search_pattern && l:search_success == 0
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
			if l:first_line > len(split(l:output,"\n")) - 1
				let l:first_line = len(split(l:output,"\n")) - 1
			elseif l:first_line < 1
				let first_line = 0
			endif
		endif
		if index(l:selection_keys,l:input) != -1
			let l:key_series .= l:input
		end
		if len(l:key_series) == l:input_length
			let l:done = 1
		end
		if index(l:special_keys,l:input) != -1
			let l:done = 2
		end
	endwhile
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Reset values we've tinkered with
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	exe "set cmdheight=".l:initial_cmdheight
	"exe "set lazyredraw=".l:initial_lazyredraw
	redraw!
endfunction
