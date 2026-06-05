import FirebaseAnalytics
import Foundation
import os

enum FAScreen: String, CaseIterable {
   case home = "home"
   case settings = "settings"
   case textSizeSettings = "text_size_settings"
   case premium = "premium"
   case personSelection = "person_selection"
   case personForm = "person_form"
   case personDetail = "person_detail"
   case chooseEntry = "choose_entry"
   case writeEntry = "write_entry"
   case itemList = "item_list"
   case editItem = "edit_item"
   case compareSelection = "compare_selection"
   case compareResult = "compare_result"
   case comparisonCategoryDetail = "comparison_category_detail"
}

enum FAEventName: String, CaseIterable {
   case homePersonTapped = "home_person_tapped"
   case homeAddPersonTapped = "home_add_person_tapped"
   case homePremiumGateShown = "home_premium_gate_shown"
   case homeCompareTapped = "home_compare_tapped"
   case settingsOpenedFromHome = "settings_opened_from_home"
   case reviewPromptConfirmed = "review_prompt_confirmed"
   case reviewPromptCancelled = "review_prompt_cancelled"

   case personSelectionAddTapped = "person_selection_add_tapped"
   case personSelectionPremiumGateShown = "person_selection_premium_gate"
   case personFormPhotoTapped = "person_form_photo_tapped"
   case personFormPresetSelected = "person_form_preset_selected"
   case personFormSaveTapped = "person_form_save_tapped"
   case personFormPremiumGateShown = "person_form_premium_gate"
   case personFormDeleteTapped = "person_form_delete_tapped"
   case personFormDeleteConfirmed = "person_form_delete_confirmed"
   case personFormDeleteCancelled = "person_form_delete_cancelled"
   case personFormPhotoLoaded = "person_form_photo_loaded"
   case personFormPhotoLoadFailed = "person_form_photo_load_failed"
   case personFormPhotoCropped = "person_form_photo_cropped"
   case personFormPhotoCropFailed = "person_form_photo_crop_failed"
   case personDetailEditTapped = "person_detail_edit_tapped"
   case personDetailCompareTapped = "person_detail_compare_tapped"
   case personDetailAddEntryTapped = "person_detail_add_entry_tapped"
   case personDetailViewAllTapped = "person_detail_view_all_tapped"

   case chooseEntryKindTapped = "choose_entry_kind_tapped"
   case writeEntryDisappeared = "write_entry_disappeared"
   case writeTextFieldFocusChanged = "write_text_field_focus_changed"
   case writeEntryEmptySubmitted = "write_entry_empty_submitted"
   case writeEntrySubmitTapped = "write_entry_submit_tapped"
   case itemListAdVisible = "item_list_ad_visible"

   case settingsAppReviewTapped = "settings_app_review_tapped"
   case settingsPremiumTapped = "settings_premium_tapped"
   case settingsRestoreTapped = "settings_restore_tapped"
   case settingsDeleteAllTapped = "settings_delete_all_tapped"
   case settingsDeleteAllConfirmed = "settings_delete_all_confirmed"
   case settingsDeleteAllCancelled = "settings_delete_all_cancelled"
   case settingsRevenueCatDebugTapped = "settings_rc_debug_tapped"
   case settingsAnimationChanged = "settings_animation_changed"
   case settingsHapticsChanged = "settings_haptics_changed"
   case settingsTextSizeChanged = "settings_text_size_changed"
   case settingsTextSizeSelected = "settings_text_size_selected"

   case compareSelectionPersonChanged = "compare_selection_person_changed"
   case compareSelectionSubmitTapped = "compare_selection_submit_tapped"
   case compareSelectionAddPersonTapped = "compare_selection_add_tapped"
   case compareSelectionPremiumGateShown = "compare_selection_premium_gate"
   case comparisonCategoryTapped = "comparison_category_tapped"
   case comparisonCategoryAdVisible = "comparison_category_ad_visible"

   case adBannerContainerAppeared = "ad_banner_container_appeared"
   case adBannerLoaded = "ad_banner_loaded"
   case adBannerFailed = "ad_banner_failed"

   case appLaunchCountRecorded = "app_launch_count_recorded"
   case personAdded = "person_added"
   case personUpdated = "person_updated"
   case personDeleted = "person_deleted"
   case entrySaved = "entry_saved"
   case entryUpdated = "entry_updated"
   case entryDeleted = "entry_deleted"
   case entryReordered = "entry_reordered"
   case allEntriesDeleted = "all_entries_deleted"
   case reviewPromptRequested = "review_prompt_requested"

   case premiumProductFetchStarted = "premium_product_fetch_started"
   case premiumProductFetchSucceeded = "premium_product_fetch_succeeded"
   case premiumProductFetchUnavailable = "premium_product_unavailable"
   case premiumProductFetchFailed = "premium_product_fetch_failed"
   case premiumPurchaseButtonTapped = "premium_purchase_button_tapped"
   case premiumPurchaseStarted = "premium_purchase_started"
   case premiumPurchaseSucceeded = "premium_purchase_succeeded"
   case premiumPurchaseCancelled = "premium_purchase_cancelled"
   case premiumPurchaseFailed = "premium_purchase_failed"
   case premiumRestoreTapped = "premium_restore_tapped"
   case premiumRestoreStarted = "premium_restore_started"
   case premiumRestoreSucceeded = "premium_restore_succeeded"
   case premiumRestoreCancelled = "premium_restore_cancelled"
   case premiumRestoreEmpty = "premium_restore_empty"
   case premiumRestoreFailed = "premium_restore_failed"
   case premiumLegacyRestoreSucceeded = "premium_legacy_restore_succeeded"
   case premiumStatusRefreshed = "premium_status_refreshed"
   case premiumStatusRefreshFailed = "premium_status_refresh_failed"
   case premiumEntitlementUpdated = "premium_entitlement_updated"
}

enum FAEvent {
   case screenView(FAScreen, parameters: [String: Any])
   case track(FAEventName, parameters: [String: Any]?)
   case purchase(productID: String, price: String?, parameters: [String: Any])

   var name: String {
      switch self {
      case .screenView:
         return AnalyticsEventScreenView
      case .track(let eventName, _):
         return eventName.rawValue
      case .purchase:
         return AnalyticsEventPurchase
      }
   }

   var parameters: [String: Any]? {
      switch self {
      case .screenView(let screen, let parameters):
         return parameters.merging([
            AnalyticsParameterScreenName: screen.rawValue,
            AnalyticsParameterScreenClass: screen.rawValue
         ]) { _, new in new }
      case .track(_, let parameters):
         return parameters
      case .purchase(let productID, let price, let parameters):
         var merged = parameters.merging([
            AnalyticsParameterItemID: productID,
            AnalyticsParameterItemName: "premium_lifetime",
            "price_text": price ?? ""
         ]) { _, new in new }
         if price == nil {
            merged.removeValue(forKey: "price_text")
         }
         return merged
      }
   }
}

enum FAAnalytics {
   static func log(_ event: FAEvent) {
      #if DEBUG
          Logger.analytics.debug(
            "log: \(event.name, privacy: .public) \(String(describing: event.parameters), privacy: .private)"
          )
      #else
          Analytics.logEvent(event.name, parameters: event.parameters)
      #endif
   }
}
