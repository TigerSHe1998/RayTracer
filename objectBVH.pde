// This file contains implementation for BVH Ray accelerated renderable object

class BVHNode extends Object { // BVH tree implemented like a binary tree
  public BVHNode left;
  public BVHNode right;
  public List<Object> leafObjectList;
  public Box bbox;
  
  public BVHNode(List<Object> passedInObjects) {
    // calculate bbox for current node
    this.bbox = passedInObjects.get(0).boundingBox();
    for (Object o : passedInObjects) this.bbox = this.bbox.expandBy(o.boundingBox());
    // subdivision base case
    if (passedInObjects.size() < 4) { 
      this.leafObjectList = passedInObjects;
      this.left = null;
      this.right = null;
    // subdivision
    } else {
      // calaculate centroid range
      Point centroidMin = passedInObjects.get(0).centroid();
      Point centroidMax = passedInObjects.get(0).centroid();
      for (Object o : passedInObjects) {
        centroidMin.x = min(centroidMin.x, o.centroid().x);
        centroidMin.y = min(centroidMin.y, o.centroid().y);
        centroidMin.z = min(centroidMin.z, o.centroid().z);
        centroidMax.x = max(centroidMax.x, o.centroid().x);
        centroidMax.y = max(centroidMax.y, o.centroid().y);
        centroidMax.z = max(centroidMax.z, o.centroid().z);
      }
      float xRange = centroidMax.x - centroidMin.x;
      float yRange = centroidMax.y - centroidMin.y;
      float zRange = centroidMax.z - centroidMin.z;
      float maxRange = max(max(xRange, yRange), zRange);     
      // split object into two list based on max centroid range
      List<Object> leftList = new ArrayList();
      List<Object> rightList = new ArrayList();
      if (maxRange == xRange) {
        for (Object o : passedInObjects) {
          if (o.centroid().x <= (centroidMax.x + centroidMin.x) / 2) leftList.add(o);
          else rightList.add(o);
        }
      } else if (maxRange == yRange) {
        for (Object o : passedInObjects) {
          if (o.centroid().y <= (centroidMax.y + centroidMin.y) / 2) leftList.add(o);
          else rightList.add(o);
        }
      } else {
        for (Object o : passedInObjects) {
          if (o.centroid().z <= (centroidMax.z + centroidMin.z) / 2) leftList.add(o);
          else rightList.add(o);
        }
      }
      // recursively construct child nodes
      if (leftList.isEmpty()) this.left = null;
      else this.left = new BVHNode(leftList);
      if (rightList.isEmpty()) this.right = null;
      else this.right = new BVHNode(rightList);
      this.leafObjectList = null;
    }
  }
  
  public String toString() {
    return "An BVH accelerated node";
  }
  
  public Box boundingBox() {
    return new Box(this.bbox.min, this.bbox.max);
  }
  
  public Point centroid() {
    return this.bbox.centroid();
  }
  
  /*
  * trace ray against the current Node object, if hit will return the hit info object, if not hit returns null.
  * traces against the current bbox, if hit recurse deeper into the tree, if miss returns null. 
  */
  public HitInfo rayTrace(Ray ray) {
    // miss bbox, no hit
    if (bbox.rayTrace(ray) == null) return null;
    // at leaf node, trace against all leaf objects
    if (left == null && right == null) {
      // trace against all leaf objects
      List<HitInfo> hits = new ArrayList();
      for (Object o : leafObjectList) hits.add(o.rayTrace(ray));
      // find hit closest to ray origin
      float minDist = Integer.MAX_VALUE;
      int minInd = -1;
      for (int i = 0; i < hits.size(); i++) {
        HitInfo hInf = hits.get(i);
        if (hInf == null) continue;
        float currDist = hInf.hitPoint.vectorTo(ray.origin).mag();
        if (min(currDist, minDist) == currDist) {
          minDist = currDist;
          minInd = i;
        }
      }
      if (minInd == -1) return null; // all leaf node trace misses
      else return hits.get(minInd); // returns closest hit
    } 
    // at intermediate node, trace against both child nodes and return closest hit
    HitInfo leftResult = null;
    HitInfo rightResult = null;
    if (left != null) leftResult = left.rayTrace(ray);
    if (right != null) rightResult = right.rayTrace(ray);
    // both child trace misses, no hit
    if (leftResult == null && rightResult == null) return null;
    // only right child hits
    else if (leftResult == null && rightResult != null) return rightResult;
    // only left child hits
    else if (rightResult == null && leftResult != null) return leftResult;
    // both children hit, compare and return closeset hit
    else {
      float leftDist = leftResult.hitPoint.vectorTo(ray.origin).mag();
      float rightDist = rightResult.hitPoint.vectorTo(ray.origin).mag();
      return leftDist <= rightDist ? leftResult : rightResult; 
    }
  }
  
  /*
  * shades point on polygon, returns a 3 float tuple of color(0-1) in r g b order
  * hInf contains point on polygon + eye ray, l is light source we are shading to
  */
  public float[] diffuseShade(HitInfo hInf, Light l) { 
    Object hitObj = hInf.hitObject;
    return hitObj.diffuseShade(hInf, l);
  }
  
  /*
  * recursively calculates reflected color for point on polygon, returns a 3 float tuple of color(0-1) in r g b order
  * hInf contains point on polygon + incoming ray
  */
  public float[] reflectionShade(HitInfo hInf) {
    Object hitObj = hInf.hitObject;
    return hitObj.reflectionShade(hInf);
  }

}
