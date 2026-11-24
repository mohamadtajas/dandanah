//! Adhkar content verification and the daily adhkar streak.
//!
//! The texts and repeat counts are bundled as JSON generated from the
//! MIT-licensed Hisn al-Muslim transcription (see `data/README.md`). The
//! tests here pin the source counts so a regeneration cannot silently drift.

use chrono::{Duration, NaiveDate};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

pub const MORNING: &str = "morning";
pub const EVENING: &str = "evening";

/// One day of adhkar completion. A day counts for the streak when either the
/// morning or the evening set is finished.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AdhkarDay {
    pub date: String,
    pub morning: bool,
    pub evening: bool,
}

impl AdhkarDay {
    pub fn empty(date: impl Into<String>) -> Self {
        Self {
            date: date.into(),
            morning: false,
            evening: false,
        }
    }

    pub fn qualifies(&self) -> bool {
        self.morning || self.evening
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AdhkarProgress {
    pub date: String,
    pub category_id: String,
    pub item_id: String,
    /// Repetitions still owed for this item.
    pub remaining: u32,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AdhkarStreak {
    pub current: u32,
    pub best: u32,
    pub today_morning: bool,
    pub today_evening: bool,
}

/// Consecutive-day adhkar streak. An unfinished today does not break a streak
/// that is still running; morning or evening completion makes a day count.
pub fn compute_adhkar_streak(days: &[AdhkarDay], today: NaiveDate) -> AdhkarStreak {
    let mut by_date: BTreeMap<NaiveDate, &AdhkarDay> = BTreeMap::new();
    for day in days {
        if let Ok(date) = NaiveDate::parse_from_str(&day.date, "%Y-%m-%d") {
            by_date.insert(date, day);
        }
    }

    let qualifies = |date: NaiveDate| {
        by_date
            .get(&date)
            .map(|day| day.qualifies())
            .unwrap_or(false)
    };

    let mut cursor = if qualifies(today) {
        today
    } else {
        today - Duration::days(1)
    };
    let mut current: u32 = 0;
    while qualifies(cursor) {
        current += 1;
        cursor -= Duration::days(1);
    }

    let mut best: u32 = 0;
    let mut run: u32 = 0;
    let mut previous: Option<NaiveDate> = None;
    for (&date, day) in &by_date {
        if day.qualifies() {
            run = if previous == Some(date - Duration::days(1)) {
                run + 1
            } else {
                1
            };
            best = best.max(run);
        } else {
            run = 0;
        }
        previous = Some(date);
    }

    let today_day = by_date.get(&today);
    AdhkarStreak {
        current,
        best,
        today_morning: today_day.map(|day| day.morning).unwrap_or(false),
        today_evening: today_day.map(|day| day.evening).unwrap_or(false),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::Value;
    use std::collections::HashSet;
    use std::path::Path;

    fn data() -> Value {
        let path = Path::new(env!("CARGO_MANIFEST_DIR")).join("../src/lib/data/adhkar.json");
        let raw = std::fs::read_to_string(&path)
            .unwrap_or_else(|error| panic!("read {}: {error}", path.display()));
        serde_json::from_str(&raw).expect("adhkar.json is valid JSON")
    }

    fn category<'a>(data: &'a Value, id: &str) -> &'a Value {
        data["categories"]
            .as_array()
            .expect("categories array")
            .iter()
            .find(|category| category["id"] == id)
            .unwrap_or_else(|| panic!("missing category {id}"))
    }

    #[test]
    fn bundled_adhkar_keep_source_counts() {
        let data = data();
        // item count / total repeats, verified against the source categories.
        for (id, expected_items, expected_repeats) in [
            ("morning", 24, 358),
            ("evening", 22, 257),
            ("sleep", 15, 116),
            ("waking", 4, 4),
            ("after-prayer", 8, 17),
        ] {
            let items = category(&data, id)["items"].as_array().expect("items");
            assert_eq!(items.len(), expected_items, "{id} item count");

            let mut repeats = 0;
            for item in items {
                let text = item["text"].as_str().expect("text");
                let reference = item["reference"].as_str().expect("reference");
                let count = item["count"].as_i64().expect("count");
                assert!(!text.trim().is_empty(), "{id} has an empty text");
                assert!(!reference.trim().is_empty(), "{id} has an empty reference");
                assert!((1..=1000).contains(&count), "{id} has a bad count {count}");
                repeats += count;
            }
            assert_eq!(repeats, expected_repeats, "{id} total repeats");
        }
    }

    #[test]
    fn categories_and_items_have_unique_ids() {
        let data = data();
        let categories = data["categories"].as_array().expect("categories");
        let mut category_ids = HashSet::new();
        let mut item_ids = HashSet::new();
        for category in categories {
            let id = category["id"].as_str().expect("category id");
            assert!(category_ids.insert(id.to_string()), "duplicate category {id}");
            let items = category["items"].as_array().expect("items");
            assert!(!items.is_empty(), "empty category {id}");
            for item in items {
                let item_id = item["id"].as_str().expect("item id");
                assert!(item_ids.insert(item_id.to_string()), "duplicate item {item_id}");
            }
        }
        assert!(
            categories.len() > 120,
            "the full book should be bundled, got {}",
            categories.len()
        );
    }

    fn day(base: NaiveDate, offset: i64, morning: bool, evening: bool) -> AdhkarDay {
        AdhkarDay {
            date: (base - chrono::Duration::days(offset))
                .format("%Y-%m-%d")
                .to_string(),
            morning,
            evening,
        }
    }

    #[test]
    fn adhkar_streak_counts_morning_or_evening() {
        let today = NaiveDate::from_ymd_opt(2026, 11, 26).unwrap();
        let days = vec![
            day(today, 0, true, false),
            day(today, 1, false, true),
            day(today, 2, true, true),
            day(today, 3, false, false),
            day(today, 4, true, false),
        ];
        let streak = compute_adhkar_streak(&days, today);
        assert_eq!(streak.current, 3);
        assert_eq!(streak.best, 3);
        assert!(streak.today_morning);
        assert!(!streak.today_evening);
    }

    #[test]
    fn unfinished_today_does_not_break_the_adhkar_streak() {
        let today = NaiveDate::from_ymd_opt(2026, 11, 26).unwrap();
        let days = vec![day(today, 1, true, false), day(today, 2, false, true)];
        let streak = compute_adhkar_streak(&days, today);
        assert_eq!(streak.current, 2);
        assert!(!streak.today_morning);
    }

    #[test]
    fn a_gap_resets_current_but_best_keeps_the_longest_run() {
        let today = NaiveDate::from_ymd_opt(2026, 11, 26).unwrap();
        let days = vec![
            day(today, 0, true, false),
            day(today, 1, false, false),
            day(today, 2, true, false),
            day(today, 3, true, false),
            day(today, 4, true, false),
            day(today, 6, true, false),
        ];
        let streak = compute_adhkar_streak(&days, today);
        assert_eq!(streak.current, 1);
        assert_eq!(streak.best, 3);
    }

    #[test]
    fn featured_categories_are_present_and_misc_is_curated() {
        let data = data();
        for id in ["morning", "evening", "sleep", "waking", "after-prayer", "misc"] {
            assert!(category(&data, id)["featured"].as_bool().unwrap_or(false), "{id}");
        }
        assert_eq!(
            category(&data, "morning")["streakKey"].as_str(),
            Some("morning")
        );
        assert_eq!(
            category(&data, "evening")["streakKey"].as_str(),
            Some("evening")
        );
        assert!(category(&data, "misc")["items"].as_array().unwrap().len() >= 6);
    }
}
