from collections import Counter

from packagerutils import load_modules
from pyvis.network import Network

net = Network(directed=True, notebook=False)

mods = [mod for mod in load_modules("./modules.json").values() if mod.is_core]
mod_weights: Counter[str] = Counter()

for mod in mods:
    mod_weights[mod.id] += 1
    for required_mod in mod.required_modules:
        mod_weights[required_mod] += 1

for mod in mods:
    color = abs(hash(mod.id)) % 16777215

    net.add_node(mod.id, value=mod_weights[mod.id], color=f"#{color:x}")

for mod in mods:
    color = abs(hash(mod.id)) % 16777215

    for other_mod in mod.required_modules:
        net.add_edge(mod.id, other_mod, color=color)

net.show("test.html", notebook=False)
