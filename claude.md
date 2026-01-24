# CLAUDE.md - MPDP Project Context

## Project Overview

**MPDP (Media Player For Disabled People)** is a desktop application built with PySide6 and Qt Quick (QML) designed to provide an accessible media playback experience. 

**Goal**: Create an inclusive media player application with intuitive file browsing, media playback controls, and accessibility features tailored for users with disabilities.

---

## Important Commands

- **Run application**: `python main.py` (launches the GUI with PySide6)
- **Install dependencies**: `pip install -r requirements.txt`
- **Activate virtual environment** (Windows): `.venv\Scripts\Activate.ps1`
- **Build for deployment**: Uses `pysidedeploy.spec` configuration

---

## Code Style & Rules

- **Language**: Python 3 (PEP 8 style) for backend logic; QML (Qt Quick) for UI
- **Indentation**: 4 spaces for Python files
- **Naming Conventions**:
  - Python classes: `PascalCase` (e.g., `Media_DB`, `fileHandler`)
  - Python functions/variables: `snake_case` (e.g., `get_main_directories`, `set_progress`)
  - QML components: Use descriptive names (e.g., `ApplicationWindow`, `StackView`)
- **Type Hints**: Use Python type hints where applicable
- **Error Handling**: Implement proper exception handling for file operations and database access
- **Signals/Slots**: Use Qt's signal-slot mechanism for PySide6 communication between Python and QML

---

## Architecture & Structure

### Backend (Python)

- **`main.py`**: Entry point; initializes QGuiApplication, loads QML engine, and registers context properties
- **`media_DB.py`**: Database layer (SQLite) managing:
  - Media playback progress tracking
  - Watch history
  - Logging
- **`fileHandler.py`**: File system operations and navigation
- **`theme.py`**: Theme management and styling configuration

### Frontend (QML)

- **`main.qml`**: Root application window with StackView navigation
- **`StartPage/main.qml`**: Initial page/landing screen
- **`FileBrowser/main.qml`**: File browser UI component
- **`MultiMediaPlayer/main.qml`**: Media playback controls and player interface
- **`icons/`**: Icon resources for the application

### Database

- **`database/media.sqlite`**: SQLite database storing:
  - `log`: Application logs
  - `media_progress`: Playback progress for each media file
  - `watch_history`: User's watched media history
- **`database/user_data.json`**: User preferences and configuration
- **`database/themes/`**: Theme definitions (e.g., `classic.json`)

### Resources

- **`resources.rcc`**: Compiled Qt resource file containing icons and assets (mounted at `:/` in QML)

---

## Key Design Patterns

### Context Properties

Python objects are exposed to QML via `engine.rootContext().setContextProperty()`:
- `fileManager`: File navigation and operations
- `media_DB`: Database access for progress and history
- `mainDirs`: Main directory structure from database

### Signal-Slot Communication

- Python methods decorated with `@Slot()` can be called from QML
- Python `Signal` objects emit events that QML can connect to

### Navigation

- Uses QML `StackView` for page navigation (push/pop pages)
- Pages load QML files dynamically from filesystem

---

## Tech Stack

- **Frontend**: Qt 6 / QML (Qt Quick)
- **Backend**: Python 3, PySide6
- **Database**: SQLite
- **Build Tool**: pysidedeploy
- **Package Manager**: pip / requirements.txt

---

## Important Development Notes

1. **QML Module Registration**: The application registers a custom resource file (`resources.rcc`) to load icons and assets
2. **Threading**: Keep long-running operations (database, file I/O) off the UI thread
3. **Accessibility**: This is an accessibility-focused project—ensure all UI elements are screen-reader compatible
4. **QML State Management**: Use anchors and property bindings for responsive UI layouts
5. **Database Transactions**: Always use context managers (`with sqlite3.connect()`) for safe database operations

---

## File Conventions

- Python files use standard `.py` extension
- QML files use `.qml` extension
- Theme files are JSON format
- Configuration uses `pyproject.toml` for project metadata

