// Dosya: game/menus.odin
package game

import "vendor:raylib"
import "core:fmt"

Update_And_Draw_Main_Menu :: proc(game_state: ^Game_State) {
    title_text := "ODIN SURVIVORS"
    title_width := raylib.MeasureText(raylib.TextFormat("%s", title_text), 80)
    raylib.DrawText(raylib.TextFormat("%s", title_text), 1280/2 - title_width/2, 150, 80, raylib.WHITE)

    mouse_pos := raylib.GetMousePosition()
    
    start_button_rect := raylib.Rectangle{1280/2 - 150, 320, 300, 50}; start_hover := raylib.CheckCollisionPointRec(mouse_pos, start_button_rect); start_button_color := raylib.BLUE; if start_hover { start_button_color = raylib.SKYBLUE }; raylib.DrawRectangleRec(start_button_rect, start_button_color); raylib.DrawText(raylib.TextFormat("Başlat"), i32(start_button_rect.x) + 110, i32(start_button_rect.y) + 10, 30, raylib.WHITE); if start_hover && raylib.IsMouseButtonPressed(.LEFT) { game_state^ = .PLAYING }
    settings_button_rect := raylib.Rectangle{1280/2 - 150, 380, 300, 50}; settings_hover := raylib.CheckCollisionPointRec(mouse_pos, settings_button_rect); settings_button_color := raylib.GRAY; if settings_hover { settings_button_color = raylib.LIGHTGRAY }; raylib.DrawRectangleRec(settings_button_rect, settings_button_color); raylib.DrawText(raylib.TextFormat("Ayarlar"), i32(settings_button_rect.x) + 100, i32(settings_button_rect.y) + 10, 30, raylib.WHITE); if settings_hover && raylib.IsMouseButtonPressed(.LEFT) { game_state^ = .SETTINGS }
    quit_button_rect := raylib.Rectangle{1280/2 - 150, 440, 300, 50}; quit_hover := raylib.CheckCollisionPointRec(mouse_pos, quit_button_rect); quit_button_color := raylib.MAROON; if quit_hover { quit_button_color = raylib.ORANGE }; raylib.DrawRectangleRec(quit_button_rect, quit_button_color); raylib.DrawText(raylib.TextFormat("Çıkış"), i32(quit_button_rect.x) + 120, i32(quit_button_rect.y) + 10, 30, raylib.WHITE); if quit_hover && raylib.IsMouseButtonPressed(.LEFT) { raylib.CloseWindow() }
}

Update_And_Draw_Settings_Menu :: proc(game_state: ^Game_State) {
    title_text := "AYARLAR"
    title_width := raylib.MeasureText(raylib.TextFormat("%s", title_text), 60); raylib.DrawText(raylib.TextFormat("%s", title_text), 1280/2 - title_width/2, 150, 60, raylib.WHITE)
    raylib.DrawText(raylib.TextFormat("Ses Ayarları (Yakında!)"), 1280/2 - 150, 300, 20, raylib.RAYWHITE)
    mouse_pos := raylib.GetMousePosition(); back_button_rect := raylib.Rectangle{1280/2 - 150, 440, 300, 50}; back_hover := raylib.CheckCollisionPointRec(mouse_pos, back_button_rect); back_button_color := raylib.GRAY; if back_hover { back_button_color = raylib.LIGHTGRAY }; raylib.DrawRectangleRec(back_button_rect, back_button_color); raylib.DrawText(raylib.TextFormat("Geri"), i32(back_button_rect.x) + 120, i32(back_button_rect.y) + 10, 30, raylib.WHITE); if back_hover && raylib.IsMouseButtonPressed(.LEFT) { game_state^ = .MAIN_MENU }
}

Draw_Level_Up_Screen :: proc(game_state: ^Game_State, player: ^Player, spinning_weapons: ^[MAX_SPIN_WEAPONS]Spinning_Weapon, possible_upgrades: [dynamic]Upgrade_Option, current_choices: [3]Upgrade_Option, screenWidth: i32, screenHeight: i32) {
    raylib.DrawRectangle(0, 0, screenWidth, screenHeight, raylib.Color{0, 0, 0, 150})
    mouse_pos := raylib.GetMousePosition(); box_width: i32 = 200; box_height: i32 = 250; start_y: i32 = screenHeight/2 - box_height/2; spacing: i32 = 30
    for i in 0..=2 {
        if i >= len(possible_upgrades) { continue }
        box_x := (screenWidth/2) - (box_width*3 + spacing*2)/2 + (box_width + spacing) * i32(i); box_rect := raylib.Rectangle{f32(box_x), f32(start_y), f32(box_width), f32(box_height)}
        is_hovering := raylib.CheckCollisionPointRec(mouse_pos, box_rect); box_color := raylib.LIGHTGRAY
        if is_hovering { box_color = raylib.RAYWHITE }
        raylib.DrawRectangleRec(box_rect, box_color); raylib.DrawRectangleLinesEx(box_rect, 2, raylib.DARKGRAY)
        title_text := raylib.TextFormat("%s", current_choices[i].title); title_width := raylib.MeasureText(title_text, 20); raylib.DrawText(title_text, box_x + (box_width - title_width)/2, start_y + 20, 20, raylib.BLACK)
        desc_text := raylib.TextFormat("%s", current_choices[i].description); raylib.DrawText(desc_text, box_x + 10, start_y + 80, 18, raylib.DARKGRAY)
        if is_hovering && raylib.IsMouseButtonPressed(.LEFT) { Apply_Upgrade(player, spinning_weapons, current_choices[i]); game_state^ = .PLAYING }
    }
}

Draw_Game_Over_Screen :: proc(screenWidth: i32, screenHeight: i32) {
    raylib.DrawRectangle(0, 0, screenWidth, screenHeight, raylib.Color{0, 0, 0, 200})
    text_width := raylib.MeasureText(raylib.TextFormat("GAME OVER"), 80); raylib.DrawText(raylib.TextFormat("GAME OVER"), screenWidth/2 - text_width/2, screenHeight/2 - 60, 80, raylib.RED)
    restart_text_width := raylib.MeasureText(raylib.TextFormat("Press ENTER to Restart"), 20); raylib.DrawText(raylib.TextFormat("Press ENTER to Restart"), screenWidth/2 - restart_text_width/2, screenHeight/2 + 40, 20, raylib.RAYWHITE)
}