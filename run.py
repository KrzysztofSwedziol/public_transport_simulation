import matplotlib
matplotlib.use("TkAgg")

from Simulation import Simulation

if __name__ == "__main__":
    sim = Simulation(10, 10)
    sim.setup()
    sim.run()