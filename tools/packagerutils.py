import enum
import os
import pathlib
import shutil
from collections.abc import Iterable
from dataclasses import dataclass
from json import load
from typing import Any


class AssociatedRuntime(enum.Enum):
    Luau = "luau"
    Roblox = "rbx"


class ModulesValidationException(Exception):
    pass


class MissingModuleDirectoryException(ModulesValidationException):
    pass


class MissingRequiredModulesException(ModulesValidationException):
    pass


@dataclass
class ModuleTypeExport:
    export_name: str
    name: str


@dataclass
class ModuleMemberExport:
    export_name: str
    source: str
    type: str


@dataclass
class ModuleExternalProviders:
    logger_module: str | None
    scheduler_module: str | None
    debugger_module: str | None

    @classmethod
    def from_dict(cls, info: dict[str, Any]) -> "ModuleExternalProviders":
        return ModuleExternalProviders(
            logger_module=info.get("logger_module"),
            scheduler_module=info.get("scheduler_module"),
            debugger_module=info.get("debugger_module"),
        )


@dataclass(frozen=True)
class Module:
    src_path: pathlib.Path
    is_core: bool
    id: str
    label: str
    description: str
    category: str
    required_modules: list[str]
    export_types: list[ModuleTypeExport]
    export_members: list[ModuleMemberExport]
    runtime: AssociatedRuntime
    external_providers: ModuleExternalProviders

    @classmethod
    def from_dict(cls, src_path: pathlib.Path, info: dict[str, Any]) -> "Module":
        id = src_path.name

        return Module(
            src_path=src_path,
            id=id,
            label=info.get("label", id),
            description=info.get("description", "no description"),
            category=info.get("category", "unspecified"),
            is_core=info.get("is_core", False),
            required_modules=info["requires"],
            export_types=[
                ModuleTypeExport(**export) for export in info["export_types"]
            ],
            export_members=[
                ModuleMemberExport(**export) for export in info["export_members"]
            ],
            runtime=AssociatedRuntime(info.get("runtime", "luau")),
            external_providers=ModuleExternalProviders.from_dict(
                info.get("external_capabilities", {})
            ),
        )


class ModuleSelection:
    selected_ids: set[str]
    module_reference: dict[str, Module]

    def __init__(self, modules: Iterable[Module]) -> None:
        self.selected_ids = {mod.id for mod in modules}
        self.module_reference = {mod.id: mod for mod in modules}

    def add_module(self, module: Module):
        self.selected_ids.add(module.id)
        self.module_reference[module.id] = module

    def iter_modules(self):
        yield from self.module_reference.values()

    def iter_ids(self):
        yield from self.selected_ids


def discover_modules(src_path: pathlib.Path) -> dict[str, Module]:
    collected_modules = {}

    for package_dir in src_path.iterdir():
        if not package_dir.is_dir():
            continue

        mod_json_path = package_dir / "mod.json"
        if not mod_json_path.is_file():
            continue

        module_id = package_dir.name

        with open(mod_json_path, "r") as f:
            collected_modules[module_id] = Module.from_dict(package_dir, load(f))

    return collected_modules


def validate_module_selection(selection: ModuleSelection) -> None:
    missing_modules: list[str] = []

    for mod in selection.iter_modules():
        for required_mod in mod.required_modules:
            if required_mod not in selection.selected_ids:
                missing_modules.append(required_mod)

        module_src_path = mod.src_path

        if not module_src_path.exists():
            raise MissingModuleDirectoryException(module_src_path)

    if len(missing_modules) > 0:
        raise MissingRequiredModulesException(missing_modules)


def _join_sections(*sections: list[str]) -> str:
    return f"\n\n{'-' * 60}\n\n".join(
        "\n".join(section).strip() for section in sections if section
    )


def _generate_package_init_source(
    selection: ModuleSelection,
    name: str,
    author: str,
    repository: str,
) -> str:
    header = [
        "--[=[",
        "This package was generated using Confusion's automated packager!",
        f"package: {name}",
        f"author: {author}",
        f"repository: {repository}",
        "",
        "included modules:",
        *(
            f"\t{mod.label:20} {f'({mod.id})':20} - {mod.description}"
            for mod in selection.iter_modules()
        ),
        "--]=]",
    ]

    type_exports: list[str] = []
    confusion_members: list[str] = []
    member_exports: list[str] = []

    def append_module_section(
        target: list[str],
        label: str,
        lines: Iterable[str],
    ) -> None:
        target.extend((f"-- {label}", *lines))

    for mod in selection.iter_modules():
        types = mod.export_types
        members = mod.export_members

        if not types and not members:
            continue

        append_module_section(
            type_exports,
            mod.label,
            (
                f'const {mod.id} = require("@self/{mod.id}/types")',
                *(
                    f"export type {item.export_name} = {mod.id}.{item.name}"
                    for item in types
                ),
            ),
        )

        append_module_section(
            confusion_members,
            mod.label,
            (f"{item.export_name}: {item.type}," for item in members),
        )

        append_module_section(
            member_exports,
            mod.label,
            (
                (
                    f"{item.export_name} = "
                    f'require("@self/{mod.id}/'
                    f'{item.source.removesuffix(".luau")}"),'
                )
                for item in members
            ),
        )

    confusion_type = [
        "export type Confusion = {",
        *(f"\t{line}" for line in confusion_members),
        "}",
    ]

    runtime_exports = [
        "return {",
        *(f"\t{line}" for line in member_exports),
        "} :: Confusion",
    ]

    return _join_sections(header, type_exports, confusion_type, runtime_exports)


def build_package(
    selection: ModuleSelection,
    path_dst_path: pathlib.Path,
    package_name: str = "confusion",
    author: str = "HappySunChild (Eli)",
    repository: str = "https://github.com/HappySunChild/confusion",
) -> None:
    validate_module_selection(selection)

    path_dst_path /= package_name
    path_dst_path.mkdir(parents=True, exist_ok=True)

    with open(path_dst_path / "init.luau", "w") as f:
        f.write(
            _generate_package_init_source(selection, package_name, author, repository)
        )

    for mod in selection.iter_modules():
        module_dst_path = path_dst_path / mod.id
        shutil.copytree(mod.src_path, module_dst_path, dirs_exist_ok=True)
        os.remove(module_dst_path / "mod.json")
