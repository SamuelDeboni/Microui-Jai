/*
** Original work: Copyright (c) 2020 rxi
** Modified work: Copyright (c) 2023 SamuelDeboni
**
** Copyright (c) 2020 rxi
**
** Permission is hereby granted, free of charge, to any person obtaining a copy
** of this software and associated documentation files (the "Software"), to
** deal in the Software without restriction, including without limitation the
** rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
** sell copies of the Software, and to permit persons to whom the Software is
** furnished to do so, subject to the following conditions:
**
** The above copyright notice and this permission notice shall be included in
** all copies or substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
** FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
** IN THE SOFTWARE.
**
** - Modified by SamuelDeboni 2023
*/

MU_VERSION :: "2.01";

MU_COMMANDLIST_SIZE    :: 1024;
MU_ROOTLIST_SIZE       :: 32;
MU_CONTAINERSTACK_SIZE :: 32;
MU_CLIPSTACK_SIZE      :: 32;
MU_IDSTACK_SIZE        :: 32;
MU_LAYOUTSTACK_SIZE    :: 16;
MU_CONTAINERPOOL_SIZE  :: 48;
MU_TREENODEPOOL_SIZE   :: 48;
MU_MAX_WIDTHS          :: 16;
MU_MAX_FMT             :: 127;

Stack :: struct($T: Type, $N: int) {
	idx: int;
	items: [N]T;
}

Clip :: enum u32 {
	PART :: 1;
	ALL;
}

Command_Type :: enum u32 {
	JUMP :: 1;
	CLIP;
	RECT;
	TEXT;
	ICON;
	MAX;
}

Color_Type :: enum u32 {
	TEXT :: 0;
	BORDER;
	WINDOWBG;
	TITLEBG;
	TITLETEXT;
	PANELBG;
	BUTTON;
	BUTTONHOVER;
	BUTTONFOCUS;
	BASE;
	BASEHOVER;
	BASEFOCUS;
	SCROLLBASE;
	SCROLLTHUMB;
	MAX;
}

Icon :: enum u32 {
	CLOSE :: 1;
	CHECK;
	COLLAPSED;
	EXPANDED;
	MAX;
}

Res :: enum_flags u32 {
	ACTIVE :: (1 << 0);
	SUBMIT :: (1 << 1);
	CHANGE :: (1 << 2);
}

Opt :: enum_flags u32 {
	ALIGNCENTER  :: (1 << 0);
	ALIGNRIGHT   :: (1 << 1);
	NOINTERACT   :: (1 << 2);
	NOFRAME      :: (1 << 3);
	NORESIZE     :: (1 << 4);
	NOSCROLL     :: (1 << 5);
	NOCLOSE      :: (1 << 6);
	NOTITLE      :: (1 << 7);
	HOLDFOCUS    :: (1 << 8);
	AUTOSIZE     :: (1 << 9);
	POPUP        :: (1 << 10);
	CLOSED       :: (1 << 11);
	EXPANDED     :: (1 << 12);
};

Mouse :: enum_flags u32 {
	LEFT   :: (1 << 0);
	RIGHT  :: (1 << 1);
	MIDDLE :: (1 << 2);
};

Key :: enum_flags u32 {
	SHIFT     :: (1 << 0);
	CTRL      :: (1 << 1);
	ALT       :: (1 << 2);
	BACKSPACE :: (1 << 3);
	RETURN    :: (1 << 4);
};

Id :: u32;
Font :: *void;

Vec2 :: struct {
	x, y: s32;
}

Rect :: struct { 
	x, y, w, h: s32;
}

Color :: struct {
	r, g, b, a: u8;
}

Pool_Item :: struct {
	id: Id;
	last_update: s32;
}

Base_Command :: struct {
	type: s32;
	size: s32;
}

Jump_Command :: struct {
	base: Base_Command;
	dst: *Command;
}

Clip_Command :: struct {
	base: Base_Command;
	rect: Rect;
}

Rect_Command :: struct {
	base:  Base_Command;
	rect:  Rect;
	color: Color;
}

Text_Command :: struct {
	base:  Base_Command;
	font:  Font;
	pos:   Vec2;
	color: Color;
	str:   string;
}

Icon_Command :: struct {
	base:  Base_Command;
	rect:  Rect;
	id:    Icon;
	color: Color;
}

Command :: struct {
	type: Command_Type;

	#place type;
	base: Base_Command;

	#place type;
	jump: Jump_Command;

	#place type;
	clip: Clip_Command;

	#place type;
	rect: Rect_Command;

	#place type;
	text: Text_Command;

	#place type;
	icon: Icon_Command;
}

Layout :: struct {
	body: Rect;
	next: Rect;
	position: Vec2;
	size: Vec2;
	max: Vec2;
	widths: [MU_MAX_WIDTHS]s32;
	items: s32;
	item_index: s32;
	next_row: s32;
	next_type: s32;
	indent: s32;
}

Container :: struct {
	head, tail: *Command;
	rect: Rect;
	body: Rect;
	content_size: Vec2;
	scroll: Vec2;
	zindex: s32;
	open: s32;
}

Style :: struct {
	font:           Font;
	size:           Vec2;
	padding:        s32;
	spacing:        s32;
	indent:         s32;
	title_height:   s32;
	scrollbar_size: s32;
	thumb_size:     s32;
	colors:         [Color_Type.MAX]Color;
}

