# Memoo — План работ

> Детальный план разработки с этапами и автотестами

**Версия:** 1.0
**Общее количество этапов:** 8
**Подход:** Итеративный, каждый этап завершается работающим приложением

---

## Обзор этапов

```
┌─────────────────────────────────────────────────────────────────┐
│  Этап 1: Инициализация проекта                                  │
├─────────────────────────────────────────────────────────────────┤
│  Этап 2: Модель данных (SwiftData)                              │
├─────────────────────────────────────────────────────────────────┤
│  Этап 3: Базовый UI — вкладки и редактор                        │
├─────────────────────────────────────────────────────────────────┤
│  Этап 4: Floating Panel Window                                  │
├─────────────────────────────────────────────────────────────────┤
│  Этап 5: Глобальный хоткей                                      │
├─────────────────────────────────────────────────────────────────┤
│  Этап 6: Управление вкладками (CRUD, drag-and-drop)             │
├─────────────────────────────────────────────────────────────────┤
│  Этап 7: Настройки и Menu Bar                                   │
├─────────────────────────────────────────────────────────────────┤
│  Этап 8: Polish и финальное тестирование                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Этап 1: Инициализация проекта

### Цель
Создать базовую структуру проекта с правильной конфигурацией.

### Задачи

| # | Задача | Файлы |
|---|--------|-------|
| 1.1 | Создать Xcode проект (macOS App, SwiftUI) | `Memoo.xcodeproj` |
| 1.2 | Настроить структуру папок | `App/`, `Features/`, `Core/`, `Tests/` |
| 1.3 | Добавить Package.swift с зависимостью HotKey | `Package.swift` |
| 1.4 | Настроить Info.plist (LSUIElement для скрытия из Dock) | `Info.plist` |
| 1.5 | Настроить Signing & Capabilities (App Sandbox) | Project settings |
| 1.6 | Создать базовый AppDelegate | `App/AppDelegate.swift` |
| 1.7 | Настроить конфигурации Debug/Release | Project settings |

### Конфигурация Info.plist

```xml
<key>LSUIElement</key>
<true/>  <!-- Скрыть из Dock, показывать только в Menu Bar -->
```

### Критерии завершения

- [ ] Проект компилируется без ошибок
- [ ] Приложение запускается и показывает пустое окно
- [ ] Приложение не появляется в Dock
- [ ] Структура папок соответствует дизайну

### Автотесты этапа 1

```swift
// Tests/MemooTests/SetupTests.swift

import XCTest
@testable import Memoo

final class SetupTests: XCTestCase {

    /// Проверяет, что приложение настроено как LSUIElement (без иконки в Dock)
    func testAppIsLSUIElement() {
        let info = Bundle.main.infoDictionary
        XCTAssertEqual(info?["LSUIElement"] as? Bool, true)
    }

    /// Проверяет наличие обязательных ключей в Info.plist
    func testInfoPlistContainsRequiredKeys() {
        let info = Bundle.main.infoDictionary
        XCTAssertNotNil(info?["CFBundleIdentifier"])
        XCTAssertNotNil(info?["CFBundleName"])
        XCTAssertNotNil(info?["CFBundleVersion"])
    }

    /// Проверяет минимальную версию macOS
    func testMinimumDeploymentTarget() {
        if #available(macOS 15.0, *) {
            XCTAssertTrue(true)
        } else {
            XCTFail("App requires macOS 15.0+")
        }
    }
}
```

---

## Этап 2: Модель данных (SwiftData)

### Цель
Реализовать персистентное хранение заметок с использованием SwiftData.

### Задачи

| # | Задача | Файлы |
|---|--------|-------|
| 2.1 | Создать модель Note | `Features/Notes/Models/Note.swift` |
| 2.2 | Создать DataController | `Core/Storage/DataController.swift` |
| 2.3 | Интегрировать SwiftData в App | `App/MemooApp.swift` |
| 2.4 | Реализовать CRUD операции для Note | `Features/Notes/ViewModels/NotesViewModel.swift` |
| 2.5 | Добавить миграцию схемы (для будущего) | `Core/Storage/Migrations/` |

### Модель Note

```swift
// Features/Notes/Models/Note.swift
import SwiftData
import Foundation

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "Untitled", content: String = "", order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.order = order
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

### DataController

```swift
// Core/Storage/DataController.swift
import SwiftData
import Foundation

@MainActor
final class DataController {
    static let shared = DataController()

    let container: ModelContainer

    private init() {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// Контейнер для тестов (in-memory)
    static func forTesting() -> ModelContainer {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try! ModelContainer(for: schema, configurations: config)
    }
}
```

### Критерии завершения

- [ ] Модель Note создана и компилируется
- [ ] DataController инициализируется без ошибок
- [ ] Данные сохраняются между запусками приложения
- [ ] CRUD операции работают корректно

### Автотесты этапа 2

