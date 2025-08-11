/*
 * Test class for JsonParser
 */
@IsTest
private class UnsplashJsonParserTest {

	@IsTest
	static void parseIsOkThenReturnsSmall() {
		String body = '{"results":[{"id":"1","urls":{"thumb":"t","small":"s","regular":"r","full":"f"}}]}';
		String url = UnsplashJsonParser.parseJsonAndGetImageUrl(body, 'small');
		System.assertEquals('s', url);
	}

	@IsTest
	static void parseIsOkThenDifferentSize() {
		String body = '{"results":[{"id":"1","urls":{"thumb":"t","small":"s","regular":"r","full":"f"}}]}';
		System.assertEquals('r', UnsplashJsonParser.parseJsonAndGetImageUrl(body, 'regular'));
		System.assertEquals('f', UnsplashJsonParser.parseJsonAndGetImageUrl(body, 'full'));
	}

	@IsTest
	static void parseIsMissingResultsThenReturnsNull() {
		String body = '{"results":[]}';
		System.assertEquals(null, UnsplashJsonParser.parseJsonAndGetImageUrl(body, 'small'));
	}

	@IsTest
	static void parseIsNullOrMalformedThenReturnsNull() {
		System.assertEquals(null, UnsplashJsonParser.parseJsonAndGetImageUrl(null, 'small'));
		System.assertEquals(null, UnsplashJsonParser.parseJsonAndGetImageUrl('', 'small'));

		String body = '{"results":[{"id":"1"}]}';
		System.assertEquals(null, UnsplashJsonParser.parseJsonAndGetImageUrl(body, 'small'));
	}
}
