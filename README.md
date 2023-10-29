# Experiments with rasterizing triangles

The basic idea behind triangle rasterization is to define it as points
that lie within the hull defined by the lines defined by the three
edge points.  This lend itself to an efficient incremental algorithm
that only needs to add three values for each point and as long as all
remain positive, we are inside the triangle.



To turn this into a race-the-beam algorithm we would have to set a
maximum of N overlapping tiles per scan line and update all for every
pixel.


