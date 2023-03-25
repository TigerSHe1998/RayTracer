// This file contains scene Graph + basic Transformation matrix implementation

class MatrixStack {
  public Stack<TMatrix> s;
  
  public MatrixStack() {
    this.s = new Stack<TMatrix>();
    this.s.push(new TMatrix("identity"));
  }
  
  public String toString() {
    return "MatrixStack Object containing " + this.s.size() + " matrices. Top element: " + this.s.peek();
  }
  
  public void push() { // make a copy of current array and add to top of stack
    this.s.push(new TMatrix(this.s.peek().raw));
  }
  
  public void pop() {
    if (this.s.size() == 1) println("[MATRIXSTACK] [WARNING] Trying to pop the base identity matrix, operation aborted.");
    else this.s.pop();
  }
  
  public void translate(float x, float y, float z) {
    TMatrix curr = this.s.pop();
    curr.matmul(new TMatrix("translate", x, y, z));
    this.s.push(curr);
  }
  
  public void scale(float x, float y, float z) {
    TMatrix curr = this.s.pop();
    curr.matmul(new TMatrix("scale", x, y, z));
    this.s.push(curr);
  }
  
  public void rotatex(float angle) {
    TMatrix curr = this.s.pop();
    curr.matmul(new TMatrix("rotatex", angle));
    this.s.push(curr);
  }
  
  public void rotatey(float angle) {
    TMatrix curr = this.s.pop();
    curr.matmul(new TMatrix("rotatey", angle));
    this.s.push(curr);
  }
  
  public void rotatez(float angle) {
    TMatrix curr = this.s.pop();
    curr.matmul(new TMatrix("rotatez", angle));
    this.s.push(curr);
  }
  
  public Point applyTransform(Point old) {
    TMatrix curr = this.s.peek();
    float x = curr.raw[0][0] * old.x + curr.raw[0][1] * old.y + curr.raw[0][2] * old.z + curr.raw[0][3];
    float y = curr.raw[1][0] * old.x + curr.raw[1][1] * old.y + curr.raw[1][2] * old.z + curr.raw[1][3];
    float z = curr.raw[2][0] * old.x + curr.raw[2][1] * old.y + curr.raw[2][2] * old.z + curr.raw[2][3];
    return new Point(x, y, z);
  }
  
  public PVector applyTransform(PVector old) {
    TMatrix curr = this.s.peek();
    float x = curr.raw[0][0] * old.x + curr.raw[0][1] * old.y + curr.raw[0][2] * old.z;
    float y = curr.raw[1][0] * old.x + curr.raw[1][1] * old.y + curr.raw[1][2] * old.z;
    float z = curr.raw[2][0] * old.x + curr.raw[2][1] * old.y + curr.raw[2][2] * old.z;
    return new PVector(x, y, z);
  }
  
  public TMatrix getCurrentTransform() {
    return this.s.peek();
  }
}

// -----------------------------------------

class TMatrix { // transformation matrix
  public float[][] raw; // should be 4x4
  
  public TMatrix() { // Matrix with all zeros
    this.raw = new float[4][4];
  }
  
  public TMatrix(String mode) { // Identity
    this.raw = new float[4][4];
    if (mode.equals("identity")) {
      this.raw[0][0] = 1;
      this.raw[1][1] = 1;
      this.raw[2][2] = 1;
      this.raw[3][3] = 1;
    } else {
      println("[TMATRIX] [WARNING] Unrecognized tranformation matrix creation, defaulting to identity matrix.");
      this.raw[0][0] = 1;
      this.raw[1][1] = 1;
      this.raw[2][2] = 1;
      this.raw[3][3] = 1;
    }
  }
  
