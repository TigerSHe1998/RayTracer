// This file contains code that handles sketch controls

void keyPressed() {
  switch(key) {
    case '1': reset_scene(); interpreter("SampleScene1_fast.cli"); break;
    case '2': reset_scene(); interpreter("SampleScene2_fast.cli"); break;
    case '3': reset_scene(); interpreter("SampleScene3_fast.cli"); break;
    case '4': reset_scene(); interpreter("SampleScene4_fast.cli"); break;
    case '5': reset_scene(); interpreter("CustomScene_fast.cli"); break;
    case '!': reset_scene(); interpreter("SampleScene1_slow.cli"); break;
    case '@': reset_scene(); interpreter("SampleScene2_slow.cli"); break;
    case '#': reset_scene(); interpreter("SampleScene3_slow.cli"); break;
    case '$': reset_scene(); interpreter("SampleScene4_slow.cli"); break;
    case '%': reset_scene(); interpreter("CustomScene_slow.cli"); break;
    case '+': fov += 1.0; draw_scene(); break;
    case '-': fov -= 1.0; draw_scene(); break;
  }
}

// prints mouse location clicks, for help debugging
void mousePressed() {
  println ("[DEBUG] Mouse pressed at x=" + mouseX + " y=" + mouseY);
}
