import FirebaseAnalytics
import Foundation
import os

/// Firebase Analyticsに送る画面名の一覧。
enum FAScreen: String, CaseIterable {
   case home = "home"
   case settings = "settings"
   case textSizeSettings = "text_size_settings"
   case license = "license"
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

/// Firebase Analyticsに送るカスタムイベント名の一覧。
enum FAEventName: String, CaseIterable {
   /// ホームで人物カードをタップして人物詳細へ進んだ。
   case homePersonTapped = "home_person_tapped"
   /// ホームで人を追加する導線をタップした。
   case homeAddPersonTapped = "home_add_person_tapped"
   /// ホームから人を追加しようとして無料上限によりプレミアム案内を表示した。
   case homePremiumGateShown = "home_premium_gate_shown"
   /// ホームでくらべる導線をタップした。
   case homeCompareTapped = "home_compare_tapped"
   /// ホームから設定画面を開いた。
   case settingsOpenedFromHome = "settings_opened_from_home"
   /// レビュー依頼の確認でレビューする側を選んだ。
   case reviewPromptConfirmed = "review_prompt_confirmed"
   /// レビュー依頼の確認でキャンセル側を選んだ。
   case reviewPromptCancelled = "review_prompt_cancelled"

   /// 人物選択画面で人を追加する導線をタップした。
   case personSelectionAddTapped = "person_selection_add_tapped"
   /// 人物選択画面から人を追加しようとして無料上限によりプレミアム案内を表示した。
   case personSelectionPremiumGateShown = "person_selection_premium_gate"
   /// 人物追加・編集画面で写真を選ぶ導線をタップした。
   case personFormPhotoTapped = "person_form_photo_tapped"
   /// 人物追加・編集画面でプリセット画像を選択した。
   case personFormPresetSelected = "person_form_preset_selected"
   /// 人物追加・編集画面で保存ボタンをタップした。
   case personFormSaveTapped = "person_form_save_tapped"
   /// 人物追加・編集画面で保存しようとして無料上限によりプレミアム案内を表示した。
   case personFormPremiumGateShown = "person_form_premium_gate"
   /// 人物編集画面で削除ボタンをタップした。
   case personFormDeleteTapped = "person_form_delete_tapped"
   /// 人物削除確認で削除を確定した。
   case personFormDeleteConfirmed = "person_form_delete_confirmed"
   /// 人物削除確認でキャンセルした。
   case personFormDeleteCancelled = "person_form_delete_cancelled"
   /// 写真ライブラリから人物写真の元画像を読み込めた。
   case personFormPhotoLoaded = "person_form_photo_loaded"
   /// 写真ライブラリから人物写真の元画像を読み込めなかった。
   case personFormPhotoLoadFailed = "person_form_photo_load_failed"
   /// 人物写真のクロップが完了した。
   case personFormPhotoCropped = "person_form_photo_cropped"
   /// 人物写真のクロップまたはサムネイル生成に失敗した。
   case personFormPhotoCropFailed = "person_form_photo_crop_failed"
   /// 人物詳細画面で編集導線をタップした。
   case personDetailEditTapped = "person_detail_edit_tapped"
   /// 人物詳細画面で比較導線をタップした。
   case personDetailCompareTapped = "person_detail_compare_tapped"
   /// 人物詳細画面で好き・嫌いの追加導線をタップした。
   case personDetailAddEntryTapped = "person_detail_add_entry_tapped"
   /// 人物詳細画面で好き・嫌いのすべて見る導線をタップした。
   case personDetailViewAllTapped = "person_detail_view_all_tapped"

   /// 好き・嫌いの入力種別選択画面で種別を選んだ。
   case chooseEntryKindTapped = "choose_entry_kind_tapped"
   /// 好き・嫌い入力画面を閉じた、または画面から離れた。
   case writeEntryDisappeared = "write_entry_disappeared"
   /// 好き・嫌い入力画面のテキストフィールドのフォーカス状態が変わった。
   case writeTextFieldFocusChanged = "write_text_field_focus_changed"
   /// 好き・嫌い入力画面で空文字のまま保存しようとした。
   case writeEntryEmptySubmitted = "write_entry_empty_submitted"
   /// 好き・嫌い入力画面で保存ボタンをタップした。
   case writeEntrySubmitTapped = "write_entry_submit_tapped"
   /// 好き・嫌い一覧画面で一覧広告の表示条件を満たして広告領域が表示された。
   case itemListAdVisible = "item_list_ad_visible"

