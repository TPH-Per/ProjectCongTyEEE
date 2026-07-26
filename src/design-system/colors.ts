// File: src/design-system/colors.ts

export const BUTTON_COLORS = {
  // Primary - Navigation chính
  primary: {
    base: '#2196F3',
    dark: '#1976D2',
    light: '#64B5F6',
    gradient: 'linear-gradient(135deg, #2196F3 0%, #1976D2 100%)'
  },
  
  // Secondary - Expo QC
  secondary: {
    base: '#9C27B0',
    dark: '#7B1FA2',
    light: '#BA68C8',
    gradient: 'linear-gradient(135deg, #9C27B0 0%, #7B1FA2 100%)'
  },
  
  // Warning - Yêu cầu Vỉ/Than
  warning: {
    base: '#FF9800',
    dark: '#F57C00',
    light: '#FFB74D',
    gradient: 'linear-gradient(135deg, #FF9800 0%, #F57C00 100%)'
  },
  
  // Success - HACCP
  success: {
    base: '#4CAF50',
    dark: '#388E3C',
    light: '#81C784',
    gradient: 'linear-gradient(135deg, #4CAF50 0%, #388E3C 100%)'
  },
  
  // Danger - 86'd
  danger: {
    base: '#F44336',
    dark: '#D32F2F',
    light: '#E57373',
    gradient: 'linear-gradient(135deg, #F44336 0%, #D32F2F 100%)'
  },
  
  // Neutral - Ẩn Panel
  neutral: {
    base: '#616161',
    dark: '#424242',
    light: '#9E9E9E',
    gradient: 'linear-gradient(135deg, #616161 0%, #424242 100%)'
  },
  
  // Urgent - Cảnh báo trễ
  urgent: {
    base: '#C62828',
    dark: '#B71C1C',
    light: '#E57373',
    gradient: 'linear-gradient(135deg, #C62828 0%, #B71C1C 100%)'
  }
} as const;

export const BADGE_COLORS = {
  default: '#F44336',
  warning: '#FF5722',
  info: '#2196F3',
  success: '#4CAF50'
} as const;
