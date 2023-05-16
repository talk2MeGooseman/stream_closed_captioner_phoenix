import { Application } from '@hotwired/stimulus';
import { CaptionsController } from './controllers';
import { DropdownController } from './controllers';
import { DarkmodeController } from './controllers';
import { ObsController } from './controllers';
import { TranslationController } from './controllers';
import { TwitchController } from './controllers';
import { ZoomController } from './controllers';

window.Stimulus = Application.start();

Stimulus.register('captions', CaptionsController);
Stimulus.register('darkmode', DarkmodeController);
Stimulus.register('dropdown', DropdownController);
Stimulus.register('obs', ObsController);
Stimulus.register('translations', TranslationController);
Stimulus.register('twitch', TwitchController);
Stimulus.register('zoom', ZoomController);
