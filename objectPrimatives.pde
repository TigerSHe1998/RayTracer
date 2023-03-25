// This file contains implementation for all renderable primative objects

// all renderable objects extends this abstract class, the functions below are available for all objects.
abstract class Object { 
  /*
  * shades point on polygon, returns a 3 float tuple of color(0-1) in r g b order
  * hInf contains point on polygon + eye ray information, l is light source we are shading to
  */
  public abstract float[] diffuseShade(HitInfo info, Light l);
  
  /*
  * recursively calculates reflected color for point on polygon, returns a 3 float tuple of color(0-1) in r g b order
  * hInf contains point on polygon + incoming ray
  */
  public abstract float[] reflectionShade(HitInfo info);
  
  /*
  * trace input ray against the current object, if hit will return the hit info, if not hit returns null.
  */
  public abstract HitInfo rayTrace(Ray ray);
  
  // helper functions essential for BVH acceleration
  public abstract Box boundingBox();
  public abstract Point centroid();
}

// -----------------------------

class Triangle extends Object {
  public Point p1, p2, p3;
  public Surface s;

  public Triangle() {
    this.p1 = new Point();
    this.p2 = new Point();
    this.p3 = new Point();
    this.s = new Surface();
  }

  public Triangle(Surface s) {
    this.p1 = new Point();
    this.p2 = new Point();
    this.p3 = new Point();
    this.s = s;
  }

  public Triangle(Point p1, Point p2, Point p3, Surface s) {
    this.p1 = p1;
    this.p2 = p2;
    this.p3 = p3;
    this.s = s;
  }
  
  public String toString() {
    return "Triangle with vertex: " + "\n--" + p1 + "\n--" + p2 + "\n--" + p3;
  }
  
  public PVector getSurfaceNorm(HitInfo hInf) {
    Ray ray = hInf.ray;
    // calculate surface norm for both directions
    PVector AB = p1.vectorTo(p2);
    PVector AC = p1.vectorTo(p3);
    PVector SurfaceNormA = AB.cross(AC).normalize(); 
    PVector SurfaceNormB = AC.cross(AB).normalize();
    // determine which surface norm to use depending on eye ray
    PVector SurfaceNorm;
    if (ray.direction.dot(SurfaceNormA) < 0) SurfaceNorm = SurfaceNormA;
    else SurfaceNorm = SurfaceNormB;
    return SurfaceNorm;
  }

  public float[] diffuseShade(HitInfo hInf, Light l) { 
    Point p = hInf.hitPoint; 
    Ray ray = hInf.ray;
    PVector SurfaceNorm = getSurfaceNorm(hInf);
    // shade color using diffuse shading equation
    PVector toLightVector = new PVector(l.pos.x - p.x, l.pos.y - p.y, l.pos.z - p.z);
    toLightVector.normalize();
    float r = s.dr * l.r * max(0, SurfaceNorm.dot(toLightVector));
    float g = s.dg * l.g * max(0, SurfaceNorm.dot(toLightVector));
    float b = s.db * l.b * max(0, SurfaceNorm.dot(toLightVector));
    // add specular term
    PVector toEyeVector = new PVector(ray.direction.x * -1, ray.direction.y * -1, ray.direction.z * -1);
    PVector h = PVector.add(toLightVector, toEyeVector);
    h.normalize();
    toEyeVector.normalize();
    if (s.spec_pow != 0) r += l.r * s.sr * pow(h.dot(SurfaceNorm), s.spec_pow);
    if (s.spec_pow != 0) g += l.g * s.sg * pow(h.dot(SurfaceNorm), s.spec_pow);
    if (s.spec_pow != 0) b += l.b * s.sb * pow(h.dot(SurfaceNorm), s.spec_pow);
    return new float[] {r, g, b};
  }
  
