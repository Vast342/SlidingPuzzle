  /* //<>//
  The goal here is to create a sliding puzzle and then eventually train an ai to solve it, somehow
 something something genetic algorithm,
 something something inputs being the state of the board
 something something reward getting a square to its spot in order
 something something punish displacing already placed squares
 something something output be one of the 4 moves and immediately punish for trying a move it can't do
 I need to adapt a few things.
 */
// defines a bunch of variables to define how the colors, sizes, and centering of the grid is going to work
int gridSize = 5; // valid values for now are 5 and 10, and you need to change one number down in the mouse position detection one from a 2 to a 4 if you make it 10
float sizeConstant = 1080/gridSize;
// not strictly necessary
float colorConstant = 255/(gridSize*gridSize);
float smolColorConstant = 100/(gridSize*gridSize);
float edgeConstant = (1920/2) - (((float)gridSize/2) * sizeConstant);
// a temporary variable used for the swaps
int temp;
// where the mouse is in the grid, which is then updated each frame
int[] mousePos = new int[2];
// the current grid position of the empty square
int[] zeroPos = new int[2];
// the nested array that stores the current state of the puzzle
int[][] puzzle = new int[gridSize][gridSize];
// a few more temporary variables for shuffling
int[] tempArray = new int[gridSize*gridSize];
int tempIndex;
// detecting how many tiles are done
boolean[] finishedTiles = new boolean[gridSize*gridSize];
// variable to show if its done
boolean done;
// completion, measured in how much of the puzzle is done
int completion;
// how many moves you've used
int moves;
// what moves you can do
int[][] validMoves = new int[4][2];
// fitness value scaled with time and amount done, so most likely on a scale of 100 where each one done is 4 points and each second spent is -0.25 points or something
float fitness;
// is it solvable?
boolean solvable;
// number of inversions
int inversions;
// shows the amount you can move
boolean[] canMove = new boolean[4];
// the number of frames that have passed since the start of the program
int frames;

// run before it starts
void setup() {
  fullScreen();
  textSize(30);
  frameRate(60);
  network thing = new network(12);
  thing.initialize();
  // initializes the array and all of its values
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      puzzle[i][j] = gridSize*i + j + 1;
      if (puzzle[i][j] == gridSize*gridSize) {
        zeroPos[1] = i;
        zeroPos[0] = j;
      }
    }
  }
  // shuffle the board
  shuffleArray();
}

// updates the valid moves
void moveUpdate() {
  // makes it so each subarray in validMoves is the grid coordinates of a potential move
  validMoves[0][0] = zeroPos[0] + 1;
  validMoves[1][0] = zeroPos[0] - 1;
  validMoves[2][1] = zeroPos[1] + 1;
  validMoves[3][1] = zeroPos[1] - 1;
  validMoves[0][1] = zeroPos[1];
  validMoves[1][1] = zeroPos[1];
  validMoves[2][0] = zeroPos[0];
  validMoves[3][0] = zeroPos[0];
  // detects if the move is on the board or not, and if it isn't than it sets it to -10 so I can show that it's impossible
  for (int i = 0; i < validMoves.length; i++) {
    for (int j = 0; j < validMoves[0].length; j++) {
      if (validMoves[i][j] < 0 || validMoves[i][j] >= gridSize) {
        validMoves[i][j] = -10;
      }
    }
  }
}

// shuffles the array at the beginning by loading all values into one array and using the ficher-yates/knuth shuffle
void shuffleArray() {
  // loads all values into 1 array
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      tempArray[gridSize*i + j] = puzzle[i][j];
    }
  }
  // randomizes it using ficher-yates / knuth shuffle
  for (int i = 0; i < gridSize * gridSize; i++) {
    // basically it goes through the array and selects a value in order and a random value from it and swaps them
    tempIndex = Math.round(random(gridSize*gridSize-1));
    temp = tempArray[i];
    tempArray[i] = tempArray[tempIndex];
    tempArray[tempIndex] = temp;
  }
  // puts the values back into the original array and then detects where the tile equal to gridSize squared is
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      puzzle[i][j] = tempArray[gridSize * i + j];
      if (tempArray[gridSize * i + j] == gridSize * gridSize) {
        zeroPos[1] = i;
        zeroPos[0] = j;
      }
    }
  }
  // update the possible moves
  moveUpdate();
  // check if its solvable
  solveableCheck();
}

