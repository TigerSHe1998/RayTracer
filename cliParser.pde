// This file contains the parser logic for the .cli scene description files

void interpreter(String file) {
  println("[PARSE] Parsing '" + file + "'");
  String str[] = loadStrings(file);
  if (str == null) println ("[PARSE] [ERROR] Failed to read the file!");
  
  for (int i = 0; i < str.length; i++) {
    String[] token = splitTokens (str[i], " ");   // get a line and separate the tokens
    if (token.length == 0) continue;              // skip blank lines

    // -------- initial scene setup -------- //

    if (token[0].equals("fov")) {
      fov = float(token[1]); // this is how to get a float value from a line in the scene description file
      if (debug_flag) println ("[PARSE] fov = " + fov);
    }
    else if (token[0].equals("background")) {
      bgColor = new float[] {float(token[1]), float(token[2]), float(token[3])};
      if (debug_flag) println ("[PARSE] background color = " + bgColor[0] + " " + bgColor[1] + " " + bgColor[2]);
    }
    else if (token[0].equals("rays_per_pixel")) {
      raysPerPixel = int(token[1]);
      if (debug_flag) println ("[PARSE] rays per pixel = " + raysPerPixel);
    }
    else if (token[0].equals("lens")) {
      dofRadius = float(token[1]);
      dofDist = float(token[2]);
      if (debug_flag) println ("[PARSE] depth of field radius = " + dofRadius + ", focus distance = " + dofDist);
    }
    
    // -------- lighting -------- //
    
    else if (token[0].equals("light")) {
      Point p = new Point(float(token[1]), float(token[2]), float(token[3]));
      p = sceneGraph.applyTransform(p);
      Light l = new Light(p, float(token[4]), float(token[5]), float(token[6]));
      lights.add(l);
      if (debug_flag) println("[PARSE] added light source " + lights.size());
    }
    else if (token[0].equals("disk_light")) {
      Point p = new Point(float(token[1]), float(token[2]), float(token[3]));
      PVector dir = new PVector(float(token[5]), float(token[6]), float(token[7]));
      p = sceneGraph.applyTransform(p);
      dir = sceneGraph.applyTransform(dir);
      DiskLight l = new DiskLight(p, float(token[4]), dir, float(token[8]), float(token[9]), float(token[10]));
      diskLights.add(l);
      if (debug_flag) println("[PARSE] added disk light source " + lights.size());
    }
    
    // -------- surface -------- //
    
    else if (token[0].equals("surface")) {
      currSurface = new Surface();
      currSurface.dr = float(token[1]);
      currSurface.dg = float(token[2]);
      currSurface.db = float(token[3]);
      if (debug_flag) println("[PARSE] using diffuse surface with color: " + currSurface.dr + " " + currSurface.dg + " " + currSurface.db);
    }
    else if (token[0].equals("glossy")) {
      currSurface = new Surface();
      currSurface.dr = float(token[1]);
      currSurface.dg = float(token[2]);
      currSurface.db = float(token[3]);
      currSurface.sr = float(token[4]);
      currSurface.sg = float(token[5]);
      currSurface.sb = float(token[6]);
      currSurface.spec_pow = float(token[7]);
      currSurface.k_refl = float(token[8]);
      currSurface.gloss_radius = float(token[9]);
      if (debug_flag) println("[PARSE] using glossy surface: " + currSurface);
    }
    
    // -------- triangles -------- //
    
    else if (token[0].equals("begin")) {
      tempTriangle = new Triangle(currSurface);
    }
    else if (token[0].equals("vertex")) {
      Point p = new Point(float(token[1]), float(token[2]), float(token[3]));
      p = sceneGraph.applyTransform(p);
      if (triangleBuildInd == 0) {
        tempTriangle.p1 = p;
        triangleBuildInd++;
      } else if (triangleBuildInd == 1) {
        tempTriangle.p2 = p;
        triangleBuildInd++;
      } else if (triangleBuildInd == 2) {
        tempTriangle.p3 = p;
        triangleBuildInd = 0;
      }
    }
    else if (token[0].equals("end")) {
      objects.add(tempTriangle);
      //if (debug_flag) println("[PARSE] built triangle as object " + objects.size());
    }
    
    // -------- axis aligned box -------- //
    
    else if (token[0].equals("box")) {
      Point min = new Point(float(token[1]), float(token[2]), float(token[3]));
      Point max = new Point(float(token[4]), float(token[5]), float(token[6]));
      min = sceneGraph.applyTransform(min);
      max = sceneGraph.applyTransform(max);
      Box box = new Box(min, max, currSurface);
      objects.add(box);
      //if (debug_flag) println("[PARSE] built box as object " + objects.size());
    }
    
    // -------- sphere -------- //
    
    else if (token[0].equals("sphere")) {
      float radius = float(token[1]);
      Point center = new Point(float(token[2]), float(token[3]), float(token[4]));
      center = sceneGraph.applyTransform(center); // scaling is not currently applied to spheres
      Sphere sphere = new Sphere(center, radius, currSurface);
      objects.add(sphere);
      //if (debug_flag) println("[PARSE] built box as object " + objects.size());
    }
    
    // -------- moving objects -------- //
    
    else if (token[0].equals("moving_object")) {
      Object o = objects.get(objects.size() - 1);
      objects.remove(objects.size() - 1);
      MovingObject mo = new MovingObject(o, float(token[1]), float(token[2]), float(token[3]));
      objects.add(mo);
      if (debug_flag) println("[PARSE] Changed previous object into a moving object.");
    }
    
    // -------- object instancing -------- //
    
    else if (token[0].equals("named_object")) {
      Object o = objects.get(objects.size() - 1);
      objects.remove(objects.size() - 1);
      String name = token[1];
      namedObjects.put(name, o);
      if (debug_flag) println("[PARSE] Created named object: " + name);
    }
    else if (token[0].equals("instance")) {
      String name = token[1];
      Object o = namedObjects.get(name);
      if (o == null) println("[PARSE] [WARNING] Named object with name: '" + name + "' was not found, instancing aborted.");
      else {
        InstanceObject instance = new InstanceObject(o, new TMatrix(sceneGraph.getCurrentTransform().raw));
        objects.add(instance);
      }
      if (debug_flag) println("[PARSE] Instanced named object '" + name + "' with current transform as object " + objects.size());
    }
    
    // -------- BVH Accelerated Objects -------- //
    
    else if (token[0].equals("begin_accel")) {
      objects = BVHTempObjects; // mounts the bvh acceleration queue
      if (debug_flag) println("[PARSE] BVH queue mounted, start creating accelerated BVH object...");
    }
    else if (token[0].equals("end_accel")) {
      BVHNode bvhObj = new BVHNode(objects);
      if (debug_flag) println("[PARSE] BVH object with " + objects.size() + " primatives successfully created.");
      objects.clear(); // empties BVH acceleration queue
      objects = sceneObjects; // mounts back the scene object queue
      objects.add(bvhObj);
      if (debug_flag) println("[PARSE] BVH object creation complete, mounting back the scene object queue.");
    }
    
    // -------- scene graph / transformations -------- //
    
    else if (token[0].equals("translate")) {
      sceneGraph.translate(float(token[1]), float(token[2]), float(token[3]));
    }
    else if (token[0].equals("scale")) {
      sceneGraph.scale(float(token[1]), float(token[2]), float(token[3]));
    }
    else if (token[0].equals("rotate")) {
      if (token[2].equals("1")) sceneGraph.rotatex(float(token[1]));
      else if (token[3].equals("1")) sceneGraph.rotatey(float(token[1]));
      else if (token[4].equals("1")) sceneGraph.rotatez(float(token[1]));
    }
    else if (token[0].equals("rotatex")) {
      sceneGraph.rotatex(float(token[1]));
    }
    else if (token[0].equals("rotatey")) {
      sceneGraph.rotatey(float(token[1]));
    }
    else if (token[0].equals("rotatez")) {
      sceneGraph.rotatez(float(token[1]));
    }
    else if (token[0].equals("pop")) {
      sceneGraph.pop();
    }
    else if (token[0].equals("push")) {
      sceneGraph.push();
    }
    
    // -------- other operations -------- //
    
    else if (token[0].equals("read")) {
      interpreter(token[1]);
    }
    else if (token[0].equals("render")) {
      println("[PARSE] Parse complete, drawing scene with " + objects.size() + " objects(s), " + lights.size() + " point light source(s), and " + diskLights.size() + " disk light source(s).");
      draw_scene();   // this is where you actually perform the scene rendering
    }
    else if (token[0].equals("#")) {
      // comment (ignore)
    }
    else {
      println ("[PARSE] [WARNING] Unknown command: " + token[0]);
    }
  }
}
