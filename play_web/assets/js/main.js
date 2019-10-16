console.log("main")

function bindJason() {
  let loginForm = document.getElementById("login-form")
  let usernameInput = document.getElementById("username-input")
  let jasonLoginBtn = document.getElementById("jason-login-btn")

  if (jasonLoginBtn) {
    jasonLoginBtn.addEventListener("click", e => {
      console.log("logging in as jason")
      e.preventDefault()
      usernameInput.value = "jason"
      loginForm.submit()
    })
  }
}

let started = false
export function start(socket, lobbyChannel) {
  bindJason()

  jQuery('#fullscreen-button').on('click', function (e) {
    if (window.game.scale.isFullscreen) {
      window.game.scale.stopFullscreen()
    } else {
      window.game.scale.startFullscreen()
    }
  })

  lobbyChannel.on('game_start', function() {
    console.log('game starting!')
    if (!started) {
      window.onCreateGame()
      jQuery('#waiting-message').hide()
      jQuery('#player-instructions').css('visibility', 'visible')
      jQuery('#fullscreen-button').css('visibility', 'visible')
    }
    started = true

    lobbyChannel.push('request_player_color', {})
  })

  lobbyChannel.on('player_color', function(msg) {
    console.log("msg", msg)

    jQuery('#player-color-value')
      .text(msg.color)
      .css({color: cssColor(msg.color)})

    jQuery('#player-color').css('visibility', 'visible')
  })

  lobbyChannel.onClose(() => {
    console.log('channel closed!')
  })

  lobbyChannel.onError(e => {
    console.log("lobby channel error", e)
  })

  socket.onOpen(() => {
    jQuery('#disconnected-message').hide();
  })

  socket.onError(e => {
    if (socket.isConnected()) {
      jQuery('#disconnected-message').hide();
    } else {
      jQuery('#disconnected-message').show();
    }
  })
}

function cssColor(color) {
  switch(color) {
    case "orange_red": return "orangered"
    case "powder_blue": return "powderblue"
    default: return color
  }
}
