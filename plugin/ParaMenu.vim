" ==============================================================================
"  ParaMenu
" ==============================================================================
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
	" get cmdheight
	let l:initial_cmdheight = &cmdheight
	" get window heights
	let l:window_heights = []
	windo :let l:window_heights += [winheight(winnr())]

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get relevant key lists/dicts
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" Get/Set selection key list
	" These are the keys used to select an item
	if exists("g:ParaMenuSelectionKeys")
		let l:selection_keys = g:ParaMenuSelectionKeys
	else
		let l:selection_keys = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
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
		let l:special_keys = ["\<esc>","\<space>","\<cr>","\<tab>","*"]
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
				" highlight if modified buffer
			elseif l:line[0] == "+"
				echohl WarningMsg
				echon l:line[0:] ."\n"
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
				echohl Normal
				let l:search_pattern = input("/")
				let l:search_direction = 1
				" doubtful the user would ask to search for everything,
				" probably meant to clear search
				if l:search_pattern == ""
					let l:search_pattern = "^^"
				endif
			elseif l:navigation_keys[l:input] == "BackwardSearch"
				" note we do more with BackwardSearch farther down
				echohl Normal
				let l:search_pattern = input("?")
				let l:search_direction = -1
			elseif l:navigation_keys[l:input] == "ClearSearch"
				" ^^ doesn't match any pattern, so effectively cleared
				let l:search_pattern = "^^"
			elseif l:navigation_keys[l:input] == "Filter"
				" request regex filter pattern
				echohl Normal
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
	" reset cmdheight
	exe "set cmdheight=".l:initial_cmdheight
	" reset window heights
	windo :exec ":resize " . l:window_heights[winnr()-1]
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

