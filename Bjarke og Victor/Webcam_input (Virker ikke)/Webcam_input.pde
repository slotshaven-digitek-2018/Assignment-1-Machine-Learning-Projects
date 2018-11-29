/*
TO_DO List
 
 Skaler billeder
 Importer Face-detection fra processing skitse
 */

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress dest;

PFont f;

PImage man18;

void setup() {
  size(160, 160, P2D);
  noStroke();
  smooth();
  
  man18 = loadImage("man18.jpg");
  scaleImage();
}

void scaleImage() {
  man18.resize(160, 0);
}

void draw() {
  image(man18, 0, 0);
}
