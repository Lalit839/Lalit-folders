import 'package:activ_user_app/core/network/api_url_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeApiBaseUrl', () {
    test('keeps /api/v1 exactly once when base has no trailing slash', () {
      expect(
        normalizeApiBaseUrl('https://active-private-0gcs.onrender.com/api/v1'),
        'https://active-private-0gcs.onrender.com/api/v1',
      );
    });

    test('removes trailing slash after /api/v1', () {
      expect(
        normalizeApiBaseUrl('https://active-private-0gcs.onrender.com/api/v1/'),
        'https://active-private-0gcs.onrender.com/api/v1',
      );
    });

    test('adds /api/v1 when configured base is only the origin', () {
      expect(
        normalizeApiBaseUrl('https://active-private-0gcs.onrender.com/'),
        'https://active-private-0gcs.onrender.com/api/v1',
      );
    });

    test('removes an extra slash before /api/v1', () {
      expect(
        normalizeApiBaseUrl(
          'https://active-private-0gcs.onrender.com//api/v1',
        ),
        'https://active-private-0gcs.onrender.com/api/v1',
      );
    });

    test('collapses duplicated /api/v1 suffixes', () {
      expect(
        normalizeApiBaseUrl(
          'https://active-private-0gcs.onrender.com/api/v1/api/v1/',
        ),
        'https://active-private-0gcs.onrender.com/api/v1',
      );
    });
  });

  group('buildApiUri', () {
    test('joins trailing-slash base and leading-slash endpoint safely', () {
      expect(
        buildApiUri(
          'https://active-private-0gcs.onrender.com/api/v1/',
          '/auth/otp/request',
        ).toString(),
        'https://active-private-0gcs.onrender.com/api/v1/auth/otp/request',
      );
    });

    test('joins origin base and endpoint without leading slash safely', () {
      expect(
        buildApiUri(
          'https://active-private-0gcs.onrender.com',
          'auth/otp/request',
        ).toString(),
        'https://active-private-0gcs.onrender.com/api/v1/auth/otp/request',
      );
    });

    test('does not duplicate /api/v1 when endpoint includes it', () {
      expect(
        buildApiUri(
          'https://active-private-0gcs.onrender.com/api/v1',
          '/api/v1/auth/otp/request',
        ).toString(),
        'https://active-private-0gcs.onrender.com/api/v1/auth/otp/request',
      );
    });

    test('preserves query parameters', () {
      expect(
        buildApiUri(
          'https://active-private-0gcs.onrender.com/',
          '/catalog/venues',
          query: {'page': '1', 'limit': '20'},
        ).toString(),
        'https://active-private-0gcs.onrender.com/api/v1/catalog/venues?page=1&limit=20',
      );
    });
  });
}