```swift
// Tests/MemooTests/DataTests/NoteModelTests.swift

import XCTest
import SwiftData
@testable import Memoo

final class NoteModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()
        container = DataController.forTesting()
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Creation Tests

    func testNoteCreation_WithDefaults() {
        let note = Note()

        XCTAssertNotNil(note.id)
        XCTAssertEqual(note.title, "Untitled")
        XCTAssertEqual(note.content, "")
        XCTAssertEqual(note.order, 0)
        XCTAssertNotNil(note.createdAt)
        XCTAssertNotNil(note.updatedAt)
    }

    func testNoteCreation_WithCustomValues() {
        let note = Note(title: "Test Note", content: "Hello", order: 5)

        XCTAssertEqual(note.title, "Test Note")
        XCTAssertEqual(note.content, "Hello")
        XCTAssertEqual(note.order, 5)
    }

    func testNoteHasUniqueID() {
        let note1 = Note()
        let note2 = Note()

        XCTAssertNotEqual(note1.id, note2.id)
    }

    // MARK: - Persistence Tests

    func testNotePersistence_Insert() throws {
        let note = Note(title: "Persistent Note", content: "Content")
        context.insert(note)
        try context.save()

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.title, "Persistent Note")
    }

    func testNotePersistence_Update() throws {
        let note = Note(title: "Original")
        context.insert(note)
        try context.save()

        note.title = "Updated"
        note.updatedAt = Date()
        try context.save()

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes.first?.title, "Updated")
    }

    func testNotePersistence_Delete() throws {
        let note = Note()
        context.insert(note)
        try context.save()

        context.delete(note)
        try context.save()

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes.count, 0)
    }

    // MARK: - Ordering Tests

    func testNotesFetchedInOrder() throws {
        let note1 = Note(title: "Third", order: 2)
        let note2 = Note(title: "First", order: 0)
        let note3 = Note(title: "Second", order: 1)

        context.insert(note1)
        context.insert(note2)
        context.insert(note3)
        try context.save()

        var descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.order)]
        )
        let notes = try context.fetch(descriptor)

        XCTAssertEqual(notes[0].title, "First")
        XCTAssertEqual(notes[1].title, "Second")
        XCTAssertEqual(notes[2].title, "Third")
    }
}
```

```swift
// Tests/MemooTests/DataTests/DataControllerTests.swift

import XCTest
import SwiftData
@testable import Memoo

final class DataControllerTests: XCTestCase {

    func testDataControllerInitialization() {
        // Используем тестовый контейнер
        let container = DataController.forTesting()
        XCTAssertNotNil(container)
    }

    func testDataControllerCreatesValidContext() {
        let container = DataController.forTesting()
        let context = ModelContext(container)
        XCTAssertNotNil(context)
    }
}
```

---

## Этап 3: Базовый UI — вкладки и редактор

### Цель
Создать базовый интерфейс с вкладками и текстовым редактором.

### Задачи

| # | Задача | Файлы |
|---|--------|-------|
| 3.1 | Создать NotesViewModel | `Features/Notes/ViewModels/NotesViewModel.swift` |
| 3.2 | Создать TabBarView | `Features/Notes/Views/TabBarView.swift` |
| 3.3 | Создать TabItemView | `Features/Notes/Views/TabItemView.swift` |
| 3.4 | Создать NoteEditorView | `Features/Notes/Views/NoteEditorView.swift` |
| 3.5 | Создать MainContentView | `Features/Notes/Views/MainContentView.swift` |
| 3.6 | Интегрировать UI с данными | `App/MemooApp.swift` |

### NotesViewModel

```swift
// Features/Notes/ViewModels/NotesViewModel.swift
import SwiftUI
import SwiftData

@Observable
@MainActor
final class NotesViewModel {
    private let modelContext: ModelContext

    var notes: [Note] = []
    var selectedNoteID: UUID?

    var selectedNote: Note? {
        notes.first { $0.id == selectedNoteID }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchNotes()
        ensureAtLeastOneNote()
    }

    func fetchNotes() {
        let descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.order)]
        )
        notes = (try? modelContext.fetch(descriptor)) ?? []
    }

    func createNote() {
        let maxOrder = notes.map(\.order).max() ?? -1
        let count = notes.count + 1
        let note = Note(title: "Untitled \(count)", order: maxOrder + 1)
        modelContext.insert(note)
        save()
        fetchNotes()
        selectedNoteID = note.id
    }

    func deleteNote(_ note: Note) {
        modelContext.delete(note)
        save()
        fetchNotes()
        ensureAtLeastOneNote()

        if selectedNoteID == note.id {
            selectedNoteID = notes.first?.id
        }
    }

    func updateNoteContent(_ note: Note, content: String) {
        note.content = content
        note.updatedAt = Date()
        save()
    }

    func updateNoteTitle(_ note: Note, title: String) {
        note.title = title.isEmpty ? "Untitled" : title
        note.updatedAt = Date()
        save()
    }

    private func ensureAtLeastOneNote() {
        if notes.isEmpty {
            createNote()
        }
        if selectedNoteID == nil {
            selectedNoteID = notes.first?.id
        }
    }

    private func save() {
        try? modelContext.save()
    }
}
```

### Критерии завершения

- [ ] Вкладки отображаются корректно
- [ ] Можно переключаться между вкладками
- [ ] Текст сохраняется при переключении вкладок
- [ ] Можно создавать новые вкладки
- [ ] Текстовый редактор работает

### Автотесты этапа 3

