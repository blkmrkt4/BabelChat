'use client';

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 py-12">
        <div className="bg-white rounded-lg shadow-sm p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Terms of Service</h1>
          <p className="text-gray-500 mb-8">Last Updated: January 3, 2026</p>

          <div className="prose prose-gray max-w-none">
            <p>
              Welcome to Fluenca! These Terms of Service ("Terms") govern your use of the Fluenca mobile application
              and related services (collectively, the "Service") operated by PainKiller Labs ("Company," "we," "us," or "our").
            </p>
            <p>
              By accessing or using our Service, you agree to be bound by these Terms. If you disagree with any part
              of these Terms, you may not access the Service.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">1. Eligibility</h2>
            <p>
              <strong>Age Requirement:</strong> You must be at least 17 years old to use the Service.
              By using the Service, you represent and warrant that you meet this age requirement.
            </p>
            <p>
              <strong>Account Registration:</strong> To use certain features of the Service, you must create an account
              using Sign in with Apple. You agree to provide accurate information, maintain account security, and accept
              responsibility for all activities under your account.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">2. Description of Service</h2>
            <p>
              Fluenca is a language exchange platform that connects users who want to practice languages with native
              speakers and AI-powered conversation partners. The Service includes:
            </p>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Matching System:</strong> Connects users based on language learning goals</li>
              <li><strong>Messaging:</strong> Real-time chat with matched users</li>
              <li><strong>AI Muses:</strong> AI-powered conversation partners for language practice</li>
              <li><strong>Translation:</strong> Message translation between languages</li>
              <li><strong>Grammar Assistance:</strong> Grammar checking and suggestions</li>
              <li><strong>Text-to-Speech:</strong> Audio pronunciation of messages</li>
              <li><strong>Language Lab:</strong> Additional learning tools and exercises</li>
            </ul>

            <h2 className="text-xl font-semibold mt-8 mb-4">3. User Conduct</h2>
            <p>You agree to use the Service only for lawful purposes. You agree not to:</p>
            <ul className="list-disc pl-6 mb-4">
              <li>Use the Service for any illegal purpose</li>
              <li>Harass, bully, intimidate, or threaten other users</li>
              <li>Post hateful, discriminatory, or violent content</li>
              <li>Impersonate any person or entity</li>
              <li>Share sexually explicit or pornographic content</li>
              <li>Solicit personal information from minors</li>
              <li>Engage in unauthorized commercial activities</li>
              <li>Spam other users</li>
              <li>Manipulate or interfere with the Service</li>
            </ul>

            <h2 className="text-xl font-semibold mt-8 mb-4">4. User Content</h2>
            <p>
              You are solely responsible for the content you post, including profile information, photos, and messages.
              Your content must not infringe intellectual property rights, contain false information, include private
              information of others without consent, or violate any laws.
            </p>
            <p>
              We reserve the right to remove any content that violates these Terms without prior notice.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">5. Subscription Services</h2>
            <p>
              The basic Service is available free with certain limitations. Premium and Pro subscriptions provide
              enhanced features and increased usage limits.
            </p>
            <ul className="list-disc pl-6 mb-4">
              <li>Subscriptions are billed through Apple's App Store</li>
              <li>Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period</li>
              <li>You can manage subscriptions in your Apple ID account settings</li>
              <li>Refunds are handled by Apple in accordance with their policies</li>
            </ul>

            <h2 className="text-xl font-semibold mt-8 mb-4">6. AI Features</h2>
            <p>
              AI Muses are artificial intelligence conversation partners. While they aim to provide helpful responses,
              they may occasionally produce inaccurate information and are not substitutes for human interaction or
              professional language instruction.
            </p>
            <p>
              Translation and grammar features are learning aids and should not be relied upon for critical translations.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">7. Intellectual Property</h2>
            <p>
              The Service, including its content, features, and functionality, is owned by PainKiller Labs and is
              protected by intellectual property laws. "Fluenca" and related logos are trademarks of PainKiller Labs.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">8. Disclaimers</h2>
            <p>
              The Service is provided on an "as is" and "as available" basis. We do not guarantee uninterrupted service.
              We are not responsible for the conduct of other users - you interact with others at your own risk.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">9. Limitation of Liability</h2>
            <p>
              To the fullest extent permitted by law, we shall not be liable for any indirect, incidental, special,
              consequential, or punitive damages. Our total liability shall not exceed the greater of the amount you
              paid us in the past 12 months or $100 USD.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">10. Termination</h2>
            <p>
              You may terminate your account at any time using the "Delete Account" feature. We may suspend or terminate
              your account if you violate these Terms or engage in harmful conduct.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">11. Governing Law</h2>
            <p>
              These Terms shall be governed by the laws of the Province of Ontario and the federal laws of Canada
              applicable therein.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">12. Changes to Terms</h2>
            <p>
              We may modify these Terms at any time. We will notify you of material changes by posting the updated
              Terms in the app or sending a notification. Your continued use of the Service after changes become
              effective constitutes acceptance of the revised Terms.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">13. Contact Information</h2>
            <p>For questions about these Terms, please contact us:</p>
            <p className="mt-4">
              <strong>Email:</strong> support@painkillerlabs.com<br />
              <strong>Address:</strong> PainKiller Labs, 8 Parkwood Avenue, Toronto, Ontario, Canada M4V 2W8
            </p>

            <hr className="my-8" />
            <p className="text-gray-600 text-sm">
              By using Fluenca, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
