/********************************************
 Flow Motion 2016 v1 © Florent Di Bartolo
 http://www.webodrome.fr/
 http://twitter.com/webodrome
 ********************************************/



































import javax.swing.*;
import java.awt.*;
import controlP5.*;
import java.util.Date;
import blobDetection.*;

private ControlP5 cp5;
ControlFrame cf;

Rectangle screen1;
Rectangle screen2;
int numberOfScreen;
boolean fsMode;
boolean takeIMG;

Minim minim;
AudioInput in;

int dWidth;
int dHeight;

boolean useSound;
float nPointer;
boolean init;

ArrayList<ArrayList<PVector>> actualBlobsList;

void setup() {

  println("setup");
  noFill();

  cp5 = new ControlP5(this);

  nPointer = 0;

  actualBlobsList = new ArrayList<ArrayList<PVector>>();

  if (fsMode) {
    dWidth = screen2.width;
    dHeight = screen2.height;
    frame.setLocation(screen1.width, 0);
  } else {
    dWidth = 640;
    dHeight = 480;
  }

  size(dWidth, dHeight, OPENGL);
  strokeCap(ROUND);
  strokeJoin(ROUND);

  useSound = false;

  minim = new Minim(this);
  in = minim.getLineIn(Minim.MONO);
}
ControlFrame addControlFrame(String theName, int theWidth, int theHeight) {


  Frame f = new Frame(theName);
  ControlFrame p = new ControlFrame(this, theWidth, theHeight);
  f.add(p);
  p.init();
  f.setTitle(theName);
  f.setSize(p.w, p.h);
  f.setLocation(100, 100);
  f.setResizable(false);
  f.setVisible(true);
  return p;
}
void init() {

  super.init();

  screen1 = new Rectangle();
  screen2 = new Rectangle();

  GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
  GraphicsDevice[] gs = ge.getScreenDevices();  

  GraphicsDevice gd = gs[0];
  GraphicsConfiguration[] gc = gd.getConfigurations();
  screen1 = gc[0].getBounds();

  numberOfScreen = gs.length;

  if (numberOfScreen > 1) {
    fsMode = true;
  }  

  if (fsMode) {
    gd = gs[1];
    gc = gd.getConfigurations();
    screen2 = new Rectangle();
    screen2 = gc[0].getBounds();

    frame.removeNotify();
    frame.setUndecorated(true);
    frame.addNotify();
  }

  frame.setTitle("main display");
  cf = addControlFrame("Flow Motion 2016 v1 © Florent Di Bartolo ", 640, 480);
} 
void draw() {
  background(0);

  if (cf.blobsLists.size()>0) {
    if (cf.echo > 1 && !useSound)displayEchos();
    computeLastBlobs();
    drawLastBlobs();
  }

  //drawBlobCenters();

  if (takeIMG) {
    saveIMG();
    takeIMG = false;
  }
}
void drawLastBlobs() {

  if (useSound) {
    noStroke();
    fill(cf.mainColor);
  } else {
    noFill();
    stroke(cf.mainColor);
    strokeWeight(cf.strokeWeight);
  }

  for (int i=0; i<actualBlobsList.size (); i++) {

    ArrayList<PVector> blobVertices = actualBlobsList.get(i);

    for (int j=0; j<blobVertices.size ()-1; j+=2) {

      PVector v1 = blobVertices.get(j);

      if (useSound) {
        nPointer += 0.001;
        float diam = noise(nPointer+j/10)*(cf.strokeWeight*2);
        ellipse(v1.x, v1.y, diam, diam);
      } else {
        PVector v2 = blobVertices.get(j+1);
        line(v1.x, v1.y, v2.x, v2.y);
      }
    }
  }
}
void computeLastBlobs() {

  ArrayList<ArrayList<PVector>> lastBlobsList = cf.blobsLists.get(cf.blobsLists.size()-1);
  ArrayList<PVector> blobCenterList = cf.blobCenterLists.get(cf.blobCenterLists.size()-1);

  if (actualBlobsList.size()<1) actualBlobsList.addAll(lastBlobsList);

  while (lastBlobsList.size () < actualBlobsList.size()) {  
    actualBlobsList.remove(actualBlobsList.size()-1);
  }  

  for (int i=0; i<lastBlobsList.size (); i++) {

    ArrayList<PVector> blobVertices = lastBlobsList.get(i);
    PVector blobCenter = blobCenterList.get(i);

    if (i>=actualBlobsList.size()) { //new blob
      actualBlobsList.add(blobVertices);
    } else { //update position

      ArrayList<PVector> actualblobVertices = actualBlobsList.get(i);

      while (blobVertices.size () < actualblobVertices.size()) {  
        actualblobVertices.remove(actualblobVertices.size()-1);
      }

      for (int j=0; j<blobVertices.size ()-1; j+=2) {

        int id1 = j;
        int id2 = j+1;

        PVector v1 = blobVertices.get(id1);
        PVector v2 = blobVertices.get(id2);

        if (useSound) {

          int range = cf.rangeBuffer;

          int pt1 = int(map(id1, 0, blobVertices.size()-1, 0, (in.bufferSize()-1)/range));
          float val1 = in.left.get(pt1) * cf.sensibility;

          PVector d1 = PVector.sub(v1, blobCenter);
          d1.normalize();
          d1.mult(val1);
          v1.add(d1);

          int pt2 = int(map(id2, 0, blobVertices.size()-1, 0, (in.bufferSize()-1)/range));
          float val2 = in.left.get(pt2) * cf.sensibility;

          PVector d2 = PVector.sub(v2, blobCenter);
          d2.normalize();
          d2.mult(val2);
          v2.add(d2);
        }

        if (j>=actualblobVertices.size()) { //new blob vertices

          actualblobVertices.add(v1);
          actualblobVertices.add(v2);
        } else { //update it

          PVector av1 = actualblobVertices.get(id1);
          PVector av2 = actualblobVertices.get(id2);

          av1.set(v1);
          av2.set(v2);
        }
      }
    }
  }
}
void displayEchos() {

  for (int b=0; b<cf.blobsLists.size ()-1; b++) { //do not display last one

    ArrayList<ArrayList<PVector>> blobsList = cf.blobsLists.get(b);

    for (int i=0; i<blobsList.size (); i++) {

      ArrayList<PVector> blobVertices = blobsList.get(i);

      float alpha = map(b, 0, cf.blobsLists.size ()-1, 25, cf.alpha);
      stroke(cf.mainColor, alpha);
      float weight = map(b, 0, cf.blobsLists.size ()-1, 1, cf.strokeWeight);
      strokeWeight(weight);

      for (int j=0; j<blobVertices.size ()-1; j+=2) {

        PVector v1 = blobVertices.get(j);
        PVector v2 = blobVertices.get(j+1);

        line(v1.x, v1.y, v2.x, v2.y);
      }
    }
  }
}
void drawBlobCenters() {

  ArrayList<ArrayList<PVector>> blobCenterLists = cf.blobCenterLists;

  for (int i=0; i<blobCenterLists.size (); i++) {

    ArrayList<PVector> blobCenterList = blobCenterLists.get(i);

    float alpha = map(i, 0, blobCenterLists.size ()-1, 25, 225);

    for (int j=0; j<blobCenterList.size (); j++) {

      PVector v = blobCenterList.get(j);

      stroke(255, 255, 0, alpha);
      strokeWeight(5);
      ellipse(v.x, v.y, 16, 16);
    }
  }
}
void saveIMG() {
  Date date = new Date();
  String name = "data/flm-" + date.getTime() + ".jpg";
  save(name);
}