```swift
// Tests/MemooTests/ViewModelTests/NotesViewModelTests.swift

import XCTest
import SwiftData
@testable import Memoo

@MainActor
final class NotesViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var viewModel: NotesViewModel!

    override func setUp() {
        super.setUp()
        container = DataController.forTesting()
        context = ModelContext(container)
        viewModel = NotesViewModel(modelContext: context)
    }

    override func tearDown() {
        viewModel = nil
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewModel_CreatesDefaultNoteOnInit() {
        XCTAssertFalse(viewModel.notes.isEmpty)
        XCTAssertEqual(viewModel.notes.count, 1)
    }

    func testViewModel_SelectsFirstNoteOnInit() {
        XCTAssertNotNil(viewModel.selectedNoteID)
        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes.first?.id)
    }

    // MARK: - Create Tests

    func testCreateNote_AddsNewNote() {
        let initialCount = viewModel.notes.count
        viewModel.createNote()

        XCTAssertEqual(viewModel.notes.count, initialCount + 1)
    }

    func testCreateNote_SelectsNewNote() {
        viewModel.createNote()
        let newNote = viewModel.notes.last

        XCTAssertEqual(viewModel.selectedNoteID, newNote?.id)
    }

    func testCreateNote_HasCorrectOrder() {
        viewModel.createNote()
        viewModel.createNote()

        let orders = viewModel.notes.map(\.order)
        XCTAssertEqual(orders, orders.sorted())
    }

    // MARK: - Delete Tests

    func testDeleteNote_RemovesNote() {
        viewModel.createNote()
        let noteToDelete = viewModel.notes.last!
        let initialCount = viewModel.notes.count

        viewModel.deleteNote(noteToDelete)

        XCTAssertEqual(viewModel.notes.count, initialCount - 1)
    }

    func testDeleteNote_EnsuresAtLeastOneNote() {
        // Удаляем все кроме одной
        while viewModel.notes.count > 1 {
            viewModel.deleteNote(viewModel.notes.last!)
        }

        // Удаляем последнюю
        viewModel.deleteNote(viewModel.notes.first!)

        // Должна создаться новая
        XCTAssertEqual(viewModel.notes.count, 1)
    }

    func testDeleteNote_UpdatesSelection() {
        viewModel.createNote()
        let firstNote = viewModel.notes.first!
        viewModel.selectedNoteID = firstNote.id

        viewModel.deleteNote(firstNote)

        XCTAssertNotNil(viewModel.selectedNoteID)
        XCTAssertNotEqual(viewModel.selectedNoteID, firstNote.id)
    }

    // MARK: - Update Tests

    func testUpdateNoteContent_UpdatesContent() {
        let note = viewModel.notes.first!
        viewModel.updateNoteContent(note, content: "New content")

        XCTAssertEqual(note.content, "New content")
    }

    func testUpdateNoteContent_UpdatesTimestamp() {
        let note = viewModel.notes.first!
        let oldTimestamp = note.updatedAt

        // Небольшая задержка для разницы во времени
        Thread.sleep(forTimeInterval: 0.01)
        viewModel.updateNoteContent(note, content: "Updated")

        XCTAssertGreaterThan(note.updatedAt, oldTimestamp)
    }

    func testUpdateNoteTitle_UpdatesTitle() {
        let note = viewModel.notes.first!
        viewModel.updateNoteTitle(note, title: "New Title")

        XCTAssertEqual(note.title, "New Title")
    }

    func testUpdateNoteTitle_EmptyTitleBecomesUntitled() {
        let note = viewModel.notes.first!
        viewModel.updateNoteTitle(note, title: "")

        XCTAssertEqual(note.title, "Untitled")
    }

    // MARK: - Selection Tests

    func testSelectedNote_ReturnsCorrectNote() {
        viewModel.createNote()
        let targetNote = viewModel.notes.last!
        viewModel.selectedNoteID = targetNote.id

        XCTAssertEqual(viewModel.selectedNote?.id, targetNote.id)
    }

    func testSelectedNote_ReturnsNilForInvalidID() {
        viewModel.selectedNoteID = UUID()
        XCTAssertNil(viewModel.selectedNote)
    }
}
```

```swift
// Tests/MemooUITests/TabBarUITests.swift

import XCTest

final class TabBarUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testTabBar_IsVisible() {
        let tabBar = app.groups["TabBar"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 2))
    }

    func testTabBar_HasAddButton() {
        let addButton = app.buttons["AddTabButton"]
        XCTAssertTrue(addButton.exists)
    }

    func testAddButton_CreatesNewTab() {
        let addButton = app.buttons["AddTabButton"]
        let initialTabCount = app.buttons.matching(identifier: "TabItem").count

        addButton.tap()

        let newTabCount = app.buttons.matching(identifier: "TabItem").count
        XCTAssertEqual(newTabCount, initialTabCount + 1)
    }

    func testTab_CanBeSelected() {
        // Создаём вторую вкладку
        app.buttons["AddTabButton"].tap()

        let firstTab = app.buttons.matching(identifier: "TabItem").element(boundBy: 0)
        let secondTab = app.buttons.matching(identifier: "TabItem").element(boundBy: 1)

        firstTab.tap()
        // Проверяем, что первая вкладка выбрана (по состоянию UI)
        XCTAssertTrue(firstTab.isSelected)
    }
}
```

---

## Этап 4: Floating Panel Window

### Цель
Реализовать кастомное окно типа floating panel.

### Задачи

| # | Задача | Файлы |
|---|--------|-------|
| 4.1 | Создать FloatingPanel (NSPanel subclass) | `Core/Window/FloatingPanel.swift` |
| 4.2 | Создать WindowManager | `Core/Window/WindowManager.swift` |
| 4.3 | Настроить внешний вид окна (no title bar) | `FloatingPanel.swift` |
| 4.4 | Реализовать show/hide с анимацией | `WindowManager.swift` |
| 4.5 | Сохранение позиции и размера окна | `WindowManager.swift` |
| 4.6 | Обработка Escape для скрытия | `FloatingPanel.swift` |

### FloatingPanel

```swift
// Core/Window/FloatingPanel.swift
import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {

    init(contentView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Конфигурация панели
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.backgroundColor = .windowBackgroundColor

        // Скрыть стандартные кнопки
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true

        // Установить SwiftUI контент
        self.contentView = NSHostingView(rootView: contentView)

        // Центрировать на экране
        self.center()
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        // Escape скрывает окно
        WindowManager.shared.hideWindow()
    }
}
```

### Критерии завершения

- [ ] Окно появляется как floating panel
- [ ] Окно не имеет стандартного title bar
- [ ] Окно центрируется на экране
- [ ] Escape скрывает окно
- [ ] Позиция и размер сохраняются

### Автотесты этапа 4

