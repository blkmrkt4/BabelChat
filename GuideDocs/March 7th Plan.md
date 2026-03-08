# March 7th Plan — Data Consistency & Sync Fixes

## Problem Summary

An audit revealed 10 data consistency issues across onboarding, profile settings, and the matching algorithm. The root causes are:

1. **Dual-format storage** — Onboarding saves canonical enum values; profile editing saves localized display strings. No inverse mapping exists.
2. **Incomplete sync in both directions** — Onboarding calls a minimal sync (8/30 fields). Profile settings saves 9/33 fields. Backend-to-local restore drops ~30% of fields.
3. **Key name fragmentation** — Different parts of the app use different UserDefaults keys for the same data (`gender`/`userGender`, `customDistanceKm`/`maxDistanceKm`, `relationshipIntent`/`relationshipIntents`).

---

## Phase 1: Fix Data Format Consistency (Critical)

These are the root causes — fixing them prevents corrupted data from entering the system.

### Fix 1a: Learning Goals picker — save canonical enum values, not display strings

- **File:** `ProfileSettingsViewController.swift` lines 559-560
- **Problem:** `showLearningGoalsPicker()` saves localized display names (e.g., `"Conversation"`) to UserDefaults under `"learningContexts"` instead of enum raw values (`"casual"`). The conversion function `convertToGoalDisplayName()` is also lossy — `"slang"` and `"casual"` both map to `"conversation"`, `"technical"` and `"formal"` both map to `"professional"`.
- **Fix:** Add an inverse mapping function (`convertFromGoalDisplayName`) that converts selected display names back to `LearningContext.rawValue` strings before writing to UserDefaults. Also unify the goal option sets between onboarding (6 options) and profile settings (7 options) — either add `grammar`, `pronunciation`, `cultural` to the `LearningContext` enum, or remove the extra options from the profile settings picker and use the enum's `displayName` property directly.
- **Recommendation:** Use the `LearningContext` enum as the single source of truth. Build the picker options from `LearningContext.allCases.map { $0.displayName }` and save via `LearningContext(rawValue:)`.

### Fix 1b: Relationship Intent picker — save canonical enum values

- **File:** `ProfileSettingsViewController.swift` lines 503-504
- **Problem:** Same pattern as learning goals — `showRelationshipIntentPicker()` saves localized display names to UserDefaults under `"relationshipIntents"`. Also, `convertToIntentDisplayName()` is missing explicit cases for `"language_exchange"` and `"networking"`, causing them to fall through to fuzzy matching.
- **Fix:** Add an inverse mapping function that converts selected display names back to `RelationshipIntent.rawValue` strings. Build picker options from `RelationshipIntent.allCases.map { $0.displayName }`.
- **Also fix:** `convertToIntentDisplayName()` (lines 520-536) — add explicit cases for `"language_exchange"` and `"networking"`.

### Fix 1c: Gender key — standardize to `"gender"`

- **File:** `MatchingPreferencesViewController.swift` line 977
- **Problem:** OnboardingCoordinator saves to `"gender"` (line 389), but MatchingPreferencesViewController saves to `"userGender"` (line 977). SupabaseService reads from `"gender"` (line 772), so edits via MatchingPreferencesViewController are never picked up.
- **Fix:** Change `"userGender"` to `"gender"` in `saveGenderPreferences()`. Also check that `MatchingPreferencesViewController` reads from `"gender"` on init (line ~92).

### Fix 1d: Distance key — standardize to `"customDistanceKm"`

- **File:** `MatchingPreferencesViewController.swift` line 987
- **Problem:** OnboardingCoordinator saves to `"customDistanceKm"` (line 396), but MatchingPreferencesViewController saves to `"maxDistanceKm"` (line 987). The `MatchingPreferences` model property is `customMaxDistanceKm`. No sync path reads `"maxDistanceKm"`.
- **Fix:** Change `"maxDistanceKm"` to `"customDistanceKm"` in `saveLocationPreferences()`. Also check that the initial value is read from `"customDistanceKm"` (line ~106).

