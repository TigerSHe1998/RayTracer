// This file contains the fundamental classes for the ray tracer

class Light {
  public float r, g, b;
  public Point pos;

  public Light(float x, float y, float z, float r, float g, float b) {
    this.pos = new Point(x, y, z);
    this.r = r;
    this.g = g;
    this.b = b;
  }
  
  public Light(Point pos, float r, float g, float b) {
    this.pos = pos;
    this.r = r;
    this.g = g;
    this.b = b;
  }
  
  public String toString() {
    return "Light Object with color " + r + " " + g + " " + b + " and position at: " + pos;
  }
}

// -----------------------------

class DiskLight {
  public Point pos;
  public float radius;
  public PVector direction;
  public float r, g, b;
  public PVector vecX, vecY;
  
  public DiskLight(Point pos, float radius, PVector d, float r, float g, float b) {
    this.pos = pos;
    this.radius = radius;
    this.direction = d;
    this.r = r;
    this.g = g;
    this.b = b;
    this.vecX = new PVector(-1 * direction.y, direction.x, 0); // generate basis vectors on the disk plane
    vecX.normalize();
    this.vecY = vecX.cross(direction);
    vecY.normalize();
  }
  
  public String toString() {
    return "Disk Light Object with color " + r + " " + g + " " + b + " and position at: " + pos;
  }
  
  public Light getRandom() { // returns random point on disk light as a point light
    Point rand;
    do { // rejection sampling
      float x = random(-1 * radius, radius);
      float y = random(-1 * radius, radius);
      rand = new Point(pos.x + vecX.x * x + vecY.x * y, pos.y + vecX.y * x + vecY.y * y, pos.z + vecX.z * x + vecY.z * y);
    } while (rand.vectorTo(pos).mag() > radius);
    Light l = new Light(rand, r, g, b);
    return l;
  }
}

// -----------------------------

class Surface {
  public float dr, dg, db; // diffuse surface color
  public float sr, sg, sb; // specular highlight color
  public float spec_pow, k_refl, gloss_radius; // glossy rendering parameters

  public Surface() {
    this.dr = 0.0;
    this.dg = 0.0;
    this.db = 0.0;
    this.sr = 0.0;
    this.sg = 0.0;
    this.sb = 0.0;
    this.spec_pow = 0.0;
    this.k_refl = 0.0;
    this.gloss_radius = 0.0;
  }

  public Surface(float r, float g, float b) { // simple diffuse surface
    this.dr = r;
    this.dg = g;
    this.db = b;
    this.sr = 0.0;
    this.sg = 0.0;
    this.sb = 0.0;
    this.spec_pow = 0.0;
    this.k_refl = 0.0;
    this.gloss_radius = 0.0;
  }
  
  public Surface(float r, float g, float b, float sr, float sg, float sb, float spec, float k, float rad) { // glossy surface
    this.dr = r;
    this.dg = g;
    this.db = b;
    this.sr = sr;
    this.sg = sg;
    this.sb = sb;
    this.spec_pow = spec;
    this.k_refl = k;
    this.gloss_radius = rad;
  }

  public String toString() {
    return "Surface Object with diffuse color " + dr + " " + dg + " " + db + ", specular color " + sr + " " + sg + " " + sb + ", and parameters " + spec_pow + " " + k_refl + " " + gloss_radius;
  }
}


// -----------------------------

class Point {
  public float x, y, z;

  public Point() {
    this.x = 0.0;
    this.y = 0.0;
    this.z = 0.0;
  }

  public Point(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public PVector vectorTo(Point other) {
    return new PVector(other.x - this.x, other.y - this.y, other.z - this.z);
  }

  public String toString() {
    return "Point Object with coordinate " + x + " " + y + " " + z;
  }
}

// -----------------------------

class Ray {
  public Point origin;
  public PVector direction;

  public Ray() {
    this.origin = new Point();
    this.direction = new PVector(0, 0, 0);
  }

  public Ray(Point origin, Point other) {
    this.origin = origin;
    PVector d = new PVector(other.x - origin.x, other.y - origin.y, other.z - origin.z);
    //this.direction = d.normalize();
    this.direction = d;
  }

  public Ray(Point origin, PVector direction) {
    this.origin = origin;
    this.direction = direction;
  }
  
  // returns a point on ray at time t
  public Point pointOnRay(float t) {
    return new Point(origin.x + t * direction.x, origin.y + t * direction.y, origin.z + t * direction.z);
  }

  public String toString() {
    return "A Ray starting at " + origin.x + " " + origin.y + " " + origin.z + ", in the direction of " + direction;
  }
}

// -----------------------------

class HitInfo {
  public Object hitObject; // object that was hit
  public Point hitPoint; // point location that was hit
  public Ray ray; // ray that caused the hit
  public float movingT;
  
  public HitInfo(Object o, Point p, Ray r) {
    this.hitObject = o;
    this.hitPoint = p;
    this.ray = r;
    this.movingT = 0;
  }
  
  public HitInfo(Object o, Point p, Ray r, float t) { // constructor for moving object hitinfo
    this.hitObject = o;
    this.hitPoint = p;
    this.ray = r;
    this.movingT = t;
  }
  
  public String toString() {
    return "A Hit Info Object with: \n--HitObject: " + hitObject + "\n--HitPoint: " + hitPoint + "\n--Ray: " + ray;
  }
}