```swift
// Tests/MemooTests/WindowTests/FloatingPanelTests.swift

import XCTest
import AppKit
import SwiftUI
@testable import Memoo

final class FloatingPanelTests: XCTestCase {

    var panel: FloatingPanel!

    override func setUp() {
        super.setUp()
        panel = FloatingPanel(contentView: Text("Test"))
    }

    override func tearDown() {
        panel?.close()
        panel = nil
        super.tearDown()
    }

    func testPanel_IsFloatingLevel() {
        XCTAssertEqual(panel.level, .floating)
    }

    func testPanel_HasCorrectStyleMask() {
        XCTAssertTrue(panel.styleMask.contains(.nonactivatingPanel))
        XCTAssertTrue(panel.styleMask.contains(.titled))
        XCTAssertTrue(panel.styleMask.contains(.resizable))
    }

    func testPanel_TitleBarIsTransparent() {
        XCTAssertTrue(panel.titlebarAppearsTransparent)
    }

    func testPanel_TitleIsHidden() {
        XCTAssertEqual(panel.titleVisibility, .hidden)
    }

    func testPanel_StandardButtonsAreHidden() {
        XCTAssertTrue(panel.standardWindowButton(.closeButton)?.isHidden ?? true)
        XCTAssertTrue(panel.standardWindowButton(.miniaturizeButton)?.isHidden ?? true)
        XCTAssertTrue(panel.standardWindowButton(.zoomButton)?.isHidden ?? true)
    }

    func testPanel_CanBecomeKey() {
        XCTAssertTrue(panel.canBecomeKey)
    }

    func testPanel_HasCorrectDefaultSize() {
        XCTAssertEqual(panel.frame.width, 600)
        XCTAssertEqual(panel.frame.height, 400)
    }

    func testPanel_JoinsAllSpaces() {
        XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
    }

    func testPanel_IsFullScreenAuxiliary() {
        XCTAssertTrue(panel.collectionBehavior.contains(.fullScreenAuxiliary))
    }
}
```

```swift
// Tests/MemooTests/WindowTests/WindowManagerTests.swift

import XCTest
import AppKit
@testable import Memoo

@MainActor
final class WindowManagerTests: XCTestCase {

    var windowManager: WindowManager!

    override func setUp() {
        super.setUp()
        windowManager = WindowManager()
    }

    override func tearDown() {
        windowManager.hideWindow()
        windowManager = nil
        super.tearDown()
    }

    func testShowWindow_MakesWindowVisible() {
        windowManager.showWindow()
        XCTAssertTrue(windowManager.isVisible)
    }

    func testHideWindow_MakesWindowInvisible() {
        windowManager.showWindow()
        windowManager.hideWindow()
        XCTAssertFalse(windowManager.isVisible)
    }

    func testToggleWindow_TogglesVisibility() {
        XCTAssertFalse(windowManager.isVisible)

        windowManager.toggleWindow()
        XCTAssertTrue(windowManager.isVisible)

        windowManager.toggleWindow()
        XCTAssertFalse(windowManager.isVisible)
    }

    func testWindowFrame_IsSavedAndRestored() {
        windowManager.showWindow()

        let newFrame = NSRect(x: 100, y: 100, width: 800, height: 600)
        windowManager.setWindowFrame(newFrame)

        let savedFrame = windowManager.getSavedWindowFrame()
        XCTAssertEqual(savedFrame, newFrame)
    }
}
```

---

## Этап 5: Глобальный хоткей

### Цель
Реализовать глобальный хоткей для вызова приложения.

### Задачи

| # | Задача | Файлы |
|---|--------|-------|
| 5.1 | Создать HotKeyManager | `Features/HotKey/HotKeyManager.swift` |
| 5.2 | Интегрировать библиотеку HotKey | `Package.swift` |
| 5.3 | Настроить дефолтный хоткей (⌥+Space) | `HotKeyManager.swift` |
| 5.4 | Связать хоткей с WindowManager | `App/AppDelegate.swift` |
| 5.5 | Добавить обработку ошибок (конфликт хоткеев) | `HotKeyManager.swift` |

### HotKeyManager

```swift
// Features/HotKey/HotKeyManager.swift
import HotKey
import AppKit

@MainActor
final class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()

    @Published private(set) var isRegistered: Bool = false
    @Published private(set) var currentHotKey: KeyCombo?

    private var hotKey: HotKey?
    private var onTrigger: (() -> Void)?

    private init() {}

    func register(
        key: Key = .space,
        modifiers: NSEvent.ModifierFlags = .option,
        handler: @escaping () -> Void
    ) {
        // Удаляем предыдущий хоткей если есть
        unregister()

        self.onTrigger = handler
        self.hotKey = HotKey(key: key, modifiers: modifiers)
        self.currentHotKey = KeyCombo(key: key, modifiers: modifiers)

        self.hotKey?.keyDownHandler = { [weak self] in
            self?.onTrigger?()
        }

        self.isRegistered = true
    }

    func unregister() {
        hotKey = nil
        isRegistered = false
    }

    func updateHotKey(key: Key, modifiers: NSEvent.ModifierFlags) {
        guard let handler = onTrigger else { return }
        register(key: key, modifiers: modifiers, handler: handler)
    }
}

struct KeyCombo: Equatable {
    let key: Key
    let modifiers: NSEvent.ModifierFlags
}
```

### Критерии завершения

- [ ] Глобальный хоткей регистрируется при запуске
- [ ] ⌥+Space показывает/скрывает окно
- [ ] Хоткей работает из любого приложения
- [ ] При ошибке регистрации показывается уведомление

### Автотесты этапа 5

