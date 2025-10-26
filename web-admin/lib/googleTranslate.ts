// Google Translate API integration
export async function translateWithGoogle(
  text: string,
  sourceLang: string,
  targetLang: string
): Promise<string> {
  try {
    // Using free Google Translate API endpoint
    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${sourceLang}&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`

    const response = await fetch(url)

    if (!response.ok) {
      throw new Error(`Google Translate API error: ${response.statusText}`)
    }

    const data = await response.json()

    // Extract translated text from response
    if (data && data[0] && Array.isArray(data[0])) {
      return data[0].map((item: any[]) => item[0]).join('')
    }

    throw new Error('Unexpected response format from Google Translate')
  } catch (error) {
    console.error('Error with Google Translate:', error)
    throw error
  }
}

// Language code mapping for Google Translate
export const GOOGLE_LANG_CODES: Record<string, string> = {
  'English': 'en',
  'Spanish': 'es',
  'French': 'fr',
  'German': 'de',
  'Italian': 'it',
  'Portuguese': 'pt',
  'Portuguese (Brazilian)': 'pt-BR',
  'Chinese': 'zh-CN',
  'Japanese': 'ja',
  'Korean': 'ko',
  'Arabic': 'ar',
  'Russian': 'ru',
  'Hindi': 'hi',
  'Dutch': 'nl',
  'Swedish': 'sv',
  'Norwegian': 'no',
  'Danish': 'da',
  'Finnish': 'fi',
  'Polish': 'pl',
  'Turkish': 'tr',
  'Greek': 'el',
  'Hebrew': 'he',
  'Thai': 'th',
  'Vietnamese': 'vi',
  'Indonesian': 'id'
}
