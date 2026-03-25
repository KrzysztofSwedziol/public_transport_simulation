from mesa import Model
from mesa.space import NetworkGrid
import networkx as nx
import matplotlib.pyplot as plt
import matplotlib.lines as mlines


class City(Model):
    def __init__(self, width, height):
        super().__init__()
        self.width = width
        self.height = height
        self.graph = nx.MultiGraph()
        self.grid = NetworkGrid(self.graph)

    #name of node is for example bus_stop
    def add_node(self, node_id, pos, name=None):
        self.graph.add_node(node_id, pos=pos, name=name)

    def add_edge(self, node1, node2, edge_type):
        weight_map = {
            'sidewalk': 3,
            'road': 2,
            'tram': 1
        }
        weight = weight_map[edge_type]

        self.graph.add_edge(node1, node2,
                            edge_type=edge_type,
                            weight=weight)

    def generate_city(self):
        nodes = {
            0: ((0, 2), "bus_stop"),
            1: ((1, 2), "intersection"),
            2: ((2, 2), "station"),
            3: ((3, 2), "intersection"),
            4: ((4, 2), "bus_stop"),

            5: ((2, 0), "tram_stop"),
            6: ((2, 1), "intersection"),
            7: ((2, 3), "intersection"),
            8: ((2, 4), "tram_stop"),

            9: ((0, 0), "intersection"),
            10: ((4, 4), "intersection")
        }

        for node_id, (pos, name) in nodes.items():
            self.add_node(node_id, pos, name=name)

        roads = [
            (0, 1), (1, 2), (2, 3), (3, 4),
            (5, 6), (6, 2), (2, 7), (7, 8)
        ]

        for u, v in roads:
            self.add_edge(u, v, 'road')

        trams = [
            (0, 2), (2, 4),
            (5, 2), (2, 8)
        ]

        for u, v in trams:
            self.add_edge(u, v, 'tram')

        sidewalks = [
            (0, 1), (1, 2), (2, 3), (3, 4),
            (5, 6), (6, 2), (2, 7), (7, 8),
            (0, 9), (9, 5),
            (4, 10), (10, 8),
            (1, 6), (3, 7)
        ]

        for u, v in sidewalks:
            self.add_edge(u, v, 'sidewalk')

        self.grid = NetworkGrid(self.graph)

    def draw_city(self):
        pos = nx.get_node_attributes(self.graph, 'pos')

        plt.figure(figsize=(6, 6))

        for u, v, key, data in self.graph.edges(keys=True, data=True):
            edge_type = data['edge_type']

            if edge_type == 'road':
                color = 'black'
                width = 4
                offset = 0.00
            elif edge_type == 'tram':
                color = 'red'
                width = 4
                offset = 0.08
            else:
                color = 'lightgray'
                width = 2
                offset = -0.08

            x1, y1 = pos[u]
            x2, y2 = pos[v]

            dx = y2 - y1
            dy = x1 - x2
            length = (dx ** 2 + dy ** 2) ** 0.5
            if length != 0:
                dx /= length
                dy /= length

            x1 += dx * offset
            y1 += dy * offset
            x2 += dx * offset
            y2 += dy * offset

            plt.plot([x1, x2], [y1, y2], color=color, linewidth=width)

        node_colors = []
        node_sizes = []
        labels = {}

        for node, data in self.graph.nodes(data=True):
            node_type = data.get("name", "intersection")

            if node_type == "station":
                node_colors.append("green")
                node_sizes.append(200)
            elif node_type == "bus_stop":
                node_colors.append("orange")
                node_sizes.append(150)
            elif node_type == "tram_stop":
                node_colors.append("purple")
                node_sizes.append(150)
            else:
                node_colors.append("blue")
                node_sizes.append(100)

            labels[node] = f"{node}\n{node_type}"

        nx.draw_networkx_nodes(self.graph, pos, node_color=node_colors, node_size=node_sizes)
        nx.draw_networkx_labels(self.graph, pos, labels=labels, font_size=8)

        import matplotlib.lines as mlines
        plt.legend(handles=[
            mlines.Line2D([], [], color='black', linewidth=4, label='Road'),
            mlines.Line2D([], [], color='red', linewidth=4, label='Tram'),
            mlines.Line2D([], [], color='lightgray', linewidth=2, label='Sidewalk'),
            mlines.Line2D([], [], color='green', marker='o', linestyle='', label='Station'),
            mlines.Line2D([], [], color='orange', marker='o', linestyle='', label='Bus Stop'),
            mlines.Line2D([], [], color='purple', marker='o', linestyle='', label='Tram Stop')
        ])

        plt.title("Miasto z typami węzłów")
        plt.axis('off')
        plt.show()