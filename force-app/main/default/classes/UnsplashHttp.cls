public with sharing class UnsplashHttp {
	@TestVisible private static Http injected;


	public static HttpRequest buildGet(String absoluteUrl, String accessKey){
		HttpRequest request = new HttpRequest();
		request.setMethod('GET');
		request.setEndpoint(absoluteUrl);
		request.setHeader('Authorization', 'Client-ID ' + accessKey);
		request.setHeader('Accept-Version', 'v1');
		request.setTimeout(20000);
		return request;
	}

	public static HttpResponse send(HttpRequest request){
		Http http = injected == null ? new Http() : injected;
		return http.send(request);
	}

	public static void ensureOk(HttpResponse res){
		if (res == null || res.getStatusCode() != 200) {
			Integer code = (res == null) ? -1 : res.getStatusCode();
			String status = (res == null) ? 'NO_RESPONSE' : res.getStatus();
			throw new AuraHandledException('Unsplash error: ' + code + ' ' + status);
		}
	}

	@TestVisible
	static void setHttp(Http h){ injected = h; }
}