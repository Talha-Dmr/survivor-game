// Dosya: game/gameplay.odin
package game

import "vendor:raylib"
import "core:time"
import "core:fmt"
import "core:math"

Apply_Upgrade :: proc(player: ^Player, spinning_weapons: ^[MAX_SPIN_WEAPONS]Spinning_Weapon, upgrade: Upgrade_Option) {
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

Reset_Game :: proc(player: ^Player, enemies: ^[MAX_ENEMIES]Enemy, projectiles: ^[MAX_PROJECTILES]Projectile, gems: ^[MAX_GEMS]XPGem, coins: ^[MAX_COINS]Coin, spinning_weapons: ^[MAX_SPIN_WEAPONS]Spinning_Weapon, spawn_timer: ^f32, spawn_rate: f32, screenWidth: i32, screenHeight: i32) {
    player.pos = {f32(screenWidth) / 2, f32(screenHeight) / 2}; player.speed = 200.0; player.fire_rate = 0.5; player.level = 1; player.xp = 0; player.xp_to_next_level = 10; player.num_active_knives = 0; 
    // --- FIX: Initialize max_health as well ---
    player.health = 100; player.max_health = 100; 
    player.current_gold = 0; 
    for i in 0..<MAX_ENEMIES { enemies[i].is_active = false }; for i in 0..<MAX_PROJECTILES { projectiles[i].is_active = false }; for i in 0..<MAX_GEMS { gems[i].is_active = false }; for i in 0..<MAX_COINS { coins[i].is_active = false }; for i in 0..<MAX_SPIN_WEAPONS { spinning_weapons[i].is_active = false }
    spawn_timer^ = spawn_rate
}

Update_Game :: proc(player: ^Player, enemies: ^[MAX_ENEMIES]Enemy, projectiles: ^[MAX_PROJECTILES]Projectile, gems: ^[MAX_GEMS]XPGem, coins: ^[MAX_COINS]Coin, spinning_weapons: ^[MAX_SPIN_WEAPONS]Spinning_Weapon, spawn_timer: ^f32, spawn_rate: f32, game_state: ^Game_State, possible_upgrades: ^[dynamic]Upgrade_Option, current_choices: ^[3]Upgrade_Option, screenWidth: i32, screenHeight: i32, enemy_texture_size: raylib.Vector2, projectile_texture_size: raylib.Vector2, gem_texture_size: raylib.Vector2, coin_texture_size: raylib.Vector2) {
    dt := raylib.GetFrameTime()
    if player.invincibility_timer > 0 { player.invincibility_timer -= dt }
    if raylib.IsKeyDown(.W) { player.pos.y -= player.speed * dt }; if raylib.IsKeyDown(.S) { player.pos.y += player.speed * dt }; if raylib.IsKeyDown(.A) { player.pos.x -= player.speed * dt }; if raylib.IsKeyDown(.D) { player.pos.x += player.speed * dt }
    if player.pos.x < 0 { player.pos.x = 0 }; if player.pos.x + player.size.x > f32(screenWidth) { player.pos.x = f32(screenWidth) - player.size.x }; if player.pos.y < 45 { player.pos.y = 45 }; if player.pos.y + player.size.y > f32(screenHeight) { player.pos.y = f32(screenHeight) - player.size.y }
    for i in 0..<MAX_SPIN_WEAPONS { if spinning_weapons[i].is_active { spinning_weapons[i].angle += spinning_weapons[i].spin_speed * dt; offset_x := math.cos(spinning_weapons[i].angle) * spinning_weapons[i].distance; offset_y := math.sin(spinning_weapons[i].angle) * spinning_weapons[i].distance; player_center := player.pos + player.size/2; spinning_weapons[i].pos = player_center + raylib.Vector2{offset_x, offset_y} - spinning_weapons[i].size/2 } }
    player.fire_cooldown -= dt; if player.fire_cooldown <= 0 { player.fire_cooldown = player.fire_rate; for i in 0..<MAX_PROJECTILES { if !projectiles[i].is_active { projectiles[i] = Projectile{ pos = player.pos, size = projectile_texture_size, speed = 400.0, is_active = true, }; break } } }
    for i in 0..<MAX_PROJECTILES { if projectiles[i].is_active { projectiles[i].pos.y -= projectiles[i].speed * dt; if projectiles[i].pos.y < 0 { projectiles[i].is_active = false } } }
    spawn_timer^ -= dt; if spawn_timer^ <= 0 { spawn_timer^ = spawn_rate; for i in 0..<MAX_ENEMIES { if !enemies[i].is_active { 
        Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF; side := Random_Seed % 4; spawn_pos: raylib.Vector2; switch side { case 0: Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF; spawn_pos = {f32(Random_Seed % u64(screenWidth)), -50}; case 1: Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF; spawn_pos = {f32(screenWidth) + 50, f32(Random_Seed % u64(screenHeight))}; case 2: Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF; spawn_pos = {f32(Random_Seed % u64(screenWidth)), f32(screenHeight) + 50}; case 3: Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF; spawn_pos = {-50, f32(Random_Seed % u64(screenHeight))}; }
        Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF
        if Random_Seed % 10 == 0 { enemies[i] = Enemy { type = .ELITE, health = 50, pos = spawn_pos, size = enemy_texture_size, speed = 75.0, is_active = true, } } 
        else { enemies[i] = Enemy { type = .NORMAL, health = 10, pos = spawn_pos, size = enemy_texture_size, speed = 100.0, is_active = true, } }
        break 
    } } }
    for i in 0..<len(enemies) { if enemies[i].is_active { direction := raylib.Vector2Normalize(player.pos - enemies[i].pos); enemies[i].pos += direction * enemies[i].speed * dt } }
    for i in 0..<MAX_PROJECTILES { if !projectiles[i].is_active { continue }; for j in 0..<len(enemies) { if !enemies[j].is_active { continue }; has_collided := raylib.CheckCollisionRecs({projectiles[i].pos.x, projectiles[i].pos.y, projectiles[i].size.x, projectiles[i].size.y}, {enemies[j].pos.x, enemies[j].pos.y, enemies[j].size.x, enemies[j].size.y}); if has_collided { projectiles[i].is_active = false; enemies[j].health -= 20; if enemies[j].health <= 0 { enemies[j].is_active = false; if enemies[j].type == .ELITE { for k in 0..<MAX_COINS { if !coins[k].is_active { coins[k] = Coin { pos = enemies[j].pos, size = coin_texture_size, is_active = true, }; break } } } else { for k in 0..<MAX_GEMS { if !gems[k].is_active { gems[k] = XPGem { pos = enemies[j].pos, size = gem_texture_size, xp_amount = 2, is_active = true, }; break } } } } } } }
    for i in 0..<MAX_SPIN_WEAPONS { if !spinning_weapons[i].is_active { continue }; weapon_rect := raylib.Rectangle{spinning_weapons[i].pos.x, spinning_weapons[i].pos.y, spinning_weapons[i].size.x, spinning_weapons[i].size.y}; for j in 0..<len(enemies) { if !enemies[j].is_active { continue }; enemy_rect := raylib.Rectangle{enemies[j].pos.x, enemies[j].pos.y, enemies[j].size.x, enemies[j].size.y}; if raylib.CheckCollisionRecs(weapon_rect, enemy_rect) { enemies[j].health -= 5 * dt; if enemies[j].health <= 0 { enemies[j].is_active = false; if enemies[j].type == .ELITE { for k in 0..<MAX_COINS { if !coins[k].is_active { coins[k] = Coin { pos = enemies[j].pos, size = coin_texture_size, is_active = true, }; break } } } else { for k in 0..<MAX_GEMS { if !gems[k].is_active { gems[k] = XPGem { pos = enemies[j].pos, size = gem_texture_size, xp_amount = 2, is_active = true, }; break } } } } } } }
    if player.invincibility_timer <= 0 { player_rect_damage := raylib.Rectangle{player.pos.x, player.pos.y, player.size.x, player.size.y}; for i in 0..<len(enemies) { if !enemies[i].is_active { continue }; enemy_rect := raylib.Rectangle{enemies[i].pos.x, enemies[i].pos.y, enemies[i].size.x, enemies[i].size.y}; if raylib.CheckCollisionRecs(player_rect_damage, enemy_rect) { player.health -= 10; player.invincibility_timer = 1.0; break } } }
    player_rect := raylib.Rectangle{player.pos.x, player.pos.y, player.size.x, player.size.y}; for i in 0..<MAX_GEMS { if !gems[i].is_active { continue }; gem_rect := raylib.Rectangle{gems[i].pos.x, gems[i].pos.y, gems[i].size.x, gems[i].size.y}; if raylib.CheckCollisionRecs(player_rect, gem_rect) { player.xp += gems[i].xp_amount; gems[i].is_active = false } }
    for i in 0..<MAX_COINS { if !coins[i].is_active { continue }; coin_rect := raylib.Rectangle{coins[i].pos.x, coins[i].pos.y, coins[i].size.x, coins[i].size.y}; if raylib.CheckCollisionRecs(player_rect, coin_rect) { player.current_gold += 1; coins[i].is_active = false } }
    if player.xp >= player.xp_to_next_level {
        game_state^ = .LEVEL_UP; player.level += 1; player.xp -= player.xp_to_next_level; player.xp_to_next_level = cast(int)(f32(player.xp_to_next_level) * 1.5)
        clear(possible_upgrades); for upgrade in Available_Upgrades { switch upgrade.type { case .ADD_SPINNING_WEAPON: if player.num_active_knives == 0 { append(possible_upgrades, upgrade) }; case .ADD_SECOND_KNIFE, .INCREASE_KNIFE_SPIN_SPEED: if player.num_active_knives > 0 && player.num_active_knives < MAX_SPIN_WEAPONS { append(possible_upgrades, upgrade) }; case .INCREASE_SPEED, .INCREASE_FIRE_RATE: append(possible_upgrades, upgrade) } }
        indices: [3]int = {-1, -1, -1}; for i in 0..=2 { if i >= len(possible_upgrades^) { indices[i] = -1; continue }; for { Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF; new_index := int(Random_Seed % u64(len(possible_upgrades^))); is_unique := true; for j in 0..<i { if new_index == indices[j] { is_unique = false; break } }; if is_unique { indices[i] = new_index; break } } }
        if indices[0] != -1 { current_choices[0] = possible_upgrades[indices[0]] }
        if indices[1] != -1 { current_choices[1] = possible_upgrades[indices[1]] }
        if indices[2] != -1 { current_choices[2] = possible_upgrades[indices[2]] }
    }
    if player.health <= 0 { game_state^ = .GAME_OVER }
}

Draw_Game :: proc(player: Player, enemies: [MAX_ENEMIES]Enemy, projectiles: [MAX_PROJECTILES]Projectile, gems: [MAX_GEMS]XPGem, coins: [MAX_COINS]Coin, spinning_weapons: [MAX_SPIN_WEAPONS]Spinning_Weapon, textures: map[string]raylib.Texture2D, screenWidth: i32, screenHeight: i32) {
    for coin in coins { if coin.is_active { raylib.DrawTextureV(textures["coin"], coin.pos, raylib.WHITE) } }
    for gem in gems { if gem.is_active { raylib.DrawTextureV(textures["gem"], gem.pos, raylib.WHITE) } }
    for projectile in projectiles { if projectile.is_active { raylib.DrawTextureV(textures["projectile"], projectile.pos, raylib.WHITE) } }
    for enemy in enemies { if enemy.is_active { enemy_color := raylib.WHITE; if enemy.type == .ELITE { enemy_color = raylib.GOLD }; raylib.DrawTextureV(textures["enemy"], enemy.pos, enemy_color) } }
    for weapon in spinning_weapons { if weapon.is_active { raylib.DrawTextureV(textures["knife"], weapon.pos, raylib.WHITE) } }
    if player.invincibility_timer > 0 { if cast(int)(player.invincibility_timer * 10) % 2 == 0 { raylib.DrawTextureV(textures["player"], player.pos, raylib.WHITE) } } else { raylib.DrawTextureV(textures["player"], player.pos, raylib.WHITE) }
    raylib.DrawRectangle(0, 0, screenWidth, 45, raylib.BLACK); xp_bar_width := (f32(player.xp) / f32(player.xp_to_next_level)) * f32(screenWidth); raylib.DrawRectangle(0, 0, i32(xp_bar_width), 20, raylib.SKYBLUE); health_bar_width := (player.health / player.max_health) * f32(screenWidth); raylib.DrawRectangle(0, 20, i32(health_bar_width), 20, raylib.RED); raylib.DrawText(raylib.TextFormat("LVL: %d", player.level), 10, 2, 20, raylib.RAYWHITE)
    raylib.DrawText(raylib.TextFormat("Altın: %d", player.current_gold), screenWidth - 150, 2, 20, raylib.GOLD)
}