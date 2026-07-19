const fs = require('fs');
const filePath = 'src/views/reception/ReceptionOrderView.vue';
const lines = fs.readFileSync(filePath, 'utf8').split('\n');

console.log('Total lines:', lines.length);

// Verify boundaries (0-indexed = line - 1)
const checks = [
  [4966, 'FIX: Auto placement', 'L4967'],
  [5636, 'handleRemoveOrCancelItem', 'L5637'],
  [5860, 'Exit Selection Mode', 'L5861'],
  [5901, 'activeMainTab', 'L5902'],
];

for (const [idx, anchor, label] of checks) {
  const line = lines[idx];
  const match = line.includes(anchor);
  console.log(`${label} (idx${idx}): "${line.trim().substring(0, 60)}" | matches "${anchor}": ${match}`);
  if (!match) {
    // Search nearby
    for (let i = Math.max(0, idx - 5); i <= Math.min(lines.length - 1, idx + 5); i++) {
      if (lines[i].includes(anchor)) {
        console.log(`  -> Found "${anchor}" at idx ${i} (L${i + 1})`);
      }
    }
  }
}

// Check what's around the boundaries
console.log('\n--- Block 1 end / Block 2 start ---');
for (let i = 5632; i <= 5640; i++) console.log(`L${i + 1}: ${lines[i]}`);
console.log('...');
for (let i = 5855; i <= 5905; i++) console.log(`L${i + 1}: ${lines[i]}`);
