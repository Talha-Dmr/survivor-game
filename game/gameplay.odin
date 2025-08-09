package game
import "vendor:raylib"
import "core:time"
import "core:fmt"
import "core:math"

Reset_Game :: proc(player: ^Player, enemies: ^[MAX_ENEMIES]Enemy, projectiles: ^[MAX_PROJECTILES]Projectile, gems: ^[MAX_GEMS]XPGem, coins: ^[MAX_COINS]Coin, spinning_weapons: ^[MAX_SPIN_WEAPONS]Spinning_Weapon, spawn_timer: ^f32, spawn_rate: f32, boss_spawn_timer: ^f32, screenWidth: i32, screenHeight: i32) {
    // Oyuncuyu dünya merkezine yerleştir
    player.pos = {f32(WORLD_WIDTH) / 2, f32(WORLD_HEIGHT) / 2}
    player.level = 1
    player.xp = 0
    player.xp_to_next_level = 10
    player.num_active_knives = 0
    player.invincibility_timer = 0
    player.fire_cooldown = 0
    
    // Karakter tipini ayarla
    player.character_type = Global_Player_Data.selected_character
    
    // Meta yükseltmeleri uygula
    apply_meta_upgrades_to_player(player)
    
    // Zorluk seviyesine göre ateş hızını ayarla
    adjust_difficulty(player)
    
    for i in 0..<MAX_ENEMIES { enemies[i].is_active = false }
    for i in 0..<MAX_PROJECTILES { projectiles[i].is_active = false }
    for i in 0..<MAX_GEMS { gems[i].is_active = false }
    for i in 0..<MAX_COINS { coins[i].is_active = false }
    for i in 0..<MAX_SPIN_WEAPONS { spinning_weapons[i].is_active = false }
    
    spawn_timer^ = spawn_rate
    boss_spawn_timer^ = BOSS_SPAWN_INTERVAL
}

// Zorluk seviyesini ayarlayan fonksiyon
adjust_difficulty :: proc(player: ^Player) {
    // Seviye arttıkça ateş hızı artar (düşen cooldown süresi)
    // Başlangıç seviyesi: 0.8s, her seviyede %5 azalır, minimum 0.2s
    fire_rate_modifier := 1.0 - 0.05 * f32(player.level - 1)
    if fire_rate_modifier < 0.25 { fire_rate_modifier = 0.25 }
    
    player.fire_rate *= fire_rate_modifier
}

