import enum
import json
import logging
import os
import pathlib
import shutil
from collections.abc import Iterable

from pydantic import BaseModel, ConfigDict, Field

MODULE_JSON_FILE_NAME = "module.json"
TYPES_LUAU_FILE_NAME = "types.luau"

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


class Runtime(enum.Enum):
    Luau = "luau"
    Roblox = "roblox"


class ModulesValidationException(Exception):
    pass


class MissingModuleDirectoryException(ModulesValidationException):
    pass


class MissingRequiredModulesException(ModulesValidationException):
    pass


class ModuleTypeExport(BaseModel):
    export_name: str
    name: str


class ModuleMemberExport(BaseModel):
    export_name: str
    source: str
    type: str


class ModuleExternalProviders(BaseModel):
    logger_source: str | None = None
    scheduler_source: str | None = None
    debugger_source: str | None = None


class Module(BaseModel):
    src_path: pathlib.Path
    id: str
    name: str = Field(default_factory=lambda d: d["id"])
    description: str
    category: str = "unspecified"

    dependencies: list[str]

    supplies_types: bool

    export_types: list[ModuleTypeExport]
    export_members: list[ModuleMemberExport]

    runtime: Runtime = Runtime.Luau
    external_providers: ModuleExternalProviders | None = None

    def require(self, source_path: str) -> str:
        return f'require("@self/{self.id}/{source_path.removesuffix(".luau")}")'


class Package(BaseModel):
    name: str
    description: str
    author: str
    repository: str
    modules: dict[str, Module]

    model_config = ConfigDict()


def discover_modules(src_path: pathlib.Path) -> dict[str, Module]:
    collected_modules = {}

    for package_dir in src_path.iterdir():
        if not package_dir.is_dir():
            continue

        mod_json_path = package_dir / MODULE_JSON_FILE_NAME
        if not mod_json_path.is_file():
            continue

        has_types = (package_dir / TYPES_LUAU_FILE_NAME).exists()

        module_id = package_dir.name

        with open(mod_json_path, "r") as f:
            collected_modules[module_id] = Module(
                id=module_id,
                src_path=package_dir,
                supplies_types=has_types,
                **json.load(f),
            )

    return collected_modules


def validate_module_selection(selection: dict[str, Module]) -> None:
    missing_modules: set[str] = set()

    for mod in selection.values():
        for required_mod in mod.dependencies:
            if required_mod not in selection:
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


def _determine_provider_module(selection: dict[str, Module]) -> Module | None:
    # TODO: something more sophisticated
    for mod in selection.values():
        if mod.external_providers is not None:
            return mod


def _generate_package_init_source(
    selection: dict[str, Module],
    name: str,
    author: str,
    repository: str,
) -> str:
    module_header_subsection: list[str] = [
        f"total module count: {len(selection)}",
        "included modules:",
        *(
            f"\t{mod.name:20} {f'({mod.id})':20} - {mod.description}"
            for mod in selection.values()
        ),
    ]

    external_provisions: list[str] = []
    external_header_subsection: list[str] = []

    provider_mod = _determine_provider_module(selection)

    if provider_mod and provider_mod.external_providers:
        core_external_mod = selection["core_external"]

        providers = provider_mod.external_providers

        scheduler_src = providers.scheduler_source
        logger_src = providers.logger_source
        debugger_src = providers.debugger_source

        external_provisions.extend(
            (
                f"{core_external_mod.require('ExternalScheduler')}.set_scheduler({provider_mod.require(scheduler_src)})"
                if scheduler_src
                else "-- no external scheduler",
                f"{core_external_mod.require('ExternalLogger')}.set_logger({provider_mod.require(logger_src)})"
                if logger_src
                else "-- no external logger",
                f"{core_external_mod.require('ExternalDebugger')}.set_debugger({provider_mod.require(debugger_src)})"
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

    package_info_header = [
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

    for mod in selection.values():
        types = mod.export_types
        members = mod.export_members

        if not types and not members:
            continue

        if mod.supplies_types:
            append_module_section(
                type_exports,
                mod.name,
                (
                    f"const {mod.id} = {mod.require('types')}",
                    *(
                        f"export type {item.export_name} = {mod.id}.{item.name}"
                        for item in types
                    ),
                ),
            )

        append_module_section(
            confusion_members,
            mod.name,
            (f"{item.export_name}: {item.type}," for item in members),
        )

        append_module_section(
            member_exports,
            mod.name,
            ((f"{item.export_name} = {mod.require(item.source)},") for item in members),
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
        package_info_header,
        type_exports,
        confusion_type,
        external_provisions,
        runtime_exports,
    )


def build_package(
    selection: dict[str, Module],
    dst_path: pathlib.Path,
    package_name: str = "confusion",
    author: str = "HappySunChild (Eli)",
    repository: str = "https://github.com/HappySunChild/confusion",
) -> None:
    validate_module_selection(selection)

    dst_path /= "confusion"

    if dst_path.exists() and dst_path.is_dir():
        logger.warning("directory '%s' already exists, removing...", dst_path)
        shutil.rmtree(dst_path)

    logger.debug("creating directory '%s'", dst_path)
    dst_path.mkdir(parents=True, exist_ok=True)

    with open(dst_path / "init.luau", "w") as f:
        logger.debug("generating package init.luau source...")
        f.write(
            _generate_package_init_source(selection, package_name, author, repository)
        )

    logger.debug("copying over modules...")
    for mod in selection.values():
        module_dst_path = dst_path / mod.id

        logger.debug(
            "copying module '%s' ('%s' -> '%s')",
            mod.id,
            mod.src_path,
            module_dst_path,
        )
        shutil.copytree(mod.src_path, module_dst_path, dirs_exist_ok=True)
        os.remove(module_dst_path / MODULE_JSON_FILE_NAME)

    logger.debug("adding notices to mirrored package modules...")
    for file_path in dst_path.rglob("*.luau"):
        if not file_path.is_file():
            continue

        temp_file_path = file_path.parent / f"{file_path.name}_temp"

        logger.debug("adding notice to '%s'", file_path)
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
