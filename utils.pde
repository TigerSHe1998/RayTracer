// This file contains only helper functions 

// converts float[r, g, b] to processing color int
public color floatTupleToColor(float[] tuple) { 
  return color(min(1, tuple[0]) * 255, min(1, tuple[1]) * 255, min(1, tuple[2]) * 255);
}
