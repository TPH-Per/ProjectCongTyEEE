import { ref } from 'vue'
import Tesseract from 'tesseract.js'

export function useOCR() {
  const isScanning = ref(false)
  const ocrProgress = ref(0)
  const ocrWords = ref<Tesseract.Word[]>([])

  const scanImage = async (file: File) => {
    isScanning.value = true
    ocrProgress.value = 0
    ocrWords.value = []
    
    try {
      const worker = await Tesseract.createWorker('vie', 1, {
        logger: (m: any) => {
          if (m.status === 'recognizing text') {
            ocrProgress.value = Math.round(m.progress * 100)
          }
        }
      })
      const ret = await worker.recognize(file)
      ocrWords.value = (ret.data as any).words || []
      await worker.terminate()

      const text = ret.data.text
      const autoFillData = {
        receiptCode: '',
      }
      
      // Auto-guess receipt code: looks for "Số", "Mã", "HD", "No" followed by alphanumeric
      const codeMatch = text.match(/(?:Số|Mã|HD|No)[^\w]*([A-Z0-9-]{4,15})/i)
      if (codeMatch) {
         autoFillData.receiptCode = codeMatch[1].trim()
      }

      return autoFillData
    } catch (err) {
      console.error("OCR Error:", err)
      throw err
    } finally {
      isScanning.value = false
    }
  }

  return { isScanning, ocrProgress, ocrWords, scanImage }
}
