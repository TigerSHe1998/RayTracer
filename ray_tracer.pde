// Main file of the Ray Tracer Renderer project
// Global imports
import java.util.*;

// Global Switches / Configs
boolean debug_flag = false;
boolean render_shadow = true;
boolean render_reflection = true;
int render_reflection_maxdepth = 20;
boolean render_dof = true;

// Scene Variables
float fov = 60.0;
float[] bgColor = new float[] {0, 0, 0};
ArrayList<Light> lights = new ArrayList();
ArrayList<DiskLight> diskLights = new ArrayList();
ArrayList<Object> sceneObjects = new ArrayList();
ArrayList<Object> BVHTempObjects = new ArrayList();
ArrayList<Object> objects = sceneObjects;
Map<String, Object> namedObjects = new HashMap();
Surface currSurface = new Surface();
int triangleBuildInd = 0;
Triangle tempTriangle = new Triangle();
MatrixStack sceneGraph = new MatrixStack();
int raysPerPixel = 1;
float dofRadius = 0;
float dofDist = 1;
int reflectionDepth = 0;

void setup() {
  size(512, 512); // set resolution here
  noStroke();
  background(0, 0, 0);
  
  // Start-up config outputs
  if (debug_flag) println("[CONFIG] debug_flag = true");
  if (render_shadow) println("[CONFIG] render_shadow = true");
  if (render_reflection) println("[CONFIG] render_reflection = true"); 
  if (render_reflection) println("[CONFIG] render_reflection_maxdepth = " + render_reflection_maxdepth); 
  if (render_dof) println("[CONFIG] render_dof = true");
  println("[CONFIG] Starting renderer with window size " + width + " x " + height);
}

void reset_scene() {
  fov = 60.0;
  bgColor = new float[] {0, 0, 0};
  lights.clear();
  diskLights.clear();
  sceneObjects.clear();
  BVHTempObjects.clear();
  objects = sceneObjects;
  namedObjects.clear();
  currSurface = new Surface();
  triangleBuildInd = 0;
  tempTriangle = new Triangle();
  sceneGraph = new MatrixStack();
  raysPerPixel = 1;
  dofRadius = 0;
  dofDist = 1;
  reflectionDepth = 0;
}

// the main driver function of the renderer
void draw_scene() {
  int tStart = millis();
  float fovK = tan(radians(fov) / 2.0);

  for(int y = 0; y < height; y++) {
    for(int x = 0; x < width; x++) {
      // create and cast an center eye ray with image plane at z = -1
      float x3D = (x - width / 2.0) * (2 * fovK / width);
      float y3D = ((height - y) - height / 2.0) * (2 * fovK / height); // flipped y here because of processing handling pixels differently
      Ray centerRay = new Ray(new Point(0, 0, 0), new Point(x3D, y3D, -1));
      
      // draw Depth of Field effect according to lens size + focal distance 
      if (dofRadius != 0 && render_dof) {
        Point focalPlaneHit = centerRay.pointOnRay(-1 * dofDist / centerRay.direction.z);
        Point rand;
        do { // rejection sampling
          float lensx = random(-1 * dofRadius, dofRadius);
          float lensy = random(-1 * dofRadius, dofRadius);
          rand = new Point(lensx, lensy, 0);
        } while (rand.vectorTo(new Point(0, 0, 0)).mag() > dofRadius);
        centerRay = new Ray(rand, focalPlaneHit);
      } 

      // determines if multiple rays per pixel is needed and renders differently
      color c = floatTupleToColor(bgColor);
      if (raysPerPixel == 1) c = floatTupleToColor(rayColor(centerRay));
      else {
        // prepare for color combination, start with center ray color
        float[] tempColor = rayColor(centerRay); 
        // determines pixel boundary
        float leftx3D = ((x - 1) - width / 2.0) * (2 * fovK / width);
        float rightx3D = ((x + 1) - width / 2.0) * (2 * fovK / width);
        float downy3D = ((height - (y + 1)) - height / 2.0) * (2 * fovK / height); 
        float upy3D = ((height - (y - 1)) - height / 2.0) * (2 * fovK / height); 
        leftx3D = (leftx3D + x3D) / 2;
        rightx3D = (rightx3D + x3D) / 2;
        downy3D = (downy3D + y3D) / 2;
        upy3D = (upy3D + y3D) / 2;
        // cast raysPerPixel - 1 number of extra rays and average them together
        for (int i = 1; i < raysPerPixel; i++) {
          Ray randomRay = new Ray(new Point(0, 0, 0), new Point(random(leftx3D, rightx3D), random(downy3D, upy3D), -1));
          // draw Depth of Field effect according to lens size + focal distance 
          if (dofRadius != 0 && render_dof) {
            Point focalPlaneHit = randomRay.pointOnRay(-1 * dofDist / randomRay.direction.z);
            Point rand;
            do { // rejection sampling
              float lensx = random(-1 * dofRadius, dofRadius);
              float lensy = random(-1 * dofRadius, dofRadius);
              rand = new Point(lensx, lensy, 0);
            } while (rand.vectorTo(new Point(0, 0, 0)).mag() > dofRadius);
            randomRay = new Ray(rand, focalPlaneHit);
          } 
          float[] randomRayColor = rayColor(randomRay);
          tempColor[0] += randomRayColor[0];
          tempColor[1] += randomRayColor[1];
          tempColor[2] += randomRayColor[2];
        }
        tempColor[0] = tempColor[0] / raysPerPixel;
        tempColor[1] = tempColor[1] / raysPerPixel;
        tempColor[2] = tempColor[2] / raysPerPixel;
        c = floatTupleToColor(tempColor);
      }
      
      // draw pixel
      set (x, y, c);  
    }
  }
  
  // output render time
  int tEnd = millis();
  int tElapsed = tEnd - tStart;
  println("[RENDER] Render completed in " + tElapsed / 1000.0 + " seconds.");
}

