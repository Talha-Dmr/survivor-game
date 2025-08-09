package game
import "vendor:raylib"
import "core:fmt"
import "core:strings"

Update_And_Draw_Main_Menu :: proc(game_state: ^Game_State) {
    title_text := "ODIN SURVIVORS"
    title_width := raylib.MeasureText(strings.clone_to_cstring(title_text), 80)
    raylib.DrawText(strings.clone_to_cstring(title_text), 1280/2 - title_width/2, 150, 80, raylib.WHITE)
    mouse_pos := raylib.GetMousePosition()
    
    // Character selection
    char_text := fmt.tprintf("Selected: %v", get_character_name(Global_Player_Data.selected_character))
    char_width := raylib.MeasureText(strings.clone_to_cstring(char_text), 20)
    raylib.DrawText(strings.clone_to_cstring(char_text), 1280/2 - char_width/2, 250, 20, raylib.YELLOW)
    
    // Display total gold
    gold_text := fmt.tprintf("Total Gold: %d", Global_Player_Data.total_gold)
    gold_width := raylib.MeasureText(strings.clone_to_cstring(gold_text), 20)
    raylib.DrawText(strings.clone_to_cstring(gold_text), 1280/2 - gold_width/2, 280, 20, raylib.GOLD)
    
    // Buttons
    start_button_rect := raylib.Rectangle{1280/2 - 150, 320, 300, 50}
    start_hover := raylib.CheckCollisionPointRec(mouse_pos, start_button_rect)
    start_button_color := raylib.BLUE
    if start_hover { start_button_color = raylib.SKYBLUE }
    raylib.DrawRectangleRec(start_button_rect, start_button_color)
    raylib.DrawText("START", i32(start_button_rect.x) + 110, i32(start_button_rect.y) + 10, 30, raylib.WHITE)
    if start_hover && raylib.IsMouseButtonPressed(.LEFT) { game_state^ = .PLAYING }
    
    // Meta upgrades button
    meta_button_rect := raylib.Rectangle{1280/2 - 150, 380, 300, 50}
    meta_hover := raylib.CheckCollisionPointRec(mouse_pos, meta_button_rect)
    meta_button_color := raylib.PURPLE
    if meta_hover { meta_button_color = raylib.VIOLET }
    raylib.DrawRectangleRec(meta_button_rect, meta_button_color)
    raylib.DrawText("META UPGRADES", i32(meta_button_rect.x) + 50, i32(meta_button_rect.y) + 10, 30, raylib.WHITE)
    if meta_hover && raylib.IsMouseButtonPressed(.LEFT) { game_state^ = .META_UPGRADE_MENU }
    
    settings_button_rect := raylib.Rectangle{1280/2 - 150, 440, 300, 50}
    settings_hover := raylib.CheckCollisionPointRec(mouse_pos, settings_button_rect)
    settings_button_color := raylib.GRAY
    if settings_hover { settings_button_color = raylib.LIGHTGRAY }
    raylib.DrawRectangleRec(settings_button_rect, settings_button_color)
    raylib.DrawText("SETTINGS", i32(settings_button_rect.x) + 85, i32(settings_button_rect.y) + 10, 30, raylib.WHITE)
    if settings_hover && raylib.IsMouseButtonPressed(.LEFT) { game_state^ = .SETTINGS }
    
    quit_button_rect := raylib.Rectangle{1280/2 - 150, 500, 300, 50}
    quit_hover := raylib.CheckCollisionPointRec(mouse_pos, quit_button_rect)
    quit_button_color := raylib.MAROON
    if quit_hover { quit_button_color = raylib.ORANGE }
    raylib.DrawRectangleRec(quit_button_rect, quit_button_color)
    raylib.DrawText("QUIT", i32(quit_button_rect.x) + 120, i32(quit_button_rect.y) + 10, 30, raylib.WHITE)
    if quit_hover && raylib.IsMouseButtonPressed(.LEFT) { raylib.CloseWindow() }
}