  public float[] reflectionShade(HitInfo hInf) {
    // add recursive reflection if condition permits
    if (render_reflection && s.k_refl > 0 && reflectionDepth < render_reflection_maxdepth) {
      Point p = hInf.hitPoint; 
      Ray ray = hInf.ray;
      PVector SurfaceNorm = getSurfaceNorm(hInf);
      // calculate reflection ray
      PVector toEyeVector = new PVector(ray.direction.x * -1, ray.direction.y * -1, ray.direction.z * -1);
      toEyeVector.normalize();
      float temp = 2 * toEyeVector.dot(SurfaceNorm);
      PVector reflDirection = new PVector(SurfaceNorm.x * temp - toEyeVector.x, SurfaceNorm.y * temp - toEyeVector.y, SurfaceNorm.z * temp - toEyeVector.z);
      Ray reflRay = new Ray(p, reflDirection);
      if (s.gloss_radius != 0) reflRay.direction = reflRay.direction.add(random(-s.gloss_radius, s.gloss_radius), random(-s.gloss_radius, s.gloss_radius), random(-s.gloss_radius, s.gloss_radius));
      // recursively color reflection ray
      reflectionDepth++;
      float[] cRefl = reflRayColor(reflRay, this);
      reflectionDepth--;
      return new float[] {s.k_refl * cRefl[0], s.k_refl * cRefl[1], s.k_refl * cRefl[2]};
    } else return new float[] {0, 0, 0};
  }
  
  public HitInfo rayTrace(Ray ray) {
    // calculate plane parameters of the triangle
    PVector AB = p1.vectorTo(p2);
    PVector AC = p1.vectorTo(p3);
    PVector tSurfaceNorm = AB.cross(AC).normalize(); // surface normal a b c at .x .y .z of the PVector obj
    float tD = -1 * (p1.x * tSurfaceNorm.x + p1.y * tSurfaceNorm.y + p1.z * tSurfaceNorm.z);
    // solve for t (time)
    float denom = tSurfaceNorm.x * ray.direction.x + tSurfaceNorm.y * ray.direction.y + tSurfaceNorm.z * ray.direction.z;
    if (denom == 0) return null; // case of ray parallel to mesh
    float nom = -1 * (ray.origin.x * tSurfaceNorm.x + ray.origin.y * tSurfaceNorm.y + ray.origin.z * tSurfaceNorm.z + tD);
    float time = nom / denom;
    if (time <= 0) return null; // edge case where intersection happenes behind the ray origin
    // get hit point on plane
    Point planeHit = ray.pointOnRay(time);
    // do PiT 3D with planeHit and Triangle t
    PVector AP = p1.vectorTo(planeHit);
    PVector BP = p2.vectorTo(planeHit);
    PVector CP = p3.vectorTo(planeHit);
    PVector BC = p2.vectorTo(p3);
    PVector CA = p3.vectorTo(p1);
    float testAB = tSurfaceNorm.dot(AP.cross(AB));
    float testBC = tSurfaceNorm.dot(BP.cross(BC));
    float testCA = tSurfaceNorm.dot(CP.cross(CA));
    if (testAB >= 0 && testBC >= 0 && testCA >= 0) return new HitInfo(this, planeHit, ray); // ray hit
    if (testAB <= 0 && testBC <= 0 && testCA <= 0) return new HitInfo(this, planeHit, ray);
    return null; // ray missed
  }
  
  public Box boundingBox() {
    float minX = min(min(p1.x, p2.x), p3.x);
    float minY = min(min(p1.y, p2.y), p3.y);
    float minZ = min(min(p1.z, p2.z), p3.z);
    float maxX = max(max(p1.x, p2.x), p3.x);
    float maxY = max(max(p1.y, p2.y), p3.y);
    float maxZ = max(max(p1.z, p2.z), p3.z);
    Point min = new Point(minX, minY, minZ);
    Point max = new Point(maxX, maxY, maxZ);
    return new Box(min, max);
  }
  
  public Point centroid() {
    Box bbox = this.boundingBox();
    return new Point((bbox.min.x + bbox.max.x) / 2, (bbox.min.y + bbox.max.y) / 2, (bbox.min.z + bbox.max.z) / 2);
  }
}

// -----------------------------

class Box extends Object { // Axis Aligned Boxes
  public Point min, max;
  public Surface s;

  public Box() {
    this.min = new Point();
    this.max = new Point();
    this.s = new Surface();
  }

  public Box(Surface s) {
    this.min = new Point();
    this.max = new Point();
    this.s = s;
  }
  
  public Box(Point min, Point max) {
    this.min = min;
    this.max = max;
    this.s = new Surface();
  }

