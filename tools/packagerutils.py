import enum
import pathlib
import shutil
from dataclasses import dataclass
from json import load
from typing import Any


class AssociatedRuntime(enum.Enum):
    Luau = "luau"
    Roblox = "rbx"


class ModulesValidationException(Exception):
    pass


class MissingSrcDirectoryException(ModulesValidationException):
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


@dataclass
class Module:
    is_core: bool
    id: str
    label: str
    category: str
    required_modules: list[str]
    export_types: list[ModuleTypeExport]
    export_members: list[ModuleMemberExport]
    runtime: AssociatedRuntime
    external_providers: ModuleExternalProviders

    def __post_init__(self) -> None:
        self.required_modules = self.required_modules or []
        self.export_types = self.export_types or []
        self.export_members = self.export_members or []

    @classmethod
    def from_dict(cls, id: str, info: dict[str, Any]) -> "Module":
        return Module(
            id=id,
            label=info.get("label", id),
            category=info.get("category", ""),
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


@dataclass
class ModuleSelection:
    all_modules: dict[str, Module]
    selected_modules: set[str]
    src_path: pathlib.Path

    def iter_modules(self):
        for mod_id in self.selected_modules:
            yield self.all_modules[mod_id]


def discover_modules(search_dir: pathlib.Path) -> ModuleSelection:
    collected_modules = {}

    for package_dir in search_dir.iterdir():
        if not package_dir.is_dir():
            continue

        mod_json_path = package_dir / "mod.json"
        if not mod_json_path.is_file():
            continue

        module_id = package_dir.name

        with open(mod_json_path, "r") as f:
            collected_modules[module_id] = Module.from_dict(module_id, load(f))

    return ModuleSelection(
        all_modules=collected_modules, selected_modules=set[str](), src_path=search_dir
    )


def validate_module_selection(selection: ModuleSelection) -> None:
    if not selection.src_path.exists():
        raise MissingSrcDirectoryException(selection.src_path)

    missing_modules: list[str] = []

    for mod in selection.iter_modules():
        for required_mod in mod.required_modules:
            if required_mod not in selection.selected_modules:
                missing_modules.append(required_mod)

        if not (selection.src_path / mod.id).exists():
            raise MissingModuleDirectoryException(selection.src_path / mod.id)

    if len(missing_modules) > 0:
        raise MissingRequiredModulesException(missing_modules)


def generate_package_init_source(
    selection: ModuleSelection,
    name: str,
    author: str,
    repository: str,
) -> str:
    header_segment: list[str] = [
        "--[=[",
        "This package was generated using Confusion's automated packager!",
        f"package: {name}",
        f"author: {author}",
        f"repository: {repository}",
        "--]=]",
    ]

    type_export_segment: list[str] = []
    confusion_type_segment: list[str] = ["export type Confusion = {"]
    member_export_segment: list[str] = ["return {"]

    for mod in selection.iter_modules():
        mod_types = mod.export_types
        mod_members = mod.export_members

        has_types = len(mod_types) > 0
        has_members = len(mod_members) > 0

        if has_types or has_members:
            type_export_segment.extend(
                (
                    f"-- {mod.label}",
                    f"const {mod.id} = require('@self/{mod.id}/types')",
                )
            )

        if has_types:
            type_export_segment.extend(
                f"export type {type_export.export_name} = {mod.id}.{type_export.name}"
                for type_export in mod_types
            )

        if has_types or has_members:
            type_export_segment.append("")

        if has_members:
            confusion_type_segment.extend(
                "\t" + s
                for s in (
                    f"-- {mod.label}",
                    *(
                        f"{member.export_name}: {member.type},"
                        for member in mod_members
                    ),
                    "",
                )
            )
            member_export_segment.extend(
                "\t" + s
                for s in (
                    f"-- {mod.label}",
                    *(
                        f'{member.export_name} = require("@self/{mod.id}/{member.source.removesuffix(".luau")}"),'
                        for member in mod_members
                    ),
                    "",
                )
            )

    confusion_type_segment.append("}")
    member_export_segment.append("} :: Confusion")

    return f"\n\n{'-' * 60}\n\n".join(
        "\n".join(segment)
        for segment in (
            header_segment,
            type_export_segment,
            confusion_type_segment,
            member_export_segment,
        )
    )


def generate_package(
    selection: ModuleSelection,
    dst_path: pathlib.Path,
    package_name: str = "confusion",
    author: str = "HappySunChild (Eli)",
    repository: str = "https://github.com/HappySunChild/confusion",
) -> None:
    validate_module_selection(selection)

    dst_path /= package_name
    dst_path.mkdir(parents=True, exist_ok=True)

    with open(dst_path / "init.luau", "w") as f:
        f.write(
            generate_package_init_source(selection, package_name, author, repository)
        )

    for mod_id in selection.selected_modules:
        shutil.copytree(
            selection.src_path / mod_id, dst_path / mod_id, dirs_exist_ok=True
        )
