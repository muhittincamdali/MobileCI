<div align="center">

# 🚀 MobileCI

**Ready-to-use CI/CD templates for iOS, Flutter & React Native**

[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-Ready-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## ✨ Features

- 📱 **iOS** — Xcode build, test, TestFlight
- 🎯 **Flutter** — Build, test, Play Store & App Store
- ⚛️ **React Native** — Expo & bare workflow
- 🔐 **Code Signing** — Fastlane Match integration
- 📊 **Coverage** — Codecov integration

---

## 🚀 Quick Start

Copy the workflow to your `.github/workflows/`:

```yaml
# iOS
- uses: muhittincamdali/MobileCI/ios@v1
  with:
    scheme: MyApp
    destination: 'platform=iOS Simulator,name=iPhone 15'

# Flutter  
- uses: muhittincamdali/MobileCI/flutter@v1
  with:
    flutter_version: '3.16.0'

# React Native
- uses: muhittincamdali/MobileCI/react-native@v1
```

---

## 📄 License

MIT • [@muhittincamdali](https://github.com/muhittincamdali)
