import gab.opencv.*;
import processing.video.*;
import java.awt.*;
import oscP5.*;
import netP5.*;

/*
 * Sender 243 inputs til wekinator på port 6448
 * Modtager 1 classfier output fra wekinator på 12000
*/

// Dette objekt bruges til at snakke med webcammet
Capture video;
// Dette objekt bruges til at snakke med OpenCV (som bruges til at finde ansigter)
OpenCV opencv;

// De to objekter, der skal bruges til sende og modtage OSC (recv- er modtagelsesobjektet)
OscP5 oscP5, recvOscP5;
// Den addresse wekinator ligger på, når de skal sendes
NetAddress dest;
// Dette bruges til at sende kontrolbeskeder til Wekinator (se WekinatorProxy-filen skrevet af Fiebrink)
WekinatorProxy proxy;

// Denne variabel holder styr på, om vi har modtaget et svar fra Wekinator
boolean gotMsg = false;
// Denne variabel holder det ID, som vi har fået som svar fra Wekinator
int msg = 0;

// Det ID, som det ansigt, der optages, tilhører 
int idToLearn = 0;
// Om der træningsdata lige nu
boolean recording = false;
public ArrayList<Player> players = new ArrayList();
public ArrayList<Obstacle> obstacles = new ArrayList();

int winnerID = 0;

boolean DEBUGGING = true;
boolean RUNNING = false;

void setup() {
  // Vi sætter vinduet til at være 640x480 pixels storrt
  //size(640, 480);
  frameRate(60);
  fullScreen();
  // Vi starter så webcam caputeren op med halv stor opløsning, så den er lidt hurtigere
  
  players.add(new Player(64, 0, 255));
  players.add(new Player(255, 255, 0));
  
  video = new Capture(this, 640/2, 480/2);
  // Vi sætter samtidig OpenCV om med samme opløsning
  opencv = new OpenCV(this, 640/2, 480/2);
  // Vi sætter den til at lede efter frontale ansigter, altså finder den ansigter der kigger mod kameraet
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  
  // Opstarter alle OSC-objekter på deres respektive porte (se bekskrivelse i toppen)
  oscP5 = new OscP5(this,9000);
  proxy = new WekinatorProxy(oscP5);
  dest = new NetAddress("127.0.0.1",6448);
  recvOscP5 = new OscP5(this,12000);
  
  ellipseMode(RADIUS);
  ellipseMode(CENTER);
  
  // Bed Wekinator om at starte, så vi kan få klasseinformation
  proxy.startRunning();
  // Start webcam-capturen
  video.start();
}

