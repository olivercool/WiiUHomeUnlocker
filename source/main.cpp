// Force Home Menu - WUPS / Aroma plugin for Wii U
//
// Core logic (universal across titles):
//  - Hook a PROC_UI export that games use to disable the Home Button and
//    force it to stay enabled whenever our toggle is ON.

#include <wups.h>
#include <wups/meta.h>
#include <wups/config/WUPSConfig.h>
#include <wups/config/WUPSConfigItemBoolean.h>

// System headers (WUT / Wii U)
#include <wiiu/proc_ui.h>
#include <wiiu/os.h>

// Basic plugin metadata
WUPS_PLUGIN_NAME("Force Home Menu");
WUPS_PLUGIN_DESCRIPTION("Force the Wii U Home Menu to remain available in heavy titles.");
WUPS_PLUGIN_VERSION("0.1.0");
WUPS_PLUGIN_AUTHOR("ForceHomeMenu Logic");
WUPS_PLUGIN_LICENSE("GPLv3");

// Global toggle that other code / agents can reference.
// Default is false (Off) until user enables it in Aroma menu.
bool g_enableForceHomeMenu = false;

extern "C" {
    // Prototype for the PROC_UI function some games use to disable Home Button.
    // Adjust the name / signature when you have the exact symbol.
    typedef int32_t (*PROCUISetHomeButtonDisabled_t)(bool disabled);
}


// === Hook 1: Override attempts to disable the Home Button =================

DECL_FUNCTION(int32_t,
              PROCUISetHomeButtonDisabled,
              bool disabled) {
    // If our feature is disabled, behave like the game expects.
    if (!g_enableForceHomeMenu) {
        return real_PROCUISetHomeButtonDisabled(disabled);
    }

    // When enabled, always keep Home Button enabled.
    (void)disabled;
    return real_PROCUISetHomeButtonDisabled(false);
}

WUPS_MUST_REPLACE(PROCUISetHomeButtonDisabled,
                  WUPS_LOADER_LIBRARY_PROCUI,
                  PROCUISetHomeButtonDisabled);


// Plugin lifecycle hooks (optional but kept for completeness)
INITIALIZE_PLUGIN() {
    // Nothing special to initialize for now.
}

DEINITIALIZE_PLUGIN() {
    // Nothing special to clean up for now.
}


// === WUPS configuration menu ================================================

// Callback for when the user toggles "Enable Force Home Menu".
static void OnForceHomeMenuChanged(WUPSConfigItemBooleanHandle handle, bool value) {
    (void)handle;
    g_enableForceHomeMenu = value;
}

// Expose a configuration UI accessible via the standard Aroma combo:
//   L + D-Pad Down + Select
WUPS_GET_CONFIG() {
    WUPSConfigHandle config;
    WUPSConfigCategoryHandle mainCategory;
    WUPSConfigItemBooleanHandle forceHomeItem;

    // Create root config (display name in Aroma menu)
    if (WUPSConfig_Create(&config, "WiiHomeMod") != WUPSCONFIG_RESULT_SUCCESS) {
        return 0;
    }

    // Add a general category
    if (WUPSConfig_AddCategory(config, "General", &mainCategory) != WUPSCONFIG_RESULT_SUCCESS) {
        WUPSConfig_Destroy(config);
        return 0;
    }

    // Boolean item: "Enable Force Home Menu", default Off (false)
    if (WUPSConfigItemBoolean_Create(
            &forceHomeItem,
            "enable_force_home_menu",   // internal key
            "Enable Force Home Menu",   // visible label
            g_enableForceHomeMenu,      // initial value (false by default)
            OnForceHomeMenuChanged)     // callback on change
        != WUPSCONFIG_RESULT_SUCCESS) {
        WUPSConfig_Destroy(config);
        return 0;
    }

    if (WUPSConfigCategory_AddItem(mainCategory, forceHomeItem) != WUPSCONFIG_RESULT_SUCCESS) {
        WUPSConfig_Destroy(config);
        return 0;
    }

    return config;
}


