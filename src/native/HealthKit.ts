import {NativeModules} from 'react-native';

const {HealthKitManager} = NativeModules;

interface HealthData {
  date: string;
  value: number;
}

interface TodayData {
  steps: number;
  stepsGoal: number;
  distance: number;
  calories: number;
  duration: number;
}

interface PeriodData {
  steps: HealthData[];
  distance: HealthData[];
  calories: HealthData[];
  duration: HealthData[];
  stepsTotal: number;
  stepsAverage: number;
  distanceTotal: number;
  distanceAverage: number;
  caloriesTotal: number;
  caloriesAverage: number;
  durationTotal: number;
  durationAverage: number;
}

interface HealthKitInterface {
  requestAuthorization(): Promise<boolean>;
  getTodayData(): Promise<TodayData>;
  getWeeklyData(): Promise<PeriodData>;
  getMonthlyData(): Promise<PeriodData>;
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
