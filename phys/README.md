File **phys.nut** contains physics data (mass and mass centers) of different physics models.
- It includes all models that have collision data file (.phy) and that are able to be a prop_physics.
- Mass centers were retrieved using in-game physics engine testing, so they are not very accurate.
- Models are sorted by mass and then by model path.
- Some models have obviously wrong mass (especially those with a large mass)

File **phys_gen.nut** contains script that was used for defining mass centers. The idea of the algorithm is that mass center is the point which shifts for the shortest distance during free rotation of the physics prop. The script iterates over all models from input file(s), tries to create physics prop for each model and makes several iterations. During each iteration script applies random angular velocity for a physics prop and clarifies it's mass center (accuracy is probably +- 2 units).

File **get_mass.java** was used to extract mass of objects from .phy files.

File **models.txt** contains all in-game models that have corresponding .phy files.
