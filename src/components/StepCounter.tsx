import React, {useEffect, useState, useCallback} from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import {HealthKit} from '../native/HealthKit';
import {WidgetManager} from '../native/WidgetUpdater';
import {TotalsView} from './TotalsView';

const CIRCLE_SIZE = Dimensions.get('window').width * 0.7;

type TabView = 'day' | 'totals' | 'settings';

export const StepCounter: React.FC = () => {
  const [steps, setSteps] = useState<number>(0);
  const [stepsGoal, setStepsGoal] = useState<number>(5000);
  const [distance, setDistance] = useState<number>(0);
  const [calories, setCalories] = useState<number>(0);
  const [duration, setDuration] = useState<number>(0);
  const [_isAuthorized, setIsAuthorized] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<TabView>('day');

  const checkAuthorization = useCallback(async () => {
    try {
      const authorized = await HealthKit.requestAuthorization();
      setIsAuthorized(authorized);
      if (authorized) {
        fetchData();
      }
    } catch (error) {
      console.error('Authorization error:', error);
    }
  }, []);

  const fetchData = async () => {
    try {
      const todayData = await HealthKit.getTodayData();
      console.log('todayyyy data', todayData);
      setSteps(todayData.steps || 0);
      setStepsGoal(todayData.stepsGoal || 5000);
      setDistance(todayData.distance || 0);
      setCalories(todayData.calories || 0);
      setDuration(todayData.duration || 0);

      // Try to update widgets, but don't let failures affect the app
      try {
        WidgetManager.reloadStepsWidgets();
      } catch (widgetError) {
        console.log('Widget update failed:', widgetError);
      }
    } catch (error) {
      console.error('Error fetching data:', error);
    }
  };

  useEffect(() => {
    checkAuthorization();
  }, [checkAuthorization]);

  // Add periodic updates
  useEffect(() => {
    const updateInterval = setInterval(() => {
      fetchData();
    }, 5 * 60 * 1000); // Update every 5 minutes

    return () => clearInterval(updateInterval);
  }, []);

  const calculateProgress = () => {
    const progress = steps / stepsGoal;
    return Math.min(progress, 1);
  };

  const renderDayView = () => {
    const progress = calculateProgress();

    return (
      <>
        <View style={styles.progressContainer}>
          <Text style={styles.stepsTitle}>STEPS</Text>
          <View style={styles.circleContainer}>
            <View style={styles.circleBackground} />
            <View style={styles.svgContainer}>
              <View
                style={[
                  styles.progressCircle,
                  {
                    borderWidth: 15,
                    borderColor: '#E5FF44',
                    transform: [{rotate: `${-90 + progress * 360}deg`}],
                  },
                ]}
              />
            </View>
            <View style={styles.stepsContainer}>
              <Text style={styles.stepsCount}>{steps.toLocaleString()}</Text>
              <Text style={styles.stepsGoal}>
                GOAL {stepsGoal.toLocaleString()}
              </Text>
            </View>
          </View>
        </View>
        <View style={styles.bottomStats}>
          <View style={styles.statItem}>
            <Text style={styles.statValue}>{calories.toFixed(0)}</Text>
            <Text style={styles.statLabel}>kcal</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statValue}>{(distance / 1000).toFixed(3)}</Text>
            <Text style={styles.statLabel}>km</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statValue}>{duration.toFixed(0)}</Text>
            <Text style={styles.statLabel}>min</Text>
          </View>
        </View>
      </>
    );
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'totals':
        return <TotalsView />;
      case 'settings':
        return (
          <View style={styles.centeredContainer}>
            <Text style={styles.comingSoonText}>Coming Soon</Text>
          </View>
        );
      default:
        return renderDayView();
    }
  };

  return (
    <View style={styles.container}>
      {renderContent()}
      <View style={styles.tabBar}>
        <TouchableOpacity
          style={styles.tabButton}
          onPress={() => setActiveTab('day')}>
          <Text
            style={[styles.tabText, activeTab === 'day' && styles.activeTab]}>
            day
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.tabButton}
          onPress={() => setActiveTab('totals')}>
          <Text
            style={[
              styles.tabText,
              activeTab === 'totals' && styles.activeTab,
            ]}>
            totals
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.tabButton}
          onPress={() => setActiveTab('settings')}>
          <Text
            style={[
              styles.tabText,
              activeTab === 'settings' && styles.activeTab,
            ]}>
            settings
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#2B2F3E',
    justifyContent: 'space-between',
  },
  centeredContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  comingSoonText: {
    fontSize: 24,
    color: '#8E8E93',
  },
  progressContainer: {
    alignItems: 'center',
    marginTop: 50,
  },
  stepsTitle: {
    fontSize: 24,
    color: '#E5FF44',
    marginBottom: 30,
    fontWeight: '600',
  },
  circleContainer: {
    width: CIRCLE_SIZE,
    height: CIRCLE_SIZE,
    justifyContent: 'center',
    alignItems: 'center',
  },
  circleBackground: {
    position: 'absolute',
    width: CIRCLE_SIZE,
    height: CIRCLE_SIZE,
    borderRadius: CIRCLE_SIZE / 2,
    borderWidth: 15,
    borderColor: '#3E4356',
  },
  svgContainer: {
    width: CIRCLE_SIZE,
    height: CIRCLE_SIZE,
    position: 'absolute',
  },
  progressCircle: {
    width: CIRCLE_SIZE,
    height: CIRCLE_SIZE,
    borderRadius: CIRCLE_SIZE / 2,
  },
  stepsContainer: {
    alignItems: 'center',
  },
  stepsCount: {
    fontSize: 48,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  stepsGoal: {
    fontSize: 16,
    color: '#8E8E93',
    marginTop: 5,
  },
  bottomStats: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 20,
    marginBottom: 20,
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
  tabBar: {
    flexDirection: 'row',
    backgroundColor: '#1C1D26',
    padding: 10,
    justifyContent: 'space-around',
  },
  tabButton: {
    paddingVertical: 10,
    paddingHorizontal: 20,
  },
  tabText: {
    color: '#8E8E93',
    fontSize: 16,
  },
  activeTab: {
    color: '#E5FF44',
  },
});
