import {NativeModules} from 'react-native';

const {HealthKitManager} = NativeModules;

interface HealthData {
  date: string;
  value: number;
}

interface HealthKitInterface {
  requestAuthorization(): Promise<boolean>;
  getTodayData(): Promise<{
    steps: number;
    distance: number;
    calories: number;
  }>;
  getWeeklyData(): Promise<{
    steps: HealthData[];
    distance: HealthData[];
    calories: HealthData[];
  }>;
  getMonthlyData(): Promise<{
    steps: HealthData[];
    distance: HealthData[];
    calories: HealthData[];
  }>;
}

export const HealthKit: HealthKitInterface = {
  requestAuthorization: async () => {
    try {
      return await HealthKitManager.requestAuthorization();
    } catch (error) {
      console.error('HealthKit authorization error:', error);
      throw error;
    }
  },

  getTodayData: async () => {
    try {
      return await HealthKitManager.getTodayData();
    } catch (error) {
      console.error("Error fetching today's data:", error);
      throw error;
    }
  },

  getWeeklyData: async () => {
    try {
      return await HealthKitManager.getWeeklyData();
    } catch (error) {
      console.error('Error fetching weekly data:', error);
      throw error;
    }
  },

  getMonthlyData: async () => {
    try {
      return await HealthKitManager.getMonthlyData();
    } catch (error) {
      console.error('Error fetching monthly data:', error);
      throw error;
    }
  },
};
