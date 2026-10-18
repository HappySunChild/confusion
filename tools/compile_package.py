import argparse
import json
from pathlib import Path

from packageutils import (
    ModuleSelection,
    build_package,
    discover_modules,
)

parser = argparse.ArgumentParser(description="Confusion's automatic packager")
parser.add_argument("package_name")
parser.add_argument("output_dir", default=".")
parser.add_argument(
    "--confusion_src", default=str(Path(__file__).parent.parent / "src"), nargs=1
)

args = parser.parse_args()

package_path = Path(__file__).parent / f"packages/{args.package_name}.json"
output_dir = Path.cwd() / args.output_dir

with open(package_path, "r", encoding="utf8") as f:
    data = json.load(f)


package_name: str = data["name"]
package_author: str = data["author"]
package_repository: str = data["repository"]
package_modules: list[str] = data["modules"]

modules = discover_modules(Path(args.confusion_src))

selection = ModuleSelection(modules[mod_id] for mod_id in package_modules)

build_package(selection, output_dir, package_name, package_author, package_repository)
