function! ParaMenu()
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
	let output = ""
	for line_num in range(0,&lines-3)
		let output .= "\n" . string(line_num)
	endfor
	set nolazyredraw
	set nomore
	echo output
	call getchar()
	echo output
	call getchar()
endfunction

