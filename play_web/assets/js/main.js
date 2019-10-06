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
    }
    started = true
  })
}

