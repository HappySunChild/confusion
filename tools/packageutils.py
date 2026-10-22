import enum
import json
import os
import pathlib
import shutil
from collections.abc import Iterable
from dataclasses import dataclass
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


@dataclass(frozen=True)
class ModuleTypeExport:
    export_name: str
    name: str


@dataclass(frozen=True)
class ModuleMemberExport:
    export_name: str
    source: str
    type: str


@dataclass(frozen=True)
class ModuleExternalProviders:
    logger_source: str | None
    scheduler_source: str | None
    debugger_source: str | None

    @classmethod
    def from_dict(cls, info: dict[str, str]) -> "ModuleExternalProviders":
        return ModuleExternalProviders(
            logger_source=info.get("logger_source"),
            scheduler_source=info.get("scheduler_source"),
            debugger_source=info.get("debugger_source"),
        )


@dataclass(frozen=True)
class Module:
    src_path: pathlib.Path
    id: str
    label: str
    description: str
    category: str
    required_modules: list[str]
    export_types: list[ModuleTypeExport]
    export_members: list[ModuleMemberExport]
    runtime: AssociatedRuntime
    external_providers: ModuleExternalProviders | None

    @classmethod
    def from_dict(cls, src_path: pathlib.Path, info: dict[str, Any]) -> "Module":
        id = src_path.name

        external_providers = info.get("external_providers")

        return Module(
            src_path=src_path,
            id=id,
            label=info.get("label", id),
            description=info.get("description", "no description"),
            category=info.get("category", "unspecified"),
            required_modules=info["requires"],
            export_types=[
                ModuleTypeExport(**export) for export in info["export_types"]
            ],
            export_members=[
                ModuleMemberExport(**export) for export in info["export_members"]
            ],
            runtime=AssociatedRuntime(info.get("runtime", "luau")),
            external_providers=ModuleExternalProviders.from_dict(external_providers)
            if external_providers
            else None,
        )

    def req_src(self, source_path: str) -> str:
        return f'require("@self/{self.id}/{source_path.removesuffix(".luau")}")'


class ModuleSelection:
    selected_ids: set[str]
    module_reference: dict[str, Module]

    def __init__(self, modules: Iterable[Module]) -> None:
        self.module_reference = {mod.id: mod for mod in modules}
        self.selected_ids = set(self.module_reference.keys())

    def add_module(self, module: Module):
        self.selected_ids.add(module.id)
        self.module_reference[module.id] = module

    def iter_modules(self):
        yield from self.module_reference.values()

    def iter_ids(self):
        yield from self.selected_ids


@dataclass(frozen=True)
class Package:
    name: str
    description: str
    author: str
    repository: str
    modules: ModuleSelection

    @classmethod
    def from_dict(
        cls, module_mapping: dict[str, Module], info: dict[str, Any]
    ) -> "Package":
        return Package(
            name=info["name"],
            description=info["description"],
            author=info["author"],
            repository=info["repository"],
            modules=ModuleSelection(
                module_mapping[mod_id] for mod_id in info["modules"]
            ),
        )


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
            collected_modules[module_id] = Module.from_dict(package_dir, json.load(f))

    return collected_modules


def validate_module_selection(selection: ModuleSelection) -> None:
    missing_modules: set[str] = set()

    for mod in selection.iter_modules():
        for required_mod in mod.required_modules:
            if required_mod not in selection.selected_ids:
                missing_modules.add(required_mod)

        module_src_path = mod.src_path

        if not module_src_path.exists():
            raise MissingModuleDirectoryException(module_src_path)

    if len(missing_modules) > 0:
        raise MissingRequiredModulesException(missing_modules)


def _join_sections(*sections: list[str]) -> str:
    return f"\n\n{'-' * 60}\n\n".join(
        "\n".join(section).strip() for section in sections if section
    )


def _determine_provider_module(selection: ModuleSelection) -> Module | None:
    # TODO: something more sophisticated
    for mod in selection.iter_modules():
        if mod.external_providers is not None:
            return mod


