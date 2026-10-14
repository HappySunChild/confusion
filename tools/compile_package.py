import pathlib

from packagerutils import ModuleSelection, build_package, discover_modules

discovered = discover_modules(pathlib.Path("../src"))


build_package(
    ModuleSelection(discovered.values()),
    pathlib.Path("./out"),
)
