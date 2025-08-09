package game
import "vendor:raylib"

// --- Constants ---
MAX_PROJECTILES :: 100
MAX_ENEMIES :: 50
MAX_GEMS :: 100
MAX_SPIN_WEAPONS :: 10
MAX_COINS :: 50
MAX_META_UPGRADE_LEVEL :: 5
// Boss spawn intervali (saniye)
BOSS_SPAWN_INTERVAL :: 60.0
// Dünya boyutları
WORLD_WIDTH :: 2560
WORLD_HEIGHT :: 1440
// --- Global Variables ---
Random_Seed: u64
// --- Data ---
Available_Upgrades :: [5]Upgrade_Option{
    { .INCREASE_SPEED, "Speed Boost", "Increases movement speed by 15%." },
    { .INCREASE_FIRE_RATE, "Rapid Fire", "Increases fire rate by 20%." },
    { .ADD_SPINNING_WEAPON, "Guardian Knife", "Adds a spinning knife around you." },
    { .ADD_SECOND_KNIFE, "Second Knife", "Adds a second spinning knife." },
    { .INCREASE_KNIFE_SPIN_SPEED, "Faster Rotor", "Increases knife spin speed by 25%."},
}
// --- Enums and Structs ---
Game_State :: enum {
    MAIN_MENU,
    SETTINGS,
    PLAYING,
    LEVEL_UP,
    GAME_OVER,
    META_UPGRADE_MENU
}
// Genişletilmiş enemy türleri
Enemy_Type :: enum {
    NORMAL,  // Standart düşman
    ELITE,   // Eski elit düşman (şimdi sadece daha güçlü normal)
    SPEEDY,  // Hızlı ama zayıf
    TANK,    // Yavaş ama çok güçlü
    BOSS,    // Boss düşman
    FLYER    // Uçan düşman
}
Upgrade_Type :: enum {
    INCREASE_SPEED,
    INCREASE_FIRE_RATE,
    ADD_SPINNING_WEAPON,
    ADD_SECOND_KNIFE,
    INCREASE_KNIFE_SPIN_SPEED
}
// Meta yükseltme türleri
Meta_Upgrade_Type :: enum {
    HEALTH_BOOST,        // Maksimum sağlık artışı
    SPEED_BOOST,         // Hareket hızı artışı
    DAMAGE_BOOST,        // Hasar artışı
    FIRE_RATE_BOOST,     // Ateş hızı artışı
    XP_BOOST,            // XP kazancı artışı
    GOLD_BOOST,          // Altın kazancı artışı
    INVINCIBILITY_BOOST, // Dokunulmazlık süresi artışı
    STARTING_GOLD,       // Başlangıç altını
}
// Karakter türleri
Character_Type :: enum {
    WARRIOR,
    MAGE,
    ROGUE
}
Player :: struct {
    pos: raylib.Vector2,
    size: raylib.Vector2,
    speed: f32,
    fire_rate: f32,
    fire_cooldown: f32,
    level: int,
    xp: int,
    xp_to_next_level: int,
    num_active_knives: int,
    health: f32,
    max_health: f32,
    invincibility_timer: f32,
    base_invincibility_duration: f32,
    current_gold: int,
    character_type: Character_Type,
}
Enemy :: struct {
    pos: raylib.Vector2,
    size: raylib.Vector2,
    speed: f32,
    is_active: bool,
    type: Enemy_Type,
    health: f32,
    max_health: f32,
    // Uçan düşmanlar için
    flight_timer: f32,  // Hareket kalıbı için timer
    base_y: f32,        // Orijinal Y pozisyonu
    // Boss için
    boss_timer: f32,    // Boss yetenekleri için timer
    boss_phase: int,    // Boss fazı
}
Projectile :: struct {
    pos: raylib.Vector2,
    size: raylib.Vector2,
    speed: f32,
    is_active: bool
}
XPGem :: struct {
    pos: raylib.Vector2,
    size: raylib.Vector2,
    xp_amount: int,
    is_active: bool
}
Coin :: struct {
    pos: raylib.Vector2,
    size: raylib.Vector2,
    is_active: bool
}
Spinning_Weapon :: struct {
    pos: raylib.Vector2,
    size: raylib.Vector2,
    angle: f32,
    distance: f32,
    spin_speed: f32,
    is_active: bool
}
Upgrade_Option :: struct {
    type: Upgrade_Type,
    title: string,
    description: string
}
// Meta yükseltme seçeneği
Meta_Upgrade_Option :: struct {
    type: Meta_Upgrade_Type,
    title: string,
    description: string,
    max_level: int,
}
// Meta ilerleme verileri
Player_Meta_Data :: struct {
    total_gold: int,
    selected_character: Character_Type,
    unlocked_characters: [3]bool, // Character_Type sayısı kadar
    meta_upgrades: [8]int, // Meta_Upgrade_Type sayısı kadar
}
// Mevcut meta yükseltmeler
Available_Meta_Upgrades :: [8]Meta_Upgrade_Option{
    { .HEALTH_BOOST, "Health Boost", "Maximum health +10%", 5 },
    { .SPEED_BOOST, "Speed Boost", "Movement speed +10%", 5 },
    { .DAMAGE_BOOST, "Damage Boost", "Damage dealt +15%", 5 },
    { .FIRE_RATE_BOOST, "Fire Rate Boost", "Fire rate +10%", 5 },
    { .XP_BOOST, "XP Gain Boost", "XP gained +20%", 5 },
    { .GOLD_BOOST, "Gold Gain Boost", "Gold gained +25%", 5 },
    { .INVINCIBILITY_BOOST, "Invincibility Duration", "Invincibility time +0.5s", 3 },
    { .STARTING_GOLD, "Starting Gold", "Start with +10 gold", 3 },
}
// Global meta veri değişkeni
Global_Player_Data: Player_Meta_Data
// Enemy spawn ağırlıkları (0-100 arası)
Enemy_Spawn_Weights :: struct {
    normal: int,
    elite: int,
    speedy: int,
    tank: int,
    flyer: int,
}
// Level'a göre spawn ağırlıkları
get_spawn_weights :: proc(player_level: int) -> Enemy_Spawn_Weights {
    if player_level < 3 {
        return {normal = 70, elite = 20, speedy = 10, tank = 0, flyer = 0}
    } else if player_level < 6 {
        return {normal = 50, elite = 25, speedy = 20, tank = 5, flyer = 0}
    } else if player_level < 10 {
        return {normal = 40, elite = 25, speedy = 20, tank = 10, flyer = 5}
    } else {
        return {normal = 30, elite = 25, speedy = 25, tank = 15, flyer = 5}
    }
}