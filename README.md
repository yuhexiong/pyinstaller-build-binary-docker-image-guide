# PyInstaller Build Binary Docker Image Guide


Adjust code to accommodate both local running and PyInstaller build environments.  
Building a Docker Image with PyInstaller as a Binary including all required packages and launch it using Docker Compose with mounted configuration files.  



## Overview

- Language: Python v3.9
- Tool: PyInstaller v6.11.0

## Adjust Code

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


## Write Down Required Modules

write the required modules into `requirements.txt`  

if using .venv
```bash
pip freeze > requirements.txt
```

## Dockerfile

refer to [Dockerfile](Dockerfile)  

In the Dockerfile, you need to modify `{EXECUTABLE_FILE_NAME}` to the desired filename, `{MODULE}` to the packages that need to be included, and `{ENTRY_FILE}` to the project entry point, which is usually manage.py or main.py and modify command to run python.  

Detailed Implementation Steps:  
- Install the required dependencies and libraries (please adjust as needed).
- Copy the code into the image.
- Install modules according to `requirements.txt`.
- Install PyInstaller(using PyInstaller in Docker can avoid issues related to differences in running on a personal computer and Linux), build it into a single file, which will be automatically generated in the /dist folder.
- Use the new image and only copy the executable from the `/dist` folder to reduce the image size.

## Docker Compose

refer to [docker-compose.yml](docker-compose.yml)  
mount the configuration files under `/app`  

```bash
docker-compose up -d
```
