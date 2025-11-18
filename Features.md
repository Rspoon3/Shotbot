# Features

This document tracks the major features of Shotbot, an iOS, macOS, and visionOS app for framing screenshots with device mockups.

## Core Screenshot Framing

### Individual Screenshot Framing
Add device frames around single screenshots for multiple device types including iPhone, iPad, Mac, Apple Watch, and Vision Pro.

### Combined Screenshot Creation
Horizontally stitch multiple framed screenshots together into a single composite image for presentations and marketing materials.

### Image Quality Control
Five quality levels (Original, High, Medium, Low, Poor) to optimize file size versus visual quality for different use cases.

### Device Type Selection
Support for multiple device types with customizable frame overlays matching the latest Apple devices.

## Screenshot Import & Processing

### Photo Picker Integration
Select screenshots from the device's photo library with full permission handling.

### File Picker Support
Import screenshots directly from the Files app for flexible file management.

### Drag & Drop
Direct drag-and-drop support for images across iOS, macOS, and visionOS.

### Widget Deep Links
Open and frame specific screenshots directly from home screen widgets.

### Multiple Image Handling
Process and frame multiple screenshots in a single operation with batch processing capabilities.

## View Modes

### Individual Mode
View and manage single framed screenshots with dedicated UI optimized for single images.

### Combined Mode
View horizontally combined multi-screenshot composites with preview and export options.

### Grid/Tabbed Views
Toggle between grid layout and tabbed navigation for multiple images to suit different workflows.

### Image Reversal
Reorder and reverse screenshot sequence before combining for flexible layout control.

## Auto Actions (Granular Control)

### Auto-Save to Photos
Automatically save framed screenshots to the photo library with granular options:
- None: No auto-saving
- Individual Only: Save only individual framed images
- Combined Only: Save only the combined composite
- All: Save both individual and combined images

### Auto-Save to iCloud Files
Automatically save framed screenshots to iCloud Documents folder with the same granular control options.

### Auto-Copy to Clipboard
Automatically copy results to the system pasteboard with options for:
- None: No auto-copying
- Individual Only: Copy all individual framed images
- Combined Only: Copy the combined composite
- All: Copy both combined and all individual images

### Auto-Delete Original Screenshots
Option to automatically delete source screenshots after processing to keep photo library clean.

## Widgets

### Latest Screenshot Widget
Quick-access widget showing and framing the most recent screenshot from the photo library.

### Multiple Screenshots Widget
Display multiple screenshot options in a compact widget for quick selection.

### Framed Screenshots Control Widget
Configurable widget for screenshot management with refresh and delete capabilities.

### Widget Intents
Deep linking support to frame specific photos directly from widgets.

### Multiple Sizes
Support for small and large widget families across iOS, macOS, and visionOS.

## Share Extension

### Share Sheet Integration
Frame screenshots directly from the share menu in any app without leaving the current context.

### Quick Processing
Fast device framing through UIKit-based action extension for immediate results.

## Shortcuts Integration

### App Intents
Create framed screenshots via Shortcuts automation for advanced workflows.

### Image Quality Selection
Choose quality level directly within shortcuts for automated processing.

### Create Framed Screenshots Intent
Dedicated intent for shortcut automation with full parameter support.

## Subscription & Monetization

### Free Tier
Limited screenshot frames per day for casual users to try the app.

### Subscription Options
Unlimited framing with RevenueCat integration for seamless subscription management.

### Referral System
Users can enter referral codes to earn credits and unlock extra screenshots.

### Credit System
Earn credits through referrals to unlock additional screenshots without subscription.

### In-App Purchase View
Beautiful subscription purchase interface with clear value proposition.

## Referral Program

### Referral Codes
Users can earn and spend credits through a referral system to unlock features.

### Notification Support
Push notifications for referral updates and credit balance changes.

### Credit Balance Tracking
Display credit balance in settings tab badge for visibility.

### Backend Integration
ReferralService API integration for referral management and credit tracking.

## Cross-Promotion

### Photo Ranker Integration
Promotional banner for Photo Ranker app with smart display logic.

### Frequency Control
Show cross-promotion banner maximum 3 times, once per week after referral banner completes.

### Settings Integration
Photo Ranker entry in settings with app icon and App Store link.

## Settings & Customization

### Image Quality Selection
Choose default compression level for all framed screenshots.

### Default View Mode
Set grid or tabbed view as default for image display.

### Default Tab Selection
Choose between Individual or Combined tab as default home screen.

### App Permissions
View and manage photo library permissions with clear status indicators.

### Supported Devices
View comprehensive list of supported device types and frames.

### Review Prompts
Configurable app store review requests using ReviewKit.

## Persistence & Synchronization

### iCloud CloudKit Integration
Sync data and preferences across all devices signed into the same iCloud account.

### iCloud Documents
Access framed screenshots across devices through iCloud Drive integration.

### UserDefaults
Local preference storage for app settings and configuration.

### App Groups
Share data seamlessly between main app, action extension, and widgets.

## Advanced Features

### Memory Warning Handling
Graceful degradation under memory pressure to prevent crashes.

### Clear on Background
Option to automatically clear processed images when app moves to background.

### Temporary File Management
Automatic cleanup of temporary files to manage storage efficiently.

### Photo Library Permissions
Granular permission handling (authorized, denied, limited) with appropriate UI feedback.

### ReviewKit Integration
Smart app review prompt timing based on user engagement and feature usage.