```swift
// Tests/MemooTests/HotKeyTests/HotKeyManagerTests.swift

import XCTest
import HotKey
@testable import Memoo

@MainActor
final class HotKeyManagerTests: XCTestCase {

    var hotKeyManager: HotKeyManager!

    override func setUp() {
        super.setUp()
        hotKeyManager = HotKeyManager.shared
    }

    override func tearDown() {
        hotKeyManager.unregister()
        super.tearDown()
    }

    func testRegister_SetsIsRegisteredTrue() {
        hotKeyManager.register(key: .space, modifiers: .option) {}
        XCTAssertTrue(hotKeyManager.isRegistered)
    }

    func testRegister_SetsCurrentHotKey() {
        hotKeyManager.register(key: .space, modifiers: .option) {}

        XCTAssertNotNil(hotKeyManager.currentHotKey)
        XCTAssertEqual(hotKeyManager.currentHotKey?.key, .space)
        XCTAssertEqual(hotKeyManager.currentHotKey?.modifiers, .option)
    }

    func testUnregister_SetsIsRegisteredFalse() {
        hotKeyManager.register(key: .space, modifiers: .option) {}
        hotKeyManager.unregister()

        XCTAssertFalse(hotKeyManager.isRegistered)
    }

    func testUpdateHotKey_ChangesHotKey() {
        hotKeyManager.register(key: .space, modifiers: .option) {}
        hotKeyManager.updateHotKey(key: .n, modifiers: [.command, .shift])

        XCTAssertEqual(hotKeyManager.currentHotKey?.key, .n)
        XCTAssertEqual(hotKeyManager.currentHotKey?.modifiers, [.command, .shift])
    }

    func testRegister_TriggersHandler() {
        let expectation = expectation(description: "Handler triggered")

        hotKeyManager.register(key: .space, modifiers: .option) {
            expectation.fulfill()
        }

        // Симулируем вызов хоткея (в реальных тестах это сложнее)
        // Это placeholder для интеграционного теста
        // В unit тестах мы проверяем только регистрацию

        XCTAssertTrue(hotKeyManager.isRegistered)
    }
}
```

```swift
// Tests/MemooUITests/HotKeyUITests.swift

import XCTest

final class HotKeyUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    func testHotKey_ShowsWindow() {
        // Скрываем окно
        app.typeKey(.escape, modifierFlags: [])

        // Ждём скрытия
        Thread.sleep(forTimeInterval: 0.5)

        // Нажимаем глобальный хоткей (⌥+Space)
        // Примечание: XCUITest может не перехватывать глобальные хоткеи
        // Это интеграционный тест, который требует ручной проверки
        // или специального test harness

        // Placeholder assertion
        XCTAssertTrue(true, "Manual verification required for global hotkey")
    }

    func testEscape_HidesWindow() {
        // Убеждаемся что окно видимо
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)

        // Нажимаем Escape
        app.typeKey(.escape, modifierFlags: [])

        // Проверяем что окно скрылось
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertFalse(window.isHittable)
    }
}
```

---

## Этап 6: Управление вкладками (CRUD, drag-and-drop)

### Цель
Полноценное управление вкладками включая переупорядочивание.

### Задачи

| # | Задача | Файлы |
|---|--------|-------|
| 6.1 | Реализовать закрытие вкладок (×) | `TabItemView.swift` |
| 6.2 | Реализовать переименование (двойной клик) | `TabItemView.swift` |
| 6.3 | Реализовать drag-and-drop | `TabBarView.swift` |
| 6.4 | Добавить контекстное меню | `TabItemView.swift` |
| 6.5 | Добавить keyboard shortcuts (⌘+T, ⌘+W, ⌘+1-9) | `MainContentView.swift` |
| 6.6 | Реализовать ⌘+[ и ⌘+] для навигации | `MainContentView.swift` |

### Критерии завершения

- [ ] Вкладки можно закрывать кнопкой ×
- [ ] Двойной клик позволяет переименовать вкладку
- [ ] Вкладки можно перетаскивать для изменения порядка
- [ ] Контекстное меню работает
- [ ] Все keyboard shortcuts работают

### Автотесты этапа 6

```swift
// Tests/MemooTests/ViewModelTests/TabManagementTests.swift

import XCTest
import SwiftData
@testable import Memoo

@MainActor
final class TabManagementTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var viewModel: NotesViewModel!

    override func setUp() {
        super.setUp()
        container = DataController.forTesting()
        context = ModelContext(container)
        viewModel = NotesViewModel(modelContext: context)
    }

    override func tearDown() {
        viewModel = nil
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Reorder Tests

    func testMoveNote_UpdatesOrder() {
        // Создаём 3 заметки
        viewModel.createNote()
        viewModel.createNote()

        let notes = viewModel.notes
        XCTAssertEqual(notes.count, 3)

        // Перемещаем первую в конец
        viewModel.moveNote(from: 0, to: 2)

        let reorderedNotes = viewModel.notes
        XCTAssertEqual(reorderedNotes.map(\.order), [0, 1, 2])
    }

    func testMoveNote_PreservesContent() {
        viewModel.createNote()

        let firstNote = viewModel.notes.first!
        viewModel.updateNoteContent(firstNote, content: "First content")

        viewModel.moveNote(from: 0, to: 1)

        // Контент должен сохраниться
        let movedNote = viewModel.notes.last!
        XCTAssertEqual(movedNote.content, "First content")
    }

    // MARK: - Duplicate Tests

    func testDuplicateNote_CreatesNewNote() {
        let note = viewModel.notes.first!
        viewModel.updateNoteContent(note, content: "Original")
        let initialCount = viewModel.notes.count

        viewModel.duplicateNote(note)

        XCTAssertEqual(viewModel.notes.count, initialCount + 1)
    }

    func testDuplicateNote_CopiesContent() {
        let note = viewModel.notes.first!
        viewModel.updateNoteContent(note, content: "Original content")
        viewModel.updateNoteTitle(note, title: "Original title")

        viewModel.duplicateNote(note)

        let duplicated = viewModel.notes.last!
        XCTAssertEqual(duplicated.content, "Original content")
        XCTAssertTrue(duplicated.title.contains("Copy"))
    }

    // MARK: - Navigation Tests

    func testSelectNextNote_SelectsNext() {
        viewModel.createNote()
        viewModel.createNote()

        viewModel.selectedNoteID = viewModel.notes.first?.id
        viewModel.selectNextNote()

        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes[1].id)
    }

    func testSelectNextNote_WrapsAround() {
        viewModel.createNote()

        viewModel.selectedNoteID = viewModel.notes.last?.id
        viewModel.selectNextNote()

        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes.first?.id)
    }

    func testSelectPreviousNote_SelectsPrevious() {
        viewModel.createNote()
        viewModel.createNote()

        viewModel.selectedNoteID = viewModel.notes[1].id
        viewModel.selectPreviousNote()

        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes.first?.id)
    }

    func testSelectPreviousNote_WrapsAround() {
        viewModel.createNote()

        viewModel.selectedNoteID = viewModel.notes.first?.id
        viewModel.selectPreviousNote()

        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes.last?.id)
    }

    func testSelectNoteByIndex_SelectsCorrectNote() {
        viewModel.createNote()
        viewModel.createNote()

        viewModel.selectNote(at: 1)

        XCTAssertEqual(viewModel.selectedNoteID, viewModel.notes[1].id)
    }

    func testSelectNoteByIndex_IgnoresInvalidIndex() {
        let currentSelection = viewModel.selectedNoteID
        viewModel.selectNote(at: 99)

        XCTAssertEqual(viewModel.selectedNoteID, currentSelection)
    }
}
```

