// ========================================
// File: main.odin - Updated
// ========================================
package main
import game "game"
import "vendor:raylib"
import "core:time"

main :: proc() {
    game.Random_Seed = u64(time.now()._nsec)
    screenWidth  : i32 = 1280
    screenHeight : i32 = 720
    
    raylib.InitWindow(screenWidth, screenHeight, "Odin Survivors - Enhanced!")
    defer raylib.CloseWindow()
    raylib.SetTargetFPS(60)
    
    // Initialize meta progression BEFORE loading textures
    game.init_meta_progression()
    
    textures := make(map[string]raylib.Texture2D)
    textures["player"]     = raylib.LoadTexture("assets/player.png");     defer raylib.UnloadTexture(textures["player"])
    textures["enemy"]      = raylib.LoadTexture("assets/enemy.png");      defer raylib.UnloadTexture(textures["enemy"])
    textures["projectile"] = raylib.LoadTexture("assets/projectile.png"); defer raylib.UnloadTexture(textures["projectile"])
    textures["gem"]        = raylib.LoadTexture("assets/gem.png");        defer raylib.UnloadTexture(textures["gem"])
    textures["knife"]      = raylib.LoadTexture("assets/knife.png");      defer raylib.UnloadTexture(textures["knife"])
    textures["coin"]       = raylib.LoadTexture("assets/coin.png");       defer raylib.UnloadTexture(textures["coin"])
    
    player: game.Player
    enemies: [game.MAX_ENEMIES]game.Enemy
    projectiles: [game.MAX_PROJECTILES]game.Projectile
    gems: [game.MAX_GEMS]game.XPGem
    coins: [game.MAX_COINS]game.Coin
    spinning_weapons: [game.MAX_SPIN_WEAPONS]game.Spinning_Weapon
    
    // Başlangıçta daha yavaş bir spawn oranı (daha az düşman)
    spawn_rate: f32 = 3.0  // Başlangıçta 3 saniyede bir düşman spawnlar
    spawn_timer: f32 = spawn_rate
    boss_spawn_timer: f32 = game.BOSS_SPAWN_INTERVAL
    
    current_choices: [3]game.Upgrade_Option
    possible_upgrades: [dynamic]game.Upgrade_Option
    defer delete(possible_upgrades)
    
    game_state := game.Game_State.MAIN_MENU
    
    // Game stats tracking
    enemies_killed_this_game := 0
    
    player.size = {f32(textures["player"].width), f32(textures["player"].height)}
    game.Reset_Game(&player, &enemies, &projectiles, &gems, &coins, &spinning_weapons, &spawn_timer, spawn_rate, &boss_spawn_timer, screenWidth, screenHeight)
    
    for !raylib.WindowShouldClose() {
        switch game_state {
        case .PLAYING:
            old_killed := enemies_killed_this_game
            game.Update_Game(
                &player, &enemies, &projectiles, &gems, &coins, &spinning_weapons, 
                &spawn_timer, spawn_rate, &boss_spawn_timer, &game_state, &possible_upgrades, &current_choices, 
                screenWidth, screenHeight,
                raylib.Vector2{f32(textures["enemy"].width), f32(textures["enemy"].height)},
                raylib.Vector2{f32(textures["projectile"].width), f32(textures["projectile"].height)},
                raylib.Vector2{f32(textures["gem"].width), f32(textures["gem"].height)},
                raylib.Vector2{f32(textures["coin"].width), f32(textures["coin"].width)},
                &enemies_killed_this_game
            )
            
            // Game over check
            if player.health <= 0 {
                // Add end game rewards before changing state
                game.add_end_game_rewards(player.level, enemies_killed_this_game, player.current_gold)
                game_state = .GAME_OVER
            }
            
        case .GAME_OVER:
            if raylib.IsKeyPressed(.ENTER) {
                enemies_killed_this_game = 0
                game.Reset_Game(&player, &enemies, &projectiles, &gems, &coins, &spinning_weapons, &spawn_timer, spawn_rate, &boss_spawn_timer, screenWidth, screenHeight)
                game_state = .PLAYING
            } else if raylib.IsKeyPressed(.M) {
                game_state = .META_UPGRADE_MENU
            }
            
        case .MAIN_MENU, .SETTINGS, .LEVEL_UP, .META_UPGRADE_MENU:
            break
        }
        
        raylib.BeginDrawing()
        defer raylib.EndDrawing()
        raylib.ClearBackground(raylib.DARKGRAY)
        switch game_state {
        case .MAIN_MENU:
            game.Update_And_Draw_Main_Menu(&game_state)
            if game_state == .PLAYING {
                enemies_killed_this_game = 0
                game.Reset_Game(&player, &enemies, &projectiles, &gems, &coins, &spinning_weapons, &spawn_timer, spawn_rate, &boss_spawn_timer, screenWidth, screenHeight)
            }
        case .SETTINGS:
            game.Update_And_Draw_Settings_Menu(&game_state)
        case .META_UPGRADE_MENU:
            game.Update_And_Draw_Meta_Upgrade_Menu(&game_state, screenWidth, screenHeight)
        case .PLAYING, .LEVEL_UP, .GAME_OVER:
            game.Draw_Game(player, enemies, projectiles, gems, coins, spinning_weapons, textures, screenWidth, screenHeight)
            
            if game_state == .LEVEL_UP {
                game.Draw_Level_Up_Screen(&game_state, &player, &spinning_weapons, possible_upgrades, current_choices, screenWidth, screenHeight)
            }
            if game_state == .GAME_OVER {
                game.Draw_Game_Over_Screen(screenWidth, screenHeight)
            }
        }
    }
    
    // YENİ EKLENDİ: Oyun kapanırken mevcut altınları kaydet
    if game_state == .PLAYING {
        // Oyun hala devam ediyorsa, mevcut altınları kalıcı altınlara ekle
        game.add_current_gold_to_total(player.current_gold)
    }
    
    // Oyun kapanırken meta verileri kaydet
    game.save_meta_progression()
}