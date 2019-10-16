// Simple throttle implementation: https://jsfiddle.net/jonathansampson/m7G64/
export function throttle(callback, limit) {
  var wait = false; // Initially, we're not waiting
  return function () {
    // console.log('in throttled with', dir)
    if (!wait) { // If we're not waiting
      callback.call(); // Execute users function
      wait = true; // Prevent future invocations
      setTimeout(function () {
        wait = false; // And allow future invocations
      }, limit);
    }
  };
}
