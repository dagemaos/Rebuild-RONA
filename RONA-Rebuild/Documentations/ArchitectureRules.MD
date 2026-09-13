# Architecture Rules — RONA

Dokumen ini mendefinisikan aturan arsitektur utama untuk codebase **RONA Rebuild**. Aturan-aturan ini memastikan kode tetap modular, testable, terpisah dengan jelas antar tanggung jawab (*separation of concerns*), serta menghindari *over-engineering*.

---

## Rule 1 — Feature Owns Its Presentation

Setiap feature memiliki lapisan presentation-nya sendiri yang terorganisir secara terpusat:

```
Feature/
├── View
└── ViewModel
```

### Contoh Struktur:
```
Features/
└── Home/
    ├── HomeView.swift
    └── HomeViewModel.swift
```

- **Boundary Rule:** `View` hanya fokus pada rendering UI deklaratif dan menangani event interaksi pengguna.
- `View` **tidak boleh** mengetahui langsung tentang *persistence* maupun *Machine Learning (ML)*.

---

## Rule 2 — ViewModel Owns Presentation State

`ViewModel` bertindak sebagai pengelola state untuk presentation layer.

### Boleh ditangani oleh ViewModel:
- **UI state** (loading, success, error, empty state)
- **Interaction state** (seleksi item, dialog/sheet presentation, form input)
- **Presentation transformation** (memformat data domain/model menjadi format yang siap ditampilkan di View)

### TIDAK menjadi tempat untuk:
- **Core ML implementation** (inferensi model, konfigurasi Vision request)
- **Low-level persistence** (kueri database langsung, manajemen konteks data)
- **Camera internals** (`AVCaptureSession`, konfigurasi device hardware, buffer handling)

---

## Rule 3 — External Complexity Sits Behind Boundaries

Kompleksitas eksternal (seperti machine learning, hardware kamera, dan storage database) harus selalu diletakkan di balik boundary atau service abstraction.

### Alur Scan & ML:
```
ScanViewModel
      ↓
ScanService
      ↓
FaceAnalyzer
      ↓
ML (Core ML / Vision)
```

### Alur Persistence:
```
ViewModels
      ↓
ScanHistoryRepository
      ↓
Persistence (SwiftData / Database)
```

Dengan pemisahan ini:
- `ScanViewModel` hanya berinteraksi dengan API tingkat tinggi pada `ScanService`.
- `FaceAnalyzer` mengisolasi implementasi teknis Vision / Core ML.
- Lapisan ViewModel tidak terikat langsung ke detail teknis penyimpanan ataupun library machine learning.

---

## Rule 4 — Dependency Points Toward Abstraction

Arah dependensi selalu mengarah ke abstraksi (protocol), bukan ke implementasi konkret (*Dependency Inversion Principle*).

### Target Arsitektur:
```
ViewModel
    ↓
Protocol / Abstraction
    ↑
Concrete Implementation
```

### Yang Dihindari:
```
ViewModel
    ↓
Concrete Infrastructure
```

- `ViewModel` hanya bergantung pada interface/protocol.
- Konkret implementasi (misal di layer `Infrastructure` atau `Data`) mengimplementasikan protocol tersebut.
- Mempermudah unit testing dengan *mock implementation* dan mencegah keterikatan langsung ke framework eksternal.

---

## Rule 5 — No Abstraction Without a Problem

> **Architecture RONA menggunakan targeted boundaries, bukan “semua feature harus punya semua layer”.**

Jangan membuat layer secara berlebihan jika tidak ada kompleksitas nyata yang perlu diisolasi.

### ❌ Jangan membuat:
- `HomeUseCase`
- `HomeRepository`
- `HomeDataSource`
- `HomeMapper`

...hanya karena merasa sedang menerapkan "Clean Architecture".

### Prinsip:
- Terapkan boundary dan protokol secara terukur (*targeted*) di mana kompleksitas nyata berada (misalnya pipeline ML, sinkronisasi data, hardware sensor).
- Feature yang sederhana cukup menggunakan struktur langsung (`View` + `ViewModel`) tanpa boilerplate layer yang tidak memberikan nilai tambah.
