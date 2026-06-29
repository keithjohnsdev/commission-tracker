import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="commission-calculator"
export default class extends Controller {
  static targets = ["amount", "rate", "output"]
  static values = { defaultRate: Number }
  connect() {
    this.calculate()   // show a value immediately on page load
  }

  calculate() {
    const amount = parseFloat(this.amountTarget.value) || 0
    const rate = parseFloat(this.rateTarget.value) || this.defaultRateValue || 0
    const commission = amount * rate

    this.outputTarget.textContent = commission.toLocaleString("en-US", {
      style: "currency", currency: "USD"
    })
  }
}