" =====================================================================
"  ParaBuffers
" =====================================================================
command! ParaBuffers call ParaBuffers()
function! ParaBuffers()
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get/set specialkey-to-parabuffer-command mapping
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" Need to know what to do with ParaMenu's special key results
	if exists("g:ParaBuffersSpecialKeyMap")
		let l:special_keys_map = g:ParaBuffersSpecialKeyMap
	else
		let l:special_keys_map = {-1: "Abort", -2: "UnlistBuffer", -3: "AlternateBuffer", -4: "ForceUnlistBuffer"}
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Gather current buffer information
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" get number of listed buffers
	let l:number_of_listed_buffers = 0
	for l:buffer_number in range(1,bufnr("$"))
		if buflisted(l:buffer_number) " listed buffer, so want to consider it
			let l:number_of_listed_buffers = l:number_of_listed_buffers + 1
		endif
	endfor
	" ensure at least one listed buffer is found
	if l:number_of_listed_buffers == 0
		" no listed buffers, abort
		echohl WarningMsg
		echo "No listed buffers."
		return 1
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Generate output and metadata
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" output to show in ParaMenu
	let l:output = ""
	" metadata corresponding with lines in l:output
	let l:metadata = []
	" current output line number
	let l:line_number = 0
	" map output line number to buffer numbers
	let l:map_output_buffer_number = {}
	" loop through all the listed buffers to generate output metadata
	for l:buffer_number in range(1,bufnr("$"))
		if buflisted(l:buffer_number) " listed buffer, so want to consider it
			" get buffer name
			let l:buffer_name = bufname(l:buffer_number)
			if l:buffer_name == ""
				let l:buffer_name = "[No Name]"
			endif
			" add buffer name to output
			if l:output != ""
				let l:output .= "\n"
			endif
			let l:output .= buffer_name
			" incrememnt line number
			let l:line_number += 1
			" map output line number to buffer number
			let l:map_output_buffer_number[l:line_number] = l:buffer_number
			" find buffer_attribute information
			if getbufvar(l:buffer_number,"&mod") " modified buffer
				let l:metadata += ["+"]
			elseif bufnr("%") == l:buffer_number " current buffer
				let l:metadata += ["%"]
			elseif bufnr("#") == l:buffer_number " alternate buffer
				let l:metadata += ["#"]
			else
				let l:metadata += [" "] " normal buffer
			endif
		endif
	endfor

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Show output and get input
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	let l:input = ParaMenu(l:output,l:metadata)

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Deal with special keys
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" no request to unlist a buffer (yet), assume any buffer-specific request
	" is a request to go to that buffer
	let l:unlist = 0
	if has_key(l:special_keys_map,l:input)
		" requested to abort
		if l:special_keys_map[l:input] == "Abort"
			return 0
		elseif l:special_keys_map[l:input] == "AlternateBuffer"
			" requested to switch to alternate buffer
			if bufnr("#") != -1
				" switch to alternate buffer
				b #
				return 0
			else
				" no listed alternate buffer
				echohl WarningMsg
				echo "E23: No alternate file"
				return 1
			end
		elseif l:special_keys_map[l:input] == "UnlistBuffer"
			" requested to unlist the next inputted buffer
			let l:unlist = 1
			" request for which buffer to unlist
			let l:input = ParaMenu(l:output,l:metadata)
		elseif l:special_keys_map[l:input] == "ForceUnlistBuffer"
			" requested to force unlist the next inputted buffer
			let l:unlist = 2
			" request for which buffer to force unlist
			let l:input = ParaMenu(l:output,l:metadata)
		endif
	endif
	" a request to unlist buffer or force unlist buffer gets new input and
	" will require checking for dealing with special keys again
	if has_key(l:special_keys_map,l:input)
		" requested to abort
		if l:special_keys_map[l:input] == "Abort"
			return 0
		elseif l:special_keys_map[l:input] == "AlternateBuffer"
			" requested alternate buffer - maybe wants to unlist it?
			if bufnr("#") != -1
				if l:unlist == 1
					bd #
					return 0
					" or force unlist it
				elseif l:unlist == 2
					bd! #
					return 0
				endif
			else
				" no listed alternate buffer
				echohl WarningMsg
				echo "E23: No alternate file"
				return 1
			end
		elseif l:special_keys_map[l:input] == "UnlistBuffer" || l:special_keys_map[l:input] == "ForceUnlistBuffer"
			" requesting to unlist twice means want to unlist current buffer
			if l:unlist == 1
				if &hidden == 0 && getbufvar("%","&mod")
					" cannot unlist modified buffer without 'hidden'
					" warn user and abort
					echohl WarningMsg
					echo "Cannot unlist current, modified buffer with 'hidden' set to off.  See :h 'hidden'"
					return 1
				else
					bd " unlist current buffer
					return 0
				endif
			elseif l:unlist == 2
				bd!
				return 0
			end
		endif
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Deal with selected buffer
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	if has_key(l:map_output_buffer_number,l:input)
		if l:unlist == 0
			if &hidden == 0 && getbufvar("%","&mod") && l:map_output_buffer_number[l:input] != bufnr("%")
				" cannot switch away from modified buffer without 'hidden'
				" warn user and abort
				echohl WarningMsg
				echo "Cannot switch away from current, modified buffer with 'hidden' set to off.  See :h 'hidden'"
				return 1
			else
				" switch to buffer
				exe "b " l:map_output_buffer_number[l:input]
				return 0
			endif
		elseif l:unlist == 1
			if &hidden == 0 && getbufvar("%","&mod") && l:map_output_buffer_number[l:input] == bufnr("%")
				" cannot unlist modified buffer without 'hidden'
				" warn user and abort
				echohl WarningMsg
				echo "Cannot unlist current, modified buffer with 'hidden' set to off.  See :h 'hidden'"
				return 1
			else
				" unlist buffer
				exe "bd " l:map_output_buffer_number[l:input]
				return 0
			end
		elseif l:unlist == 2
			" force unlist buffer
			exe "bd! " l:map_output_buffer_number[l:input]
			return 0
		endif
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" Uninterpretable input
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" inform user malformed input
	echohl WarningMsg
	echo "Did not request listed buffer, aborting"
	return 1
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