  public Box(Point min, Point max, Surface s) {
    this.min = min;
    this.max = max;
    this.s = s;
  }
  
  public String toString() {
    return "Axis aligned box with vertex: " + "\n--" + min + "\n--" + max;
  }

  public PVector getSurfaceNorm(HitInfo hInf) {
    Point p = hInf.hitPoint;
    Ray ray = hInf.ray;
    // check the plane that p is on, and calculate surface norm for both directions
    PVector SurfaceNorm, SurfaceNormA, SurfaceNormB;
    float delta = 0.0001;
    if (abs(p.x - min.x) < delta || abs(p.x - max.x) < delta) {
      SurfaceNormA = new PVector(-1, 0, 0); 
      SurfaceNormB = new PVector(1, 0, 0); 
    } else if (abs(p.y - min.y) < delta || abs(p.y - max.y) < delta) {
      SurfaceNormA = new PVector(0, -1, 0); 
      SurfaceNormB = new PVector(0, 1, 0); 
    } else {
      SurfaceNormA = new PVector(0, 0, -1); 
      SurfaceNormB = new PVector(0, 0, 1); 
    }
    // determine which surface norm to use depending on eye ray
    if (ray.direction.dot(SurfaceNormA) < 0) SurfaceNorm = SurfaceNormA;
    else SurfaceNorm = SurfaceNormB;
    return SurfaceNorm;
  }

  public float[] diffuseShade(HitInfo hInf, Light l) { 
    Point p = hInf.hitPoint;
    Ray ray = hInf.ray;
    PVector SurfaceNorm = getSurfaceNorm(hInf);
    // shade color using diffuse shading equation
    PVector toLightVector = new PVector(l.pos.x - p.x, l.pos.y - p.y, l.pos.z - p.z);
    toLightVector.normalize();
    float r = s.dr * l.r * max(0, SurfaceNorm.dot(toLightVector));
    float g = s.dg * l.g * max(0, SurfaceNorm.dot(toLightVector));
    float b = s.db * l.b * max(0, SurfaceNorm.dot(toLightVector));
    // add specular term
    PVector toEyeVector = new PVector(ray.direction.x * -1, ray.direction.y * -1, ray.direction.z * -1);
    PVector h = PVector.add(toLightVector, toEyeVector);
    h.normalize();
    toEyeVector.normalize();
    if (s.spec_pow != 0) r += l.r * s.sr * pow(h.dot(SurfaceNorm), s.spec_pow);
    if (s.spec_pow != 0) g += l.g * s.sg * pow(h.dot(SurfaceNorm), s.spec_pow);
    if (s.spec_pow != 0) b += l.b * s.sb * pow(h.dot(SurfaceNorm), s.spec_pow);
    return new float[] {r, g, b};
  }

  public float[] reflectionShade(HitInfo hInf) {
    // add recursive reflection if condition permits
    if (render_reflection && s.k_refl > 0 && reflectionDepth < render_reflection_maxdepth) {
      Point p = hInf.hitPoint;
      Ray ray = hInf.ray;
      PVector SurfaceNorm = getSurfaceNorm(hInf);
      // calculate reflection ray
      PVector toEyeVector = new PVector(ray.direction.x * -1, ray.direction.y * -1, ray.direction.z * -1);
      toEyeVector.normalize();
      float temp = 2 * toEyeVector.dot(SurfaceNorm);
      PVector reflDirection = new PVector(SurfaceNorm.x * temp - toEyeVector.x, SurfaceNorm.y * temp - toEyeVector.y, SurfaceNorm.z * temp - toEyeVector.z);
      Ray reflRay = new Ray(p, reflDirection);
      if (s.gloss_radius != 0) reflRay.direction = reflRay.direction.add(random(-s.gloss_radius, s.gloss_radius), random(-s.gloss_radius, s.gloss_radius), random(-s.gloss_radius, s.gloss_radius));
      // recursively color reflection ray
      reflectionDepth++;
      float[] cRefl = reflRayColor(reflRay, this);
      reflectionDepth--;
      return new float[] {s.k_refl * cRefl[0], s.k_refl * cRefl[1], s.k_refl * cRefl[2]};
    } else return new float[] {0, 0, 0};
  }
  
