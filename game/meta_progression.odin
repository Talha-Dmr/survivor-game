package game
import "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:os"
import "core:encoding/json"

// Meta verileri dosyaya kaydet
save_meta_progression :: proc() -> bool {
    file_path := "meta_progression.json"
    
    json_data, marshal_err := json.marshal(Global_Player_Data)
    if marshal_err != nil {  // DÜZELTİLDİ: Hata nil değilse başarısız
        fmt.println("JSON marshal error:", marshal_err)
        return false
    }
    
    file, open_err := os.open(file_path, os.O_CREATE | os.O_WRONLY | os.O_TRUNC)
    if open_err != os.ERROR_NONE {
        fmt.println("Error opening file for writing:", open_err)
        return false
    }
    defer os.close(file)
    
    bytes_written, write_err := os.write(file, json_data)
    if write_err != os.ERROR_NONE {
        fmt.println("Error writing to file:", write_err)
        return false
    }
    
    if bytes_written != len(json_data) {
        fmt.println("Not all data was written")
        return false
    }
    
    return true
}

// Meta verileri dosyadan yükle
load_meta_progression :: proc() -> bool {
    file_path := "meta_progression.json"
    
    // Dosyanın var olup olmadığını kontrol et
    _, stat_err := os.stat(file_path)
    if stat_err != os.ERROR_NONE {
        fmt.println("Meta progression file not found, starting fresh.")
        return false
    }
    
    file, open_err := os.open(file_path, os.O_RDONLY)
    if open_err != os.ERROR_NONE {
        fmt.println("Error opening file for reading:", open_err)
        return false
    }
    defer os.close(file)
    
    file_info, stat_err2 := os.stat(file_path)
    if stat_err2 != os.ERROR_NONE {
        fmt.println("Error getting file size:", stat_err2)
        return false
    }
    
    buffer := make([]byte, int(file_info.size))
    defer delete(buffer)
    
    bytes_read, read_err := os.read(file, buffer)
    if read_err != os.ERROR_NONE {
        fmt.println("Error reading file:", read_err)
        return false
    }
    
    if bytes_read != int(file_info.size) {
        fmt.println("Not all data was read")
        return false
    }
    
    data: Player_Meta_Data
    unmarshal_err := json.unmarshal(buffer, &data)
    if unmarshal_err != nil {  // DÜZELTİLDİ: Hata nil değilse başarısız
        fmt.println("JSON unmarshal error:", unmarshal_err)
        return false
    }
    
    Global_Player_Data = data
    return true
}

// Initialize meta progression system
init_meta_progression :: proc() {
    if !load_meta_progression() {  // Burası boolean döndürdüğü için ! kullanabiliriz
        Global_Player_Data.total_gold = 0
        Global_Player_Data.selected_character = .WARRIOR
        Global_Player_Data.unlocked_characters[0] = true
        Global_Player_Data.unlocked_characters[1] = false
        Global_Player_Data.unlocked_characters[2] = false
        
        for i in 0..<len(Global_Player_Data.meta_upgrades) {
            Global_Player_Data.meta_upgrades[i] = 0
        }
    }
}

// Purchase meta upgrade
purchase_meta_upgrade :: proc(upgrade_type: Meta_Upgrade_Type) {
    idx: int
    switch upgrade_type {
    case .HEALTH_BOOST: idx = 0
    case .SPEED_BOOST: idx = 1
    case .DAMAGE_BOOST: idx = 2
    case .FIRE_RATE_BOOST: idx = 3
    case .XP_BOOST: idx = 4
    case .GOLD_BOOST: idx = 5
    case .INVINCIBILITY_BOOST: idx = 6
    case .STARTING_GOLD: idx = 7
    }
    
    current_level := Global_Player_Data.meta_upgrades[idx]
    cost := get_meta_upgrade_cost(upgrade_type, current_level)
    
    if Global_Player_Data.total_gold >= cost && current_level < MAX_META_UPGRADE_LEVEL {
        Global_Player_Data.total_gold -= cost
        Global_Player_Data.meta_upgrades[idx] += 1
        save_meta_progression()
    }
}

// Select character
select_character :: proc(char_type: Character_Type) {
    idx: int
    switch char_type {
    case .WARRIOR: idx = 0
    case .MAGE: idx = 1
    case .ROGUE: idx = 2
    }
    
    if Global_Player_Data.unlocked_characters[idx] {
        Global_Player_Data.selected_character = char_type
        save_meta_progression()
    }
}

