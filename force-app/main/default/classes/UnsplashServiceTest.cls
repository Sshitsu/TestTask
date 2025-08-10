@IsTest
private class UnsplashServiceTest {

	@IsTest
	static void findImageUrlIsSuccessThenReturnsSmall() {
		String json = '{"results":[{"id":"1","urls":{"thumb":"t","small":"s","regular":"r","full":"f"}}]}';
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new UnsplashHttpMock(200, json, 'OK'));
		String url = UnsplashService.findImageUrl('apple');
		Test.stopTest();
		System.assertEquals('s', url, 'Must return  small URL');
	}

	@IsTest
	static void findImageUrlIsEmptyThenReturnsNull() {
		String json = '{"results":[]}';
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new UnsplashHttpMock(200, json, 'OK'));
		String url = UnsplashService.findImageUrl('unknown');
		Test.stopTest();
		System.assertEquals(null, url);
	}

	@IsTest
	static void findImageUrlByItemUsesItemName() {
		Item__c it = new Item__c(Name = 'Banana');
		insert it;

		String json = '{"results":[{"id":"2","urls":{"small":"bananaUrl"}}]}';
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new UnsplashHttpMock(200, json, 'OK'));
		String url = UnsplashService.findImageUrlByItem(it.Id);
		Test.stopTest();

		System.assertEquals('bananaUrl', url);
	}
}
