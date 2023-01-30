var response400 = {
	statusCode: 400,
	statusDescription: "Bad Request",
};

var SUPPORTED_FORMATS = ["gif", "avif", "webp", "png", "svg", "jpeg", "jpg"];

function handler(event) {
	var request = event.request;

	if (!request.querystring.k) return response400;
	var key = decodeURIComponent(request.querystring.k.value);

	var format = key.split(".").pop();
	if (!format || !SUPPORTED_FORMATS.includes(format)) return response400;
	if (request.headers.accept && format !== "gif") {
		if (request.headers.accept.value.includes("avif")) {
			format = "avif";
		} else if (request.headers.accept.value.includes("webp")) {
			format = "webp";
		}
	}

	if (!request.querystring.w) return response400;
	var width = parseInt(request.querystring.w.value);
	if (isNaN(width)) return response400;

	request.querystring = {};
	request.uri = "/" + encodeURIComponent(key) + "/" + format + "/" + width;
	return request;
}