" ==============================================================================
"  ParaTags
" ==============================================================================
command! ParaTags call ParaTags()
function! ParaTags()
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get/set specialkey-to-paratags-command mapping
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" Need to know what to do with ParaMenu's special key results
	if exists("g:ParaBuffersTagsKeyMap")
		let l:special_keys_map = g:ParaTagsSpecialKeyMap
	else
		let l:special_keys_map = {-1: "Abort", -2: "TagUnderCursor", -5: "TagUnderCursor"}
	endif
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Initial Setup
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" get current word under cursor
	let l:current_word = expand("<cword>")
	" are we only considering buffer or all listed buffers for tags
	if exists("g:ParaTagsCurrentBufferOnly")
		let l:current_buffer_only = g:ParaTagsCurrentBufferOnly
	else
		let l:current_buffer_only = 0
	endif
	" ctags won't read contents from stdin, has to read from file location for
	" temporary file
	if exists("g:ParaTagsTempDir")
		let l:temporary_file_location = g:ParaTagsTempDir
	else
		if has("unix")
			let l:temporary_file_location = "/tmp"
		elseif has("win32")
			let l:temporary_file_location = "%TEMP%"
		end
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get ctags
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" will hold the list of tags as ctags gives them too us
	let l:tag_list = ""
	" track whether or not we ran into an unloaded tag
	let l:unloaded_tag = 0
	for l:buffer_number in range(1,bufnr("$"))
		" if we hit a listed buffer and allow any buffers, or if we hit the
		" current buffer and only can do the current buffer, get ctags for
		" that buffer
		if (buflisted(l:buffer_number) && l:current_buffer_only == 0) || (l:current_buffer_only == 1 && l:buffer_number == bufnr("%"))
			" if the user hasn't loaded the buffer yet, this won't work
			if bufloaded(l:buffer_number)
				" determine path for temporary file
				let l:temporary_file = l:temporary_file_location . "/.paratags-" . getpid()
				" ensure there isn't already a file there, could be a problem
				if filereadable(l:temporary_file)
					redraw
					echo "Looks like temp file " . l:temporary_file . " already exists; Remove and try again"
					return 1
				endif
				" ensure tempfile isn't loaded in another buffer - can happen when canceling with ctrl-c
				exe "silent! bw! " . l:temporary_file
				" write temporary file to disk
				call writefile(getbufline(l:buffer_number,1,"$"),l:temporary_file)
				" ensure tempfile was writen 
				if !filereadable(l:temporary_file)
					echohl WarningMsg
					echo "Can not create \"" . l:temporary_file . "\", aborting."
					return 1
				endif
				exe "silent! bw! " . l:temporary_file
				" ensure tempfile isn't loaded anymore
				exe "silent! bw! " . l:temporary_file
				" get ctag's name for the given filetype
				let l:ctags_filetype = ParaTagsCtagsFiletype(getbufvar(l:buffer_number,"&filetype"))
				" get ctags for buffer
				if l:ctags_filetype == ""
					" if no ctags_filetype, go by filename
					let l:tag_list = tag_list . substitute(system("ctags -f - --fields=nk " . l:temporary_file), l:temporary_file, l:buffer_number,"g")
				else
					" otherwise, force by ctagsfiletype
					let l:tag_list = tag_list . substitute(system("ctags -f - --fields=nk --language-force=\"" . l:ctags_filetype . "\" " . l:temporary_file), l:temporary_file, l:buffer_number,"g")
				endif
				" remove temporary file
				call delete(l:temporary_file)
			else " warn user about unloaded buffer
				let l:unloaded_tag = 1
				echohl WarningMsg
				echo bufname(l:buffer_number) "has not been loaded yet; can't get tags yet."
			endif
		endif
	endfor
	" Give user chance to read about unloaded buffers
	if l:unloaded_tag == 1
		echohl Normal
		echo "(Press any key to continue)"
		call getchar()
	endif
	" Warn user no tags found and abort
	if l:tag_list == ""
		echohl WarningMsg
		echo "No tags found, aborting"
		return 1
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Convert ctags to output/metadata
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" this is the information that will be outputted to the user, displaying
	" information on the tags
	let l:output = ""
	" this is the metadata associated with each line
	let l:metadata = []
	" current output tag number
	let l:tag_number = 0
	" this is the mapping of the number of the tag (ie, what ParaMenu() will
	" return) and the buffer/line that we will want to jump too
	let l:tag_buffer_map = {}
	let l:tag_line_map = {}
	" this is a map of the number of the tag's text to the number of the tag
	" it is useful for finding the tag under the cursor
	let l:text_tag_map = {}
	" iterate over all of the lines in the tag, parsing each for the data we
	" want and using it to create the output, metadata, and tag map
	for l:line in split(l:tag_list,"\n")
		" break the line up into the five fields it gives
		" fields are seperated by tabs
		let l:field_seperator = range(0,5)
		for l:field_number in range(1,5)
			let l:field_seperator[l:field_number] = stridx(l:line,"\t",l:field_seperator[l:field_number-1]+1)
		endfor
		let l:tag_name = strpart(l:line,0,l:field_seperator[1])
		let l:buffer_number = strpart(l:line,l:field_seperator[1]+1, l:field_seperator[2] - l:field_seperator[1]-1)
		let l:regex = strpart(l:line,l:field_seperator[2]+1, l:field_seperator[3] - l:field_seperator[2]-1)
		let l:ctag_kind = strpart(l:line,l:field_seperator[3]+1, l:field_seperator[4] - l:field_seperator[3]-1)
		let l:line_number = strpart(l:line,l:field_seperator[4]+6)
		" append fields to output
		if l:output != ""
			let l:output .= "\n"
		endif
		let l:output .= bufname(str2nr(l:buffer_number)) . " (" . l:ctag_kind . "):\t" . l:tag_name
		" incrememnt tag number
		let l:tag_number += 1
		" map tag to buffer and line
		let l:tag_buffer_map[l:tag_number] = l:buffer_number
		let l:tag_line_map[l:tag_number] = l:line_number
		let l:text_tag_map[l:tag_name] = l:tag_number
		" get metadata
		if getbufvar(l:buffer_number,"&mod") " modified buffer
			let l:metadata += ["+"]
		elseif bufnr("%") == l:buffer_number " current buffer
			let l:metadata += ["%"]
		elseif bufnr("#") == l:buffer_number " alternate buffer
			let l:metadata += ["#"]
		else
			let l:metadata += [" "] " normal buffer
		endif
	endfor

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Show output and get input
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	let l:input = ParaMenu(l:output,l:metadata)

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Deal with special keys
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	if has_key(l:special_keys_map,l:input)
		" requested to abort
		if l:special_keys_map[l:input] == "Abort"
			return 0
		elseif l:special_keys_map[l:input] == "TagUnderCursor"
			" wants to jump to tag under cursor
			if has_key(l:text_tag_map,l:current_word)
				" jump to buffer
				exe "b " . l:tag_buffer_map[l:text_tag_map[l:current_word]]
				" jump to line
				call cursor(l:tag_line_map[l:text_tag_map[l:current_word]],0)
				return 0
			else
				echohl WarningMsg
				echo "Cannot find \"" . l:current_word . "\" in the tag list"
				return 1
			endif
		endif
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Deal with selected tag
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	if has_key(l:tag_buffer_map,l:input)
		" jump to buffer
		exe "b " . l:tag_buffer_map[l:input]
		" jump to line
		call cursor(l:tag_line_map[l:input],0)
		return 0
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" Uninterpretable input
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" inform user malformed input
	echohl WarningMsg
	echo "Did not request a tag, aborting"
	return 1
