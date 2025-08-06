package main

import "vendor:raylib"
import "core:time"
import "core:fmt"
import "core:math"

Game_State :: enum {
    PLAYING,
    LEVEL_UP,
    GAME_OVER,
}

Player :: struct {
    pos:              raylib.Vector2,
    size:             raylib.Vector2,
    speed:            f32,
    fire_rate:        f32,
    fire_cooldown:    f32,
    level:            int,
    xp:               int,
    xp_to_next_level: int,
    num_active_knives: int,
    health:           f32,
    max_health:       f32,
    invincibility_timer: f32,
}
Enemy :: struct { pos: raylib.Vector2, size: raylib.Vector2, speed: f32, is_active: bool }
Projectile :: struct { pos: raylib.Vector2, size: raylib.Vector2, speed: f32, is_active: bool }
XPGem :: struct { pos: raylib.Vector2, size: raylib.Vector2, xp_amount: int, is_active: bool }
Spinning_Weapon :: struct { pos: raylib.Vector2, size: raylib.Vector2, angle: f32, distance: f32, spin_speed: f32, is_active:  bool }
Upgrade_Type :: enum { INCREASE_SPEED, INCREASE_FIRE_RATE, ADD_SPINNING_WEAPON, ADD_SECOND_KNIFE, INCREASE_KNIFE_SPIN_SPEED }
Upgrade_Option :: struct { type: Upgrade_Type, title: string, description: string }

MAX_PROJECTILES   :: 100; MAX_ENEMIES       :: 50; MAX_GEMS          :: 100; MAX_SPIN_WEAPONS  :: 10
random_seed: u64
available_upgrades :: [5]Upgrade_Option{ { .INCREASE_SPEED, "Hızlı Botlar", "Hareket hızını %15 artırır." }, { .INCREASE_FIRE_RATE, "Hızlı Tetik", "Ateş etme sıklığını %20 artırır." }, { .ADD_SPINNING_WEAPON, "Koruyucu Bıçak", "Etrafınızda dönen bir bıçak ekler." }, { .ADD_SECOND_KNIFE, "İkinci Bıçak", "Dönen ikinci bir bıçak ekler." }, { .INCREASE_KNIFE_SPIN_SPEED, "Hızlandırılmış Rotor", "Bıçakların dönüş hızını %25 artırır."} }

apply_upgrade :: proc(player: ^Player, spinning_weapons: ^[MAX_SPIN_WEAPONS]Spinning_Weapon, upgrade: Upgrade_Option) {
    switch upgrade.type {
    case .INCREASE_SPEED: player.speed *= 1.15
    case .INCREASE_FIRE_RATE: player.fire_rate *= 0.80
    case .ADD_SPINNING_WEAPON, .ADD_SECOND_KNIFE:
        for i in 0..<MAX_SPIN_WEAPONS { if !spinning_weapons[i].is_active { spinning_weapons[i] = Spinning_Weapon { size={20, 10}, angle=0, distance=50, spin_speed=4.0, is_active=true }; player.num_active_knives += 1; break } }
        active_knife_count := 0; for i in 0..<MAX_SPIN_WEAPONS { if spinning_weapons[i].is_active { active_knife_count += 1 } }; current_knife_index := 0
        for i in 0..<MAX_SPIN_WEAPONS { if spinning_weapons[i].is_active { spinning_weapons[i].angle = (2 * math.PI / f32(active_knife_count)) * f32(current_knife_index); current_knife_index += 1 } }
    case .INCREASE_KNIFE_SPIN_SPEED:
        for i in 0..<MAX_SPIN_WEAPONS { if spinning_weapons[i].is_active { spinning_weapons[i].spin_speed *= 1.25 } }
    }
}