def _generate_package_init_source(
    selection: ModuleSelection,
    name: str,
    author: str,
    repository: str,
) -> str:
    module_header_subsection: list[str] = [
        f"total module count: {len(selection.selected_ids)}",
        "included modules:",
        *(
            f"\t{mod.label:20} {f'({mod.id})':20} - {mod.description}"
            for mod in selection.iter_modules()
        ),
    ]

    external_provisions: list[str] = []
    external_header_subsection: list[str] = []

    provider_mod = _determine_provider_module(selection)

    if provider_mod and provider_mod.external_providers:
        core_external_mod = selection.module_reference["core_external"]

        providers = provider_mod.external_providers

        scheduler_src = providers.scheduler_source
        logger_src = providers.logger_source
        debugger_src = providers.debugger_source

        external_provisions.extend(
            (
                f"{core_external_mod.req_src('ExternalScheduler')}.set_scheduler({provider_mod.req_src(scheduler_src)})"
                if scheduler_src
                else "-- no external scheduler",
                f"{core_external_mod.req_src('ExternalLogger')}.set_logger({provider_mod.req_src(logger_src)})"
                if logger_src
                else "-- no external logger",
                f"{core_external_mod.req_src('ExternalDebugger')}.set_debugger({provider_mod.req_src(debugger_src)})"
                if debugger_src
                else "-- no external debugger",
            )
        )

        external_header_subsection.extend(
            (
                "",
                "external provider:",
                f"\tmodule: {provider_mod.id}",
                f"\thas scheduler: {'yes' if scheduler_src else 'no'}",
                f"\thas logger: {'yes' if logger_src else 'no'}",
                f"\thas debugger: {'yes' if debugger_src else 'no'}",
                "",
            )
        )

    header = [
        "--[=[",
        "This package was generated using Confusion's automated packager!",
        f"package: {name}",
        f"author: {author}",
        f"repository: {repository}",
        "",
        *module_header_subsection,
        *external_header_subsection,
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
        ls = tuple(lines)

        if len(ls) == 0:
            return

        target.extend((f"-- {label}", *ls, ""))

    for mod in selection.iter_modules():
        types = mod.export_types
        members = mod.export_members

        if not types and not members:
            continue

        append_module_section(
            type_exports,
            mod.label,
            (
                f"const {mod.id} = {mod.req_src('types')}",
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
            ((f"{item.export_name} = {mod.req_src(item.source)},") for item in members),
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

    return _join_sections(
        header, type_exports, confusion_type, external_provisions, runtime_exports
    )


def build_package(
    selection: ModuleSelection,
    dst_path: pathlib.Path,
    package_name: str = "confusion",
    author: str = "HappySunChild (Eli)",
    repository: str = "https://github.com/HappySunChild/confusion",
) -> None:
    validate_module_selection(selection)

    dst_path /= "confusion"
    dst_path.mkdir(parents=True, exist_ok=True)

    with open(dst_path / "init.luau", "w") as f:
        f.write(
            _generate_package_init_source(selection, package_name, author, repository)
        )

    for mod in selection.iter_modules():
        module_dst_path = dst_path / mod.id
        shutil.copytree(mod.src_path, module_dst_path, dirs_exist_ok=True)
        os.remove(module_dst_path / "mod.json")

    luau_module_files = [file for file in dst_path.rglob("*.luau") if file.is_file()]

    for file_path in luau_module_files:
        temp_file_path = file_path.parent / f"{file_path.name}_temp"

        with (
            open(temp_file_path, "w", encoding="utf8") as temp_file,
            open(file_path, "r", encoding="utf8") as original_file,
        ):
            temp_file.write(
                "-- NOTICE: THIS FILE IS MIRRORED/TEMPORARY! DO NOT MODIFY THIS FILE IF YOU WANT YOUR CHANGES TO SAVE!\n"
                * 16
                + "\n"
            )

            temp_file.writelines(original_file)
        os.replace(temp_file_path, file_path)


def build_package_from_package(package: Package, dst_path: pathlib.Path) -> None:
    build_package(
        package.modules, dst_path, package.name, package.author, package.repository
    )