Update_Game :: proc(player: ^Player, enemies: ^[MAX_ENEMIES]Enemy, projectiles: ^[MAX_PROJECTILES]Projectile, gems: ^[MAX_GEMS]XPGem, coins: ^[MAX_COINS]Coin, spinning_weapons: ^[MAX_SPIN_WEAPONS]Spinning_Weapon, spawn_timer: ^f32, spawn_rate: f32, boss_spawn_timer: ^f32, game_state: ^Game_State, possible_upgrades: ^[dynamic]Upgrade_Option, current_choices: ^[3]Upgrade_Option, screenWidth: i32, screenHeight: i32, enemy_texture_size: raylib.Vector2, projectile_texture_size: raylib.Vector2, gem_texture_size: raylib.Vector2, coin_texture_size: raylib.Vector2, enemies_killed: ^int) {
    dt := raylib.GetFrameTime()
    
    if player.invincibility_timer > 0 { 
        player.invincibility_timer -= dt 
    }
    
    // Player hareket
    if raylib.IsKeyDown(.W) { player.pos.y -= player.speed * dt }
    if raylib.IsKeyDown(.S) { player.pos.y += player.speed * dt }
    if raylib.IsKeyDown(.A) { player.pos.x -= player.speed * dt }
    if raylib.IsKeyDown(.D) { player.pos.x += player.speed * dt }
    
    // Player dünya sınır kontrolü
    if player.pos.x < 0 { player.pos.x = 0 }
    if player.pos.x + player.size.x > f32(WORLD_WIDTH) { player.pos.x = f32(WORLD_WIDTH) - player.size.x }
    if player.pos.y < 40 { player.pos.y = 40 }
    if player.pos.y + player.size.y > f32(WORLD_HEIGHT) { player.pos.y = f32(WORLD_HEIGHT) - player.size.y }
    
    // Fire cooldown
    if player.fire_cooldown > 0 {
        player.fire_cooldown -= dt
    }
    
    // Otomatik ateş (en yakın düşmana)
    if player.fire_cooldown <= 0 {
        closest_enemy_pos: raylib.Vector2
        closest_distance: f32 = 999999
        found_enemy := false
        
        for i in 0..<MAX_ENEMIES {
            if enemies[i].is_active {
                distance := raylib.Vector2Distance(player.pos, enemies[i].pos)
                if distance < closest_distance {
                    closest_distance = distance
                    closest_enemy_pos = enemies[i].pos
                    found_enemy = true
                }
            }
        }
        
        if found_enemy && closest_distance < 400 {
            for i in 0..<MAX_PROJECTILES {
                if !projectiles[i].is_active {
                    direction := raylib.Vector2Normalize(closest_enemy_pos - player.pos)
                    projectiles[i] = Projectile {
                        pos = player.pos + player.size / 2,
                        size = projectile_texture_size,
                        speed = 500.0,
                        is_active = true,
                    }
                    projectiles[i].pos += direction * 5
                    player.fire_cooldown = player.fire_rate
                    break
                }
            }
        }
    }
    
    // Spinning weapons update
    for i in 0..<MAX_SPIN_WEAPONS {
        if spinning_weapons[i].is_active {
            spinning_weapons[i].angle += spinning_weapons[i].spin_speed * dt
            
            spinning_weapons[i].pos = player.pos + player.size / 2 + raylib.Vector2 {
                math.cos(spinning_weapons[i].angle) * spinning_weapons[i].distance,
                math.sin(spinning_weapons[i].angle) * spinning_weapons[i].distance,
            } - spinning_weapons[i].size / 2
        }
    }
    
    // Projectiles update
    for i in 0..<MAX_PROJECTILES {
        if projectiles[i].is_active {
            projectiles[i].pos.y -= projectiles[i].speed * dt
            
            // Mermi dünya sınırları dışına çıkarsa devre dışı bırak
            if projectiles[i].pos.y < 0 || projectiles[i].pos.y > f32(WORLD_HEIGHT) ||
               projectiles[i].pos.x < 0 || projectiles[i].pos.x > f32(WORLD_WIDTH) {
                projectiles[i].is_active = false
            }
        }
    }
    
    // Enemy spawn - zorluk seviyesine göre ayarlanmış
    spawn_timer^ -= dt
    if spawn_timer^ <= 0 {
        Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF
        side := int(Random_Seed % 4)
        spawn_pos: raylib.Vector2
        
        // Düşmanları ekranın kenarları yerine dünya kenarlarından spawnla
        switch side {
        case 0: spawn_pos = {f32(Random_Seed % u64(WORLD_WIDTH)), -50}
        case 1: spawn_pos = {f32(WORLD_WIDTH) + 50, f32(Random_Seed % u64(WORLD_HEIGHT))}
        case 2: spawn_pos = {f32(Random_Seed % u64(WORLD_WIDTH)), f32(WORLD_HEIGHT) + 50}
        case 3: spawn_pos = {-50, f32(Random_Seed % u64(WORLD_HEIGHT))}
        }
        
        enemy_type := select_enemy_type(player.level)
        spawn_enemy(enemies, enemy_type, spawn_pos, enemy_texture_size)
        
        // Zorluk seviyesine göre spawn oranını ayarla
        // Başlangıçta 3.0s, her seviyede %10 azalır, minimum 0.5s
        spawn_rate_modifier := 1.0 - 0.1 * f32(player.level - 1)
        if spawn_rate_modifier < 0.17 { spawn_rate_modifier = 0.17 }
        
        spawn_timer^ = spawn_rate * spawn_rate_modifier
    }
    
    // Boss spawn timer
    boss_spawn_timer^ -= dt
    if boss_spawn_timer^ <= 0 {
        boss_spawn_pos := raylib.Vector2{f32(WORLD_WIDTH / 2), f32(WORLD_HEIGHT / 2)}
        spawn_enemy(enemies, .BOSS, boss_spawn_pos, enemy_texture_size)
        boss_spawn_timer^ = BOSS_SPAWN_INTERVAL
    }
    
    // Enemies update
    for i in 0..<MAX_ENEMIES {
        if enemies[i].is_active {
            update_enemy_ai(&enemies[i], player.pos + player.size / 2, dt)
            
            // Enemy-Player collision
            if check_collision(enemies[i].pos, enemies[i].size, player.pos, player.size) {
                if player.invincibility_timer <= 0 {
                    player.health -= 10
                    player.invincibility_timer = player.base_invincibility_duration
                }
            }
        }
    }
    
    // Projectile-Enemy collisions
    for i in 0..<MAX_PROJECTILES {
        if projectiles[i].is_active {
            for j in 0..<MAX_ENEMIES {
                if enemies[j].is_active {
                    if check_collision(projectiles[i].pos, projectiles[i].size, enemies[j].pos, enemies[j].size) {
                        // Calculate damage with meta upgrades
                        damage := f32(calculate_damage(10, player^))
                        enemies[j].health -= damage
                        projectiles[i].is_active = false
                        
                        // Enemy öldü mü?
                        if enemies[j].health <= 0 {
                            enemies_killed^ += 1
                            
                            // XP gem spawn with meta multiplier
                            base_xp := 1
                            if enemies[j].type == .ELITE { base_xp = 3 }
                            if enemies[j].type == .BOSS { base_xp = 10 }
                            if enemies[j].type == .TANK { base_xp = 5 }
                            
                            final_xp := calculate_xp_gain(base_xp, player^)
                            spawn_xp_gem(gems, enemies[j].pos, gem_texture_size, final_xp)
                            
                            // Coin spawn with meta multiplier
                            Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF
                            if (Random_Seed % 100) < 30 {
                                spawn_coin(coins, enemies[j].pos, coin_texture_size)
                            }
                            
                            enemies[j].is_active = false
                        }
                        break
                    }
                }
            }
        }
    }
    
    // Spinning weapon-Enemy collisions
    for i in 0..<MAX_SPIN_WEAPONS {
        if spinning_weapons[i].is_active {
            for j in 0..<MAX_ENEMIES {
                if enemies[j].is_active {
                    if check_collision(spinning_weapons[i].pos, spinning_weapons[i].size, enemies[j].pos, enemies[j].size) {
                        damage := f32(calculate_damage(15, player^))
                        enemies[j].health -= damage
                        
                        if enemies[j].health <= 0 {
                            enemies_killed^ += 1
                            
                            base_xp := 1
                            if enemies[j].type == .ELITE { base_xp = 3 }
                            if enemies[j].type == .BOSS { base_xp = 10 }
                            if enemies[j].type == .TANK { base_xp = 5 }
                            
                            final_xp := calculate_xp_gain(base_xp, player^)
                            spawn_xp_gem(gems, enemies[j].pos, gem_texture_size, final_xp)
                            
                            Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF
                            if (Random_Seed % 100) < 30 {
                                spawn_coin(coins, enemies[j].pos, coin_texture_size)
                            }
                            
                            enemies[j].is_active = false
                        }
                    }
                }
            }
        }
    }
    
    // Player-XP Gem collisions
    for i in 0..<MAX_GEMS {
        if gems[i].is_active {
            if check_collision(player.pos, player.size, gems[i].pos, gems[i].size) {
                player.xp += gems[i].xp_amount
                gems[i].is_active = false
                
                // Level up kontrolü
                if player.xp >= player.xp_to_next_level {
                    handle_level_up(player, game_state, possible_upgrades, current_choices)
                }
            }
        }
    }
    
    // Player-Coin collisions
    for i in 0..<MAX_COINS {
        if coins[i].is_active {
            if check_collision(player.pos, player.size, coins[i].pos, coins[i].size) {
                gold_gained := calculate_gold_gain(1, player^)
                player.current_gold += gold_gained
                coins[i].is_active = false
            }
        }
    }
}

