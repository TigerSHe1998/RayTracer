// This file contains implementation on a moving object that creates motion blur

class MovingObject extends Object {
  public float dx, dy, dz;
  public Object o;
  
  public MovingObject(Object o, float dx, float dy, float dz) {
    this.dx = dx;
    this.dy = dy;
    this.dz = dz;
    this.o = o;
  }
  
  public String toString() {
    return "A moving object: " + o;
  }
  
  /*
  * shades point on polygon, returns a 3 float tuple of color(0-1) in r g b order
  * p is point on polygon, l is light source we are shading to, r is eye ray
  */
  public float[] diffuseShade(HitInfo hInf, Light l) {
    Point p = hInf.hitPoint;
    Ray ray = hInf.ray;
    float t = hInf.movingT;
    Point transformedP = transformPoint(p, t);
    Light transformedL = transformLight(l, t);
    Ray transformedRay = transformRay(ray, t);
    HitInfo transformedHInf = new HitInfo(hInf.hitObject, transformedP, transformedRay);
    return o.diffuseShade(transformedHInf, transformedL);
  }
  
  /*
  * recursively calculates reflected color for point on polygon, returns a 3 float tuple of color(0-1) in r g b order
  * hInf contains point on polygon + incoming ray
  */
  public float[] reflectionShade(HitInfo hInf) {
    Point p = hInf.hitPoint;
    Ray ray = hInf.ray;
    float t = hInf.movingT;
    Point transformedP = transformPoint(p, t);
    Ray transformedRay = transformRay(ray, t);
    HitInfo transformedHInf = new HitInfo(hInf.hitObject, transformedP, transformedRay);
    return o.reflectionShade(transformedHInf);
  }
  
  /*
  * transforming ray origin randomly then tracing against the original object
  * returns null if not hit, returns hit point in world coordinate if hit
  */
  public HitInfo rayTrace(Ray ray) { 
    float t = random(1);
    Ray transformedRay = transformRay(ray, t);
    HitInfo transformedHInf = o.rayTrace(transformedRay);
    if (transformedHInf == null) return null;
    return new HitInfo(transformedHInf.hitObject, transformPoint(transformedHInf.hitPoint, -t), ray, t);
  }
  
  public Ray transformRay(Ray old, float t) { // create a new transformed ray at random time t
    Point newOrigin = transformPoint(old.origin, t);
    return new Ray(newOrigin, old.direction);
  }
  
  public Point transformPoint(Point old, float t) { // create a new transformed point at random time t
    return new Point(old.x - t * dx, old.y - t * dy, old.z - t * dz);
  }
  
  public Light transformLight(Light old, float t) { // create a new transformed light at random time t
    Point newPos = transformPoint(old.pos, t);
    return new Light(newPos, old.r, old.g, old.b);
  }
  
  public Box boundingBox() {
    println("[MOVING] [WARNING] Bounding box for moving object currently unsupported, returning default box.");
    return new Box();
  }
  
  public Point centroid() {
    println("[MOVING] [WARNING] Centroid for moving object currently unsupported, returning default point.");
    return new Point();
  }
  
}
