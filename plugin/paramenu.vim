function! ParaMenu()
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get some information we may need to reset later
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	let init_cmdheight = &cmdheight
	let init_lazyredraw = &lazyredraw
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Get relevant key lists/dicts
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	" get/set selection key list
	if exists("g:ParaMenuSelectionKeys")
		let selection_keys = g:ParaMenuSelectionKeys
	else
		"let sel_list = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
		let selection_keys = ["a","b","c"]
	endif
	" get/set navigation key dictionary
	if exists("g:ParaMenuNavigationKeys")
		let navigation_keys = g:ParaMenuNavigationKeys
	else
		let navigation_keys = {"\<c-y>": "ScrollUp", "\<c-e>": "ScrollDown"}
	endif
	" get/set navigation key dictionary
	if exists("g:ParaMenuSpecialKeys")
		let special_keys = g:ParaMenuNavigationKeys
	else
		let special_keys = ["\<esc>","\<space>"]
	endif
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Generate test output
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	let output = ""
	for line_num in range(0,&lines-3)
		let output .= "\n" . string(line_num)
	endfor
	let &cmdheight=len(split(output,"\n"))
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Reset values we've tinkered with
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"while 1
		call getchar()
	"endwhile
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	"  Reset values we've tinkered with
	" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	let &cmdheight=init_cmdheight
	let &lazyredraw=init_lazyredraw
endfunction
