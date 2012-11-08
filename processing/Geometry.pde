//some utility classes
class Point{
  float x,y;
  public Point(float x, float y){
    this.x = x;
    this.y = y;
  }
  public void draw(){
    point(x,y);
  }
}

class Rect{
  float x,y,w,h;
  public Rect(float x,float y, float w, float h){
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  public void draw(){
    rect(x,y,w,h);
  }
  public Point center(){
    return new Point(x+w/2,y+h/2);
  }
}
