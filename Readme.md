# 🎬 MPDP (Media Player For Disabled People)

![Python](https://img.shields.io/badge/Python-3.x-blue?style=for-the-badge&logo=python)
![PySide6](https://img.shields.io/badge/PySide6-Qt_Quick-41CD52?style=for-the-badge&logo=qt)
![SQLite](https://img.shields.io/badge/SQLite-Database-003B57?style=for-the-badge&logo=sqlite)

**MPDP** is a desktop application designed to provide an accessible, inclusive, and intuitive media playback experience for people with disabilities. 
The project combines powerful Python backend logic with a modern, responsive Qt Quick (QML) user interface.

---

## ✨ Key Features

- ♿ **Accessibility First**: Specifically designed for easy and intuitive operation.
- 📁 **Integrated File Browser**: Smooth navigation through local media files.
- ⏯️ **Smart Media Playback**: Automatic saving of playback progress and management of watch history.
- 🎨 **Theme Support**: Customizable user interface via JSON-based themes (e.g., `classic.json`).
- 💾 **Local Database**: Efficient data storage (logs, progress, history) using SQLite.

---

## 🛠️ Technology Stack

- **Frontend**: Qt 6 / QML (Qt Quick) for smooth and modern UI components.
- **Backend**: Python 3 with PySide6.
- **Database**: SQLite (`media.sqlite` for history & progress).
- **Configuration**: JSON (user data & themes).

---

## 🏗️ Project Architecture

The project is divided into clearly structured modules separating frontend and backend:

*   **`main.py`**: The main entry point. Initializes the app, loads the QML engine, and connects Python logic to the frontend.
*   **`media_DB.py`**: Interacts with the SQLite database (saves playback status, history, and logs).
*   **`fileHandler.py`**: Handles file system navigation and management.
*   **`theme.py`**: Controls visual representation and themes.
*   **Folder Structure (QML)**:
    *   `StartPage/` - The application's start screen.
    *   `FileBrowser/` - Visual representation of file management.
    *   `MultiMediaPlayer/` - The actual player controls and interface.

---

## 🚀 Installation & Setup

### Prerequisites
- Python 3 installed
- Git (optional, for cloning the repo)

### Step-by-Step Guide

1. **Clone the repository**
   ```bash
   git clone https://github.com/Niklas-Allard/MPDP.git
   cd MPDP
   ```

2. **Create and activate a virtual environment (Recommended)**
   *Windows:*
   ```bash
   python -m venv .venv
   .venv\Scripts\Activate.ps1
   ```
   *Linux/macOS:*
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the application**
   ```bash
   python main.py
   ```

---

## 🧑‍💻 Development & Build

- **Signals & Slots**: The project uses Qt's signal-slot mechanism for seamless communication between Python and QML. (Context properties like `fileManager` and `media_DB` are directly available in QML).
- **Resources**: Graphics and icons are loaded via the compiled resource file `resources.rcc`.
- **Build for Deployment**: The app can be built for release using the `pysidedeploy.spec` configuration.

---

## 🤝 Contributing

Since this project aims at accessibility, suggestions to improve it (e.g., screen reader compatibility, contrast updates, or navigation simplifications) are especially welcome!
Feel free to create an issue or open a pull request.