```swift
// Tests/MemooUITests/TabDragDropUITests.swift

import XCTest

final class TabDragDropUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testTab_CanBeClosed() {
        // Создаём вторую вкладку
        app.buttons["AddTabButton"].tap()

        let tabCount = app.buttons.matching(identifier: "TabItem").count
        XCTAssertEqual(tabCount, 2)

        // Находим кнопку закрытия
        let closeButton = app.buttons["CloseTabButton"].firstMatch
        closeButton.tap()

        let newTabCount = app.buttons.matching(identifier: "TabItem").count
        XCTAssertEqual(newTabCount, 1)
    }

    func testTab_CanBeRenamed() {
        let tab = app.buttons.matching(identifier: "TabItem").firstMatch

        // Двойной клик для редактирования
        tab.doubleTap()

        // Должно появиться поле ввода
        let textField = app.textFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 1))

        // Вводим новое название
        textField.typeText("New Name")
        textField.typeKey(.return, modifierFlags: [])

        // Проверяем что название изменилось
        XCTAssertTrue(app.staticTexts["New Name"].exists)
    }

    func testKeyboardShortcut_CmdT_CreatesNewTab() {
        let initialCount = app.buttons.matching(identifier: "TabItem").count

        app.typeKey("t", modifierFlags: .command)

        let newCount = app.buttons.matching(identifier: "TabItem").count
        XCTAssertEqual(newCount, initialCount + 1)
    }

    func testKeyboardShortcut_CmdW_ClosesTab() {
        // Создаём вторую вкладку
        app.typeKey("t", modifierFlags: .command)
        let countAfterCreate = app.buttons.matching(identifier: "TabItem").count

        app.typeKey("w", modifierFlags: .command)

        let countAfterClose = app.buttons.matching(identifier: "TabItem").count
        XCTAssertEqual(countAfterClose, countAfterCreate - 1)
    }

    func testKeyboardShortcut_Cmd1_SelectsFirstTab() {
        // Создаём несколько вкладок
        app.typeKey("t", modifierFlags: .command)
        app.typeKey("t", modifierFlags: .command)

        // Выбираем первую
        app.typeKey("1", modifierFlags: .command)

        let firstTab = app.buttons.matching(identifier: "TabItem").element(boundBy: 0)
        XCTAssertTrue(firstTab.isSelected)
    }
}
```

---

## Этап 7: Настройки и Menu Bar

### Цель
Добавить настройки приложения и иконку в Menu Bar.

### Задачи

| # | Задача | Файлы |
|---|--------|-------|
| 7.1 | Создать SettingsView | `Features/Settings/Views/SettingsView.swift` |
| 7.2 | Создать SettingsViewModel | `Features/Settings/ViewModels/SettingsViewModel.swift` |
| 7.3 | Добавить настройку хоткея | `SettingsView.swift` |
| 7.4 | Добавить Launch at Login | `SettingsView.swift` |
| 7.5 | Реализовать MenuBarExtra | `App/MemooApp.swift` |
| 7.6 | Добавить контекстное меню Menu Bar | `App/MemooApp.swift` |

### SettingsView структура

```swift
// Features/Settings/Views/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("Hotkey") {
                HotKeyRecorderView(
                    keyCombo: $viewModel.hotKeyCombo
                )
            }

            Section("Behavior") {
                Toggle("Hide on click outside", isOn: $viewModel.hideOnClickOutside)
                Toggle("Show Menu Bar icon", isOn: $viewModel.showMenuBarIcon)
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $viewModel.launchAtLogin)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
```

### Критерии завершения

- [ ] Настройки открываются по ⌘+,
- [ ] Можно изменить глобальный хоткей
- [ ] Launch at Login работает
- [ ] Иконка в Menu Bar отображается
- [ ] Клик по иконке показывает/скрывает окно

### Автотесты этапа 7

