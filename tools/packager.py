import pathlib
import shutil
from collections.abc import Iterable
from dataclasses import dataclass
from json import load
from typing import Any


# TODO: this
class ModulesValidationException(Exception):
    pass


@dataclass
class ModuleTypeExport:
    name: str
    alias: str


@dataclass
class ModuleMemberExport:
    alias: str
    module: str
    associated_type: str


@dataclass
class Module:
    is_core: bool
    name: str
    label: str
    required_modules: list[str]
    export_types: list[ModuleTypeExport]
    export_members: list[ModuleMemberExport]

    def __post_init__(self) -> None:
        self.required_modules = self.required_modules or []
        self.export_types = self.export_types or []
        self.export_members = self.export_members or []

    @classmethod
    def from_dict(cls, name: str, info: dict[str, Any]) -> "Module":
        exports = info["exports"]

        return cls(
            name=name,
            label=info.get("label", name),
            is_core=info.get("is_core", False),
            required_modules=info["requires"],
            export_types=[ModuleTypeExport(**export) for export in exports["types"]],
            export_members=[
                ModuleMemberExport(**export) for export in exports["members"]
            ],
        )


@dataclass
class ModuleSelection:
    modules: list[Module]
    src_path: pathlib.Path


def load_modules(module_json_path: str) -> dict[str, Module]:
    modules = {}

    with open(module_json_path, "r") as mf:
        for name, module_info in load(mf).items():
            modules[name] = Module.from_dict(name, module_info)

    return modules


def validate_module_selection(selection: ModuleSelection) -> None:
    if not selection.src_path.exists():
        raise ModulesValidationException()

    available_modules: tuple[str, ...] = tuple[str, ...](
        mod.name for mod in selection.modules
    )
    missing_modules: list[str] = []

    for mod in selection.modules:
        for required_mod in mod.required_modules:
            if required_mod not in available_modules:
                missing_modules.append(required_mod)

        if not (selection.src_path / mod.name).exists():
            raise ModulesValidationException()

    if len(missing_modules) > 0:
        raise ModulesValidationException()


def generate_package_init_source(
    modules: Iterable[Module],
    package_name: str,
    author: str,
    repository: str,
) -> str:
    header_segment: list[str] = [
        "--[=[",
        "This package was generated using Confusion's automated packager!",
        f"package: {package_name}",
        f"author: {author}",
        f"repository: {repository}",
        "--]=]",
    ]

    type_export_segment: list[str] = []
    confusion_type_segment: list[str] = ["export type Confusion = {"]
    member_export_segment: list[str] = ["return {"]

    for mod in modules:
        mod_types = mod.export_types
        mod_members = mod.export_members

        has_types = len(mod_types) > 0
        has_members = len(mod_members) > 0

        if has_types or has_members:
            type_export_segment.extend(
                (
                    f"-- {mod.label}",
                    f"const {mod.name} = require('@self/{mod.name}/types')",
                )
            )

        if has_types:
            type_export_segment.extend(
                f"export type {type_export.alias} = {mod.name}.{type_export.name}"
                for type_export in mod_types
            )
            type_export_segment.append("")

        if has_members:
            confusion_type_segment.extend(
                "\t" + s
                for s in (
                    f"-- {mod.label}",
                    *(
                        f"{member.alias}: {mod.name}.{member.associated_type},"
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
                        f'{member.alias} = require("@self/{mod.name}/{member.module.removesuffix(".luau")}"),'
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
            generate_package_init_source(
                selection.modules, package_name, author, repository
            )
        )

    for mod in selection.modules:
        shutil.copytree(
            selection.src_path / mod.name, dst_path / mod.name, dirs_exist_ok=True
        )
