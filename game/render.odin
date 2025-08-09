package game
import "vendor:raylib"
import "core:math"
import "core:fmt"
import "core:strings"

Draw_Game :: proc(player: Player, enemies: [MAX_ENEMIES]Enemy, projectiles: [MAX_PROJECTILES]Projectile, gems: [MAX_GEMS]XPGem, coins: [MAX_COINS]Coin, spinning_weapons: [MAX_SPIN_WEAPONS]Spinning_Weapon, textures: map[string]raylib.Texture2D, screenWidth: i32, screenHeight: i32) {
    // Kamera oluştur ve oyuncuyu takip et
    camera := raylib.Camera2D {
        offset = {f32(screenWidth) / 2, f32(screenHeight) / 2},
        target = player.pos + player.size / 2,
        rotation = 0,
        zoom = 1.0,
    }
    
    // Kamera modunu başlat
    raylib.BeginMode2D(camera)
    
    // Arka planı çiz (dünya boyutlarında)
    raylib.DrawRectangle(0, 0, WORLD_WIDTH, WORLD_HEIGHT, raylib.DARKGRAY)
    
    // Dünya sınırlarını göster (isteğe bağlı)
    raylib.DrawRectangleLines(0, 0, WORLD_WIDTH, WORLD_HEIGHT, raylib.RED)
    
    // Projectiles çizimi
    for i in 0..<MAX_PROJECTILES {
        if projectiles[i].is_active {
            raylib.DrawTextureEx(
                textures["projectile"],
                projectiles[i].pos,
                0,
                1,
                raylib.WHITE
            )
        }
    }
    
    // Enemies çizimi
    for i in 0..<MAX_ENEMIES {
        if enemies[i].is_active {
            enemy_color := raylib.WHITE
            
            // Enemy türüne göre renk
            switch enemies[i].type {
            case .NORMAL:
                enemy_color = raylib.WHITE
            case .ELITE:
                enemy_color = raylib.PURPLE
            case .SPEEDY:
                enemy_color = raylib.YELLOW
            case .TANK:
                enemy_color = raylib.DARKGREEN
            case .BOSS:
                enemy_color = raylib.RED
            case .FLYER:
                enemy_color = raylib.SKYBLUE
            }
            
            raylib.DrawTextureEx(
                textures["enemy"],
                enemies[i].pos,
                0,
                enemies[i].size.x / f32(textures["enemy"].width),
                enemy_color
            )
            
            // Enemy health bar (sadece hasar almışlarsa)
            if enemies[i].health < enemies[i].max_health {
                bar_width: f32 = enemies[i].size.x
                bar_height: f32 = 4
                health_ratio := enemies[i].health / enemies[i].max_health
                
                if health_ratio < 0 { health_ratio = 0 }
                
                raylib.DrawRectangle(
                    i32(enemies[i].pos.x),
                    i32(enemies[i].pos.y - 8),
                    i32(bar_width),
                    i32(bar_height),
                    raylib.DARKGRAY
                )
                
                bar_color := raylib.GREEN
                if health_ratio < 0.5 { bar_color = raylib.YELLOW }
                if health_ratio < 0.25 { bar_color = raylib.RED }
                
                raylib.DrawRectangle(
                    i32(enemies[i].pos.x),
                    i32(enemies[i].pos.y - 8),
                    i32(bar_width * health_ratio),
                    i32(bar_height),
                    bar_color
                )
            }
        }
    }
    
    // Gems çizimi
    for i in 0..<MAX_GEMS {
        if gems[i].is_active {
            gem_color := raylib.BLUE
            if gems[i].xp_amount > 5 {
                gem_color = raylib.PURPLE  // Büyük XP gem'leri mor
            }
            
            raylib.DrawTextureEx(
                textures["gem"],
                gems[i].pos,
                0,
                1,
                gem_color
            )
        }
    }
    
    // Coins çizimi
    for i in 0..<MAX_COINS {
        if coins[i].is_active {
            raylib.DrawTextureEx(
                textures["coin"],
                coins[i].pos,
                0,
                1,
                raylib.GOLD
            )
        }
    }
    
    // Player çizimi
    player_color := raylib.WHITE
    if player.invincibility_timer > 0 {
        // Yanıp sönme efekti
        flash_time := math.mod(player.invincibility_timer * 10, 1.0)
        if flash_time > 0.5 {
            player_color = raylib.Color{255, 255, 255, 100}
        }
    }
    
    raylib.DrawTextureEx(
        textures["player"],
        player.pos,
        0,
        1,
        player_color
    )
    
    // Spinning weapons çizimi
    for i in 0..<MAX_SPIN_WEAPONS {
        if spinning_weapons[i].is_active {
            // Bıçağın dönüş açısını texture'a uygula
            angle_degrees := spinning_weapons[i].angle * 180 / math.PI
            
            raylib.DrawTextureEx(
                textures["knife"],
                spinning_weapons[i].pos,
                angle_degrees,
                1,
                raylib.WHITE
            )
        }
    }
    
    // Kamera modunu bitir
    raylib.EndMode2D()
    
    // UI üst bar (ekran koordinatlarında)
    raylib.DrawRectangle(0, 0, screenWidth, 40, raylib.DARKBLUE)
    
    // Health bar
    health_bar_width: f32 = 200
    health_bar_height: f32 = 20
    health_percentage := player.health / player.max_health
    if health_percentage < 0 { health_percentage = 0 }
    
    raylib.DrawRectangle(10, 10, i32(health_bar_width), i32(health_bar_height), raylib.DARKGRAY)
    
    health_color := raylib.GREEN
    if health_percentage < 0.5 { health_color = raylib.YELLOW }
    if health_percentage < 0.25 { health_color = raylib.RED }
    
    raylib.DrawRectangle(10, 10, i32(health_bar_width * health_percentage), i32(health_bar_height), health_color)
    raylib.DrawRectangleLines(10, 10, i32(health_bar_width), i32(health_bar_height), raylib.WHITE)
    
    // Player stats
    level_text := fmt.tprintf("Level: %d", player.level)
    raylib.DrawText(strings.clone_to_cstring(level_text), 230, 10, 20, raylib.WHITE)
    
    xp_text := fmt.tprintf("XP: %d/%d", player.xp, player.xp_to_next_level)
    raylib.DrawText(strings.clone_to_cstring(xp_text), 350, 10, 20, raylib.WHITE)
    
    gold_text := fmt.tprintf("Gold: %d", player.current_gold)
    raylib.DrawText(strings.clone_to_cstring(gold_text), 550, 10, 20, raylib.YELLOW)
    
    // Minimap
    draw_minimap(player, enemies, screenWidth, screenHeight)
    
    // Game over kontrolü
    if player.health <= 0 {
        // Bu Draw_Game_Over_Screen fonksiyonunda handle edilecek
    }
}

