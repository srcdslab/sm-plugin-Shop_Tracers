# Copilot Instructions for Shop_Tracers SourcePawn Plugin

## Repository Overview
This repository contains a SourceMod plugin called "Shop_Tracers" that provides colored bullet tracers for Source engine games. The plugin integrates with a shop system, allowing players to purchase and use different colored bullet tracers. The plugin demonstrates typical SourcePawn development patterns including event handling, client preferences, configuration management, and visual effects.

## Technical Environment

### Language and Platform
- **Language**: SourcePawn (SourceMod scripting language)
- **Platform**: SourceMod 1.11+ for Source engine games
- **Build System**: SourceKnight (version 0.2)
- **CI/CD**: GitHub Actions with automated building and releases

### Dependencies
The plugin depends on these SourceMod extensions and includes:
- `sourcemod` (1.11.0-git6934) - Core SourceMod functionality
- `shop` - Shop system core from `sm-plugin-Shop-Core`
- `multicolors` - Chat color support from `sm-plugin-MultiColors`
- `sdktools` - SourceMod SDK tools
- `clientprefs` - Client preference storage

### Build Configuration
- **Build file**: `sourceknight.yaml` defines project structure and dependencies
- **Output**: Compiled `.smx` files in `/addons/sourcemod/plugins`
- **Dependencies**: Auto-downloaded during build process
- **CI**: Automated builds on push/PR, releases on tags and main branch

## Code Organization

### File Structure
```
addons/sourcemod/
├── scripting/
│   └── Shop_Tracers.sp          # Main plugin source
└── configs/
    └── shop/
        └── tracers.txt          # Configuration for tracer colors and prices
```

### Plugin Architecture
- **Entry Points**: `OnPluginStart()`, `OnPluginEnd()`, `OnMapStart()`
- **Event System**: Hooks `bullet_impact` event for tracer rendering
- **Shop Integration**: Registers with shop system for item management
- **Client Management**: Tracks per-client settings and preferences
- **Configuration**: KeyValues-based config parsing from `tracers.txt`

## SourcePawn Coding Standards

### Style Guidelines
- Use `#pragma semicolon 1` and `#pragma newdecls required` (already implemented)
- Indentation: 4 spaces with tabs
- Variables: `camelCase` for locals, `PascalCase` for functions, `g_` prefix for globals
- **Followed in codebase**: Global variables use `g_` prefix (e.g., `g_bEnabled`, `g_iSprite`)

### Memory Management Best Practices
- **Current pattern**: Plugin uses `CloseHandle()` and `INVALID_HANDLE` checks
- **Recommended upgrade**: Use `delete` operator and `null` checks instead
- **StringMap/ArrayList**: Use `delete` instead of `.Clear()` to prevent memory leaks
- **Handle cleanup**: Always clean up handles in `OnPluginEnd()` or appropriate lifecycle

### Performance Considerations
- **Frequent functions**: `BulletImpact()` is called often - minimize operations
- **Client loops**: Current implementation efficiently filters clients for tracer visibility
- **Caching**: Plugin caches sprite model and client preferences
- **Complexity**: Current O(n) client filtering is acceptable for typical server sizes

## Common Development Patterns

### Event Handling
```sourcepawn
// Plugin demonstrates proper event hooking
HookEvent("bullet_impact", BulletImpact, EventHookMode_Post);

// Event handler with parameter extraction
public void BulletImpact(Event event, char[] name, bool dontBroadcast) {
    int iClient = GetClientOfUserId(event.GetInt("userid"));
    // Process bullet impact for tracer rendering
}
```

### Shop System Integration
```sourcepawn
// Register shop category and items
CategoryId category_id = Shop_RegisterCategory("color_tracers", sName, sDescription);
Shop_SetCallbacks(_, OnTracersUsed);  // Item usage callback

// Handle item activation/deactivation
public ShopAction OnTracersUsed(int iClient, CategoryId category_id, const char[] category, 
                               ItemId item_id, const char[] item, bool isOn, bool elapsed) {
    // Return Shop_UseOn, Shop_UseOff, or Shop_Raw
}
```