   /// 設定画面でレビュー導線をタップした。
   case settingsAppReviewTapped = "settings_app_review_tapped"
   /// 設定画面でプレミアム導線をタップした。
   case settingsPremiumTapped = "settings_premium_tapped"
   /// 設定画面で購入復元導線をタップした。
   case settingsRestoreTapped = "settings_restore_tapped"
   /// 設定画面で全データ削除導線をタップした。
   case settingsDeleteAllTapped = "settings_delete_all_tapped"
   /// 全データ削除確認で削除を確定した。
   case settingsDeleteAllConfirmed = "settings_delete_all_confirmed"
   /// 全データ削除確認でキャンセルした。
   case settingsDeleteAllCancelled = "settings_delete_all_cancelled"
   /// デバッグセクションでRevenueCatデバッグ画面を開いた。
   case settingsRevenueCatDebugTapped = "settings_rc_debug_tapped"
   /// 設定画面でアニメーション設定を変更した。
   case settingsAnimationChanged = "settings_animation_changed"
   /// 設定画面で触覚フィードバック設定を変更した。
   case settingsHapticsChanged = "settings_haptics_changed"
   /// 設定画面で文字サイズ設定値が変わった。
   case settingsTextSizeChanged = "settings_text_size_changed"
   /// 文字サイズ選択画面で文字サイズを選んだ。
   case settingsTextSizeSelected = "settings_text_size_selected"

   /// 比較相手選択画面で比較対象の人物を変更した。
   case compareSelectionPersonChanged = "compare_selection_person_changed"
   /// 比較相手選択画面でくらべるボタンをタップした。
   case compareSelectionSubmitTapped = "compare_selection_submit_tapped"
   /// 比較相手選択画面で人を追加する導線をタップした。
   case compareSelectionAddPersonTapped = "compare_selection_add_tapped"
   /// 比較相手選択画面から人を追加しようとして無料上限によりプレミアム案内を表示した。
   case compareSelectionPremiumGateShown = "compare_selection_premium_gate"
   /// 比較結果画面で比較カテゴリの詳細セルをタップした。
   case comparisonCategoryTapped = "comparison_category_tapped"
   /// 比較カテゴリ詳細画面で一覧広告の表示条件を満たして広告領域が表示された。
   case comparisonCategoryAdVisible = "comparison_category_ad_visible"

   /// AdMobバナーを包む表示コンテナが画面に出た。
   case adBannerContainerAppeared = "ad_banner_container_appeared"
   /// AdMobバナー広告の読み込みが成功した。
   case adBannerLoaded = "ad_banner_loaded"
   /// AdMobバナー広告の読み込みが失敗した。
   case adBannerFailed = "ad_banner_failed"

   /// 起動回数を記録した。
   case appLaunchCountRecorded = "app_launch_count_recorded"
   /// 人物データの追加が完了した。
   case personAdded = "person_added"
   /// 人物データの更新が完了した。
   case personUpdated = "person_updated"
   /// 人物データの削除が完了した。
   case personDeleted = "person_deleted"
   /// 好き・嫌い項目の追加保存が完了した。
   case entrySaved = "entry_saved"
   /// 好き・嫌い項目の編集保存が完了した。
   case entryUpdated = "entry_updated"
   /// 好き・嫌い項目の削除が完了した。
   case entryDeleted = "entry_deleted"
   /// 好き・嫌い項目の並び替えが完了した。
   case entryReordered = "entry_reordered"
   /// 全データ削除により好き・嫌い項目をまとめて削除した。
   case allEntriesDeleted = "all_entries_deleted"
   /// 起動回数や登録回数の条件によりレビュー依頼を出した。
   case reviewPromptRequested = "review_prompt_requested"