---

## Phase 2: Complete the Save Payload (High)

### Fix 2a: ProfileSettingsViewController.saveToSupabase() — include all editable fields

- **File:** `ProfileSettingsViewController.swift` lines 613-665
- **Problem:** Only saves 9 fields: `firstName`, `lastName`, `bio`, `birthYear`, `birthMonth`, `location`, `city`, `country`, `latitude`, `longitude`, `nativeLanguage`, `learningLanguages`, `strictlyPlatonic`. Missing 24 fields that the user can edit.
- **Fix:** Add all missing preference fields to the `ProfileUpdate` object:
  - `gender`, `genderPreference`
  - `minAge`, `maxAge`
  - `locationPreference`, `preferredCountries`, `excludedCountries`
  - `relationshipIntents` (from `"relationshipIntents"` or `"relationshipIntent"`)
  - `learningContexts`
  - `blurPhotosUntilMatch`
  - `showCityInProfile`
  - `minProficiencyLevel`, `maxProficiencyLevel`
  - `museLanguages`
  - `travelDestination`

### Fix 2b: OnboardingCoordinator — call `syncAllOnboardingDataToSupabase()` instead of minimal

- **File:** `OnboardingCoordinator.swift` line 670
- **Problem:** `syncAndTransition()` calls `syncOnboardingDataToSupabase()` which only sends 8 fields. A comprehensive `syncAllOnboardingDataToSupabase()` already exists (line 729) that handles ~25 fields.
- **Fix:** Change `syncOnboardingDataToSupabase()` to `syncAllOnboardingDataToSupabase()`.
- **Prerequisite:** Verify all referenced database columns exist in Supabase. The minimal method was created to avoid "column not found" errors (see comment at line 728). Check schema before switching.

### Fix 2c: Add `showCityInProfile` to syncAllOnboardingDataToSupabase()

- **File:** `SupabaseService.swift` around line 815
- **Problem:** `syncAllOnboardingDataToSupabase()` syncs `strictlyPlatonic` and `blurPhotosUntilMatch` but not `showCityInProfile`.
- **Fix:** Add: `profileUpdate.showCityInProfile = UserDefaults.standard.bool(forKey: "showCityInProfile")`

---

## Phase 3: Complete the Restore Path (Medium)

### Fix 3a: syncProfileToUserDefaults() — restore missing fields

- **File:** `SupabaseService.swift` lines 576-643
- **Problem:** Only syncs ~20 of ~33 fields from `ProfileResponse` to UserDefaults. Missing: `preferredCountries`, `excludedCountries`, `travelDestination`, `relationshipIntents`, `learningContexts`, `museLanguages`, `city`, `country`, `showCityInProfile`.
- **Fix:** Add the missing fields to `syncProfileToUserDefaults()`:
  ```swift
  // Country preferences
  if let preferredCountries = profile.preferredCountries {
      UserDefaults.standard.set(preferredCountries, forKey: "preferredCountries")
  }
  if let excludedCountries = profile.excludedCountries {
      UserDefaults.standard.set(excludedCountries, forKey: "excludedCountries")
  }

  // Relationship intent
  if let intents = profile.relationshipIntents, !intents.isEmpty {
      UserDefaults.standard.set(intents.first, forKey: "relationshipIntent")
      UserDefaults.standard.set(intents, forKey: "relationshipIntents")
  }

  // Learning contexts
  if let contexts = profile.learningContexts {
      UserDefaults.standard.set(contexts, forKey: "learningContexts")
  }

  // Muse languages
  if let museLanguages = profile.museLanguages {
      UserDefaults.standard.set(museLanguages, forKey: "museLanguages")
  }

  // City and country
  if let city = profile.city {
      UserDefaults.standard.set(city, forKey: "city")
  }
  if let country = profile.country {
      UserDefaults.standard.set(country, forKey: "country")
  }

  // City visibility
  if let showCity = profile.showCityInProfile {
      UserDefaults.standard.set(showCity, forKey: "showCityInProfile")
  }

  // Travel destination
  if let travel = profile.travelDestination {
      // Encode as TravelDestination and save
  }
  ```

