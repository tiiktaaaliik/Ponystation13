import { Feature, FeatureColorInput, FeatureToggle, CheckboxInput } from '../base';

// Taken from the OOC toggle found in [tgui\packages\tgui\interfaces\PreferencesMenu\preferences\features\game_preferences\legacy_chat_toggles.tsx]
// export const should be same with savefile_key in /datum/preference/toggle (from my understanding)
// Named, really, after CHAT_OOC. Maybe I should have picked a better name. Maybe YOU will pick a better name?
export const chat_looc: FeatureToggle = {
  name: 'Enable LOOC',
  category: 'CHAT',
  component: CheckboxInput,
};

export const looccolor: Feature<string> = {
  name: 'LOOC color',
  category: 'CHAT',
  description: 'The color of your LOOC messages.',
  component: FeatureColorInput,
};
