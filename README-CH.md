# PyInstaller Build Binary Docker Image Guide

修改程式碼以適應本地執行和 PyInstaller 兩個環境。  
使用 PyInstaller 作為 binary 檔來建立 Docker Image，包括所有所需的套件，並使用 Docker Compose 啟動它，同時掛載設定檔。


## Overview

- Language: Python v3.9
- Tool: PyInstaller v6.11.0

## PyInstaller Introduction

參考 [PyInstaller 官方手冊](https://pyinstaller.org/en/stable/)  
PyInstaller 可以將 Python 專案打包成可執行檔，方便在沒有 Python 環境的機器上直接執行。

### Command

將 `main.py` 打包成可執行檔的基本指令
```sh
pyinstaller main.py
```

### Issues and Solutions

- **打包後產生多個檔案**  
   預設情況下，PyInstaller 會在當前目錄下生成 `build` 資料夾，內含多個檔案。如果希望只生成一個可執行檔，可使用 `--onefile` 參數。執行後可執行檔會放在 `dist` 資料夾中：

- **跨平台相容性**  
   在 Windows 環境下生成的檔案為 `.exe` 格式，無法在 Linux 環境中執行。為避免相容性問題，直接在 Dockerfile 中打包，以確保執行環境一致。

- **套件依賴處理**  
   PyInstaller 需要將所有依賴的套件一同打包。可以撰寫 `requirements.txt`，安裝後使用 `--collect-all` 參數以確保所有套件都被包含：

- **檔案路徑問題**  
   打包後的程式在運行時，會暫時解壓至 `/tmp` 資料夾，而外部掛載的設定檔掛載於`/app`，因此必須根據執行環境（`/tmp` 或 `/app`）調整路徑`BASE_DIR` 變數來設定正確的目錄位置。


## Steps

### 1. Adjust Code

參考 [Stackoverflow 問題](https://stackoverflow.com/questions/70405069/pyinstaller-executable-saves-files-to-temp-folder)  

原先我們使用

```py
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
```

但在使用 PyInstaller 建置後，實際上是在 /tmp 下面的某個資料夾中運行檔案。  
因此，我們需要區分一起打包進去的程式路徑和掛載的設定檔路徑。

```py
# get the base directory for the main script
def get_base_dir():
    if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
        base_dir = os.path.dirname(sys.executable)
    else:
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    return base_dir
BASE_DIR = get_base_dir()

# get the temporary directory used by PyInstaller
def get_data_folder():
    if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
        data_folder_path = sys._MEIPASS
    else:
        data_folder_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return data_folder_path
DATA_DIR = get_data_folder()
```

除此之外還要修改程式碼中的資料夾路徑，YAML 路徑使用 `BASE_DIR`，而程式路徑使用 `DATA_DIR`。


### 2. Write Down Required Modules

將所需的套件寫入 `requirements.txt`  

如果你使用 .venv：
```bash
pip freeze > requirements.txt
```

### 3. Dockerfile

參考 [Dockerfile](Dockerfile)  

在 Dockerfile 中，你需要將 `{EXECUTABLE_FILE_NAME}` 修改為所需的檔名，將 `{MODULE}` 修改為需要包含的套件，將 `{ENTRY_FILE}` 修改為專案的入口檔案，通常是 manage.py 或 main.py，並修改運行 Python的指令。  

詳細實作步驟：  
- 安裝所需的依賴和函式庫（請根據需要進行調整）。
- 將程式碼複製到 image 內。
- 根據 `requirements.txt` 安裝套件。
- 安裝 PyInstaller，將其建置成一個檔案，該檔案將自動生成在 /dist 資料夾下。
- 使用新的 image，只複製 /dist 資料夾中的執行檔，以減少 image 大小。

### 4. Docker Compose

參考 [docker-compose.yml](docker-compose.yml)  
將設定檔掛載到 `/app` 下  

```bash
docker-compose up -d
```