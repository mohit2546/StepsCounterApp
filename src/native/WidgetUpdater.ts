import {NativeModules, Platform} from 'react-native';

const {WidgetUpdater} = NativeModules;

interface WidgetUpdaterInterface {
  reloadAllWidgets(): void;
  reloadStepsWidgets(): void;
}

export const WidgetManager: WidgetUpdaterInterface = {
  reloadAllWidgets: () => {
    if (Platform.OS === 'ios' && WidgetUpdater) {
      try {
        WidgetUpdater.reloadAllWidgets();
      } catch (error) {
        console.log('Failed to reload all widgets:', error);
      }
    }
  },
  reloadStepsWidgets: () => {
    if (Platform.OS === 'ios' && WidgetUpdater) {
      try {
        WidgetUpdater.reloadStepsWidgets();
      } catch (error) {
        console.log('Failed to reload steps widgets:', error);
      }
    }
  },
};