  public HitInfo rayTrace(Ray ray) {
    float tMinX = (min.x - ray.origin.x) / ray.direction.x;
    float tMinY = (min.y - ray.origin.y) / ray.direction.y;
    float tMinZ = (min.z - ray.origin.z) / ray.direction.z;
    float tMaxX = (max.x - ray.origin.x) / ray.direction.x;
    float tMaxY = (max.y - ray.origin.y) / ray.direction.y;
    float tMaxZ = (max.z - ray.origin.z) / ray.direction.z;
    Point t1 = new Point(min(tMinX, tMaxX), min(tMinY, tMaxY), min(tMinZ, tMaxZ));
    Point t2 = new Point(max(tMinX, tMaxX), max(tMinY, tMaxY), max(tMinZ, tMaxZ));
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    if (tNear > tFar) return null;
    else return new HitInfo(this, ray.pointOnRay(tNear), ray);
  }
  
  public Box boundingBox() {
    return new Box(min, max);
  }
  
  public Point centroid() {
    Box bbox = this;
    return new Point((bbox.min.x + bbox.max.x) / 2, (bbox.min.y + bbox.max.y) / 2, (bbox.min.z + bbox.max.z) / 2);
  }
  
  public Box expandBy(Point p) { // returns a new box expanded by a point, useful when box is used as bbox
    float minX = min(p.x, min.x);
    float minY = min(p.y, min.y);
    float minZ = min(p.z, min.z);
    float maxX = max(p.x, max.x);
    float maxY = max(p.y, max.y);
    float maxZ = max(p.z, max.z);
    Point newMin = new Point(minX, minY, minZ);
    Point newMax = new Point(maxX, maxY, maxZ);
    return new Box(newMin, newMax);
  }
  
  public Box expandBy(Box b) { // returns a new box expanded by another box, useful when box is used as bbox
    float minX = min(b.min.x, min.x);
    float minY = min(b.min.y, min.y);
    float minZ = min(b.min.z, min.z);
    float maxX = max(b.max.x, max.x);
    float maxY = max(b.max.y, max.y);
    float maxZ = max(b.max.z, max.z);
    Point newMin = new Point(minX, minY, minZ);
    Point newMax = new Point(maxX, maxY, maxZ);
    return new Box(newMin, newMax);
  }
  
  public boolean pointInBox(Point p) { // check if point p lies in the box
    return p.x >= min.x && p.x <= max.x && p.y >= min.y && p.y <= max.y && p.z >= min.z && p.z <= max.z;
  }
}

// -----------------------------

class Sphere extends Object {
  public Point center;
  public float radius;
  public Surface s;
  
  public Sphere(Point center, float radius, Surface s) {
    this.center = center;
    this.radius = radius;
    this.s = s;
  }
  
  public String toString() {
    return "Sphere with radius " + radius + " at center:\n--" + center;
  }
  
  public HitInfo rayTrace(Ray ray) {
    // calculate ray-sphere intersection delta
    PVector u = ray.direction;
    Point o_c = new Point(ray.origin.x - center.x, ray.origin.y - center.y, ray.origin.z - center.z);
    float delta = pow((2 * (u.x * o_c.x + u.y * o_c.y + u.z * o_c.z)), 2) - (4 * (u.x * u.x + u.y * u.y + u.z * u.z) * ((o_c.x * o_c.x + o_c.y * o_c.y + o_c.z * o_c.z) - radius * radius));
    // if delta < 0, no intersection
    if (delta < 0) return null;
    // if delta == 0, 1 intersection
    else if (delta == 0) {
      float t = (-2 * (u.x * o_c.x + u.y * o_c.y + u.z * o_c.z)) / (2 * (u.x * u.x + u.y * u.y + u.z * u.z));
      if (t < 0) return null; // hit behind ray origin
      return new HitInfo(this, ray.pointOnRay(t), ray);
    // if delta > 0, 2 intersections, compare and return closest intersect
    } else {
      float t1 = (-2 * (u.x * o_c.x + u.y * o_c.y + u.z * o_c.z) + sqrt(delta)) / (2 * (u.x * u.x + u.y * u.y + u.z * u.z));
      float t2 = (-2 * (u.x * o_c.x + u.y * o_c.y + u.z * o_c.z) - sqrt(delta)) / (2 * (u.x * u.x + u.y * u.y + u.z * u.z));
      Point hit1 = ray.pointOnRay(t1);
      Point hit2 = ray.pointOnRay(t2);
      Point hit = hit1.vectorTo(ray.origin).mag() > hit2.vectorTo(ray.origin).mag() ? hit2 : hit1;
      if (hit == hit1 && t1 < 0) return null; // hit behind ray origin
      if (hit == hit2 && t2 < 0) return null; // hit behind ray origin
      return new HitInfo(this, hit, ray);
    }
  }
  
