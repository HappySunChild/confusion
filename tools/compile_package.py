import argparse
import json
import logging
from pathlib import Path

from packageutils import (
    build_package,
    discover_modules,
)

parser = argparse.ArgumentParser(description="Confusion's automatic packager")
parser.add_argument("package_name")
parser.add_argument("output_dir", default=".")
parser.add_argument(
    "--confusion_src", default=str(Path(__file__).parent.parent / "src"), nargs=1
)
parser.add_argument("-v", default=False, action=argparse.BooleanOptionalAction)

args = parser.parse_args()

package_path = Path(args.package_name).resolve()
output_dir = Path(args.output_dir).resolve()

with open(package_path, "r", encoding="utf8") as f:
    data = json.load(f)


if args.v:
    logging.basicConfig()


package_name: str = data["name"]
package_author: str = data["author"]
package_repository: str = data["repository"]
package_modules: list[str] = data["modules"]

all_modules = discover_modules(Path(args.confusion_src))
specified_modules = {
    mod_id: mod for (mod_id, mod) in all_modules.items() if mod_id in package_modules
}

build_package(
    specified_modules, output_dir, package_name, package_author, package_repository
)
