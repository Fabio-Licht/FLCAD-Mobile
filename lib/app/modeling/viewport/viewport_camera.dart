class ViewportCamera {
  const ViewportCamera({
    this.orbitX = 0,
    this.orbitY = 0,
    this.zoom = 1,
    this.panX = 0,
    this.panY = 0,
  });
  final double orbitX, orbitY, zoom, panX, panY;
  ViewportCamera orbit(double dx, double dy) => ViewportCamera(
    orbitX: orbitX + dx,
    orbitY: orbitY + dy,
    zoom: zoom,
    panX: panX,
    panY: panY,
  );
  ViewportCamera pan(double dx, double dy) => ViewportCamera(
    orbitX: orbitX,
    orbitY: orbitY,
    zoom: zoom,
    panX: panX + dx,
    panY: panY + dy,
  );
  ViewportCamera scale(double factor) => ViewportCamera(
    orbitX: orbitX,
    orbitY: orbitY,
    zoom: (zoom * factor).clamp(.05, 100),
    panX: panX,
    panY: panY,
  );
}
