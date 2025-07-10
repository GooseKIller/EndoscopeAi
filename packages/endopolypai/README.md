# endopolypai

Flutter FFI package that connects Flutter with Rust-based AI for polyp detection.

## Requirements
To build this package, you need:
- [Rust/Cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html)
- [flutter_rust_bridge_codegen](https://cjycode.com/flutter_rust_bridge/quickstart):  
  `cargo install flutter_rust_bridge_codegen`
- **Windows only**: Microsoft Visual Studio 2022 (May update or newer)

## Usage
### Initialize Rust backend
```dart
import 'package:endopolypai/endopolypai.dart' as epi;
...
await epi.RustLib.init();
```

### Create EndoAI instance
Load from external file:
```dart
final ai = await epi.newFromFile(modelPath);
```

Load from Flutter assets:
```dart
final ai = await epi.createFromAsset(assetPath);
```

### Run predictions
```dart
final List<FFIDetectionResult> results = await ai.predict(
  width, 
  height, 
  pixels
);
```

## Building
Rust code compiles automatically during project builds.  

**After modifying Rust code**, regenerate bridge files:
```bash
cd packages/endopolypai
flutter_rust_bridge_codegen generate
```

## Troubleshooting
### Error: `undefined reference to ...`
1. Update MSVC to the latest version
2. **Apple platforms only**: Modify `.podspec` files in `macos`/`ios` folders:
```diff
'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/libendopolypai.a'
```
→ Change to →
```diff
'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/libendopolypai.a -lc++'
```