import pathlib

from packager import ModuleSelection, generate_package, load_modules

all_modules = load_modules("./modules.json")
selected_modules = list(all_modules.values())

generate_package(
    ModuleSelection(selected_modules, pathlib.Path("../src")),
    pathlib.Path("./test_package"),
)