endfunction

command! ParaQuickFix call ParaQuickFix()
function! ParaQuickFix()
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get/set specialkey-to-paraquickfix-command mapping
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	if exists("g:ParaQuickFixSpecialKeyMap")
		let l:special_keys_map = g:ParaQuickFixSpecialKeyMap
	else
		let l:special_keys_map = {-1: "Abort"}
	endif
	" information on the tags
	let l:output = ""
	" this is the metadata associated with each line
	let l:metadata = []
	" track which quickfix number we're on, to map below
	let l:quickfix_number = 0
	" this is the mapping of the number of the quickfix item (ie, what
	" ParaMenu() will return) and the buffer, line, and column that we will
	" want to jump too
	let l:quickfix_buffer_map = {}
	let l:quickfix_line_map = {}
	let l:quickfix_column_map = {}
	" iterate over all of the items in the quickfixlist
	for l:line in getqflist()
		" create output for line
		if l:output != ""
			let l:output .= "\n"
		endif
		let l:output .= bufname(l:line["bufnr"]) . ":\t" . substitute(l:line["text"],"^[\t ]*","","")
		" get metadata for line
		if getbufvar(l:line["bufnr"],"&mod") " modified buffer
			let l:metadata += ["+"]
		elseif bufnr("%") == l:line["bufnr"] " current buffer
			let l:metadata += ["%"]
		elseif bufnr("#") == l:line["bufnr"] " alternate buffer
			let l:metadata += ["#"]
		else
			let l:metadata += [" "] " normal buffer
		endif
		" incrememnt quickfix_number
		let l:quickfix_number+=1
		" map quickfix item to buffer, line and column
		let l:quickfix_buffer_map[l:quickfix_number] = l:line['bufnr']
		let l:quickfix_line_map[l:quickfix_number] = l:line['lnum']
		let l:quickfix_column_map[l:quickfix_number] = l:line['col']
	endfor

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Show output and get input
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	let l:input = ParaMenu(l:output,l:metadata)

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Deal with special keys
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	if has_key(l:special_keys_map,l:input)
		" requested to abort
		if l:special_keys_map[l:input] == "Abort"
			return 0
		endif
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Deal with selected quickfix item
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	if has_key(l:quickfix_buffer_map,l:input)
		" jump to buffer
		exe "b " . l:quickfix_buffer_map[l:input]
		" jump to line
		call cursor(l:quickfix_line_map[l:input],l:quickfix_column_map[l:input])
		return 0
	endif

	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" Uninterpretable input
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" inform user malformed input
	echohl WarningMsg
	echo "Did not request a quickfix item, aborting"
	return 1
endfunction
