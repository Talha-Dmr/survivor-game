// Dosya: game/types.odin
package game

import "vendor:raylib"

// --- Constants ---
// Moved all constants here to be part of the 'game' package and accessible everywhere
MAX_PROJECTILES   :: 100
MAX_ENEMIES       :: 50
MAX_GEMS          :: 100
MAX_SPIN_WEAPONS  :: 10
MAX_COINS         :: 50

// --- Global Variables ---
// Capitalized to be exported from the 'game' package
Random_Seed: u64

// --- Data ---
// Capitalized and moved here to be exported from the 'game' package
Available_Upgrades :: [5]Upgrade_Option{
    { .INCREASE_SPEED,        "Hızlı Botlar",      "Hareket hızını %15 artırır."         },
    { .INCREASE_FIRE_RATE,    "Hızlı Tetik",       "Ateş etme sıklığını %20 artırır."    },
    { .ADD_SPINNING_WEAPON,   "Koruyucu Bıçak",    "Etrafınızda dönen bir bıçak ekler."    },
    { .ADD_SECOND_KNIFE,      "İkinci Bıçak",      "Dönen ikinci bir bıçak ekler."       },
    { .INCREASE_KNIFE_SPIN_SPEED, "Hızlandırılmış Rotor",  "Bıçakların dönüş hızını %25 artırır."},
}

// --- Enums and Structs ---
Game_State :: enum { MAIN_MENU, SETTINGS, PLAYING, LEVEL_UP, GAME_OVER }
Enemy_Type :: enum { NORMAL, ELITE }
Upgrade_Type :: enum { INCREASE_SPEED, INCREASE_FIRE_RATE, ADD_SPINNING_WEAPON, ADD_SECOND_KNIFE, INCREASE_KNIFE_SPIN_SPEED }

Player :: struct { pos: raylib.Vector2, size: raylib.Vector2, speed: f32, fire_rate: f32, fire_cooldown: f32, level: int, xp: int, xp_to_next_level: int, num_active_knives: int, health: f32, max_health: f32, invincibility_timer: f32, current_gold: int }
Enemy :: struct { pos: raylib.Vector2, size: raylib.Vector2, speed: f32, is_active: bool, type: Enemy_Type, health: f32 }
Projectile :: struct { pos: raylib.Vector2, size: raylib.Vector2, speed: f32, is_active: bool }
XPGem :: struct { pos: raylib.Vector2, size: raylib.Vector2, xp_amount: int, is_active: bool }
Coin :: struct { pos: raylib.Vector2, size: raylib.Vector2, is_active:  bool }
Spinning_Weapon :: struct { pos: raylib.Vector2, size: raylib.Vector2, angle: f32, distance: f32, spin_speed: f32, is_active:  bool }
Upgrade_Option :: struct { type: Upgrade_Type, title: string, description: string }