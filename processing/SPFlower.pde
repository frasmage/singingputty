class SPFlower {
  //fields
  public Point center;
  public Point targetCenter;
  public float size = height/3.5;
  public Point anchor;
  public Point anchorOffset = new Point(random(-height/10,height/10),random(height/10));
  public PShape bloom;
  public float sizeMin = size;
  public float sizeMax = size*1.25;
  public float sizeStepper = PI;
  public boolean enabled;
  public float easingSpeed = .1;
  
  //constructor
  public SPFlower(Point center, Point anchor, PShape bloom){
    this.center = center;
    
    targetCenter = new Point(center.x,center.y);
    this.anchor = anchor;
    this.bloom = bloom;
  }
  
  public void draw(){
    //draw stem
    stroke(0,255,0); //green
    strokeWeight(height/80);
    noFill();
    bezier(anchor.x,anchor.y,anchor.x+anchorOffset.x,anchor.y-anchorOffset.y,
    center.x+anchorOffset.x/2,center.y-anchorOffset.y/2,center.x,center.y);
    
    //draw flower bloom
    if(bloom != null){
      shapeMode(CORNER);
      bloom.enableStyle();
      float displaySize;
      if(enabled){
        displaySize = sin(sizeStepper)*(sizeMax-sizeMin)+sizeMin;
        sizeStepper+= PI/20;
      }
      else displaySize = size;
      shape(bloom,center.x-displaySize/2,center.y-displaySize/2,displaySize,displaySize);
    }
    //animate
  }
  
  public void update(){
    //ease towards target location
    if(targetCenter.y != center.y)println(targetCenter.y +" - "+ center.y);
    center.x += (targetCenter.x -center.x)*easingSpeed;
    center.y += (targetCenter.y -center.y)*easingSpeed;
  }
}
