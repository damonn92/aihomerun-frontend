import { useState } from 'react'
import UploadPage from './pages/UploadPage'
import ResultPage from './pages/ResultPage'

export default function App() {
  const [result, setResult] = useState(null)

  return (
    <div className="app-shell">
      {result
        ? <ResultPage result={result} onReset={() => setResult(null)} />
        : <UploadPage onResult={setResult} />
      }
    </div>
  )
}