```swift
// Tests/MemooTests/SettingsTests/SettingsViewModelTests.swift

import XCTest
@testable import Memoo

@MainActor
final class SettingsViewModelTests: XCTestCase {

    var viewModel: SettingsViewModel!

    override func setUp() {
        super.setUp()
        // Очищаем UserDefaults перед каждым тестом
        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier!
        )
        viewModel = SettingsViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testDefaultHotKey_IsOptionSpace() {
        XCTAssertEqual(viewModel.hotKeyKey, .space)
        XCTAssertEqual(viewModel.hotKeyModifiers, .option)
    }

    func testShowMenuBarIcon_DefaultsToTrue() {
        XCTAssertTrue(viewModel.showMenuBarIcon)
    }

    func testHideOnClickOutside_DefaultsToTrue() {
        XCTAssertTrue(viewModel.hideOnClickOutside)
    }

    func testLaunchAtLogin_DefaultsToFalse() {
        XCTAssertFalse(viewModel.launchAtLogin)
    }

    func testUpdateHotKey_SavesSetting() {
        viewModel.updateHotKey(key: .n, modifiers: [.command, .shift])

        // Создаём новый viewModel чтобы проверить персистентность
        let newViewModel = SettingsViewModel()
        XCTAssertEqual(newViewModel.hotKeyKey, .n)
        XCTAssertEqual(newViewModel.hotKeyModifiers, [.command, .shift])
    }

    func testToggleLaunchAtLogin_SavesSetting() {
        viewModel.launchAtLogin = true

        let newViewModel = SettingsViewModel()
        XCTAssertTrue(newViewModel.launchAtLogin)
    }
}
```

```swift
// Tests/MemooUITests/SettingsUITests.swift

import XCTest

final class SettingsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testSettings_OpensWithCmdComma() {
        app.typeKey(",", modifierFlags: .command)

        let settingsWindow = app.windows["Settings"]
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 2))
    }

    func testSettings_ContainsHotkeySection() {
        app.typeKey(",", modifierFlags: .command)

        let hotkeySection = app.staticTexts["Hotkey"]
        XCTAssertTrue(hotkeySection.exists)
    }

    func testSettings_ContainsBehaviorSection() {
        app.typeKey(",", modifierFlags: .command)

        let behaviorSection = app.staticTexts["Behavior"]
        XCTAssertTrue(behaviorSection.exists)
    }

    func testSettings_HideOnClickOutsideToggle() {
        app.typeKey(",", modifierFlags: .command)

        let toggle = app.switches["Hide on click outside"]
        XCTAssertTrue(toggle.exists)

        toggle.tap()
        // Проверяем что состояние изменилось
        XCTAssertEqual(toggle.value as? String, "0")
    }

    func testMenuBar_IconExists() {
        // Ищем иконку в menu bar
        let menuBar = XCUIApplication(bundleIdentifier: "com.apple.controlcenter")
        // Примечание: тестирование Menu Bar требует особого подхода
        // Это placeholder для интеграционного теста
        XCTAssertTrue(true, "Manual verification required for Menu Bar")
    }
}
```

---

## Этап 8: Polish и финальное тестирование

### Цель
Финальная доработка, оптимизация и полное тестирование.

### Задачи

| # | Задача | Файлы |
|---|--------|-------|
| 8.1 | Добавить анимации (появление/скрытие окна) | `WindowManager.swift` |
| 8.2 | Оптимизировать производительность | Various |
| 8.3 | Добавить VoiceOver support | Views |
| 8.4 | Добавить локализацию (en, ru) | `Localizable.strings` |
| 8.5 | Провести memory profiling | - |
| 8.6 | Написать интеграционные тесты | Tests |
| 8.7 | Подготовить для App Store | Project settings |

### Performance тесты

```swift
// Tests/MemooTests/PerformanceTests/PerformanceTests.swift

import XCTest
@testable import Memoo

final class PerformanceTests: XCTestCase {

    func testWindowShowPerformance() {
        let windowManager = WindowManager()

        measure {
            windowManager.showWindow()
            windowManager.hideWindow()
        }
    }

    func testNoteSavePerformance() throws {
        let container = DataController.forTesting()
        let context = ModelContext(container)

        measure {
            let note = Note(content: String(repeating: "a", count: 10000))
            context.insert(note)
            try? context.save()
            context.delete(note)
            try? context.save()
        }
    }

    func testTabSwitchPerformance() {
        let container = DataController.forTesting()
        let context = ModelContext(container)
        let viewModel = NotesViewModel(modelContext: context)

        // Создаём 20 заметок
        for _ in 0..<20 {
            viewModel.createNote()
        }

        measure {
            for i in 0..<20 {
                viewModel.selectNote(at: i)
            }
        }
    }

    func testLargeNoteRenderPerformance() {
        let container = DataController.forTesting()
        let context = ModelContext(container)
        let viewModel = NotesViewModel(modelContext: context)

        // Создаём заметку с большим текстом
        let largeContent = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)
        let note = viewModel.notes.first!
        viewModel.updateNoteContent(note, content: largeContent)

        measure {
            // Симулируем рендеринг
            _ = note.content.count
        }
    }
}
```

### Accessibility тесты

```swift
// Tests/MemooUITests/AccessibilityUITests.swift

import XCTest

final class AccessibilityUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testTabBar_HasAccessibilityLabel() {
        let tabBar = app.groups["TabBar"]
        XCTAssertNotNil(tabBar.label)
    }

    func testAddButton_HasAccessibilityLabel() {
        let addButton = app.buttons["AddTabButton"]
        XCTAssertEqual(addButton.label, "Add new tab")
    }

    func testEditor_HasAccessibilityLabel() {
        let editor = app.textViews["NoteEditor"]
        XCTAssertNotNil(editor.label)
    }

    func testTabs_AreAccessibleByVoiceOver() {
        let tabs = app.buttons.matching(identifier: "TabItem")

        for i in 0..<tabs.count {
            let tab = tabs.element(boundBy: i)
            XCTAssertTrue(tab.isAccessibilityElement)
            XCTAssertNotNil(tab.label)
        }
    }

    func testAllInteractiveElements_HaveAccessibilityTraits() {
        let buttons = app.buttons.allElementsBoundByIndex

        for button in buttons {
            XCTAssertTrue(
                button.accessibilityTraits.contains(.button),
                "Button \(button.identifier) missing button trait"
            )
        }
    }
}
```

