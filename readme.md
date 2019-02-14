# SyntaxKit

Syntax highlighting, line numbers, auto-indentation for iOS.

## Using SyntaxKit
- Clone or download SyntaxKit
- Drag the SyntaxKit.xcodeproj file into your Xcode project.
- Embed the SyntaxKit.framework into your App.

## Extending SyntaxKit
Languages can be added by creating a JSON file containing language patterns.
The JSON file for a language can then be loaded and a SKLanguage can be created from it.

Color schemes can be added by creating a Strings file containing colors for all keys which should be overridden.
