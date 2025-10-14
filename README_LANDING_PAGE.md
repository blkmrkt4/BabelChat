# Landing Page Setup Instructions

## Adding the Background Animation

To add the animated background from Leonardo AI to your landing page:

1. **Download the GIF/Video**:
   - Visit the Leonardo AI generation page
   - Download the animation as a GIF file
   - Name it: `language_animation.gif`

2. **Add to Xcode Project**:
   - Open your project in Xcode
   - Right-click on the `LangChat` folder in the project navigator
   - Select "Add Files to LangChat..."
   - Navigate to your downloaded `language_animation.gif`
   - Make sure "Copy items if needed" is checked
   - Ensure "LangChat" target is selected
   - Click "Add"

3. **Alternative: Add to Assets Catalog** (for static image):
   - Open `Assets.xcassets` in Xcode
   - Drag the image file into the assets catalog
   - Name it "language_background"

## Current Implementation

The landing page (`LandingViewController.swift`) is set up with:

1. **GIF Support**: Automatically loads and displays animated GIFs
2. **Fallback Options**:
   - First tries to load `language_animation.gif`
   - Falls back to static `language_background` image
   - Final fallback: Animated gradient background

3. **UI Elements**:
   - App name "LangChat" at top
   - "Connect Through Language" tagline
   - Two buttons: "Create Account" and "Sign In"
   - Dark overlay for text visibility

## Testing

1. Build and run the app
2. The landing page should appear first (unless user is signed in)
3. Verify the background animation is playing
4. Test both buttons (currently show placeholder alerts)

## Customization

You can adjust these properties in `LandingViewController.swift`:
- Overlay opacity: Line 54 (currently 0.5)
- Button colors and styles: Lines 77-95
- Text colors and fonts: Lines 58-68
- Layout constraints: Lines 108-139