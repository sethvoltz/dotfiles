if has("mac")
	let g:gist_clip_command = 'pbcopy'
elseif has("unix")
	let g:gist_clip_command = 'xclip -selection clipboard'
endif
let g:gist_detect_filetype = 1
let g:gist_open_browser_after_post = 1
