command! TestParaMenu source /home/paradigm/.vim/bundle/paramenu/plugin/paramenu.vim | echo ParaMenu(TestOutput()[0], TestOutput()[1])

function! TestOutput()
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
		elseif nr2char(l:line_num) == "m"
			let l:metadata += ["^"]
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
		elseif nr2char(l:line_num) == "m"
			let l:metadata += ["^"]
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
		elseif nr2char(l:line_num) == "m"
			let l:metadata += ["^"]
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
		elseif nr2char(l:line_num) == "m"
			let l:metadata += ["^"]
		else
			let l:metadata += [" "]
		endif
	endfor
	return [l:output, l:metadata]
endfunction


function! ParaMenu(prefixless_output, original_metadata)
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Arguments
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" a:prefixless_output: (original) content to be displayed for the user to
	" pick from, before the prefixes were added.
	"
	" a:original_metadata: (original) metadata related to a:prefixless_output.

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get some information we may need to reset later
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	let l:initial_cmdheight = &cmdheight

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get relevant key lists/dicts
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" Get/Set selection key list
	" These are the keys used to select an item
	if exists("g:ParaMenuSelectionKeys")
		let l:selection_keys = g:ParaMenuSelectionKeys
	else
		"let l:selection_keys = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
		let l:selection_keys = ["a","b","c"]
	endif
	" Get/Set navigation key dictionary
	" These are the keys used to navigate the item list, without selecting
	" anything.
	if exists("g:ParaMenuNavigationKeys")
		let l:navigation_keys = g:ParaMenuNavigationKeys
	else
		let l:navigation_keys = {"\<c-y>": "ScrollUp", "\<c-e>": "ScrollDown", "\<c-f>": "PageDown", "\<c-b>": "PageUp", "\<c-d>": "HalfPageDown", "\<c-u>": "HalfPageUp", "/": "Search", "?": "BackwardSearch", "\<c-r>": "Filter", "\<c-t>": "ClearFilter", "\<c-n>": "SearchNext", "\<c-p>": "SearchPrevious", "\<c-l>": "ClearSearch", "\<c-g>": "LastFirstLine"}
	endif
	" Get/Set navigation key dictionary
	" These keys have special meanings, such as aborting.
	if exists("g:ParaMenuSpecialKeys")
		let l:special_keys = g:ParaMenuNavigationKeys
	else
		let l:special_keys = ["\<esc>","\<space>","\<cr>"]
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Prefix selection keys to output
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" Determine input_length
	let l:number_of_items = len(a:original_metadata)
	" Metadata ^ and quote indicate non-selectable line, like a comment
	" So they don't count for number of selectable items
	for l:item in a:original_metadata
		if l:item == "\"" || l:item == "^"
			let l:number_of_items -= 1
		endif
	endfor
	" input_length is the number of keys the user has to press to select an
	" item.
	" We want the input length to be the smallest value that makes this true:
	" number of selectable items <= number-of-selection-keys^input_length
	let l:original_input_length = 1
	while l:number_of_items > float2nr(pow(len(l:selection_keys),l:original_input_length))
	    let l:original_input_length = l:original_input_length + 1
	endwhile
	" Set up a list of counters for each key entry.
	" This is an easy way to generate which keys go with which item for an
	" aribtrary number of possible item while minimizing the required number
	" of input keys.
	let l:key_counters = []
	for l:key in range(1,l:original_input_length)
		let l:key_counters = add(l:key_counters,0)
	endfor
	" Prepare some variables for generating the with-prefix output and the map
	" of keyseries to each selectable item in the output
	" This is "original" because we may modify it later and need to know
	" how to get back to original
	let l:original_output = ""
	" This is "original" because we may modify it later and need to know
	" how to get back to original
	let l:original_map_keyseries_line = {}
	" This is counter for metadata to match up with items in
	" prefixless_output.  lists are zero-indexed.
	let l:line_number = 0
	" Iterate over each line in the prefixless_output, building the
	" with-prefix output
	for l:line in split(a:prefixless_output,"\n")
		let l:key_series = ""
		" if using non-selectable metadata, no key series for item (since it's
		" non-selectable).
		if a:original_metadata[l:line_number] == "\"" || a:original_metadata[l:line_number] == "^"
			for l:key in l:key_counters
				let key_series = key_series . " "
			endfor
		else
			" selectable item, so build key series
			for l:key in l:key_counters
				let key_series = key_series . selection_keys[key]
			endfor
			" map the key series to line number
			let l:original_map_keyseries_line[key_series]=line_number+1
			" increment key_counters for next loop
			let l:key_counters[len(l:key_counters)-1] = l:key_counters[len(l:key_counters)-1] + 1
			for l:index in range(len(l:key_counters)-1,0,-1)
				if l:key_counters[l:index] == len(selection_keys)
					let l:key_counters[l:index] = 0
					let l:key_counters[l:index-1] = l:key_counters[l:index-1] + 1
				endif
			endfor
		endif
		" add newly prefixed line to output
		if l:original_output != ""
			let l:original_output .= "\n"
		endif
		let l:original_output .= a:original_metadata[l:line_number] . key_series . " " . l:line
		" increment line number counter
		let l:line_number += 1
	endfor

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Main loop
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" prepare some variables for main loop
	" output that will be displayed for user to select from
	let l:output = l:original_output
	" mapping of keyseries to selectable items
	let l:map_keyseries_line = l:original_map_keyseries_line
	" length of key series needed to select an item
	let l:input_length = l:original_input_length
	" first line of output which is displayed on the first line of the window
	let l:first_line=0
	" regex search pattern.  default to ^^ since it doesn't match anything.
	let l:search_pattern = "^^"
	" direction of last search request
	let l:search_direction = ""
	" when non-zero, we've got what we need to finish looping
	let l:done = 0
	" sum total of key series the user has inputted thus far
	let l:key_series = ""
	" prepare window to display output
	" note that we'll want to undo this before exiting
	exe "set cmdheight=".&lines

	" main loop begins here
	while l:done == 0
		" clear screen from last loop iteration
		redraw!
		" output the output to the screen
		" iterate over each line in the range which we want to display
		for l:line in split(l:output,"\n")[l:first_line : l:first_line+&lines-3]
			" highlight if line was searched for
			if l:line[l:input_length+2:] =~ l:search_pattern
				echohl Search
				echon l:line . "\n"
			" highlight if line is comment
			elseif l:line[0] == "\""
				echohl Comment
				echon l:line . "\n"
			" highlight if current buffer
			elseif l:line[0] == "#"
				echohl Statement
				echon l:line . "\n"
			" highlight if alterate buffer
			elseif l:line[0] == "%"
				echohl MatchParen
				echon l:line . "\n"
			" highlight if line is continuation of previous item
			elseif l:line[0] == "^"
				echohl Comment
				echon l:line[0]
				echohl Normal
				echon l:line[1:] ."\n"
			" highlight if warning needed
			elseif l:line[0] == "!"
				echohl WarningMsg
				echon l:line[0:] ."\n"
			else
			" normal highlighting
				echohl Identifier
				echon l:line[0: l:input_length] . " "
				echohl Normal
				echon l:line[l:input_length+2:] . "\n"
			end
		endfor
		" get input from user
		let l:input=nr2char(getchar())
		" if user inputted navigation key, respond accordingly
		if has_key(l:navigation_keys,l:input)
			" Most of these are obvious enough not to need comments
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
				" note we do more with Search farther down
				let l:search_pattern = input("/")
				let l:search_direction = 1
				" doubtful the user would ask to search for everything,
				" probably meant to clear search
				if l:search_pattern == ""
					let l:search_pattern = "^^"
				endif
			elseif l:navigation_keys[l:input] == "BackwardSearch"
				" note we do more with BackwardSearch farther down
				let l:search_pattern = input("?")
				let l:search_direction = -1
			elseif l:navigation_keys[l:input] == "ClearSearch"
				" ^^ doesn't match any pattern, so effectively cleared
				let l:search_pattern = "^^"
			elseif l:navigation_keys[l:input] == "Filter"
				" request regex filter pattern
				let l:filter_pattern = input("Filter: ")
				" prepare variables to hold temporary prefixless output,
				" keyseriesmap, and metadata transition info
				let l:temp_prefixless_output = ""
				let l:temp_map_keyseries_line = {}
				let l:temp_metadata = []
				" generate new prefixless output and map original selectable
				" item line numbers to filtered selectable item line numbers
				" variables to track both old and new line number
				let l:line_number = 0
				let l:new_line_number = 0
				" iterate over each line in original output.  If patches
				" filter pattern, append to new output, new keyseries map and
				" new metadata
				for l:line in split(l:original_output,"\n")
					if l:line[l:original_input_length+2:] =~ l:filter_pattern
						if l:temp_prefixless_output != ""
							let l:temp_prefixless_output .= "\n"
						endif
						let l:temp_prefixless_output .= l:line[l:original_input_length+2:]
						let l:temp_map_keyseries_line[l:new_line_number] = l:line_number+1
						let l:temp_metadata += [a:original_metadata[line_number]]
						let l:new_line_number += 1
					endif
					let l:line_number += 1
				endfor
				" find new number of selectable items
				let l:number_of_items = len(split(l:temp_prefixless_output,"\n"))
				for l:item in range(0,len(split(l:temp_prefixless_output,"\n")))
					" commented items are not selectable
					if l:item == "\"" || l:item == "^"
						let l:number_of_items -= 1
					endif
				endfor
				" find new input length
				let l:input_length = 1
				while l:number_of_items > float2nr(pow(len(l:selection_keys),l:input_length))
					let l:input_length = l:input_length + 1
				endwhile
				" generate key counters for new input length
				let l:key_counters = []
				for l:key in range(1,l:input_length)
					let l:key_counters = add(l:key_counters,0)
				endfor
				" add prefixes to temp_prefixless_output and incorporate temp
				" keyseriesmap to create new filtered output and keyseriesmap
				let l:output = ""
				let l:map_keyseries_line = {}
				" This is counter for metadata to match up with items in
				" prefixless_output.  lists are zero-indexed.
				let l:line_number = 0
				" Iterate over each line in the prefixless_output, building the
				" with-prefix output
				for l:line in split(l:temp_prefixless_output,"\n")
					let l:key_series = ""
					if l:temp_metadata[l:line_number] == "\"" || l:temp_metadata[l:line_number] == "^"
						" if using non-selectable metadata, no key series for item (since it's
						" non-selectable).
						for l:key in l:key_counters
							let key_series = key_series . " "
						endfor
					else
						" selectable item, so build key series
						for l:key in l:key_counters
							let l:key_series = l:key_series . l:selection_keys[key]
						endfor
						" map the key series to line number
						let l:map_keyseries_line[key_series]=l:temp_map_keyseries_line[line_number]
						" increment key_counters for next loop
						let l:key_counters[len(l:key_counters)-1] = l:key_counters[len(l:key_counters)-1] + 1
						for l:index in range(len(l:key_counters)-1,0,-1)
							if l:key_counters[l:index] == len(selection_keys)
								let l:key_counters[l:index] = 0
								let l:key_counters[l:index-1] = l:key_counters[l:index-1] + 1
							endif
						endfor
					endif
					" add newly prefixed line to output
					if l:output != ""
						let l:output .= "\n"
					endif
					let l:output .= l:temp_metadata[l:line_number] . key_series . " " . l:line
					" increment line number counter
					let l:line_number += 1
				endfor
				let l:key_series = ""
			elseif l:navigation_keys[l:input] == "ClearFilter"
				" clear filter -> return to original data
				let l:output = l:original_output
				let l:input_length = l:original_input_length
				let l:map_keyseries_line = l:original_map_keyseries_line
			endif

			" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			"  Search
			" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			" If any of the four possible search things are triggered, we
			" gotta do stuff
			if l:navigation_keys[l:input] == "SearchNext" || l:navigation_keys[l:input] == "SearchPrevious" || l:navigation_keys[l:input] == "Search" || l:navigation_keys[l:input] == "BackwardSearch"
				" Are we searching up in the document or down in the document?
				" 'next' and 'forward' -> down
				" 'next' and 'backward' -> up
				" 'previous' and 'forward' -> up
				" 'previous' and 'backward' -> down
				if ((l:navigation_keys[l:input] == "SearchNext" || l:navigation_keys[l:input] == "Search") && l:search_direction == 1) || ((l:navigation_keys[l:input] == "SearchPrevious" || l:navigation_keys[l:input] == "BackwardSearch" ) && l:search_direction == -1)
					" searching down
					let l:actual_search_direction = 1
					" search through document as though currently top-most
					" line is the top of the document, and it wraps back to
					" that point
					let l:search_contents = split(l:output,"\n")[l:first_line + 1 : ] + split(l:output,"\n")[0 : l:first_line - 1]
				else
					" searching up
					let l:actual_search_direction = -1
					" search through document as though currently top-most
					" line is the top of the document, and it wraps back to
					" that point.  Reverse the order, so we are effectively
					" searching upwards.
					let l:search_contents = reverse(split(l:output,"\n")[l:first_line + 1 : ] + split(l:output,"\n")[0 : l:first_line - 1])
				endif
				" store whether or not search is successful
				let l:search_success = 0
				" store how many lines we've searched, to know how far to move
				" topmost visible line (so search results become topmost
				" visible line)
				let l:searched_lines = 0
				" iterate over all of the lines in the document, with the
				" wrapping stop point and direction determined in
				" l:search_contents
				for l:line in l:search_contents
					" searching new line, increment or decrement searched_lines
					let l:searched_lines += l:actual_search_direction
					" line matched and we haven't found a match yet
					if l:line[l:input_length+2:] =~ l:search_pattern && l:search_success == 0
						" successfully found a match, don't care about the
						" rest of the lines in this search anymore
						let l:search_success = 1
						" offset top line by proper amount
						let l:first_line += l:searched_lines
						" deal with wrapping
						if l:first_line > len(split(l:output,"\n")) - 1 || l:first_line < 0
							let l:first_line -= len(split(l:output,"\n"))*l:actual_search_direction
						endif
					endif
				endfor
				" search failed, let user know
				if l:search_success == 0
					redraw!
					echo "Pattern not found: " . l:search_pattern
					echo "(press any key to continue)"
					call getchar()
				endif
			endif
			" topmost visible line could have moved in an above if/else/end
			" block.  ensure topmost viewable line remains within the actual
			" available lines
			" went to far down
			if l:first_line > len(split(l:output,"\n")) - 1
				" make last line topmost viewable line
				let l:first_line = len(split(l:output,"\n")) - 1
			" went to up down
			elseif l:first_line < 1
				" make first line topmost viewable line
				let first_line = 0
			endif
		endif
		" note: this is the end of the big navigation if/else/end block
		" if input is selection key, append to input to list of inputs thus
		" far in the key series
		if index(l:selection_keys,l:input) != -1
			let l:key_series .= l:input
		end
		" detect conditions to end main loop
		" if enough input keys have been given, we're done with main loop
		if len(l:key_series) == l:input_length
			let l:done = 1
		end
		" if a special key has been given, we're done with main loop
		if index(l:special_keys,l:input) != -1
			let l:done = 2
		end
	endwhile
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Reset values we've tinkered with
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" clean up before exiting
	exe "set cmdheight=".l:initial_cmdheight
	redraw!
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Return value
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" special key given, return coresponding value
	if l:done == 2
		return (index(l:special_keys,l:input)+1)*-1
	endif
	" a valid key series to select an item was given, return the line number
	if l:done == 1 && has_key(l:map_keyseries_line,key_series)
		return l:map_keyseries_line[key_series]
	endif
	" an invalid key series was given, return 0 to indicate this
	return 0
endfunction
