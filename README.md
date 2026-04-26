# GoodMusic

> Ứng dụng nghe nhạc đa nền tảng viết bằng Flutter — hỗ trợ nhạc online (API), nhạc offline trong máy và catalog tĩnh đi kèm app. Có đầy đủ luồng đăng ký / đăng nhập, thư viện cá nhân (yêu thích, gần đây, playlist), trình phát toàn cục với mini player, và giao diện sáng / tối.

Tên hiển thị: **GoodMusic** — Slogan: *"Âm nhạc cho mọi cảm xúc"*.

---

## Mục lục

1. [Tính năng chính](#tính-năng-chính)
2. [Stack & thư viện](#stack--thư-viện)
3. [Kiến trúc & cấu trúc thư mục](#kiến-trúc--cấu-trúc-thư-mục)
4. [Luồng dữ liệu](#luồng-dữ-liệu)
5. [Cài đặt & chạy](#cài-đặt--chạy)
6. [Cấu hình Firebase (tuỳ chọn)](#cấu-hình-firebase-tuỳ-chọn)
7. [Catalog & API nhạc online](#catalog--api-nhạc-online)
8. [Lưu trữ dữ liệu](#lưu-trữ-dữ-liệu)
9. [Tài khoản mặc định & quyền truy cập](#tài-khoản--quyền-truy-cập)
10. [Build release](#build-release)
11. [Lộ trình phát triển](#lộ-trình-phát-triển)
12. [Khắc phục sự cố](#khắc-phục-sự-cố)

---

## Tính năng chính

### Phát nhạc
- Phát nhạc từ **3 nguồn**: file `assets/data/songs.json` đi kèm app, **API local** (`http://10.0.2.2:3001/songs`) cho nhạc online, và **file `.mp3`** trong thư mục `Music` của thiết bị.
- Trình phát dùng `just_audio` với `ConcatenatingAudioSource` → hỗ trợ queue, next / previous mượt.
- **Shuffle** (ngẫu nhiên không lặp bài hiện tại) và **Repeat** 3 chế độ: `off → all → one`.
- **Mini Player toàn cục**: được overlay ở mọi route trừ Splash, các trang Auth và Now Playing.
- **Now Playing** với hiệu ứng đĩa vinyl xoay, lyrics palette tự động trích màu chủ đạo từ ảnh bìa (`palette_generator`), hiệu ứng glassmorphism.
- **Khôi phục phiên cuối**: tự động lưu `last_song_id` + `last_position` mỗi 2 giây và mở lại khi bật ứng dụng (nếu user bật *autoPlayOnStart*).

### Tài khoản & thư viện
- Đăng ký / Đăng nhập / Quên mật khẩu — chạy **local** (file `users.json` trong thư mục riêng app, mật khẩu hash SHA-256). Có thể swap sang Firebase Auth bằng cách thay `AuthService`, giữ nguyên public API.
- Mỗi user có file thư viện riêng `lib_<userId>.json`, gồm:
  - **Favorites** — danh sách bài yêu thích.
  - **Recents** — 30 bài gần đây nhất.
  - **Playlists** — CRUD đầy đủ, mỗi playlist có tên, mô tả, màu và danh sách `songIds`.
- Trang **Profile**: chỉnh tên hiển thị, đổi avatar (theo seed), đổi mật khẩu, xoá tài khoản.

### Khám phá & tìm kiếm
- Trang **Home** với các section: Featured carousel, Categories, Mixes, Suggestions, Albums, Recent.
- Trang **Search** lọc theo tên bài, nghệ sĩ, album và category.
- Trang **Collection Detail** & **Album / Playlist Detail** dùng chung layout, tự đổi màu nền theo ảnh bìa.

### Cài đặt
- Toggle **Light / Dark / System** theme (`ThemeController`).
- Chất lượng cao (`highQuality`), tự động phát khi mở app (`autoPlayOnStart`), ngôn ngữ (`language` — mặc định `vi`).

### UI / Theme
- Material 3 với 2 theme (sáng / tối) + `AppPalette.of(context)` cho colors phụ.
- Hiệu ứng `glassmorphism` cho các card lớn, animated logo trên splash.

---

## Stack & thư viện

| Mục | Phiên bản | Vai trò |
|---|---|---|
| Flutter SDK | `>=3.11.3 <4.0.0` | Framework |
| `provider` | `^6.1.2` | State management (ChangeNotifier) |
| `just_audio` | `^0.9.46` | Phát audio (queue, gapless) |
| `on_audio_query_pluse` | `^3.0.6` | Truy vấn nhạc trên thiết bị |
| `permission_handler` | `^11.4.0` | Xin quyền đọc Media |
| `shared_preferences` | `^2.3.2` | Lưu session + tiến trình + settings |
| `path_provider` | `^2.1.5` | Thư mục lưu file JSON (`goodmusic/`) |
| `http` | `^1.2.2` | Gọi API nhạc online |
| `crypto` | `^3.0.3` | Hash password (SHA-256) |
| `uuid` | `^4.5.1` | Sinh `id` cho user / playlist |
| `cached_network_image` | `^3.4.1` | Cache ảnh bìa |
| `palette_generator` | `^0.3.3+7` | Trích màu chủ đạo từ ảnh |
| `glassmorphism` | `^3.0.0` | Hiệu ứng kính mờ |
| `firebase_core` | `^3.6.0` | Khởi tạo Firebase (tuỳ chọn) |

---

## Kiến trúc & cấu trúc thư mục

Layered architecture: **features** dựa vào **data** (services + repositories) và **core** (theme / widgets / utils / routes).

```
lib/
├── main.dart                    # Bootstrap MultiProvider, init Firebase
├── app.dart                     # MaterialApp + global mini player overlay
├── firebase_options.dart        # Sinh ra bởi flutterfire configure
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart      # Hằng số màu thương hiệu
│   │   ├── app_theme.dart       # ThemeData light / dark + AppPalette
│   │   └── theme_controller.dart# ChangeNotifier theme mode
│   ├── routes/
│   │   └── route_tracker.dart   # NavigatorObserver — theo dõi route hiện tại
│   ├── utils/
│   │   ├── hash.dart            # hashPassword(SHA-256)
│   │   ├── format.dart          # Định dạng duration / số nghe
│   │   └── validators.dart      # Validate email / password
│   └── widgets/
│       ├── animated_logo.dart
│       ├── app_text_field.dart
│       ├── empty_state.dart
│       ├── glass_card.dart
│       ├── mini_player.dart
│       ├── primary_button.dart
│       └── song_tile.dart
│
├── data/
│   ├── models/
│   │   ├── song_model.dart      # SongModel + Category/Featured/Mix/Suggestion/Album
│   │   ├── playlist_model.dart
│   │   └── user_model.dart
│   ├── services/
│   │   ├── audio_player_service.dart  # Wrap just_audio: queue, shuffle, repeat
│   │   ├── auth_service.dart          # Auth local (users.json)
│   │   ├── catalog_service.dart       # Load nhạc từ assets + API + máy
│   │   ├── settings_service.dart      # AppSettings (HQ / autoPlay / lang)
│   │   └── storage_service.dart       # Đọc/ghi JSON trong goodmusic/
│   └── repositories/
│       └── library_repository.dart    # Favorites / Recents / Playlists
│
└── features/
    ├── splash/                  # Bootstrap + redirect login/home
    ├── auth/                    # login / register / forgot_password
    ├── home/                    # home_shell (bottom nav) + home_page + collection_detail
    ├── search/
    ├── library/                 # library + playlist_detail + form_dialog
    ├── player/                  # now_playing + vinyl_disc widget
    ├── profile/                 # profile + edit_profile
    └── settings/

assets/
├── data/songs.json              # Catalog gốc (songs/categories/featured/mixes/...)
└── images/
```

### Điều hướng

- Route đầu tiên (`/`) được route tới `SplashPage` qua `onGenerateRoute`.
- `AppRouteTracker` (NavigatorObserver) cập nhật `currentName` để mini player ẩn / hiện đúng trang.
- Mini player tự dịch lên 72px khi đang ở `HomeShell` (vì có bottom nav 64px), 12px ở các trang khác.

---

## Luồng dữ liệu

### Bootstrap (`main.dart` → `SplashPage`)

1. `Firebase.initializeApp` (bỏ qua nếu chưa cấu hình platform native).
2. Khởi tạo `StorageService`, `AuthService`, `LibraryRepository`, `AppSettings`, `ThemeController`, `AudioPlayerService`, `CatalogService`, `CatalogHolder`.
3. `theme.load()` chạy sớm để splash đúng theme.
4. `MultiProvider` cung cấp tất cả service xuống cây widget.
5. `SplashPage._bootstrap`:
   - `auth.bootstrap()` + `settings.load()` chạy song song.
   - `catalog = catalogSvc.loadCatalog()` (assets + API + scan máy).
   - Gắn `audio.onPlayed = library.pushRecent` → bài nào phát thật sự sẽ vào "Gần đây".
   - `library.bind(userId)` → load file thư viện của user hiện tại.
   - Nếu `autoPlayOnStart` bật → `audio.restoreLastSession(songs)`.
   - Điều hướng tới `LoginPage` hoặc `HomeShell`.

### Phát một bài

```
SongTile.onTap → audio.playSongAt(songs, index)
  → audio.setQueue(songs, initialIndex)
      → just_audio.setAudioSource(ConcatenatingAudioSource)
      → đăng ký 3 stream: position / playerState / currentIndex
  → onPlayed callback → library.pushRecent(song)
  → SharedPreferences lưu last_song_id + last_position (mỗi 2s)
```

---

## Cài đặt & chạy

### Yêu cầu

- Flutter `>=3.11.3 <4.0.0`
- Dart SDK đi kèm Flutter
- Android Studio / Xcode / Visual Studio (tuỳ platform)
- Trình giả lập hoặc thiết bị thật

### Các bước

```bash
# 1. Clone về
git clone <repo-url>
cd test3

# 2. Lấy dependencies
flutter pub get

# 3. (Tuỳ chọn) chạy server nhạc local — xem mục Catalog
# Mặc định CatalogService gọi http://10.0.2.2:3001/songs

# 4. Chạy
flutter run                # tự chọn device đang kết nối
flutter run -d windows     # Windows desktop
flutter run -d chrome      # Web (chưa chính thức hỗ trợ — phụ thuộc plugin native)
```

### Quyền truy cập

- **Android** — quyền `READ_MEDIA_AUDIO` (Android 13+) / `READ_EXTERNAL_STORAGE` (cũ hơn) được xin runtime qua `permission_handler` để quét `/storage/emulated/0/Music`.
- **Windows** — đọc `C:/Users/Public/Music`, không cần quyền.

---

## Cấu hình Firebase (tuỳ chọn)

App **vẫn chạy bình thường ở chế độ local** nếu chưa cấu hình Firebase — `main.dart` đã bọc `Firebase.initializeApp` trong `try / catch`.

Nếu muốn bật:

```bash
# Cài flutterfire CLI
dart pub global activate flutterfire_cli

# Cấu hình
flutterfire configure
```

Lệnh trên sẽ sinh / cập nhật:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `firebase.json`

> ⚠️ **Lưu ý bảo mật**: `android/app/google-services.json` đang ở trạng thái untracked. Trước khi commit, kiểm tra xem có chứa key nhạy cảm không và cân nhắc gitignore.

---

## Catalog & API nhạc online

### Catalog tĩnh — `assets/data/songs.json`

Cấu trúc:

```json
{
  "songs":       [{ "id": "...", "title": "...", "artist": "...", "url": "...", "cover": "...", "color": "0xFF1ED760" }],
  "categories":  [{ "id": "pop", "name": "Pop", "color": "0xFFE91E63" }],
  "featured":    [{ "id": "...", "title": "...", "subtitle": "...", "image": "...", "category": "pop" }],
  "mixes":       [{ "id": "...", "title": "Mix yêu thích", "image": "...", "color": "0xFF...", "songIds": ["..."] }],
  "suggestions": [{ "id": "...", "title": "Gợi ý cho bạn", "image": "...", "songIds": ["..."] }],
  "albums":      [{ "id": "...", "title": "...", "artist": "...", "year": 2024, "cover": "...", "color": "0xFF...", "songIds": ["..."] }]
}
```

`SongModel.fromJson` chấp nhận cả key `url` lẫn `data` (alias) cho đường dẫn audio.

### API nhạc online (dev server tuỳ chọn)

`CatalogService.apiUrl = 'http://10.0.2.2:3001/songs'` — `10.0.2.2` là alias của `localhost` từ Android Emulator. Mở một server JSON đơn giản (ví dụ `json-server`) trả về một mảng `[{ id, title, artist, url, cover, ... }]` và app sẽ gộp vào catalog. Timeout 3s — nếu offline thì bỏ qua, không lỗi.

### Quét nhạc trong máy

- Android: quét đệ quy `/storage/emulated/0/Music`.
- Windows: `C:/Users/Public/Music`.

Mỗi `.mp3` được wrap thành `SongModel(id: 'local_n', title: <tên file>, artist: 'Trên máy', category: 'local')`.

---

## Lưu trữ dữ liệu

| Dữ liệu | Nơi lưu | Cơ chế |
|---|---|---|
| Session (`auth_user_id`) | `SharedPreferences` | `AuthService._setSession` |
| Tiến trình bài hát (`last_song_id`, `last_position`) | `SharedPreferences` | Throttle 2s trong `audio_player_service` |
| Settings (HQ / autoPlay / lang / theme) | `SharedPreferences` | `AppSettings` + `ThemeController` |
| Users | `<AppDocs>/goodmusic/users.json` | `StorageService` |
| Library theo user | `<AppDocs>/goodmusic/lib_<userId>.json` | `LibraryRepository` |

`StorageService` luôn tạo folder `goodmusic/` trong `getApplicationDocumentsDirectory()` — sandbox riêng của app, người dùng cuối không thấy.

---

## Tài khoản & quyền truy cập

- App chưa seed user mặc định — lần đầu chạy phải bấm **Đăng ký**.
- Mật khẩu được hash bằng SHA-256 (`core/utils/hash.dart`), **không lưu plaintext**.
- *Quên mật khẩu*: nhập email + mật khẩu mới → ghi đè trực tiếp (vì là local). Không gửi email — đây là điểm cần thay khi chuyển lên Firebase.

---

## Build release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (cần macOS + Xcode)
flutter build ipa --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

---

## Lộ trình phát triển

Một số hướng có thể mở rộng (chưa implement):

- [ ] Swap `AuthService` sang Firebase Auth thật, đẩy library lên Firestore.
- [ ] Chạy nền (background audio) qua `audio_service` + notification điều khiển.
- [ ] Equalizer / sleep timer.
- [ ] Tải bài từ URL về cache để nghe offline.
- [ ] CarPlay / Android Auto.
- [ ] Đa ngôn ngữ (i18n) — hiện chỉ `vi` được lưu trong settings.

---

## Khắc phục sự cố

**Build báo thiếu `firebase_options.dart` hoặc `google-services.json`**
→ Chạy `flutterfire configure`, hoặc xoá `firebase_core` khỏi `pubspec.yaml` nếu không cần.

**Android không thấy nhạc trong máy**
→ Kiểm tra quyền `READ_MEDIA_AUDIO` (Android 13+). Vào Settings → Apps → GoodMusic → Permissions → cấp quyền *Music and audio*.

**API local `10.0.2.2:3001` không phản hồi**
→ Đây là alias từ Android Emulator. Trên thiết bị thật / iOS / desktop, đổi `apiUrl` trong `lib/data/services/catalog_service.dart` sang IP máy chủ thật trong cùng LAN.

**Phát file `.mp3` báo lỗi `setAudioSource`**
→ Kiểm tra trường `data` / `url` trong JSON có hợp lệ không. `setQueue` đã filter các bài có `data` rỗng, nhưng URL chết vẫn sẽ throw từ `just_audio`.

**Mini player bị che bởi bottom nav**
→ Đảm bảo bạn đang ở route có `name`. Mini player dùng `AppRouteTracker.currentName` để biết có đang ở `HomeShell` không. Tất cả `Navigator.push` mới nên truyền `RouteSettings(name: ...)`.

---

## Giấy phép

Dự án nội bộ — chưa công bố license. Nếu fork ra dùng, vui lòng giữ credit.