reset_game :: proc(
    player: ^Player, 
    enemies: ^[MAX_ENEMIES]Enemy, 
    projectiles: ^[MAX_PROJECTILES]Projectile,
    gems: ^[MAX_GEMS]XPGem,
    spinning_weapons: ^[MAX_SPIN_WEAPONS]Spinning_Weapon,
    spawn_timer: ^f32,
    spawn_rate: f32,
) {
    player.pos               = {800 / 2, 450 / 2}
    player.speed             = 200.0
    player.fire_rate         = 0.5
    player.level             = 1
    player.xp                = 0
    player.xp_to_next_level  = 10
    player.num_active_knives = 0
    player.health            = 100
    
    for i in 0..<MAX_ENEMIES       { enemies[i].is_active = false }
    for i in 0..<MAX_PROJECTILES   { projectiles[i].is_active = false }
    for i in 0..<MAX_GEMS          { gems[i].is_active = false }
    for i in 0..<MAX_SPIN_WEAPONS  { spinning_weapons[i].is_active = false }

    spawn_timer^ = spawn_rate
}

main :: proc() {
    random_seed = u64(time.now()._nsec)
    screenWidth  : i32 = 800; screenHeight : i32 = 450
    raylib.InitWindow(screenWidth, screenHeight, "Odin Survivors - Prototype Complete!")
    defer raylib.CloseWindow()
    raylib.SetTargetFPS(60)

    player := Player{
        pos               = {f32(screenWidth) / 2, f32(screenHeight) / 2},
        size              = {25, 25},
        speed             = 200.0,
        fire_rate         = 0.5,
        fire_cooldown     = 0,
        level             = 1,
        xp                = 0,
        xp_to_next_level  = 10,
        num_active_knives = 0,
        max_health        = 100,
        health            = 100,
        invincibility_timer = 0,
    }

    enemies: [MAX_ENEMIES]Enemy; projectiles: [MAX_PROJECTILES]Projectile; gems: [MAX_GEMS]XPGem
    spinning_weapons: [MAX_SPIN_WEAPONS]Spinning_Weapon
    spawn_rate: f32 = 1.0; spawn_timer: f32 = spawn_rate
    current_choices: [3]Upgrade_Option; upgrades_var := available_upgrades
    possible_upgrades: [dynamic]Upgrade_Option; defer delete(possible_upgrades)
    
    game_state := Game_State.PLAYING

    for !raylib.WindowShouldClose() {
        dt := raylib.GetFrameTime()
        
        switch game_state {
        case .PLAYING:
            if player.invincibility_timer > 0 { player.invincibility_timer -= dt }
            for i in 0..<MAX_SPIN_WEAPONS { if spinning_weapons[i].is_active { spinning_weapons[i].angle += spinning_weapons[i].spin_speed * dt; offset_x := math.cos(spinning_weapons[i].angle) * spinning_weapons[i].distance; offset_y := math.sin(spinning_weapons[i].angle) * spinning_weapons[i].distance; player_center := player.pos + player.size/2; spinning_weapons[i].pos = player_center + raylib.Vector2{offset_x, offset_y} - spinning_weapons[i].size/2 } }
            spawn_timer -= dt; if spawn_timer <= 0 { spawn_timer = spawn_rate; for i in 0..<MAX_ENEMIES { if !enemies[i].is_active { random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF; side := random_seed % 4; spawn_pos: raylib.Vector2; switch side { case 0: random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF; spawn_pos = {f32(random_seed % u64(screenWidth)), -50}; case 1: random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF; spawn_pos = {f32(screenWidth) + 50, f32(random_seed % u64(screenHeight))}; case 2: random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF; spawn_pos = {f32(random_seed % u64(screenWidth)), f32(screenHeight) + 50}; case 3: random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF; spawn_pos = {-50, f32(random_seed % u64(screenHeight))}; }; enemies[i] = Enemy { pos = spawn_pos, size = {30, 30}, speed = 100.0, is_active = true, }; break } } }
            if raylib.IsKeyDown(.W) { player.pos.y -= player.speed * dt }; if raylib.IsKeyDown(.S) { player.pos.y += player.speed * dt }; if raylib.IsKeyDown(.A) { player.pos.x -= player.speed * dt }; if raylib.IsKeyDown(.D) { player.pos.x += player.speed * dt }
            player.fire_cooldown -= dt; if player.fire_cooldown <= 0 { player.fire_cooldown = player.fire_rate; for i in 0..<MAX_PROJECTILES { if !projectiles[i].is_active { projectiles[i] = Projectile{ pos = player.pos, size = {5, 10}, speed = 400.0, is_active = true, }; break } } }
            for i in 0..<MAX_PROJECTILES { if projectiles[i].is_active { projectiles[i].pos.y -= projectiles[i].speed * dt; if projectiles[i].pos.y < 0 { projectiles[i].is_active = false } } }
            for i in 0..<len(enemies) { if enemies[i].is_active { direction := raylib.Vector2Normalize(player.pos - enemies[i].pos); enemies[i].pos += direction * enemies[i].speed * dt } }
            for i in 0..<MAX_PROJECTILES { if !projectiles[i].is_active { continue }; for j in 0..<len(enemies) { if !enemies[j].is_active { continue }; has_collided := raylib.CheckCollisionRecs({projectiles[i].pos.x, projectiles[i].pos.y, projectiles[i].size.x, projectiles[i].size.y}, {enemies[j].pos.x, enemies[j].pos.y, enemies[j].size.x, enemies[j].size.y}); if has_collided { projectiles[i].is_active = false; enemies[j].is_active = false; for k in 0..<MAX_GEMS { if !gems[k].is_active { gems[k] = XPGem { pos = enemies[j].pos, size = {10, 10}, xp_amount = 2, is_active = true, }; break } } } } }
            for i in 0..<MAX_SPIN_WEAPONS { if !spinning_weapons[i].is_active { continue }; weapon_rect := raylib.Rectangle{spinning_weapons[i].pos.x, spinning_weapons[i].pos.y, spinning_weapons[i].size.x, spinning_weapons[i].size.y}; for j in 0..<len(enemies) { if !enemies[j].is_active { continue }; enemy_rect := raylib.Rectangle{enemies[j].pos.x, enemies[j].pos.y, enemies[j].size.x, enemies[j].size.y}; if raylib.CheckCollisionRecs(weapon_rect, enemy_rect) { enemies[j].is_active = false; for k in 0..<MAX_GEMS { if !gems[k].is_active { gems[k] = XPGem { pos = enemies[j].pos, size = {10, 10}, xp_amount = 2, is_active = true, }; break } } } } }
            if player.invincibility_timer <= 0 { player_rect_damage := raylib.Rectangle{player.pos.x, player.pos.y, player.size.x, player.size.y}; for i in 0..<len(enemies) { if !enemies[i].is_active { continue }; enemy_rect := raylib.Rectangle{enemies[i].pos.x, enemies[i].pos.y, enemies[i].size.x, enemies[i].size.y}; if raylib.CheckCollisionRecs(player_rect_damage, enemy_rect) { player.health -= 10; player.invincibility_timer = 1.0; break } } }
            player_rect := raylib.Rectangle{player.pos.x, player.pos.y, player.size.x, player.size.y}; for i in 0..<MAX_GEMS { if !gems[i].is_active { continue }; gem_rect := raylib.Rectangle{gems[i].pos.x, gems[i].pos.y, gems[i].size.x, gems[i].size.y}; if raylib.CheckCollisionRecs(player_rect, gem_rect) { player.xp += gems[i].xp_amount; gems[i].is_active = false } }
            
            if player.xp >= player.xp_to_next_level {
                game_state = .LEVEL_UP; player.level += 1; player.xp -= player.xp_to_next_level; player.xp_to_next_level = cast(int)(f32(player.xp_to_next_level) * 1.5)
                clear(&possible_upgrades); for upgrade in upgrades_var { switch upgrade.type { case .ADD_SPINNING_WEAPON: if player.num_active_knives == 0 { append(&possible_upgrades, upgrade) }; case .ADD_SECOND_KNIFE, .INCREASE_KNIFE_SPIN_SPEED: if player.num_active_knives > 0 && player.num_active_knives < MAX_SPIN_WEAPONS { append(&possible_upgrades, upgrade) }; case .INCREASE_SPEED, .INCREASE_FIRE_RATE: append(&possible_upgrades, upgrade) } }
                indices: [3]int = {-1, -1, -1}; for i in 0..=2 { if i >= len(possible_upgrades) { indices[i] = -1; continue }; for { random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF; new_index := int(random_seed % u64(len(possible_upgrades))); is_unique := true; for j in 0..<i { if new_index == indices[j] { is_unique = false; break } }; if is_unique { indices[i] = new_index; break } } }
                if indices[0] != -1 { current_choices[0] = possible_upgrades[indices[0]] }; if indices[1] != -1 { current_choices[1] = possible_upgrades[indices[1]] }; if indices[2] != -1 { current_choices[2] = possible_upgrades[indices[2]] }
            }
            if player.health <= 0 { game_state = .GAME_OVER }
        case .LEVEL_UP:
            break
        case .GAME_OVER:
            if raylib.IsKeyPressed(.ENTER) {
                reset_game(&player, &enemies, &projectiles, &gems, &spinning_weapons, &spawn_timer, spawn_rate)
                game_state = .PLAYING
            }
        }
        
        raylib.BeginDrawing(); defer raylib.EndDrawing(); raylib.ClearBackground(raylib.DARKGRAY)
        for gem in gems { if gem.is_active { raylib.DrawRectangleV(gem.pos, gem.size, raylib.GREEN) } }; for projectile in projectiles { if projectile.is_active { raylib.DrawRectangleV(projectile.pos, projectile.size, raylib.YELLOW) } }; for enemy in enemies { if enemy.is_active { raylib.DrawRectangleV(enemy.pos, enemy.size, raylib.BLUE) } }; for weapon in spinning_weapons { if weapon.is_active { raylib.DrawRectangleV(weapon.pos, weapon.size, raylib.GRAY) } }
        if player.invincibility_timer > 0 { if cast(int)(player.invincibility_timer * 10) % 2 == 0 { raylib.DrawRectangleV(player.pos, player.size, raylib.MAROON) } } else { raylib.DrawRectangleV(player.pos, player.size, raylib.MAROON) }
        raylib.DrawRectangle(0, 0, screenWidth, 45, raylib.BLACK); xp_bar_width := (f32(player.xp) / f32(player.xp_to_next_level)) * f32(screenWidth); raylib.DrawRectangle(0, 0, i32(xp_bar_width), 20, raylib.SKYBLUE); health_bar_width := (player.health / player.max_health) * f32(screenWidth); raylib.DrawRectangle(0, 20, i32(health_bar_width), 20, raylib.RED); raylib.DrawText(raylib.TextFormat("LVL: %d", player.level), 10, 2, 20, raylib.RAYWHITE)
        
        if game_state == .LEVEL_UP {
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
                if is_hovering && raylib.IsMouseButtonPressed(.LEFT) { apply_upgrade(&player, &spinning_weapons, current_choices[i]); game_state = .PLAYING }
            }
        }
        
        if game_state == .GAME_OVER {
            raylib.DrawRectangle(0, 0, screenWidth, screenHeight, raylib.Color{0, 0, 0, 200})
            text_width := raylib.MeasureText(raylib.TextFormat("GAME OVER"), 80); raylib.DrawText(raylib.TextFormat("GAME OVER"), screenWidth/2 - text_width/2, screenHeight/2 - 60, 80, raylib.RED)
            restart_text_width := raylib.MeasureText(raylib.TextFormat("Press ENTER to Restart"), 20); raylib.DrawText(raylib.TextFormat("Press ENTER to Restart"), screenWidth/2 - restart_text_width/2, screenHeight/2 + 40, 20, raylib.RAYWHITE)
        }
    }
}