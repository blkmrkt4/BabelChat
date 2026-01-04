'use client';

export default function SupportPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 py-12">
        <div className="bg-white rounded-lg shadow-sm p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Support</h1>
          <p className="text-gray-600 mb-8">We're here to help you get the most out of Fluenca.</p>

          <div className="space-y-8">
            {/* Contact Section */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Contact Us</h2>
              <div className="bg-blue-50 rounded-lg p-6">
                <p className="text-gray-700 mb-4">
                  Have a question, feedback, or need help? Reach out to our support team:
                </p>
                <p className="text-lg">
                  <strong>Email:</strong>{' '}
                  <a href="mailto:support@painkillerlabs.com" className="text-blue-600 hover:underline">
                    support@painkillerlabs.com
                  </a>
                </p>
                <p className="text-gray-500 text-sm mt-2">
                  We typically respond within 24-48 hours.
                </p>
              </div>
            </section>

            {/* FAQ Section */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Frequently Asked Questions</h2>
              <div className="space-y-4">
                <div className="border-b pb-4">
                  <h3 className="font-medium text-gray-900">How do I delete my account?</h3>
                  <p className="text-gray-600 mt-1">
                    Go to Settings &gt; Data &amp; Privacy &gt; Delete Account. This will permanently delete
                    your profile, photos, and message history.
                  </p>
                </div>

                <div className="border-b pb-4">
                  <h3 className="font-medium text-gray-900">How do I cancel my subscription?</h3>
                  <p className="text-gray-600 mt-1">
                    Subscriptions are managed through the App Store. Go to your iPhone Settings &gt; Apple ID &gt;
                    Subscriptions &gt; Fluenca to cancel or modify your subscription.
                  </p>
                </div>

                <div className="border-b pb-4">
                  <h3 className="font-medium text-gray-900">How do I report a user?</h3>
                  <p className="text-gray-600 mt-1">
                    On any user's profile or in a chat, tap the menu icon and select "Report." You can also
                    email us directly at support@painkillerlabs.com with details.
                  </p>
                </div>

                <div className="border-b pb-4">
                  <h3 className="font-medium text-gray-900">What languages are supported?</h3>
                  <p className="text-gray-600 mt-1">
                    Fluenca supports 21 languages: English, Spanish, French, German, Portuguese (Brazilian &amp; European),
                    Italian, Japanese, Korean, Mandarin Chinese, Dutch, Russian, Polish, Hindi, Indonesian, Filipino,
                    Swedish, Danish, Finnish, Norwegian, and Arabic.
                  </p>
                </div>

                <div className="border-b pb-4">
                  <h3 className="font-medium text-gray-900">What are AI Muses?</h3>
                  <p className="text-gray-600 mt-1">
                    AI Muses are AI-powered language tutors available 24/7 for practice when human partners aren't
                    available. They can hold conversations in your target language and help you practice.
                  </p>
                </div>

                <div className="border-b pb-4">
                  <h3 className="font-medium text-gray-900">How do I use translation features?</h3>
                  <p className="text-gray-600 mt-1">
                    In any chat, swipe right on a message to see instant translation. Swipe left to see grammar
                    explanations and corrections.
                  </p>
                </div>

                <div className="pb-4">
                  <h3 className="font-medium text-gray-900">What is Strictly Platonic mode?</h3>
                  <p className="text-gray-600 mt-1">
                    Strictly Platonic mode ensures you only match with other users who also have this setting enabled,
                    creating a focused language learning environment without romantic elements.
                  </p>
                </div>
              </div>
            </section>

            {/* Company Info */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-4">About Us</h2>
              <div className="bg-gray-50 rounded-lg p-6">
                <p className="text-gray-700 mb-4">
                  Fluenca is developed by PainKiller Labs, based in Toronto, Canada.
                </p>
                <p className="text-gray-600">
                  <strong>PainKiller Labs</strong><br />
                  8 Parkwood Avenue<br />
                  Toronto, Ontario, Canada<br />
                  M4V 2W8
                </p>
              </div>
            </section>

            {/* Legal Links */}
            <section>
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Legal</h2>
              <div className="flex gap-4">
                <a href="/privacy" className="text-blue-600 hover:underline">Privacy Policy</a>
                <a href="/terms" className="text-blue-600 hover:underline">Terms of Service</a>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
}
