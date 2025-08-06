package main

import "vendor:raylib"
import "core:time"

Player :: struct {
    pos:            raylib.Vector2,
    size:           raylib.Vector2,
    speed:          f32,
    fire_rate:      f32, 
    fire_cooldown:  f32, 
}

Enemy :: struct {
    pos:       raylib.Vector2,
    size:      raylib.Vector2,
    speed:     f32,
    is_active: bool, 
}

Projectile :: struct {
    pos:       raylib.Vector2,
    size:      raylib.Vector2,
    speed:     f32,
    is_active: bool,
}

// --- NEW CONSTANTS ---
MAX_PROJECTILES :: 100
MAX_ENEMIES     :: 50 // Maximum number of enemies that can be on screen at once

// Variable to hold the state of our pseudo-random number generator.
random_seed: u64

main :: proc() {
    // Initialize our random number generator with the current time.
    random_seed = u64(time.now()._nsec)

    screenWidth  : i32 = 800
    screenHeight : i32 = 450

    raylib.InitWindow(screenWidth, screenHeight, "Odin Survivors Prototype - Phase 1 COMPLETE")
    defer raylib.CloseWindow()

    raylib.SetTargetFPS(60)

    player := Player{
        pos           = {f32(screenWidth) / 2, f32(screenHeight) / 2},
        size          = {25, 25},
        speed         = 200.0,
        fire_rate     = 0.5, 
        fire_cooldown = 0,
    }
    
    // --- INCREASING THE ENEMY ARRAY SIZE ---
    enemies: [MAX_ENEMIES]Enemy
    // We are no longer creating enemies at the start, they will all start as inactive.
    
    projectiles: [MAX_PROJECTILES]Projectile

    // --- NEW TIMERS ---
    spawn_rate: f32 = 1.0 // A new enemy will spawn every 1.0 second
    spawn_timer: f32 = spawn_rate
    // ------------------

    for !raylib.WindowShouldClose() {
        dt := raylib.GetFrameTime() 

        // --- UPDATE PHASE ---

        // ENEMY SPAWNING LOGIC
        spawn_timer -= dt
        if spawn_timer <= 0 {
            spawn_timer = spawn_rate // Reset the timer

            // Find an inactive enemy and activate it
            for i in 0..<MAX_ENEMIES {
                if !enemies[i].is_active {
                    // Randomly choose which edge of the screen to spawn from (0:top, 1:right, 2:bottom, 3:left)
                    random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF
                    side := random_seed % 4

                    spawn_pos: raylib.Vector2
                    switch side {
                    case 0: // Top
                        random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF
                        spawn_pos = {f32(random_seed % u64(screenWidth)), -50}
                    case 1: // Right
                        random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF
                        spawn_pos = {f32(screenWidth) + 50, f32(random_seed % u64(screenHeight))}
                    case 2: // Bottom
                        random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF
                        spawn_pos = {f32(random_seed % u64(screenWidth)), f32(screenHeight) + 50}
                    case 3: // Left
                        random_seed = (random_seed * 1103515245 + 12345) & 0x7FFFFFFF
                        spawn_pos = {-50, f32(random_seed % u64(screenHeight))}
                    }

                    enemies[i] = Enemy {
                        pos = spawn_pos,
                        size = {30, 30},
                        speed = 100.0,
                        is_active = true,
                    }
                    break // We spawned an enemy, so break out of the loop.
                }
            }
        }
        
        // Other update logic (player movement, shooting etc.) remains the same...
        if raylib.IsKeyDown(.W) { player.pos.y -= player.speed * dt }
        if raylib.IsKeyDown(.S) { player.pos.y += player.speed * dt }
        if raylib.IsKeyDown(.A) { player.pos.x -= player.speed * dt }
        if raylib.IsKeyDown(.D) { player.pos.x += player.speed * dt }

        player.fire_cooldown -= dt
        if player.fire_cooldown <= 0 {
            player.fire_cooldown = player.fire_rate
            for i in 0..<MAX_PROJECTILES {
                if !projectiles[i].is_active {
                    projectiles[i] = Projectile{ pos = player.pos, size = {5, 10}, speed = 400.0, is_active = true, }
                    break 
                }
            }
        }

        for i in 0..<MAX_PROJECTILES {
            if projectiles[i].is_active {
                projectiles[i].pos.y -= projectiles[i].speed * dt 
                if projectiles[i].pos.y < 0 { projectiles[i].is_active = false }
            }
        }
        
        for i in 0..<len(enemies) {
            if enemies[i].is_active {
                direction := raylib.Vector2Normalize(player.pos - enemies[i].pos)
                enemies[i].pos += direction * enemies[i].speed * dt
            }
        }

        for i in 0..<MAX_PROJECTILES {
            if !projectiles[i].is_active { continue }
            for j in 0..<len(enemies) {
                if !enemies[j].is_active { continue }

                has_collided := raylib.CheckCollisionRecs(
                    {projectiles[i].pos.x, projectiles[i].pos.y, projectiles[i].size.x, projectiles[i].size.y},
                    {enemies[j].pos.x, enemies[j].pos.y, enemies[j].size.x, enemies[j].size.y},
                )

                if has_collided {
                    projectiles[i].is_active = false 
                    enemies[j].is_active = false // We don't respawn it anymore, just make it inactive.
                }
            }
        }

        // --- DRAWING PHASE ---
        raylib.BeginDrawing()
        defer raylib.EndDrawing()
        raylib.ClearBackground(raylib.DARKGRAY)

        raylib.DrawRectangleV(player.pos, player.size, raylib.MAROON)
        for enemy in enemies {
            if enemy.is_active {
                raylib.DrawRectangleV(enemy.pos, enemy.size, raylib.BLUE)
            }
        }
        for projectile in projectiles {
            if projectile.is_active {
                raylib.DrawRectangleV(projectile.pos, projectile.size, raylib.YELLOW)
            }
        }
        
        raylib.DrawText("Survive!", 10, 10, 20, raylib.RAYWHITE)
    }
}