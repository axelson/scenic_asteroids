var config = {
  type: Phaser.AUTO,
  width: 800,
  height: 600,
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

var game = new Phaser.Game(config);

function preload() {
  this.load.setBaseURL('http://labs.phaser.io');

  this.load.image('sky', 'assets/skies/space3.png');
  this.load.image('logo', 'assets/sprites/phaser3-logo.png');
  this.load.image('red', 'assets/particles/red.png');
}

function create() {
  this.add.image(400, 300, 'sky');

  var particles = this.add.particles('red');

  var emitter = particles.createEmitter({
    speed: 100,
    scale: {
      start: 1,
      end: 0
    },
    blendMode: 'ADD'
  });

  var logo = this.physics.add.image(400, 100, 'logo');

  logo.setVelocity(100, 200);
  logo.setBounce(1, 1);
  logo.setCollideWorldBounds(true);

  emitter.startFollow(logo);

  cursors = this.input.keyboard.createCursorKeys();
  keys = {};
}

// game.input.addPointer(3);

// game.input.onDown.add(itemTouched, this);
// game.input.on('pointerdown', itemTouched, game);

function itemTouched(pointer) {
  console.log("item touched!!!!");
}

function recordDirection(direction) {
  if (!keys[direction]) {
    console.log(`recording direction: ${direction}`)
    keys[direction] = true;
    window.onDirection(direction);
  }
}

function unRecordDirection(direction) {
  if (keys[direction]) {
    keys[direction] = false;
    console.log('pau ' + direction);
    window.onClearDirection(direction);
  }
}

function update() {
  console.log('update!')
  // console.log("keys", keys);

  // console.log("cursors.left", cursors.left)
  var pointer = game.input.activePointer;
  if (pointer.isDown) {
    var touchX = pointer.x;
    var touchY = pointer.y;
    alert(`x: ${touchX} y:${touchY}`);
  }

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
