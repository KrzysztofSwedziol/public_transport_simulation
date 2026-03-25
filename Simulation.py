from City import City

class Simulation:
    def __init__(self, city_width, city_height):
        self.city = City(city_width, city_height)

    def setup(self):
        self.city.generate_city()

    def run(self):
        self.city.draw_city()