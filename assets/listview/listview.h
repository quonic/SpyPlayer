//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
// StyleAsCode exporter v2.0 - Style data exported as a values array            //
//                                                                              //
// USAGE: On init call: GuiLoadStyleListView();                                   //
//                                                                              //
// more info and bugs-report:  github.com/raysan5/raygui                        //
// feedback and support:       ray[at]raylibtech.com                            //
//                                                                              //
// Copyright (c) 2020-2023 raylib technologies (@raylibtech)                    //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////

#define LISTVIEW_STYLE_PROPS_COUNT  15

// Custom style name: ListView
static const GuiStyleProp listviewStyleProps[LISTVIEW_STYLE_PROPS_COUNT] = {
    { 0, 0, 0x00000000 },    // DEFAULT_BORDER_COLOR_NORMAL 
    { 0, 1, 0x00000000 },    // DEFAULT_BASE_COLOR_NORMAL 
    { 0, 2, 0xffffffff },    // DEFAULT_TEXT_COLOR_NORMAL 
    { 0, 3, 0x00000000 },    // DEFAULT_BORDER_COLOR_FOCUSED 
    { 0, 4, 0x00000000 },    // DEFAULT_BASE_COLOR_FOCUSED 
    { 0, 5, 0x9f9f9fff },    // DEFAULT_TEXT_COLOR_FOCUSED 
    { 0, 6, 0x00000000 },    // DEFAULT_BORDER_COLOR_PRESSED 
    { 0, 7, 0x00000000 },    // DEFAULT_BASE_COLOR_PRESSED 
    { 0, 8, 0x9de9f8ff },    // DEFAULT_TEXT_COLOR_PRESSED 
    { 0, 9, 0x00000000 },    // DEFAULT_BORDER_COLOR_DISABLED 
    { 0, 10, 0x00000000 },    // DEFAULT_BASE_COLOR_DISABLED 
    { 0, 18, 0x00000000 },    // DEFAULT_LINE_COLOR 
    { 0, 19, 0x00000000 },    // DEFAULT_BACKGROUND_COLOR 
    { 12, 14, 0x00000000 },    // LISTVIEW_TEXT_ALIGNMENT 
    { 14, 14, 0x00000000 },    // SCROLLBAR_TEXT_ALIGNMENT 
};

// Style loading function: ListView
static void GuiLoadStyleListView(void)
{
    // Load style properties provided
    // NOTE: Default properties are propagated
    for (int i = 0; i < LISTVIEW_STYLE_PROPS_COUNT; i++)
    {
        GuiSetStyle(listviewStyleProps[i].controlId, listviewStyleProps[i].propertyId, listviewStyleProps[i].propertyValue);
    }

    //-----------------------------------------------------------------

    // TODO: Custom user style setup: Set specific properties here (if required)
    // i.e. Controls specific BORDER_WIDTH, TEXT_PADDING, TEXT_ALIGNMENT
}
