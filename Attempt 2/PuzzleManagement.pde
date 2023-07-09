/*
  The goal here is to make a similar script to the previous one but with support for multiple boards at the same time, as when I eventually create and train the AI, I will need to have each AI try on it's own board.
 
 
 
 
 */
int gridSize = 5;
int[][] startingState = new int[gridSize][gridSize];
// a few more temporary variables for shuffling
int[] tempArray = new int[gridSize*gridSize];
int tempIndex;
int temp;
// is it solvable?
boolean solvable;
// number of inversions
int inversions;
// the current grid position of the empty square
int[] zeroSpot = new int[2];

void setup() {
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      startingState[i][j] = gridSize*i + j + 1;
      if (startingState[i][j] == gridSize*gridSize) {
        zeroSpot[1] = i;
        zeroSpot[0] = j;
      }
    }
  }
  shuffleArray();
}

// shuffles the array at the beginning by loading all values into one array and using the ficher-yates/knuth shuffle
void shuffleArray() {
  // loads all values into 1 array
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      tempArray[gridSize*i + j] = startingState[i][j];
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
      startingState[i][j] = tempArray[gridSize * i + j];
      if (tempArray[gridSize * i + j] == gridSize * gridSize) {
        zeroSpot[1] = i;
        zeroSpot[0] = j;
      }
    }
  }
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
      tempArray[gridSize*i + j] = startingState[i][j];
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
void draw() {
}

class puzzle {
  int[][] state = new int[gridSize][gridSize];
  int[] zeroPos = new int[2];
  int[][] validMoves = new int[4][2];
  puzzle (int[][] startState, int[] zeroPo) {
    state = startState;
    zeroPos = zeroPo
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
  void move(int direction) {
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
}
