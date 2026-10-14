import pathlib
from collections import Counter

from packagerutils import Module, discover_modules
from pyvis.network import Network

net = Network(directed=True, notebook=False)

mods = [
    mod for mod in discover_modules(pathlib.Path("../src")).all_modules.values() if True
]
mod_weights: Counter[str] = Counter(
    module_id for mod in mods for module_id in (mod.id, *mod.required_modules)
)


def get_color(module: Module) -> str:
    return f"#{abs(hash(module.id)) % 16777215:x}"


net.add_nodes(
    [mod.id for mod in mods],
    label=[mod.label for mod in mods],
    color=[get_color(mod) for mod in mods],
    mass=[mod_weights[mod.id] for mod in mods],
    value=[mod_weights[mod.id] * 10 for mod in mods],
    group=[mod.category for mod in mods],
)

for mod in mods:
    color = abs(hash(mod.id)) % 16777215

    for other_mod in mod.required_modules:
        net.add_edge(other_mod, mod.id, color=color)


net.save_graph("graph.html")
