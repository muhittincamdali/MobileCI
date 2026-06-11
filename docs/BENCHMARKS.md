# MobileCI Benchmarks

This document defines how MobileCI should prove its speed and reliability claims.

## Compare Against

- Fastlane
- raw Xcodebuild scripts
- one hosted CI baseline where relevant

## Measure

- cold build time
- warm build time with cache
- test execution time
- artifact size
- signing/setup time
- failure detection speed

## Scenarios

| Scenario | Platform | Purpose |
| --- | --- | --- |
| Native iOS app | iOS | baseline Apple workflow |
| Multi-target app | iOS + extensions | signing and target complexity |
| Flutter app | Flutter iOS pipeline | cross-stack proof |
| React Native app | RN iOS pipeline | mixed ecosystem proof |

## Publish For Each Run

- runner type
- Xcode version
- cache state
- dependency restore time
- build time
- test time
- deployment prep time
- notes on failures or retries

## Quality Rule

Do not make “faster than Fastlane” a headline unless the README links to reproducible evidence.