  public PVector getSurfaceNorm(HitInfo hInf) {
    Point p = hInf.hitPoint; 
    Ray ray = hInf.ray;
    // calculate surface norm for both directions
    PVector SurfaceNormA = center.vectorTo(p).normalize(); 
    PVector SurfaceNormB = p.vectorTo(center).normalize();
    // determine which surface norm to use depending on eye ray
    PVector SurfaceNorm;
    if (ray.direction.dot(SurfaceNormA) < 0) SurfaceNorm = SurfaceNormA;
    else SurfaceNorm = SurfaceNormB;
    return SurfaceNorm;
  }
  
  public float[] diffuseShade(HitInfo hInf, Light l) { 
    Point p = hInf.hitPoint; 
    Ray ray = hInf.ray;
    PVector SurfaceNorm = getSurfaceNorm(hInf);
    // shade color using diffuse shading equation
    PVector toLightVector = new PVector(l.pos.x - p.x, l.pos.y - p.y, l.pos.z - p.z);
    toLightVector.normalize();
    float r = s.dr * l.r * max(0, SurfaceNorm.dot(toLightVector));
    float g = s.dg * l.g * max(0, SurfaceNorm.dot(toLightVector));
    float b = s.db * l.b * max(0, SurfaceNorm.dot(toLightVector));
    // add specular term
    PVector toEyeVector = new PVector(ray.direction.x * -1, ray.direction.y * -1, ray.direction.z * -1);
    PVector h = PVector.add(toLightVector, toEyeVector);
    h.normalize();
    toEyeVector.normalize();
    if (s.spec_pow != 0) r += l.r * s.sr * pow(h.dot(SurfaceNorm), s.spec_pow);
    if (s.spec_pow != 0) g += l.g * s.sg * pow(h.dot(SurfaceNorm), s.spec_pow);
    if (s.spec_pow != 0) b += l.b * s.sb * pow(h.dot(SurfaceNorm), s.spec_pow);
    return new float[] {r, g, b};
  }
  
  public float[] reflectionShade(HitInfo hInf) {
    // add recursive reflection if condition permits
    if (render_reflection && s.k_refl > 0 && reflectionDepth < render_reflection_maxdepth) {
      Point p = hInf.hitPoint;
      Ray ray = hInf.ray;
      PVector SurfaceNorm = getSurfaceNorm(hInf);
      // calculate reflection ray
      PVector toEyeVector = new PVector(ray.direction.x * -1, ray.direction.y * -1, ray.direction.z * -1);
      toEyeVector.normalize();
      float temp = 2 * toEyeVector.dot(SurfaceNorm);
      PVector reflDirection = new PVector(SurfaceNorm.x * temp - toEyeVector.x, SurfaceNorm.y * temp - toEyeVector.y, SurfaceNorm.z * temp - toEyeVector.z);
      Ray reflRay = new Ray(p, reflDirection);
      if (s.gloss_radius != 0) reflRay.direction = reflRay.direction.add(random(-s.gloss_radius, s.gloss_radius), random(-s.gloss_radius, s.gloss_radius), random(-s.gloss_radius, s.gloss_radius));
      // recursively color reflection ray
      reflectionDepth++;
      float[] cRefl = reflRayColor(reflRay, this);
      reflectionDepth--;
      return new float[] {s.k_refl * cRefl[0], s.k_refl * cRefl[1], s.k_refl * cRefl[2]};
    } else return new float[] {0, 0, 0};
  }
  
  public Box boundingBox() {
    Point min = new Point(center.x - radius, center.y - radius, center.z - radius);
    Point max = new Point(center.x + radius, center.y + radius, center.z + radius);
    return new Box(min, max);
  }
  
  public Point centroid() {
    return this.boundingBox().centroid();
  }
}
