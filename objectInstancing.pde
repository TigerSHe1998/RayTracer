// This file contains implementations on object instancing

class InstanceObject extends Object {
  public TMatrix c, cinv;
  public Object o;
  
  public InstanceObject(Object o, TMatrix c) {
    this.o = o;
    this.c = c;
    this.cinv = c.inverse();
  }
  
  public String toString() {
    return "An instanced object: " + o;
  }
  
  /*
  * shades point on polygon, returns a 3 float tuple of color(0-1) in r g b order
  * p is point on polygon, l is light source we are shading to, r is eye ray
  */
  public float[] diffuseShade(HitInfo hInf, Light l) {
    Point p = hInf.hitPoint;
    Ray ray = hInf.ray;
    Point transformedP = transformPoint(p, cinv);
    Light transformedL = transformLight(l, cinv);
    Ray transformedRay = transformRay(ray, cinv);
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
    Point transformedP = transformPoint(p, cinv);
    Ray transformedRay = transformRay(ray, cinv);
    HitInfo transformedHInf = new HitInfo(hInf.hitObject, transformedP, transformedRay);
    return o.reflectionShade(transformedHInf);
  }
  
  /*
  * transforming ray then tracing against the original object
  * returns null if not hit, returns hit point in world coordinate if hit
  */
  public HitInfo rayTrace(Ray ray) { 
    Ray transformedRay = transformRay(ray, cinv);
    HitInfo transformedHInf = o.rayTrace(transformedRay);
    if (transformedHInf == null) return null;
    return new HitInfo(transformedHInf.hitObject, transformPoint(transformedHInf.hitPoint, c), ray);
  }
  
  public Point transformPoint(Point old, TMatrix c) { // create a new transformed point with TMatrix c
    TMatrix curr = c;
    float x = curr.raw[0][0] * old.x + curr.raw[0][1] * old.y + curr.raw[0][2] * old.z + curr.raw[0][3];
    float y = curr.raw[1][0] * old.x + curr.raw[1][1] * old.y + curr.raw[1][2] * old.z + curr.raw[1][3];
    float z = curr.raw[2][0] * old.x + curr.raw[2][1] * old.y + curr.raw[2][2] * old.z + curr.raw[2][3];
    return new Point(x, y, z);
  }
  
  public PVector transformDirection(PVector old, TMatrix c) { // create a new transformed direction with TMatrix c
    TMatrix curr = c;
    float x = curr.raw[0][0] * old.x + curr.raw[0][1] * old.y + curr.raw[0][2] * old.z;
    float y = curr.raw[1][0] * old.x + curr.raw[1][1] * old.y + curr.raw[1][2] * old.z;
    float z = curr.raw[2][0] * old.x + curr.raw[2][1] * old.y + curr.raw[2][2] * old.z;
    return new PVector(x, y, z);
  }
  
  public Ray transformRay(Ray old, TMatrix c) { // create a new transformed ray with TMatrix c
    Point newOrigin = transformPoint(old.origin, c);
    PVector newDirection = transformDirection(old.direction, c);
    return new Ray(newOrigin, newDirection);
  }
  
  public Light transformLight(Light old, TMatrix c) { // create a new transformed light with TMatrix c
    Point newPos = transformPoint(old.pos, c);
    return new Light(newPos, old.r, old.g, old.b);
  }
  
  public Box boundingBox() {
    println("[INSTANCE] [WARNING] Bounding box for instanced object currently unsupported, returning default box.");
    return new Box();
  }
  
  public Point centroid() {
    println("[INSTANCE] [WARNING] Centroid for instanced object currently unsupported, returning default point.");
    return new Point();
  }
}