### Fix 3b: Add `showCityInProfile` to ProfileResponse

- **File:** `SupabaseService.swift` line 1469
- **Problem:** `ProfileResponse` struct doesn't include `showCityInProfile`. The `toUser()` method hardcodes it to `true` (line 1596).
- **Fix:**
  1. Add `let showCityInProfile: Bool?` to `ProfileResponse`
  2. Add `case showCityInProfile = "show_city_in_profile"` to CodingKeys
  3. Update `toUser()` line 1596: `showCityInProfile: showCityInProfile ?? true`

### Fix 3c: Add missing fields to ProfileResponse

- **File:** `SupabaseService.swift` line 1469
- **Problem:** `ProfileResponse` is missing `excludedCountries`, `museLanguages`, and `customMaxDistanceKm`.
- **Fix:** Add these fields to `ProfileResponse` with appropriate CodingKeys, and pass them through in `createMatchingPreferences()`.

---

## Phase 4: Surface Hidden UI Fields (Medium)

### Fix 4a: Add missing fields to ProfileSettingsViewController sections

- **File:** `ProfileSettingsViewController.swift` lines 22-33
- **Problem:** `ProfileField` enum defines `.relationshipIntent` and `.strictlyPlatonic` with complete implementations (title, icon, placeholder, handler), but they're not included in any `SettingSection.items` array.
- **Fix:** Add them to the `.preferences` section:
  ```swift
  case .preferences:
      return [.learningGoals, .relationshipIntent, .strictlyPlatonic]
  ```

---

## Phase 5: Fix Legacy Mapping (Low)

### Fix 5a: Complete intent display conversion

- **File:** `ProfileSettingsViewController.swift` lines 520-536
- **Problem:** `convertToIntentDisplayName()` handles `"language_practice_only"` (legacy), `"friendship"`, and `"open_to_dating"`, but `"language_exchange"` (current canonical) and `"networking"` fall through to fuzzy default matching.
- **Fix:** Add explicit cases:
  ```swift
  case "language_exchange":
      return "profile_intent_language_exchange".localized
  case "networking":
      return "profile_intent_networking".localized
  ```
- **Note:** If Fix 1b is implemented using enum-based pickers, this function becomes less critical but should still be fixed for reading legacy stored values.

---

## Files Modified (Summary)

| File | Phases |
|------|--------|
| `ProfileSettingsViewController.swift` | 1a, 1b, 2a, 4a, 5a |
| `MatchingPreferencesViewController.swift` | 1c, 1d |
| `OnboardingCoordinator.swift` | 2b |
| `SupabaseService.swift` | 2c, 3a, 3b, 3c |

## Database Prerequisites

Before implementing Phase 2b, verify these columns exist in the Supabase `profiles` table:
- `gender`, `gender_preference`, `min_age`, `max_age`
- `location_preference`, `preferred_countries`, `excluded_countries`
- `travel_destination` (JSONB)
- `relationship_intents` (text[])
- `learning_contexts` (text[])
- `muse_languages` (text[])
- `strictly_platonic`, `blur_photos_until_match`
- `show_city_in_profile`
- `min_proficiency_level`, `max_proficiency_level`
- `proficiency_levels` (JSONB)
- `custom_max_distance_km` (if distance is to be persisted)

## Testing Strategy

- After each phase, build and run in Simulator
- After Phase 1: Verify profile settings saves/reads enum raw values via console logs
- After Phase 2: Check Supabase dashboard to confirm all fields are populated after onboarding
- After Phase 3: Force-quit app, relaunch, verify UserDefaults are restored from backend
- After Phase 4: Verify relationship intent and strictly platonic appear in settings UI
- After Phase 5: Test with legacy `"language_practice_only"` values in database