Context :: struct {
	/* callbacks */
	text_width:  (font: Font, str: string) -> int;
	text_height: (font: Font) -> int;
	draw_frame:  (rect: Rect, colorid: Color_Type) = _draw_frame;

	/* core state */
	style: *Style = *default_style;
	hover: Id;
	focus: Id;
	last_id: Id;
	last_rect: Rect;
	last_zindex: s32;
	updated_focus: s32;
	frame: s32;
	hover_root: *Container;
	next_hover_root: *Container;
	scroll_target: *Container;
	number_edit_buf:   [MU_MAX_FMT]u8;
	number_edit_count: int;
	number_edit: Id;

	/* stacks */
	command_list: Stack(Command, MU_COMMANDLIST_SIZE);
	root_list: Stack(*Container, MU_ROOTLIST_SIZE);
	container_stack: Stack(*Container, MU_CONTAINERSTACK_SIZE);
	clip_stack: Stack(Rect, MU_CLIPSTACK_SIZE);
	id_stack: Stack(Id, MU_IDSTACK_SIZE);
	layout_stack: Stack(Layout, MU_LAYOUTSTACK_SIZE);

	/* retained state pools */
	container_pool: [MU_CONTAINERPOOL_SIZE]Pool_Item;
	containers: [MU_CONTAINERPOOL_SIZE]Container;
	treenode_pool: [MU_TREENODEPOOL_SIZE]Pool_Item;

	/* input state */
	mouse_pos: Vec2;
	last_mouse_pos: Vec2;
	mouse_delta: Vec2;
	scroll_delta: Vec2;
	mouse_down: Mouse;
	mouse_pressed: Mouse;
	key_down: Key;
	key_pressed: Key;
	_input_text: [32]u8;
	input_text: []u8;
}

#add_context mu_ctx: *Context;

//
// Useful macros
//
/*
treenode :: (label: string, opt: Opt = 0) -> Res #expand {
    res := begin_treenode(label, opt);
    `defer if res end_treenode();
    return res;
}
*/
treenode :: (label: string, $code: Code) #expand {
    if begin_treenode(label, 0) {
        #insert code;
        end_treenode();
    }
}

treenode :: (label: string, opt: Opt, $code: Code) #expand {
    if begin_treenode(label, 0) {
        #insert code;
        end_treenode();
    }
}

window :: (title: string, rect: Rect, opt: Opt, $code: Code) #expand {
    if begin_window(title, rect, opt) {
        #insert code;
        end_window();
    }
}

window :: (title: string, rect: Rect, $code: Code) #expand {
    if begin_window(title, rect, 0) {
        #insert code;
        end_window();
    }
}

layout :: (widths: []int, height: int, $code: Code) #expand {
    layout_begin_column();
    layout_row(widths, height);
    #insert code;
    layout_end_column();
}

//slider :: inline (value, lo, hi) => slider(value, lo, hi, 0, MU_SLIDER_FMT, Opt.ALIGNCENTER);
//number :: inline (value, step) => number(value, step, MU_SLIDER_FMT, Opt.ALIGNCENTER);

begin :: () {
    using context.mu_ctx;

	assert(text_width && text_height);
	command_list.idx = 0;
	root_list.idx = 0;
	scroll_target = null;
	hover_root = next_hover_root;
	next_hover_root = null;
	mouse_delta.x = mouse_pos.x - last_mouse_pos.x;
	mouse_delta.y = mouse_pos.y - last_mouse_pos.y;
	frame += 1;
}

end :: () {
    using context.mu_ctx;
	i, n: int;

	/* check stacks */
	assert(container_stack.idx == 0);
	assert(clip_stack.idx      == 0);
	assert(id_stack.idx        == 0);
	assert(layout_stack.idx    == 0);

	/* handle scroll input */
	if scroll_target {
		scroll_target.scroll.x += scroll_delta.x;
		scroll_target.scroll.y += scroll_delta.y;
	}

	/* unset focus if focus id was not touched this frame */
	if !updated_focus focus = 0;
	updated_focus = 0;

	/* bring hover root to front if mouse was pressed */
	if  mouse_pressed && next_hover_root &&
		next_hover_root.zindex < context.mu_ctx.last_zindex &&
		next_hover_root.zindex >= 0
	{
		bring_to_front(next_hover_root);
	}

	/* reset input state */
	key_pressed = 0;
	input_text.count = 0;
	mouse_pressed = 0;
	scroll_delta = .{0, 0};
	last_mouse_pos = mouse_pos;

	/* sort root containers by zindex */
	n = root_list.idx;
	{
		view := array_view(root_list.items, 0, root_list.idx);
		view = quick_sort(view, (a, b) => a.zindex - b.zindex);
	}

	// TODO: Sort by zindex
	//qsort(root_list.items, n, size_of(Container*), compare_zindex);

	/* set root container jump commands */
	i = 0;
	while i < n {
		defer i += 1;

		cnt := root_list.items[i];

		/* if this is the first container then make the first command jump to it.
		** otherwise set the previous container's tail to jump to this one */
		if i == 0 {
			cmd := *command_list.items[0];

			cmd.jump.dst = cnt.*.head + 1;
		} else {
			prev := root_list.items[i - 1];
			prev.tail.jump.dst = cnt.head + 1;
		}

		/* make the last container's tail jump to the end of command list */
		if i == n - 1 {
			cnt.tail.jump.dst = command_list.items.data + command_list.idx;
		}
	}
}

set_focus :: (id: Id) {
    using context.mu_ctx;
	focus = id;
	updated_focus = 1;
}

get_id :: (data: *void, size: int) -> Id {
    using context.mu_ctx;

	idx := id_stack.idx;
	res := ifx idx > 0  id_stack.items[idx - 1]  HASH_INITIAL;
	hash(*res, data, size);
	last_id = res;
	return res;
}

draw_box :: (rect: Rect, color: Color) {
	draw_rect(Rect.{rect.x + 1, rect.y, rect.w - 2, 1}, color);
	draw_rect(Rect.{rect.x + 1, rect.y + rect.h - 1, rect.w - 2, 1}, color);
	draw_rect(Rect.{rect.x, rect.y, 1, rect.h}, color);
	draw_rect(Rect.{rect.x + rect.w - 1, rect.y, 1, rect.h}, color);
}

draw_rect :: (rect: Rect, color: Color) {
    using context.mu_ctx;

	_rect := intersect_rects(rect, get_clip_rect());

	if _rect.w > 0 && _rect.h > 0 {
		cmd := push_command(.RECT);
		cmd.rect.rect = _rect;
		cmd.rect.color = color;
	}
}

get_clip_rect :: () -> Rect {
    using context.mu_ctx;

	assert(clip_stack.idx > 0);
	return clip_stack.items[clip_stack.idx - 1];
}