Update_And_Draw_Meta_Upgrade_Menu :: proc(game_state: ^Game_State, screenWidth: i32, screenHeight: i32) {
    mouse_pos := raylib.GetMousePosition()
    
    // Title
    title_text := "META UPGRADES"
    title_width := raylib.MeasureText(strings.clone_to_cstring(title_text), 60)
    raylib.DrawText(strings.clone_to_cstring(title_text), screenWidth/2 - title_width/2, 50, 60, raylib.WHITE)
    
    // Display total gold
    gold_text := fmt.tprintf("Total Gold: %d", Global_Player_Data.total_gold)
    gold_width := raylib.MeasureText(strings.clone_to_cstring(gold_text), 30)
    raylib.DrawText(strings.clone_to_cstring(gold_text), screenWidth/2 - gold_width/2, 120, 30, raylib.GOLD)
    
    // Character selection section
    raylib.DrawText("CHARACTER SELECTION:", 50, 180, 20, raylib.WHITE)
    char_y := i32(220)
    for char_type in Character_Type {
        idx: int
        switch char_type {
        case .WARRIOR: idx = 0
        case .MAGE: idx = 1
        case .ROGUE: idx = 2
        }
        
        if Global_Player_Data.unlocked_characters[idx] {
            char_rect := raylib.Rectangle{50, f32(char_y), 200, 30}
            char_hover := raylib.CheckCollisionPointRec(mouse_pos, char_rect)
            
            char_color := raylib.DARKGRAY
            if Global_Player_Data.selected_character == char_type {
                char_color = raylib.GREEN
            } else if char_hover {
                char_color = raylib.GRAY
            }
            
            raylib.DrawRectangleRec(char_rect, char_color)
            char_name := get_character_name(char_type)
            raylib.DrawText(strings.clone_to_cstring(char_name), 60, char_y + 5, 20, raylib.WHITE)
            
            if char_hover && raylib.IsMouseButtonPressed(.LEFT) {
                select_character(char_type)
            }
        } else {
            // Locked characters
            char_rect := raylib.Rectangle{50, f32(char_y), 200, 30}
            raylib.DrawRectangleRec(char_rect, raylib.DARKGRAY)
            char_name := get_character_name(char_type)
            locked_text := fmt.tprintf("%s (LOCKED)", char_name)
            raylib.DrawText(strings.clone_to_cstring(locked_text), 60, char_y + 5, 20, raylib.RED)
            
            // Display unlock cost
            unlock_cost := ""
            switch char_type {
            case .WARRIOR:
                // WARRIOR is already unlocked by default
            case .MAGE:
                unlock_cost = "500 gold"
            case .ROGUE:
                unlock_cost = "1000 gold"
            }
            
            unlock_text := fmt.tprintf("Unlock: %s", unlock_cost)
            raylib.DrawText(strings.clone_to_cstring(unlock_text), 60, char_y + 5, 12, raylib.YELLOW)
        }
        char_y += 35
    }
    
    // Meta upgrades grid
    raylib.DrawText("PERMANENT UPGRADES:", 350, 180, 20, raylib.WHITE)
    
    upgrade_y := i32(220)
    col_width := i32(400)
    
    // Create a variable copy of the constant array to index it
    available_upgrades := Available_Meta_Upgrades
    
    for idx in 0..<len(available_upgrades) {
        upgrade := available_upgrades[idx]
        
        if idx % 2 == 0 && idx > 0 {
            upgrade_y += 80
        }
        
        upgrade_x := i32(350) + (i32(idx % 2) * col_width)
        upgrade_rect := raylib.Rectangle{f32(upgrade_x), f32(upgrade_y), 380, 70}
        upgrade_hover := raylib.CheckCollisionPointRec(mouse_pos, upgrade_rect)
        
        current_level := Global_Player_Data.meta_upgrades[idx]
        cost := get_meta_upgrade_cost(upgrade.type, current_level)
        can_afford := Global_Player_Data.total_gold >= cost
        max_level_reached := current_level >= upgrade.max_level
        
        // Color coding
        upgrade_color := raylib.DARKGRAY
        if max_level_reached {
            upgrade_color = raylib.DARKGREEN  // Maxed out
        } else if can_afford && upgrade_hover {
            upgrade_color = raylib.GREEN      // Can purchase and hovering
        } else if can_afford {
            upgrade_color = raylib.GRAY       // Can purchase
        } else {
            upgrade_color = raylib.MAROON     // Can't afford
        }
        
        raylib.DrawRectangleRec(upgrade_rect, upgrade_color)
        raylib.DrawRectangleLinesEx(upgrade_rect, 2, raylib.WHITE)
        
        // Text
        title_text := fmt.tprintf("%s [%d/%d]", upgrade.title, current_level, upgrade.max_level)
        raylib.DrawText(strings.clone_to_cstring(title_text), upgrade_x + 10, upgrade_y + 5, 16, raylib.WHITE)
        raylib.DrawText(strings.clone_to_cstring(upgrade.description), upgrade_x + 10, upgrade_y + 25, 12, raylib.LIGHTGRAY)
        
        if !max_level_reached {
            cost_text := fmt.tprintf("Cost: %d gold", cost)
            raylib.DrawText(strings.clone_to_cstring(cost_text), upgrade_x + 10, upgrade_y + 45, 14, raylib.YELLOW)
        } else {
            raylib.DrawText("MAXED", upgrade_x + 10, upgrade_y + 45, 14, raylib.GREEN)
        }
        
        // Handle click
        if upgrade_hover && raylib.IsMouseButtonPressed(.LEFT) && !max_level_reached {
            purchase_meta_upgrade(upgrade.type)
        }
    }
    
    // Back button
    back_button_rect := raylib.Rectangle{50, f32(screenHeight - 100), 200, 50}
    back_hover := raylib.CheckCollisionPointRec(mouse_pos, back_button_rect)
    back_button_color := raylib.GRAY
    if back_hover { back_button_color = raylib.LIGHTGRAY }
    raylib.DrawRectangleRec(back_button_rect, back_button_color)
    raylib.DrawText("BACK TO MENU", 90, screenHeight - 85, 20, raylib.WHITE)
    if back_hover && raylib.IsMouseButtonPressed(.LEFT) {
        game_state^ = .MAIN_MENU
    }
}

