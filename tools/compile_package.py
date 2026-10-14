import pathlib

from packagerutils import (
    AssociatedRuntime,
    ModuleSelection,
    build_package,
    discover_modules,
)

discovered = discover_modules(pathlib.Path("../src"))

print([mod for mod in discovered.values() if mod.is_core])

build_package(
    ModuleSelection(
        mod for mod in discovered.values() if mod.runtime != AssociatedRuntime.Roblox
    ),
    pathlib.Path("./out"),
)
