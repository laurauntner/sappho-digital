import matplotlib.pyplot as plt
import networkx as nx
import matplotlib.image as mpimg
import numpy as np

# Load the image
image_path = 'sappho-reception-digital_logo.png'
img = mpimg.imread(image_path)

# Create a sparse and chaotic graph
G = nx.connected_watts_strogatz_graph(50, 4, 0.1, tries=100, seed=42)  # Ensure connectivity with Watts-Strogatz model

# Define the positions of the nodes for a random layout within a circle
def random_circular_layout(graph):
    pos = {}
    for node in graph.nodes():
        angle = np.random.uniform(0, 2 * np.pi)
        radius = np.sqrt(np.random.uniform(0, 1))
        x = radius * np.cos(angle)
        y = radius * np.sin(angle)
        pos[node] = np.array([x, y])
    return pos

pos = random_circular_layout(G)

# Draw the graph with images as nodes
plt.figure(figsize=(8, 8))
ax = plt.gca()
ax.set_axis_off()

# Draw edges
nx.draw_networkx_edges(G, pos, alpha=0.4, edge_color='grey')

# Draw nodes with images
for n in G.nodes:
    (x, y) = pos[n]
    img_extent = (x-0.03, x+0.03, y-0.03, y+0.03)
    ax.imshow(img, extent=img_extent, aspect='auto')

# Draw fully transparent nodes on top of the images
nx.draw_networkx_nodes(G, pos, node_size=20, node_color='blue', alpha=0)

# Save the image
plt.savefig('sappho-network.png', format='png', bbox_inches='tight')
plt.show()
