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
export function start(lobbyChannel) {
  bindJason()

  lobbyChannel.on('game_start', function() {
    if (!started) {
      window.onCreateGame()
      jQuery('#waiting-message').hide()
      jQuery('#player-instructions').show()
    }
    started = true
  })

  lobbyChannel.push('request_player_color', {})

  lobbyChannel.on('player_color', function(msg) {
    console.log("msg", msg)

    jQuery('#player-color-value')
      .text(msg.color)
      .css({color: cssColor(msg.color)})

    jQuery('#player-color').show()
  })
}

function cssColor(color) {
  switch(color) {
    case "orange_red": return "orangered"
    case "powder_blue": return "powderblue"
    default: return color
  }
}
