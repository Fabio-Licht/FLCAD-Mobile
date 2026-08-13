# Boolean Engine

Union, Subtract and Intersect require at least two Solid handles. Inputs are validated in the domain and translated only inside the active kernel adapter. Results pass the full solid validation set before transaction commit.

Failures return diagnostics and do not create a valid feature node or persistent output.