   /// RevenueCatからプレミアム商品情報の取得を開始した。
   case premiumProductFetchStarted = "premium_product_fetch_started"
   /// RevenueCatからプレミアム商品情報の取得に成功した。
   case premiumProductFetchSucceeded = "premium_product_fetch_succeeded"
   /// RevenueCatで購入可能なプレミアム商品が見つからなかった。
   case premiumProductFetchUnavailable = "premium_product_unavailable"
   /// RevenueCatからプレミアム商品情報の取得に失敗した。
   case premiumProductFetchFailed = "premium_product_fetch_failed"
   /// プレミアム画面で購入ボタンをタップした。
   case premiumPurchaseButtonTapped = "premium_purchase_button_tapped"
   /// RevenueCatのプレミアム購入処理を開始した。
   case premiumPurchaseStarted = "premium_purchase_started"
   /// RevenueCatのプレミアム購入処理が成功した。
   case premiumPurchaseSucceeded = "premium_purchase_succeeded"
   /// RevenueCatのプレミアム購入処理がユーザー操作などでキャンセルされた。
   case premiumPurchaseCancelled = "premium_purchase_cancelled"
   /// RevenueCatのプレミアム購入処理が失敗した。
   case premiumPurchaseFailed = "premium_purchase_failed"
   /// プレミアム画面で購入復元ボタンをタップした。
   case premiumRestoreTapped = "premium_restore_tapped"
   /// RevenueCatの購入復元処理を開始した。
   case premiumRestoreStarted = "premium_restore_started"
   /// RevenueCatの購入復元処理が成功した。
   case premiumRestoreSucceeded = "premium_restore_succeeded"
   /// RevenueCatの購入復元処理がユーザー操作などでキャンセルされた。
   case premiumRestoreCancelled = "premium_restore_cancelled"
   /// 購入復元で有効な購入が見つからなかった。
   case premiumRestoreEmpty = "premium_restore_empty"
   /// RevenueCatの購入復元処理が失敗した。
   case premiumRestoreFailed = "premium_restore_failed"
   /// 旧広告非表示購入からプレミアム相当の復元に成功した。
   case premiumLegacyRestoreSucceeded = "premium_legacy_restore_succeeded"
   /// RevenueCatの現在の権利状態を再取得できた。
   case premiumStatusRefreshed = "premium_status_refreshed"
   /// RevenueCatの現在の権利状態の再取得に失敗した。
   case premiumStatusRefreshFailed = "premium_status_refresh_failed"
   /// RevenueCatから通知されたプレミアム権利状態をアプリに反映した。
   case premiumEntitlementUpdated = "premium_entitlement_updated"
}

/// Firebase Analyticsに送るパラメータキーの一覧。
enum FAParameter: CaseIterable, Hashable {
   /// アプリ内アニメーション設定が有効かどうか。
   case animationEnabled
   /// レイアウト計算時に利用できた横幅。
   case availableWidth
   /// 比較カテゴリや表示分類などのカテゴリ識別子。
   case category
   /// 汎用的な件数。
   case count
   /// 削除した対象の件数。
   case deletedCount
   /// 人物削除などに伴って削除された好き・嫌い項目数。
   case deletedItemCount
   /// 遷移先や操作後に向かう画面・状態。
   case destination
   /// 買い切りプレミアム購入済み状態かどうか。
   case didBuyPremium
   /// 旧広告非表示購入済み状態かどうか。
   case didBuyRemoveAd
   /// ユーザーが入力・保存した好き・嫌い項目の本文。
   case entryText
   /// 好き・嫌い項目の総数。
   case entryCount
   /// SDKやシステムから返されたエラーコード。
   case errorCode
   /// SDKやシステムから返されたエラー説明。
   case errorDescription
   /// SDKやシステムから返されたエラードメイン。
   case errorDomain
   /// 比較対象の1人目がわたしかどうか。
   case firstIsMe
   /// 比較対象の1人目の人物ID。
   case firstPersonID
   /// 編集前から人物写真が設定されているかどうか。
   case hasExistingPhoto
   /// プレミアムまたは旧広告非表示による有効なアクセス権があるかどうか。
   case hasPremiumAccess
   /// フォーム上で新しい写真が選択されているかどうか。
   case hasSelectedPhoto
   /// わたしの嫌い項目数。
   case hateCount
   /// 対象の一覧や状態が空かどうか。
   case isEmpty
   /// 入力欄にフォーカスが当たっているかどうか。
   case isFocused
   /// 触覚フィードバック設定が有効かどうか。
   case isHapticsEnabled
   /// 対象人物がわたしかどうか。
   case isMe
   /// RevenueCat上のプレミアム権利が有効かどうか。
   case isPremium
   /// 対象リスト内の項目数。
   case itemCount
   /// 好き・嫌いなどの入力種別。
   case kind
   /// 特定人物・特定種別内の項目数。
   case kindCount
   /// アプリ起動回数。
   case launchCount
   /// わたしの好き項目数。
   case likeCount
   /// 表示したLottieアニメーション名。
   case lottieName
   /// 追加・編集などの画面モード。
   case mode
   /// 並び替えで移動した項目数。
   case movedCount
   /// 入力された人物名の文字数。
   case nameLength
   /// 登録されている人物数。
   case personCount
   /// 対象人物の人物ID。
   case personID
   /// ユーザーが入力・保存した人物名。
   case personName
   /// 広告やUI要素の表示位置。
   case placement
   /// 変更前の文字サイズ設定。
   case previousTextSize
   /// 購入商品の数値価格。
   case price
   /// RevenueCatから取得した表示用価格文字列。
   case priceText
   /// 購入商品のプロダクトID。
   case productID
   /// 選択・保存されているプリセットプロフィール画像名。
   case profileImage
   /// プロフィール画像がランダム・手動選択・写真・既存状態のどれ由来か。
   case profileImageSource
   /// 分岐や失敗の理由。
   case reason
   /// 既存写真を削除してプリセットへ戻す操作かどうか。
   case removesExistingPhoto
   /// イベントが発生した画面名。
   case screen
   /// 比較対象の2人目がわたしかどうか。
   case secondIsMe
   /// 比較対象の2人目の人物ID。
   case secondPersonID
   /// 選択中の人物ID。
   case selectedPersonID
   /// フォーム上で選択中のプリセットプロフィール画像名。
   case selectedProfileImage
   /// 広告バナーを表示する条件を満たしているかどうか。
   case showsBanner
   /// イベント発生元の導線や画面。
   case source
   /// 操作対象や比較対象の種別。
   case target
   /// 入力・編集されたテキストの文字数。
   case textLength
   /// 現在の文字サイズ設定。
   case textSize
   /// 好き・嫌いを合算した総数。
   case totalCount
   /// レビュー依頼などを発火させた条件やきっかけ。
   case trigger
   /// Firebase Analytics標準のアイテムIDキー。
   case firebaseItemID
   /// Firebase Analytics標準のアイテム名キー。
   case firebaseItemName
   /// Firebase Analytics標準の画面クラスキー。
   case firebaseScreenClass
   /// Firebase Analytics標準の画面名キー。
   case firebaseScreenName

