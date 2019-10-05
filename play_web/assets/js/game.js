const scaleFactor = 0.6;
const gameWidth = 800 * scaleFactor;
const gameHeight = 350 * scaleFactor
var config = {
  type: Phaser.AUTO,
  width: gameWidth,
  height: gameHeight,
  scale: {
    mode: Phaser.Scale.FIT,
  },
  physics: {
    default: 'arcade',
    arcade: {
      gravity: {
        y: 200
      }
    }
  },
  scene: {
    preload: preload,
    create: create,
    update: update
  }
};

var cursors;
var keys;
var arrows;
var game;
var shooting = false;

// Circle location is used to calculate the angle for firing
const arrowBaseX = 100;
const arrowBaseY = 100;
const circleX = 350;
const circleY = 100;

window.onCreateGame = function() {
  game = new Phaser.Game(config);
}

function preload() {
  this.load.image('arrow', '/images/arrow.png');
}

function create() {
  arrows = this.physics.add.staticGroup();
  createArrows(arrows);

  this.input.on('gameobjectdown', function(pointer, gameObject) {
    if (isArrow(gameObject)) {
      const direction = arrowToDirection(gameObject);
      console.log("send", direction);

      sendSetDirection(direction);
    }
  });

  this.input.on('gameobjectup', function(pointer, gameObject) {
    if (isArrow(gameObject)) {
      const direction = arrowToDirection(gameObject);
      console.log("done", direction);
      sendClearDirection(direction);
    }
  });

  cursors = this.input.keyboard.createCursorKeys();
  keys = {};

  var graphics = this.add.graphics({ fillStyle: { color: 0x00ff00 } });

  var circle = new Phaser.Geom.Circle(circleX, circleY, 15);

  function drawCircle () {
    graphics.fillCircleShape(circle);
  }

  drawCircle(graphics, circle);

  this.input.on('pointerdown', function (pointer) {
    console.log('down!');
    var touchX = pointer.x;
    var touchY = pointer.y;
    console.log(`x: ${touchX} y:${touchY}`);

    var relX = touchX - circleX;
    var relY = touchY - circleY;
    // Only shoot if the touch is near the circle (ideally this area would be a
    // circle but it isn't really that important)
    if (Math.abs(relX) < 100 && Math.abs(relY) < 100) {
      shooting = true;
      sendShoot(relX, -relY);
    }
  });

  this.input.on('pointerup', function (pointer) {
    if (shooting) {
      shooting = false;
      clearShooting();
    }
  });
}

function arrowToDirection(gameObject) {
  switch(gameObject.name) {
    case 'right-arrow': return 'right';
    case 'down-arrow': return 'down';
    case 'left-arrow': return 'left';
    case 'up-arrow': return 'up';
    default: return false;
  }
}

function isArrow(gameObject) {
  return ['right-arrow', 'down-arrow', 'left-arrow', 'up-arrow'].indexOf(gameObject.name) !== -1
}

function createArrows() {
  const offset = 50;

  var rightArrow = arrows.create(arrowBaseX + offset, arrowBaseY, 'arrow').setInteractive();
  rightArrow.name = "right-arrow";

  var downArrow = arrows.create(arrowBaseX, arrowBaseY + offset, 'arrow').setInteractive();
  downArrow.name = "down-arrow";
  downArrow.angle = 90;

  var leftArrow = arrows.create(arrowBaseX - offset, arrowBaseY, 'arrow').setInteractive();
  leftArrow.name = "left-arrow";
  leftArrow.angle = 180;

  var upArrow = arrows.create(arrowBaseX, arrowBaseY - offset, 'arrow').setInteractive();
  upArrow.name = "up-arrow";
  upArrow.angle = 270;
}

// game.input.addPointer(3);

function recordDirection(direction) {
  // Need to keep track of if this key is currently pressed so we know when it
  // transitions
  if (!keys[direction]) {
    console.log(`recording direction: ${direction}`)
    keys[direction] = true;
    sendSetDirection(direction);
  }
}

function unRecordDirection(direction) {
  if (keys[direction]) {
    keys[direction] = false;
    console.log('unrecord ' + direction);
    sendClearDirection(direction);
  }
}

function sendSetDirection(direction) {
  window.onDirection(direction);
}

function sendClearDirection(direction) {
  window.onClearDirection(direction);
}

function sendShoot(relX, relY) {
  window.onSendShoot(relX, relY);
}

function clearShooting() {
  window.onClearShooting();
}

function update() {
  // console.log('update!')
  // console.log("keys", keys);

  // console.log("cursors.left", cursors.left)

  // TODO: Use this to periodically send the orientation of the ship
  // var pointer = game.input.activePointer;
  // if (pointer.isDown) {
  //   var touchX = pointer.x;
  //   var touchY = pointer.y;
  //   console.log(`x: ${touchX} y:${touchY}`);

  //   var relX = arrowBaseX - touchX;
  //   var relY = arrowBaseY - touchY;
  //   console.log(`relX: ${relX} relY: ${relY}`)
  // }

  // console.log("cursors.left.isDown", cursors.left.isDown);
  // console.log("cursors.right.isDown", cursors.right.isDown);
  // console.log("cursors.up.isDown", cursors.up.isDown);
  // console.log("cursors.down.isDown", cursors.down.isDown);

  if (cursors.left.isDown) {
    recordDirection('left');
  } else {
    unRecordDirection('left');
  }

  if (cursors.up.isDown) {
    recordDirection('up');
  } else {
    unRecordDirection('up');
  }

  if (cursors.right.isDown) {
    recordDirection('right');
  } else {
    unRecordDirection('right');
  }

  if (cursors.down.isDown) {
    recordDirection('down');
  } else {
    unRecordDirection('down');
  }
}