// Enemy spawn fonksiyonları
spawn_enemy :: proc(enemies: ^[MAX_ENEMIES]Enemy, enemy_type: Enemy_Type, pos: raylib.Vector2, texture_size: raylib.Vector2) {
    for i in 0..<MAX_ENEMIES {
        if !enemies[i].is_active {
            enemies[i] = Enemy {
                pos = pos,
                size = texture_size,
                is_active = true,
                type = enemy_type,
                flight_timer = 0,
                base_y = pos.y,
                boss_timer = 0,
                boss_phase = 0,
            }
            
            // Enemy türüne göre özellikler
            switch enemy_type {
            case .NORMAL:
                enemies[i].speed = 80
                enemies[i].health = 20
                enemies[i].max_health = 20
            case .ELITE:
                enemies[i].speed = 90
                enemies[i].health = 40
                enemies[i].max_health = 40
            case .SPEEDY:
                enemies[i].speed = 150
                enemies[i].health = 15
                enemies[i].max_health = 15
            case .TANK:
                enemies[i].speed = 50
                enemies[i].health = 80
                enemies[i].max_health = 80
            case .BOSS:
                enemies[i].speed = 60
                enemies[i].health = 200
                enemies[i].max_health = 200
                enemies[i].size.x *= 2
                enemies[i].size.y *= 2
            case .FLYER:
                enemies[i].speed = 100
                enemies[i].health = 25
                enemies[i].max_health = 25
            }
            
            break
        }
    }
}

