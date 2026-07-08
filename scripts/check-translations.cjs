const fs = require('fs')
const path = require('path')

function extractTranslationKeys(content) {
  const regex = /t\(['"]([^'"]+)['"]\)/g
  const keys = []
  let match
  
  while ((match = regex.exec(content)) !== null) {
    keys.push(match[1])
  }
  
  return keys
}

function getAllVueFiles(dir) {
  const files = []
  const entries = fs.readdirSync(dir)
  
  entries.forEach(entry => {
    const fullPath = path.join(dir, entry)
    const stat = fs.statSync(fullPath)
    
    if (stat.isDirectory()) {
      if (entry !== 'node_modules' && entry !== '.git') {
        files.push(...getAllVueFiles(fullPath))
      }
    } else if (entry.endsWith('.vue') || entry.endsWith('.ts')) {
      files.push(fullPath)
    }
  })
  
  return files
}

// Main
const srcDir = path.join(__dirname, '../src')
const files = getAllVueFiles(srcDir)
const allKeys = new Set()

files.forEach(file => {
  const content = fs.readFileSync(file, 'utf8')
  const keys = extractTranslationKeys(content)
  keys.forEach(key => allKeys.add(key))
})

console.log(`Found ${allKeys.size} translation keys in codebase.`)

// Load vi.ts translation file
const viTsPath = path.join(__dirname, '../src/locales/vi.ts')
let viTranslations = {}
if (fs.existsSync(viTsPath)) {
  const content = fs.readFileSync(viTsPath, 'utf8')
  const jsContent = content.replace('export default', 'module.exports =')
  const tempFilePath = path.join(__dirname, '../scratch/temp-vi.cjs')
  
  fs.mkdirSync(path.dirname(tempFilePath), { recursive: true })
  fs.writeFileSync(tempFilePath, jsContent, 'utf8')
  
  try {
    viTranslations = require(tempFilePath)
  } catch (err) {
    console.error('Failed to load translations from vi.ts:', err)
  } finally {
    if (fs.existsSync(tempFilePath)) {
      fs.unlinkSync(tempFilePath)
    }
  }
} else {
  console.warn('Warning: src/locales/vi.ts not found.')
}

function getNestedValue(obj, keyPath) {
  if (obj && Object.prototype.hasOwnProperty.call(obj, keyPath)) {
    return obj[keyPath]
  }
  return keyPath.split('.').reduce((o, p) => o && o[p], obj)
}

const missingKeys = []
allKeys.forEach(key => {
  if (key.includes('${') || key.includes('`')) {
    return
  }
  if (!getNestedValue(viTranslations, key)) {
    missingKeys.push(key)
  }
})

if (missingKeys.length > 0) {
  console.log('\n❌ Missing translations in vi.ts:')
  missingKeys.forEach(key => {
    console.log(`  "${key}": "${key.replace(/\./g, ' ')}"`)
  })
} else {
  console.log('\n✅ All translations found!')
}
