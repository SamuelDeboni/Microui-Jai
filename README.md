# MicroUI-Jai

A port from [microui](https://github.com/rxi/microui) to the Jai programming language.

## Example

```rust
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
            
            Mu.column(.[85, -1], 0, #code {
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
```

## Screenshot
![2023-07-20_13-40](https://github.com/SamuelDeboni/Microui-Jai/assets/23066049/4bfc5e3b-6188-4c67-9c49-a8398c2d042a)