Update_And_Draw_Settings_Menu :: proc(game_state: ^Game_State) {
    title_text := "SETTINGS"
    title_width := raylib.MeasureText(strings.clone_to_cstring(title_text), 60)
    raylib.DrawText(strings.clone_to_cstring(title_text), 1280/2 - title_width/2, 150, 60, raylib.WHITE)
    raylib.DrawText("Sound Settings (Coming Soon!)", 1280/2 - 150, 300, 20, raylib.RAYWHITE)
    
    mouse_pos := raylib.GetMousePosition()
    back_button_rect := raylib.Rectangle{1280/2 - 150, 440, 300, 50}
    back_hover := raylib.CheckCollisionPointRec(mouse_pos, back_button_rect)
    back_button_color := raylib.GRAY
    if back_hover { back_button_color = raylib.LIGHTGRAY }
    raylib.DrawRectangleRec(back_button_rect, back_button_color)
    raylib.DrawText("BACK", i32(back_button_rect.x) + 100, i32(back_button_rect.y) + 10, 30, raylib.WHITE)
    if back_hover && raylib.IsMouseButtonPressed(.LEFT) {
        game_state^ = .MAIN_MENU
    }
}

Draw_Level_Up_Screen :: proc(game_state: ^Game_State, player: ^Player, spinning_weapons: ^[MAX_SPIN_WEAPONS]Spinning_Weapon, possible_upgrades: [dynamic]Upgrade_Option, current_choices: [3]Upgrade_Option, screenWidth: i32, screenHeight: i32) {
    // Semi-transparent background
    raylib.DrawRectangle(0, 0, screenWidth, screenHeight, raylib.Color{0, 0, 0, 200})
    
    // Title
    title_text := "LEVEL UP!"
    title_width := raylib.MeasureText(strings.clone_to_cstring(title_text), 60)
    raylib.DrawText(strings.clone_to_cstring(title_text), screenWidth/2 - title_width/2, 150, 60, raylib.YELLOW)
    
    // Options
    mouse_pos := raylib.GetMousePosition()
    
    for i in 0..<3 {
        option_rect := raylib.Rectangle{f32(screenWidth/2 - 200), f32(250 + i * 100), 400, 80}
        hover := raylib.CheckCollisionPointRec(mouse_pos, option_rect)
        
        button_color := raylib.BLUE
        if hover { button_color = raylib.SKYBLUE }
        
        raylib.DrawRectangleRec(option_rect, button_color)
        raylib.DrawRectangleLinesEx(option_rect, 3, raylib.WHITE)
        
        // Text
        raylib.DrawText(strings.clone_to_cstring(current_choices[i].title), i32(option_rect.x) + 20, i32(option_rect.y) + 10, 24, raylib.WHITE)
        raylib.DrawText(strings.clone_to_cstring(current_choices[i].description), i32(option_rect.x) + 20, i32(option_rect.y) + 40, 16, raylib.LIGHTGRAY)
        
        // Click handler
        if hover && raylib.IsMouseButtonPressed(.LEFT) {
            Apply_Upgrade(player, spinning_weapons, current_choices[i])
            game_state^ = .PLAYING
        }
    }
}

Draw_Game_Over_Screen :: proc(screenWidth: i32, screenHeight: i32) {
    // Semi-transparent background
    raylib.DrawRectangle(0, 0, screenWidth, screenHeight, raylib.Color{0, 0, 0, 200})
    
    // Title
    title_text := "GAME OVER"
    title_width := raylib.MeasureText(strings.clone_to_cstring(title_text), 60)
    raylib.DrawText(strings.clone_to_cstring(title_text), screenWidth/2 - title_width/2, 200, 60, raylib.RED)
    
    // Gold collected
    gold_text := fmt.tprintf("Gold Collected: %d", Global_Player_Data.total_gold)
    gold_width := raylib.MeasureText(strings.clone_to_cstring(gold_text), 30)
    raylib.DrawText(strings.clone_to_cstring(gold_text), screenWidth/2 - gold_width/2, 280, 30, raylib.GOLD)
    
    // Instructions
    restart_text := "Press ENTER to play again"
    restart_width := raylib.MeasureText(strings.clone_to_cstring(restart_text), 30)
    raylib.DrawText(strings.clone_to_cstring(restart_text), screenWidth/2 - restart_width/2, 350, 30, raylib.WHITE)
    
    meta_text := "Press M for meta upgrades"
    meta_width := raylib.MeasureText(strings.clone_to_cstring(meta_text), 30)
    raylib.DrawText(strings.clone_to_cstring(meta_text), screenWidth/2 - meta_width/2, 400, 30, raylib.WHITE)
}