   var key: String {
      switch self {
      case .animationEnabled:
         return "animation_enabled"
      case .availableWidth:
         return "available_width"
      case .category:
         return "category"
      case .count:
         return "count"
      case .deletedCount:
         return "deleted_count"
      case .deletedItemCount:
         return "deleted_item_count"
      case .destination:
         return "destination"
      case .didBuyPremium:
         return "did_buy_premium"
      case .didBuyRemoveAd:
         return "did_buy_remove_ad"
      case .entryText:
         return "entry_text"
      case .entryCount:
         return "entry_count"
      case .errorCode:
         return "error_code"
      case .errorDescription:
         return "error_description"
      case .errorDomain:
         return "error_domain"
      case .firstIsMe:
         return "first_is_me"
      case .firstPersonID:
         return "first_person_id"
      case .hasExistingPhoto:
         return "has_existing_photo"
      case .hasPremiumAccess:
         return "has_premium_access"
      case .hasSelectedPhoto:
         return "has_selected_photo"
      case .hateCount:
         return "hate_count"
      case .isEmpty:
         return "is_empty"
      case .isFocused:
         return "is_focused"
      case .isHapticsEnabled:
         return "is_haptics_enabled"
      case .isMe:
         return "is_me"
      case .isPremium:
         return "is_premium"
      case .itemCount:
         return "item_count"
      case .kind:
         return "kind"
      case .kindCount:
         return "kind_count"
      case .launchCount:
         return "launch_count"
      case .likeCount:
         return "like_count"
      case .lottieName:
         return "lottie_name"
      case .mode:
         return "mode"
      case .movedCount:
         return "moved_count"
      case .nameLength:
         return "name_length"
      case .personCount:
         return "person_count"
      case .personID:
         return "person_id"
      case .personName:
         return "person_name"
      case .placement:
         return "placement"
      case .previousTextSize:
         return "previous_text_size"
      case .price:
         return "price"
      case .priceText:
         return "price_text"
      case .productID:
         return "product_id"
      case .profileImage:
         return "profile_image"
      case .profileImageSource:
         return "profile_image_source"
      case .reason:
         return "reason"
      case .removesExistingPhoto:
         return "removes_existing_photo"
      case .screen:
         return "screen"
      case .secondIsMe:
         return "second_is_me"
      case .secondPersonID:
         return "second_person_id"
      case .selectedPersonID:
         return "selected_person_id"
      case .selectedProfileImage:
         return "selected_profile_image"
      case .showsBanner:
         return "shows_banner"
      case .source:
         return "source"
      case .target:
         return "target"
      case .textLength:
         return "text_length"
      case .textSize:
         return "text_size"
      case .totalCount:
         return "total_count"
      case .trigger:
         return "trigger"
      case .firebaseItemID:
         return AnalyticsParameterItemID
      case .firebaseItemName:
         return AnalyticsParameterItemName
      case .firebaseScreenClass:
         return AnalyticsParameterScreenClass
      case .firebaseScreenName:
         return AnalyticsParameterScreenName
      }
   }
}

/// 好き・嫌い本文を分析パラメータとして送るための整形ルール。
enum FAEntryTextParameter {
   static let maxLength = 100

