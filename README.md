# ShikaSwap - WoW Vanilla/Turtle Addon

**ShikaSwap** is an addon for World of Warcraft 1.12 (Vanilla/Turtle WoW) that automatically equips the correct libram when you cast Paladin spells.

> **Note**: This is a modified version of the original LibramSwap addon by Theo. I've rebuilt and enhanced it with my own features and improvements.

## 📋 Features

- ✅ **Automatic libram swapping** before casting spells
- ✅ **Profile system** to save different configurations
- ✅ **Spell management** via Sorts Manager (Add/Remove)
- ✅ **Visual indicators** (green = libram in bags, red = missing)
- ✅ **Auto-load** last used profile on login
- ✅ **Intuitive interface** with dropdowns and checkboxes

## 🎮 Installation

1. Download the addon (green "Code" button → "Download ZIP")
2. Extract the `Libramswap-main` folder
3. Rename it to `LibramSwap`
4. Place it in: `World of Warcraft/Interface/AddOns/LibramSwap`
5. Restart WoW or type `/reload` in-game

## ⌨️ Commands

| Command | Description |
|---------|-------------|
| `/ss` | Open/close the configuration menu |
| `/shikaswap` | Toggle addon on/off |
| `/ssikaprofile` | Show currently active profile |
| `/ssikadebug on/off` | Enable/disable debug messages |
| `/swaplibram <Spell>` | Manual swap test for a spell |
| `/equiplibram <Name>` | Manually equip a libram |

## 📖 Usage Guide

### 1️⃣ First Launch

After installation, type `/ss` to open the menu.

### 2️⃣ Add Spells to Configure

1. Click the **"Sorts"** button (top right)
2. Search for a spell in the list (e.g., "Holy Light")
3. Click **"Add"** to add it to your configuration
4. Repeat for all your important spells

### 3️⃣ Choose Librams

1. In the main configuration, click the button next to the spell name
2. Select the libram you want to equip for that spell
3. The indicator turns **green** if you have the libram in your bags

### 4️⃣ Save a Profile

1. Click **"Save"** (top right)
2. Enter a profile name (e.g., "Heal", "Tank", "PvP")
3. Click **"Create"** or **"Save"**
4. Your configuration is now saved!

### 5️⃣ Load a Profile

1. Click **"Save"** to open the profile manager
2. Click on a profile in the list
3. Click **"Load"**
4. The profile will auto-load on next login

### 6️⃣ Remove Spells

1. Click **"Sorts"**
2. Find the spell to remove
3. Click **"Remove"**
4. The spell disappears from the configuration

## ⚠️ Important - Macro Requirements

**For proper functionality, you MUST use macros for the following spells:**

The addon needs the **exact spell rank** to work correctly. Create macros for these spells:

### Required Macros

**Holy Strike:**
```
#showtooltip Holy Strike
/cast Holy Strike(Rank X)
```

**Holy Shield:**
```
#showtooltip Holy Shield
/cast Holy Shield(Rank X)
```

**Consecration:**
```
#showtooltip Consecration
/cast Consecration(Rank X)
```

**Flash of Light:**
```
#showtooltip Flash of Light
/cast Flash of Light(Rank X)
```

**Holy Light:**
```
#showtooltip Holy Light
/cast Holy Light(Rank X)
```

> **Note**: Replace `Rank X` with your actual spell rank (e.g., `Rank 5`, `Rank 6`, etc.)

### Why Macros Are Needed

The game client doesn't always provide the spell rank when you cast directly from your action bar. Using macros ensures ShikaSwap can:
- Identify the exact spell being cast
- Equip the correct libram before casting
- Work reliably in all situations

**Without macros**, these spells may not trigger the libram swap!

## 🔧 Advanced Options

### Swap Delay
- Adjust the delay between libram swap and spell cast
- Recommended value: **0.02 seconds**

### Debug
- Enable to see all detailed messages in chat
- Useful for troubleshooting

## 🎯 Supported Spells

The addon supports all Paladin spells, including:
- Holy Light / Flash of Light
- Holy Shield / Holy Strike
- Consecration
- Cleanse
- Blessings (Wisdom, Might, Kings, etc.)
- Seals (Righteousness, Crusader, Wisdom, etc.)
- Judgement
- Hand of Freedom
- Hammer of Justice

## 📦 Supported Librams

- Libram of the Faithful
- Libram of the Farraki Zealot
- Libram of Radiance
- Libram of Light
- Libram of Grace
- Libram of the Dreamguard
- Libram of the Justicar
- Libram of the Resolute
- Libram of the Eternal Tower
- Libram of Final Judgement
- Libram of Hope
- Libram of Fervor
- Libram of Truth
- Libram of Veracity
- Libram of Divinity

## ❓ FAQ

**Q: The addon doesn't load my librams on login?**  
A: Make sure you clicked "Save" after configuring your spells. The profile must be saved to auto-load.

**Q: Dropdowns are empty after `/reload`?**  
A: This means the profile was created before configuring librams. Configure your spells, then click "Save" to overwrite the profile.

**Q: How do I know which profile is active?**  
A: Type `/ssikaprofile` to see the active profile and number of configured spells.

**Q: The addon doesn't swap in combat?**  
A: For safety, the addon won't swap if your cursor has an item or a transaction window is open.

**Q: How do I create multiple profiles (Heal/Tank/PvP)?**  
A: Configure spells for one role, save the profile with a name (e.g., "Heal"). Change configuration, save with another name (e.g., "Tank"). Load the desired profile as needed.

## 🐛 Known Issues

- Swap may fail if you spam the spell too quickly (use the delay setting)
- Some librams require exact name matching (case-sensitive)

## 👨‍💻 Development

This project is open-source. Contributions are welcome!

### File Structure
- `LibramSwap_fixed.lua` : Main swap logic
- `LibramSwapConfig.lua` : User interface (Configuration, Profiles, Sorts Manager)
- `LibramSwap.toc` : Addon manifest

## 📜 Credits

- **Original LibramSwap**: Created by Theo
- **ShikaSwap**: Modified and enhanced by Shikawa

This version is a complete overhaul of the original addon with new features, improved UI, and a robust profile system.

## 📜 License

Free to use and modify.

## 🙏 Acknowledgments

Thanks to the Turtle WoW community for their feedback and suggestions!

---

**Version** : 1.0  
**Author** : Shikawa (based on LibramSwap by Theo)  
**Compatibility** : WoW 1.12 (Vanilla) / Turtle WoW