// Add end game rewards
add_end_game_rewards :: proc(level: int, enemies_killed: int, gold_collected: int) {
    level_bonus := level * 5
    kill_bonus := enemies_killed / 10
    gold_bonus := gold_collected * 3 / 10
    
    total_bonus := level_bonus + kill_bonus + gold_bonus
    Global_Player_Data.total_gold += total_bonus
    
    if Global_Player_Data.total_gold >= 500 && !Global_Player_Data.unlocked_characters[1] {
        Global_Player_Data.unlocked_characters[1] = true
    }
    
    if Global_Player_Data.total_gold >= 1000 && !Global_Player_Data.unlocked_characters[2] {
        Global_Player_Data.unlocked_characters[2] = true
    }
    
    save_meta_progression()
}

get_meta_upgrade_cost :: proc(upgrade_type: Meta_Upgrade_Type, current_level: int) -> int {
    base_cost: int
    switch upgrade_type {
    case .HEALTH_BOOST: base_cost = 50
    case .SPEED_BOOST: base_cost = 60
    case .DAMAGE_BOOST: base_cost = 80
    case .FIRE_RATE_BOOST: base_cost = 70
    case .XP_BOOST: base_cost = 90
    case .GOLD_BOOST: base_cost = 100
    case .INVINCIBILITY_BOOST: base_cost = 120
    case .STARTING_GOLD: base_cost = 150
    }
    
    if current_level >= MAX_META_UPGRADE_LEVEL {
        return -1
    }
    
    return base_cost * (current_level + 1)
}

apply_meta_upgrades_to_player :: proc(player: ^Player) {
    switch player.character_type {
    case .WARRIOR:
        player.max_health = 100
        player.health = player.max_health
        player.speed = 200
        player.fire_rate = 0.8
    case .MAGE:
        player.max_health = 70
        player.health = player.max_health
        player.speed = 220
        player.fire_rate = 0.7
    case .ROGUE:
        player.max_health = 80
        player.health = player.max_health
        player.speed = 250
        player.fire_rate = 0.75
    }
    
    health_boost := 1.0 + 0.1 * f32(Global_Player_Data.meta_upgrades[0])
    speed_boost := 1.0 + 0.1 * f32(Global_Player_Data.meta_upgrades[1])
    fire_rate_boost := 1.0 - 0.1 * f32(Global_Player_Data.meta_upgrades[3]) * 0.1
    
    player.max_health *= health_boost
    player.health = player.max_health
    player.speed *= speed_boost
    player.fire_rate *= fire_rate_boost
    
    player.base_invincibility_duration = 1.0 + 0.5 * f32(Global_Player_Data.meta_upgrades[6])
    player.current_gold = 10 * Global_Player_Data.meta_upgrades[7]
}

calculate_damage :: proc(base_damage: int, player: Player) -> int {
    damage_multiplier := 1.0 + 0.15 * f32(Global_Player_Data.meta_upgrades[2])
    
    switch player.character_type {
    case .WARRIOR:
    case .MAGE:
        damage_multiplier *= 1.2
    case .ROGUE:
        damage_multiplier *= 1.1
    }
    
    return int(f32(base_damage) * damage_multiplier)
}

calculate_xp_gain :: proc(base_xp: int, player: Player) -> int {
    xp_multiplier := 1.0 + 0.2 * f32(Global_Player_Data.meta_upgrades[4])
    return int(f32(base_xp) * xp_multiplier)
}

calculate_gold_gain :: proc(base_gold: int, player: Player) -> int {
    gold_multiplier := 1.0 + 0.25 * f32(Global_Player_Data.meta_upgrades[5])
    return int(f32(base_gold) * gold_multiplier)
}

get_character_name :: proc(char_type: Character_Type) -> string {
    switch char_type {
    case .WARRIOR: return "Warrior"
    case .MAGE: return "Mage"
    case .ROGUE: return "Rogue"
    }
    return "Unknown"
}

// Mevcut altınları kalıcı altınlara ekle ve kaydet
add_current_gold_to_total :: proc(current_gold: int) {
    Global_Player_Data.total_gold += current_gold
    save_meta_progression()
}