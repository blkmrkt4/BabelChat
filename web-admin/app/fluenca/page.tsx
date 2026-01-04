'use client';

export default function MarketingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-900 via-purple-900 to-pink-800">
      {/* Hero Section */}
      <div className="max-w-6xl mx-auto px-4 py-16">
        <div className="text-center">
          <h1 className="text-5xl md:text-7xl font-bold text-white mb-6">
            Fluenca
          </h1>
          <p className="text-xl md:text-2xl text-purple-200 mb-4">
            Science says your brain learns faster when it cares
          </p>
          <p className="text-lg text-purple-300 mb-12">
            Speaking like a local is the fastest path to fluency
          </p>

          {/* App Store Badge */}
          <a href="https://apps.apple.com/app/fluenca" className="inline-block">
            <img
              src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83"
              alt="Download on the App Store"
              className="h-14"
            />
          </a>
        </div>
      </div>

      {/* Features Section */}
      <div className="bg-white/10 backdrop-blur-sm py-16">
        <div className="max-w-6xl mx-auto px-4">
          <h2 className="text-3xl font-bold text-white text-center mb-12">
            Learn languages through real connections
          </h2>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-white/10 rounded-xl p-6 text-center">
              <div className="text-4xl mb-4">🎯</div>
              <h3 className="text-xl font-semibold text-white mb-2">Smart Matching</h3>
              <p className="text-purple-200">
                Find partners who speak your target language and share your interests
              </p>
            </div>

            <div className="bg-white/10 rounded-xl p-6 text-center">
              <div className="text-4xl mb-4">💬</div>
              <h3 className="text-xl font-semibold text-white mb-2">Built-in Translation</h3>
              <p className="text-purple-200">
                Swipe right on any message for instant translation, left for grammar help
              </p>
            </div>

            <div className="bg-white/10 rounded-xl p-6 text-center">
              <div className="text-4xl mb-4">🤖</div>
              <h3 className="text-xl font-semibold text-white mb-2">AI Language Muses</h3>
              <p className="text-purple-200">
                Practice 24/7 with AI tutors when human partners aren't available
              </p>
            </div>

            <div className="bg-white/10 rounded-xl p-6 text-center">
              <div className="text-4xl mb-4">📊</div>
              <h3 className="text-xl font-semibold text-white mb-2">Language Lab</h3>
              <p className="text-purple-200">
                Track your progress and see how you're improving over time
              </p>
            </div>

            <div className="bg-white/10 rounded-xl p-6 text-center">
              <div className="text-4xl mb-4">🔊</div>
              <h3 className="text-xl font-semibold text-white mb-2">Text-to-Speech</h3>
              <p className="text-purple-200">
                Hear native pronunciation for any message with one tap
              </p>
            </div>

            <div className="bg-white/10 rounded-xl p-6 text-center">
              <div className="text-4xl mb-4">🤝</div>
              <h3 className="text-xl font-semibold text-white mb-2">Strictly Platonic</h3>
              <p className="text-purple-200">
                Optional mode for learners who want friendship-focused practice
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Languages Section */}
      <div className="py-16">
        <div className="max-w-6xl mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold text-white mb-8">
            21 Languages Supported
          </h2>
          <p className="text-purple-200 text-lg max-w-3xl mx-auto">
            English, Spanish, French, German, Portuguese, Italian, Japanese, Korean,
            Mandarin Chinese, Dutch, Russian, Polish, Hindi, Indonesian, Filipino,
            Swedish, Danish, Finnish, Norwegian, and Arabic
          </p>
        </div>
      </div>

      {/* CTA Section */}
      <div className="bg-white/5 py-16">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold text-white mb-4">
            Start learning for free
          </h2>
          <p className="text-purple-200 text-lg mb-8">
            Your brain learns faster when it cares about who you're talking to.
          </p>
          <a href="https://apps.apple.com/app/fluenca" className="inline-block">
            <img
              src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83"
              alt="Download on the App Store"
              className="h-14"
            />
          </a>
        </div>
      </div>

      {/* Footer */}
      <footer className="py-8 border-t border-white/10">
        <div className="max-w-6xl mx-auto px-4">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <p className="text-purple-300 text-sm">
              © 2026 PainKiller Labs. All rights reserved.
            </p>
            <div className="flex gap-6">
              <a href="/privacy" className="text-purple-300 hover:text-white text-sm">
                Privacy Policy
              </a>
              <a href="/terms" className="text-purple-300 hover:text-white text-sm">
                Terms of Service
              </a>
              <a href="/support" className="text-purple-300 hover:text-white text-sm">
                Support
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