// Minimap çizen fonksiyon
draw_minimap :: proc(player: Player, enemies: [MAX_ENEMIES]Enemy, screenWidth: i32, screenHeight: i32) {
    // Minimap boyutları
    minimap_width: f32 = f32(200.0)
    minimap_height: f32 = f32(112.5)  // 16:9 oranında
    minimap_scale_x := minimap_width / f32(WORLD_WIDTH)
    minimap_scale_y := minimap_height / f32(WORLD_HEIGHT)
    
    // Minimap konumu
    minimap_x := f32(screenWidth) - minimap_width - f32(10.0)
    minimap_y := f32(50.0)
    
    // Minimap arka planı
    raylib.DrawRectangle(i32(minimap_x), i32(minimap_y), i32(minimap_width), i32(minimap_height), raylib.Color{0, 0, 0, 180})
    raylib.DrawRectangleLines(i32(minimap_x), i32(minimap_y), i32(minimap_width), i32(minimap_height), raylib.WHITE)
    
    // Oyuncu minimap'te
    player_scaled_x := player.pos.x * minimap_scale_x
    player_scaled_y := player.pos.y * minimap_scale_y
    player_minimap_x := minimap_x + player_scaled_x
    player_minimap_y := minimap_y + player_scaled_y
    raylib.DrawCircle(i32(player_minimap_x), i32(player_minimap_y), 3, raylib.GREEN)
    
    // Düşmanlar minimap'te
    for i in 0..<MAX_ENEMIES {
        if enemies[i].is_active {
            enemy_scaled_x := enemies[i].pos.x * minimap_scale_x
            enemy_scaled_y := enemies[i].pos.y * minimap_scale_y
            enemy_minimap_x := minimap_x + enemy_scaled_x
            enemy_minimap_y := minimap_y + enemy_scaled_y
            
            // Düşman türüne göre renk
            enemy_color := raylib.RED
            switch enemies[i].type {
            case .NORMAL:
                enemy_color = raylib.RED
            case .ELITE:
                enemy_color = raylib.PURPLE
            case .SPEEDY:
                enemy_color = raylib.YELLOW
            case .TANK:
                enemy_color = raylib.DARKGREEN
            case .BOSS:
                enemy_color = raylib.MAROON
            case .FLYER:
                enemy_color = raylib.SKYBLUE
            }
            
            raylib.DrawCircle(i32(enemy_minimap_x), i32(enemy_minimap_y), 2, enemy_color)
        }
    }
}

// Enemy türü isimlerini döndüren helper fonksiyon
get_enemy_type_name :: proc(enemy_type: Enemy_Type) -> string {
    switch enemy_type {
    case .NORMAL: return "Normal"
    case .ELITE: return "Elite"
    case .SPEEDY: return "Speedy"
    case .TANK: return "Tank"
    case .BOSS: return "Boss"
    case .FLYER: return "Flyer"
    }
    return "Unknown"
}