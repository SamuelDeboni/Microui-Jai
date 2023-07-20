//
// This example was copied from modules/Simp/examples/example.jai.
//

Mu :: #import,file "../module.jai";

my_window: Window_Type;
window_width  : s32 = 1280;
window_height : s32 = 720;
ui_icons: Simp.Texture;

main :: () {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();
        Windows.timeBeginPeriod(1);
    }

    my_window = create_window(window_width, window_height, "A Window");
    window_width, window_height = Simp.get_render_dimensions(my_window);
    Simp.set_render_target(my_window);

    icon_data :: #run cast([]u8)read_entire_file("./icons.png");
    ok := Simp.texture_load_from_memory(*ui_icons, icon_data);
    assert(ok);

	init_fonts :: () { // Init fonts
		pixel_height := 18;
		font_data :: #run cast([]u8)read_entire_file("./default_font.ttf");
		my_font = Simp.get_font_at_size(font_data, pixel_height);
		assert(my_font != null);
	}
	init_fonts();

	context.mu_ctx = New(Mu.Context);
	context.mu_ctx.text_width = (font: Mu.Font, str: string) -> int {
		text_width := Simp.prepare_text(cast(*Simp.Dynamic_Font)font, str);
		return text_width;
	};
	context.mu_ctx.text_height = (font) => (cast(*Simp.Dynamic_Font)font).character_height + 2;
	context.mu_ctx.style.font = my_font;
    
    quit := false;
    want_screenshot := false;
    while !quit {
        Input.update_window_events();

        for Input.get_window_resizes() {
            Simp.update_window(it.window);
            
            if it.window == my_window {
                should_reinit := (it.width != window_width) || (it.height != window_height);

                window_width  = it.width;
                window_height = it.height;

                if should_reinit init_fonts();
            }
        }

		mouse_x, mouse_y := get_mouse_pointer_position();
		Mu.input_mousemove(mouse_x, mouse_y);

        for Input.events_this_frame {
            if it.type == .QUIT then quit = true;

            if it.type == {
              case .KEYBOARD;
                if it.key_pressed && it.key_code == .ESCAPE {
                    quit = true;
                }

				if it.key_code ==  {
				  case .MOUSE_BUTTON_RIGHT;
					if it.key_pressed Mu.input_mousedown(mouse_x, mouse_y, .RIGHT);
					else Mu.input_mouseup(mouse_x, mouse_y, .RIGHT);
				  case .MOUSE_BUTTON_LEFT;
					if it.key_pressed Mu.input_mousedown(mouse_x, mouse_y, .LEFT);
					else Mu.input_mouseup(mouse_x, mouse_y, .LEFT);
				  case .MOUSE_BUTTON_MIDDLE;
					if it.key_pressed Mu.input_mousedown(mouse_x, mouse_y, .MIDDLE);
					else Mu.input_mouseup(mouse_x, mouse_y, .MIDDLE);
				  case .SHIFT;
					if it.key_pressed Mu.input_keydown(.SHIFT);
					else              Mu.input_keyup  (.SHIFT);
				  case .CTRL;
					if it.key_pressed Mu.input_keydown(.CTRL);
					else              Mu.input_keyup  (.CTRL);
				  case .ALT;
					if it.key_pressed Mu.input_keydown(.ALT);
					else              Mu.input_keyup  (.ALT);
				  case .BACKSPACE;
					if it.key_pressed Mu.input_keydown(.BACKSPACE);
					else              Mu.input_keyup  (.BACKSPACE);
				  case .ENTER;
					if it.key_pressed Mu.input_keydown(.RETURN);
					else              Mu.input_keyup  (.RETURN);
				}

			  case .TEXT_INPUT;
				buf: [16]u8;
				str: string;
				str.data = buf.data;
				str.count = 16;
                Unicode.character_utf32_to_utf8(it.utf32, *str);
				Mu.input_text(str);

			  case .MOUSE_WHEEL;
				  print("yay %\n", it);
				Mu.input_scroll(0, -it.wheel_delta);
            }
        }

        draw_one_frame();
        
        reset_temporary_storage();
    }
}

