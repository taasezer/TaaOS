# TaaOS Complete Visual System Documentation

This document describes EVERY visual element of TaaOS.

## Theme System Architecture

```
TaaTheme Engine (taatheme)
    ↓
┌─────────────────────────────────────────────┐
│  Theme Files                                │
├─────────────────────────────────────────────┤
│  • Qt Stylesheet (.qss)                     │
│  • GTK3 Theme (.css)                        │
│  • Plasma Color Scheme (.colors)            │
│  • Icon Mappings (index.theme)              │
│  • Cursor Theme                             │
│  • Window Decorations                       │
│  • Notification Style                       │
│  • Sound Theme                              │
└─────────────────────────────────────────────┘
    ↓
Applied to ALL applications system-wide
```

## Color Palette

### Primary Colors
- **Rosso Corsa** (Ferrari Red): `#D40000`
  - Light variant: `#FF3333`
  - Dark variant: `#8B0000`
  
- **Off-White**: `#F5F5F0`
  - For text and UI elements
  
- **Pure Black**: `#0A0A0A`
  - Main background
  
- **Surface**: `#1A1A1A`
  - Cards, panels, elevated surfaces
  
- **Surface Light**: `#2B2B2B`
  - Hover states, borders

### Accent Colors
- Success: `#00CC66` (green)
- Warning: `#FFA500` (orange)
- Error: `#FF0000` (bright red)
- Info: `#4A90E2` (blue)

### Text Colors
- Primary text: `#F5F5F0`
- Secondary text: `#808080`
- Disabled text: `#606060`

## Visual Components

### 1. Wallpapers

#### Desktop Wallpaper
**Location**: `taaos/branding/wallpapers/taaos-dark.png`
- 4K resolution
- Dark minimalist design
- Rosso Corsa geometric patterns
- Subtle triangle shapes (Arch-inspired)
- Ferrari racing aesthetic

#### Lock Screen
**Location**: `taaos/branding/wallpapers/taaos-lockscreen.png`
- Dark gradient background
- Centered TaaOS logo with glow
- Premium, cinematic feel
- Clean and minimal

#### Alternative Wallpapers (5 total)
1. **Rosso Corsa** - Default dark with red geometry
2. **Midnight** - Pure black minimalist
3. **Arctic** - Blue accents on dark
4. **Graphite** - Grey geometric patterns
5. **Carbon Fiber** - Subtle texture pattern

### 2. Qt Theme (All Qt Applications)

**File**: `taaos/taatheme/styles/rosso-corsa.qss`

Styled Components:
- ✅ Main Windows - Dark with Rosso Corsa accents
- ✅ Menu Bar - Elevated with red bottom border
- ✅ Menus - Rounded, smooth hover states
- ✅ Toolbars - Seamless integration
- ✅ Push Buttons - Gradient Rosso Corsa
- ✅ Line Edit - Glowing red focus
- ✅ Text Edit - Clean, minimal
- ✅ Combo Box - Dropdown styled
- ✅ Spin Box - Custom arrows
- ✅ Sliders - Red track and handle
- ✅ Progress Bars - Gradient animation
- ✅ Check Boxes - Red checked state
- ✅ Radio Buttons - Circular red dot
- ✅ List Widgets - Smooth selection
- ✅ Tree Widgets - Expandable branches
- ✅ Table Widgets - Grid with red header
- ✅ Tab Widgets - Modern tab style
- ✅ Scroll Bars - Thin, rounded, red
- ✅ Tooltips - Red border
- ✅ Status Bar - Red top border
- ✅ Group Box - Red title background
- ✅ Dialogs - Consistent theming
- ✅ Splitters - Red handle
- ✅ Dock Widgets - Dockable panels
- ✅ Calendar - Date picker styled

**Features**:
- Smooth 0.3s transitions on all elements
- Hover states with color shifts
- Focus indicators with red glow
- Disabled states with grey
- Consistent 5px border radius
- 2px borders on focused elements

### 3. GTK3 Theme (GTK Applications)

**File**: `taaos/taatheme/styles/gtk-rosso-corsa.css`

Styled GTK Components:
- ✅ Windows
- ✅ Buttons with gradient
- ✅ Entry fields
- ✅ Header bars
- ✅ Menu bars and menus
- ✅ Toolbars
- ✅ Scroll bars
- ✅ Notebooks (tabs)
- ✅ Progress bars with gradient
- ✅ Switches
- ✅ Check buttons
- ✅ Radio buttons
- ✅ Tooltips
- ✅ Tree views
- ✅ Status bars

**Features**:
- Uses GTK3 CSS syntax
- Defines color variables
- Inherits some Breeze Dark elements
- Overrides with TaaOS colors

### 4. KDE Plasma Theme

#### Color Scheme
**File**: `plasma-rosso-corsa.colors`

Sections:
- View colors (backgrounds, selections)
- Window colors (title bars, borders)
- Button colors (normal, hover, pressed)
- Selection colors
- Tooltip colors
- Complementary colors

