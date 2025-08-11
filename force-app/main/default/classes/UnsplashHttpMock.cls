/*
 * UnsplashHttpMock
 *
 * Utility class for building and sending HTTP requests to the Unsplash API in test methods.
 */
@IsTest
global class UnsplashHttpMock implements HttpCalloutMock{
	global Integer code; global String body; global String status;
	global UnsplashHttpMock(Integer code, String body, String status) {
		this.code = code; this.body = body; this.status = status;
	}
	global HTTPResponse respond(HTTPRequest req) {
		HttpResponse res = new HttpResponse();
		res.setStatusCode(code);
		res.setStatus(status == null ? (code == 200 ? 'OK' : 'ERROR') : status);
		if (body != null) res.setBody(body);
		return res;
	}
}