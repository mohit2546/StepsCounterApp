import React, {useState, useEffect, useCallback} from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import {HealthKit} from '../native/HealthKit';

type ViewMode = 'WEEK' | 'MONTH';

interface StatsData {
  total: number;
  calories: number;
  distance: number;
  duration: number;
  average: number;
  dailyData?: {
    steps: {date: string; value: number}[];
  };
}

export const TotalsView: React.FC = () => {
  const [viewMode, setViewMode] = useState<ViewMode>('WEEK');
  const [isLoading, setIsLoading] = useState(true);
  const [data, setData] = useState<StatsData>({
    total: 0,
    calories: 0,
    distance: 0,
    duration: 0,
    average: 0,
  });

  const fetchData = useCallback(async () => {
    try {
      setIsLoading(true);
      const response =
        viewMode === 'WEEK'
          ? await HealthKit.getWeeklyData()
          : await HealthKit.getMonthlyData();

      console.log('response health data', response);

      // Calculate totals from arrays
      const stepsTotal =
        response.steps?.reduce((sum, item) => sum + (item.value || 0), 0) || 0;
      const caloriesTotal =
        response.calories?.reduce((sum, item) => sum + (item.value || 0), 0) ||
        0;
      const distanceTotal =
        response.distance?.reduce((sum, item) => sum + (item.value || 0), 0) ||
        0;

      // Calculate average steps
      const stepsCount = response.steps?.length || 0;
      const stepsAverage = stepsCount > 0 ? stepsTotal / stepsCount : 0;

      setData({
        total: stepsTotal,
        calories: caloriesTotal,
        distance: distanceTotal,
        duration: response.durationTotal || 0,
        average: stepsAverage,
        dailyData: {
          steps: response.steps || [],
        },
      });
    } catch (error) {
      console.error('Error fetching data:', error);
      // Set default values in case of error
      setData({
        total: 0,
        calories: 0,
        distance: 0,
        duration: 0,
        average: 0,
      });
    } finally {
      setIsLoading(false);
    }
  }, [viewMode]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const formatDate = () => {
    const now = new Date();
    if (viewMode === 'MONTH') {
      return now.toLocaleString('default', {
        month: 'long',
        year: 'numeric',
      });
    }
    return 'WEEK';
  };

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#E5FF44" />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => setViewMode('WEEK')}>
          <Text
            style={[
              styles.headerText,
              viewMode === 'WEEK' && styles.activeHeaderText,
            ]}>
            WEEK
          </Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={() => setViewMode('MONTH')}>
          <Text
            style={[
              styles.headerText,
              viewMode === 'MONTH' && styles.activeHeaderText,
            ]}>
            MONTH
          </Text>
        </TouchableOpacity>
      </View>

      <Text style={styles.dateText}>{formatDate()}</Text>

      <View style={styles.calendar}>
        {/* Calendar implementation will go here */}
      </View>

      <Text style={styles.totalText}>{data.total.toLocaleString()}</Text>
      <Text style={styles.totalLabel}>total</Text>

      <View style={styles.stats}>
        <View style={styles.statItem}>
          <Text style={styles.statValue}>{data.calories.toFixed(0)}</Text>
          <Text style={styles.statLabel}>kcal</Text>
        </View>
        <View style={styles.statItem}>
          <Text style={styles.statValue}>
            {(data.distance / 1000).toFixed(3)}
          </Text>
          <Text style={styles.statLabel}>m</Text>
        </View>
        <View style={styles.statItem}>
          <Text style={styles.statValue}>{data.duration.toFixed(0)}</Text>
          <Text style={styles.statLabel}>min</Text>
        </View>
        <View style={styles.statItem}>
          <Text style={styles.statValue}>{data.average.toFixed(0)}</Text>
          <Text style={styles.statLabel}>average</Text>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#2B2F3E',
    padding: 20,
  },
  loadingContainer: {
    flex: 1,
    backgroundColor: '#2B2F3E',
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 40,
    marginBottom: 20,
  },
  headerText: {
    fontSize: 24,
    color: '#8E8E93',
    fontWeight: '600',
  },
  activeHeaderText: {
    color: '#E5FF44',
  },
  dateText: {
    fontSize: 20,
    color: '#E5FF44',
    textAlign: 'center',
    marginBottom: 20,
  },
  calendar: {
    height: 300,
    marginBottom: 20,
  },
  totalText: {
    fontSize: 48,
    color: '#E5FF44',
    textAlign: 'center',
    fontWeight: 'bold',
  },
  totalLabel: {
    fontSize: 16,
    color: '#8E8E93',
    textAlign: 'center',
    marginBottom: 20,
  },
  stats: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 20,
  },
  statItem: {
    alignItems: 'center',
  },
  statValue: {
    fontSize: 24,
    color: '#E5FF44',
    fontWeight: '500',
  },
  statLabel: {
    fontSize: 14,
    color: '#8E8E93',
    marginTop: 5,
  },
});
