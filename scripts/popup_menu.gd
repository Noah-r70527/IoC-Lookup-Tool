extends PopupMenu


func _ready():
	self.menu_changed.connect(print_select)
	
func print_select():
	self.get_item_id(self.id)
