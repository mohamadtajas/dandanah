use crate::db::Database;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use tauri::{AppHandle, Emitter};
use tauri_plugin_global_shortcut::{GlobalShortcutExt, Shortcut, ShortcutState};

pub const SETTING_KEY: &str = "hotkeys";

pub const DEFAULT_TOGGLE: &str = "Ctrl+Alt+Space";
pub const DEFAULT_NEXT: &str = "Ctrl+Alt+ArrowRight";
pub const DEFAULT_PREVIOUS: &str = "Ctrl+Alt+ArrowLeft";

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct HotkeyMap {
    pub toggle: String,
    pub next: String,
    pub previous: String,
}

impl Default for HotkeyMap {
    fn default() -> Self {
        Self {
            toggle: DEFAULT_TOGGLE.into(),
            next: DEFAULT_NEXT.into(),
            previous: DEFAULT_PREVIOUS.into(),
        }
    }
}

impl HotkeyMap {
    fn entries(&self) -> [(&'static str, &str); 3] {
        [
            ("toggle", &self.toggle),
            ("next", &self.next),
            ("previous", &self.previous),
        ]
    }

    /// Rejects malformed accelerators and two actions bound to the same keys.
    pub fn validate(&self) -> Result<(), String> {
        let mut seen: Vec<u32> = Vec::new();
        for (action, accelerator) in self.entries() {
            let accelerator = accelerator.trim();
            if accelerator.is_empty() {
                continue;
            }
            let shortcut = Shortcut::from_str(accelerator)
                .map_err(|error| format!("{action}: {error}"))?;
            if seen.contains(&shortcut.id()) {
                return Err(format!("duplicate shortcut: {accelerator}"));
            }
            seen.push(shortcut.id());
        }
        Ok(())
    }
}

pub fn load(db: &Database) -> HotkeyMap {
    db.get_setting(SETTING_KEY)
        .ok()
        .flatten()
        .and_then(|raw| serde_json::from_str(&raw).ok())
        .unwrap_or_default()
}

pub fn save(db: &Database, map: &HotkeyMap) -> Result<(), String> {
    let json = serde_json::to_string(map).map_err(|error| error.to_string())?;
    db.set_setting(SETTING_KEY, &json)
        .map_err(|error| error.to_string())
}

/// Replaces every registered shortcut with `map`. An empty accelerator disables
/// that action.
pub fn apply(app: &AppHandle, map: &HotkeyMap) -> Result<(), String> {
    map.validate()?;
    let manager = app.global_shortcut();
    manager
        .unregister_all()
        .map_err(|error| format!("could not clear shortcuts: {error}"))?;

    for (action, accelerator) in map.entries() {
        let accelerator = accelerator.trim();
        if accelerator.is_empty() {
            continue;
        }
        let shortcut =
            Shortcut::from_str(accelerator).map_err(|error| format!("{action}: {error}"))?;
        let label = action.to_string();
        let action = label.clone();
        manager
            .on_shortcut(shortcut, move |app, _, event| {
                if event.state == ShortcutState::Pressed {
                    let _ = app.emit("player:command", action.clone());
                }
            })
            .map_err(|error| format!("{label}: {error}"))?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_are_valid_accelerators() {
        HotkeyMap::default().validate().unwrap();
    }

    #[test]
    fn duplicate_bindings_are_rejected() {
        let map = HotkeyMap {
            toggle: "Ctrl+Alt+K".into(),
            next: "Ctrl+Alt+K".into(),
            previous: "Ctrl+Alt+J".into(),
        };
        assert!(map.validate().is_err());
    }

    #[test]
    fn empty_bindings_are_allowed() {
        let map = HotkeyMap {
            toggle: String::new(),
            next: "Ctrl+Alt+ArrowRight".into(),
            previous: String::new(),
        };
        map.validate().unwrap();
    }

    #[test]
    fn garbage_is_rejected() {
        let map = HotkeyMap {
            toggle: "Ctrl+NotAKey".into(),
            ..HotkeyMap::default()
        };
        assert!(map.validate().is_err());
    }
}
