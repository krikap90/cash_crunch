// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import Chart from 'chart.js/auto';

let hooks = {}
hooks.ChartJS =  {
  // this function will help deserialize the dataset
   options() { return {
      plugins: {
        legend: {
          display: true,
          position: 'bottom',
          align: 'left'
        }
      },
      scales: {
        y: {
            beginAtZero: true
        }
      },
      responsive: true,
      maintainAspectRatio: false
    }},
   dataset() { return JSON.parse(this.el.dataset.datasets); },
   mounted() {
    const ctx = this.el;
    const data = {
        type: 'line',
        data: {
          labels: ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'],
          datasets: this.dataset()
        },
        options: this.options()
      };
    const chart = new Chart(ctx, data);
    this.el.chart = chart

    this.handleEvent("update-datasets", function(payload){ 
      const id = payload.relevant_id
      const chartObject = document.getElementById(id);
      chartObject.chart.data.datasets = JSON.parse(payload.datasets);
      chartObject.chart.update();
    })
   },
    updated() { 
     this.el.chart.data.datasets = this.dataset()
     this.el.chart.options = this.options()
   }
 }

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  hooks: hooks,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


// Allows to execute JS commands from the server
window.addEventListener("phx:js-exec", ({detail}) => {
  document.querySelectorAll(detail.to).forEach(el => {
    liveSocket.execJS(el, el.getAttribute(detail.attr))
  })
})