#### Plasma Desktop Theme
**Components**:
- Panel backgrounds (translucent dark)
- System tray (Rosso Corsa icons)
- Task manager (red active indicators)
- Application launcher (red accents)
- Widgets (themed backgrounds)
- Window decorations

#### Effects Configuration
**File**: `kwinrc`

Active Effects:
- ✅ **Blur** - Strength 15 (translucency effects)
- ✅ **Glide** - Window slide animation
- ✅ **Magic Lamp** - Minimize animation
- ✅ **Scale** - Window scale effect
- ✅ **Desktop Grid** - Virtual desktop switcher
- ✅ **Present Windows** - Exposé-like view
- ✅ **Wobbly Windows** - Elastic windows
- ✅ **Fade** - Smooth transitions
- ✅ **Sliding Popups** - Menu animations
- ✅ **Window Aperture** - Rounded corners

**Animation Settings**:
- Duration: 200-300ms
- Speed: Medium-fast
- OpenGL backend with VSync
- 60 FPS cap
- Smooth curves

### 5. Icon Theme

**Location**: `taaos/branding/icons/taaos-icons/`

**Base**: Inherits from Breeze Dark
**Customizations**: Rosso Corsa accents

Icon Categories:
- **Actions** (16, 22, 24px) - UI actions
- **Apps** (48, 64px, scalable) - Application icons
- **Places** (48px, scalable) - Folders, locations
- **Devices** (48px, scalable) - Hardware
- **Status** (22px) - System status
- **Mimes** - File types

**Custom TaaOS Icons**:
- `taaos-logo.svg` - Main logo (T-shaped triangle)
- `taaos-taapac.svg` - Package manager
- `taaos-update.svg` - System update
- `taaos-security.svg` - Security shield
- `taaos-monitor.svg` - System monitor
- `taaos-settings.svg` - Settings gear
- `taaos-terminal.svg` - Terminal icon
- `taaos-files.svg` - File manager

### 6. Cursor Theme

**Location**: `taaos/branding/cursors/taaos-cursors/`

**Style**: Based on Breeze with Rosso Corsa accents

Cursor Types:
- default (arrow)
- pointer (hand)
- wait (watch)
- text (I-beam)
- crosshair
- move (4-way arrows)
- resize (bidirectional)
- not-allowed (circle with slash)
- help (question mark)
- progress (arrow + watch)

**Sizes Available**:
- Small: 24px
- Medium: 32px (default)
- Large: 48px
- Huge: 64px

**Colors**:
- Primary: Off-white `#F5F5F0`
- Accent: Rosso Corsa `#D40000`
- Shadow: Black with transparency

### 7. Window Decorations

**File**: `window-decorations.conf`

**Title Bar**:
- Height: 32px
- Background: Dark gradient
- Active: `#1A1A1A` → `#0A0A0A`
- Inactive: `#0A0A0A` (flat)
- Font: Inter Bold 10pt
- Icon + Title + Buttons layout

**Window Buttons**:
- Close: Red `#FF0000` (hover: `#FF3333`)
- Minimize: Orange `#FFA500`
- Maximize: Green `#00CC66`
- Size: 18px
- Spacing: 2px
- Border radius: 3px

**Window Border**:
- Active: Red glow `#D40000`
- Inactive: Dark grey `#2B2B2B`
- Width: 1px
- Glow radius: 10px (active only)

**Window Shadow**:
- Active: 30px radius, 5px offset, 70% opacity
- Inactive: 20px radius, 3px offset, 40% opacity

**Corners**:
- Top: 8px radius (rounded)
- Bottom: 0px (square, for better stacking)

### 8. Notification Theme

**File**: `notifications.conf`

**Appearance**:
- Background: `#1A1A1A`
- Border: 2px Rosso Corsa `#D40000`
- Border radius: 10px
- Padding: 15px
- Shadow: 15px blur, 5px offset
- Opacity: 95%

**Position**: Top-right corner
**Timeout**: 5 seconds
**Max visible**: 3 notifications

**Icons**:
- Critical: Red `#FF0000`
- Warning: Orange `#FFA500`
- Info: Blue `#4A90E2`
- Success: Green `#00CC66`
- Size: 48px

**Animations**:
- Show: Slide from right (300ms)
- Hide: Fade out (300ms)

**Action Buttons**:
- Background: Rosso Corsa
- Hover: Light red
- Text: Off-white
- Padding: 8px 15px
- Border radius: 5px

**Progress Bar** (for ongoing operations):
- Bar color: Rosso Corsa
- Background: Dark grey
- Height: 6px
- Radius: 3px

### 9. Sound Theme

**Location**: `taaos/branding/sounds/taaos-sounds/`

Sound Files (.ogg):
- `login.ogg` - Desktop login
- `logout.ogg` - Desktop logout
- `message.ogg` - New message/notification
- `sent.ogg` - Message sent confirmation
- `bell.ogg` - System bell
- `trash-empty.ogg` - Trash emptied
- `package-success.ogg` - Package installed
- `package-error.ogg` - Installation failed
- `security-alert.ogg` - Guardian alert
- `system-ready.ogg` - Boot complete
- `suspend.ogg` - System suspend
- `resume.ogg` - System resume
- `volume.ogg` - Volume changed
- `battery-low.ogg` - Low battery
- `battery-critical.ogg` - Critical battery
- `network-connected.ogg` - Network up
- `network-disconnected.ogg` - Network down

