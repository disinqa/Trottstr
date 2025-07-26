import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Progress Bar Percentage Calculations', () {
    test('should calculate correct percentage for 1 day out of 183 total days', () {
      // The reported issue: 1 day out of 183 shows as 100% instead of ~0.55%
      const totalDays = 183;
      const countryDays = 1;
      
      final percentage = totalDays > 0 ? (countryDays / totalDays * 100) : 0.0;
      
      expect(percentage, closeTo(0.547, 0.001)); // Should be approximately 0.547%
      expect(percentage < 1.0, true); // Should definitely be less than 1%
      expect(percentage > 0.0, true); // Should be greater than 0%
    });
    
    test('should handle various small percentage scenarios correctly', () {
      final testCases = [
        {'days': 1, 'total': 183, 'expected': 0.547},
        {'days': 1, 'total': 365, 'expected': 0.274},
        {'days': 2, 'total': 183, 'expected': 1.093},
        {'days': 5, 'total': 1000, 'expected': 0.5},
        {'days': 10, 'total': 365, 'expected': 2.740},
      ];
      
      for (final testCase in testCases) {
        final days = testCase['days'] as int;
        final total = testCase['total'] as int;
        final expected = testCase['expected'] as double;
        
        final percentage = total > 0 ? (days / total * 100) : 0.0;
        expect(percentage, closeTo(expected, 0.001), 
          reason: '$days days out of $total should be ~$expected%');
      }
    });
    
    test('should format percentage display text correctly', () {
      const totalDays = 183;
      const countryDays = 1;
      
      final percentage = totalDays > 0 ? (countryDays / totalDays * 100) : 0.0;
      final displayText = '${percentage.toStringAsFixed(1)}% of total';
      
      expect(displayText, '0.5% of total'); // Should show 0.5% not 1.0% or 100.0%
    });
    
    test('should handle edge cases properly', () {
      // Edge cases
      expect(0 / 183 * 100, 0.0); // Zero days
      expect(183 / 183 * 100, 100.0); // All days
      expect(1 / 1 * 100, 100.0); // Single day total
      expect((0 / 0).isNaN, true); // Division by zero (handled by UI logic)
    });
    
    test('should verify visual progress bar width calculation', () {
      // Simulate the new LayoutBuilder logic
      const totalWidth = 300.0; // Example container width
      const percentage = 0.547; // 1 day out of 183
      
      final filledWidth = (percentage / 100) * totalWidth;
      final displayWidth = percentage > 0 ? (filledWidth < 2.0 ? 2.0 : filledWidth) : 0.0;
      
      expect(filledWidth, closeTo(1.641, 0.001)); // ~1.64 pixels
      expect(displayWidth, 2.0); // Should be minimum 2 pixels for visibility
      expect(displayWidth > 0, true); // Should be visible
      expect(displayWidth < totalWidth, true); // Should not fill entire width
    });
  });
}