### Configuration Management
```sourcepawn
// KeyValues configuration parsing
Kv = CreateKeyValues("Tracers");
Shop_GetCfgFile(buffer, sizeof(buffer), "tracers.txt");
Kv.ImportFromFile(buffer);

// Extract configuration values
Kv.GetString("material", buffer, sizeof(buffer), "materials/sprites/laser.vmt");
Kv.GetColor("color", g_iColor[iClient][0], g_iColor[iClient][1], g_iColor[iClient][2], g_iColor[iClient][3]);
```

### Client Preference Storage
```sourcepawn
// Cookie registration and management
g_hCookie = RegClientCookie("sm_shop_tracers_v2", "1 - enabled, 0 - disabled", CookieAccess_Private);

// Helper functions for boolean cookie handling
bool GetCookieBool(int iClient, Handle hCookie);
void SetCookieBool(int iClient, Handle hCookie, bool bValue);
```

## Development Workflow

### Local Development
1. **Setup**: Clone repository and ensure SourceKnight is available
2. **Dependencies**: Run `sourceknight build` to download dependencies
3. **Compilation**: SourceKnight compiles `.sp` files to `.smx` plugins
4. **Testing**: Deploy to development server for testing

### Configuration Changes
- Modify `tracers.txt` to add/remove tracer colors or adjust prices
- Plugin automatically reloads configuration on map change
- Test configuration syntax with KeyValues validation

### Adding New Features
- **New tracer properties**: Add to KeyValues configuration and parsing logic
- **Client features**: Consider cookie storage for persistent settings
- **Performance**: Profile any changes that affect frequent event handlers
- **Shop integration**: Follow existing callback patterns for new item types

## Testing and Validation

### Manual Testing Approach
- **Server deployment**: Test on development server with multiple clients
- **Feature validation**: Verify tracer colors, visibility settings, shop integration
- **Performance testing**: Monitor server performance during heavy combat
- **Configuration testing**: Validate config file parsing and error handling

### Build Validation
```bash
# CI automatically builds on push/PR
# Local build testing:
sourceknight build

# Check for compilation warnings or errors
# Validate plugin loads without errors in SourceMod
```

### Common Test Scenarios
- Multiple clients with different tracer colors active simultaneously
- Team-based visibility settings (hide_opposite_team configuration)
- Client preference persistence across reconnections
- Shop item purchase, activation, and deactivation flows

## Troubleshooting Common Issues

### Build Issues
- **Dependency errors**: Ensure SourceKnight can download dependencies from GitHub
- **Include path issues**: Verify include files are properly extracted to scripting/include
- **Version conflicts**: Check SourceMod version compatibility

### Runtime Issues
- **Tracer not visible**: Check client visibility preferences and team settings
- **Performance problems**: Profile BulletImpact function execution time
- **Configuration errors**: Validate KeyValues syntax in tracers.txt
- **Shop integration**: Verify shop core plugin is loaded and functional

### Memory Management
- **Handle leaks**: Audit for proper cleanup of KeyValues and other handles
- **Client disconnect cleanup**: Ensure client-specific data is properly reset
- **Map change cleanup**: Verify resources are properly released and recreated

## Release Process

### Versioning
- **Plugin version**: Update in `myinfo` structure in main plugin file
- **Semantic versioning**: Use MAJOR.MINOR.PATCH format
- **Git tags**: Create tags for releases to trigger automated builds

### Automated Release
1. **Push to main/master**: Triggers latest release build
2. **Tag creation**: Triggers versioned release build
3. **Artifact generation**: CI creates packaged plugin with configs
4. **GitHub releases**: Automated upload of build artifacts

### Manual Release Steps
1. Update plugin version in source code
2. Test thoroughly on development server
3. Commit changes and create git tag
4. Verify CI build succeeds and artifacts are created
5. Test deployed release on production server

## Key Files to Modify

### For Code Changes
- `addons/sourcemod/scripting/Shop_Tracers.sp` - Main plugin logic
- `sourceknight.yaml` - Build configuration and dependencies

### For Configuration Changes  
- `addons/sourcemod/configs/shop/tracers.txt` - Tracer colors, prices, and settings

### For Build/CI Changes
- `.github/workflows/ci.yml` - CI/CD pipeline configuration
- `.gitignore` - Exclude build artifacts and temporary files

This repository demonstrates solid SourcePawn development practices and provides a good foundation for understanding shop system integration, client preference management, and visual effect rendering in SourceMod plugins.