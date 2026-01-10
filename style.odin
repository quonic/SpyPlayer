package main


import "vendor:raylib"

loadStyle :: proc() {
	// raylib.GuiLoadStyle("assets/listview.rgs")
	raylib.GuiSetStyle(
		raylib.GuiControl.LISTVIEW,
		i32(raylib.GuiControlProperty.TEXT_ALIGNMENT),
		i32(raylib.GuiTextAlignment.TEXT_ALIGN_LEFT),
	)
	raylib.GuiSetStyle(
		raylib.GuiControl.LISTVIEW,
		i32(raylib.GuiControlProperty.TEXT_COLOR_FOCUSED),
		i32(raylib.ColorToInt(raylib.WHITE)),
	)
	raylib.GuiSetStyle(
		raylib.GuiControl.LISTVIEW,
		i32(raylib.GuiControlProperty.BASE_COLOR_FOCUSED),
		i32(raylib.ColorToInt(raylib.GRAY)),
	)
	raylib.GuiSetStyle(
		raylib.GuiControl.LISTVIEW,
		i32(raylib.GuiControlProperty.BASE_COLOR_PRESSED),
		i32(raylib.ColorToInt(raylib.LIGHTGRAY)),
	)
	raylib.GuiSetStyle(
		raylib.GuiControl.LISTVIEW,
		i32(raylib.GuiControlProperty.BORDER_COLOR_FOCUSED),
		i32(raylib.ColorToInt(raylib.GRAY)),
	)
	raylib.GuiSetStyle(
		raylib.GuiControl.LISTVIEW,
		i32(raylib.GuiControlProperty.BORDER_WIDTH),
		i32(0),
	)
	raylib.GuiSetStyle(
		raylib.GuiControl.LISTVIEW,
		i32(raylib.GuiControlProperty.TEXT_PADDING),
		i32(1),
	)

	raylib.GuiSetStyle(
		raylib.GuiControl.LISTVIEW,
		i32(raylib.GuiListViewProperty.LIST_ITEMS_SPACING),
		i32(1),
	)
	raylib.GuiSetStyle(
		raylib.GuiControl.LISTVIEW,
		i32(raylib.GuiListViewProperty.LIST_ITEMS_HEIGHT),
		i32(15),
	)
}