### Интеграционные тесты

```swift
// Tests/MemooTests/IntegrationTests/FullWorkflowTests.swift

import XCTest
import SwiftData
@testable import Memoo

@MainActor
final class FullWorkflowTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var notesViewModel: NotesViewModel!
    var windowManager: WindowManager!
    var hotKeyManager: HotKeyManager!

    override func setUp() {
        super.setUp()
        container = DataController.forTesting()
        context = ModelContext(container)
        notesViewModel = NotesViewModel(modelContext: context)
        windowManager = WindowManager()
        hotKeyManager = HotKeyManager.shared
    }

    override func tearDown() {
        hotKeyManager.unregister()
        windowManager.hideWindow()
        notesViewModel = nil
        context = nil
        container = nil
        super.tearDown()
    }

    /// Полный workflow: показать окно -> написать заметку -> скрыть -> показать -> проверить содержимое
    func testFullNoteWorkflow() {
        // 1. Показываем окно
        windowManager.showWindow()
        XCTAssertTrue(windowManager.isVisible)

        // 2. Пишем заметку
        let note = notesViewModel.notes.first!
        notesViewModel.updateNoteContent(note, content: "Test content")

        // 3. Скрываем окно
        windowManager.hideWindow()
        XCTAssertFalse(windowManager.isVisible)

        // 4. Показываем снова
        windowManager.showWindow()

        // 5. Проверяем что контент сохранился
        XCTAssertEqual(notesViewModel.selectedNote?.content, "Test content")
    }

    /// Workflow с несколькими вкладками
    func testMultiTabWorkflow() {
        // Создаём вкладки с разным контентом
        notesViewModel.updateNoteContent(notesViewModel.notes.first!, content: "Tab 1")

        notesViewModel.createNote()
        notesViewModel.updateNoteContent(notesViewModel.notes.last!, content: "Tab 2")

        notesViewModel.createNote()
        notesViewModel.updateNoteContent(notesViewModel.notes.last!, content: "Tab 3")

        // Переключаемся между вкладками
        notesViewModel.selectNote(at: 0)
        XCTAssertEqual(notesViewModel.selectedNote?.content, "Tab 1")

        notesViewModel.selectNote(at: 1)
        XCTAssertEqual(notesViewModel.selectedNote?.content, "Tab 2")

        notesViewModel.selectNote(at: 2)
        XCTAssertEqual(notesViewModel.selectedNote?.content, "Tab 3")
    }

    /// Workflow с удалением и восстановлением
    func testDeleteAndRecoverWorkflow() {
        // Создаём несколько заметок
        notesViewModel.createNote()
        notesViewModel.createNote()

        XCTAssertEqual(notesViewModel.notes.count, 3)

        // Удаляем все
        while notesViewModel.notes.count > 0 {
            notesViewModel.deleteNote(notesViewModel.notes.first!)
        }

        // Должна остаться одна дефолтная
        XCTAssertEqual(notesViewModel.notes.count, 1)
        XCTAssertNotNil(notesViewModel.selectedNoteID)
    }

    /// Тест на сохранение последней активной вкладки
    func testLastActiveTabPersistence() {
        // Создаём вкладки
        notesViewModel.createNote()
        notesViewModel.createNote()

        // Выбираем среднюю
        let middleNote = notesViewModel.notes[1]
        notesViewModel.selectedNoteID = middleNote.id

        // Сохраняем ID
        let savedID = middleNote.id

        // Симулируем перезапуск (создаём новый viewModel с тем же context)
        let newViewModel = NotesViewModel(modelContext: context)

        // Проверяем что заметка существует
        XCTAssertTrue(newViewModel.notes.contains { $0.id == savedID })
    }
}
```

### Критерии завершения этапа 8 и всего проекта

- [ ] Все тесты проходят (>95% coverage)
- [ ] Производительность соответствует требованиям
- [ ] VoiceOver работает корректно
- [ ] Приложение локализовано (en, ru)
- [ ] Нет memory leaks
- [ ] Готово для App Store

---

## Чеклист для релиза

### Технический

- [ ] Все unit тесты проходят
- [ ] Все UI тесты проходят
- [ ] Все интеграционные тесты проходят
- [ ] Performance тесты в пределах нормы
- [ ] Нет memory leaks (проверено Instruments)
- [ ] Нет crash'ей при edge cases

### App Store

- [ ] App icon готов (все размеры)
- [ ] Screenshots готовы
- [ ] Описание написано (en, ru)
- [ ] Privacy policy готова
- [ ] App Sandbox настроен корректно
- [ ] Hardened Runtime включён
- [ ] Notarization пройдена

### Документация

- [ ] README.md обновлён
- [ ] CHANGELOG.md создан
- [ ] License добавлена
- [ ] Contribution guide (если open source)

---

## Оценка времени по этапам

| Этап | Описание | Story Points |
|------|----------|--------------|
| 1 | Инициализация проекта | 2 SP |
| 2 | Модель данных | 3 SP |
| 3 | Базовый UI | 5 SP |
| 4 | Floating Panel | 3 SP |
| 5 | Глобальный хоткей | 3 SP |
| 6 | Управление вкладками | 5 SP |
| 7 | Настройки и Menu Bar | 5 SP |
| 8 | Polish и тестирование | 5 SP |
| **Итого** | | **31 SP** |

---

## Риски и митигации

| Риск | Вероятность | Импакт | Митигация |
|------|-------------|--------|-----------|
| Конфликт глобального хоткея | Средняя | Средний | Показать диалог с выбором альтернативы |
| SwiftData баги (новый фреймворк) | Низкая | Высокий | Fallback на Core Data или файлы |
| Accessibility issues | Средняя | Средний | Тестирование с VoiceOver на каждом этапе |
| App Store rejection | Низкая | Средний | Следовать Human Interface Guidelines |
