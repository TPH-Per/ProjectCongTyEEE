const lang = 'ja';
const dict = {
  vi: { 'reception.dashboard.shift_overview': 'Ca làm việc Tổng quan' },
  en: { 'reception.dashboard.shift_overview': 'Shift overview' },
  ja: { 'reception.dashboard.shift_overview': '概要' }
};

const key = 'reception.dashboard.shift_overview';
const val = dict[lang]?.[key] ?? dict['vi']?.[key] ?? key;
console.log('Value is: ' + val);
