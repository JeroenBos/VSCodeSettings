import importlib.util
import os


def run():
    pwd = os.environ.get("PWD")
    if pwd:
        dir = os.path.join(pwd, ".vscode")
        if not os.path.exists(dir):
            return print("STARTUP_SCRIPT: no .vscode dir found")
        if not os.path.isdir(dir):
            return print(f"ERROR STARTUP_SCRIPT: '{dir}' is not a directory")

        path = os.path.join(dir, "pythonstartup.py")
        if not os.path.exists(path):
            return print("STARTUP_SCRIPT: no '.vscode/pythonstartup.py' found")
        if not os.path.isfile(path):
            return print(f"ERROR STARTUP_SCRIPT: '{path}' is not a directory")

        spec = importlib.util.spec_from_file_location("pythonstartup", path)
        foo = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(foo)

        print("STARTUP_SCRIPT imported")


if not os.getcwd().lower().startswith("c:\\users\\windows\\.vscode\\extensions\\"):
    run()