push_id :: (data: *void, size: int) {
    using context.mu_ctx;

	push(*id_stack, get_id(data, size));
}


pop_id :: () {
    using context.mu_ctx;

	pop(*id_stack);
}


push_clip_rect :: (rect: Rect) {
    using context.mu_ctx;

	last := get_clip_rect();
	push(*clip_stack, intersect_rects(rect, last));
}


pop_clip_rect :: () {
    using context.mu_ctx;

	pop(*context.mu_ctx.clip_stack);
}

check_clip :: (r: Rect) -> Clip {
    using context.mu_ctx;

	cr := get_clip_rect();
	if r.x > cr.x + cr.w || r.x + r.w < cr.x ||
	   r.y > cr.y + cr.h || r.y + r.h < cr.y return Clip.ALL;

	if r.x >= cr.x && r.x + r.w <= cr.x + cr.w &&
	   r.y >= cr.y && r.y + r.h <= cr.y + cr.h return 0;

	return Clip.PART;
}


get_current_container :: () -> *Container{
    using context.mu_ctx;

	assert(container_stack.idx > 0);
	return container_stack.items[ container_stack.idx - 1 ];
}

get_container :: (name: string) -> *Container{
	id := get_id(name.data, name.count);
	return get_container(id, 0);
}

bring_to_front :: (cnt: *Container) {
    using context.mu_ctx;

	last_zindex -= 1;
	cnt.zindex = last_zindex;
}


/*============================================================================
** pool
**============================================================================*/

pool_init :: (items: *Pool_Item, len: int, id: Id) -> int {
    using context.mu_ctx;

	n := -1;
	f := frame;
	for i: 0..len-1 {
		if items[i].last_update < f {
			f = items[i].last_update;
			n = i;
		}
	}

	assert(n > -1);
	items[n].id = id;
	pool_update(items, n);
	return n;
}


pool_get :: (items: *Pool_Item, len: int, id: Id) -> int {
	for i: 0..len-1 if items[i].id == id return i;
	return -1;
}


pool_update :: (items: *Pool_Item, idx: int) {
    using context.mu_ctx;

	items[idx].last_update = frame;
}


/*============================================================================
** input handlers
**============================================================================*/

input_mousemove :: (x: int, y: int) {
    using context.mu_ctx;
	mouse_pos = Vec2.{xx x, xx y};
}

input_mousedown :: (x: int, y: int, btn: Mouse) {
    using context.mu_ctx;

	input_mousemove(x, y);
	mouse_down |= btn;
	mouse_pressed |= btn;
}

input_mouseup :: (x: int, y: int, btn: Mouse) {
	input_mousemove(x, y);
	context.mu_ctx.mouse_down &= ~btn;
}

input_scroll :: (x: int, y: int) {
    using context.mu_ctx;

	scroll_delta.x += xx x;
	scroll_delta.y += xx y;
}

input_keydown :: (key: Key) {
    using context.mu_ctx;

	key_pressed |= key;
	key_down |= key;
}

input_keyup :: (key: Key) {
    using context.mu_ctx;

	key_down &= ~key;
}

input_text :: (text: string) {
    using context.mu_ctx;

	len  := input_text.count;
	size := text.count;
	assert(len + size <= _input_text.count);
	memcpy(_input_text.data + len, text.data, size);
	input_text.data = _input_text.data;
	input_text.count = size + len;
}


/*============================================================================
** commandlist
**============================================================================*/

push_command :: (type: Command_Type) -> *Command {
    using context.mu_ctx;

	cmd := *command_list.items[command_list.idx];
	cmd.* = Command.{
		type = type,
	};
	command_list.idx += 1;
	return cmd;
}


next_command :: (cmd: **Command) -> int {
    using context.mu_ctx;

	if cmd.* {
		cmd.* += 1;
	} else {
		cmd.* = context.mu_ctx.command_list.items.data;
	}

	while cmd.* != context.mu_ctx.command_list.items.data + context.mu_ctx.command_list.idx {
		if cmd.*.type != .JUMP return 1;
		cmd.* = cmd.*.jump.dst;
	}

	return 0;
}

set_clip :: (rect: Rect) {
    using context.mu_ctx;

	cmd := push_command(.CLIP);
	cmd.clip.rect = rect;
}

draw_text :: (font: Font, str: string, pos: Vec2, color: Color)
{
    using context.mu_ctx;

	rect := Rect.{pos.x, pos.y, xx text_width(font, str), xx text_height(font)};
	clipped := check_clip(rect);

	if clipped == .ALL  return;
	if clipped == .PART set_clip(get_clip_rect());

	/* add command */
	len := str.count;
	cmd := push_command(.TEXT);

	cmd.text.str = copy_string(str, temporary_allocator);
	cmd.text.pos = pos;
	cmd.text.color = color;
	cmd.text.font = font;

	/* reset clipping if it was set */
	if clipped set_clip(unclipped_rect);
}


draw_icon :: (id: Icon, rect: Rect, color: Color) {
    using context.mu_ctx;

	/* do clip command if the rect isn't fully contained within the cliprect */
	clipped := check_clip(rect);
	if clipped == .ALL  return;
	if clipped == .PART set_clip(get_clip_rect());

	/* do icon command */
	cmd := push_command(.ICON);
	cmd.icon.id = id;
	cmd.icon.rect = rect;
	cmd.icon.color = color;

	/* reset clipping if it was set */
	if (clipped) { set_clip(unclipped_rect); }
}


//============================================================================
//  layout
//============================================================================

RELATIVE :: 1;
ABSOLUTE :: 2;

layout_begin_column :: () {
	push_layout(layout_next(), .{0, 0});
}

layout_end_column :: () {
    using context.mu_ctx;

	b := get_layout();
	pop(*layout_stack);

	/* inherit position/next_row/max from child layout if they are greater */
	a := get_layout();
	a.position.x = max(a.position.x, b.position.x + b.body.x - a.body.x);
	a.next_row = max(a.next_row, b.next_row + b.body.y - a.body.y);
	a.max.x = max(a.max.x, b.max.x);
	a.max.y = max(a.max.y, b.max.y);
}