// checks if the puzzle is solvable, and if not it shuffles.
/*
The algorithm I am using here is quite interesting, as it is seemingly random.
 First, we need to define an inversion. If you put all the numbers into one array, just like for the shuffle, than an inversion occurs if 2 numbers if a comes before b but a > b
 If the size of the grid is odd, then the puzzle is solvable if the number of inversions are even
 If the size of the grid is even, the puzzle is solvable if 1 of 2 things is true
 - Either the blank is on an even row from the bottom and number of inversions is odd
 - the blank is on an odd row counting from the bottom, and number of inversions is even
 it's goofy, and explained better than I ever could on the site geeksforgeeks.
 */
void solveableCheck() {
  // sets solvable to false so that i can override it later, saves a bit of if logic
  solvable = false;
  inversions = 0;
  // check inversions
  // loads all values into 1 array (taken from earlier)
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      tempArray[gridSize*i + j] = puzzle[i][j];
    }
  }
  // loops through said array and finds the inversions
  for (int i = 0; i < tempArray.length-1; i++) {
    for (int j = i + 1; j < tempArray.length; j++) {
      // sidenote if you are looking at the code on geeksforgeeks this is pretty similar except I use gridSize * gridSize as my empty tile.
      if (tempArray[j] != gridSize*gridSize && tempArray[i] != gridSize*gridSize && tempArray[i] > tempArray[j]) {
        inversions++;
      }
    }
  }
  // detect even or odd gridSize
  if (gridSize % 2 == 0) {
    // detects if either thing is true
    if ((gridSize - zeroPos[1]) % 2 == 0 && inversions % 2 != 0) {
      solvable = true;
    } else if ((gridSize - zeroPos[1]) % 2 != 0 && inversions % 2 == 0) {
      solvable = true;
    }
  } else {
    // detects if inversions are even
    if (inversions % 2 == 0) {
      solvable = true;
    }
  }
  // if its not solvable, reset the array and try again.
  if (solvable == false) {
    shuffleArray();
  }
}

// swaps the values given
void swapArrayValues(int row1, int position1, int row2, int position2) {
  temp = puzzle[row1][position1];
  puzzle[row1][position1] = puzzle[row2][position2];
  puzzle[row2][position2] = temp;
}

void mouseUpdate() {
  // detects what grid position the mouse is over and puts it into the mousePos array
  mousePos[0] = (int)constrain(mouseX / sizeConstant - 2, 0, gridSize-1);
  mousePos[1] = (int)constrain(mouseY / sizeConstant, 0, gridSize-1);
  // if the mouse is pressed
  if (mousePressed == true) {
    // if the move is valid to do on 1 axis
    if (mousePos[0] == zeroPos[0] && mousePos[1] - 1 == zeroPos[1] || mousePos[1] + 1 == zeroPos[1] && mousePos[0] == zeroPos[0]) {
      // make the move
      swapArrayValues(mousePos[1], mousePos[0], zeroPos[1], zeroPos[0]);
      // update where the zero is so we know where to render the color and how to swap next time, and updates what the possible moves are
      zeroPos[0] = mousePos[0];
      zeroPos[1] = mousePos[1];
      moveUpdate();
      moves++;
      // this is the same thing but for the other axis
    } else if (mousePos[1] == zeroPos[1] && mousePos[0] - 1 == zeroPos[0] || mousePos[0] + 1 == zeroPos[0] & mousePos[1] == zeroPos[1]) {
      swapArrayValues(mousePos[1], mousePos[0], zeroPos[1], zeroPos[0]);
      zeroPos[0] = mousePos[0];
      zeroPos[1] = mousePos[1];
      moveUpdate();
      moves++;
    }
  }
}

