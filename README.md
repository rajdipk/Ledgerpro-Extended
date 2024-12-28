# LedgerPro Extended - Advanced Business Management Suite

![LedgerPro Logo](assets/images/accounting.png)

**PRIVATE REPOSITORY - CONFIDENTIAL**

This is the extended version of LedgerPro with advanced features and complete implementation of inventory management, accounting, and business operations. This repository contains proprietary features and improvements.

## Latest Updates (v2.1.0)

### Billing System Enhancements
- **Improved Balance Summary**:
  - Added delivery charge and discount fields
  - Real-time total calculation with GST
  - Interactive quantity editing with stock validation
  - Save/Cancel functionality with proper error handling

- **Bill Item Management**:
  - Enhanced item list display with proper spacing
  - Click-to-edit quantity feature
  - Real-time price calculations
  - Stock availability checks

- **UI/UX Improvements**:
  - Modern card-based design
  - Themed buttons and icons
  - Responsive layout
  - Better error messages and feedback

### Previous Updates (v2.0.0)
### Authentication Improvements
- Enhanced password field functionality
- Improved focus management
- Responsive design across different screen sizes
- Fixed screen refresh issues

### Inventory Management Enhancements
- **Improved Purchase Order System**:
  - Fixed quantity input in purchase orders
  - Enhanced barcode scanning with audio feedback
  - Updated order status indicators with new color scheme
  - Improved receive items functionality
  - Real-time quantity validation

- **Barcode Scanner Improvements**:
  - Added audio feedback (beep sound) on successful scans
  - Better error handling and user feedback
  - Support for both camera and USB barcode scanners
  - Improved desktop mode support

## Extended Features

### Inventory Management
- **Complete Item Tracking**:
  - SKU and barcode support
  - Real-time stock levels
  - Low stock alerts
  - Item categories and tags
  - Custom attributes
  
- **Purchase Order System**:
  - Create and manage purchase orders
  - Track order status with visual indicators
  - Supplier integration
  - Automatic stock updates
  - Order history and analytics
  
- **Stock Movement**:
  - Track item movements
  - Transfer between locations
  - Movement history
  - Audit trails
  
### Advanced Business Features
- **Multi-Business Support**: 
  - Separate inventory per business
  - Business-specific settings
  - Role-based access control
  
- **Enhanced Supplier Management**:
  - Detailed supplier profiles
  - Order history
  - Payment tracking
  - Supplier performance metrics

- **Advanced Analytics**:
  - Inventory valuation
  - Stock turnover analysis
  - Supplier performance reports
  - Custom report generation

## Releases

LedgerPro releases are managed through GitHub Releases. Each release includes:
- Windows installer (LedgerPro-Setup.exe)
- Android APK (LedgerPro.apk)

### Creating a New Release

1. Run the release script:
   ```bash
   node scripts/create-release.js
   ```

2. Follow the prompts to:
   - Enter the new version number
   - Add changelog entries
   - Confirm the release

3. The script will:
   - Update package.json version
   - Update CHANGELOG.md
   - Create a git tag
   - Push changes to GitHub

4. GitHub Actions will automatically:
   - Build the Windows installer
   - Build the Android APK
   - Create a GitHub Release
   - Upload the build artifacts

### Release Requirements

#### Windows Build
- Node.js 18 or later
- electron-builder

#### Android Build
- Java JDK 11
- Android SDK
- Gradle

### Security

Release builds are signed using:
- Windows: Code signing certificate (optional)
- Android: Release keystore (required)

Configure the following secrets in your GitHub repository:
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

## Google Sign In Setup

1. Copy `windows/flutter/google_sign_in_windows.template.json` to `windows/flutter/google_sign_in_windows.json`
2. Replace the placeholder values with your actual Google OAuth credentials
3. Never commit the `google_sign_in_windows.json` file as it contains sensitive information

## Development Guidelines

### Branch Structure
- `main`: Production-ready code
- `develop`: Development branch
- `feature/*`: Feature branches
- `hotfix/*`: Hot fixes for production

### Code Standards
- Follow Flutter/Dart best practices
- Maintain comprehensive documentation
- Write unit tests for new features
- Use meaningful commit messages

### Security Considerations
- Keep API keys secure
- Follow data protection guidelines
- Implement proper error handling
- Regular security audits

## Installation & Setup

1. Clone the private repository:
```bash
git clone https://github.com/rajdipk/Ledgerpro-Extended.git
```

2. Switch to the development branch:
```bash
git checkout develop
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the application:
```bash
flutter run
```

## Contributing

This is a private repository. Please follow these guidelines:
1. Create feature branches from `develop`
2. Use descriptive commit messages
3. Update documentation as needed
4. Create pull requests for review
5. Ensure all tests pass

## License & Confidentiality

This software is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.
