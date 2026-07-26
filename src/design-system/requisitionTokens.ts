// File: src/design-system/requisitionTokens.ts

export const REQUISITION_COLORS = {
  // Priority Colors
  priority: {
    low: '#4CAF50',
    medium: '#FF9800',
    high: '#F44336',
  },
  
  // Status Colors
  status: {
    pending: '#FF9800',
    approved: '#4CAF50',
    delivered: '#2196F3',
    rejected: '#F44336',
  },

  // Background and borders
  surfaces: {
    cardBg: '#2D2D2D',
    panelBg: '#1A1A1A',
    borderColor: '#404040',
    hoverBorderColor: '#616161',
  },

  // Highlight gradients
  gradients: {
    orange: 'linear-gradient(135deg, #FF9800 0%, #F57C00 100%)',
    green: 'linear-gradient(135deg, #4CAF50 0%, #388E3C 100%)',
    blue: 'linear-gradient(135deg, #2196F3 0%, #1976D2 100%)',
    red: 'linear-gradient(135deg, #F44336 0%, #D32F2F 100%)',
    selectedItem: 'linear-gradient(135deg, #1A1A1A 0%, #2D2517 100%)',
  }
} as const;

export const REQUISITION_TYPOGRAPHY = {
  fontFamily: "'Inter', sans-serif",
  sizes: {
    title: '20px',
    sectionHeader: '16px',
    bodyText: '14px',
    metaText: '13px',
    badgeText: '11px',
  },
  weights: {
    bold: '700',
    semiBold: '600',
    regular: '400',
  }
} as const;

export const REQUISITION_SPACING = {
  padding: {
    modal: '24px',
    card: '16px',
    item: '12px',
  },
  gap: {
    grid: '16px',
    stack: '12px',
    inline: '8px',
  },
  borderRadius: {
    modal: '16px',
    card: '12px',
    button: '8px',
  }
} as const;
