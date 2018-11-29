class Obstacle {
  public float x, y;
  public float radius;
  public float vel_x;
  public float vel_y;
  private color col;
  public boolean evil;
  
  public Obstacle(float x, float y, float tx, float ty) {
    evil = random(100) < 20;
    if (evil) {
      col = color(random(150,255),random(80),random(80));
    } else {
      col = color(random(80),random(255),random(150,255));
    }
    this.x = x;
    this.y = y;
    radius = random(16,48);
    float d = dist(x, y, tx, ty);
    float v = random(6, 14);
    vel_x = (tx-x) * v/d;
    vel_y = (ty-y) * v/d;
  }
  boolean isOut() {
    if (x >= -radius && x <= width/2+radius && y >= -radius && y <= height/2+radius)
      return false;
    
    return Math.signum(vel_x) == Math.signum(x)
        && Math.signum(vel_y) == Math.signum(y);
  }
  void draw() {
    noStroke();
    fill(col);
    ellipse(x, y, radius, radius);
    x += vel_x;
    y += vel_y;
  }
}