**Characteristics**:
- Short (< 1 second)
- Pleasant, non-intrusive
- Clear audio feedback
- Rosso Corsa themed (racing-inspired)

### 10. Boot & Login Visuals

#### Plymouth Splash
**File**: `taaos-splash.png`
- Black background
- Large Rosso Corsa TaaOS logo (center)
- Animated loading dots (red)
- Minimal, clean design
- 1920x1080 resolution

#### SDDM Login Screen
**Theme**: `taaos-sddm`

Elements:
- Background: Lock screen wallpaper
- Login box: Dark with red border
- Username/Password fields: Rosso Corsa focus
- Session selector: Dropdown styled
- Power buttons: Icon only, red on hover
- Clock: Top-right, minimalist
- Logo: TaaOS logo above login

**Colors**:
- Background overlay: `#0A0A0A` 30% opacity
- Login box: `#1A1A1A`
- Input fields: `#0A0A0A` with red border
- Buttons: Rosso Corsa gradient
- Text: Off-white

### 11. Application-Specific Themes

#### Konsole Terminal
- Background: Pure black `#0A0A0A`
- Text: Off-white `#F5F5F0`
- Selection: Rosso Corsa `#D40000`
- Cursor: Rosso Corsa block
- Tab bar: Dark with red active tab
- Font: JetBrains Mono 11pt

#### VSCode/VSCodium
**Theme**: "TaaOS Rosso Corsa"
- Editor background: `#0A0A0A`
- Sidebar: `#1A1A1A`
- Activity bar: `#1A1A1A` with red accents
- Status bar: `#D40000`
- Selection: `#D40000` 30% opacity
- Syntax highlighting: Custom with red keywords

#### Firefox (User CSS)
- Dark theme base
- Red accent color
- Tab bar: Dark with red active tab
- Address bar: Dark with red focus
- Sidebar: Dark themed

#### File Manager (Dolphin)
- Sidebar: Dark
- Main view: Dark with red selection
- Path bar: Red current folder
- Status bar: Dark with red info

## Visual Effects Summary

### Animations
- Window open/close: 250ms scale
- Minimize: Magic lamp effect
- Desktop switch: Glide transition
- Menu popups: Slide + fade (150ms)
- Button hover: Color shift (0.3s)
- Focus changes: Glow effect (0.2s)

### Transparency
- Panel: 90% opacity
- Inactive windows: Slight dimming
- Notifications: 95% opacity
- Menus: 98% opacity
- Tooltips: 95% opacity

### Shadows
- Active windows: Large, strong
- Inactive windows: Smaller, subtle
- Notifications: Medium blur
- Menus: Small, sharp
- Tooltips: Very subtle

### Blur
- Behind panels: 15px blur
- Behind menus: 10px blur
- Behind notifications: 15px blur
- KWin blur effect: Enabled

## Consistency Rules

### Border Radius
- Small elements (buttons): 5px
- Medium elements (inputs, cards): 5-8px
- Large elements (windows): 8px top, 0px bottom
- Notifications: 10px
- Cursors: Varied by type

### Spacing
- Button padding: 10px 20px
- Input padding: 8px 12px
- Panel margins: 5-10px
- Icon spacing: 5-10px
- List item padding: 10px

### Typography
- Headers: Inter Bold
- Body: Inter Regular
- Code: JetBrains Mono
- Sizes: 10-14pt (UI), 11-13pt (code)

### Transitions
- Fast: 150ms (tooltips, hover)
- Medium: 200-300ms (animations)
- Slow: 500ms (complex animations)

## Theme Application

### System-Wide Theme Command
```bash
taatheme apply rosso-corsa
```

This applies:
1. Qt stylesheet to all Qt apps
2. GTK3 theme to all GTK apps
3. Plasma color scheme
4. Icon theme
5. Cursor theme  
6. Window decorations
7. Notification style
8. Sound theme
9. Wallpapers
10. SDDM theme

### Per-Application
Each app respects the system theme automatically through:
- Qt: QSS file loaded globally
- GTK: `~/.config/gtk-3.0/settings.ini`
- Plasma: KDE settings
- Terminal: Profile configuration

## Visual Quality Targets

- ✅ **Consistency**: All apps look cohesive
- ✅ **Performance**: Smooth 60fps animations
- ✅ **Accessibility**: High contrast, readable
- ✅ **Modern**: 2024 design trends
- ✅ **Professional**: Production-ready polish
- ✅ **Branded**: Unmistakably TaaOS
- ✅ **Minimal**: Arch-style simplicity
- ✅ **Premium**: Ferrari-level quality

---

**TaaOS Visual System - Complete** ✅

Every pixel is Rosso Corsa themed, from kernel boot to desktop shutdown.

**Developer power, Ferrari style** 🏎️