draw_one_frame :: () {
	
	// @TODO: The example is very imcomplete, maybe I should port the official demo...
	{
		Mu.begin();
		test_window();
		Mu.end();
	}

    Simp.clear_render_target(.15, .08, .08, 1);

    time := get_time();

	cmd: *Mu.Command;
	while Mu.next_command(*cmd) {
		if cmd.type == {
			case .RECT;
				r := cmd.rect.rect;
				color := cmd.rect.color;
				r.y = cast(s32)window_height - r.y;
				c := Vector4.{
					cast(float)color.r, 
					cast(float)color.g, 
					cast(float)color.b,
					cast(float)color.a,
				} / 255.0;

				Simp.set_shader_for_color();
				Simp.immediate_quad(
					cast(float) r.x,
					cast(float) r.y - r.h,
					cast(float) r.x + r.w,
					cast(float) r.y,
					c,
				);

			case .TEXT;
				font := cast(*Simp.Dynamic_Font)cmd.text.font;
				Simp.set_shader_for_text();
				text_width := Simp.prepare_text(font, cmd.text.str);
				text_x := cast(s64)cmd.text.pos.x;
				text_y := window_height - cast(s64)cmd.text.pos.y;
				text_y -= font.character_height - font.y_offset_for_centering / 2;
				Simp.draw_prepared_text(font, text_x, text_y, Vector4.{1,1,1,1});

			case .CLIP;
				Simp.immediate_flush();
				if cmd.clip.rect.w > window_width && cmd.clip.rect.h > window_height {
					Simp.clear_scissor();
				} else {
					y := window_height - cmd.clip.rect.y;
					Simp.set_scissor(
						cmd.clip.rect.x,
						y - cmd.clip.rect.h,
						cmd.clip.rect.x + cmd.clip.rect.w,
						y,
					);
				}
            case .ICON;
				r := cmd.icon.rect;
				color := cmd.icon.color;
				r.y = cast(s32)window_height - r.y;
				c := Vector4.{
					cast(float)color.r, 
					cast(float)color.g, 
					cast(float)color.b,
                    255,
				} / 255.0;

                Simp.set_shader_for_images(*ui_icons);
				//Simp.set_shader_for_color();

                x_width :: 32.0 / 196.0;
                x_offset := cast(float)cmd.icon.id / 6.0;

                Simp.immediate_quad(
                    Vector2.{cast(float32)r.x,       cast(float32)r.y},
                    Vector2.{cast(float32)r.x + r.w, cast(float32)r.y},
                    Vector2.{cast(float32)r.x + r.w, cast(float32)r.y - r.h},
                    Vector2.{cast(float32)r.x,       cast(float32)r.y - r.h},
                    c,
                    Vector2.{x_offset, 1},
                    Vector2.{x_offset + x_width, 1},
                    Vector2.{x_offset + x_width, 0},
                    Vector2.{x_offset, 0},
                );
				Simp.immediate_flush();
		}

	}

    Simp.swap_buffers(my_window);
}

text_buffer: [256]u8;
text_len: int;
number_box_value: float64;
slider_value: float64;

test_window :: () {
    if Mu.begin_window("Demo Window", Mu.Rect.{40, 40, 300, 450}) {
        defer Mu.end_window();

        win := Mu.get_current_container();
        win.rect.w = max(win.rect.w, 240);
        win.rect.h = max(win.rect.h, 300);

        Mu.layout_row(.[-1], 0);

        Mu.button("Button 1");
        Mu.button("Button 2");
        res, str := Mu.textbox(text_buffer, *text_len);

        if Mu.header("Window Info", true) {
            win := Mu.get_current_container();
            
            Mu.layout(.[85, -1], 0, #code {
                Mu.label("Position:");
                Mu.labelf("%d, %d", win.rect.x, win.rect.y);

                Mu.label("Size:");
                Mu.labelf("%d, %d", win.rect.w, win.rect.h);
            });
        }
        
        Mu.number(*number_box_value, 1);
        Mu.slider(*slider_value, 0, 100, 1);

        Mu.treenode("treenode", #code {
            Mu.label("depth 1");

            Mu.treenode("treenode", #code {
                Mu.label("depth 2");

                Mu.treenode("treenode", #code {
                    Mu.label("depth 3");
                });

                Mu.label("depth 2");
            });
        });
    }
}

my_font: *Simp.Dynamic_Font;

Simp  :: #import "Simp";
Input :: #import "Input";

#import "Window_Creation";

#import "Basic";
#import "Math";
#import "File";
Unicode :: #import "Unicode";

#run {
    #if OS == .WINDOWS {
        WR :: #import "Windows_Resources";
        WR.disable_runtime_console();
    }
}
