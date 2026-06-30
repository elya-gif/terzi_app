# CLAUDE.md

Bu dosya Claude Code (claude.ai/code) için proje rehberidir. Büyük işlerden sonra güncellenir.

## Proje

Butik bir terzi dükkanı için Flutter yönetim uygulaması. Müşteri, sipariş, prova, ölçü, ödeme/alacak ve finans takibi yapar. Arayüz dili **Türkçe** (locale `tr`).

## Komutlar

```bash
flutter pub get                  # bağımlılıkları kur
flutter run                      # cihaz/emülatörde çalıştır
flutter analyze                  # statik analiz (flutter_lints)
dart format lib/                 # biçimlendir
flutter test                     # testler (henüz yazılmadı)
flutter build apk / ios          # release derleme
```

## Mimari

Katmanlı yapı. Veri akışı **Firestore-only**: Firestore tek veri kaynağı. SQLite kaldırıldı. Offline çalışma Firestore'un kendi cache'iyle (`persistenceEnabled`, `main.dart`).

```
UI (screens/widgets)
  → Riverpod provider (state + iş mantığı)
    → FirestoreSyncService (Firestore, tek kaynak)  ← okuma + yazma, await edilir
```

**Önemli kural:** Provider'larda okuma init'te bir kez `FirestoreSyncService.getX()` (tek seferlik `.get()`). Yazmada önce lokal `state` güncellenir (UI anında tepki verir), sonra `FirestoreSyncService.upsertX/deleteX` **await** edilir. Yeni kayıt id'si `FirestoreSyncService.nextId(collection)` ile alınır (eski SQLite autoincrement yerine). Firestore hatası `debugPrint` ile loglanır, exception fırlatmaz. Bu deseni bozma.

### Katmanlar
- `lib/models/` — düz Dart modelleri. Her birinde `toMap()` / `fromMap()` / `copyWith()`. `id` hâlâ `int?` (Firestore doc id = `id.toString()`). JSON kod üretimi yok, elle yazılı.
- `lib/services/firestore_sync_service.dart` — tek veri erişim noktası (singleton). Tüm okuma (`getAllCustomers`, `getFittings(customerId)`, ...), yazma (`upsertX`/`deleteX`), cascade silme (`deleteCustomerCascade`) ve id üretimi (`nextId`) burada. Sıralama client-side (`list.sort`).
- `lib/services/` — Firestore sync, bildirimler.
- `lib/providers/` — Riverpod. State yönetimi + iş mantığı.
- `lib/screens/` — ekranlar (feature klasörlerine bölünmüş).
- `lib/widgets/` — paylaşılan widget'lar (`customer_card`, `order_card`, `alpha_scroll_list`).

