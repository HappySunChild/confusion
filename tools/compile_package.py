import pathlib

from packagerutils import discover_modules, generate_package

discovered = discover_modules(pathlib.Path("../src"))
discovered.selected_modules.update(discovered.all_modules.keys())

print(discovered.selected_modules)

generate_package(
    discovered,
    pathlib.Path("./test_package"),
)