void draw() {
  // Skalér alt der bliver tegnet op med 2 (da webcam-capturen har halv opløsning)
  scale(2);
  
  pushMatrix();
  scale(-1, 1);
  translate(-width/2, 0);
  // Tag en kopi af webcam-billedet
  PImage dsCopy = video.copy();
  // Vær sikker på den holder størrelsen på halvdelen af vinduet
  dsCopy.resize(640/2, 480/2);
  // Læs billedet i openCV
  opencv.loadImage(dsCopy);

  // Billedet tegnes på skærmen, så vi kan se, hvad den kigger på
  image(dsCopy, width/4-640/4, height/4-480/4);
 
  popMatrix();
  if (recording) {
    // Hvis vi er igang med at optage, skriver vi på skærmen, hvilket ID vi henter data for
    fill(255, 0, 0);
    text("Recording #"+idToLearn, width/4-640/4, 200);
  }

  // Sæt farverne til grøn, med en bredde på 3, så firkanterne bliver tydelige
  fill(0, 255, 0);
  noFill();
  stroke(0, 255, 0);
  strokeWeight(3);
  
  // Bed OpenCV om de steder, den har fundet ansigter
  Rectangle[] faces = opencv.detect();
  // Vi går gennem hvert ansigt
  for (int i = 0; i < faces.length; i++) {
    // For fat i ansigtet som billede
    PImage face = dsCopy.get(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
    
    // Kompenser for spejlning af billedet
    faces[i].x = width/2-faces[i].x-faces[i].width;
    
    // Flyt ind på midten
    faces[i].x -= width/4-640/4;
    faces[i].y += height/4-480/4;
    
    // Vi omdimensionerer det til 9x9, så vi får ens data til Wekinator hver gang
    face.resize(9, 9);
    
    // Find midten af ansigtet
    float x = faces[i].x + faces[i].width/2, y = faces[i].y + faces[i].height/2;
    
    if (DEBUGGING)
      image(face, 36*i, 0, 36, 36);
    
    // Dataen sendes til Wekinator via OSC
    sendOsc(face.pixels);
    
    int id = 0;
    
    // Vi tjekker 5 gange, om vi har fået svar fra Wekinator
    for(int j = 0; j < 5; j++) {
      // Vent 5 millisekunder
      delay(5);
      // Vi tjekker, om der er kommet en besked
      if (gotMsg) {
        // Vi sætter den til falsk, så vi ikke læser det samme svar igen
        gotMsg = false;
        
        id = msg;
        
        switch (msg) {
          case 1:
          players.get(0).x = x;
          players.get(0).y = y;
          break;
          case 2:
          players.get(1).x = x;
          players.get(1).y = y;
          break;
          case 3:
          if (players.size() >= 3) {
            players.get(2).x = x;
            players.get(2).y = y;
          }
          break;
        }
        // Vi skriver det ID, Wekinator har udregnet, på ansigtet
        if (DEBUGGING) {
          text(""+msg, 36*i+18, 18);
          text(""+msg, faces[i].x+2, faces[i].y+12);
        }
        break;
      }
    }
    // Tegn rektanglen, OpenCV har givet os.
    if (DEBUGGING)
      rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
      
    if (winnerID != 0 && id != 0 && winnerID != id) {
      if (winnerID != id) {
        fill(0);
        stroke(255, 0, 0);
      } else {
        stroke(255, 200, 0);
      }
      rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
      noFill();
      stroke(0, 255, 0);
      strokeWeight(3);
    }
  }

  if (winnerID == 0 && RUNNING) {
    if (frameCount % 20 == 0) {
      Player p = players.get(int(random(0, players.size())));
      
      int area = (int) random(1024) % 4;
      float x = 0, y = 0;
      switch (area) {
       case 0:
       x = width/2;
       case 1:
       y = random(height/2);
       break;
       case 2:
       y = height/2;
       case 3:
       x = random(width/2);
       break;
      }
      obstacles.add(new Obstacle(x, y, p.x, p.y));
    }
    Obstacle toDelete2 = null;
    for (Obstacle obstacle : obstacles) {
      obstacle.draw();
      if (toDelete2 == null && obstacle.isOut()) {
        toDelete2 = obstacle;
      }
    }
    obstacles.remove(toDelete2);
    
    int pointWidth = 98;
    int left = width/4-pointWidth/2;
    int down = 10;
    fill(128);
    noStroke();
    textSize(24);
    rect(left, down, pointWidth, (players.size()-1)*32+30, 5);
    for (int i = 0; i < players.size(); i++) {
      players.get(i).draw();
      int points = players.get(i).point;
      text("P"+(i+1)+": "+points, left+2, i*32+24+down);
      
      if (points >= 100) {
        winnerID = i+1;
      }
      
      Obstacle toDelete = null;
      for (Obstacle obstacle : obstacles) {
        if (players.get(i).collides(obstacle)) {
          if (obstacle.evil) {
            players.get(i).point -= 10;
          } else {
            players.get(i).point += 5;
          }
          toDelete = obstacle;
          break;
        }
      }
      if (toDelete != null)
        obstacles.remove(toDelete);
    }
    textSize(12);
  }
}

void keyReleased() {
  // Tjek, om den knap, der blev trykket på, er et tal.
  int d = int(key+"");
  // Udskriv til debugging
  println(key);

  // Hvis det ikke er et 0, er det et nyd ansigts-ID
  if (d != 0)
    idToLearn = d;
  /*
  if (key == '1') {
    players.get(0).point += 10;
  }
  if (key == '2') {
    players.get(1).point += 10;
  }
  if (players.size() >= 3 && key == '3') {
    players.get(2).point += 10;
  }
  */
  
  if (players.size() == 2 && key == 'p' || key == 'P') {
    players.add(new Player(30, 230, 80));
  }

  if (key == 'd' || key == 'D') {
    DEBUGGING = !DEBUGGING;
  }
  if (key == ' ') {
    RUNNING = !RUNNING;
    DEBUGGING = !RUNNING;
  }
  if (key == 'x' || key == 'X') {
    proxy.deleteTraining();
  }
  
  // Trykkes på knappen R, skal vi skifte recording-mode
  if (key == 'r' || key == 'R') {
    if (recording) {
      // Hvis vi er igang med at optage indstiller vi optagningen, og starter Wekinator igen
      proxy.startRunning();
      proxy.stopRecording();
      // Ydermere træner vi på det nye data
      proxy.train();
      // Vi sætter flaget til falsk igen
      recording = false;
    } else if (idToLearn != 0) {
      // Hvis vi ikke optager, og har et ID at træne til, stopper vi Wekinator
      proxy.stopRunning();
      // Vi sætter outputtet til det ID, vi har fået
      proxy.setOutput(idToLearn);
      // Og begynder at optage træningsdata til ID'et
      proxy.startRecording();
      // Sætter flaget til sandt, så vi kan stopppe det hele igen, når R gentrykkes
      recording = true;
    } else {
      // Optager vi ikke, og heller ikke har noget ID, sørger vi lige for, at vi er sikre på, vi ikke optager
      proxy.stopRecording();
    }
  } 
}

void captureEvent(Capture c) {
  // Læs data fra kameraet
  c.read();
}

//This is called automatically when OSC message is received
void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/wek/outputs") == true) {
    // Vi sørger for, vi har fået et tal fra Wekinator som output
    if(theOscMessage.checkTypetag("f")) {
      float f = theOscMessage.get(0).floatValue();
      // Vi gemmer dataen, vi har fra Wekinator, og sætter flaget
      gotMsg = true;
      msg = int(f);
    }
  }
  
}

void sendOsc(int[] px) {
  OscMessage msg = new OscMessage("/wek/inputs");
  for (int i = 0; i < px.length; i++) {
    color p = px[i];
    msg.add(red(p));
    msg.add(green(p));
    msg.add(blue(p));
  }
  // Sidst sender vi beskeden
  oscP5.send(msg, dest);
}
