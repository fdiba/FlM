import ddf.minim.*;
import SimpleOpenNI.*;

public class ControlFrame extends PApplet {

  int w, h;

  ColorPicker cp;

  color mainColor;
  float strokeWeight;

  int btnWidth, btnHeight;

  PImage depthImage;
  int[] depthValues;
  int depthMin, depthMax;
  float rawImage;
  int range, blur, border, echo, sensibility, rangeBuffer, alpha;
  boolean frame;

  SimpleOpenNI  context;
  BlobDetection theBlobDetection;
  PImage mini;

  ArrayList<ArrayList<ArrayList<PVector>>> blobsLists;
  ArrayList<ArrayList<PVector>> blobCenterLists;

  public void setup() {

    size(w, h);
    frameRate(25);
    cp5 = new ControlP5(this);

    println("setup2");

    blobsLists = new ArrayList<ArrayList<ArrayList<PVector>>>();
    blobCenterLists = new ArrayList<ArrayList<PVector>>();

    range = 500;

    depthImage = createImage(640, 480, RGB);
    depthImage.loadPixels();
    for (int i = 0; i < depthImage.pixels.length; i++) {
      depthImage.pixels[i] = color(127);
    }
    depthImage.updatePixels();

    mini = new PImage(64*2, 48*2); 
    theBlobDetection = new BlobDetection(mini.width, mini.height);
    theBlobDetection.setPosDiscrimination(true);
    theBlobDetection.setThreshold(0.2f); 

    depthMin = 500;
    depthMax = 2000;
    rawImage = 5;
    border = 0;
    blur = 2;
    echo = 5;
    sensibility = 250;
    rangeBuffer = 10;
    alpha = 255;

    btnWidth = 50;
    btnHeight = 20;

    mainColor = color(255);
    strokeWeight = 4;

    context = new SimpleOpenNI(this);
    if (context.isInit() == false) {
      println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
      exit();
      return;
    }
    context.enableDepth();

    cp5 = new ControlP5(this);

    int w = 100;
    int h = 14;
    int xPos = 10;
    int yPos = 10;
    int yOffset = 20;

    cp5.addSlider("DEPTH MIN", 1, 9000-range, depthMin, xPos, yPos, w, h).setId(0);
    cp5.addSlider("DEPTH MAX", 1+range, 9000, depthMax, xPos, yPos+=yOffset, w, h).setId(1);
    cp5.addSlider("STROKE WEIGHT", 1, 100, strokeWeight, xPos, yPos+=yOffset, w, h).setId(2);    
    cp5.addSlider("BORDER", 0, 100, border, xPos, yPos+=yOffset, w, h).setId(3);
    cp5.addSlider("RAW IMG", 1, 10, rawImage, xPos, yPos+=yOffset, w, h).setId(4);
    cp5.addSlider("BLUR", 0, 100, blur, xPos, yPos+=yOffset, w, h).setId(5);

    cp = cp5.addColorPicker("picker")
      .setPosition(10, 135)
        .setColorValue(mainColor)
          .setId(6);

    cp5.addSlider("ECHO", 1, 300, echo, 10, 210, 100, 14).setId(7);
    cp5.addSlider("SENSIBILITY", 1, 2000, sensibility, 10, 230, 100, 14).setId(8);
    cp5.addSlider("RANGE BUFFER", 1, 100, rangeBuffer, 10, 250, 100, 14).setId(9);

    cp5.addToggle("useSound")
      .setPosition(10, 280)
        .setSize(btnWidth, btnHeight)
          .setValue(useSound)
            .setId(10);

    cp5.addToggle("frame")
      .setPosition(80, 280)
        .setSize(btnWidth, btnHeight)
          .setValue(frame)
            .setId(11);

    cp5.addButton("save jpg")
      .setValue(0)
        .setPosition(150, 280)
          .setSize(btnWidth, btnHeight).
            setId(12);

    cp5.addButton("close")
      .setValue(0)
        .setPosition(640-(btnWidth+10), 10)
          .setSize(btnWidth, btnHeight).
            setId(13);
  }
  void useSound(boolean result) {
    useSound = result;
    if (!result) {
      cp5.getController("SENSIBILITY").setPosition(10, -230);
      cp5.getController("RANGE BUFFER").setPosition(10, -250);
      cp5.getController("ECHO").setPosition(10, 210);
    } else {
      cp5.getController("ECHO").setPosition(10, -210);
      cp5.getController("SENSIBILITY").setPosition(10, 230);
      cp5.getController("RANGE BUFFER").setPosition(10, 250);
    }
  }
  void frame(boolean result) {
    frame = result;
  }
  public void controlEvent(ControlEvent evt) {

    switch(evt.getId()) {
      case(0):
      depthMin = (int)(evt.getController().getValue());
      if (depthMin + range > depthMax) cp5.getController("DEPTH MAX").setValue(depthMin + range);
      break;
      case(1):
      depthMax = (int)(evt.getController().getValue());
      if (depthMax < depthMin + range) cp5.getController("DEPTH MIN").setValue(depthMax - range);
      break;
      case(2):
      strokeWeight = (int)(evt.getController().getValue()); 
      break;
      case(3):
      border = (int)(evt.getController().getValue());
      break;
      case(4):
      rawImage = evt.getController().getValue(); 
      break;
      case(5):
      blur = (int)(evt.getController().getValue());
      break;
      case(6):
      int r = int(evt.getArrayValue(0));
      int g = int(evt.getArrayValue(1));
      int b = int(evt.getArrayValue(2));
      alpha = int(evt.getArrayValue(3));
      mainColor = color(r, g, b, alpha);
      break;
      case(7):
      echo = (int)(evt.getController().getValue());
      break;
      case(8):
      sensibility = (int)(evt.getController().getValue());
      break;
      case(9):
      rangeBuffer = (int)(evt.getController().getValue());
      break;
      case(12):
      takeIMG = true;
      break;
      case(13):
      exit(); 
      break;
    default:
      //println("got a control event from controller with id "+evt.getId());
      break;
    }
  }
  void setDepthImage() {
    depthValues = context.depthMap();

    depthImage.loadPixels();
    for (int i=0; i<depthValues.length; i++) {
      float value = depthValues[i];

      if (value < depthMin) value = depthMax;

      value = PApplet.map(value, depthMin, depthMax, 255, 0);
      value = Math.max(0, Math.min(255, value));

      int actualValue = depthImage.pixels[i] >> 16 & 0xFF;

      if (actualValue > value) value = actualValue - (actualValue - value)/rawImage;
      if (actualValue < value) value = actualValue + (value - actualValue)/rawImage;
      //if (actualValue < value) value = actualValue + (actualValue - value)/rawImage;

      depthImage.pixels[i] = ((int)value << 16) | ((int)value << 8) | (int)value;

      if (i > depthValues.length-640*border || i < 640*border || i%640<border || i%640>640-border  ) {
        if (frame)depthImage.pixels[i] = ((int)255 << 16) | ((int)0 << 8) | (int)0;
        else depthImage.pixels[i] = ((int)0 << 16) | ((int)0 << 8) | (int)0;
      }
    }
    depthImage.updatePixels();
  }
  void createIMG() {
    mini.copy(depthImage, 0, 0, depthImage.width, depthImage.height, 0, 0, mini.width, mini.height);
    fastblur(mini, blur);
    theBlobDetection.computeBlobs(mini.pixels);
    saveBlobsList();
  }
  void saveBlobsList() {

    ArrayList<ArrayList<PVector>> blobsList = new ArrayList<ArrayList<PVector>>();
    ArrayList<PVector> blobCenterList = new ArrayList<PVector>();

    Blob b;
    EdgeVertex eA, eB;

    for (int n=0; n<theBlobDetection.getBlobNb (); n++) {

      b = theBlobDetection.getBlob(n);

      if (b!=null) {

        ArrayList<PVector> blobVertices = new ArrayList<PVector>();
        PVector blobCenter = new PVector();

        for (int m=0; m<b.getEdgeNb (); m++) {

          eA = b.getEdgeVertexA(m);
          eB = b.getEdgeVertexB(m);

          if (eA !=null && eB !=null) {

            blobVertices.add(new PVector(eA.x*dWidth, eA.y*dHeight));
            blobVertices.add(new PVector(eB.x*dWidth, eB.y*dHeight));

            blobCenter.add(blobVertices.get(blobVertices.size()-2));
            blobCenter.add(blobVertices.get(blobVertices.size()-1));
          }
        }

        if (blobVertices.size()>0) {

          blobsList.add(blobVertices);

          blobCenter.div(blobVertices.size());
          blobCenterList.add(blobCenter);
        }
      }
    }

    blobsLists.add(blobsList);
    blobCenterLists.add(blobCenterList);

    while (blobsLists.size () > echo) {
      blobsLists.remove(0);
      blobCenterLists.remove(0);
    }
  }
  public void draw() {
    context.update();
    background(127);
    setDepthImage();

    image(depthImage, 0, 0);
    createIMG();
    image(mini, width-mini.width, height-mini.height);
  }
  void fastblur(PImage img, int radius) {
    if (radius<1) {
      return;
    }
    int w=img.width;
    int h=img.height;
    int wm=w-1;
    int hm=h-1;
    int wh=w*h;
    int div=radius+radius+1;
    int r[]=new int[wh];
    int g[]=new int[wh];
    int b[]=new int[wh];
    int rsum, gsum, bsum, x, y, i, p, p1, p2, yp, yi, yw;
    int vmin[] = new int[max(w, h)];
    int vmax[] = new int[max(w, h)];
    int[] pix=img.pixels;
    int dv[]=new int[256*div];
    for (i=0; i<256*div; i++) {
      dv[i]=(i/div);
    }

    yw=yi=0;

    for (y=0; y<h; y++) {
      rsum=gsum=bsum=0;
      for (i=-radius; i<=radius; i++) {
        p=pix[yi+min(wm, max(i, 0))];
        rsum+=(p & 0xff0000)>>16;
        gsum+=(p & 0x00ff00)>>8;
        bsum+= p & 0x0000ff;
      }
      for (x=0; x<w; x++) {

        r[yi]=dv[rsum];
        g[yi]=dv[gsum];
        b[yi]=dv[bsum];

        if (y==0) {
          vmin[x]=min(x+radius+1, wm);
          vmax[x]=max(x-radius, 0);
        }
        p1=pix[yw+vmin[x]];
        p2=pix[yw+vmax[x]];

        rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
        gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
        bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
        yi++;
      }
      yw+=w;
    }

    for (x=0; x<w; x++) {
      rsum=gsum=bsum=0;
      yp=-radius*w;
      for (i=-radius; i<=radius; i++) {
        yi=max(0, yp)+x;
        rsum+=r[yi];
        gsum+=g[yi];
        bsum+=b[yi];
        yp+=w;
      }
      yi=x;
      for (y=0; y<h; y++) {
        pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
        if (x==0) {
          vmin[y]=min(y+radius+1, hm)*w;
          vmax[y]=max(y-radius, 0)*w;
        }
        p1=x+vmin[y];
        p2=x+vmax[y];

        rsum+=r[p1]-r[p2];
        gsum+=g[p1]-g[p2];
        bsum+=b[p1]-b[p2];

        yi+=w;
      }
    }
  }
  private ControlFrame() {
  }

  public ControlFrame(Object theParent, int theWidth, int theHeight) {
    parent = theParent;
    w = theWidth;
    h = theHeight;
  }
  public ControlP5 control() {
    return cp5;
  }
  ControlP5 cp5;
  Object parent;
}

