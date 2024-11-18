# PyInstaller Build Binary Docker Image Guide

**(also provided Traditional Chinese version document [README-CH.md](README-CH.md).)**

Use PyInstaller to package the project into a binary file to build a Docker image, including all required dependencies, and use Docker Compose to start it while mounting configuration files.  


## Overview

- Language: Python v3.9
- Tool: PyInstaller v6.11.0

## PyInstaller Introduction

refer to [PyInstaller Official Manual](https://pyinstaller.org/en/stable/)  
PyInstaller can package Python projects into executable files, making them easier to run on machines without a Python environment.


### Basic Command

#### Basic command to package `{ENTRY_FILE}.py` as an executable file
```sh
pyinstaller {ENTRY_FILE}.py
```

#### Set the name of the packaged executable file as `{EXECUTABLE_FILE_NAME}`
```sh
pyinstaller -n {EXECUTABLE_FILE_NAME} {ENTRY_FILE}.py
```

### Issues and Solutions

- **Multiple files generated after packaging**  
   By default, PyInstaller creates a `build` folder in the current directory, containing multiple files. If you want to generate a single executable file, use the `--onefile` option. The executable will then be placed in the `dist` folder.

- **Cross-platform compatibility**  
   Files generated on Windows are in `.exe` format, which cannot be executed on Linux. To avoid compatibility issues, package the executable directly in the Dockerfile to ensure a consistent environment.

- **Dependency management**  
   PyInstaller needs to include all required dependencies in the package. You can create a `requirements.txt` file, install it, and use the `--collect-all` option to ensure all necessary packages are included.

- **File path issues**  
   After packaging, the program runs temporarily in the `/tmp` folder, while external configuration files are mounted in `/app`. Therefore, the directory path must be adjusted based on the execution environment (`/tmp` or `/app`). Use a `BASE_DIR` variable to set the correct directory location.

### Custom Command

Combine with the above, the command we used is as follows, and it will be included in the Dockerfile in the subsequent steps.  

```bash
pyinstaller --onefile -n {EXECUTABLE_FILE_NAME} --collect-all {MODULE} {ENTRY_FILE}.py
```


## Steps

The implementation steps are divided into 4 stages.  

### 1. Adjust Code

refer to [Stackoverflow Question](https://stackoverflow.com/questions/70405069/pyinstaller-executable-saves-files-to-temp-folder)  

In the past, we used

```py
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
```

however, after building with PyInstaller, the files actually run in a folder under /tmp.  
therefore, we need to distinguish between the program paths packaged together and the paths of the mounted configuration files.

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

also, modify the folder paths in the code so that the YAML paths use `BASE_DIR` and the program paths use `DATA_DIR`.


### 2. Write Down Required Modules

write the required modules into `requirements.txt`  

If using .venv, you can either export the modules to a `requirements.txt` file using a command, or skip this step and directly use `DockerfilePoetry` in the next step.  
```bash
pip freeze > requirements.txt
```

### 3. Dockerfile

**(1) using `requirements.txt`**  

refer to [Dockerfile](Dockerfile)  

**(2) using `poetry`**  

refer to [DockerfilePoetry](DockerfilePoetry)  

In the Dockerfile, you need to modify `{EXECUTABLE_FILE_NAME}` to the desired filename, `{MODULE}` to the packages that need to be included, and `{ENTRY_FILE}` to the project entry point, which is usually manage.py or main.py and modify command to run python.  

Detailed Implementation Steps:  
- Install the required dependencies and libraries (please adjust as needed).
- Copy the code into the image.
- Install modules according to `requirements.txt` or poetry install.  
- Install PyInstaller, build it into a single file, which will be automatically generated in the /dist folder.
- Use the new image and only copy the executable from the `/dist` folder to reduce the image size.

### 4. Docker Compose

refer to [docker-compose.yml](docker-compose.yml)  
mount the configuration files under `/app`  

```bash
docker-compose up -d
```