layout_row :: (widths: []int, height: int) {
    using context.mu_ctx;

	layout := get_layout();
	if widths.count > 0 {
		assert(widths.count <= MU_MAX_WIDTHS);
		memcpy(layout.widths.data, widths.data, widths.count * size_of(s32));
	}

	layout.items = cast(s32)widths.count;
	layout.position = Vec2.{layout.indent, layout.next_row};
	layout.size.y = xx height;
	layout.item_index = 0;
}

layout_row_items :: (items: s32, height: s32 = 0) {
    using context.mu_ctx;

	layout := get_layout();
	layout.items = items;
	layout.position = Vec2.{layout.indent, layout.next_row};
	layout.size.y = height;
	layout.item_index = 0;
}

layout_width :: (width: int) {
    using context.mu_ctx;

	get_layout().size.x = width;
}


layout_height :: (height: int) {
    using context.mu_ctx;

	get_layout().size.y = height;
}


layout_set_next :: (r: Rect, relative: int) {
    using context.mu_ctx;

	layout := get_layout();
	layout.next = r;
	layout.next_type = ifx relative then RELATIVE else ABSOLUTE;
}

layout_next :: () -> Rect {
    using context.mu_ctx;

	layout := get_layout();
	res: Rect;

	if layout.next_type {
		/* handle rect set by `layout_set_next` */
		type := layout.next_type;
		layout.next_type = 0;
		res = layout.next;

		if type == ABSOLUTE {
			context.mu_ctx.last_rect = res;
			return res;
		}
	} else {
		/* handle next row */
		if layout.item_index == layout.items {
			layout_row_items(layout.items, layout.size.y);
		}

		/* position */
		res.x = layout.position.x;
		res.y = layout.position.y;

		/* size */
		res.w = ifx layout.items > 0 then layout.widths[layout.item_index] else layout.size.x;
		res.h = layout.size.y;
		if res.w == 0  res.w = style.size.x + style.padding * 2;
		if res.h == 0  res.h = style.size.y + style.padding * 2;
		if res.w <  0  res.w += layout.body.w - res.x + 1;
		if res.h <  0  res.h += layout.body.h - res.y + 1;

		layout.item_index += 1;
	}

	/* update position */
	layout.position.x += res.w + style.spacing;
	layout.next_row = max(layout.next_row, res.y + res.h + style.spacing);

	/* apply body offset */
	res.x += layout.body.x;
	res.y += layout.body.y;

	/* update max position */
	layout.max.x = max(layout.max.x, res.x + res.w);
	layout.max.y = max(layout.max.y, res.y + res.h);
	context.mu_ctx.last_rect = res;

	return res;
}


/*============================================================================
** controls
**============================================================================*/



draw_control_frame :: (id: Id, rect: Rect, colorid: Color_Type, opt: Opt)
{
    using context.mu_ctx;

	if opt & Opt.NOFRAME return;

	if context.mu_ctx.focus == id {
		colorid += 2;
	} else if context.mu_ctx.hover == id {
		colorid += 1;
	}

	context.mu_ctx.draw_frame(rect, colorid);
}


draw_control_text :: (str: string, rect: Rect, colorid: Color_Type, opt: Opt)
{
    using context.mu_ctx;

	r := rect;

	font := style.font;
	tw := cast(s32)text_width(font, str);
	push_clip_rect(r);

	pos: Vec2;
	pos.y = r.y + (r.h - cast(s32)text_height(font)) / 2;
	if opt & .ALIGNCENTER {
		pos.x = r.x + (r.w - tw) / 2;
	} else if opt & .ALIGNRIGHT {
		pos.x = r.x + r.w - tw - style.padding;
	} else {
		pos.x = r.x + style.padding;
	}
	draw_text(font, str, pos, style.colors[colorid]);
	pop_clip_rect();
}


mouse_over :: (rect: Rect) -> bool {
    using context.mu_ctx;

	return rect_overlaps_vec2(rect, context.mu_ctx.mouse_pos) &&
		   rect_overlaps_vec2(get_clip_rect(), context.mu_ctx.mouse_pos) &&
		   in_hover_root();
}


update_control :: (id: Id, rect: Rect, opt: Opt) {
    using context.mu_ctx;

	mouseover := mouse_over(rect);
	
	if focus == id               updated_focus = 1;
	if opt & Opt.NOINTERACT      return;
	if mouseover && !mouse_down  hover = id;

	if focus == id {
		if mouse_pressed && !mouseover set_focus(0);
		if !mouse_down && !(opt & .HOLDFOCUS) set_focus(0);
	}

	if hover == id {
		if       mouse_pressed  set_focus(id);
		else if !mouseover      hover = 0;
	}
}


