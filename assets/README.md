# Assets Directory

This directory contains static assets for the Odoo Stock Viewer app.

## Directory Structure

```
assets/
├── images/          # App images, splash screens, backgrounds
├── icons/           # Custom icons and graphics
└── README.md        # This file
```

## Usage

### Adding Images
1. Place image files in `assets/images/`
2. Reference them in Flutter code: `'assets/images/your_image.png'`

### Adding Icons
1. Place icon files in `assets/icons/`
2. Reference them in Flutter code: `'assets/icons/your_icon.svg'`

## Supported Formats
- **Images**: PNG, JPG, JPEG, GIF, WebP
- **Vector Graphics**: SVG (with flutter_svg package)
- **Other**: JSON (for Lottie animations), etc.

## Best Practices
1. Use meaningful file names
2. Optimize images for mobile (compress, appropriate resolution)
3. Provide multiple resolutions (@2x, @3x) for better quality on different devices
4. Use vector formats (SVG) when possible for scalability

## Examples

### Using an image:
```dart
Image.asset('assets/images/logo.png')
```

### Using an icon:
```dart
SvgPicture.asset('assets/icons/inventory.svg')
```