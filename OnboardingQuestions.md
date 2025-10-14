# LangChat Onboarding Questions Guide

## Currently Implemented ✅
1. **Phone Number** - Account security & verification
2. **Phone Verification** - SMS code confirmation
3. **Name** - How users appear to partners
4. **Email** - Account recovery
5. **Birth Year** - Age-appropriate matching (13+ requirement)
6. **Location** - City & Country with privacy toggle
7. **Native Language** - Primary fluent language

## Language-Specific Questions to Implement 🌍

### 8. Learning Languages (Multi-select)
- **Title**: "Which languages are you learning?"
- **Subtitle**: "Select all that interest you (up to 5)"
- **UI**: Multi-select list with search
- **Purpose**: Core matching criteria

### 9. Language Proficiency
- **Title**: "How well do you speak [Language]?"
- **For each selected language**:
  - Beginner (A1-A2): "I know basic phrases"
  - Intermediate (B1-B2): "I can have simple conversations"
  - Advanced (C1-C2): "I'm comfortable with complex topics"
- **UI**: Cards for each language with level selection

### 10. Learning Goals
- **Title**: "What are your language learning goals?"
- **Multi-select options**:
  - 💬 Conversational fluency
  - ✈️ Travel preparation
  - 💼 Business/Professional
  - 📚 Academic study
  - 🎭 Cultural understanding
  - 👨‍👩‍👧 Family/Heritage connection
  - 🎮 Media consumption (movies, games, books)
  - 💑 Dating/Relationships

### 11. Practice Preferences
- **Title**: "How do you prefer to practice?"
- **Multi-select**:
  - 🎥 Video calls
  - 🎤 Voice calls
  - 💬 Text messaging
  - ✍️ Written corrections
  - 🎯 Structured lessons
  - 🗣️ Casual conversation

### 12. Availability
- **Title**: "When are you usually available?"
- **Options**:
  - Morning (6am - 12pm)
  - Afternoon (12pm - 5pm)
  - Evening (5pm - 10pm)
  - Night (10pm - 2am)
  - Weekdays
  - Weekends
- **Note**: "Times shown in your timezone"

### 13. Conversation Topics
- **Title**: "What do you enjoy talking about?"
- **Categories** (select up to 10):
  - 🎬 Movies & TV
  - 🎵 Music
  - 🍳 Food & Cooking
  - ⚽ Sports & Fitness
  - 🎮 Gaming
  - 📚 Books & Literature
  - 💻 Technology
  - 🎨 Art & Design
  - 🌍 Travel
  - 📰 Current Events
  - 💼 Career & Business
  - 🔬 Science
  - 🌱 Environment
  - 👗 Fashion
  - 🐕 Pets & Animals
  - 📷 Photography
  - 🧘 Wellness & Mindfulness
  - 📈 Finance & Investing

## Profile Building Questions 📸

### 14. Profile Photos
- **Title**: "Add photos of yourself"
- **Requirements**:
  - Minimum 3 photos
  - Maximum 6 photos
  - Clear face in at least 1 photo
- **Tips shown**:
  - "Show your personality"
  - "Include photos of you doing activities you enjoy"
  - "Smile - you're here to make friends!"

### 15. About Me / Bio
- **Title**: "Tell us about yourself"
- **Prompts** (optional guided questions):
  - "What's your language learning story?"
  - "What motivates you to learn languages?"
  - "Fun fact about yourself"
- **Character limit**: 500

### 16. Voice Introduction (Optional)
- **Title**: "Record a voice greeting"
- **Subtitle**: "Say hello in your native language (30 seconds max)"
- **Purpose**: Helps partners hear pronunciation/accent
- **Skip option**: Available

## Matching Preferences 🤝

### 17. Partner Preferences
- **Title**: "Who would you like to practice with?"
- **Options**:
  - Age range (e.g., 18-25, 26-35, etc.)
  - Gender preference (All, Same, Different)
  - Language level (Similar to mine, More advanced, Any)
  - Location preference (Same country, Same continent, Anywhere)

### 18. Learning Style Match
- **Title**: "What kind of language partner are you?"
- **Single choice**:
  - 👩‍🏫 **Teacher Type**: "I love helping others learn my language"
  - 🎓 **Student Type**: "I'm focused on learning new languages"
  - 🤝 **Exchange Type**: "Equal give and take"
  - 🎯 **Goal-Oriented**: "Structured practice with clear objectives"
  - 😄 **Casual Learner**: "Fun conversations without pressure"

## App Settings & Permissions 🔔

### 19. Notifications
- **Title**: "Stay connected with your language partners"
- **Options**:
  - New matches
  - Messages
  - Practice reminders
  - Weekly progress
- **System permission request**

### 20. Profile Visibility
- **Title**: "Who can see your profile?"
- **Options**:
  - Everyone learning my languages
  - Only my matches
  - Custom (by language/location)

## Optional Premium Upsell 💎

### 21. Premium Features Introduction
- **Title**: "Unlock your full potential"
- **Features shown**:
  - Unlimited likes
  - See who liked you
  - Advanced filters
  - Translation assistance
  - Priority matching
- **Options**: "Start Free Trial" / "Maybe Later"

## Completion Screen 🎉

### 22. Welcome to LangChat!
- **Title**: "You're all set!"
- **Message**: "Start connecting with language partners from around the world"
- **CTA**: "Start Exploring"
- **Tips shown**:
  - "Be patient and kind"
  - "Practice makes perfect"
  - "Respect cultural differences"

## Best Practices for Implementation

1. **Progressive Disclosure**: Don't overwhelm - mark some questions as optional
2. **Smart Defaults**: Pre-select common options
3. **Skip Options**: Allow skipping non-essential questions
4. **Progress Indicator**: Show clear progress through onboarding
5. **Save & Resume**: Save progress in case user exits
6. **Validation**: Clear error messages and input validation
7. **Accessibility**: Support VoiceOver and Dynamic Type
8. **Localization**: Translate onboarding for major languages

## Data Privacy Considerations

- Clearly indicate what information is public vs private
- Explain how location data is used
- Provide links to privacy policy and terms
- GDPR compliance for EU users
- Age verification (13+ or 16+ depending on region)