  public TMatrix(String mode, float x, float y, float z) { // Translate and Scale
    this.raw = new float[4][4];
    if (mode.equals("translate")) {
      this.raw[0][0] = 1;
      this.raw[1][1] = 1;
      this.raw[2][2] = 1;
      this.raw[3][3] = 1;
      this.raw[0][3] = x;
      this.raw[1][3] = y;
      this.raw[2][3] = z;
    } else if (mode.equals("scale")) {
      this.raw[0][0] = x;
      this.raw[1][1] = y;
      this.raw[2][2] = z;
      this.raw[3][3] = 1;
    } else {
      println("[TMATRIX] [WARNING] Unrecognized tranformation matrix creation, defaulting to identity matrix.");
      this.raw[0][0] = 1;
      this.raw[1][1] = 1;
      this.raw[2][2] = 1;
      this.raw[3][3] = 1;
    }
  }
  
  public TMatrix(String mode, float angle) { // 3D rotation
    this.raw = new float[4][4];
    if (mode.equals("rotatex")) {
      this.raw[0][0] = 1;
      this.raw[3][3] = 1;
      this.raw[1][1] = cos(radians(angle));
      this.raw[1][2] = - sin(radians(angle));
      this.raw[2][1] = sin(radians(angle));
      this.raw[2][2] = cos(radians(angle));
    } else if (mode.equals("rotatey")) {
      this.raw[1][1] = 1;
      this.raw[3][3] = 1;
      this.raw[0][0] = cos(radians(angle));
      this.raw[0][2] = sin(radians(angle));
      this.raw[2][0] = - sin(radians(angle));
      this.raw[2][2] = cos(radians(angle));
    } else if (mode.equals("rotatez")) {
      this.raw[2][2] = 1;
      this.raw[3][3] = 1;
      this.raw[0][0] = cos(radians(angle));
      this.raw[0][1] = - sin(radians(angle));
      this.raw[1][0] = sin(radians(angle));
      this.raw[1][1] = cos(radians(angle));
    } else {
      println("[TMATRIX] [WARNING] Unrecognized tranformation matrix creation, defaulting to identity matrix.");
      this.raw[0][0] = 1;
      this.raw[1][1] = 1;
      this.raw[2][2] = 1;
      this.raw[3][3] = 1;
    }
  }
  
  public TMatrix(float[][] copy) { // deep copy constructor for duplicating TMatrices
    this.raw = new float[4][4];
    for (int i = 0; i < copy.length; i++) {
      for (int j = 0; j < copy[0].length; j++) {
        this.raw[i][j] = copy[i][j];
      }
    }
  }
  
  public String toString() {
    return "TMatrix Object with content: " + Arrays.deepToString(this.raw);
  }
  
  public TMatrix matmul(TMatrix other) { // 4x4 Matrix multiplication to the right of current matrix 
    TMatrix res = new TMatrix(); // empty new matrix
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        for (int k = 0; k < 4; k++) res.raw[i][j] += this.raw[i][k] * other.raw[k][j];
      }
    }
    this.raw = res.raw;
    return res;
  }
  
  public TMatrix inverse() { // invert current TMatrix and returns a new TMatrix
    PMatrix3D invTemp = new PMatrix3D(raw[0][0], raw[0][1], raw[0][2], raw[0][3], raw[1][0], raw[1][1], raw[1][2], raw[1][3], raw[2][0], raw[2][1], raw[2][2], raw[2][3], raw[3][0], raw[3][1], raw[3][2], raw[3][3]);
    invTemp.invert();
    float[] invResult = new float[16];
    invTemp.get(invResult);
    float[][] invRaw = new float[4][4];
    for (int i = 0; i < invResult.length; i++) {
      if (i < 4) {
        invRaw[0][i] = invResult[i];
      } if (i >= 4 && i < 8) {
        invRaw[1][i - 4] = invResult[i];
      } if (i >= 8 && i < 12) {
        invRaw[2][i - 8] = invResult[i];
      } if (i >= 12 && i < 16) {
        invRaw[3][i - 12] = invResult[i];
      }
    }
    return new TMatrix(invRaw);
  }
}
