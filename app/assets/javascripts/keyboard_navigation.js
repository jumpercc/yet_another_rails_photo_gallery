document.onkeydown = NavigateThrough;

function NavigateThrough (event) {
	if (!document.getElementById) return;

	if (window.event) event = window.event;

	if ( event.ctrlKey || event.altKey ){
		var link = null;
		var href = null;
		switch (event.keyCode ? event.keyCode : event.which ? event.which : null){
			case 0x25:
                my_navigation.go_to_prev_page();
				break;
			case 0x27:
                my_navigation.go_to_next_page();
				break;
			case 0x26:
                my_navigation.go_to_upper_page();
				break;
		}
	}
}
