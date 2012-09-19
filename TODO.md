Planned interface-breaking changes before 1.0:

* The callback API must guarantee that the request body has been consumed
  somehow...

* Make the Header.t header parsing more efficient by only lazily parsing them
  instead of copying into a Map as we do now.

* Make the Lwt response stream bounded (new in lwt-2.4+)

* Server file support and default_spec

* Make Lwt_ssl optional

Better HTTP support:

- Range requests need to be fully implemented (206)
- 100 Continue should be a noop
- Lwt Connection: close support
- A client interface that deals with redirects
- Proxy support (manual means a full URI in the request)
- SSL support for Async?

Tests:

- Test the lib_test server scripts via external invocations of
  curl and httperf, so that the tests terminate.

- Test the HTTP timeout support