// renders a single eye ray against the entire scene
public float[] rayColor(Ray r) {
  // determine the object that eye ray intersects
  float nearestZ = Integer.MIN_VALUE;
  Object nearestObj = null;
  HitInfo nearestHInf = null;
  for (Object o : objects) {
    HitInfo hInf = o.rayTrace(r);
    if (hInf != null && hInf.hitPoint.z > -1) continue; // edge case where mesh was hit before the image plane
    if (hInf != null && hInf.hitPoint.z > nearestZ) {
      nearestZ = hInf.hitPoint.z;
      nearestObj = o;
      nearestHInf = hInf;
    }
  }
  
  // shade object against every light in scene
  if (nearestObj == null) return new float[] {bgColor[0], bgColor[1], bgColor[2]}; // defaults to bgColor if ray misses
  float[] tempColor = {0.0, 0.0, 0.0}; // prepare for color combination
  HitInfo hInf = nearestHInf;
  Point hit = hInf.hitPoint;
  // add disk light sample into lights rendering queue
  for (DiskLight dl : diskLights) { 
    Light l = dl.getRandom();
    lights.add(l);
  }
  // render against all lights
  for (Light l : lights) {
    // render without shadow
    if (!render_shadow) { 
      float[] currColor = nearestObj.diffuseShade(hInf, l);
      tempColor[0] += currColor[0];
      tempColor[1] += currColor[1];
      tempColor[2] += currColor[2];
    }
    // render with shadow
    else if (render_shadow) { 
      boolean pointInShadow = false;
      Ray shadowRay = new Ray(hit, hit.vectorTo(l.pos).normalize());
      float distToLight = hit.vectorTo(l.pos).mag();
      for (Object o : objects) {
        if (o == nearestObj) continue; // stop shadow ray from hitting the same triangle
        HitInfo shadowHInf = o.rayTrace(shadowRay);
        if (shadowHInf != null && hit.vectorTo(shadowHInf.hitPoint).mag() < distToLight) {
          pointInShadow = true;
          break;
        }
      }
      if (!pointInShadow) {
        float[] currColor = nearestObj.diffuseShade(hInf, l);
        tempColor[0] += currColor[0];
        tempColor[1] += currColor[1];
        tempColor[2] += currColor[2];  
      } 
    }
  }
  // remove the temp disk light samples
  for (int i = 0; i < diskLights.size(); i++) lights.remove(lights.size() - 1);
  
  // add recursive reflection colors depending on object surface properties
  float[] reflectedColor = nearestObj.reflectionShade(hInf);
  tempColor[0] += reflectedColor[0];
  tempColor[1] += reflectedColor[1];
  tempColor[2] += reflectedColor[2];  
  
  return tempColor;
}


// renders a single reflected ray against the entire scene
public float[] reflRayColor(Ray r, Object self) {
  // determine the object that refl ray intersects
  float nearestDist = Integer.MAX_VALUE;
  Object nearestObj = null;
  HitInfo nearestHInf = null;
  for (Object o : objects) {
    if (o == self) continue;
    HitInfo hInf = o.rayTrace(r);
    if (hInf != null && hInf.hitPoint.vectorTo(r.origin).mag() < nearestDist) {
      nearestDist = hInf.hitPoint.vectorTo(r.origin).mag();
      nearestObj = o;
      nearestHInf = hInf;
    }
  }
  
  // shade object against every light in scene
  if (nearestObj == null) return new float[] {bgColor[0], bgColor[1], bgColor[2]}; // defaults to bgColor if ray misses
  float[] tempColor = {0.0, 0.0, 0.0}; // prepare for color combination
  HitInfo hInf = nearestHInf;
  Point hit = hInf.hitPoint;
  // add disk light sample into lights rendering queue
  for (DiskLight dl : diskLights) { 
    Light l = dl.getRandom();
    lights.add(l);
  }
  // render against all lights
  for (Light l : lights) {
    // render without shadow
    if (!render_shadow) { 
      float[] currColor = nearestObj.diffuseShade(hInf, l);
      tempColor[0] += currColor[0];
      tempColor[1] += currColor[1];
      tempColor[2] += currColor[2];
    }
    // render with shadow
    else if (render_shadow) { 
      boolean pointInShadow = false;
      Ray shadowRay = new Ray(hit, hit.vectorTo(l.pos).normalize());
      float distToLight = hit.vectorTo(l.pos).mag();
      for (Object o : objects) {
        if (o == nearestObj) continue; // stop shadow ray from hitting the same triangle
        HitInfo shadowHInf = o.rayTrace(shadowRay);
        if (shadowHInf != null && hit.vectorTo(shadowHInf.hitPoint).mag() < distToLight) {
          pointInShadow = true;
          break;
        }
      }
      if (!pointInShadow) {
        float[] currColor = nearestObj.diffuseShade(hInf, l);
        tempColor[0] += currColor[0];
        tempColor[1] += currColor[1];
        tempColor[2] += currColor[2];  
      } 
    }
  }
  // remove the temp disk light samples
  for (int i = 0; i < diskLights.size(); i++) lights.remove(lights.size() - 1);
  // add recursive reflection colors depending on object surface properties
  float[] reflectedColor = nearestObj.reflectionShade(hInf);
  tempColor[0] += reflectedColor[0];
  tempColor[1] += reflectedColor[1];
  tempColor[2] += reflectedColor[2];  
  
  return tempColor;
}

// nothing here, but must have the empty draw function for processing to work
void draw() {} 