### State yönetimi (Riverpod) — DİKKAT: karışık API
Kod hem yeni hem eski Riverpod API'sini kullanıyor:
- `customer_provider` → yeni `Notifier` / `NotifierProvider`.
- Diğerleri (`order`, `fitting`, `measurement`, `payment`) → eski `StateNotifier` / `StateNotifierProvider` (`flutter_riverpod/legacy.dart` import'u ile).

Yeni provider eklerken yeni `Notifier` API'sini tercih et. Mevcut `StateNotifier`'ları gereksiz yere migrate etme.

Notable provider'lar:
- `allFittingsProvider` — tüm provalar (takvim için). Provalar değişince `.notifier.reload()` çağrılır.
- `nextFittingProvider.family(customerId)` — müşterinin en yakın provası.
- `orderCountProvider.family(customerId)`, `paymentProvider.family(orderId)`.

## Veri modeli

| Model | Koleksiyon | Notlar |
|-------|-----------|--------|
| `Customer` | `customers` | ad, telefon, adres, not |
| `Measurement` | `measurements` | 14 ölçü alanı (göğüs, bel, kalça, çeşitli boylar), müşteriye bağlı |
| `Order` | `orders` | fiyat, `paidAmount`, `status` (received/delivered), teslim tarihi. `remainingDebt = price - paidAmount` |
| `Fitting` | `fittings` | prova; opsiyonel `orderId`/`productName`, prova tarihi |
| `PaymentRecord` | `payments` | siparişe bağlı ödeme kayıtları |

İlişkiler: ölçü/sipariş/prova → müşteri; ödeme → sipariş. Müşteri silinince tüm bağlı kayıtlar cascade silinir (`FirestoreSyncService.deleteCustomerCascade` — batch). Sipariş silinince ödemeleri (`deletePaymentsByOrder`); sipariş "teslim edildi" olunca provaları (`deleteFittingsByOrder`) silinir. FK alanları (`customer_id`, `order_id`) `where()` ile sorgulanır.

### Model alanı ekleme
Şema migration yok (Firestore şemasız). Model alanı eklersen sadece `toMap`/`fromMap`/`copyWith`'i güncelle. `fromMap`'te sayısal alanları `map['x']?.toDouble()` ile oku (Firestore tam sayıyı `int`, ondalığı `double` döndürür — düz `as double` cast patlar).

### ID üretimi
`FirestoreSyncService.nextId(collection)` — `users/{uid}/meta/counters` dokümanında transaction ile sıradaki int id. Sayaç yoksa koleksiyonun mevcut max id'sinden seed eder. id'ler küçük int kalır; bildirim aritmetiği (`order.id + 10000` vb.) ve 32-bit bildirim id sınırı korunur.

## Firebase

- **Auth:** email/şifre (`auth_provider.dart`). Giriş yoksa router `/login`'e yönlendirir.
- **Firestore yapısı:** `users/{uid}/{collection}/{docId}` — her kullanıcının verisi izole. Doc id = model int id (string'e çevrili). `users/{uid}/meta/counters` id sayaçlarını tutar.
- **firestore.rules:** sadece `request.auth != null` kontrolü (kullanıcı bazlı izolasyon path ile sağlanıyor, kural değil).
- `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist` git'te değil / hassas.

> Not: Veri **tek seferlik** okunur (provider init'te `.get()`). Canlı çok-cihaz sync (`.snapshots()` listener) yok — gerekirse eklenmeli (`allFittingsProvider.reload()` deseni buna uygun).

## Navigation

`go_router` (`main.dart` içinde `routerProvider`). `ShellRoute` + `NavigationBar` ile 4 sekme: Müşteriler, Siparişler, Takvim, Alacaklar. Auth redirect `authStateChanges` stream'ine bağlı. Detay/form ekranlarına nesne `state.extra` ile geçirilir.

## Bildirimler

`flutter_local_notifications` + `timezone` (Europe/Istanbul). `NotificationService` singleton.
- Teslim hatırlatması: teslim tarihinden 2 gün ve 1 gün önce 09:00. ID = `order.id` ve `order.id + 10000`.
- Prova hatırlatması: prova günü 08:00 ve 1 gün önce. ID = `fitting.id + 20000` ve `+20001`.
Sipariş "teslim edildi" olunca veya silinince hatırlatmalar iptal edilir; teslim edilen siparişin provaları da silinir.

## Konvansiyonlar

- Diller: kod/değişken İngilizce, kullanıcıya görünen metin Türkçe.
- Yeni ekran → `lib/screens/<feature>/`, route'u `main.dart`'a ekle.
- Tekrar eden UI → `lib/widgets/`'a ayır, `const` constructor kullan.
- Her yazma: önce lokal `state`, sonra `FirestoreSyncService` (await). Yeni id `nextId` ile.
- Satır ≤ 80 karakter, `snake_case` dosya, `PascalCase` sınıf.

## Tasarım / Tema ("Atölye" kimliği)

Tek tema kaynağı `lib/theme/app_theme.dart` → `buildAtelierTheme()`
(`main.dart`'ta kullanılır). Palet: mürekkep + keten + pirinç (mavi
değil). Markaya özel renkler `AtelierColors` ThemeExtension'da:
`canvas/ink/graphite/brass/brassSoft/sage/plum/amber/stitch`. Erişim:
`Theme.of(context).extension<AtelierColors>()!`. Semantik renkler:
sage=teslim/tahsil, plum=prova, amber=yakın/acil, `colorScheme.error`=borç.
`Colors.green/purple/orange/red` kullanma — extension token kullan.

Tipografi (`google_fonts`): başlık + sayılar **Fraunces** (serif),
gövde **Manrope**. Fiyat/tutar gibi vurgu sayıları `textTheme.titleLarge`
(Fraunces) ile yazılır.

İmza öğesi: dikiş (running-stitch) motifi. `lib/widgets/atelier.dart`:
`StitchDivider` (yatay dikiş ayraç), `SeamAccent` (kart sol kenarı dikey
dikiş, durum rengi), `SectionHeading` (etiket + dikiş çizgili bölüm
başlığı), `MonogramAvatar` (dikiş halkalı baş harf). Yeni bölüm/kart
eklerken bu widget'ları kullan; kart `Card` (tema: yumuşak gölge, r16).

## Yapıldı

- Müşteri CRUD + alfabetik liste (`alpha_scroll_list`).
- Ölçü kaydı (14 alan), sipariş CRUD + durum/ödeme, prova CRUD.
- Takvim ekranı (provalar), alacaklar ekranı.
- Yerel bildirimler (teslim + prova).
- Firebase Auth + Firestore-only veri katmanı (SQLite kaldırıldı).

## Yapılacak (bilinen eksikler)

- Realtime sync (`.snapshots()` listener) — çok cihaz canlı güncelleme.
- Test yok (`flutter test` boş).
- Finans/özet raporlama ekranı (toplam ciro, tahsilat) — alacaklar var ama genel finans paneli yok.
