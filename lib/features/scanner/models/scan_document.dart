import 'dart:ui';

/// Represents a single scanned page.
class ScanPage {
  final String id;
  final String originalPath;   // raw camera capture
  String processedPath;         // after perspective + enhancement
  ScanFilter filter;
  double brightness;
  double contrast;
  double saturation;
  int rotationDegrees;          // 0 / 90 / 180 / 270
  bool isFlippedHorizontal;

  ScanPage({
    required this.id,
    required this.originalPath,
    required this.processedPath,
    this.filter = ScanFilter.auto,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.rotationDegrees = 0,
    this.isFlippedHorizontal = false,
  });

  ScanPage copyWith({
    String? processedPath,
    ScanFilter? filter,
    double? brightness,
    double? contrast,
    double? saturation,
    int? rotationDegrees,
    bool? isFlippedHorizontal,
  }) =>
      ScanPage(
        id: id,
        originalPath: originalPath,
        processedPath: processedPath ?? this.processedPath,
        filter: filter ?? this.filter,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        rotationDegrees: rotationDegrees ?? this.rotationDegrees,
        isFlippedHorizontal: isFlippedHorizontal ?? this.isFlippedHorizontal,
      );
}

/// Enhancement / colour filter modes.
enum ScanFilter {
  original,
  auto,
  magicColor,
  blackAndWhite,
  gray,
  color,
  document,
  highContrast,
  sharpen,
  cleanPaper,
  vintage,
}

extension ScanFilterLabel on ScanFilter {
  String get label {
    switch (this) {
      case ScanFilter.original:     return 'Original';
      case ScanFilter.auto:         return 'Auto';
      case ScanFilter.magicColor:   return 'Magic';
      case ScanFilter.blackAndWhite:return 'B&W';
      case ScanFilter.gray:         return 'Gray';
      case ScanFilter.color:        return 'Color';
      case ScanFilter.document:     return 'Document';
      case ScanFilter.highContrast: return 'Hi-Con';
      case ScanFilter.sharpen:      return 'Sharpen';
      case ScanFilter.cleanPaper:   return 'Clean';
      case ScanFilter.vintage:      return 'Vintage';
    }
  }
}

/// Document category classification.
enum DocCategory {
  citizenship,
  passport,
  pan,
  drivingLicense,
  birthCertificate,
  academicCertificate,
  insurance,
  bluebook,
  medical,
  property,
  vehicle,
  other,
}

extension DocCategoryLabel on DocCategory {
  String get label {
    switch (this) {
      case DocCategory.citizenship:          return 'Citizenship';
      case DocCategory.passport:             return 'Passport';
      case DocCategory.pan:                  return 'PAN Card';
      case DocCategory.drivingLicense:       return 'Driving License';
      case DocCategory.birthCertificate:     return 'Birth Certificate';
      case DocCategory.academicCertificate:  return 'Academic';
      case DocCategory.insurance:            return 'Insurance';
      case DocCategory.bluebook:             return 'Blue Book';
      case DocCategory.medical:              return 'Medical';
      case DocCategory.property:             return 'Property';
      case DocCategory.vehicle:              return 'Vehicle';
      case DocCategory.other:                return 'Other';
    }
  }
}

/// The complete scan session that gets saved to the vault.
class ScanDocument {
  final String id;
  String name;
  DocCategory category;
  final List<ScanPage> pages;
  final DateTime createdAt;
  DateTime updatedAt;
  String? savedPdfPath;
  String? ocrText;
  List<String> tags;
  DateTime? expiryDate;

  ScanDocument({
    required this.id,
    required this.name,
    required this.category,
    required this.pages,
    required this.createdAt,
    required this.updatedAt,
    this.savedPdfPath,
    this.ocrText,
    List<String>? tags,
    this.expiryDate,
  }) : tags = tags ?? [];
}

/// Corner points for perspective correction (normalised 0..1).
class DocumentCorners {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;

  const DocumentCorners({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  static const DocumentCorners fullFrame = DocumentCorners(
    topLeft:     Offset(0.05, 0.05),
    topRight:    Offset(0.95, 0.05),
    bottomRight: Offset(0.95, 0.95),
    bottomLeft:  Offset(0.05, 0.95),
  );

  /// No-op corners — full pixel range, perspective crop becomes identity.
  /// Use for images already cropped by a native scanner.
  static const DocumentCorners noOp = DocumentCorners(
    topLeft:     Offset(0.0, 0.0),
    topRight:    Offset(1.0, 0.0),
    bottomRight: Offset(1.0, 1.0),
    bottomLeft:  Offset(0.0, 1.0),
  );

  List<Offset> get asList =>
      [topLeft, topRight, bottomRight, bottomLeft];

  DocumentCorners copyWith({
    Offset? topLeft,
    Offset? topRight,
    Offset? bottomRight,
    Offset? bottomLeft,
  }) =>
      DocumentCorners(
        topLeft:     topLeft     ?? this.topLeft,
        topRight:    topRight    ?? this.topRight,
        bottomRight: bottomRight ?? this.bottomRight,
        bottomLeft:  bottomLeft  ?? this.bottomLeft,
      );
}

/// Save format.
enum SaveFormat { pdf, jpeg }

/// PDF page size.
enum PdfPageSize { a4, letter, original }
