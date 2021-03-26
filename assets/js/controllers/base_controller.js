import { Controller } from 'stimulus';
import { useApplication } from 'stimulus-use';

export default class extends Controller {
  connect() {
    useApplication(this);
  }
}
