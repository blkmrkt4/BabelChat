'use client';

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 py-12">
        <div className="bg-white rounded-lg shadow-sm p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Privacy Policy</h1>
          <p className="text-gray-500 mb-8">Last Updated: January 3, 2026</p>

          <div className="prose prose-gray max-w-none">
            <p>
              PainKiller Labs ("Company," "we," "us," or "our") operates the Fluenca mobile application (the "App").
              This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our App.
            </p>
            <p>
              Please read this Privacy Policy carefully. By using the App, you agree to the collection and use of
              information in accordance with this policy.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">1. Information We Collect</h2>

            <h3 className="text-lg font-medium mt-6 mb-3">1.1 Information You Provide</h3>
            <p><strong>Account Information</strong></p>
            <ul className="list-disc pl-6 mb-4">
              <li>Name (first and last)</li>
              <li>Email address (via Sign in with Apple)</li>
              <li>Username</li>
              <li>Profile photo(s)</li>
              <li>Date of birth</li>
              <li>Gender</li>
            </ul>

            <p><strong>Profile Information</strong></p>
            <ul className="list-disc pl-6 mb-4">
              <li>Bio/description</li>
              <li>Native language</li>
              <li>Languages you're learning</li>
              <li>Language proficiency levels</li>
              <li>Location (city)</li>
              <li>Language learning preferences</li>
            </ul>

            <p><strong>User Content</strong></p>
            <ul className="list-disc pl-6 mb-4">
              <li>Messages sent to other users</li>
              <li>Messages sent to AI Muses</li>
              <li>Feedback and support requests</li>
            </ul>

            <h3 className="text-lg font-medium mt-6 mb-3">1.2 Information Collected Automatically</h3>
            <p><strong>Device Information</strong></p>
            <ul className="list-disc pl-6 mb-4">
              <li>Device type and model</li>
              <li>Operating system version</li>
              <li>Unique device identifiers</li>
              <li>App version</li>
            </ul>

            <p><strong>Usage Information</strong></p>
            <ul className="list-disc pl-6 mb-4">
              <li>Features used and interactions</li>
              <li>Time and duration of sessions</li>
              <li>Messages sent and received (count)</li>
              <li>Matches and connections made</li>
            </ul>

            <h2 className="text-xl font-semibold mt-8 mb-4">2. How We Use Your Information</h2>

            <h3 className="text-lg font-medium mt-6 mb-3">2.1 Provide and Improve the Service</h3>
            <ul className="list-disc pl-6 mb-4">
              <li>Create and manage your account</li>
              <li>Match you with other users based on language preferences</li>
              <li>Enable messaging and communication features</li>
              <li>Provide AI-powered features (translations, grammar checking, AI Muses)</li>
              <li>Process text-to-speech requests</li>
              <li>Respond to your requests and support inquiries</li>
              <li>Analyze usage to improve the App</li>
            </ul>

            <h3 className="text-lg font-medium mt-6 mb-3">2.2 Safety and Security</h3>
            <ul className="list-disc pl-6 mb-4">
              <li>Detect and prevent fraud, abuse, and violations of our Terms</li>
              <li>Verify user identity</li>
              <li>Protect the safety of our users and the integrity of the Service</li>
            </ul>

            <h2 className="text-xl font-semibold mt-8 mb-4">3. How We Share Your Information</h2>

            <h3 className="text-lg font-medium mt-6 mb-3">3.1 With Other Users</h3>
            <p>When you use the App, certain information is visible to other users:</p>
            <ul className="list-disc pl-6 mb-4">
              <li>Profile information (name, photo, bio, languages)</li>
              <li>Location (city, if enabled)</li>
              <li>Online status</li>
              <li>Messages you send to them</li>
            </ul>

            <h3 className="text-lg font-medium mt-6 mb-3">3.2 With Service Providers</h3>
            <p>We share information with third-party service providers who assist us in operating the App:</p>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Supabase:</strong> Database and authentication - Account data, messages, profile info</li>
              <li><strong>Google Cloud:</strong> Text-to-speech services - Message text for audio generation</li>
              <li><strong>OpenRouter/AI Providers:</strong> Translation and grammar - Message text for processing</li>
              <li><strong>Apple:</strong> Authentication, payments - Apple ID, subscription data</li>
            </ul>

            <h2 className="text-xl font-semibold mt-8 mb-4">4. Data Storage and Security</h2>
            <p>Your data is stored on secure servers. We implement appropriate security measures including:</p>
            <ul className="list-disc pl-6 mb-4">
              <li>Encryption of data in transit (TLS/SSL)</li>
              <li>Encryption of data at rest</li>
              <li>Secure authentication via Sign in with Apple</li>
              <li>Regular security assessments</li>
              <li>Access controls for employee access to data</li>
            </ul>

            <h2 className="text-xl font-semibold mt-8 mb-4">5. Your Rights and Choices</h2>
            <ul className="list-disc pl-6 mb-4">
              <li><strong>Access and Update:</strong> You can access and update your profile information at any time through the App settings.</li>
              <li><strong>Delete Your Account:</strong> You can delete your account using the "Delete Account" feature in Settings &gt; Data &amp; Privacy.</li>
              <li><strong>Data Export:</strong> You can request a copy of your data by contacting us at support@painkillerlabs.com.</li>
              <li><strong>Location Settings:</strong> You can control location sharing in your device's Settings or in the App.</li>
            </ul>

            <h2 className="text-xl font-semibold mt-8 mb-4">6. Children's Privacy</h2>
            <p>
              The App is intended for users who are at least 17 years old. We do not knowingly collect information
              from children under 17. If we discover that we have collected information from a child under 17,
              we will delete it promptly.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">7. Changes to This Privacy Policy</h2>
            <p>
              We may update this Privacy Policy from time to time. We will notify you of material changes by
              posting the updated policy in the App or sending a notification. The "Last Updated" date at the
              top indicates when the policy was last revised.
            </p>

            <h2 className="text-xl font-semibold mt-8 mb-4">8. Contact Us</h2>
            <p>If you have questions about this Privacy Policy or our privacy practices, please contact us:</p>
            <p className="mt-4">
              <strong>Email:</strong> support@painkillerlabs.com<br />
              <strong>Address:</strong> PainKiller Labs, 8 Parkwood Avenue, Toronto, Ontario, Canada M4V 2W8
            </p>

            <hr className="my-8" />
            <p className="text-gray-600 text-sm">
              By using Fluenca, you acknowledge that you have read and understood this Privacy Policy.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
