import 'package:flutter/material.dart';
import 'element_payloads.dart';
import 'gradient_background.dart';
import 'story_element.dart';
import 'story_page.dart';
import 'story_transform.dart';

/// Predefined layout templates for quickly bootstrapping stylized story pages.
@immutable
class StoryTemplate {
  const StoryTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.builder,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final StoryPage Function(String pageId) builder;

  StoryPage createPage(String pageId) => builder(pageId);

  // ---------------------------------------------------------------------------
  // Built-in Presets
  // ---------------------------------------------------------------------------

  static final quoteTemplate = StoryTemplate(
    id: 'template_quote',
    name: 'Quote of the Day',
    description:
        'Clean typographic layout with gradient background and accent frame.',
    category: 'Typography',
    builder:
        (pageId) => StoryPage(
          id: pageId,
          backgroundColor: const Color(0xFF1E1E2E),
          backgroundGradient: StoryGradientBackground.midnight,
          elements: [
            // Accent frame
            const StoryElement(
              id: 'tpl_el_frame',
              type: StoryElementType.shape,
              transform: StoryTransform(
                x: 0.5,
                y: 0.5,
                width: 0.85,
                height: 0.5,
              ),
              payload: ShapeElementPayload(
                shapeType: ShapeType.rectangle,
                strokeColor: Colors.white24,
                strokeWidth: 1.5,
                cornerRadius: 16.0,
              ),
            ),
            // Quote text
            const StoryElement(
              id: 'tpl_el_quote',
              type: StoryElementType.text,
              transform: StoryTransform(
                x: 0.5,
                y: 0.45,
                width: 0.75,
                height: 0.25,
              ),
              payload: TextElementPayload(
                text: '"Stay hungry, stay foolish."',
                fontSize: 28.0,
                textColor: Colors.white,
                textAlign: TextAlign.center,
                isBold: true,
                isItalic: true,
              ),
            ),
            // Author caption
            const StoryElement(
              id: 'tpl_el_author',
              type: StoryElementType.text,
              transform: StoryTransform(
                x: 0.5,
                y: 0.62,
                width: 0.6,
                height: 0.08,
              ),
              payload: TextElementPayload(
                text: '— Steve Jobs',
                fontSize: 16.0,
                textColor: Colors.white70,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
  );

  static final announcementTemplate = StoryTemplate(
    id: 'template_announcement',
    name: 'Big Announcement',
    description: 'High-contrast headline banner with bright sunset gradient.',
    category: 'Marketing',
    builder:
        (pageId) => StoryPage(
          id: pageId,
          backgroundColor: const Color(0xFFC0392B),
          backgroundGradient: StoryGradientBackground.sunset,
          elements: [
            // Headline banner
            const StoryElement(
              id: 'tpl_el_banner',
              type: StoryElementType.text,
              transform: StoryTransform(
                x: 0.5,
                y: 0.35,
                width: 0.8,
                height: 0.15,
              ),
              payload: TextElementPayload(
                text: 'NEW RELEASE!',
                fontSize: 36.0,
                textColor: Colors.white,
                backgroundColor: Colors.black87,
                textAlign: TextAlign.center,
                isBold: true,
              ),
            ),
            // Subtitle
            const StoryElement(
              id: 'tpl_el_sub',
              type: StoryElementType.text,
              transform: StoryTransform(
                x: 0.5,
                y: 0.5,
                width: 0.7,
                height: 0.12,
              ),
              payload: TextElementPayload(
                text: 'Available everywhere now.\nCheck the link in bio!',
                fontSize: 20.0,
                textColor: Colors.white,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
  );

  static final minimalistPhotoTemplate = StoryTemplate(
    id: 'template_minimalist',
    name: 'Minimalist Frame',
    description: 'Sleek neutral aesthetic with photo placeholder.',
    category: 'Minimal',
    builder:
        (pageId) => StoryPage(
          id: pageId,
          backgroundColor: const Color(0xFF121212),
          elements: [
            // Star decorative accent
            const StoryElement(
              id: 'tpl_el_star',
              type: StoryElementType.shape,
              transform: StoryTransform(
                x: 0.5,
                y: 0.25,
                width: 0.15,
                height: 0.08,
              ),
              payload: ShapeElementPayload(
                shapeType: ShapeType.star,
                fillColor: Colors.amberAccent,
                strokeColor: Colors.white,
                strokeWidth: 1.0,
              ),
            ),
            // Subtitle text
            const StoryElement(
              id: 'tpl_el_title',
              type: StoryElementType.text,
              transform: StoryTransform(
                x: 0.5,
                y: 0.75,
                width: 0.7,
                height: 0.1,
              ),
              payload: TextElementPayload(
                text: 'Moments worth remembering',
                fontSize: 22.0,
                textColor: Colors.white,
                textAlign: TextAlign.center,
                isItalic: true,
              ),
            ),
          ],
        ),
  );

  static List<StoryTemplate> get presets => [
    quoteTemplate,
    announcementTemplate,
    minimalistPhotoTemplate,
  ];
}