   static func value(from rawText: String) -> String? {
      let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return nil }
      return String(trimmed.prefix(maxLength))
   }
}

/// 人物名を分析パラメータとして送るための整形ルール。
enum FAPersonNameParameter {
   static let maxLength = PersonNameRules.maxLength

   static func value(from rawName: String) -> String? {
      let sanitized = PersonNameRules.sanitized(rawName)
      guard !sanitized.isEmpty else { return nil }
      return sanitized
   }
}

/// プロフィール画像がどの操作・状態に由来するかを表す分析用分類。
enum FAProfileImageSource: String, CaseIterable {
   case randomPreset = "random_preset"
   case selectedPreset = "selected_preset"
   case selectedPhoto = "selected_photo"
   case existingPreset = "existing_preset"
   case existingPhoto = "existing_photo"
}

/// `FAParameter`をキーにした型付き分析パラメータ。
struct FAParameters: ExpressibleByDictionaryLiteral {
   private var storage: [FAParameter: Any]

   init(_ storage: [FAParameter: Any] = [:]) {
      self.storage = storage
   }

   init(dictionaryLiteral elements: (FAParameter, Any)...) {
      storage = Dictionary(uniqueKeysWithValues: elements)
   }

   subscript(_ parameter: FAParameter) -> Any? {
      get {
         storage[parameter]
      }
      set {
         storage[parameter] = newValue
      }
   }

   /// 既存値に別のパラメータを重ねた新しい値を返す。
   func merging(_ other: FAParameters) -> FAParameters {
      var merged = self
      for (key, value) in other.storage {
         merged.storage[key] = value
      }
      return merged
   }

   /// Firebase Analyticsに渡せる文字列キーの辞書。
   var firebaseParameters: [String: Any] {
      Dictionary(uniqueKeysWithValues: storage.map { parameter, value in
         (parameter.key, value)
      })
   }
}

/// Firebase Analyticsに送るイベントの型付き表現。
enum FAEvent {
   case screenView(FAScreen, parameters: FAParameters)
   case track(FAEventName, parameters: FAParameters?)
   case purchase(productID: String, price: String?, parameters: FAParameters)

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

   /// Firebase Analyticsに渡すイベントパラメータ。
   var parameters: [String: Any]? {
      switch self {
      case .screenView(let screen, let parameters):
         return parameters.merging([
            .firebaseScreenName: screen.rawValue,
            .firebaseScreenClass: screen.rawValue
         ]).firebaseParameters
      case .track(_, let parameters):
         return parameters?.firebaseParameters
      case .purchase(let productID, let price, let parameters):
         var merged = parameters.merging([
            .firebaseItemID: productID,
            .firebaseItemName: "premium_lifetime"
         ])
         if let price {
            merged[.priceText] = price
         }
         return merged.firebaseParameters
      }
   }
}

/// Firebase Analytics送信の入口。
enum FAAnalytics {
   /// 本番ビルドでのみFirebaseへ送信するかどうか。
   static var sendsFirebaseEvents: Bool {
      #if DEBUG
      return false
      #else
      return true
      #endif
   }

   /// DEBUGではログのみ、本番ではFirebase Analyticsへ送信する。
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
