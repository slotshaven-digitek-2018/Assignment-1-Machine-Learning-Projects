class Player {
  public float x = width/4, y = height/4;
  public int point = 0;
  private color col;
  public Player(int r, int g, int b) {
    col = color(r, g, b);
  }
  void draw() {
    noStroke();
    fill(col);
    ellipse(x, y, 24, 24);
  }
  boolean collides(Obstacle obstacle) {
    return dist(x, y, obstacle.x, obstacle.y) <= (24+obstacle.radius)/2;
  }
}
