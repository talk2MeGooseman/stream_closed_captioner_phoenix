import { Application } from 'stimulus';
import * as Controllers from './controllers';

window.Stimulus = Application.start();
window.Stimulus.register('captions', Controllers.CaptionsController);
window.Stimulus.register('darkmode', Controllers.DarkmodeController);
window.Stimulus.register('dropdown', Controllers.DropdownController);
window.Stimulus.register('obs', Controllers.ObsController);
window.Stimulus.register('translations', Controllers.TranslationController);
window.Stimulus.register('twitch', Controllers.TwitchController);
window.Stimulus.register('zoom', Controllers.ZoomController);
