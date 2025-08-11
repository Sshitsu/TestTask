/*
 * UnsplashHttpTest
 *
 * Test class
 */
@IsTest
private class UnsplashHttpTest {
	@IsTest
	static void buildGetSetsHeaders() {
		HttpRequest req = UnsplashHttp.buildGet('https://api.unsplash.com/search/photos?query=apple', 'KEY123');
		System.assertEquals('GET', req.getMethod());
		System.assertEquals('https://api.unsplash.com/search/photos?query=apple', req.getEndpoint());
		System.assertEquals('Client-ID KEY123', req.getHeader('Authorization'));
		System.assertEquals('v1', req.getHeader('Accept-Version'));
	}

	@IsTest
	static void sendUsesHttpCalloutMock() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new UnsplashHttpMock(200, '{"results":[]}', 'OK'));
		HttpResponse res = UnsplashHttp.send(UnsplashHttp.buildGet('https://api.unsplash.com', 'x'));
		Test.stopTest();
		System.assertEquals(200, res.getStatusCode());
	}

}