select_enemy_type :: proc(player_level: int) -> Enemy_Type {
    weights := get_spawn_weights(player_level)
    total_weight := weights.normal + weights.elite + weights.speedy + weights.tank + weights.flyer
    
    Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF
    roll := int(Random_Seed % u64(total_weight))
    
    if roll < weights.normal {
        return .NORMAL
    } else if roll < weights.normal + weights.elite {
        return .ELITE
    } else if roll < weights.normal + weights.elite + weights.speedy {
        return .SPEEDY
    } else if roll < weights.normal + weights.elite + weights.speedy + weights.tank {
        return .TANK
    } else {
        return .FLYER
    }
}

update_enemy_ai :: proc(enemy: ^Enemy, player_pos: raylib.Vector2, dt: f32) {
    switch enemy.type {
    case .NORMAL, .ELITE, .TANK:
        // Basit takip davranışı
        direction := raylib.Vector2Normalize(player_pos - enemy.pos)
        enemy.pos += direction * enemy.speed * dt
        
    case .SPEEDY:
        // Hızlı düşmanlar - düz çizgide hareket eder
        direction := raylib.Vector2Normalize(player_pos - enemy.pos)
        enemy.pos += direction * enemy.speed * dt
        
    case .BOSS:
        // Boss davranışı
        enemy.boss_timer += dt
        
        // Her 5 saniyede bir faz değiştir
        if enemy.boss_timer > 5.0 {
            enemy.boss_timer = 0
            enemy.boss_phase = (enemy.boss_phase + 1) % 3
        }
        
        // Faza göre davranış
        switch enemy.boss_phase {
        case 0:
            // Takip
            direction := raylib.Vector2Normalize(player_pos - enemy.pos)
            enemy.pos += direction * enemy.speed * dt
        case 1:
            // Dairesel hareket
            angle := enemy.boss_timer * 2
            enemy.pos.x = player_pos.x + math.cos(angle) * 150
            enemy.pos.y = player_pos.y + math.sin(angle) * 150
        case 2:
            // Hızlı saldırı
            if enemy.boss_timer < 1.0 {
                direction := raylib.Vector2Normalize(player_pos - enemy.pos)
                enemy.pos += direction * enemy.speed * 2 * dt
            }
        }
        
    case .FLYER:
        // Uçan düşmanlar - dalgalı hareket
        enemy.flight_timer += dt
        enemy.pos.y = enemy.base_y + math.sin(enemy.flight_timer * 3) * 30
        
        // Yatay hareket
        if enemy.pos.x < player_pos.x {
            enemy.pos.x += enemy.speed * dt
        } else {
            enemy.pos.x -= enemy.speed * dt
        }
    }
}