text :: (text: string) {
    using context.mu_ctx;

	start, end: *u8;
	p := text.data;

	width: int = -1;

	font  := context.mu_ctx.style.font;
	color := context.mu_ctx.style.colors[Color_Type.TEXT];

	layout_begin_column();
	layout_row(1, *width, context.mu_ctx.text_height(font));

	while true {
		r := layout_next();
		w: int = 0;

		start, end = p, p;

		while true {
			word := p;

			while (p.* && p.* != #char " " && p.* != #char "\n") p += 1;

			w += context.mu_ctx.text_width(font, string.{word, p - word});

			if w > r.w && end != start break;

			w += context.mu_ctx.text_width(font, string.{p, 1});

			end = p += 1;

			if !(end.* && end.* != #char "\n") break;
		}

		draw_text(font, start, end - start, Vec2.{r.x, r.y}, color);
		p = end + 1;

		if !end break;
	}

	layout_end_column();
}


label :: (text: string) {
	draw_control_text(text, layout_next(), .TEXT, 0);
}

labelf :: (fmt: string, args: .. Any) {
    str := tprint(fmt, ..args);
    label(str);
}

button :: (label: string, icon: Icon = 0, opt: Opt = .ALIGNCENTER) -> Res {
    using context.mu_ctx;

	res: Res;
	id: Id = ifx label get_id(label.data, label.count) else get_id(*icon, size_of(Icon));

	r: Rect = layout_next();
	update_control(id, r, opt);

	/* handle click */
	if mouse_pressed == .LEFT && focus == id {
		res |= .SUBMIT;
	}

	/* draw */

	draw_control_frame(id, r, .BUTTON, opt);
	if label  draw_control_text(label, r, .TEXT, opt);
	if icon   draw_icon(icon, r, style.colors[Color_Type.TEXT]);

	return res;
}


checkbox :: (label: string, state: *bool) -> Res {
    using context.mu_ctx;

	res: Res;
	id: Id = get_id(*state, size_of(state));

	r   := layout_next();
	box := Rect.{r.x, r.y, r.h, r.h};

	update_control(id, r, 0);

	/* handle click */
	if context.mu_ctx.mouse_pressed == .LEFT && context.mu_ctx.focus == id {
		res |= .CHANGE;
		state.* = !state.*;
	}

	/* draw */
	draw_control_frame(id, box, .BASE, 0);
	if state.* {
		draw_icon(.CHECK, box, context.mu_ctx.style.colors[Color_Type.TEXT]);
	}

	r = Rect.{r.x + box.w, r.y, r.w - box.w, r.h};
	draw_control_text(label, r, .TEXT, 0);
	return res;
}


textbox_raw :: (buf: []u8, text_len: *int, id: Id, r: Rect, opt: Opt) -> Res, string {
    using context.mu_ctx;

	res: Res;

	update_control(id, r, opt | .HOLDFOCUS);
	
	if focus == id {
		/* handle text input */
		n: int = min(buf.count - text_len.*, input_text.count);

		if n > 0 {
			memcpy(buf.data + text_len.*, input_text.data, n);
			text_len.* += n;

			res |= .CHANGE;
		}

		/* handle backspace */
		if (key_pressed & .BACKSPACE) && text_len.* > 0 {
			/* skip utf-8 continuation bytes */
			while true {
				text_len.* -= 1;
				if !((buf[text_len.*] & 0xc0) == 0x80 && text_len.* > 0) break;
			}
			
			res |= .CHANGE;
		}

		/* handle return */
		if key_pressed & .RETURN {
			set_focus(0);
			res |= .SUBMIT;
		}
	}

	buf_str: string;
	buf_str.data = buf.data;
	buf_str.count = text_len.*;

	/* draw */
	draw_control_frame(id, r, .BASE, opt);
	if focus == id {
		color := style.colors[Color_Type.TEXT];
		font  := style.font;
		textw := text_width(font, buf_str);
		texth := text_height(font);
		ofx   := r.w - style.padding - textw - 1;
		textx := r.x + min(ofx, style.padding);
		texty := r.y + (r.h - texth) / 2;

		push_clip_rect(r);
		draw_text(font, buf_str, Vec2.{xx textx, xx texty}, color);
		draw_rect(Rect.{xx (textx + textw), xx texty, 1, xx texth}, color);
		pop_clip_rect();
	} else {
		draw_control_text(buf_str, r, Color_Type.TEXT, opt);
	}

	return res, buf_str;
}


number_textbox :: (value: *float64, r: Rect, id: Id) -> Res {
    using context.mu_ctx;

	if mouse_pressed == .LEFT && (key_down & .SHIFT) && hover == id {
		number_edit = id;
        str := tprint("%", value.*);
        for cast([]u8)str {
            if it_index >= MU_MAX_FMT break;
            number_edit_buf[it_index] = it;
        }
        number_edit_count = str.count;
	}

	if number_edit == id {
		res := textbox_raw(number_edit_buf, *number_edit_count, id, r, 0);
		if res & Res.SUBMIT || focus != id {
            str: string;
            str.data = number_edit_buf.data;
            str.count = number_edit_count;
			value.* = string_to_float64(str);
			number_edit = 0;
		} else {
			return 1;
		}
	}

	return 0;
}


textbox :: (buf: []u8, text_len: *int, opt: Opt = .HOLDFOCUS) -> Res, string {
    using context.mu_ctx;

	id := get_id(*buf.data, size_of(*u8));
	r  := layout_next();
	res, str := textbox_raw(buf, text_len, id, r, opt);
	return res, str;
}


slider :: (value: *float64, low: float64, high: float64, step: float64, fmt: FormatFloat = .{}, opt: Opt = 0) -> Res {
    using context.mu_ctx;

    res: Res;

    last := value.*;
    v := last;

	id := get_id(*value, size_of(type_of(value)));
	base := layout_next();

	/* handle text input mode */
	if number_textbox(*v, base, id) return res;

	/* handle normal mode */
	update_control(id, base, opt);

	/* handle input */
	if focus == id && (mouse_down | mouse_pressed) == Mouse.LEFT {
		v = low + (mouse_pos.x - base.x) * (high - low) / base.w;
		if step v = (((v + step / 2) / step)) * step;
	}

	/* clamp and store value, update res */
    v = clamp(v, low, high);
    value.* = v;

	if last != v  res |= Res.CHANGE;

	/* draw base */
	draw_control_frame(id, base, .BASE, opt);
    
	/* draw thumb */
    w := style.thumb_size;
    x := (v - low) * (base.w - w) / (high - low);

    thumb := Rect.{cast(s32)(base.x + x), cast(s32)base.y, cast(s32)w, cast(s32)base.h};
	draw_control_frame(id, thumb, .BUTTON, opt);

	/* draw text  */
    _fmt := fmt; _fmt.value = v;
    str := tprint("%", _fmt);
	draw_control_text(str, base, .TEXT, opt);

	return res;
}

number :: (value: *float32, step: float32, fmt: FormatFloat = .{}, opt: Opt = 0) -> Res {
    push_id(*value, size_of(**float32));
    defer pop_id();

    v64 := cast(float64)value.*;
    res := number(*v64, cast(float64)step, fmt, opt);
    value.* = cast(float32)v64;
    return res;
}

number :: (value: *int, step: int, fmt: FormatFloat = .{}, opt: Opt = 0) -> Res {
    push_id(*value, size_of(**int));
    defer pop_id();

    v64 := cast(float64)value.*;
    res := number(*v64, cast(float64)step, fmt, opt);
    value.* = cast(itn)v64;
    return res;
}

number :: (value: *s32, step: s32, fmt: FormatFloat = .{}, opt: Opt = 0) -> Res {
    push_id(*value, size_of(**s32));
    defer pop_id();

    v64 := cast(float64)value.*;
    res := number(*v64, cast(float64)step, fmt, opt);
    value.* = cast(s32)v64;
    return res;
}

number :: (value: *float64, step: float64, fmt: FormatFloat = .{}, opt: Opt = 0) -> Res {
    using context.mu_ctx;

	res: Res;
	id := get_id(*value, size_of(*float64));

	base := layout_next();
	last := value.*;

	/* handle text input mode */
	if number_textbox(value, base, id) return res;

	/* handle normal mode */
	update_control(id, base, opt);

	/* handle input */
	if focus == id && mouse_down == Mouse.LEFT {
		value.* += mouse_delta.x * step;
	}
	/* set flag if value changed */
	if value.* != last  res |= .CHANGE;

	/* draw base */
	draw_control_frame(id, base, .BASE, opt);
	/* draw text  */
    
    _fmt := fmt;
    _fmt.value = value.*;
    str := tprint("%", _fmt);
	draw_control_text(str, base, .TEXT, opt);

	return res;
}

header :: (label: string, istreenode: bool = false, opt: Opt = 0) -> Res {
    using context.mu_ctx;

	id := get_id(label.data, label.count);
	idx := pool_get(context.mu_ctx.treenode_pool.data, MU_TREENODEPOOL_SIZE, id);
	width: int = -1;
	layout_row(.[width], 0);

	active := (idx >= 0);
	expanded := ifx (opt & Opt.EXPANDED) !active else active;

	r := layout_next();
	update_control(id, r, 0);

	/* handle click */
	active ^= (mouse_pressed == .LEFT && focus == id);

	/* update pool ref */
	if idx >= 0 {
		if active  pool_update(treenode_pool.data, idx);
		else memset(*treenode_pool[idx], 0, size_of(Pool_Item));
	} else if active {
		pool_init(treenode_pool.data, MU_TREENODEPOOL_SIZE, id);
	}

	/* draw */
	if istreenode {
		if hover == id draw_frame(r, .BUTTONHOVER);
	} else {
		draw_control_frame(id, r, Color_Type.BUTTON, 0);
	}
	draw_icon(ifx expanded Icon.EXPANDED else Icon.COLLAPSED, Rect.{r.x, r.y, r.h, r.h}, style.colors[Color_Type.TEXT]);
	r.x += r.h - style.padding;
	r.w -= r.h - style.padding;
	draw_control_text(label, r, .TEXT, 0);
	
	return ifx expanded Res.ACTIVE else 0;
}


header :: (label: string, opt: Opt) -> Res {
	return header(label, 0, opt);
}

begin_treenode :: (label: string, opt: Opt = 0) -> Res {
    using context.mu_ctx;

	res := header(label, true, opt);
	if (res & .ACTIVE) {
		get_layout().indent += style.indent;
		push(*context.mu_ctx.id_stack, context.mu_ctx.last_id);
	}
	return res;
}


end_treenode :: () {
    using context.mu_ctx;

	get_layout().indent -= style.indent;
	pop_id();
}

scrollbar :: (cnt: *Container, b: *Rect, cs: Vec2,
		      $x: string, $y: string, $w: string, $h: string) #expand
{
    using context.mu_ctx;

	/* only add scrollbar if content size is larger than body */
	maxscroll := #insert #run sprint("cs.% - b.%;", y, h);

	if maxscroll > 0 && b.h > 0 {
		base, thumb: Rect;
		id := get_id("!scrollbar".data, 11);

		/* get sizing / positioning */
		base = b.*;
		base.x = #insert #run sprint("b.% + b.%;", x, w);
		base.w = context.mu_ctx.style.scrollbar_size;

		/* handle input */
		update_control(id, base, 0);
		if context.mu_ctx.focus == id && context.mu_ctx.mouse_down == Mouse.LEFT {
			#insert #run sprint("cnt.scroll.% += context.mu_ctx.mouse_delta.% * cs.% / base.%;", y, y, y, h);
		}

		/* clamp scroll to limits */
		#insert #run sprint("cnt.scroll.% = clamp(cnt.scroll.%, 0, maxscroll);", y, y);
		
		/* draw base and thumb */
		context.mu_ctx.draw_frame(base, Color_Type.SCROLLBASE);
		thumb = base;
		#insert #run sprint("thumb.% = max(context.mu_ctx.style.thumb_size, base.% * b.% / cs.%);", h, h, h, y);
		#insert #run sprint("thumb.% += cnt.scroll.% * (base.% - thumb.%) / maxscroll;", y, y, h, h);
		context.mu_ctx.draw_frame(thumb, Color_Type.SCROLLTHUMB);
		
		/* set this as the scroll_target (will get scrolled on mousewheel) */
		/* if the mouse is over it */
		if mouse_over(b.*) context.mu_ctx.scroll_target = cnt;
	} else {
		#insert #run sprint("cnt.scroll.% = 0;", y);
	}
}

begin_window :: (title: string, _rect: Rect, opt: Opt = 0) -> Res {
    using context.mu_ctx;

	rect := _rect;

	body: Rect;
	id := get_id(title.data, title.count);
	cnt := get_container(id, opt);

	if !cnt || !cnt.open  return 0;
	push(*context.mu_ctx.id_stack, id);

	if cnt.rect.w == 0  cnt.rect = rect;
	begin_root_container(cnt);
	rect, body = cnt.rect, cnt.rect;

	/* draw frame */
	if ~opt & .NOFRAME context.mu_ctx.draw_frame(rect, .WINDOWBG);

	/* do title bar */
	if ~opt & .NOTITLE {
		tr := rect;
		tr.h = context.mu_ctx.style.title_height;
		context.mu_ctx.draw_frame(tr, .TITLEBG);

		/* do title text */
		if ~opt & .NOTITLE {
			id := get_id("!title".data, 6);
			update_control(id, tr, opt);
			draw_control_text(title, tr, .TITLETEXT, opt);

			if id == context.mu_ctx.focus && context.mu_ctx.mouse_down == .LEFT {
				cnt.rect.x += context.mu_ctx.mouse_delta.x;
				cnt.rect.y += context.mu_ctx.mouse_delta.y;
			}

			body.y += tr.h;
			body.h -= tr.h;
		}

		/* do `close` button */
		if ~opt & .NOCLOSE {
			id := get_id("!close".data, 6);
			r := Rect.{tr.x + tr.w - tr.h, tr.y, tr.h, tr.h};
			tr.w -= r.w;
			draw_icon(.CLOSE, r, context.mu_ctx.style.colors[Color_Type.TITLETEXT]);
			update_control(id, r, opt);

			if context.mu_ctx.mouse_pressed == .LEFT && id == context.mu_ctx.focus  cnt.open = 0;
		}
	}

	push_container_body(cnt, body, opt);

	/* do `resize` handle */
	if ~opt & .NORESIZE {
		sz := context.mu_ctx.style.title_height;
		id := get_id("!resize".data, 7);
		r := Rect.{rect.x + rect.w - sz, rect.y + rect.h - sz, sz, sz};

		update_control(id, r, opt);
		if id == context.mu_ctx.focus && context.mu_ctx.mouse_down == .LEFT {
			cnt.rect.w = xx max(96, cnt.rect.w + context.mu_ctx.mouse_delta.x);
			cnt.rect.h = xx max(64, cnt.rect.h + context.mu_ctx.mouse_delta.y);
		}
	}

	/* resize to content size */
	if opt & .AUTOSIZE {
		r := get_layout().body;
		cnt.rect.w = cnt.content_size.x + (cnt.rect.w - r.w);
		cnt.rect.h = cnt.content_size.y + (cnt.rect.h - r.h);
	}

	/* close if this is a popup window and elsewhere was clicked */
	if opt & .POPUP && context.mu_ctx.mouse_pressed && context.mu_ctx.hover_root != cnt  cnt.open = 0;

	push_clip_rect(cnt.body);
	return Res.ACTIVE;
}


end_window :: () {
	pop_clip_rect();
	end_root_container();
}

open_popup :: (name: string) {
    using context.mu_ctx;

	cnt: *Container = get_container(name);

	/* set as hover root so popup isn't closed in begin_window_ex()  */
	context.mu_ctx.hover_root = context.mu_ctx.next_hover_root = cnt;

	/* position at mouse cursor, open and bring-to-front */
	cnt.rect = Rect.{context.mu_ctx.mouse_pos.x, context.mu_ctx.mouse_pos.y, 1, 1};
	cnt.open = 1;
	bring_to_front(cnt);
}


begin_popup :: (name: string) -> int {
	opt: Opt = Opt.POPUP | Opt.AUTOSIZE | Opt.NORESIZE | Opt.NOSCROLL | Opt.NOTITLE | Opt.CLOSED;
	return begin_window_ex(name, Rect.{0, 0, 0, 0}, opt);
}

end_popup :: () {
	end_window();
}

begin_panel :: (name: string, opt: Opt = 0) {
    using context.mu_ctx;

	push_id(name.data, name.count);
	cnt := get_container(context.mu_ctx.last_id, opt);
	cnt.rect = layout_next();

	if ~opt & .NOFRAME {
		context.mu_ctx.draw_frame(cnt.rect, .PANELBG);
	}

	push(context.mu_ctx.container_stack, cnt);
	push_container_body(cnt, cnt.rect, opt);
	push_clip_rect(cnt.body);
}


end_panel :: () {
	pop_clip_rect();
	pop_container();
}

#scope_module

push :: (stack: *Stack($T, $N), val: T) {
	stack.items[stack.idx] = val;
	stack.idx += 1;
}

pop :: (stack: *Stack($T, $N)) -> T {
	assert(stack.idx > 0);
	stack.idx -= 1;
	return stack.items[stack.idx];
}

unclipped_rect := Rect.{ 0, 0, 0x1000000, 0x1000000 };

default_style := Style.{
	/* font | size | padding | spacing | indent */
	null, .{ 68, 10 }, 5, 4, 24,
	/* title_height | scrollbar_size | thumb_size */
	24, 12, 8,
	.[
		.{ 230, 230, 230, 255 }, // Color_Type.TEXT
		.{ 25,  25,  25,  255 }, // Color_Type.BORDER
		.{ 50,  50,  50,  255 }, // Color_Type.WINDOWBG
		.{ 25,  25,  25,  255 }, // Color_Type.TITLEBG
		.{ 240, 240, 240, 255 }, // Color_Type.TITLETEXT
		.{ 0,   0,   0,   0   }, // Color_Type.PANELBG
		.{ 75,  75,  75,  255 }, // Color_Type.BUTTON
		.{ 95,  95,  95,  255 }, // Color_Type.BUTTONHOVER
		.{ 115, 115, 115, 255 }, // Color_Type.BUTTONFOCUS
		.{ 30,  30,  30,  255 }, // Color_Type.BASE
		.{ 35,  35,  35,  255 }, // Color_Type.BASEHOVER
		.{ 40,  40,  40,  255 }, // Color_Type.BASEFOCUS
		.{ 43,  43,  43,  255 }, // Color_Type.SCROLLBASE
		.{ 30,  30,  30,  255 }  // Color_Type.SCROLLTHUMB
	],
};

expand_rect :: inline (rect: Rect, n: s32) -> Rect {
	return Rect.{rect.x - n, rect.y - n, rect.w + n * 2, rect.h + n * 2};
}

intersect_rects :: (r1: Rect, r2: Rect) -> Rect{
	x1 := Max(r1.x, r2.x);
	y1 := Max(r1.y, r2.y);
	x2 := Min(r1.x + r1.w, r2.x + r2.w);
	y2 := Min(r1.y + r1.h, r2.y + r2.h);
	if x2 < x1  x2 = x1;
	if y2 < y1  y2 = y1;
	return Rect.{x1, y1, x2 - x1, y2 - y1};
}


rect_overlaps_vec2 :: inline (r: Rect, p: Vec2) -> bool {
	return p.x >= r.x && p.x < r.x + r.w && p.y >= r.y && p.y < r.y + r.h;
}


_draw_frame :: (rect: Rect, colorid: Color_Type) {
    using context.mu_ctx;

	draw_rect(rect, context.mu_ctx.style.colors[colorid]);
	if colorid == .SCROLLBASE  || colorid == .SCROLLTHUMB || colorid == .TITLEBG  return;

	/* draw border */
	if style.colors[Color_Type.BORDER].a {
		draw_box(expand_rect(rect, 1), style.colors[Color_Type.BORDER]);
	}
}

/*
compare_zindex(const void *a, const void *b) -> s32{
	return (*(Container**) a)->zindex - (*(Container**) b)->zindex;
}
*/

push_layout :: (body: Rect, scroll: Vec2) {
	layout: Layout;
	width := 0;

	layout.body = Rect.{body.x - scroll.x, body.y - scroll.y, body.w, body.h};
	layout.max = Vec2.{-0x1000000, -0x1000000};
	push(*context.mu_ctx.layout_stack, layout);
	layout_row(.[width], 0);
}


get_layout :: () -> *Layout{
	return *context.mu_ctx.layout_stack.items[context.mu_ctx.layout_stack.idx - 1];
}


pop_container :: () {
	cnt := get_current_container();
	layout := get_layout();

	cnt.content_size.x = layout.max.x - layout.body.x;
	cnt.content_size.y = layout.max.y - layout.body.y;

	/* pop container, layout and id */
	pop(*context.mu_ctx.container_stack);
	pop(*context.mu_ctx.layout_stack);
	pop_id();
}

get_container :: (id: Id, opt: Opt) -> *Container {
    using context.mu_ctx;

	cnt: *Container;

	idx := pool_get(context.mu_ctx.container_pool.data, MU_CONTAINERPOOL_SIZE, id);
	if idx >= 0 {
		if context.mu_ctx.containers[idx].open || (~opt & Opt.CLOSED) {
			pool_update(context.mu_ctx.container_pool.data, idx);
		}
		return *context.mu_ctx.containers[idx];
	}

	if opt & Opt.CLOSED { return null; }

	/* container not found in pool: init new container */
	idx = pool_init(context.mu_ctx.container_pool.data, MU_CONTAINERPOOL_SIZE, id);
	cnt = *context.mu_ctx.containers[idx];

	cnt.* = .{
		open = 1,
	};

	bring_to_front(cnt);

	return cnt;
}

push_jump :: (dst: *Command) -> *Command {
	cmd := push_command(.JUMP);
	cmd.jump.dst = dst;
	return cmd;
}

in_hover_root :: () -> int {
    using context.mu_ctx;

	i := container_stack.idx;
	while i {
		i -= 1;

		if context.mu_ctx.container_stack.items[i] == context.mu_ctx.hover_root return 1;
		/* only root containers have their `head` field set; stop searching if we've
		** reached the current root container */
		if context.mu_ctx.container_stack.items[i].head break;
	}
	return 0;
}

push_container_body :: (cnt: *Container, body: Rect, opt: Opt) {
    using context.mu_ctx;

	if (~opt & Opt.NOSCROLL) scrollbars(cnt, *body);
	push_layout(expand_rect(body, -context.mu_ctx.style.padding), cnt.scroll);
	cnt.body = body;
}


begin_root_container :: (cnt: *Container) {
    using context.mu_ctx;

	push(*context.mu_ctx.container_stack, cnt);
	/* push container to roots list and push head command */
	push(*context.mu_ctx.root_list, cnt);
	cnt.head = push_jump(null);
	/* set as hover root if the mouse is overlapping this container and it has a
	** higher zindex than the current hover root */
	if rect_overlaps_vec2(cnt.rect, context.mu_ctx.mouse_pos) &&
	   (!context.mu_ctx.next_hover_root || cnt.zindex > context.mu_ctx.next_hover_root.zindex)
	{
		context.mu_ctx.next_hover_root = cnt;
	}

	/* clipping is reset here in case a root-container is made within
	** another root-containers's begin/end block; this prevents the inner
	** root-container being clipped to the outer */
	push(*context.mu_ctx.clip_stack, unclipped_rect);
}


end_root_container :: () {
    using context.mu_ctx;

	/* push tail 'goto' jump command and set head 'skip' command. the final steps
	** on initing these are done in end() */
	cnt := get_current_container();
	cnt.tail = push_jump(null);
	cnt.head.jump.dst = context.mu_ctx.command_list.items.data + context.mu_ctx.command_list.idx;

	/* pop base clip rect and container */
	pop_clip_rect();
	pop_container();
}

scrollbars :: (cnt: *Container, body: *Rect) {
    using context.mu_ctx;

	sz := style.scrollbar_size;
	cs := cnt.content_size;

	cs.x += style.padding * 2;
	cs.y += style.padding * 2;
	push_clip_rect(body.*);
	
	/* resize body to make room for scrollbars */
	if cs.y > cnt.body.h  body.w -= sz;
	if cs.x > cnt.body.w  body.h -= sz;

	/* to create a horizontal or vertical scrollbar almost-identical code is
	** used; only the references to `x|y` `w|h` need to be switched */
	scrollbar(cnt, body, cs, "x", "y", "w", "h");
	scrollbar(cnt, body, cs, "y", "x", "h", "w");
	pop_clip_rect();
}

/* 32bit fnv-1a hash */
HASH_INITIAL :: 2166136261;

hash :: (hash: *Id, data: *void, size: int) {
	p := cast(*u8)data;
	while size {
		hash.* = (hash.* ^ p.*) * 16777619;
		p += 1;
		size -= 1;
	}
}

#import "Basic";
#import "Sort";
