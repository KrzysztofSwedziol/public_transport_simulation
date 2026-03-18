from mesa import Model
from mesa.space import NetworkGrid
import networkx as nx

class City(Model):
    def __init__(self, width, height):
        super().__init__()
        self.width = width
        self.height = height
        self.graph = nx.Graph()
        self.grid = NetworkGrid(self.graph)

    def print_city(self):
        print("Węzły miasta:")
        for node, data in self.graph.nodes(data=True):
            print(f"  Node {node}: {data}")
        print("\nKrawędzie miasta:")
        for u, v, data in self.graph.edges(data=True):
            print(f"  Edge {u}-{v}: {data}")

    def generate_city(self):
        node_id = 0
        for x in range(self.width):
            for y in range(self.height):
                self.graph.add_node(node_id, pos=(x, y))
                node_id += 1

        for node, data in self.graph.nodes(data=True):
            x, y = data['pos']
            neighbors = [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]
            for nx_pos, ny_pos in neighbors:
                for other_node, other_data in self.graph.nodes(data=True):
                    if other_data['pos'] == (nx_pos, ny_pos):
                        if not self.graph.has_edge(node, other_node):
                            self.graph.add_edge(node, other_node)

    def add_node(self, node_id, pos, name=None):
        """
        node_id: unikalny identyfikator węzła
        pos: (x, y)
        name: opcjonalna nazwa węzła, np. 'bus_stop', 'station'
        """
        self.graph.add_node(node_id, pos=pos, name=name)
    def add_edge(self, node1, node2, edge_type):
        weight_map = {
            'sidewalk': 3,
            'road': 2,
            'tram': 1
        }
        weight = weight_map.get(edge_type, 1)
        self.graph.add_edge(node1, node2, edge_type=edge_type, weight=weight)