check_collision :: proc(pos1: raylib.Vector2, size1: raylib.Vector2, pos2: raylib.Vector2, size2: raylib.Vector2) -> bool {
    return pos1.x < pos2.x + size2.x &&
           pos1.x + size1.x > pos2.x &&
           pos1.y < pos2.y + size2.y &&
           pos1.y + size1.y > pos2.y
}

spawn_xp_gem :: proc(gems: ^[MAX_GEMS]XPGem, pos: raylib.Vector2, texture_size: raylib.Vector2, xp_amount: int) {
    for i in 0..<MAX_GEMS {
        if !gems[i].is_active {
            gems[i] = XPGem {
                pos = pos,
                size = texture_size,
                xp_amount = xp_amount,
                is_active = true,
            }
            break
        }
    }
}

spawn_coin :: proc(coins: ^[MAX_COINS]Coin, pos: raylib.Vector2, texture_size: raylib.Vector2) {
    for i in 0..<MAX_COINS {
        if !coins[i].is_active {
            coins[i] = Coin {
                pos = pos,
                size = texture_size,
                is_active = true,
            }
            break
        }
    }
}

handle_level_up :: proc(player: ^Player, game_state: ^Game_State, possible_upgrades: ^[dynamic]Upgrade_Option, current_choices: ^[3]Upgrade_Option) {
    player.level += 1
    player.xp -= player.xp_to_next_level
    player.xp_to_next_level = player.level * 10
    
    // Seçenekleri oluştur
    clear(possible_upgrades)
    for upgrade in Available_Upgrades {
        append(possible_upgrades, upgrade)
    }
    
    // Rastgele 3 seçenek seç
    for i in 0..<3 {
        Random_Seed = (Random_Seed * 1103515245 + 12345) & 0x7FFFFFFF
        index := int(Random_Seed % u64(len(possible_upgrades)))
        current_choices[i] = possible_upgrades[index]
        ordered_remove(possible_upgrades, index)
    }
    
    // Seviye atlandığında zorluğu güncelle
    adjust_difficulty(player)
    
    game_state^ = .LEVEL_UP
}

Apply_Upgrade :: proc(player: ^Player, spinning_weapons: ^[MAX_SPIN_WEAPONS]Spinning_Weapon, upgrade: Upgrade_Option) {
    switch upgrade.type {
    case .INCREASE_SPEED:
        player.speed *= 1.15
    case .INCREASE_FIRE_RATE:
        player.fire_rate *= 0.8
    case .ADD_SPINNING_WEAPON:
        if player.num_active_knives < MAX_SPIN_WEAPONS {
            for i in 0..<MAX_SPIN_WEAPONS {
                if !spinning_weapons[i].is_active {
                    spinning_weapons[i] = Spinning_Weapon {
                        pos = player.pos,
                        size = {20, 20},
                        angle = f32(player.num_active_knives) * (2 * math.PI / f32(MAX_SPIN_WEAPONS)),
                        distance = 40,
                        spin_speed = 3,
                        is_active = true,
                    }
                    player.num_active_knives += 1
                    break
                }
            }
        }
    case .ADD_SECOND_KNIFE:
        if player.num_active_knives < MAX_SPIN_WEAPONS {
            for i in 0..<MAX_SPIN_WEAPONS {
                if !spinning_weapons[i].is_active {
                    spinning_weapons[i] = Spinning_Weapon {
                        pos = player.pos,
                        size = {20, 20},
                        angle = f32(player.num_active_knives) * (2 * math.PI / f32(MAX_SPIN_WEAPONS)),
                        distance = 40,
                        spin_speed = 3,
                        is_active = true,
                    }
                    player.num_active_knives += 1
                    break
                }
            }
        }
    case .INCREASE_KNIFE_SPIN_SPEED:
        for i in 0..<MAX_SPIN_WEAPONS {
            if spinning_weapons[i].is_active {
                spinning_weapons[i].spin_speed *= 1.25
            }
        }
    }
}