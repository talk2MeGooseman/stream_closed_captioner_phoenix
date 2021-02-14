import { Controller } from 'stimulus';

export default class extends Controller {
  get menuTarget() {
    return this.element.querySelector('div[data-target="dropdown.menu"]')
  }

  connect() {
    this.toggleClass = this.data.get('class') || 'hidden';
  }

  toggle() {
    this.menuTarget.classList.toggle(this.toggleClass);
  }
}