void render() {
  // resets the background
  background(0, 0, 0);
  // loops through the entire grid
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      // sets the default color, which scales how blue it is based off of the value of the tile.
      fill(255-(colorConstant*puzzle[i][j]), 0, colorConstant*puzzle[i][j]);
      // updates color of empty square to black
      if (i == zeroPos[1] && j == zeroPos[0]) {
        fill(0, 0, 0);
      }
      // if the move is valid, tint the box pink ( for debugging only)
      if (i == validMoves[0][1] && j == validMoves[0][0] || i == validMoves[1][1] && j == validMoves[1][0] || i == validMoves[2][1] && j == validMoves[2][0] || i == validMoves[3][1] && j == validMoves[3][0]) {
        //fill(255-smolColorConstant*puzzle[i][j], 150, 150+smolColorConstant*puzzle[i][j]);
      }
      // draws the rectangles based off of the position, sizeConstant, and the edgeConstant so it's centered
      rect(j*sizeConstant + edgeConstant, i*sizeConstant, sizeConstant, sizeConstant);
      // displays text of the value
      textSize(30);
      fill(255, 255, 255);
      text(puzzle[i][j], j*sizeConstant + edgeConstant, i*sizeConstant+30);
      // completion text
      text("completion: " + completion + "/" + gridSize*gridSize, 0, 500);
      // time text
      text("Time: " + millis()/1000, 0, 600);
      // moves counter
      text("Moves: " + moves, 0, 550);
      // fitness text
      text("Fitness: " + fitness, 0, 650);
      // solvable text
      text("Solvable? " + solvable, 0, 700);
      // done text
      if (done == true) {
        textSize(100);
        text("Done!", 0, 100);
      }
      // reset button
      rect(1600, 100, 200, 100);
      fill(0, 0, 0);
      textSize(30);
      text("Reset", 1670, 165);
      // availible input index
      for (var l = 0; l < 4; l++) {
        if (validMoves[l][0] != -10 && validMoves[l][1] != -10) {
          fill(200, 0, 255);
          canMove[l] = true;
        } else {
          fill(255, 0, 0);
          canMove[l] = false;
        }
        rect(1600, 600+100*l, 75, 75);
      }
      fill(255, 255, 255);
      text("Move Right", 1675, 650);
      text("Move Left", 1675, 750);
      text("Move Down", 1675, 850);
      text("Move Up", 1675, 950);
      for (int l = 0; l < 4; l++) {
        if (validMoves[l][0] != -10 && validMoves[l][1] != -10) {
          fill(0, 0, 0);
          text(validMoves[l][0] + ", " + validMoves[l][1], 1600, 650+l*100);
        }
      }
    }
  }
}

// function to move the empty square, based on a direction
void move(int direction) { // 0 = up, 1 = right, 2 = down, 3 = left
  if (direction == 0 && canMove[3] == true) {
    swapArrayValues(zeroPos[1]-1, zeroPos[0], zeroPos[1], zeroPos[0]);
    zeroPos[0] = zeroPos[0];
    zeroPos[1] = zeroPos[1]-1;
  } else if (direction == 1 && canMove[0] == true) {
    swapArrayValues(zeroPos[1], zeroPos[0]+1, zeroPos[1], zeroPos[0]);
    zeroPos[0] = zeroPos[0]+1;
    zeroPos[1] = zeroPos[1];
  } else if (direction == 2 && canMove[2] == true) {
    swapArrayValues(zeroPos[1]+1, zeroPos[0], zeroPos[1], zeroPos[0]);
    zeroPos[0] = zeroPos[0];
    zeroPos[1] = zeroPos[1]+1;
  } else if (direction == 3 && canMove[1] == true) {
    swapArrayValues(zeroPos[1], zeroPos[0]-1, zeroPos[1], zeroPos[0]);
    zeroPos[0] = zeroPos[0]-1;
    zeroPos[1] = zeroPos[1];
  }
  moveUpdate();
  moves++;
}

// detects if you are done by checking if each tile is done each frame, could probably be optimised further with like only checking when a tile is updated,
// I tried that but it seems like it might just be better now because its either functioning completion value or efficient done detection
void doneDetect() {
  completion = 0;
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      if (puzzle[i][j] == gridSize*i + j + 1) {
        finishedTiles[gridSize*i + j] = true;
        completion++;
      } else {
        finishedTiles[gridSize*i + j] = false;
      }
    }
  }
  if (completion == gridSize * gridSize) {
    done = true;
  }
}

// detects input on the reset button
void buttonUpdate() {
  if (mousePressed == true && mouseX >= 1600 && mouseY >= 100) {
    if (mouseX <= 1800 && mouseY <= 200) {
      completion = 0;
      done = false;
      moves = 0;
      shuffleArray();
    }
  }
}

// detects input
void keyPressed() {
  if (key == CODED && done == false) {
    if (keyCode == UP) {
      move(0);
    } else if (keyCode == RIGHT) {
      move(1);
    } else if (keyCode == DOWN) {
      move(2);
    } else if (keyCode == LEFT) {
      move(3);
    }
  }
}

// calculates fitness
void calculateFitness() {
  fitness = 0;
  // calculate fitness with the function y=-1/3x+8, so that it's biased towards the first few spots more
  // side note this function means the highest value you can get is actually not quite 100, but its probably fine. it's a meaningless number anyway that is just used to judge.
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      if (puzzle[i][j] == gridSize * i + j + 1) {
        fitness += -0.33333 * (float)puzzle[i][j] + 8;
        fitness = round(fitness);
      }
    }
  }
}

void draw() {
  frames++;
  if (done == false) {
    mouseUpdate();
    calculateFitness();
    solveableCheck();
    doneDetect();
  }
  if (frames % 20 == 0) {
    brain();
  }
  buttonUpdate();
  render();
}
